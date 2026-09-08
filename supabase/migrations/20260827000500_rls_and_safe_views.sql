-- RLS helpers use a fixed search_path and execute as the migration owner to avoid policy recursion.
create or replace function public.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'user'::public.app_role);
$$;

create or replace function public.has_role(required_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select case public.current_app_role()
    when 'super_admin' then true
    when 'admin' then required_role in ('admin', 'moderator', 'user')
    when 'moderator' then required_role in ('moderator', 'user')
    else required_role = 'user'
  end;
$$;

create or replace function public.is_match_participant(target_match_id uuid, target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.match_players
    where match_id = target_match_id and user_id = target_user_id
  );
$$;

create or replace function public.is_room_member(target_room_id uuid, target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.room_members
    where room_id = target_room_id and user_id = target_user_id and status <> 'kicked'
  );
$$;

create or replace function public.owns_wallet(target_wallet_id uuid, target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.wallets where id = target_wallet_id and user_id = target_user_id
  );
$$;

revoke all on function public.current_app_role() from public;
revoke all on function public.has_role(public.app_role) from public;
revoke all on function public.is_match_participant(uuid, uuid) from public;
revoke all on function public.is_room_member(uuid, uuid) from public;
revoke all on function public.owns_wallet(uuid, uuid) from public;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.has_role(public.app_role) to authenticated;
grant execute on function public.current_app_role() to anon;
grant execute on function public.has_role(public.app_role) to anon;
grant execute on function public.is_match_participant(uuid, uuid) to authenticated;
grant execute on function public.is_room_member(uuid, uuid) to authenticated;
grant execute on function public.owns_wallet(uuid, uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.player_stats enable row level security;
alter table public.categories enable row level security;
alter table public.questions enable row level security;
alter table public.question_options enable row level security;
alter table public.tags enable row level security;
alter table public.question_tags enable row level security;
alter table public.question_history enable row level security;
alter table public.system_opponents enable row level security;
alter table public.seasons enable row level security;
alter table public.player_season_stats enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friends enable row level security;
alter table public.matches enable row level security;
alter table public.match_players enable row level security;
alter table public.match_questions enable row level security;
alter table public.match_question_options enable row level security;
alter table public.match_answers enable row level security;
alter table public.match_events enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.matchmaking_queue enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.store_items enable row level security;
alter table public.user_inventory enable row level security;
alter table public.subscriptions enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
alter table public.question_reports enable row level security;
alter table public.import_batches enable row level security;
alter table public.import_rows enable row level security;
alter table public.game_settings enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_read_authenticated on public.profiles
for select to authenticated using (true);
create policy profiles_update_self on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_admin_update on public.profiles
for update to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy player_stats_read on public.player_stats
for select to authenticated using (true);
create policy player_stats_admin_write on public.player_stats
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy categories_public_read on public.categories
for select to anon, authenticated using (is_active or public.has_role('moderator'));
create policy categories_moderator_write on public.categories
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy questions_published_read on public.questions
for select to authenticated using (status = 'published' or public.has_role('moderator'));
create policy questions_moderator_write on public.questions
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy question_options_read on public.question_options
for select to authenticated using (
  exists (
    select 1 from public.questions q
    where q.id = question_id and (q.status = 'published' or public.has_role('moderator'))
  )
);
create policy question_options_moderator_write on public.question_options
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy tags_read on public.tags for select to authenticated using (true);
create policy tags_moderator_write on public.tags
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));
create policy question_tags_read on public.question_tags
for select to authenticated using (
  exists (select 1 from public.questions q where q.id = question_id and (q.status = 'published' or public.has_role('moderator')))
);
create policy question_tags_moderator_write on public.question_tags
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy question_history_owner_read on public.question_history
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));

create policy system_opponents_read on public.system_opponents
for select to authenticated using (is_active or public.has_role('admin'));
create policy system_opponents_admin_write on public.system_opponents
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy seasons_read on public.seasons
for select to authenticated using (status <> 'draft' or public.has_role('admin'));
create policy seasons_admin_write on public.seasons
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy season_stats_read on public.player_season_stats
for select to authenticated using (true);
create policy season_stats_admin_write on public.player_season_stats
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy friend_requests_read_involved on public.friend_requests
for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid() or public.has_role('moderator'));
create policy friend_requests_send on public.friend_requests
for insert to authenticated with check (sender_id = auth.uid() and status = 'pending');
create policy friend_requests_receiver_update on public.friend_requests
for update to authenticated using (receiver_id = auth.uid()) with check (receiver_id = auth.uid());
create policy friend_requests_moderator on public.friend_requests
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));
create policy friends_read_involved on public.friends
for select to authenticated using (user_a_id = auth.uid() or user_b_id = auth.uid() or public.has_role('moderator'));
create policy friends_delete_involved on public.friends
for delete to authenticated using (user_a_id = auth.uid() or user_b_id = auth.uid() or public.has_role('moderator'));

