-- Ranked seasons, social graph, room lifecycle, and server-authoritative match records.
create table public.seasons (
  id uuid primary key default gen_random_uuid(),
  slug extensions.citext not null unique,
  name_ar text not null,
  name_en text,
  status public.season_status not null default 'draft',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  rating_reset_factor numeric(5,4) not null default 0.25 check (rating_reset_factor between 0 and 1),
  rewards jsonb not null default '[]'::jsonb check (jsonb_typeof(rewards) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint seasons_valid_window check (ends_at > starts_at)
);

create unique index seasons_one_active_uidx on public.seasons((status)) where status = 'active';

create table public.player_season_stats (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null default 1000 check (rating >= 0),
  matches_played integer not null default 0 check (matches_played >= 0),
  wins integer not null default 0 check (wins >= 0),
  losses integer not null default 0 check (losses >= 0),
  draws integer not null default 0 check (draws >= 0),
  points bigint not null default 0,
  final_rank integer check (final_rank is null or final_rank > 0),
  reward_claimed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (season_id, user_id),
  constraint player_season_stats_totals check (wins + losses + draws <= matches_played)
);

create index player_season_leaderboard_idx
  on public.player_season_stats(season_id, rating desc, wins desc);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status public.friend_request_status not null default 'pending',
  message text check (message is null or char_length(message) <= 200),
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friend_requests_not_self check (sender_id <> receiver_id)
);

create unique index friend_requests_one_pending_uidx
  on public.friend_requests(sender_id, receiver_id)
  where status = 'pending';
create index friend_requests_inbox_idx on public.friend_requests(receiver_id, status, created_at desc);

create table public.friends (
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  request_id uuid references public.friend_requests(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_a_id, user_b_id),
  constraint friends_canonical_order check (user_a_id::text < user_b_id::text)
);

create index friends_user_b_idx on public.friends(user_b_id, created_at desc);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  mode public.match_mode not null,
  status public.match_status not null default 'created',
  season_id uuid references public.seasons(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  category_ids uuid[] not null default '{}',
  question_count smallint not null default 15 check (question_count between 1 and 50),
  current_question_number smallint not null default 0 check (current_question_number >= 0),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  state_version integer not null default 1 check (state_version > 0),
  winner_team public.team_side,
  started_at timestamptz,
  finished_at timestamptz,
  cancelled_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint matches_question_progress check (current_question_number <= question_count),
  constraint matches_finish_consistency check (
    (status not in ('finished', 'cancelled')) or finished_at is not null
  )
);

create index matches_status_created_idx on public.matches(status, created_at desc);
create index matches_season_idx on public.matches(season_id, status);
create index matches_creator_idx on public.matches(created_by, created_at desc);

create table public.match_players (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  system_opponent_id uuid references public.system_opponents(id) on delete set null,
  team public.team_side not null,
  seat smallint not null default 1 check (seat between 1 and 2),
  display_name_snapshot text not null,
  avatar_url_snapshot text,
  status public.match_player_status not null default 'joined',
  score integer not null default 0 check (score >= 0),
  correct_answers integer not null default 0 check (correct_answers >= 0),
  wrong_answers integer not null default 0 check (wrong_answers >= 0),
  total_answer_time_ms bigint not null default 0 check (total_answer_time_ms >= 0),
  rating_before integer check (rating_before is null or rating_before >= 0),
  rating_after integer check (rating_after is null or rating_after >= 0),
  xp_awarded integer not null default 0 check (xp_awarded >= 0),
  coins_awarded integer not null default 0 check (coins_awarded >= 0),
  ready_at timestamptz,
  last_connected_at timestamptz,
  disconnected_at timestamptz,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint match_players_identity check (
    (user_id is not null and system_opponent_id is null)
    or (user_id is null and system_opponent_id is not null)
    or (user_id is null and system_opponent_id is null)
  ),
  unique (match_id, team, seat)
);

create unique index match_players_user_uidx
  on public.match_players(match_id, user_id)
  where user_id is not null;
create index match_players_user_history_idx on public.match_players(user_id, joined_at desc);

