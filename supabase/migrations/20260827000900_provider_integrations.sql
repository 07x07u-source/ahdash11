-- Provider-facing contracts for RevenueCat and Firebase Cloud Messaging.

drop index if exists public.subscriptions_original_tx_uidx;
create index subscriptions_original_tx_entitlement_idx
  on public.subscriptions(provider, original_transaction_id, entitlement_id)
  where original_transaction_id is not null;

create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  device_token_id uuid not null references public.device_tokens(id) on delete cascade,
  status text not null check (status in ('sent', 'failed', 'skipped')),
  provider_message_id text,
  error_code text,
  attempted_at timestamptz not null default clock_timestamp(),
  unique (notification_id, device_token_id)
);

create index notification_deliveries_notification_idx
  on public.notification_deliveries(notification_id, status, attempted_at desc);

alter table public.notification_deliveries enable row level security;

create policy notification_deliveries_admin_read on public.notification_deliveries
  for select using (public.has_role('moderator'));

revoke all on public.notification_deliveries from anon, authenticated;
grant select on public.notification_deliveries to authenticated;

create or replace function public.apply_revenuecat_subscription_event(
  p_user_id uuid,
  p_entitlement_id text,
  p_product_id text,
  p_original_transaction_id text,
  p_status text,
  p_platform text,
  p_purchased_at timestamptz,
  p_current_period_ends_at timestamptz,
  p_cancelled_at timestamptz,
  p_event_at timestamptz,
  p_raw_event jsonb
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  affected integer;
begin
  if p_user_id is null or nullif(trim(p_entitlement_id), '') is null then
    raise exception using errcode = '22023', message = 'User and entitlement are required';
  end if;

  if p_status not in ('trialing', 'active', 'grace_period', 'paused', 'expired', 'cancelled', 'refunded') then
    raise exception using errcode = '22023', message = 'Unsupported subscription status';
  end if;

  if p_platform not in ('ios', 'android', 'unknown') then
    raise exception using errcode = '22023', message = 'Unsupported subscription platform';
  end if;

  insert into public.subscriptions(
    user_id,
    entitlement_id,
    product_id,
    original_transaction_id,
    status,
    platform,
    purchased_at,
    current_period_ends_at,
    cancelled_at,
    raw_event,
    last_event_at
  ) values (
    p_user_id,
    trim(p_entitlement_id),
    coalesce(nullif(trim(p_product_id), ''), 'unknown'),
    nullif(trim(p_original_transaction_id), ''),
    p_status::public.subscription_status,
    p_platform,
    p_purchased_at,
    p_current_period_ends_at,
    p_cancelled_at,
    coalesce(p_raw_event, '{}'::jsonb),
    coalesce(p_event_at, clock_timestamp())
  )
  on conflict (user_id, entitlement_id) do update set
    product_id = excluded.product_id,
    original_transaction_id = coalesce(excluded.original_transaction_id, public.subscriptions.original_transaction_id),
    status = excluded.status,
    platform = excluded.platform,
    purchased_at = coalesce(excluded.purchased_at, public.subscriptions.purchased_at),
    current_period_ends_at = excluded.current_period_ends_at,
    cancelled_at = excluded.cancelled_at,
    raw_event = excluded.raw_event,
    last_event_at = excluded.last_event_at,
    updated_at = clock_timestamp()
  where excluded.last_event_at >= public.subscriptions.last_event_at;

  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

revoke all on function public.apply_revenuecat_subscription_event(
  uuid, text, text, text, text, text, timestamptz, timestamptz,
  timestamptz, timestamptz, jsonb
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_subscription_event(
  uuid, text, text, text, text, text, timestamptz, timestamptz,
  timestamptz, timestamptz, jsonb
) to service_role;

create table public.ad_reward_claims (
  transaction_id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  ad_unit_id text not null,
  reward_item text not null,
  provider_reward_amount numeric not null check (provider_reward_amount > 0),
  awarded_coins bigint not null check (awarded_coins > 0),
  provider_timestamp timestamptz not null,
  wallet_transaction_id uuid references public.wallet_transactions(id) on delete set null,
  callback_data jsonb not null default '{}'::jsonb check (jsonb_typeof(callback_data) = 'object'),
  created_at timestamptz not null default clock_timestamp()
);

create index ad_reward_claims_user_created_idx
  on public.ad_reward_claims(user_id, created_at desc);

alter table public.ad_reward_claims enable row level security;
revoke all on public.ad_reward_claims from anon, authenticated;

create or replace function public.claim_verified_admob_reward(
  p_transaction_id text,
  p_user_id uuid,
  p_ad_unit_id text,
  p_reward_item text,
  p_provider_reward_amount numeric,
  p_provider_timestamp timestamptz,
  p_callback_data jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  coin_reward bigint;
  created_claim text;
  existing_claim public.ad_reward_claims%rowtype;
  transaction_row public.wallet_transactions%rowtype;
begin
  if char_length(coalesce(trim(p_transaction_id), '')) not between 8 and 180 then
    raise exception using errcode = '22023', message = 'Invalid provider transaction';
  end if;
  if p_provider_reward_amount <= 0 then
    raise exception using errcode = '22023', message = 'Invalid provider reward';
  end if;

  coin_reward := coalesce(
    (select (value #>> '{}')::bigint from public.game_settings where key = 'ads.rewarded_coins'),
    25
  );
  if coin_reward <= 0 or coin_reward > 10000 then
    raise exception using errcode = '22023', message = 'Invalid configured coin reward';
  end if;

  insert into public.ad_reward_claims(
    transaction_id, user_id, ad_unit_id, reward_item,
    provider_reward_amount, awarded_coins, provider_timestamp, callback_data
  ) values (
    trim(p_transaction_id), p_user_id, trim(p_ad_unit_id), trim(p_reward_item),
    p_provider_reward_amount, coin_reward, p_provider_timestamp,
    coalesce(p_callback_data, '{}'::jsonb)
  )
  on conflict (transaction_id) do nothing
  returning transaction_id into created_claim;

  if created_claim is null then
    select * into existing_claim
    from public.ad_reward_claims
    where transaction_id = trim(p_transaction_id);
    return jsonb_build_object(
      'duplicate', true,
      'awarded_coins', existing_claim.awarded_coins,
      'wallet_transaction_id', existing_claim.wallet_transaction_id
    );
  end if;

  transaction_row := public.post_wallet_transaction(
    p_user_id,
    coin_reward,
    'reward',
    'verified_admob_reward',
    'admob_reward',
    trim(p_transaction_id),
    'admob:' || trim(p_transaction_id),
    jsonb_build_object(
      'ad_unit_id', trim(p_ad_unit_id),
      'reward_item', trim(p_reward_item),
      'provider_reward_amount', p_provider_reward_amount,
      'provider_timestamp', p_provider_timestamp
    ),
    null
  );

  update public.ad_reward_claims
  set wallet_transaction_id = transaction_row.id
  where transaction_id = created_claim;

  return jsonb_build_object(
    'duplicate', false,
    'awarded_coins', coin_reward,
    'wallet_transaction_id', transaction_row.id,
    'balance_after', transaction_row.balance_after
  );
end;
$$;

revoke all on function public.claim_verified_admob_reward(
  text, uuid, text, text, numeric, timestamptz, jsonb
) from public, anon, authenticated;
grant execute on function public.claim_verified_admob_reward(
  text, uuid, text, text, numeric, timestamptz, jsonb
) to service_role;

create or replace function public.search_players(
  p_query text,
  p_limit integer default 20
)
returns table(
  user_id uuid,
  username text,
  display_name text,
  avatar_url text,
  level integer,
  rating integer,
  relationship text
)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  caller public.profiles%rowtype;
  normalized_query text;
begin
  caller := public.require_active_user();
  normalized_query := trim(coalesce(p_query, ''));
  if char_length(normalized_query) < 2 then
    raise exception using errcode = '22023', message = 'Search query must contain at least two characters';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'search_players', 60, interval '1 hour');

  return query
  select
    profile.id,
    profile.username::text,
    profile.display_name,
    profile.avatar_url,
    profile.level,
    profile.rating,
    case
      when exists (
        select 1 from public.friends friendship
        where (friendship.user_a_id = caller.id and friendship.user_b_id = profile.id)
           or (friendship.user_b_id = caller.id and friendship.user_a_id = profile.id)
      ) then 'friend'
      when exists (
        select 1 from public.friend_requests request
        where request.sender_id = caller.id and request.receiver_id = profile.id and request.status = 'pending'
      ) then 'pending_sent'
      when exists (
        select 1 from public.friend_requests request
        where request.receiver_id = caller.id and request.sender_id = profile.id and request.status = 'pending'
      ) then 'pending_received'
      else 'none'
    end
  from public.profiles profile
  where profile.id <> caller.id
    and profile.status = 'active'
    and (
      profile.username::text ilike '%' || normalized_query || '%'
      or profile.display_name ilike '%' || normalized_query || '%'
    )
  order by
    case when lower(profile.username::text) = lower(normalized_query) then 0 else 1 end,
    similarity(profile.username::text, normalized_query) desc,
    profile.rating desc
  limit greatest(1, least(coalesce(p_limit, 20), 30));
end;
$$;

create or replace function public.send_friend_request(
  p_receiver_id uuid,
  p_message text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  receiver public.profiles%rowtype;
  request_id uuid;
begin
  caller := public.require_active_user();
  if p_receiver_id = caller.id then
    raise exception using errcode = '22023', message = 'Cannot add yourself';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'send_friend_request', 30, interval '1 day');
  select * into receiver from public.profiles where id = p_receiver_id and status = 'active';
  if not found then
    raise exception using errcode = 'P0002', message = 'Player not found';
  end if;
  if exists (
    select 1 from public.friends friendship
    where (friendship.user_a_id = caller.id and friendship.user_b_id = receiver.id)
       or (friendship.user_b_id = caller.id and friendship.user_a_id = receiver.id)
  ) then
    raise exception using errcode = '23505', message = 'Players are already friends';
  end if;
  if exists (
    select 1 from public.friend_requests request
    where request.status = 'pending'
      and ((request.sender_id = caller.id and request.receiver_id = receiver.id)
        or (request.receiver_id = caller.id and request.sender_id = receiver.id))
  ) then
    raise exception using errcode = '23505', message = 'A friend request is already pending';
  end if;

  insert into public.friend_requests(sender_id, receiver_id, message)
  values (caller.id, receiver.id, nullif(trim(p_message), ''))
  returning id into request_id;

  insert into public.notifications(
    target_user_id, type, title_ar, body_ar, data, status
  ) values (
    receiver.id,
    'friend_request',
    'طلب صداقة جديد',
    caller.display_name || ' يريد إضافتك إلى قائمة الأصدقاء.',
    jsonb_build_object('request_id', request_id, 'sender_id', caller.id),
    'queued'
  );
  return jsonb_build_object('request_id', request_id, 'status', 'pending');
end;
$$;

create or replace function public.respond_friend_request(
  p_request_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_request public.friend_requests%rowtype;
  result jsonb;
begin
  caller := public.require_active_user();
  select * into target_request
  from public.friend_requests
  where id = p_request_id
  for update;
  if not found or target_request.status <> 'pending' then
    raise exception using errcode = 'P0001', message = 'Friend request is no longer pending';
  end if;

  if target_request.receiver_id = caller.id then
    if p_accept then
      result := public.accept_friend_request(target_request.id);
      insert into public.notifications(target_user_id, type, title_ar, body_ar, data, status)
      values (
        target_request.sender_id,
        'friend_request',
        'تم قبول طلب الصداقة',
        caller.display_name || ' أصبح ضمن قائمة أصدقائك.',
        jsonb_build_object('friend_user_id', caller.id),
        'queued'
      );
      return result;
    end if;
    update public.friend_requests
    set status = 'declined', responded_at = clock_timestamp()
    where id = target_request.id;
    return jsonb_build_object('request_id', target_request.id, 'status', 'declined');
  end if;

  if target_request.sender_id = caller.id and not p_accept then
    update public.friend_requests
    set status = 'cancelled', responded_at = clock_timestamp()
    where id = target_request.id;
    return jsonb_build_object('request_id', target_request.id, 'status', 'cancelled');
  end if;
  raise exception using errcode = '42501', message = 'Friend request action is not allowed';
end;
$$;

create or replace function public.remove_friend(p_friend_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  affected integer;
begin
  caller := public.require_active_user();
  delete from public.friends
  where (user_a_id = caller.id and user_b_id = p_friend_user_id)
     or (user_b_id = caller.id and user_a_id = p_friend_user_id);
  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

create or replace function public.get_friend_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  inbox jsonb;
  outbox jsonb;
  friend_list jsonb;
begin
  caller := public.require_active_user();
  select coalesce(jsonb_agg(jsonb_build_object(
    'request_id', request.id,
    'message', request.message,
    'created_at', request.created_at,
    'user_id', sender.id,
    'username', sender.username,
    'display_name', sender.display_name,
    'avatar_url', sender.avatar_url,
    'level', sender.level,
    'rating', sender.rating
  ) order by request.created_at desc), '[]'::jsonb)
  into inbox
  from public.friend_requests request
  join public.profiles sender on sender.id = request.sender_id
  where request.receiver_id = caller.id and request.status = 'pending';

  select coalesce(jsonb_agg(jsonb_build_object(
    'request_id', request.id,
    'message', request.message,
    'created_at', request.created_at,
    'user_id', receiver.id,
    'username', receiver.username,
    'display_name', receiver.display_name,
    'avatar_url', receiver.avatar_url,
    'level', receiver.level,
    'rating', receiver.rating
  ) order by request.created_at desc), '[]'::jsonb)
  into outbox
  from public.friend_requests request
  join public.profiles receiver on receiver.id = request.receiver_id
  where request.sender_id = caller.id and request.status = 'pending';

  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id', friend_profile.id,
    'username', friend_profile.username,
    'display_name', friend_profile.display_name,
    'avatar_url', friend_profile.avatar_url,
    'level', friend_profile.level,
    'rating', friend_profile.rating,
    'online', friend_profile.last_seen_at >= clock_timestamp() - interval '5 minutes',
    'friends_since', friendship.created_at
  ) order by (friend_profile.last_seen_at >= clock_timestamp() - interval '5 minutes') desc, friend_profile.display_name), '[]'::jsonb)
  into friend_list
  from public.friends friendship
  join public.profiles friend_profile on friend_profile.id = case
    when friendship.user_a_id = caller.id then friendship.user_b_id
    else friendship.user_a_id
  end
  where friendship.user_a_id = caller.id or friendship.user_b_id = caller.id;

  return jsonb_build_object('friends', friend_list, 'inbox', inbox, 'outbox', outbox);
end;
$$;

create or replace function public.invite_friend_to_room(
  p_room_id uuid,
  p_friend_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_room public.rooms%rowtype;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'invite_friend_to_room', 30, interval '1 hour');
  if not exists (
    select 1 from public.friends friendship
    where (friendship.user_a_id = caller.id and friendship.user_b_id = p_friend_user_id)
       or (friendship.user_b_id = caller.id and friendship.user_a_id = p_friend_user_id)
  ) then
    raise exception using errcode = '42501', message = 'Only friends can be invited directly';
  end if;
  select * into target_room from public.rooms
  where id = p_room_id and host_user_id = caller.id and status = 'open' and expires_at > clock_timestamp();
  if not found then
    raise exception using errcode = 'P0001', message = 'Room is not available for invitation';
  end if;
  insert into public.notifications(target_user_id, type, title_ar, body_ar, data, status)
  values (
    p_friend_user_id,
    'match_invite',
    'دعوة مباراة من ' || caller.display_name,
    'ادخل الغرفة بالرمز ' || target_room.code || ' قبل انتهاء صلاحيتها.',
    jsonb_build_object('room_id', target_room.id, 'match_id', target_room.match_id, 'room_code', target_room.code),
    'queued'
  );
  return jsonb_build_object('invited', true, 'room_id', target_room.id, 'room_code', target_room.code);
end;
$$;

revoke insert, update on public.friend_requests from authenticated;
revoke delete on public.friends from authenticated;
revoke execute on function public.accept_friend_request(uuid) from authenticated;
revoke select, insert, update, delete on public.matchmaking_queue from authenticated;

revoke all on function public.search_players(text, integer) from public, anon, authenticated;
revoke all on function public.send_friend_request(uuid, text) from public, anon, authenticated;
revoke all on function public.respond_friend_request(uuid, boolean) from public, anon, authenticated;
revoke all on function public.remove_friend(uuid) from public, anon, authenticated;
revoke all on function public.get_friend_dashboard() from public, anon, authenticated;
revoke all on function public.invite_friend_to_room(uuid, uuid) from public, anon, authenticated;

grant execute on function public.search_players(text, integer) to authenticated;
grant execute on function public.send_friend_request(uuid, text) to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.get_friend_dashboard() to authenticated;
grant execute on function public.invite_friend_to_room(uuid, uuid) to authenticated;

create or replace function public.get_my_profile_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  stats public.player_stats%rowtype;
  coin_balance bigint := 0;
  leaderboard_rank integer := 0;
  premium_active boolean := false;
  answer_total bigint := 0;
begin
  caller := public.require_active_user();
  select * into stats from public.player_stats where user_id = caller.id;
  select coalesce(
    (select wallet.balance from public.wallets wallet where wallet.user_id = caller.id),
    0
  ) into coin_balance;
  select count(*)::integer + 1 into leaderboard_rank
  from public.profiles profile
  where profile.status = 'active' and profile.rating > caller.rating;
  select exists (
    select 1 from public.subscriptions subscription
    where subscription.user_id = caller.id
      and subscription.status in ('trialing', 'active', 'grace_period')
      and (
        subscription.current_period_ends_at is null
        or subscription.current_period_ends_at > clock_timestamp()
      )
  ) into premium_active;
  answer_total := coalesce(stats.correct_answers, 0) + coalesce(stats.wrong_answers, 0);

  return jsonb_build_object(
    'id', caller.id,
    'username', caller.username,
    'level', caller.level,
    'xp', caller.xp,
    'coins', coin_balance,
    'rating', caller.rating,
    'wins', coalesce(stats.wins, 0),
    'losses', coalesce(stats.losses, 0),
    'draws', coalesce(stats.draws, 0),
    'matches', coalesce(stats.matches_played, 0),
    'accuracy', case
      when answer_total = 0 then 0
      else coalesce(stats.correct_answers, 0)::numeric / answer_total
    end,
    'best_streak', coalesce(stats.best_streak, 0),
    'current_streak', coalesce(stats.current_streak, 0),
    'rank', leaderboard_rank,
    'favorite_club', caller.favorite_club,
    'avatar_url', caller.avatar_url,
    'is_premium', premium_active
  );
end;
$$;

revoke all on function public.get_my_profile_summary() from public, anon, authenticated;
grant execute on function public.get_my_profile_summary() to authenticated;

create or replace view public.leaderboard
with (security_invoker = true)
as
select
  row_number() over (order by profile.rating desc, profile.xp desc, profile.created_at) as rank,
  profile.id as user_id,
  profile.username::text as username,
  profile.rating,
  case
    when profile.rating >= 2100 then 'Champion'
    when profile.rating >= 1800 then 'Diamond'
    when profile.rating >= 1500 then 'Platinum'
    when profile.rating >= 1250 then 'Gold'
    when profile.rating >= 1050 then 'Silver'
    else 'Bronze'
  end as tier,
  profile.avatar_url
from public.profiles profile
where profile.status = 'active';

revoke all on public.leaderboard from public, anon, authenticated;
grant select on public.leaderboard to authenticated;