create policy matches_participant_read on public.matches
for select to authenticated using (
  created_by = auth.uid() or public.is_match_participant(id) or public.has_role('moderator')
);
create policy match_players_participant_read on public.match_players
for select to authenticated using (public.is_match_participant(match_id) or public.has_role('moderator'));
create policy match_questions_participant_read on public.match_questions
for select to authenticated using (public.is_match_participant(match_id) or public.has_role('moderator'));
create policy match_question_options_participant_read on public.match_question_options
for select to authenticated using (
  exists (
    select 1 from public.match_questions mq
    where mq.id = match_question_id and (public.is_match_participant(mq.match_id) or public.has_role('moderator'))
  )
);
-- No direct SELECT policy exists on match_answers: delayed result RPC is the only client path.
create policy match_events_participant_read on public.match_events
for select to authenticated using (public.is_match_participant(match_id) or public.has_role('moderator'));

create policy rooms_member_read on public.rooms
for select to authenticated using (
  host_user_id = auth.uid() or public.is_room_member(id) or public.has_role('moderator')
);
create policy room_members_same_room_read on public.room_members
for select to authenticated using (public.is_room_member(room_id) or public.has_role('moderator'));

create policy matchmaking_queue_owner_read on public.matchmaking_queue
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy matchmaking_queue_owner_insert on public.matchmaking_queue
for insert to authenticated with check (user_id = auth.uid());
create policy matchmaking_queue_owner_update on public.matchmaking_queue
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy matchmaking_queue_owner_delete on public.matchmaking_queue
for delete to authenticated using (user_id = auth.uid() or public.has_role('admin'));

create policy wallets_owner_read on public.wallets
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy wallet_transactions_owner_read on public.wallet_transactions
for select to authenticated using (public.owns_wallet(wallet_id) or public.has_role('admin'));

create policy store_items_catalog_read on public.store_items
for select to anon, authenticated using (
  (is_active and (available_from is null or available_from <= now()) and (available_until is null or available_until > now()))
  or public.has_role('admin')
);
create policy store_items_admin_write on public.store_items
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy inventory_owner_read on public.user_inventory
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy subscriptions_owner_read on public.subscriptions
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));

create policy device_tokens_owner_read on public.device_tokens
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy device_tokens_owner_insert on public.device_tokens
for insert to authenticated with check (user_id = auth.uid());
create policy device_tokens_owner_update on public.device_tokens
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy device_tokens_owner_delete on public.device_tokens
for delete to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy notification_preferences_owner_read on public.notification_preferences
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy notification_preferences_owner_update on public.notification_preferences
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_owner_read on public.notifications
for select to authenticated using (target_user_id = auth.uid() or public.has_role('admin'));
create policy notifications_owner_mark_read on public.notifications
for update to authenticated using (target_user_id = auth.uid()) with check (target_user_id = auth.uid());
create policy notifications_admin_write on public.notifications
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy question_reports_owner_read on public.question_reports
for select to authenticated using (reporter_id = auth.uid() or public.has_role('moderator'));
create policy question_reports_owner_insert on public.question_reports
for insert to authenticated with check (reporter_id = auth.uid());
create policy question_reports_moderator_update on public.question_reports
for update to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy import_batches_moderator on public.import_batches
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));
create policy import_rows_moderator on public.import_rows
for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));

create policy game_settings_public_read on public.game_settings
for select to anon, authenticated using (is_public or public.has_role('admin'));
create policy game_settings_admin_write on public.game_settings
for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));

create policy account_deletion_owner_read on public.account_deletion_requests
for select to authenticated using (user_id = auth.uid() or public.has_role('admin'));
create policy account_deletion_owner_insert on public.account_deletion_requests
for insert to authenticated with check (user_id = auth.uid() and status = 'requested');
create policy audit_logs_admin_read on public.audit_logs
for select to authenticated using (public.has_role('admin'));

-- Remove Supabase's broad default grants, then expose only safe columns/actions.
revoke all on all tables in schema public from anon, authenticated;
grant usage on schema public to anon, authenticated;

grant select on public.categories, public.store_items, public.game_settings to anon;

grant select (
  id, username, display_name, avatar_url, role, status, level, xp, rating,
  favorite_club, locale, last_seen_at, created_at, updated_at
) on public.profiles to authenticated;
grant update (username, display_name, avatar_url, favorite_club, locale, timezone, last_seen_at)
  on public.profiles to authenticated;