create table public.match_questions (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete restrict,
  sequence_number smallint not null check (sequence_number between 1 and 50),
  status public.match_question_status not null default 'queued',
  question_text_snapshot text not null,
  question_type_snapshot public.question_type not null,
  image_url_snapshot text,
  category_id_snapshot uuid not null references public.categories(id) on delete restrict,
  duration_ms integer not null default 15000 check (duration_ms between 3000 and 120000),
  base_score integer not null default 100 check (base_score >= 0),
  max_speed_bonus integer not null default 50 check (max_speed_bonus >= 0),
  opened_at timestamptz,
  closes_at timestamptz,
  revealed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (match_id, sequence_number),
  unique (match_id, question_id),
  constraint match_questions_window check (
    (opened_at is null and closes_at is null)
    or (opened_at is not null and closes_at = opened_at + make_interval(secs => duration_ms / 1000.0))
  ),
  constraint match_questions_reveal check (revealed_at is null or opened_at is not null)
);

create index match_questions_match_status_idx on public.match_questions(match_id, status, sequence_number);

create table public.match_question_options (
  id uuid primary key default gen_random_uuid(),
  match_question_id uuid not null references public.match_questions(id) on delete cascade,
  source_option_id uuid not null references public.question_options(id) on delete restrict,
  option_text_snapshot text not null,
  position smallint not null check (position between 1 and 4),
  created_at timestamptz not null default now(),
  unique (match_question_id, position),
  unique (match_question_id, source_option_id)
);

create index match_question_options_question_idx
  on public.match_question_options(match_question_id, position);

create table public.match_answers (
  id uuid primary key default gen_random_uuid(),
  match_question_id uuid not null references public.match_questions(id) on delete cascade,
  match_player_id uuid not null references public.match_players(id) on delete cascade,
  selected_match_option_id uuid not null references public.match_question_options(id) on delete restrict,
  is_correct boolean not null,
  score_awarded integer not null check (score_awarded >= 0),
  response_time_ms integer not null check (response_time_ms >= 0),
  server_received_at timestamptz not null default clock_timestamp(),
  created_at timestamptz not null default now(),
  unique (match_question_id, match_player_id)
);

create index match_answers_player_idx on public.match_answers(match_player_id, created_at desc);

create table public.match_events (
  id bigint generated always as identity primary key,
  match_id uuid not null references public.matches(id) on delete cascade,
  event_type text not null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  state_version integer not null,
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  created_at timestamptz not null default clock_timestamp()
);

create index match_events_stream_idx on public.match_events(match_id, id);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_user_id uuid not null references public.profiles(id) on delete cascade,
  match_id uuid references public.matches(id) on delete set null unique,
  mode public.match_mode not null check (mode in ('friend_1v1', 'team_2v2')),
  status public.room_status not null default 'open',
  max_members smallint not null check (max_members in (2, 4)),
  category_ids uuid[] not null default '{}',
  question_count smallint not null default 15 check (question_count between 1 and 50),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  expires_at timestamptz not null default (now() + interval '2 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rooms_code_format check (code ~ '^[0-9]{6}$'),
  constraint rooms_capacity_mode check (
    (mode = 'friend_1v1' and max_members = 2)
    or (mode = 'team_2v2' and max_members = 4)
  )
);

create index rooms_host_idx on public.rooms(host_user_id, created_at desc);
create index rooms_open_expiry_idx on public.rooms(status, expires_at) where status = 'open';

create table public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  team public.team_side not null,
  seat smallint not null check (seat between 1 and 2),
  status public.room_member_status not null default 'joined',
  joined_at timestamptz not null default now(),
  ready_at timestamptz,
  last_seen_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id),
  unique (room_id, team, seat)
);

create index room_members_user_idx on public.room_members(user_id, joined_at desc);

create table public.matchmaking_queue (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  mode public.match_mode not null check (mode = 'quick_1v1'),
  rating integer not null check (rating >= 0),
  initial_range integer not null default 100 check (initial_range between 25 and 1000),
  region text,
  category_ids uuid[] not null default '{}',
  enqueued_at timestamptz not null default clock_timestamp(),
  heartbeat_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null default (now() + interval '2 minutes')
);

create index matchmaking_candidate_idx on public.matchmaking_queue(mode, rating, enqueued_at);

