-- Economy, match finalization, moderation, friendship, and deterministic import pipeline.
create or replace function public.post_wallet_transaction(
  p_user_id uuid,
  p_amount bigint,
  p_type public.wallet_transaction_type,
  p_reason text,
  p_reference_type text default null,
  p_reference_id text default null,
  p_idempotency_key text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_created_by uuid default null
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_wallet public.wallets%rowtype;
  existing_transaction public.wallet_transactions%rowtype;
  created_transaction public.wallet_transactions%rowtype;
begin
  if p_amount = 0 then
    raise exception using errcode = '22023', message = 'Wallet amount cannot be zero';
  end if;
  if char_length(coalesce(trim(p_reason), '')) not between 1 and 120 then
    raise exception using errcode = '22023', message = 'Wallet reason is required';
  end if;
  if jsonb_typeof(coalesce(p_metadata, '{}'::jsonb)) <> 'object' then
    raise exception using errcode = '22023', message = 'Wallet metadata must be an object';
  end if;

  select * into target_wallet from public.wallets where user_id = p_user_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Wallet not found';
  end if;

  if p_idempotency_key is not null then
    select * into existing_transaction
    from public.wallet_transactions
    where wallet_id = target_wallet.id and idempotency_key = p_idempotency_key;
    if found then
      return existing_transaction;
    end if;
  end if;

  insert into public.wallet_transactions(
    wallet_id, amount, type, reason, reference_type, reference_id,
    idempotency_key, balance_after, metadata, created_by
  ) values (
    target_wallet.id, p_amount, p_type, trim(p_reason), p_reference_type, p_reference_id,
    p_idempotency_key, 0, coalesce(p_metadata, '{}'), p_created_by
  ) returning * into created_transaction;
  return created_transaction;
end;
$$;

create or replace function public.finalize_match(p_match_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_match public.matches%rowtype;
  player_row public.match_players%rowtype;
  team_a_score bigint;
  team_b_score bigint;
  team_a_correct bigint;
  team_b_correct bigint;
  team_a_time bigint;
  team_b_time bigint;
  winning_team public.team_side;
  is_draw boolean;
  player_won boolean;
  xp_reward integer;
  coin_reward integer;
  rating_delta integer;
  result_players jsonb;
begin
  select * into target_match from public.matches where id = p_match_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match not found';
  end if;
  if target_match.status = 'finished' then
    select coalesce(jsonb_agg(to_jsonb(mp) order by mp.team, mp.seat), '[]'::jsonb)
    into result_players from public.match_players mp where mp.match_id = target_match.id;
    return jsonb_build_object('match_id', target_match.id, 'state', 'finished', 'players', result_players);
  end if;
  if target_match.status <> 'result' then
    raise exception using errcode = 'P0001', message = 'Match cannot be finalized from its current state';
  end if;
  if (select count(*) from public.match_questions where match_id = target_match.id and status = 'revealed')
     <> target_match.question_count then
    raise exception using errcode = 'P0001', message = 'All questions must be revealed before finalization';
  end if;

  select coalesce(sum(score) filter (where team = 'a'), 0),
         coalesce(sum(score) filter (where team = 'b'), 0),
         coalesce(sum(correct_answers) filter (where team = 'a'), 0),
         coalesce(sum(correct_answers) filter (where team = 'b'), 0),
         coalesce(sum(total_answer_time_ms) filter (where team = 'a'), 0),
         coalesce(sum(total_answer_time_ms) filter (where team = 'b'), 0)
  into team_a_score, team_b_score, team_a_correct, team_b_correct, team_a_time, team_b_time
  from public.match_players where match_id = target_match.id;
  is_draw := team_a_score = team_b_score
    and team_a_correct = team_b_correct
    and team_a_time = team_b_time;
  winning_team := case
    when is_draw then null
    when team_a_score > team_b_score then 'a'::public.team_side
    when team_a_score < team_b_score then 'b'::public.team_side
    when team_a_correct > team_b_correct then 'a'::public.team_side
    when team_a_correct < team_b_correct then 'b'::public.team_side
    when team_a_time < team_b_time then 'a'::public.team_side
    else 'b'::public.team_side
  end;

  update public.matches
  set status = 'finished', winner_team = winning_team
  where id = target_match.id;
  update public.rooms set status = 'closed' where match_id = target_match.id;

  for player_row in
    select * from public.match_players
    where match_id = target_match.id and user_id is not null
    order by team, seat
    for update
  loop
    player_won := not is_draw and player_row.team = winning_team;
    xp_reward := coalesce((select (value #>> '{}')::integer from public.game_settings where key = 'rewards.match_finish_xp'), 50)
      + case when player_won then coalesce((select (value #>> '{}')::integer from public.game_settings where key = 'rewards.win_xp'), 25) else 0 end;
    coin_reward := coalesce((select (value #>> '{}')::integer from public.game_settings where key = 'rewards.match_finish_coins'), 10)
      + case when player_won then coalesce((select (value #>> '{}')::integer from public.game_settings where key = 'rewards.win_coins'), 10) else 0 end;
    rating_delta := case
      when target_match.mode = 'solo' then 0
      when is_draw then 0
      when player_won then 20
      else -20
    end;

    update public.profiles
    set xp = xp + xp_reward,
        level = greatest(level, floor(sqrt((xp + xp_reward)::numeric / 100))::integer + 1),
        rating = greatest(0, rating + rating_delta)
    where id = player_row.user_id;

    update public.player_stats
    set matches_played = matches_played + 1,
        wins = wins + case when player_won then 1 else 0 end,
        losses = losses + case when not player_won and not is_draw then 1 else 0 end,
        draws = draws + case when is_draw then 1 else 0 end,
        correct_answers = correct_answers + player_row.correct_answers,
        wrong_answers = wrong_answers + player_row.wrong_answers,
        total_answer_time_ms = total_answer_time_ms + player_row.total_answer_time_ms,
        highest_rating = greatest(highest_rating, greatest(0, coalesce(player_row.rating_before, 1000) + rating_delta))
    where user_id = player_row.user_id;

    update public.match_players
    set status = 'finished',
        xp_awarded = xp_reward,
        coins_awarded = coin_reward,
        rating_after = greatest(0, coalesce(player_row.rating_before, 1000) + rating_delta)
    where id = player_row.id;

    if coin_reward > 0 then
      perform public.post_wallet_transaction(
        player_row.user_id,
        coin_reward,
        'reward',
        'match_reward',
        'match',
        target_match.id::text,
        'match_reward:' || target_match.id::text,
        jsonb_build_object('won', player_won, 'draw', is_draw),
        null
      );
    end if;

    if target_match.season_id is not null and target_match.mode <> 'solo' then
      insert into public.player_season_stats(season_id, user_id, rating, matches_played, wins, losses, draws, points)
      values (
        target_match.season_id, player_row.user_id,
        greatest(0, coalesce(player_row.rating_before, 1000) + rating_delta), 1,
        case when player_won then 1 else 0 end,
        case when not player_won and not is_draw then 1 else 0 end,
        case when is_draw then 1 else 0 end,
        case when player_won then 3 when is_draw then 1 else 0 end
      )
      on conflict (season_id, user_id) do update
      set rating = excluded.rating,
          matches_played = public.player_season_stats.matches_played + 1,
          wins = public.player_season_stats.wins + excluded.wins,
          losses = public.player_season_stats.losses + excluded.losses,
          draws = public.player_season_stats.draws + excluded.draws,
          points = public.player_season_stats.points + excluded.points;
    end if;
  end loop;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select id, 'match_finished', auth.uid(), state_version,
    jsonb_build_object('winner_team', winning_team, 'team_a_score', team_a_score, 'team_b_score', team_b_score)
  from public.matches where id = target_match.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'match_player_id', mp.id,
    'display_name', mp.display_name_snapshot,
    'team', mp.team,
    'score', mp.score,
    'correct_answers', mp.correct_answers,
    'wrong_answers', mp.wrong_answers,
    'total_answer_time_ms', mp.total_answer_time_ms,
    'xp_awarded', mp.xp_awarded,
    'coins_awarded', mp.coins_awarded,
    'rating_before', mp.rating_before,
    'rating_after', mp.rating_after
  ) order by mp.team, mp.seat), '[]'::jsonb)
  into result_players
  from public.match_players mp where mp.match_id = target_match.id;

  return jsonb_build_object(
    'match_id', target_match.id,
    'state', 'finished',
    'winner_team', winning_team,
    'team_a_score', team_a_score,
    'team_b_score', team_b_score,
    'players', result_players
  );
end;
$$;

create or replace function public.purchase_store_item(
  p_store_item_id uuid,
  p_quantity integer default 1,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_item public.store_items%rowtype;
  target_wallet public.wallets%rowtype;
  transaction_row public.wallet_transactions%rowtype;
  existing_transaction public.wallet_transactions%rowtype;
  inventory_row public.user_inventory%rowtype;
  total_price bigint;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'purchase_store_item', 20, interval '1 minute');
  if p_quantity not between 1 and 100 then
    raise exception using errcode = '22023', message = 'quantity must be between 1 and 100';
  end if;
  if char_length(coalesce(p_idempotency_key, '')) not between 8 and 120 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;

  select * into target_item from public.store_items where id = p_store_item_id for share;
  if not found or not target_item.is_active
     or target_item.price_coins is null
     or (target_item.available_from is not null and target_item.available_from > now())
     or (target_item.available_until is not null and target_item.available_until <= now()) then
    raise exception using errcode = 'P0002', message = 'Store item is unavailable for coins';
  end if;
  if not target_item.consumable and p_quantity <> 1 then
    raise exception using errcode = '22023', message = 'Non-consumable items can only be purchased once';
  end if;

  select * into target_wallet from public.wallets where user_id = caller.id for update;
  select * into existing_transaction
  from public.wallet_transactions
  where wallet_id = target_wallet.id and idempotency_key = p_idempotency_key;
  if found then
    select * into inventory_row from public.user_inventory
    where user_id = caller.id and store_item_id = target_item.id;
    return jsonb_build_object(
      'duplicate', true,
      'transaction_id', existing_transaction.id,
      'balance', existing_transaction.balance_after,
      'inventory', to_jsonb(inventory_row)
    );
  end if;

  total_price := target_item.price_coins * p_quantity;
  transaction_row := public.post_wallet_transaction(
    caller.id,
    -total_price,
    'spend',
    'store_purchase',
    'store_item',
    target_item.id::text,
    p_idempotency_key,
    jsonb_build_object('sku', target_item.sku::text, 'quantity', p_quantity),
    caller.id
  );

  insert into public.user_inventory(
    user_id, store_item_id, quantity, acquired_via, source_transaction_id
  ) values (
    caller.id, target_item.id, p_quantity, 'coins', transaction_row.id
  )
  on conflict (user_id, store_item_id) do update
  set quantity = case
        when target_item.consumable then public.user_inventory.quantity + excluded.quantity
        else public.user_inventory.quantity
      end,
      status = 'active',
      source_transaction_id = excluded.source_transaction_id
  returning * into inventory_row;

  return jsonb_build_object(
    'duplicate', false,
    'transaction_id', transaction_row.id,
    'balance', transaction_row.balance_after,
    'inventory', to_jsonb(inventory_row)
  );
end;
$$;

create or replace function public.admin_adjust_wallet(
  p_user_id uuid,
  p_amount bigint,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  transaction_row public.wallet_transactions%rowtype;
begin
  caller := public.require_active_user();
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if char_length(coalesce(p_idempotency_key, '')) not between 8 and 120 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;
  transaction_row := public.post_wallet_transaction(
    p_user_id, p_amount, 'admin_adjustment', p_reason,
    'admin', caller.id::text, p_idempotency_key, '{}'::jsonb, caller.id
  );
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
  values (caller.id, 'wallet.adjust', 'wallet', p_user_id::text, to_jsonb(transaction_row));
  return to_jsonb(transaction_row);
end;
$$;

create or replace function public.accept_friend_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_request public.friend_requests%rowtype;
  first_user uuid;
  second_user uuid;
begin
  caller := public.require_active_user();
  select * into target_request from public.friend_requests where id = p_request_id for update;
  if not found or target_request.receiver_id <> caller.id or target_request.status <> 'pending' then
    raise exception using errcode = 'P0001', message = 'Friend request cannot be accepted';
  end if;
  first_user := case when target_request.sender_id::text < target_request.receiver_id::text then target_request.sender_id else target_request.receiver_id end;
  second_user := case when first_user = target_request.sender_id then target_request.receiver_id else target_request.sender_id end;
  insert into public.friends(user_a_id, user_b_id, request_id)
  values (first_user, second_user, target_request.id)
  on conflict (user_a_id, user_b_id) do nothing;
  update public.friend_requests
  set status = 'accepted', responded_at = clock_timestamp()
  where id = target_request.id;
  return jsonb_build_object('request_id', target_request.id, 'friend_user_id', target_request.sender_id, 'status', 'accepted');
end;
$$;

create or replace function public.set_profile_role(p_user_id uuid, p_role public.app_role)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_profile public.profiles%rowtype;
begin
  caller := public.require_active_user();
  if caller.role <> 'super_admin' then
    raise exception using errcode = '42501', message = 'Super admin role required';
  end if;
  if p_user_id = caller.id and p_role <> 'super_admin' then
    raise exception using errcode = 'P0001', message = 'A super admin cannot demote themselves';
  end if;
  update public.profiles set role = p_role where id = p_user_id returning * into target_profile;
  if not found then
    raise exception using errcode = 'P0002', message = 'Profile not found';
  end if;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
  values (caller.id, 'profile.role_changed', 'profile', p_user_id::text, jsonb_build_object('role', p_role));
  return jsonb_build_object('id', target_profile.id, 'role', target_profile.role);
end;
$$;

create or replace function public.moderate_profile(
  p_user_id uuid,
  p_status public.profile_status,
  p_reason text default null,
  p_until timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_profile public.profiles%rowtype;
begin
  caller := public.require_active_user();
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_user_id = caller.id or (select role = 'super_admin' from public.profiles where id = p_user_id) then
    raise exception using errcode = '42501', message = 'Target profile cannot be moderated';
  end if;
  if p_status in ('banned', 'suspended') and nullif(trim(p_reason), '') is null then
    raise exception using errcode = '22023', message = 'A reason is required';
  end if;
  update public.profiles
  set status = p_status,
      ban_reason = case when p_status in ('banned', 'suspended') then trim(p_reason) else null end,
      banned_until = case when p_status in ('banned', 'suspended') then p_until else null end
  where id = p_user_id
  returning * into target_profile;
  if not found then
    raise exception using errcode = 'P0002', message = 'Profile not found';
  end if;
  delete from public.matchmaking_queue where user_id = p_user_id;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
  values (caller.id, 'profile.moderated', 'profile', p_user_id::text,
    jsonb_build_object('status', p_status, 'reason', p_reason, 'until', p_until));
  return jsonb_build_object('id', target_profile.id, 'status', target_profile.status, 'banned_until', target_profile.banned_until);
end;
$$;

create or replace function public.request_account_deletion(p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  request_id uuid;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'request_account_deletion', 2, interval '1 day');
  insert into public.account_deletion_requests(user_id, reason)
  values (caller.id, nullif(trim(p_reason), ''))
  returning id into request_id;
  update public.profiles set status = 'deletion_pending' where id = caller.id;
  delete from public.matchmaking_queue where user_id = caller.id;
  update public.device_tokens set is_active = false where user_id = caller.id;
  return jsonb_build_object('request_id', request_id, 'status', 'requested');
end;
$$;

create or replace function public.validate_import_row_data(
  p_raw_data jsonb,
  p_filename text default '',
  p_category_hint_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  question_text_value text;
  option_values text[];
  correct_value text;
  image_value text;
  normalized_value text;
  question_hash text;
  correct_position integer;
  errors_value jsonb := '[]'::jsonb;
  warnings_value jsonb := '[]'::jsonb;
  category_value uuid;
  subcategory_value uuid;
  confidence_value numeric(5,4) := 0.25;
  duplicate_value uuid;
  similar_values uuid[] := '{}'::uuid[];
  status_value public.import_row_status;
  difficulty_value public.question_difficulty := 'medium'::public.question_difficulty;
  tags_value text[] := '{}'::text[];
  search_text text;
begin
  if auth.uid() is not null and not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  if jsonb_typeof(coalesce(p_raw_data, '{}'::jsonb)) <> 'object' then
    return jsonb_build_object(
      'normalized_data', '{}'::jsonb,
      'errors', jsonb_build_array('row_must_be_an_object'),
      'warnings', '[]'::jsonb,
      'classification', '{}'::jsonb,
      'confidence', 0,
      'status', 'invalid'
    );
  end if;

  question_text_value := trim(coalesce(
    p_raw_data ->> 'question_text', p_raw_data ->> 'question', p_raw_data ->> 'السؤال', ''
  ));
  option_values := array[
    trim(coalesce(p_raw_data ->> 'option_1', p_raw_data ->> 'option1', p_raw_data ->> 'الخيار الأول', '')),
    trim(coalesce(p_raw_data ->> 'option_2', p_raw_data ->> 'option2', p_raw_data ->> 'الخيار الثاني', '')),
    trim(coalesce(p_raw_data ->> 'option_3', p_raw_data ->> 'option3', p_raw_data ->> 'الخيار الثالث', '')),
    trim(coalesce(p_raw_data ->> 'option_4', p_raw_data ->> 'option4', p_raw_data ->> 'الخيار الرابع', ''))
  ];
  correct_value := trim(coalesce(
    p_raw_data ->> 'correct_answer', p_raw_data ->> 'correct', p_raw_data ->> 'الإجابة الصحيحة', ''
  ));
  image_value := nullif(trim(coalesce(
    p_raw_data ->> 'image_url', p_raw_data ->> 'image', p_raw_data ->> 'الصورة - اختياري', p_raw_data ->> 'الصورة', ''
  )), '');

  if char_length(question_text_value) < 5 then
    errors_value := errors_value || jsonb_build_array('question_is_required');
  end if;
  if exists (
    select 1 from unnest(option_values) as options(option_value)
    where options.option_value = ''
  ) then
    errors_value := errors_value || jsonb_build_array('four_options_are_required');
  elsif (
    select count(distinct lower(options.option_value))
    from unnest(option_values) as options(option_value)
  ) <> 4 then
    errors_value := errors_value || jsonb_build_array('options_must_be_unique');
  end if;
  select min(position) into correct_position
  from unnest(option_values) with ordinality options(option_value, position)
  where lower(option_value) = lower(correct_value);
  if correct_position is null then
    errors_value := errors_value || jsonb_build_array('correct_answer_must_match_an_option');
  end if;

  normalized_value := public.normalize_question_text(question_text_value);
  question_hash := encode(extensions.digest(convert_to(normalized_value, 'UTF8'), 'sha256'), 'hex');
  select id into duplicate_value from public.questions
  where content_hash = question_hash and status <> 'archived' limit 1;
  select coalesce(array_agg(similar_rows.id), '{}'::uuid[])
  into similar_values
  from (
    select q.id
    from public.questions q
    where q.status <> 'archived'
      and q.content_hash <> question_hash
      and extensions.similarity(q.normalized_text, normalized_value) >= 0.72
    order by extensions.similarity(q.normalized_text, normalized_value) desc
    limit 5
  ) as similar_rows;

  search_text := lower(concat_ws(' ', question_text_value, p_filename, array_to_string(option_values, ' ')));
  if p_category_hint_id is not null and exists (
    select 1 from public.categories where id = p_category_hint_id and parent_id is null and is_active
  ) then
    category_value := p_category_hint_id;
    confidence_value := 0.98;
  else
    select c.id into category_value
    from public.categories c
    where c.parent_id is null and c.is_active and (
      position(lower(c.name_ar) in search_text) > 0
      or position(lower(c.slug::text) in lower(coalesce(p_filename, ''))) > 0
      or exists (
        select 1 from unnest(c.keywords) as terms(keyword)
        where char_length(terms.keyword) >= 3
          and position(lower(terms.keyword) in search_text) > 0
      )
    )
    order by
      case when position(lower(c.name_ar) in search_text) > 0 then 0 else 1 end,
      c.sort_order
    limit 1;
    if category_value is not null then
      confidence_value := 0.82;
    end if;
  end if;

  if category_value is not null then
    select c.id into subcategory_value
    from public.categories c
    where c.parent_id = category_value and c.is_active and (
      position(lower(c.name_ar) in search_text) > 0
      or exists (
        select 1 from unnest(c.keywords) as terms(keyword)
        where char_length(terms.keyword) >= 3
          and position(lower(terms.keyword) in search_text) > 0
      )
    )
    order by c.sort_order
    limit 1;
  else
    warnings_value := warnings_value || jsonb_build_array('category_needs_manual_review');
  end if;

  if char_length(question_text_value) <= 65 then
    difficulty_value := 'easy';
  elsif char_length(question_text_value) >= 180 then
    difficulty_value := 'hard';
  end if;
  if search_text ~ '(رتب|الترتيب|الموسم|المسيرة)' then
    difficulty_value := 'hard';
  end if;

  if search_text ~ '(ملعب|الملاعب)' then tags_value := array_append(tags_value, 'stadiums'); end if;
  if search_text ~ '(انتقل|انتقال|ناديه السابق)' then tags_value := array_append(tags_value, 'transfers'); end if;
  if search_text ~ '(مدرب|المدربون)' then tags_value := array_append(tags_value, 'coaches'); end if;
  if search_text ~ '(جائزة|الكرة الذهبية|الهداف)' then tags_value := array_append(tags_value, 'awards'); end if;

  if duplicate_value is not null then
    status_value := 'duplicate';
    warnings_value := warnings_value || jsonb_build_array('exact_duplicate');
  elsif jsonb_array_length(errors_value) > 0 then
    status_value := 'invalid';
  elsif category_value is null or confidence_value < 0.75 or cardinality(similar_values) > 0 then
    status_value := 'needs_review';
    if cardinality(similar_values) > 0 then
      warnings_value := warnings_value || jsonb_build_array('similar_questions_found');
    end if;
  else
    status_value := 'valid';
  end if;

  return jsonb_build_object(
    'normalized_data', jsonb_strip_nulls(jsonb_build_object(
      'question_text', question_text_value,
      'question_type', case when image_value is null then 'text' else 'image' end,
      'options', to_jsonb(option_values),
      'correct_option_position', correct_position,
      'image_url', image_value,
      'category_id', category_value,
      'subcategory_id', subcategory_value,
      'difficulty', difficulty_value,
      'tags', to_jsonb(tags_value),
      'suitable_modes', jsonb_build_array('solo', 'quick_1v1', 'friend_1v1', 'team_2v2')
    )),
    'errors', errors_value,
    'warnings', warnings_value,
    'classification', jsonb_strip_nulls(jsonb_build_object(
      'category_id', category_value,
      'subcategory_id', subcategory_value,
      'difficulty', difficulty_value,
      'tags', to_jsonb(tags_value),
      'method', 'rules_keywords_metadata'
    )),
    'confidence', confidence_value,
    'status', status_value,
    'duplicate_question_id', duplicate_value,
    'similar_question_ids', to_jsonb(similar_values)
  );
end;
$$;

create or replace function public.validate_import_batch(p_batch_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_batch public.import_batches%rowtype;
  target_row public.import_rows%rowtype;
  validation_result jsonb;
  count_total integer;
  count_valid integer;
  count_invalid integer;
  count_review integer;
  count_duplicate integer;
begin
  caller := public.require_active_user();
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'validate_import_batch', 20, interval '1 minute');
  select * into target_batch from public.import_batches where id = p_batch_id for update;
  if not found or target_batch.status in ('committing', 'completed', 'cancelled') then
    raise exception using errcode = 'P0001', message = 'Import batch cannot be validated';
  end if;
  update public.import_batches set status = 'validating', error_summary = '{}' where id = target_batch.id;

  for target_row in
    select * from public.import_rows where batch_id = target_batch.id order by row_number for update
  loop
    validation_result := public.validate_import_row_data(
      target_row.raw_data, target_batch.filename, target_batch.category_hint_id
    );
    update public.import_rows
    set normalized_data = validation_result -> 'normalized_data',
        status = (validation_result ->> 'status')::public.import_row_status,
        errors = validation_result -> 'errors',
        warnings = validation_result -> 'warnings',
        classification = validation_result -> 'classification',
        confidence = (validation_result ->> 'confidence')::numeric,
        duplicate_question_id = nullif(validation_result ->> 'duplicate_question_id', '')::uuid,
        similar_question_ids = coalesce(
          array(select jsonb_array_elements_text(validation_result -> 'similar_question_ids')::uuid), '{}'
        )
    where id = target_row.id;
  end loop;

  select
    count(*),
    count(*) filter (where status = 'valid'),
    count(*) filter (where status = 'invalid'),
    count(*) filter (where status = 'needs_review'),
    count(*) filter (where status = 'duplicate')
  into count_total, count_valid, count_invalid, count_review, count_duplicate
  from public.import_rows where batch_id = target_batch.id;

  update public.import_batches
  set total_rows = count_total,
      valid_rows = count_valid,
      invalid_rows = count_invalid,
      review_rows = count_review,
      duplicate_rows = count_duplicate,
      status = case
        when count_invalid = 0 and count_review = 0 then 'ready'::public.import_batch_status
        else 'review'::public.import_batch_status
      end
  where id = target_batch.id;

  return jsonb_build_object(
    'batch_id', target_batch.id,
    'status', case when count_invalid = 0 and count_review = 0 then 'ready' else 'review' end,
    'total_rows', count_total,
    'valid_rows', count_valid,
    'invalid_rows', count_invalid,
    'review_rows', count_review,
    'duplicate_rows', count_duplicate
  );
exception when others then
  update public.import_batches
  set status = 'failed', error_summary = jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  where id = p_batch_id;
  return jsonb_build_object('batch_id', p_batch_id, 'status', 'failed', 'error', sqlerrm, 'sqlstate', sqlstate);
end;
$$;

create or replace function public.commit_import_batch(
  p_batch_id uuid,
  p_publish boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_batch public.import_batches%rowtype;
  target_row public.import_rows%rowtype;
  question_id_value uuid;
  correct_option_id_value uuid;
  option_record record;
  tag_slug text;
  committed_count integer := 0;
  skipped_count integer := 0;
  mode_values public.match_mode[];
begin
  caller := public.require_active_user();
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  select * into target_batch from public.import_batches where id = p_batch_id for update;
  if not found or target_batch.status not in ('ready', 'review') then
    raise exception using errcode = 'P0001', message = 'Import batch is not ready to commit';
  end if;
  update public.import_batches set status = 'committing' where id = target_batch.id;

  for target_row in
    select * from public.import_rows where batch_id = target_batch.id order by row_number for update
  loop
    if target_row.status <> 'valid' then
      skipped_count := skipped_count + 1;
      continue;
    end if;
    if nullif(target_row.normalized_data ->> 'category_id', '') is null then
      raise exception using errcode = '22023', message = format('Row %s has no category', target_row.row_number);
    end if;

    select coalesce(array_agg(mode_text::public.match_mode), array['solo'::public.match_mode])
    into mode_values
    from jsonb_array_elements_text(
      coalesce(target_row.normalized_data -> 'suitable_modes', jsonb_build_array('solo'))
    ) as modes(mode_text);

    insert into public.questions(
      question_text, question_type, image_url, category_id, subcategory_id,
      difficulty, status, needs_review, suitable_modes, created_by, published_at
    ) values (
      target_row.normalized_data ->> 'question_text',
      (target_row.normalized_data ->> 'question_type')::public.question_type,
      nullif(target_row.normalized_data ->> 'image_url', ''),
      (target_row.normalized_data ->> 'category_id')::uuid,
      nullif(target_row.normalized_data ->> 'subcategory_id', '')::uuid,
      coalesce((target_row.normalized_data ->> 'difficulty')::public.question_difficulty, 'medium'),
      case when p_publish then 'published'::public.question_status else 'draft'::public.question_status end,
      false,
      mode_values,
      caller.id,
      case when p_publish then clock_timestamp() else null end
    ) returning id into question_id_value;

    for option_record in
      select option_text, ordinality::smallint as position
      from jsonb_array_elements_text(target_row.normalized_data -> 'options')
        with ordinality options(option_text, ordinality)
    loop
      insert into public.question_options(question_id, option_text, position)
      values (question_id_value, option_record.option_text, option_record.position)
      returning id into correct_option_id_value;
      if option_record.position <> (target_row.normalized_data ->> 'correct_option_position')::smallint then
        correct_option_id_value := null;
      end if;
      if correct_option_id_value is not null then
        update public.questions set correct_option_id = correct_option_id_value where id = question_id_value;
      end if;
    end loop;

    for tag_slug in
      select jsonb_array_elements_text(coalesce(target_row.normalized_data -> 'tags', '[]'::jsonb))
    loop
      insert into public.tags(slug, name_ar)
      values (tag_slug, tag_slug)
      on conflict (slug) do nothing;
      insert into public.question_tags(question_id, tag_id)
      select question_id_value, id from public.tags where slug = tag_slug
      on conflict do nothing;
    end loop;

    update public.import_rows
    set status = 'committed', committed_question_id = question_id_value
    where id = target_row.id;
    committed_count := committed_count + 1;
  end loop;

  if committed_count = 0 then
    raise exception using errcode = 'P0001', message = 'No approved valid rows to commit';
  end if;
  update public.import_batches
  set status = 'completed', committed_by = caller.id, committed_at = clock_timestamp()
  where id = target_batch.id;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data)
  values (caller.id, 'import.committed', 'import_batch', target_batch.id::text,
    jsonb_build_object('committed_rows', committed_count, 'published', p_publish));

  return jsonb_build_object(
    'batch_id', target_batch.id,
    'status', 'completed',
    'committed_rows', committed_count,
    'skipped_rows', skipped_count,
    'published', p_publish
  );
exception when others then
  update public.import_batches
  set status = 'failed', error_summary = jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  where id = p_batch_id;
  return jsonb_build_object('batch_id', p_batch_id, 'status', 'failed', 'error', sqlerrm, 'sqlstate', sqlstate);
end;
$$;

create or replace function public.get_admin_question(p_question_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  result_value jsonb;
begin
  if auth.uid() is null or not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  select to_jsonb(q) || jsonb_build_object(
    'options', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', qo.id,
        'option_text', qo.option_text,
        'position', qo.position,
        'is_correct', qo.id = q.correct_option_id
      ) order by qo.position)
      from public.question_options qo where qo.question_id = q.id
    ), '[]'::jsonb),
    'tags', coalesce((
      select jsonb_agg(t.slug::text order by t.slug::text)
      from public.question_tags qt join public.tags t on t.id = qt.tag_id
      where qt.question_id = q.id
    ), '[]'::jsonb)
  ) into result_value
  from public.questions q where q.id = p_question_id;
  if result_value is null then
    raise exception using errcode = 'P0002', message = 'Question not found';
  end if;
  return result_value;
end;
$$;

create or replace function public.recalculate_question_difficulty(p_question_id uuid default null)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  updated_count integer;
  minimum_sample integer;
begin
  caller := public.require_active_user();
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  minimum_sample := coalesce(
    (select (value #>> '{}')::integer from public.game_settings where key = 'questions.difficulty_min_sample'), 50
  );
  update public.questions
  set difficulty = case
    when correct_answers::numeric / nullif(correct_answers + wrong_answers, 0) >= 0.90 then
      case difficulty when 'expert' then 'hard' when 'hard' then 'medium' else 'easy' end::public.question_difficulty
    when correct_answers::numeric / nullif(correct_answers + wrong_answers, 0) < 0.25 then
      case difficulty when 'easy' then 'medium' when 'medium' then 'hard' else 'expert' end::public.question_difficulty
    else difficulty
  end
  where difficulty_sample_size >= minimum_sample
    and (p_question_id is null or id = p_question_id);
  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

create or replace function public.protect_profile_privileged_fields()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if current_user in ('authenticated', 'anon') and not public.has_role('admin') and (
    new.id is distinct from old.id or
    new.role is distinct from old.role or
    new.status is distinct from old.status or
    new.level is distinct from old.level or
    new.xp is distinct from old.xp or
    new.rating is distinct from old.rating or
    new.banned_until is distinct from old.banned_until or
    new.ban_reason is distinct from old.ban_reason or
    new.is_guest is distinct from old.is_guest
  ) then
    raise exception using errcode = '42501', message = 'Privileged profile fields are server managed';
  end if;
  return new;
end;
$$;

create trigger profiles_protect_privileged_fields
before update on public.profiles
for each row execute function public.protect_profile_privileged_fields();

create or replace function public.protect_notification_update()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if current_user = 'authenticated' and not public.has_role('admin') and (
    new.id is distinct from old.id or
    new.target_user_id is distinct from old.target_user_id or
    new.type is distinct from old.type or
    new.title_ar is distinct from old.title_ar or
    new.body_ar is distinct from old.body_ar or
    new.title_en is distinct from old.title_en or
    new.body_en is distinct from old.body_en or
    new.data is distinct from old.data or
    new.audience is distinct from old.audience or
    new.status is distinct from old.status or
    new.scheduled_at is distinct from old.scheduled_at or
    new.sent_at is distinct from old.sent_at or
    new.created_by is distinct from old.created_by
  ) then
    raise exception using errcode = '42501', message = 'Only read_at may be changed by a recipient';
  end if;
  return new;
end;
$$;

create trigger notifications_protect_update
before update on public.notifications
for each row execute function public.protect_notification_update();

create or replace function public.protect_friend_request_update()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.id is distinct from old.id
     or new.sender_id is distinct from old.sender_id
     or new.receiver_id is distinct from old.receiver_id
     or new.created_at is distinct from old.created_at then
    raise exception using errcode = '42501', message = 'Friend request identity is immutable';
  end if;
  if current_user = 'authenticated' and not public.has_role('moderator') then
    if old.status <> 'pending' or new.status <> 'declined'
       or new.message is distinct from old.message then
      raise exception using errcode = '42501', message = 'Use accept_friend_request() to accept; direct updates may only decline';
    end if;
    new.responded_at := coalesce(new.responded_at, clock_timestamp());
  end if;
  return new;
end;
$$;

create trigger friend_requests_protect_update
before update on public.friend_requests
for each row execute function public.protect_friend_request_update();

revoke all on function public.post_wallet_transaction(uuid, bigint, public.wallet_transaction_type, text, text, text, text, jsonb, uuid) from public, anon, authenticated;
revoke all on function public.finalize_match(uuid) from public, anon, authenticated;

revoke all on function public.purchase_store_item(uuid, integer, text) from public;
revoke all on function public.admin_adjust_wallet(uuid, bigint, text, text) from public;
revoke all on function public.accept_friend_request(uuid) from public;
revoke all on function public.set_profile_role(uuid, public.app_role) from public;
revoke all on function public.moderate_profile(uuid, public.profile_status, text, timestamptz) from public;
revoke all on function public.request_account_deletion(text) from public;
revoke all on function public.validate_import_row_data(jsonb, text, uuid) from public;
revoke all on function public.validate_import_batch(uuid) from public;
revoke all on function public.commit_import_batch(uuid, boolean) from public;
revoke all on function public.get_admin_question(uuid) from public;
revoke all on function public.recalculate_question_difficulty(uuid) from public;

grant execute on function public.purchase_store_item(uuid, integer, text) to authenticated;
grant execute on function public.admin_adjust_wallet(uuid, bigint, text, text) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.set_profile_role(uuid, public.app_role) to authenticated;
grant execute on function public.moderate_profile(uuid, public.profile_status, text, timestamptz) to authenticated;
grant execute on function public.request_account_deletion(text) to authenticated;
grant execute on function public.validate_import_row_data(jsonb, text, uuid) to authenticated;
grant execute on function public.validate_import_batch(uuid) to authenticated;
grant execute on function public.commit_import_batch(uuid, boolean) to authenticated;
grant execute on function public.get_admin_question(uuid) to authenticated;
grant execute on function public.recalculate_question_difficulty(uuid) to authenticated;

comment on function public.purchase_store_item(uuid, integer, text) is
  'Atomic coin purchase with wallet row lock, immutable ledger entry, idempotency, and inventory upsert.';
comment on function public.validate_import_row_data(jsonb, text, uuid) is
  'Rules/keywords/metadata classifier supporting Arabic and canonical headers; no external AI dependency.';
comment on function public.commit_import_batch(uuid, boolean) is
  'Commits only rows explicitly in valid status. needs_review rows must be approved by changing their staged status first.';