grant select on public.player_stats to authenticated;

grant select, insert, update, delete on public.categories to authenticated;
revoke select on public.questions from authenticated;
grant select (
  id, question_text, question_type, image_url, category_id, subcategory_id,
  difficulty, season, club, player, competition, country, status, needs_review,
  suitable_modes, times_played, correct_answers, wrong_answers,
  average_answer_time_ms, difficulty_sample_size, created_by, published_at,
  created_at, updated_at
) on public.questions to authenticated;
grant insert, update, delete on public.questions to authenticated;
revoke select on public.question_options from authenticated;
grant select (id, question_id, option_text, position, created_at, updated_at)
  on public.question_options to authenticated;
grant insert, update, delete on public.question_options to authenticated;
grant select, insert, update, delete on public.tags, public.question_tags to authenticated;
grant select on public.question_history, public.system_opponents to authenticated;
grant insert, update, delete on public.system_opponents to authenticated;

grant select, insert, update, delete on public.seasons, public.player_season_stats to authenticated;
grant select, insert, update on public.friend_requests to authenticated;
grant select, delete on public.friends to authenticated;

grant select on public.matches, public.match_players, public.match_events to authenticated;
revoke select on public.match_questions from authenticated;
grant select (
  id, match_id, sequence_number, status, question_text_snapshot,
  question_type_snapshot, image_url_snapshot, category_id_snapshot,
  duration_ms, base_score, max_speed_bonus, opened_at, closes_at,
  revealed_at, created_at, updated_at
) on public.match_questions to authenticated;
revoke select on public.match_question_options from authenticated;
grant select (id, match_question_id, option_text_snapshot, position, created_at)
  on public.match_question_options to authenticated;
grant select on public.rooms, public.room_members to authenticated;
grant select, insert, update, delete on public.matchmaking_queue to authenticated;

grant select on public.wallets, public.wallet_transactions to authenticated;
grant select, insert, update, delete on public.store_items to authenticated;
grant select on public.user_inventory, public.subscriptions to authenticated;
grant select, insert, update, delete on public.device_tokens to authenticated;
grant select on public.notification_preferences to authenticated;
grant update (friend_requests, match_invites, challenges, rewards, season_events, announcements, quiet_hours_start, quiet_hours_end)
  on public.notification_preferences to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
grant insert, update, delete on public.notifications to authenticated;
grant select, insert, update on public.question_reports to authenticated;
grant select, insert, update, delete on public.import_batches, public.import_rows to authenticated;
grant select, insert, update, delete on public.game_settings to authenticated;
grant select, insert on public.account_deletion_requests to authenticated;
grant select on public.audit_logs to authenticated;

create view public.match_question_payloads
with (security_invoker = true)
as
select
  mq.id as match_question_id,
  mq.match_id,
  mq.sequence_number,
  mq.status,
  mq.question_text_snapshot as question_text,
  mq.question_type_snapshot as question_type,
  mq.image_url_snapshot as image_url,
  mq.category_id_snapshot as category_id,
  mq.duration_ms,
  mq.opened_at,
  mq.closes_at,
  coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', mqo.id,
        'text', mqo.option_text_snapshot,
        'position', mqo.position
      ) order by mqo.position
    ) filter (where mqo.id is not null),
    '[]'::jsonb
  ) as options
from public.match_questions mq
left join public.match_question_options mqo on mqo.match_question_id = mq.id
group by mq.id;

grant select on public.match_question_payloads to authenticated;

comment on view public.match_question_payloads is
  'Client-safe online DTO: question/options/timer only. It deliberately contains no answer key or source option ids.';

-- Storage buckets contain owner-uploaded licensed media only.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values
  ('question-media', 'question-media', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy question_media_moderator_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'question-media' and public.has_role('moderator')
);
create policy question_media_moderator_update on storage.objects
for update to authenticated using (
  bucket_id = 'question-media' and public.has_role('moderator')
) with check (
  bucket_id = 'question-media' and public.has_role('moderator')
);
create policy question_media_moderator_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'question-media' and public.has_role('moderator')
);
create policy avatars_owner_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy avatars_owner_update on storage.objects
for update to authenticated using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy avatars_owner_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
);

-- Trigger-only SECURITY DEFINER functions must never be callable as RPCs.
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
revoke all on function public.after_profile_created() from public, anon, authenticated;
revoke all on function public.after_profile_create_wallet() from public, anon, authenticated;
revoke all on function public.apply_wallet_balance() from public, anon, authenticated;
revoke all on function public.record_answer_aggregates() from public, anon, authenticated;