create or replace function public.validate_match_status_transition()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'cancelled' and old.status <> 'finished' then
    new.finished_at := coalesce(new.finished_at, clock_timestamp());
    new.state_version := old.state_version + 1;
    return new;
  end if;

  if not (
    (old.status = 'created' and new.status = 'lobby') or
    (old.status = 'lobby' and new.status = 'ready') or
    (old.status = 'ready' and new.status = 'countdown') or
    (old.status = 'countdown' and new.status = 'question') or
    (old.status = 'question' and new.status = 'answers_locked') or
    (old.status = 'answers_locked' and new.status = 'result') or
    (old.status = 'result' and new.status in ('next_question', 'finished')) or
    (old.status = 'next_question' and new.status = 'question')
  ) then
    raise exception using errcode = '23514', message = format('Invalid match state transition: %s -> %s', old.status, new.status);
  end if;

  new.state_version := old.state_version + 1;
  if new.status = 'question' and new.started_at is null then
    new.started_at := clock_timestamp();
  end if;
  if new.status = 'finished' then
    new.finished_at := coalesce(new.finished_at, clock_timestamp());
  end if;
  return new;
end;
$$;

create trigger matches_validate_status
before update of status on public.matches
for each row execute function public.validate_match_status_transition();

create or replace function public.record_answer_aggregates()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  source_question_id uuid;
  player_user_id uuid;
begin
  select mq.question_id, mp.user_id
    into source_question_id, player_user_id
  from public.match_questions mq
  join public.match_players mp on mp.id = new.match_player_id
  where mq.id = new.match_question_id;

  update public.questions
  set times_played = times_played + 1,
      correct_answers = correct_answers + case when new.is_correct then 1 else 0 end,
      wrong_answers = wrong_answers + case when new.is_correct then 0 else 1 end,
      average_answer_time_ms =
        ((coalesce(average_answer_time_ms, 0) * difficulty_sample_size) + new.response_time_ms)
        / (difficulty_sample_size + 1),
      difficulty_sample_size = difficulty_sample_size + 1
  where id = source_question_id;

  if player_user_id is not null then
    insert into public.question_history(
      user_id, question_id, times_seen, correct_count, wrong_count,
      average_answer_time_ms, last_was_correct, first_seen_at, last_seen_at
    ) values (
      player_user_id, source_question_id, 1,
      case when new.is_correct then 1 else 0 end,
      case when new.is_correct then 0 else 1 end,
      new.response_time_ms, new.is_correct, now(), now()
    )
    on conflict (user_id, question_id) do update
    set times_seen = public.question_history.times_seen + 1,
        correct_count = public.question_history.correct_count + case when new.is_correct then 1 else 0 end,
        wrong_count = public.question_history.wrong_count + case when new.is_correct then 0 else 1 end,
        average_answer_time_ms =
          ((coalesce(public.question_history.average_answer_time_ms, 0) * public.question_history.times_seen) + new.response_time_ms)
          / (public.question_history.times_seen + 1),
        last_was_correct = new.is_correct,
        last_seen_at = now();
  end if;
  return new;
end;
$$;

create trigger match_answers_update_aggregates
after insert on public.match_answers
for each row execute function public.record_answer_aggregates();

create trigger seasons_set_updated_at before update on public.seasons
for each row execute function public.set_updated_at();
create trigger player_season_stats_set_updated_at before update on public.player_season_stats
for each row execute function public.set_updated_at();
create trigger friend_requests_set_updated_at before update on public.friend_requests
for each row execute function public.set_updated_at();
create trigger matches_set_updated_at before update on public.matches
for each row execute function public.set_updated_at();
create trigger match_players_set_updated_at before update on public.match_players
for each row execute function public.set_updated_at();
create trigger match_questions_set_updated_at before update on public.match_questions
for each row execute function public.set_updated_at();
create trigger rooms_set_updated_at before update on public.rooms
for each row execute function public.set_updated_at();
create trigger room_members_set_updated_at before update on public.room_members
for each row execute function public.set_updated_at();

comment on table public.match_question_options is
  'Per-match option snapshots. source_option_id is never granted to client roles.';
comment on table public.match_answers is
  'Server-written answer facts. Clients receive delayed results only through get_match_question_result().';
