-- Social football V1: rights-aware football data, private istiraha teams,
-- blocking/moderation, and server-authoritative team challenges.

create table public.football_countries (
  id uuid primary key default gen_random_uuid(),
  provider_name text,
  provider_id text,
  code text not null unique check (code ~ '^[A-Z]{2,3}$'),
  name_ar text not null check (char_length(name_ar) between 2 and 80),
  name_en text not null check (char_length(name_en) between 2 and 80),
  normalized_search text not null default '',
  is_featured boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (provider_name, provider_id)
);

create table public.football_leagues (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.football_countries(id) on delete restrict,
  provider_name text,
  provider_id text,
  name_ar text not null check (char_length(name_ar) between 2 and 100),
  name_en text not null check (char_length(name_en) between 2 and 100),
  short_name text check (short_name is null or char_length(short_name) between 2 and 24),
  normalized_search text not null default '',
  visual_status text not null default 'fallback' check (visual_status in ('fallback', 'custom', 'licensed')),
  logo_url text,
  license_reference text,
  primary_color text check (primary_color is null or primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  secondary_color text check (secondary_color is null or secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  is_featured boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (provider_name, provider_id),
  constraint football_leagues_visual_rights check (
    (visual_status = 'fallback' and logo_url is null)
    or (visual_status = 'custom' and logo_url is not null)
    or (visual_status = 'licensed' and logo_url is not null and nullif(btrim(license_reference), '') is not null)
  )
);

create table public.football_clubs (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.football_leagues(id) on delete restrict,
  provider_name text,
  provider_id text,
  name_ar text not null check (char_length(name_ar) between 2 and 100),
  name_en text not null check (char_length(name_en) between 2 and 100),
  short_name text check (short_name is null or char_length(short_name) between 1 and 24),
  normalized_search text not null default '',
  visual_status text not null default 'fallback' check (visual_status in ('fallback', 'custom', 'licensed')),
  logo_url text,
  license_reference text,
  primary_color text check (primary_color is null or primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  secondary_color text check (secondary_color is null or secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (provider_name, provider_id),
  constraint football_clubs_visual_rights check (
    (visual_status = 'fallback' and logo_url is null)
    or (visual_status = 'custom' and logo_url is not null)
    or (visual_status = 'licensed' and logo_url is not null and nullif(btrim(license_reference), '') is not null)
  )
);

create index football_countries_featured_idx on public.football_countries(is_featured desc, sort_order) where is_active;
create index football_leagues_country_idx on public.football_leagues(country_id, is_featured desc, sort_order) where is_active;
create index football_clubs_league_idx on public.football_clubs(league_id, sort_order, name_ar) where is_active;
create index football_countries_search_idx on public.football_countries using gin (normalized_search extensions.gin_trgm_ops);
create index football_leagues_search_idx on public.football_leagues using gin (normalized_search extensions.gin_trgm_ops);
create index football_clubs_search_idx on public.football_clubs using gin (normalized_search extensions.gin_trgm_ops);

alter table public.profiles
  add column favorite_league_id uuid references public.football_leagues(id) on delete set null,
  add column favorite_club_id uuid references public.football_clubs(id) on delete set null,
  add column show_football_preferences boolean not null default true,
  add column avatar_style text not null default 'player_11' check (avatar_style in ('player_11', 'uploaded')),
  add column avatar_background text not null default 'najdi_dusk' check (avatar_background in ('najdi_dusk', 'stadium_night', 'desert_light')),
  add column avatar_jersey_color text check (avatar_jersey_color is null or avatar_jersey_color ~ '^#[0-9A-Fa-f]{6}$');

create index profiles_favorite_league_idx on public.profiles(favorite_league_id) where favorite_league_id is not null;
create index profiles_favorite_club_idx on public.profiles(favorite_club_id) where favorite_club_id is not null;

create or replace function public.prepare_football_search()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.normalized_search := public.normalize_question_text(concat_ws(
    ' ',
    to_jsonb(new) ->> 'name_ar',
    to_jsonb(new) ->> 'name_en',
    to_jsonb(new) ->> 'short_name'
  ));
  return new;
end;
$$;

create trigger football_countries_prepare_search before insert or update of name_ar, name_en
on public.football_countries for each row execute function public.prepare_football_search();
create trigger football_leagues_prepare_search before insert or update of name_ar, name_en, short_name
on public.football_leagues for each row execute function public.prepare_football_search();
create trigger football_clubs_prepare_search before insert or update of name_ar, name_en, short_name
on public.football_clubs for each row execute function public.prepare_football_search();

create trigger football_countries_set_updated_at before update on public.football_countries
for each row execute function public.set_updated_at();
create trigger football_leagues_set_updated_at before update on public.football_leagues
for each row execute function public.set_updated_at();
create trigger football_clubs_set_updated_at before update on public.football_clubs
for each row execute function public.set_updated_at();

create table public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_not_self check (blocker_id <> blocked_id)
);
create index user_blocks_blocked_idx on public.user_blocks(blocked_id, created_at desc);

create table public.blocked_social_terms (
  id bigint generated always as identity primary key,
  normalized_term text not null unique check (char_length(normalized_term) between 2 and 80),
  reason text,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.social_teams (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 3 and 40),
  normalized_name text not null,
  description text check (description is null or char_length(description) <= 160),
  primary_color text not null default '#B6FF3B' check (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  badge_seed text not null check (char_length(badge_seed) between 1 and 4),
  banner_style text not null default 'najdi_lines' check (banner_style in ('najdi_lines', 'desert_dusk', 'stadium_night')),
  privacy text not null default 'invite_only' check (privacy = 'invite_only'),
  invite_code_hash text not null unique,
  invite_code_rotated_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  moderation_reason text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint social_teams_moderation_consistency check (status = 'active' or moderation_reason is not null)
);
create index social_teams_status_idx on public.social_teams(status, created_at desc);
create index social_teams_name_idx on public.social_teams using gin (normalized_name extensions.gin_trgm_ops);

create table public.social_team_members (
  team_id uuid not null references public.social_teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (team_id, user_id),
  constraint social_team_members_leave_time check (left_at is null or left_at >= joined_at)
);
create unique index social_team_one_owner_uidx on public.social_team_members(team_id) where role = 'owner' and left_at is null;
create unique index social_team_one_active_membership_uidx on public.social_team_members(user_id) where left_at is null;
create index social_team_members_active_idx on public.social_team_members(team_id, joined_at) where left_at is null;

create table public.social_team_invites (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.social_teams(id) on delete cascade,
  invited_user_id uuid not null references public.profiles(id) on delete cascade,
  invited_by uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  constraint social_team_invites_not_self check (invited_user_id <> invited_by),
  constraint social_team_invites_expiry check (expires_at > created_at)
);
create unique index social_team_invites_pending_uidx on public.social_team_invites(team_id, invited_user_id) where status = 'pending';
create index social_team_invites_inbox_idx on public.social_team_invites(invited_user_id, status, created_at desc);

create table public.team_challenges (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.social_teams(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 80),
  description text check (description is null or char_length(description) <= 240),
  category_id uuid references public.categories(id) on delete restrict,
  question_count smallint not null check (question_count between 3 and 15),
  max_attempts smallint not null default 1 check (max_attempts between 1 and 3),
  question_duration_ms integer not null default 15000 check (question_duration_ms between 5000 and 30000),
  scoring_rule text not null default 'accuracy_speed' check (scoring_rule = 'accuracy_speed'),
  artwork_key text not null default 'eye_of_the_falcon' check (artwork_key in ('eye_of_the_falcon', 'saudi_week', 'thursday_challenge')),
  status text not null default 'scheduled' check (status in ('draft', 'scheduled', 'active', 'completed', 'cancelled')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  is_official boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint team_challenges_window check (ends_at > starts_at and ends_at <= starts_at + interval '31 days'),
  constraint team_challenges_scope check ((team_id is null) = is_official)
);
create index team_challenges_team_window_idx on public.team_challenges(team_id, starts_at desc, ends_at desc);
create index team_challenges_official_idx on public.team_challenges(starts_at desc) where is_official;

create table public.team_challenge_questions (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.team_challenges(id) on delete cascade,
  source_question_id uuid not null references public.questions(id) on delete restrict,
  sequence_number smallint not null check (sequence_number between 1 and 15),
  question_text_snapshot text not null,
  question_type_snapshot public.question_type not null,
  image_url_snapshot text,
  category_id_snapshot uuid not null references public.categories(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (challenge_id, sequence_number),
  unique (challenge_id, source_question_id)
);

create table public.team_challenge_options (
  id uuid primary key default gen_random_uuid(),
  challenge_question_id uuid not null references public.team_challenge_questions(id) on delete cascade,
  source_option_id uuid not null references public.question_options(id) on delete restrict,
  option_text_snapshot text not null,
  position smallint not null check (position between 1 and 4),
  is_correct boolean not null,
  created_at timestamptz not null default now(),
  unique (challenge_question_id, position),
  unique (challenge_question_id, source_option_id)
);
create unique index team_challenge_one_correct_uidx on public.team_challenge_options(challenge_question_id) where is_correct;

create table public.team_challenge_attempts (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.team_challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  attempt_number smallint not null check (attempt_number between 1 and 3),
  status text not null default 'active' check (status in ('active', 'completed', 'expired', 'abandoned')),
  current_sequence smallint not null default 1 check (current_sequence between 1 and 15),
  question_opened_at timestamptz not null default clock_timestamp(),
  score integer not null default 0 check (score >= 0),
  correct_answers smallint not null default 0 check (correct_answers >= 0),
  wrong_answers smallint not null default 0 check (wrong_answers >= 0),
  total_response_time_ms bigint not null default 0 check (total_response_time_ms >= 0),
  started_at timestamptz not null default clock_timestamp(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (challenge_id, user_id, attempt_number),
  constraint team_challenge_attempt_completion check ((status = 'completed') = (completed_at is not null))
);
create index team_challenge_attempt_rank_idx on public.team_challenge_attempts(challenge_id, score desc, total_response_time_ms, completed_at) where status = 'completed';
create index team_challenge_attempt_user_idx on public.team_challenge_attempts(user_id, created_at desc);

create table public.team_challenge_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.team_challenge_attempts(id) on delete cascade,
  challenge_question_id uuid not null references public.team_challenge_questions(id) on delete cascade,
  selected_option_id uuid references public.team_challenge_options(id) on delete restrict,
  is_correct boolean not null,
  score_awarded integer not null check (score_awarded >= 0),
  response_time_ms integer not null check (response_time_ms >= 0),
  server_received_at timestamptz not null default clock_timestamp(),
  unique (attempt_id, challenge_question_id)
);

create table public.social_team_activity_events (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.social_teams(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null check (event_type in ('team_created', 'member_joined', 'member_left', 'challenge_created', 'challenge_won', 'weekly_mvp')),
  safe_data jsonb not null default '{}'::jsonb check (jsonb_typeof(safe_data) = 'object'),
  created_at timestamptz not null default now()
);
create index social_team_activity_idx on public.social_team_activity_events(team_id, created_at desc);

create table public.social_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  subject_type text not null check (subject_type in ('user', 'team')),
  subject_id uuid not null,
  reason text not null check (reason in ('abuse', 'spam', 'unsafe_name', 'unsafe_banner', 'impersonation', 'other')),
  details text check (details is null or char_length(details) <= 800),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index social_reports_status_idx on public.social_reports(status, created_at desc);
create index social_reports_reporter_idx on public.social_reports(reporter_id, created_at desc);

create table public.achievement_definitions (
  id uuid primary key default gen_random_uuid(),
  slug extensions.citext not null unique,
  name_ar text not null,
  description_ar text not null,
  artwork_key text not null,
  rule_key text not null,
  threshold integer not null check (threshold > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_achievements (
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievement_definitions(id) on delete restrict,
  source_type text not null check (source_type in ('match', 'challenge', 'weekly_mvp', 'system')),
  source_id uuid,
  awarded_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

alter table public.notification_preferences
  add column teams boolean not null default true,
  add column promotions boolean not null default false;

insert into public.achievement_definitions(slug, name_ar, description_ar, artwork_key, rule_key, threshold, sort_order)
values
  ('social_captain', 'راعي الاستراحة', 'أنشأ فريق استراحة خاص لأول مرة.', 'social_captain', 'social_team_created', 1, 10),
  ('first_team_challenge', 'دخل التحدي', 'أكمل أول تحدٍ موثق لفريق الاستراحة.', 'first_win', 'team_challenge_completed', 1, 20),
  ('perfect_five', 'خمسة على خمسة', 'أكمل تحديًا من خمسة أسئلة أو أكثر بلا إجابة خاطئة.', 'streak', 'perfect_team_challenge', 5, 30)
on conflict (slug) do update set
  name_ar = excluded.name_ar,
  description_ar = excluded.description_ar,
  artwork_key = excluded.artwork_key,
  rule_key = excluded.rule_key,
  threshold = excluded.threshold,
  sort_order = excluded.sort_order;

create or replace function public.award_player_achievement(
  p_user_id uuid,
  p_slug text,
  p_source_type text,
  p_source_id uuid default null
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare definition_id uuid; affected integer;
begin
  select id into definition_id from public.achievement_definitions
  where slug = p_slug and is_active;
  if definition_id is null then return false; end if;
  insert into public.player_achievements(user_id, achievement_id, source_type, source_id)
  values (p_user_id, definition_id, p_source_type, p_source_id)
  on conflict do nothing;
  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

create trigger social_teams_set_updated_at before update on public.social_teams
for each row execute function public.set_updated_at();
create trigger team_challenges_set_updated_at before update on public.team_challenges
for each row execute function public.set_updated_at();
create trigger social_reports_set_updated_at before update on public.social_reports
for each row execute function public.set_updated_at();
create trigger achievement_definitions_set_updated_at before update on public.achievement_definitions
for each row execute function public.set_updated_at();

create or replace function public.social_text_is_allowed(p_value text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select nullif(btrim(p_value), '') is not null
    and p_value !~ E'[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]'
    and not exists (
      select 1 from public.blocked_social_terms term
      where term.is_active
        and public.normalize_question_text(p_value) like '%' || term.normalized_term || '%'
    );
$$;

create or replace function public.is_social_team_member(p_team_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.social_team_members member
    join public.social_teams team on team.id = member.team_id
    where member.team_id = p_team_id and member.user_id = p_user_id
      and member.left_at is null and team.status = 'active'
  );
$$;

create or replace function public.has_social_team_role(p_team_id uuid, p_user_id uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.social_team_members member
    join public.social_teams team on team.id = member.team_id
    where member.team_id = p_team_id and member.user_id = p_user_id
      and member.left_at is null and member.role = any(p_roles) and team.status = 'active'
  );
$$;

create or replace function public.list_football_leagues(p_country_id uuid default null)
returns table(
  id uuid, country_id uuid, country_name_ar text, name_ar text, name_en text,
  short_name text, badge_text text, logo_url text, visual_status text,
  primary_color text, secondary_color text, is_featured boolean
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select league.id, league.country_id, country.name_ar, league.name_ar, league.name_en,
    league.short_name, upper(left(coalesce(league.short_name, league.name_en), 3)),
    case when league.visual_status in ('licensed', 'custom') then league.logo_url else null end,
    league.visual_status, league.primary_color, league.secondary_color, league.is_featured
  from public.football_leagues league
  join public.football_countries country on country.id = league.country_id
  where league.is_active and country.is_active
    and (p_country_id is null or league.country_id = p_country_id)
  order by country.is_featured desc, league.is_featured desc, league.sort_order, league.name_ar;
$$;

create or replace function public.search_football_clubs(
  p_query text default null,
  p_league_id uuid default null,
  p_limit integer default 24,
  p_offset integer default 0
)
returns table(
  id uuid, league_id uuid, league_name_ar text, country_name_ar text,
  name_ar text, name_en text, short_name text, badge_text text, logo_url text,
  visual_status text, primary_color text, secondary_color text
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  normalized_query text := public.normalize_question_text(p_query);
begin
  return query
  select club.id, club.league_id, league.name_ar, country.name_ar,
    club.name_ar, club.name_en, club.short_name,
    upper(left(coalesce(club.short_name, club.name_en), 3)),
    case when club.visual_status in ('licensed', 'custom') then club.logo_url else null end,
    club.visual_status, club.primary_color, club.secondary_color
  from public.football_clubs club
  join public.football_leagues league on league.id = club.league_id
  join public.football_countries country on country.id = league.country_id
  where club.is_active and league.is_active and country.is_active
    and (p_league_id is null or club.league_id = p_league_id)
    and (normalized_query = '' or club.normalized_search % normalized_query or club.normalized_search like '%' || normalized_query || '%')
  order by
    country.is_featured desc,
    league.is_featured desc,
    case when normalized_query = '' then 0 else extensions.similarity(club.normalized_search, normalized_query) end desc,
    club.sort_order,
    club.name_ar
  limit greatest(1, least(coalesce(p_limit, 24), 50))
  offset greatest(0, coalesce(p_offset, 0));
end;
$$;

create or replace function public.set_football_preferences(
  p_league_id uuid default null,
  p_club_id uuid default null,
  p_show_publicly boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_club public.football_clubs%rowtype;
  target_league public.football_leagues%rowtype;
begin
  caller := public.require_active_user();
  if p_club_id is not null then
    select * into target_club from public.football_clubs where id = p_club_id and is_active;
    if not found then raise exception using errcode = 'P0002', message = 'Club not found'; end if;
    if p_league_id is not null and target_club.league_id <> p_league_id then
      raise exception using errcode = '22023', message = 'Club does not belong to league';
    end if;
    p_league_id := target_club.league_id;
  end if;
  if p_league_id is not null then
    select * into target_league from public.football_leagues where id = p_league_id and is_active;
    if not found then raise exception using errcode = 'P0002', message = 'League not found'; end if;
  end if;
  update public.profiles
  set favorite_league_id = p_league_id,
      favorite_club_id = p_club_id,
      favorite_club = target_club.name_ar,
      show_football_preferences = coalesce(p_show_publicly, true)
  where id = caller.id;
  return jsonb_build_object('league_id', p_league_id, 'club_id', p_club_id, 'show_publicly', coalesce(p_show_publicly, true));
end;
$$;

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
  favorite_league jsonb;
  favorite_club_data jsonb;
  social_team jsonb;
  achievements jsonb;
begin
  caller := public.require_active_user();
  select * into stats from public.player_stats where user_id = caller.id;
  select coalesce((select wallet.balance from public.wallets wallet where wallet.user_id = caller.id), 0) into coin_balance;
  select count(*)::integer + 1 into leaderboard_rank from public.profiles profile
  where profile.status = 'active' and profile.rating > caller.rating;
  select exists (
    select 1 from public.subscriptions subscription
    where subscription.user_id = caller.id and subscription.status in ('trialing', 'active', 'grace_period')
      and (subscription.current_period_ends_at is null or subscription.current_period_ends_at > clock_timestamp())
  ) into premium_active;
  answer_total := coalesce(stats.correct_answers, 0) + coalesce(stats.wrong_answers, 0);
  select jsonb_build_object('id', league.id, 'name_ar', league.name_ar, 'name_en', league.name_en,
    'primary_color', league.primary_color, 'visual_status', league.visual_status)
  into favorite_league from public.football_leagues league where league.id = caller.favorite_league_id;
  select jsonb_build_object('id', club.id, 'league_id', club.league_id, 'name_ar', club.name_ar, 'name_en', club.name_en,
    'badge_text', upper(left(coalesce(club.short_name, club.name_en), 3)),
    'logo_url', case when club.visual_status in ('licensed', 'custom') then club.logo_url else null end,
    'visual_status', club.visual_status, 'primary_color', club.primary_color)
  into favorite_club_data from public.football_clubs club where club.id = caller.favorite_club_id;
  select jsonb_build_object('id', team.id, 'name', team.name, 'primary_color', team.primary_color,
    'badge_seed', team.badge_seed, 'role', member.role)
  into social_team from public.social_team_members member join public.social_teams team on team.id = member.team_id
  where member.user_id = caller.id and member.left_at is null and team.status = 'active';
  select coalesce(jsonb_agg(jsonb_build_object('slug', definition.slug, 'name_ar', definition.name_ar,
    'description_ar', definition.description_ar, 'artwork_key', definition.artwork_key, 'awarded_at', award.awarded_at)
    order by award.awarded_at desc), '[]'::jsonb)
  into achievements from public.player_achievements award
  join public.achievement_definitions definition on definition.id = award.achievement_id
  where award.user_id = caller.id and definition.is_active;
  return jsonb_build_object(
    'id', caller.id, 'username', caller.username, 'display_name', caller.display_name,
    'level', caller.level, 'xp', caller.xp, 'coins', coin_balance, 'rating', caller.rating,
    'wins', coalesce(stats.wins, 0), 'losses', coalesce(stats.losses, 0), 'draws', coalesce(stats.draws, 0),
    'matches', coalesce(stats.matches_played, 0), 'correct_answers', coalesce(stats.correct_answers, 0),
    'accuracy', case when answer_total = 0 then 0 else coalesce(stats.correct_answers, 0)::numeric / answer_total end,
    'best_streak', coalesce(stats.best_streak, 0), 'current_streak', coalesce(stats.current_streak, 0),
    'rank', leaderboard_rank, 'favorite_club', caller.favorite_club,
    'favorite_league_data', favorite_league,
    'favorite_club_data', case when caller.show_football_preferences then favorite_club_data else null end,
    'show_football_preferences', caller.show_football_preferences,
    'avatar_url', caller.avatar_url, 'avatar_style', caller.avatar_style,
    'avatar_background', caller.avatar_background,
    'avatar_jersey_color', coalesce(
      social_team ->> 'primary_color',
      favorite_club_data ->> 'primary_color',
      caller.avatar_jersey_color,
      '#B6FF3B'
    ),
    'social_team', social_team, 'achievements', achievements, 'is_premium', premium_active
  );
end;
$$;

create or replace function public.block_player(p_blocked_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; shared_team_id uuid; caller_team_role text;
begin
  caller := public.require_active_user();
  if p_blocked_user_id = caller.id then raise exception using errcode = '22023', message = 'Cannot block yourself'; end if;
  perform public.assert_rate_limit(caller.id::text, 'block_player', 30, interval '1 day');
  if not exists (select 1 from public.profiles where id = p_blocked_user_id) then
    raise exception using errcode = 'P0002', message = 'Player not found';
  end if;
  insert into public.user_blocks(blocker_id, blocked_id) values (caller.id, p_blocked_user_id)
  on conflict do nothing;
  delete from public.friends
  where (user_a_id = caller.id and user_b_id = p_blocked_user_id)
     or (user_b_id = caller.id and user_a_id = p_blocked_user_id);
  update public.friend_requests set status = 'cancelled', responded_at = clock_timestamp()
  where status = 'pending' and ((sender_id = caller.id and receiver_id = p_blocked_user_id)
    or (receiver_id = caller.id and sender_id = p_blocked_user_id));
  update public.social_team_invites set status = 'cancelled', responded_at = clock_timestamp()
  where status = 'pending' and ((invited_user_id = caller.id and invited_by = p_blocked_user_id)
    or (invited_user_id = p_blocked_user_id and invited_by = caller.id));
  select mine.team_id, mine.role into shared_team_id, caller_team_role
  from public.social_team_members mine
  join public.social_team_members other_member on other_member.team_id = mine.team_id
  where mine.user_id = caller.id and mine.left_at is null
    and other_member.user_id = p_blocked_user_id and other_member.left_at is null
  limit 1;
  if shared_team_id is not null then
    if caller_team_role = 'owner' then
      update public.social_team_members set left_at = clock_timestamp()
      where team_id = shared_team_id and user_id = p_blocked_user_id and left_at is null;
      insert into public.social_team_activity_events(team_id, actor_user_id, event_type)
      values (shared_team_id, p_blocked_user_id, 'member_left');
    else
      update public.social_team_members set left_at = clock_timestamp()
      where team_id = shared_team_id and user_id = caller.id and left_at is null;
      insert into public.social_team_activity_events(team_id, actor_user_id, event_type)
      values (shared_team_id, caller.id, 'member_left');
    end if;
  end if;
  return true;
end;
$$;

create or replace function public.unblock_player(p_blocked_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare affected integer;
begin
  perform public.require_active_user();
  delete from public.user_blocks where blocker_id = auth.uid() and blocked_id = p_blocked_user_id;
  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

create or replace function public.get_blocked_players()
returns table(user_id uuid, username text, display_name text, avatar_url text, blocked_at timestamptz)
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype;
begin
  caller := public.require_active_user();
  return query
  select profile.id, profile.username::text, profile.display_name, profile.avatar_url, block.created_at
  from public.user_blocks block
  join public.profiles profile on profile.id = block.blocked_id
  where block.blocker_id = caller.id
  order by block.created_at desc;
end;
$$;

create or replace function public.report_social_subject(
  p_subject_type text,
  p_subject_id uuid,
  p_reason text,
  p_details text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; report_id uuid; clean_details text;
begin
  caller := public.require_active_user();
  if p_subject_type not in ('user', 'team') or p_reason not in ('abuse', 'spam', 'unsafe_name', 'unsafe_banner', 'impersonation', 'other') then
    raise exception using errcode = '22023', message = 'Invalid social report';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'social_report', 8, interval '1 day');
  if p_subject_type = 'user' and (p_subject_id = caller.id or not exists (select 1 from public.profiles where id = p_subject_id)) then
    raise exception using errcode = '22023', message = 'Invalid reported player';
  end if;
  if p_subject_type = 'team' and not exists (select 1 from public.social_teams where id = p_subject_id) then
    raise exception using errcode = 'P0002', message = 'Team not found';
  end if;
  clean_details := public.sanitize_app_error_text(p_details, 800);
  insert into public.social_reports(reporter_id, subject_type, subject_id, reason, details)
  values (caller.id, p_subject_type, p_subject_id, p_reason, clean_details)
  returning id into report_id;
  return report_id;
end;
$$;

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
  select profile.id, profile.username::text, profile.display_name, profile.avatar_url,
    profile.level, profile.rating,
    case
      when exists (select 1 from public.friends friendship where
        (friendship.user_a_id = caller.id and friendship.user_b_id = profile.id)
        or (friendship.user_b_id = caller.id and friendship.user_a_id = profile.id)) then 'friend'
      when exists (select 1 from public.friend_requests request where
        request.sender_id = caller.id and request.receiver_id = profile.id and request.status = 'pending') then 'pending_sent'
      when exists (select 1 from public.friend_requests request where
        request.receiver_id = caller.id and request.sender_id = profile.id and request.status = 'pending') then 'pending_received'
      else 'none'
    end
  from public.profiles profile
  where profile.id <> caller.id and profile.status = 'active'
    and not exists (select 1 from public.user_blocks block where
      (block.blocker_id = caller.id and block.blocked_id = profile.id)
      or (block.blocked_id = caller.id and block.blocker_id = profile.id))
    and (profile.username::text ilike '%' || normalized_query || '%'
      or profile.display_name ilike '%' || normalized_query || '%')
  order by case when lower(profile.username::text) = lower(normalized_query) then 0 else 1 end,
    extensions.similarity(profile.username::text, normalized_query) desc, profile.rating desc
  limit greatest(1, least(coalesce(p_limit, 20), 30));
end;
$$;

create or replace function public.send_friend_request(p_receiver_id uuid, p_message text default null)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; receiver public.profiles%rowtype; request_id uuid;
begin
  caller := public.require_active_user();
  if p_receiver_id = caller.id then raise exception using errcode = '22023', message = 'Cannot add yourself'; end if;
  perform public.assert_rate_limit(caller.id::text, 'send_friend_request', 30, interval '1 day');
  if exists (select 1 from public.user_blocks block where (block.blocker_id = caller.id and block.blocked_id = p_receiver_id) or (block.blocker_id = p_receiver_id and block.blocked_id = caller.id)) then
    raise exception using errcode = '42501', message = 'Friend interaction is unavailable';
  end if;
  select * into receiver from public.profiles where id = p_receiver_id and status = 'active';
  if not found then raise exception using errcode = 'P0002', message = 'Player not found'; end if;
  if exists (select 1 from public.friends friendship where (friendship.user_a_id = caller.id and friendship.user_b_id = receiver.id) or (friendship.user_b_id = caller.id and friendship.user_a_id = receiver.id)) then
    raise exception using errcode = '23505', message = 'Players are already friends';
  end if;
  if exists (select 1 from public.friend_requests request where request.status = 'pending' and ((request.sender_id = caller.id and request.receiver_id = receiver.id) or (request.receiver_id = caller.id and request.sender_id = receiver.id))) then
    raise exception using errcode = '23505', message = 'A friend request is already pending';
  end if;
  insert into public.friend_requests(sender_id, receiver_id, message)
  values (caller.id, receiver.id, nullif(trim(p_message), '')) returning id into request_id;
  insert into public.notifications(target_user_id, type, title_ar, body_ar, data, status)
  values (receiver.id, 'friend_request', 'خويك أرسل طلب', caller.display_name || ' يبي يضيفك عند ربعه.', jsonb_build_object('request_id', request_id, 'sender_id', caller.id, 'deep_link', '/friends'), 'queued');
  return jsonb_build_object('request_id', request_id, 'status', 'pending');
end;
$$;

create or replace function public.create_social_team(
  p_name text,
  p_description text default null,
  p_primary_color text default '#B6FF3B',
  p_banner_style text default 'najdi_lines'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare caller public.profiles%rowtype; team_id uuid; invite_code text; clean_name text; clean_description text;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'create_social_team', 3, interval '30 days');
  if exists (select 1 from public.social_team_members where user_id = caller.id and left_at is null) then
    raise exception using errcode = '23505', message = 'Player already belongs to a team';
  end if;
  clean_name := btrim(regexp_replace(coalesce(p_name, ''), '[[:space:]]+', ' ', 'g'));
  clean_description := public.sanitize_app_error_text(p_description, 160);
  if char_length(clean_name) not between 3 and 40 or not public.social_text_is_allowed(clean_name) then
    raise exception using errcode = '22023', message = 'Team name is not allowed';
  end if;
  if clean_description is not null and not public.social_text_is_allowed(clean_description) then
    raise exception using errcode = '22023', message = 'Team description is not allowed';
  end if;
  if p_primary_color !~ '^#[0-9A-Fa-f]{6}$' or p_banner_style not in ('najdi_lines', 'desert_dusk', 'stadium_night') then
    raise exception using errcode = '22023', message = 'Invalid team appearance';
  end if;
  invite_code := upper(substr(encode(extensions.gen_random_bytes(8), 'hex'), 1, 8));
  insert into public.social_teams(name, normalized_name, description, primary_color, badge_seed, banner_style, invite_code_hash, created_by)
  values (clean_name, public.normalize_question_text(clean_name), clean_description, upper(p_primary_color), upper(left(clean_name, 2)), p_banner_style,
    encode(extensions.digest(convert_to(invite_code, 'UTF8'), 'sha256'), 'hex'), caller.id)
  returning id into team_id;
  insert into public.social_team_members(team_id, user_id, role) values (team_id, caller.id, 'owner');
  insert into public.social_team_activity_events(team_id, actor_user_id, event_type) values (team_id, caller.id, 'team_created');
  perform public.award_player_achievement(caller.id, 'social_captain', 'system', team_id);
  return jsonb_build_object('team_id', team_id, 'invite_code', invite_code);
end;
$$;

create or replace function public.rotate_social_team_code(p_team_id uuid)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare caller public.profiles%rowtype; invite_code text;
begin
  caller := public.require_active_user();
  if not public.has_social_team_role(p_team_id, caller.id, array['owner', 'admin']) then
    raise exception using errcode = '42501', message = 'Team admin permission required';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'rotate_team_code', 5, interval '1 day');
  invite_code := upper(substr(encode(extensions.gen_random_bytes(8), 'hex'), 1, 8));
  update public.social_teams set invite_code_hash = encode(extensions.digest(convert_to(invite_code, 'UTF8'), 'sha256'), 'hex'), invite_code_rotated_at = clock_timestamp()
  where id = p_team_id;
  return invite_code;
end;
$$;

create or replace function public.join_social_team(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare caller public.profiles%rowtype; target_team public.social_teams%rowtype; code_hash text;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'join_social_team', 12, interval '1 hour');
  if exists (select 1 from public.social_team_members where user_id = caller.id and left_at is null) then
    raise exception using errcode = '23505', message = 'Player already belongs to a team';
  end if;
  code_hash := encode(extensions.digest(convert_to(upper(btrim(coalesce(p_invite_code, ''))), 'UTF8'), 'sha256'), 'hex');
  select * into target_team from public.social_teams where invite_code_hash = code_hash and status = 'active' for update;
  if not found then raise exception using errcode = 'P0002', message = 'Invite code is invalid'; end if;
  if exists (select 1 from public.user_blocks block join public.social_team_members member on member.team_id = target_team.id and member.left_at is null where (block.blocker_id = caller.id and block.blocked_id = member.user_id) or (block.blocked_id = caller.id and block.blocker_id = member.user_id)) then
    raise exception using errcode = '42501', message = 'Team interaction is unavailable';
  end if;
  insert into public.social_team_members(team_id, user_id, role) values (target_team.id, caller.id, 'member')
  on conflict (team_id, user_id) do update set role = 'member', joined_at = clock_timestamp(), left_at = null;
  insert into public.social_team_activity_events(team_id, actor_user_id, event_type, safe_data)
  values (target_team.id, caller.id, 'member_joined', jsonb_build_object('display_name', caller.display_name));
  return jsonb_build_object('team_id', target_team.id, 'team_name', target_team.name);
end;
$$;

create or replace function public.invite_friend_to_social_team(p_team_id uuid, p_friend_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; target_team public.social_teams%rowtype; invite_id uuid;
begin
  caller := public.require_active_user();
  if not public.has_social_team_role(p_team_id, caller.id, array['owner', 'admin']) then raise exception using errcode = '42501', message = 'Team admin permission required'; end if;
  perform public.assert_rate_limit(caller.id::text, 'invite_friend_to_social_team', 30, interval '1 day');
  if exists (select 1 from public.user_blocks block where (block.blocker_id = caller.id and block.blocked_id = p_friend_user_id) or (block.blocked_id = caller.id and block.blocker_id = p_friend_user_id)) then
    raise exception using errcode = '42501', message = 'Team interaction is unavailable';
  end if;
  if not exists (select 1 from public.friends friendship where (friendship.user_a_id = caller.id and friendship.user_b_id = p_friend_user_id) or (friendship.user_b_id = caller.id and friendship.user_a_id = p_friend_user_id)) then
    raise exception using errcode = '42501', message = 'Only friends can be invited';
  end if;
  if exists (select 1 from public.social_team_members where user_id = p_friend_user_id and left_at is null) then
    raise exception using errcode = '23505', message = 'Player already belongs to a team';
  end if;
  select * into target_team from public.social_teams where id = p_team_id and status = 'active';
  insert into public.social_team_invites(team_id, invited_user_id, invited_by)
  values (p_team_id, p_friend_user_id, caller.id) returning id into invite_id;
  insert into public.notifications(target_user_id, type, title_ar, body_ar, data, status)
  values (p_friend_user_id, 'challenge', 'فريق الاستراحة يناديك', caller.display_name || ' دعاك تنضم إلى ' || target_team.name,
    jsonb_build_object('social_event', 'team_invite', 'team_id', p_team_id, 'invite_id', invite_id, 'deep_link', '/teams'), 'queued');
  return jsonb_build_object('invite_id', invite_id, 'status', 'pending');
end;
$$;

create or replace function public.respond_social_team_invite(p_invite_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; target_invite public.social_team_invites%rowtype;
begin
  caller := public.require_active_user();
  select * into target_invite from public.social_team_invites where id = p_invite_id for update;
  if not found or target_invite.invited_user_id <> caller.id or target_invite.status <> 'pending' then
    raise exception using errcode = '42501', message = 'Team invite is unavailable';
  end if;
  if target_invite.expires_at <= clock_timestamp() then
    update public.social_team_invites set status = 'expired', responded_at = clock_timestamp() where id = p_invite_id;
    return jsonb_build_object('status', 'expired');
  end if;
  if not p_accept then
    update public.social_team_invites set status = 'declined', responded_at = clock_timestamp() where id = p_invite_id;
    return jsonb_build_object('status', 'declined');
  end if;
  if exists (select 1 from public.social_team_members where user_id = caller.id and left_at is null) then raise exception using errcode = '23505', message = 'Player already belongs to a team'; end if;
  if exists (select 1 from public.user_blocks block where (block.blocker_id = caller.id and block.blocked_id = target_invite.invited_by) or (block.blocked_id = caller.id and block.blocker_id = target_invite.invited_by)) then raise exception using errcode = '42501', message = 'Team interaction is unavailable'; end if;
  insert into public.social_team_members(team_id, user_id, role) values (target_invite.team_id, caller.id, 'member')
  on conflict (team_id, user_id) do update set role = 'member', joined_at = clock_timestamp(), left_at = null;
  update public.social_team_invites set status = 'accepted', responded_at = clock_timestamp() where id = p_invite_id;
  insert into public.social_team_activity_events(team_id, actor_user_id, event_type, safe_data)
  values (target_invite.team_id, caller.id, 'member_joined', jsonb_build_object('display_name', caller.display_name));
  return jsonb_build_object('status', 'accepted', 'team_id', target_invite.team_id);
end;
$$;

create or replace function public.remove_social_team_member(p_team_id uuid, p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; caller_role text; target_role text;
begin
  caller := public.require_active_user();
  select role into caller_role from public.social_team_members where team_id = p_team_id and user_id = caller.id and left_at is null;
  select role into target_role from public.social_team_members where team_id = p_team_id and user_id = p_user_id and left_at is null for update;
  if target_role is null then raise exception using errcode = 'P0002', message = 'Team member not found'; end if;
  if target_role = 'owner' then raise exception using errcode = '42501', message = 'Team owner cannot leave or be removed'; end if;
  if p_user_id <> caller.id and caller_role not in ('owner', 'admin') then raise exception using errcode = '42501', message = 'Team admin permission required'; end if;
  if target_role = 'admin' and caller_role <> 'owner' then raise exception using errcode = '42501', message = 'Only owner can remove an admin'; end if;
  update public.social_team_members set left_at = clock_timestamp() where team_id = p_team_id and user_id = p_user_id;
  insert into public.social_team_activity_events(team_id, actor_user_id, event_type) values (p_team_id, p_user_id, 'member_left');
  return true;
end;
$$;

-- Only the owner can promote or demote another active member.
-- This function intentionally cannot transfer ownership.
create or replace function public.set_social_team_member_role(p_team_id uuid, p_user_id uuid, p_role text)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; target_role text;
begin
  caller := public.require_active_user();
  if not public.has_social_team_role(p_team_id, caller.id, array['owner']) then
    raise exception using errcode = '42501', message = 'Team owner permission required';
  end if;
  if p_role not in ('admin', 'member') or p_user_id = caller.id then
    raise exception using errcode = '22023', message = 'Invalid team role update';
  end if;
  select role into target_role from public.social_team_members
  where team_id = p_team_id and user_id = p_user_id and left_at is null for update;
  if target_role is null then raise exception using errcode = 'P0002', message = 'Team member not found'; end if;
  if target_role = 'owner' then raise exception using errcode = '42501', message = 'Owner role cannot be changed'; end if;
  update public.social_team_members set role = p_role
  where team_id = p_team_id and user_id = p_user_id and left_at is null;
  return true;
end;
$$;

create or replace function public.create_team_challenge(
  p_team_id uuid,
  p_title text,
  p_category_id uuid default null,
  p_question_count integer default 10,
  p_starts_at timestamptz default clock_timestamp(),
  p_ends_at timestamptz default (clock_timestamp() + interval '7 days'),
  p_max_attempts integer default 1,
  p_artwork_key text default 'eye_of_the_falcon'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; challenge_id uuid; selected record; selected_count integer := 0; challenge_question_id uuid; clean_title text;
begin
  caller := public.require_active_user();
  if p_team_id is null then
    if not public.has_role('admin') then raise exception using errcode = '42501', message = 'Administrator permission required'; end if;
  elsif not public.has_social_team_role(p_team_id, caller.id, array['owner', 'admin']) then
    raise exception using errcode = '42501', message = 'Team admin permission required';
  end if;
  perform public.assert_rate_limit(caller.id::text, 'create_team_challenge', 10, interval '7 days');
  clean_title := btrim(regexp_replace(coalesce(p_title, ''), '[[:space:]]+', ' ', 'g'));
  if char_length(clean_title) not between 3 and 80 or not public.social_text_is_allowed(clean_title) then raise exception using errcode = '22023', message = 'Challenge title is not allowed'; end if;
  if p_question_count not between 3 and 15 or p_max_attempts not between 1 and 3 or p_ends_at <= p_starts_at or p_ends_at > p_starts_at + interval '31 days' then raise exception using errcode = '22023', message = 'Invalid challenge configuration'; end if;
  if p_artwork_key not in ('eye_of_the_falcon', 'saudi_week', 'thursday_challenge') then raise exception using errcode = '22023', message = 'Invalid challenge artwork'; end if;
  insert into public.team_challenges(team_id, title, category_id, question_count, max_attempts, artwork_key, status, starts_at, ends_at, created_by, is_official)
  values (p_team_id, clean_title, p_category_id, p_question_count, p_max_attempts, p_artwork_key,
    case when p_starts_at <= clock_timestamp() then 'active' else 'scheduled' end,
    p_starts_at, p_ends_at, caller.id, p_team_id is null)
  returning id into challenge_id;
  for selected in
    select question.* from public.questions question
    where question.status = 'published' and question.needs_review = false
      and 'solo'::public.match_mode = any(question.suitable_modes)
      and (p_category_id is null or question.category_id = p_category_id)
      and (select count(*) from public.question_options option where option.question_id = question.id) = 4
    order by md5(question.id::text || challenge_id::text)
    limit p_question_count
  loop
    selected_count := selected_count + 1;
    insert into public.team_challenge_questions(challenge_id, source_question_id, sequence_number, question_text_snapshot, question_type_snapshot, image_url_snapshot, category_id_snapshot)
    values (challenge_id, selected.id, selected_count, selected.question_text, selected.question_type, selected.image_url, selected.category_id)
    returning id into challenge_question_id;
    insert into public.team_challenge_options(challenge_question_id, source_option_id, option_text_snapshot, position, is_correct)
    select challenge_question_id, option.id, option.option_text,
      row_number() over (order by md5(option.id::text || challenge_id::text))::smallint,
      option.id = selected.correct_option_id
    from public.question_options option where option.question_id = selected.id;
  end loop;
  if selected_count <> p_question_count then raise exception using errcode = 'P0001', message = 'Not enough eligible questions'; end if;
  if p_team_id is not null then
    insert into public.social_team_activity_events(team_id, actor_user_id, event_type, safe_data)
    values (p_team_id, caller.id, 'challenge_created', jsonb_build_object('challenge_id', challenge_id, 'title', clean_title));
  end if;
  return jsonb_build_object('challenge_id', challenge_id, 'status', case when p_starts_at <= clock_timestamp() then 'active' else 'scheduled' end);
end;
$$;

create or replace function public.start_team_challenge_attempt(p_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; challenge public.team_challenges%rowtype; attempt_no integer; attempt_id uuid;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'start_team_challenge_attempt', 30, interval '1 day');
  select * into challenge from public.team_challenges where id = p_challenge_id for update;
  if not found or challenge.status in ('draft', 'cancelled') or clock_timestamp() not between challenge.starts_at and challenge.ends_at then raise exception using errcode = 'P0001', message = 'Challenge is not active'; end if;
  if challenge.team_id is not null and not public.is_social_team_member(challenge.team_id, caller.id) then raise exception using errcode = '42501', message = 'Team membership required'; end if;
  select id, attempt_number into attempt_id, attempt_no
  from public.team_challenge_attempts
  where challenge_id = challenge.id and user_id = caller.id and status = 'active'
  order by started_at desc
  limit 1;
  if attempt_id is not null then
    return jsonb_build_object('attempt_id', attempt_id, 'attempt_number', attempt_no,
      'question_count', challenge.question_count, 'resumed', true);
  end if;
  select count(*)::integer + 1 into attempt_no from public.team_challenge_attempts where challenge_id = challenge.id and user_id = caller.id;
  if attempt_no > challenge.max_attempts then raise exception using errcode = 'P0001', message = 'No attempts remaining'; end if;
  insert into public.team_challenge_attempts(challenge_id, user_id, attempt_number) values (challenge.id, caller.id, attempt_no) returning id into attempt_id;
  return jsonb_build_object('attempt_id', attempt_id, 'attempt_number', attempt_no, 'question_count', challenge.question_count);
end;
$$;

create or replace function public.get_team_challenge_question(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; attempt public.team_challenge_attempts%rowtype; challenge public.team_challenges%rowtype; question public.team_challenge_questions%rowtype; options jsonb;
begin
  caller := public.require_active_user();
  select * into attempt from public.team_challenge_attempts where id = p_attempt_id and user_id = caller.id;
  if not found or attempt.status <> 'active' then raise exception using errcode = 'P0001', message = 'Attempt is not active'; end if;
  select * into challenge from public.team_challenges where id = attempt.challenge_id;
  if challenge.team_id is not null and not public.is_social_team_member(challenge.team_id, caller.id) then
    raise exception using errcode = '42501', message = 'Team membership required';
  end if;
  select * into question from public.team_challenge_questions where challenge_id = challenge.id and sequence_number = attempt.current_sequence;
  select coalesce(jsonb_agg(jsonb_build_object('id', option.id, 'text', option.option_text_snapshot, 'position', option.position) order by option.position), '[]'::jsonb)
  into options from public.team_challenge_options option where option.challenge_question_id = question.id;
  return jsonb_build_object(
    'attempt_id', attempt.id, 'challenge_id', challenge.id, 'challenge_title', challenge.title,
    'sequence', attempt.current_sequence, 'question_count', challenge.question_count,
    'question_id', question.id, 'question_text', question.question_text_snapshot,
    'question_type', question.question_type_snapshot, 'image_url', question.image_url_snapshot,
    'duration_ms', challenge.question_duration_ms,
    'opened_at', attempt.question_opened_at,
    'closes_at', attempt.question_opened_at + make_interval(secs => challenge.question_duration_ms / 1000.0),
    'options', options, 'score', attempt.score
  );
end;
$$;

create or replace function public.submit_team_challenge_answer(p_attempt_id uuid, p_option_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; attempt public.team_challenge_attempts%rowtype; challenge public.team_challenges%rowtype; question public.team_challenge_questions%rowtype; selected_option public.team_challenge_options%rowtype; correct_option_id uuid; elapsed_ms integer; correct boolean := false; awarded integer := 0; finished boolean;
begin
  caller := public.require_active_user();
  select * into attempt from public.team_challenge_attempts where id = p_attempt_id and user_id = caller.id for update;
  if not found or attempt.status <> 'active' then raise exception using errcode = 'P0001', message = 'Attempt is not active'; end if;
  select * into challenge from public.team_challenges where id = attempt.challenge_id;
  if clock_timestamp() > challenge.ends_at then
    update public.team_challenge_attempts set status = 'expired' where id = attempt.id;
    return jsonb_build_object('expired', true, 'completed', false, 'total_score', attempt.score);
  end if;
  select * into question from public.team_challenge_questions where challenge_id = challenge.id and sequence_number = attempt.current_sequence;
  if p_option_id is not null then
    select * into selected_option from public.team_challenge_options where id = p_option_id and challenge_question_id = question.id;
    if not found then raise exception using errcode = '22023', message = 'Option does not belong to question'; end if;
  end if;
  elapsed_ms := greatest(0, floor(extract(epoch from (clock_timestamp() - attempt.question_opened_at)) * 1000)::integer);
  elapsed_ms := least(elapsed_ms, challenge.question_duration_ms);
  correct := p_option_id is not null and selected_option.is_correct and clock_timestamp() <= attempt.question_opened_at + make_interval(secs => challenge.question_duration_ms / 1000.0);
  if correct then awarded := 100 + floor(50 * (1 - elapsed_ms::numeric / challenge.question_duration_ms))::integer; end if;
  select id into correct_option_id from public.team_challenge_options where challenge_question_id = question.id and is_correct;
  insert into public.team_challenge_answers(attempt_id, challenge_question_id, selected_option_id, is_correct, score_awarded, response_time_ms)
  values (attempt.id, question.id, p_option_id, correct, awarded, elapsed_ms);
  finished := attempt.current_sequence >= challenge.question_count;
  update public.team_challenge_attempts
  set score = score + awarded,
      correct_answers = correct_answers + case when correct then 1 else 0 end,
      wrong_answers = wrong_answers + case when correct then 0 else 1 end,
      total_response_time_ms = total_response_time_ms + elapsed_ms,
      status = case when finished then 'completed' else 'active' end,
      completed_at = case when finished then clock_timestamp() else null end,
      current_sequence = case when finished then current_sequence else current_sequence + 1 end,
      question_opened_at = case when finished then question_opened_at else clock_timestamp() end
  where id = attempt.id
  returning * into attempt;
  if finished then
    perform public.award_player_achievement(caller.id, 'first_team_challenge', 'challenge', attempt.challenge_id);
    if attempt.correct_answers >= 5 and attempt.wrong_answers = 0 then
      perform public.award_player_achievement(caller.id, 'perfect_five', 'challenge', attempt.challenge_id);
    end if;
  end if;
  return jsonb_build_object('correct', correct, 'score_awarded', awarded, 'total_score', attempt.score,
    'correct_option_id', correct_option_id, 'completed', finished,
    'next_sequence', case when finished then null else attempt.current_sequence end);
end;
$$;

create or replace function public.get_team_challenge_result(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; attempt public.team_challenge_attempts%rowtype; player_rank integer; gap_to_next integer; leaderboard jsonb;
begin
  caller := public.require_active_user();
  select * into attempt from public.team_challenge_attempts where id = p_attempt_id and user_id = caller.id and status = 'completed';
  if not found then raise exception using errcode = 'P0001', message = 'Completed attempt not found'; end if;
  select count(distinct other.user_id)::integer + 1 into player_rank from public.team_challenge_attempts other
  where other.challenge_id = attempt.challenge_id and other.status = 'completed' and other.score > attempt.score;
  select min(other.score) - attempt.score into gap_to_next from public.team_challenge_attempts other
  where other.challenge_id = attempt.challenge_id and other.status = 'completed' and other.score > attempt.score;
  select coalesce(jsonb_agg(row_data order by (row_data ->> 'rank')::integer), '[]'::jsonb) into leaderboard
  from (
    select jsonb_build_object('rank', row_number() over (order by best.score desc, best.total_response_time_ms, best.completed_at),
      'user_id', profile.id, 'display_name', profile.display_name, 'avatar_url', profile.avatar_url, 'score', best.score) as row_data
    from (
      select distinct on (candidate.user_id) candidate.user_id, candidate.score, candidate.total_response_time_ms, candidate.completed_at
      from public.team_challenge_attempts candidate
      where candidate.challenge_id = attempt.challenge_id and candidate.status = 'completed'
      order by candidate.user_id, candidate.score desc, candidate.total_response_time_ms, candidate.completed_at
    ) best join public.profiles profile on profile.id = best.user_id
    order by best.score desc, best.total_response_time_ms, best.completed_at
    limit 10
  ) ranked;
  return jsonb_build_object('attempt_id', attempt.id, 'score', attempt.score, 'correct_answers', attempt.correct_answers,
    'wrong_answers', attempt.wrong_answers, 'rank', player_rank, 'gap_to_next', gap_to_next, 'leaderboard', leaderboard);
end;
$$;

create or replace function public.get_social_hub()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; team jsonb; invites jsonb;
begin
  caller := public.require_active_user();
  select jsonb_build_object('id', social_team.id, 'name', social_team.name, 'primary_color', social_team.primary_color,
    'badge_seed', social_team.badge_seed, 'banner_style', social_team.banner_style, 'role', member.role,
    'member_count', (select count(*) from public.social_team_members count_member where count_member.team_id = social_team.id and count_member.left_at is null),
    'active_challenges', (select count(*) from public.team_challenges challenge where (challenge.team_id = social_team.id or challenge.is_official) and challenge.status in ('scheduled', 'active') and challenge.ends_at > clock_timestamp()))
  into team from public.social_team_members member join public.social_teams social_team on social_team.id = member.team_id
  where member.user_id = caller.id and member.left_at is null and social_team.status = 'active';
  select coalesce(jsonb_agg(jsonb_build_object('invite_id', invite.id, 'team_id', social_team.id, 'team_name', social_team.name,
    'primary_color', social_team.primary_color, 'badge_seed', social_team.badge_seed, 'invited_by_name', inviter.display_name,
    'expires_at', invite.expires_at) order by invite.created_at desc), '[]'::jsonb)
  into invites from public.social_team_invites invite
  join public.social_teams social_team on social_team.id = invite.team_id
  join public.profiles inviter on inviter.id = invite.invited_by
  where invite.invited_user_id = caller.id and invite.status = 'pending' and invite.expires_at > clock_timestamp();
  return jsonb_build_object('team', team, 'invites', invites);
end;
$$;

create or replace function public.get_social_team_detail(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare caller public.profiles%rowtype; target_team public.social_teams%rowtype; members jsonb; challenges jsonb; activity jsonb; mvp jsonb; caller_role text;
begin
  caller := public.require_active_user();
  if not public.is_social_team_member(p_team_id, caller.id) and not public.has_role('moderator') then raise exception using errcode = '42501', message = 'Team membership required'; end if;
  select * into target_team from public.social_teams where id = p_team_id;
  if not found then raise exception using errcode = 'P0002', message = 'Team not found'; end if;
  select role into caller_role from public.social_team_members
  where team_id = p_team_id and user_id = caller.id and left_at is null;
  with member_points as (
    select member.user_id, member.role, member.joined_at,
      coalesce((select sum(best.best_score) from (
        select max(attempt.score) as best_score
        from public.team_challenge_attempts attempt
        join public.team_challenges challenge on challenge.id = attempt.challenge_id
        where attempt.user_id = member.user_id and attempt.status = 'completed'
          and (challenge.team_id = p_team_id or challenge.is_official)
          and attempt.completed_at >= date_trunc('week', clock_timestamp())
        group by attempt.challenge_id
      ) best), 0)::bigint as weekly_points
    from public.social_team_members member where member.team_id = p_team_id and member.left_at is null
  ), ranked as (
    select member_points.*, row_number() over (order by weekly_points desc, joined_at) as rank from member_points
  )
  select coalesce(jsonb_agg(jsonb_build_object('user_id', profile.id, 'display_name', profile.display_name,
    'username', profile.username, 'avatar_url', profile.avatar_url, 'level', profile.level, 'role', ranked.role,
    'weekly_points', ranked.weekly_points, 'rank', ranked.rank, 'jersey_color', target_team.primary_color)
    order by ranked.rank), '[]'::jsonb),
    (select jsonb_build_object('user_id', profile.id, 'display_name', profile.display_name, 'avatar_url', profile.avatar_url,
      'weekly_points', ranked.weekly_points) from ranked join public.profiles profile on profile.id = ranked.user_id where ranked.rank = 1 and ranked.weekly_points > 0)
  into members, mvp from ranked join public.profiles profile on profile.id = ranked.user_id;
  select coalesce(jsonb_agg(jsonb_build_object('id', challenge.id, 'title', challenge.title, 'question_count', challenge.question_count,
    'starts_at', challenge.starts_at, 'ends_at', challenge.ends_at, 'status', challenge.status, 'artwork_key', challenge.artwork_key,
    'is_official', challenge.is_official, 'attempts_used', (select count(*) from public.team_challenge_attempts attempt where attempt.challenge_id = challenge.id and attempt.user_id = caller.id))
    order by challenge.ends_at), '[]'::jsonb)
  into challenges from public.team_challenges challenge
  where (challenge.team_id = p_team_id or challenge.is_official) and challenge.status not in ('draft', 'cancelled')
    and challenge.ends_at >= clock_timestamp() - interval '30 days';
  select coalesce(jsonb_agg(jsonb_build_object('id', event.id, 'type', event.event_type, 'actor_name', profile.display_name,
    'data', event.safe_data, 'created_at', event.created_at) order by event.created_at desc), '[]'::jsonb)
  into activity from (select * from public.social_team_activity_events where team_id = p_team_id order by created_at desc limit 20) event
  left join public.profiles profile on profile.id = event.actor_user_id;
  return jsonb_build_object('team', jsonb_build_object('id', target_team.id, 'name', target_team.name, 'description', target_team.description,
    'primary_color', target_team.primary_color, 'badge_seed', target_team.badge_seed, 'banner_style', target_team.banner_style,
    'status', target_team.status, 'current_role', coalesce(caller_role, 'moderator'),
    'current_user_id', caller.id),
    'members', members, 'weekly_mvp', mvp, 'challenges', challenges, 'activity', activity);
end;
$$;

create or replace function public.moderate_social_team(p_team_id uuid, p_status text, p_reason text)
returns public.social_teams
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare previous_team public.social_teams%rowtype; updated_team public.social_teams%rowtype; clean_reason text;
begin
  if not public.has_role('moderator') then raise exception using errcode = '42501', message = 'Moderator permission required'; end if;
  if p_status not in ('active', 'suspended', 'archived') then raise exception using errcode = '22023', message = 'Invalid team status'; end if;
  clean_reason := public.sanitize_app_error_text(p_reason, 500);
  if p_status <> 'active' and clean_reason is null then raise exception using errcode = '22023', message = 'Moderation reason is required'; end if;
  select * into previous_team from public.social_teams where id = p_team_id for update;
  if not found then raise exception using errcode = 'P0002', message = 'Team not found'; end if;
  update public.social_teams set status = p_status, moderation_reason = case when p_status = 'active' then null else clean_reason end
  where id = p_team_id returning * into updated_team;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (auth.uid(), 'social_team.moderated', 'social_team', p_team_id::text,
    jsonb_build_object('status', previous_team.status, 'reason', previous_team.moderation_reason),
    jsonb_build_object('status', updated_team.status, 'reason', updated_team.moderation_reason));
  return updated_team;
end;
$$;

create or replace function public.review_social_report(p_report_id uuid, p_status text, p_admin_note text default null)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare previous_report public.social_reports%rowtype; clean_note text;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator permission required';
  end if;
  if p_status not in ('reviewing', 'resolved', 'dismissed') then
    raise exception using errcode = '22023', message = 'Invalid report status';
  end if;
  clean_note := public.sanitize_app_error_text(p_admin_note, 500);
  select * into previous_report from public.social_reports where id = p_report_id for update;
  if not found then raise exception using errcode = 'P0002', message = 'Social report not found'; end if;
  update public.social_reports
  set status = p_status, reviewed_by = auth.uid(), reviewed_at = clock_timestamp()
  where id = p_report_id;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (auth.uid(), 'social_report.reviewed', 'social_report', p_report_id::text,
    jsonb_build_object('status', previous_report.status),
    jsonb_build_object('status', p_status, 'note', clean_note));
  return true;
end;
$$;

create or replace function public.audit_football_data_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is not null and public.has_role('moderator') then
    if tg_op = 'INSERT' then
      insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
      values (auth.uid(), 'football_data.insert', tg_table_name, new.id::text, null,
        to_jsonb(new) - 'license_reference');
    elsif tg_op = 'UPDATE' then
      insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
      values (auth.uid(), 'football_data.update', tg_table_name, new.id::text,
        to_jsonb(old) - 'license_reference', to_jsonb(new) - 'license_reference');
    else
      insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
      values (auth.uid(), 'football_data.delete', tg_table_name, old.id::text,
        to_jsonb(old) - 'license_reference', null);
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger football_countries_audit after insert or update or delete on public.football_countries
for each row execute function public.audit_football_data_change();
create trigger football_leagues_audit after insert or update or delete on public.football_leagues
for each row execute function public.audit_football_data_change();
create trigger football_clubs_audit after insert or update or delete on public.football_clubs
for each row execute function public.audit_football_data_change();

alter table public.football_countries enable row level security;
alter table public.football_leagues enable row level security;
alter table public.football_clubs enable row level security;
alter table public.user_blocks enable row level security;
alter table public.blocked_social_terms enable row level security;
alter table public.social_teams enable row level security;
alter table public.social_team_members enable row level security;
alter table public.social_team_invites enable row level security;
alter table public.team_challenges enable row level security;
alter table public.team_challenge_questions enable row level security;
alter table public.team_challenge_options enable row level security;
alter table public.team_challenge_attempts enable row level security;
alter table public.team_challenge_answers enable row level security;
alter table public.social_team_activity_events enable row level security;
alter table public.social_reports enable row level security;
alter table public.achievement_definitions enable row level security;
alter table public.player_achievements enable row level security;

create policy football_countries_public_read on public.football_countries for select to anon, authenticated using (is_active or public.has_role('moderator'));
create policy football_leagues_public_read on public.football_leagues for select to anon, authenticated using (is_active or public.has_role('moderator'));
create policy football_clubs_public_read on public.football_clubs for select to anon, authenticated using (is_active or public.has_role('moderator'));
create policy football_countries_admin_write on public.football_countries for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy football_leagues_admin_write on public.football_leagues for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy football_clubs_admin_write on public.football_clubs for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy user_blocks_owner_read on public.user_blocks for select to authenticated using (blocker_id = auth.uid());
create policy blocked_social_terms_admin on public.blocked_social_terms for all to authenticated using (public.has_role('moderator')) with check (public.has_role('moderator'));
create policy social_teams_member_or_staff_read on public.social_teams for select to authenticated using (public.is_social_team_member(id, auth.uid()) or public.has_role('moderator'));
create policy social_team_members_same_team_read on public.social_team_members for select to authenticated using (public.is_social_team_member(team_id, auth.uid()) or public.has_role('moderator'));
create policy social_team_invites_involved_read on public.social_team_invites for select to authenticated using (invited_user_id = auth.uid() or invited_by = auth.uid() or public.has_role('moderator'));
create policy team_challenges_member_read on public.team_challenges for select to authenticated using (is_official or public.is_social_team_member(team_id, auth.uid()) or public.has_role('moderator'));
create policy team_challenge_attempts_owner_read on public.team_challenge_attempts for select to authenticated using (user_id = auth.uid() or public.has_role('moderator'));
create policy social_team_activity_member_read on public.social_team_activity_events for select to authenticated using (public.is_social_team_member(team_id, auth.uid()) or public.has_role('moderator'));
create policy social_reports_owner_or_staff_read on public.social_reports for select to authenticated using (reporter_id = auth.uid() or public.has_role('moderator'));
create policy achievement_definitions_read on public.achievement_definitions for select to authenticated using (is_active or public.has_role('moderator'));
create policy player_achievements_read on public.player_achievements for select to authenticated using (user_id = auth.uid() or public.has_role('moderator'));

revoke all on public.football_countries, public.football_leagues, public.football_clubs,
  public.user_blocks, public.blocked_social_terms, public.social_teams, public.social_team_members,
  public.social_team_invites, public.team_challenges, public.team_challenge_questions,
  public.team_challenge_options, public.team_challenge_attempts, public.team_challenge_answers,
  public.social_team_activity_events, public.social_reports, public.achievement_definitions,
  public.player_achievements from public, anon, authenticated;

grant select on public.football_countries, public.football_leagues, public.football_clubs to anon, authenticated;
grant insert, update, delete on public.football_countries, public.football_leagues, public.football_clubs to authenticated;
grant select, insert, update, delete on public.blocked_social_terms to authenticated;
grant select on public.user_blocks, public.social_teams, public.social_team_members, public.social_team_invites,
  public.team_challenges, public.team_challenge_attempts, public.social_team_activity_events,
  public.social_reports, public.achievement_definitions, public.player_achievements to authenticated;

revoke select on public.team_challenge_questions, public.team_challenge_options, public.team_challenge_answers from authenticated;
grant update (favorite_league_id, favorite_club_id, show_football_preferences, avatar_style, avatar_background, avatar_jersey_color) on public.profiles to authenticated;
grant update (teams, promotions) on public.notification_preferences to authenticated;

revoke all on function public.prepare_football_search() from public, anon, authenticated;
revoke all on function public.award_player_achievement(uuid, text, text, uuid) from public, anon, authenticated;
revoke all on function public.social_text_is_allowed(text) from public, anon, authenticated;
revoke all on function public.is_social_team_member(uuid, uuid) from public, anon, authenticated;
revoke all on function public.has_social_team_role(uuid, uuid, text[]) from public, anon, authenticated;
revoke all on function public.list_football_leagues(uuid) from public, anon, authenticated;
revoke all on function public.search_football_clubs(text, uuid, integer, integer) from public, anon, authenticated;
revoke all on function public.set_football_preferences(uuid, uuid, boolean) from public, anon, authenticated;
revoke all on function public.block_player(uuid) from public, anon, authenticated;
revoke all on function public.unblock_player(uuid) from public, anon, authenticated;
revoke all on function public.get_blocked_players() from public, anon, authenticated;
revoke all on function public.report_social_subject(text, uuid, text, text) from public, anon, authenticated;
revoke all on function public.create_social_team(text, text, text, text) from public, anon, authenticated;
revoke all on function public.rotate_social_team_code(uuid) from public, anon, authenticated;
revoke all on function public.join_social_team(text) from public, anon, authenticated;
revoke all on function public.invite_friend_to_social_team(uuid, uuid) from public, anon, authenticated;
revoke all on function public.respond_social_team_invite(uuid, boolean) from public, anon, authenticated;
revoke all on function public.remove_social_team_member(uuid, uuid) from public, anon, authenticated;
revoke all on function public.set_social_team_member_role(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.create_team_challenge(uuid, text, uuid, integer, timestamptz, timestamptz, integer, text) from public, anon, authenticated;
revoke all on function public.start_team_challenge_attempt(uuid) from public, anon, authenticated;
revoke all on function public.get_team_challenge_question(uuid) from public, anon, authenticated;
revoke all on function public.submit_team_challenge_answer(uuid, uuid) from public, anon, authenticated;
revoke all on function public.get_team_challenge_result(uuid) from public, anon, authenticated;
revoke all on function public.get_social_hub() from public, anon, authenticated;
revoke all on function public.get_social_team_detail(uuid) from public, anon, authenticated;
revoke all on function public.moderate_social_team(uuid, text, text) from public, anon, authenticated;
revoke all on function public.review_social_report(uuid, text, text) from public, anon, authenticated;
revoke all on function public.audit_football_data_change() from public, anon, authenticated;

grant execute on function public.is_social_team_member(uuid, uuid) to authenticated;
grant execute on function public.list_football_leagues(uuid) to anon, authenticated;
grant execute on function public.search_football_clubs(text, uuid, integer, integer) to anon, authenticated;
grant execute on function public.set_football_preferences(uuid, uuid, boolean) to authenticated;
grant execute on function public.block_player(uuid) to authenticated;
grant execute on function public.unblock_player(uuid) to authenticated;
grant execute on function public.get_blocked_players() to authenticated;
grant execute on function public.report_social_subject(text, uuid, text, text) to authenticated;
grant execute on function public.create_social_team(text, text, text, text) to authenticated;
grant execute on function public.rotate_social_team_code(uuid) to authenticated;
grant execute on function public.join_social_team(text) to authenticated;
grant execute on function public.invite_friend_to_social_team(uuid, uuid) to authenticated;
grant execute on function public.respond_social_team_invite(uuid, boolean) to authenticated;
grant execute on function public.remove_social_team_member(uuid, uuid) to authenticated;
grant execute on function public.set_social_team_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.create_team_challenge(uuid, text, uuid, integer, timestamptz, timestamptz, integer, text) to authenticated;
grant execute on function public.start_team_challenge_attempt(uuid) to authenticated;
grant execute on function public.get_team_challenge_question(uuid) to authenticated;
grant execute on function public.submit_team_challenge_answer(uuid, uuid) to authenticated;
grant execute on function public.get_team_challenge_result(uuid) to authenticated;
grant execute on function public.get_social_hub() to authenticated;
grant execute on function public.get_social_team_detail(uuid) to authenticated;
grant execute on function public.moderate_social_team(uuid, text, text) to authenticated;
grant execute on function public.review_social_report(uuid, text, text) to authenticated;

comment on table public.football_clubs is 'Rights-aware club catalog. logo_url is rendered only for licensed/custom visual_status.';
comment on table public.team_challenge_options is 'Server-only option snapshots; is_correct must never be granted to Flutter clients.';
comment on table public.team_challenge_attempts is 'Scores and ranks are written only by SECURITY DEFINER challenge RPCs.';
