-- Ahdash 11 tournament product: organizer-owned, single-elimination brackets.
-- This is intentionally additive. Applied Party migrations are not modified.

create type public.tournament_status as enum (
  'draft', 'registration', 'ready', 'live', 'completed', 'cancelled'
);
create type public.tournament_visibility as enum ('private', 'invite', 'public');
create type public.tournament_seeding as enum ('draw', 'manual');
create type public.tournament_team_status as enum ('pending', 'approved', 'rejected', 'withdrawn');
create type public.tournament_match_status as enum ('pending', 'ready', 'live', 'completed', 'bye', 'cancelled');

create table public.tournaments (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles(id) on delete restrict,
  name text not null check (char_length(name) between 3 and 60),
  status public.tournament_status not null default 'draft',
  visibility public.tournament_visibility not null default 'private',
  seeding public.tournament_seeding not null default 'draw',
  capacity smallint not null check (capacity in (4, 8, 16, 32, 64)),
  players_per_team smallint not null default 1 check (players_per_team between 1 and 8),
  timer_seconds smallint check (timer_seconds is null or timer_seconds between 10 and 120),
  helpers_enabled boolean not null default true,
  tiebreaker_enabled boolean not null default true,
  category_ids uuid[] not null default '{}',
  rules_snapshot jsonb not null default '{}'::jsonb check (jsonb_typeof(rules_snapshot) = 'object'),
  invite_code extensions.citext unique,
  champion_team_id uuid,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tournaments_time_order check (
    (completed_at is null or started_at is not null)
    and (completed_at is null or completed_at >= started_at)
  )
);

create table public.tournament_teams (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  owner_user_id uuid references public.profiles(id) on delete set null,
  name text not null check (char_length(name) between 2 and 40),
  status public.tournament_team_status not null default 'approved',
  seed smallint check (seed is null or seed between 1 and 64),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tournament_id, name),
  unique (tournament_id, seed),
  unique (id, tournament_id)
);

alter table public.tournaments
  add constraint tournaments_champion_fk
  foreign key (champion_team_id, id)
  references public.tournament_teams(id, tournament_id)
  deferrable initially deferred;

create table public.tournament_players (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  team_id uuid not null,
  user_id uuid references public.profiles(id) on delete set null,
  display_name text not null check (char_length(display_name) between 1 and 50),
  is_captain boolean not null default false,
  created_at timestamptz not null default now(),
  foreign key (team_id, tournament_id)
    references public.tournament_teams(id, tournament_id) on delete cascade,
  unique (tournament_id, user_id),
  unique (team_id, display_name)
);

create table public.tournament_registrations (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  team_name text not null check (char_length(team_name) between 2 and 40),
  roster jsonb not null default '[]'::jsonb check (jsonb_typeof(roster) = 'array'),
  status public.tournament_team_status not null default 'pending',
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tournament_id, requested_by)
);

create table public.tournament_matches (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  round_number smallint not null check (round_number between 1 and 6),
  position smallint not null check (position between 0 and 31),
  status public.tournament_match_status not null default 'pending',
  team_a_id uuid,
  team_b_id uuid,
  score_a integer check (score_a is null or score_a >= 0),
  score_b integer check (score_b is null or score_b >= 0),
  winner_team_id uuid,
  next_match_id uuid references public.tournament_matches(id) deferrable initially deferred,
  next_slot smallint check (next_slot is null or next_slot in (0, 1)),
  party_session_id uuid,
  confirmed_by uuid references public.profiles(id) on delete set null,
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tournament_id, round_number, position),
  unique (id, tournament_id),
  foreign key (team_a_id, tournament_id)
    references public.tournament_teams(id, tournament_id) deferrable initially deferred,
  foreign key (team_b_id, tournament_id)
    references public.tournament_teams(id, tournament_id) deferrable initially deferred,
  foreign key (winner_team_id, tournament_id)
    references public.tournament_teams(id, tournament_id) deferrable initially deferred,
  constraint tournament_matches_next_slot check (
    (next_match_id is null and next_slot is null)
    or (next_match_id is not null and next_slot is not null)
  ),
  constraint tournament_matches_distinct_teams check (
    team_a_id is null or team_b_id is null or team_a_id <> team_b_id
  ),
  constraint tournament_matches_winner_participates check (
    winner_team_id is null or winner_team_id in (team_a_id, team_b_id)
  )
);

create table public.tournament_events (
  id bigint generated always as identity primary key,
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  event_type text not null check (event_type ~ '^[a-z][a-z0-9_]{2,49}$'),
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  created_at timestamptz not null default now()
);

create index tournaments_organizer_status_idx
  on public.tournaments(organizer_id, status, updated_at desc);
create index tournaments_public_idx
  on public.tournaments(status, created_at desc) where visibility = 'public';
create index tournament_teams_tournament_idx
  on public.tournament_teams(tournament_id, seed, created_at);
create index tournament_players_user_idx
  on public.tournament_players(user_id, tournament_id) where user_id is not null;
create index tournament_registrations_review_idx
  on public.tournament_registrations(tournament_id, status, created_at);
create index tournament_matches_round_idx
  on public.tournament_matches(tournament_id, round_number, position);
create index tournament_events_stream_idx
  on public.tournament_events(tournament_id, id);

create trigger tournaments_set_updated_at before update on public.tournaments
for each row execute function public.set_updated_at();
create trigger tournament_teams_set_updated_at before update on public.tournament_teams
for each row execute function public.set_updated_at();
create trigger tournament_registrations_set_updated_at before update on public.tournament_registrations
for each row execute function public.set_updated_at();
create trigger tournament_matches_set_updated_at before update on public.tournament_matches
for each row execute function public.set_updated_at();

alter table public.tournaments enable row level security;
alter table public.tournament_teams enable row level security;
alter table public.tournament_players enable row level security;
alter table public.tournament_registrations enable row level security;
alter table public.tournament_matches enable row level security;
alter table public.tournament_events enable row level security;

create or replace function public.can_view_tournament(
  target_tournament_id uuid,
  target_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.tournaments tournament
    where tournament.id = target_tournament_id
      and (
        tournament.organizer_id = target_user_id
        or tournament.visibility = 'public'
        or exists (
          select 1
          from public.tournament_players player
          where player.tournament_id = tournament.id
            and player.user_id = target_user_id
        )
      )
  );
$$;

revoke all on function public.can_view_tournament(uuid, uuid) from public;
grant execute on function public.can_view_tournament(uuid, uuid) to authenticated;

create policy tournaments_read on public.tournaments
for select to authenticated
using (public.can_view_tournament(id) or public.has_role('moderator'));
create policy tournaments_admin on public.tournaments
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

create policy tournament_teams_read on public.tournament_teams
for select to authenticated
using (public.can_view_tournament(tournament_id) or public.has_role('moderator'));
create policy tournament_teams_admin on public.tournament_teams
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

create policy tournament_players_read on public.tournament_players
for select to authenticated
using (public.can_view_tournament(tournament_id) or public.has_role('moderator'));
create policy tournament_players_admin on public.tournament_players
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

create policy tournament_registrations_read on public.tournament_registrations
for select to authenticated
using (
  requested_by = auth.uid()
  or exists (
    select 1 from public.tournaments tournament
    where tournament.id = tournament_id and tournament.organizer_id = auth.uid()
  )
  or public.has_role('moderator')
);
create policy tournament_registrations_admin on public.tournament_registrations
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

create policy tournament_matches_read on public.tournament_matches
for select to authenticated
using (public.can_view_tournament(tournament_id) or public.has_role('moderator'));
create policy tournament_matches_admin on public.tournament_matches
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

create policy tournament_events_read on public.tournament_events
for select to authenticated
using (public.can_view_tournament(tournament_id) or public.has_role('moderator'));
create policy tournament_events_admin on public.tournament_events
for all to authenticated
using (public.has_role('admin')) with check (public.has_role('admin'));

grant select on public.tournaments, public.tournament_teams,
  public.tournament_players, public.tournament_registrations,
  public.tournament_matches, public.tournament_events to authenticated;

create or replace function public.create_tournament(
  p_client_id uuid,
  p_name text,
  p_rules jsonb
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  created_id uuid;
  capacity_value smallint;
  players_value smallint;
  visibility_value public.tournament_visibility;
  seeding_value public.tournament_seeding;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'create_tournament', 10, interval '1 hour');
  if jsonb_typeof(p_rules) <> 'object' then
    raise exception using errcode = '22023', message = 'Rules must be an object';
  end if;
  capacity_value := coalesce((p_rules ->> 'capacity')::smallint, 8);
  players_value := coalesce((p_rules ->> 'players_per_team')::smallint, 1);
  visibility_value := coalesce(
    (p_rules ->> 'visibility')::public.tournament_visibility,
    'private'::public.tournament_visibility
  );
  seeding_value := coalesce(
    (p_rules ->> 'seeding')::public.tournament_seeding,
    'draw'::public.tournament_seeding
  );
  insert into public.tournaments(
    id, organizer_id, name, status, visibility, seeding, capacity,
    players_per_team, timer_seconds, helpers_enabled, tiebreaker_enabled,
    category_ids, rules_snapshot, invite_code
  ) values (
    coalesce(p_client_id, gen_random_uuid()), caller.id, trim(p_name),
    case when visibility_value = 'public' then 'registration'::public.tournament_status
      else 'draft'::public.tournament_status end,
    visibility_value, seeding_value, capacity_value, players_value,
    coalesce((p_rules ->> 'timer_seconds')::smallint, 30),
    coalesce((p_rules ->> 'helpers_enabled')::boolean, true),
    coalesce((p_rules ->> 'tiebreaker_enabled')::boolean, true),
    coalesce(
      array(select value::uuid from jsonb_array_elements_text(coalesce(p_rules -> 'category_ids', '[]'::jsonb))),
      '{}'::uuid[]
    ),
    p_rules,
    case when visibility_value = 'private' then null
      else upper(encode(extensions.gen_random_bytes(4), 'hex'))::extensions.citext end
  )
  on conflict (id) do update
  set name = excluded.name,
      rules_snapshot = excluded.rules_snapshot,
      updated_at = clock_timestamp()
  where public.tournaments.organizer_id = caller.id
    and public.tournaments.status in ('draft', 'registration')
  returning id into created_id;
  if created_id is null then
    raise exception using errcode = '42501', message = 'Tournament cannot be replaced';
  end if;
  insert into public.tournament_events(tournament_id, actor_user_id, event_type)
  values (created_id, caller.id, 'tournament_created');
  return created_id;
end;
$$;

create or replace function public.save_tournament_bracket(
  p_tournament_id uuid,
  p_teams jsonb,
  p_matches jsonb
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target public.tournaments%rowtype;
  team_value jsonb;
  match_value jsonb;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'save_tournament_bracket', 20, interval '1 hour');
  select * into target from public.tournaments
  where id = p_tournament_id and organizer_id = caller.id for update;
  if not found then raise exception using errcode = '42501', message = 'Tournament not owned'; end if;
  if target.status not in ('draft', 'registration', 'ready') then
    raise exception using errcode = '55000', message = 'Bracket is already locked';
  end if;
  if jsonb_typeof(p_teams) <> 'array' or jsonb_typeof(p_matches) <> 'array' then
    raise exception using errcode = '22023', message = 'Teams and matches must be arrays';
  end if;
  if jsonb_array_length(p_teams) < 2 or jsonb_array_length(p_teams) > target.capacity then
    raise exception using errcode = '22023', message = 'Invalid team count';
  end if;
  delete from public.tournament_matches where tournament_id = target.id;
  delete from public.tournament_players where tournament_id = target.id;
  delete from public.tournament_teams where tournament_id = target.id;
  for team_value in select value from jsonb_array_elements(p_teams) loop
    insert into public.tournament_teams(id, tournament_id, name, status, seed)
    values (
      (team_value ->> 'id')::uuid,
      target.id,
      trim(team_value ->> 'name'),
      'approved',
      (team_value ->> 'seed')::smallint
    );
  end loop;
  for match_value in select value from jsonb_array_elements(p_matches) loop
    insert into public.tournament_matches(
      id, tournament_id, round_number, position, status,
      team_a_id, team_b_id, score_a, score_b, winner_team_id,
      next_slot, party_session_id, confirmed_at
    ) values (
      (match_value ->> 'id')::uuid,
      target.id,
      (match_value ->> 'round')::smallint,
      (match_value ->> 'position')::smallint,
      (match_value ->> 'status')::public.tournament_match_status,
      (match_value ->> 'team_a_id')::uuid,
      (match_value ->> 'team_b_id')::uuid,
      (match_value ->> 'score_a')::integer,
      (match_value ->> 'score_b')::integer,
      (match_value ->> 'winner_id')::uuid,
      null,
      (match_value ->> 'party_session_id')::uuid,
      (match_value ->> 'confirmed_at')::timestamptz
    );
  end loop;
  for match_value in select value from jsonb_array_elements(p_matches) loop
    if match_value ->> 'next_match_id' is not null then
      update public.tournament_matches
      set next_match_id = (match_value ->> 'next_match_id')::uuid,
          next_slot = (match_value ->> 'next_slot')::smallint
      where id = (match_value ->> 'id')::uuid and tournament_id = target.id;
    end if;
  end loop;
  update public.tournaments
  set status = 'live', started_at = coalesce(started_at, clock_timestamp())
  where id = target.id;
  insert into public.tournament_events(tournament_id, actor_user_id, event_type, payload)
  values (target.id, caller.id, 'bracket_locked', jsonb_build_object('team_count', jsonb_array_length(p_teams)));
  return true;
end;
$$;

create or replace function public.confirm_tournament_match_result(
  p_tournament_id uuid,
  p_match_id uuid,
  p_score_a integer,
  p_score_b integer,
  p_winner_team_id uuid,
  p_party_session_id uuid default null
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target public.tournaments%rowtype;
  target_match public.tournament_matches%rowtype;
  next_match public.tournament_matches%rowtype;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'confirm_tournament_result', 120, interval '1 hour');
  select * into target from public.tournaments
  where id = p_tournament_id and organizer_id = caller.id for update;
  if not found then raise exception using errcode = '42501', message = 'Tournament not owned'; end if;
  if target.status <> 'live' then raise exception using errcode = '55000', message = 'Tournament is not live'; end if;
  select * into target_match from public.tournament_matches
  where id = p_match_id and tournament_id = target.id for update;
  if not found or target_match.status <> 'ready' then
    raise exception using errcode = '55000', message = 'Match is not ready';
  end if;
  if p_score_a < 0 or p_score_b < 0 then raise exception using errcode = '22023', message = 'Invalid score'; end if;
  if p_winner_team_id not in (target_match.team_a_id, target_match.team_b_id) then
    raise exception using errcode = '22023', message = 'Winner is not a participant';
  end if;
  if p_score_a = p_score_b and not target.tiebreaker_enabled then
    raise exception using errcode = '22023', message = 'Tied result is not allowed';
  end if;
  update public.tournament_matches
  set status = 'completed', score_a = p_score_a, score_b = p_score_b,
      winner_team_id = p_winner_team_id, party_session_id = p_party_session_id,
      confirmed_by = caller.id, confirmed_at = clock_timestamp()
  where id = target_match.id;
  if target_match.next_match_id is null then
    update public.tournaments
    set status = 'completed', champion_team_id = p_winner_team_id,
        completed_at = clock_timestamp()
    where id = target.id;
  else
    select * into next_match from public.tournament_matches
    where id = target_match.next_match_id and tournament_id = target.id for update;
    if next_match.status in ('live', 'completed') then
      raise exception using errcode = '55000', message = 'Dependent match already started';
    end if;
    update public.tournament_matches
    set team_a_id = case when target_match.next_slot = 0 then p_winner_team_id else team_a_id end,
        team_b_id = case when target_match.next_slot = 1 then p_winner_team_id else team_b_id end,
        status = case
          when (case when target_match.next_slot = 0 then p_winner_team_id else team_a_id end) is not null
           and (case when target_match.next_slot = 1 then p_winner_team_id else team_b_id end) is not null
          then 'ready'::public.tournament_match_status
          else 'pending'::public.tournament_match_status end
    where id = next_match.id;
  end if;
  insert into public.tournament_events(tournament_id, actor_user_id, event_type, payload)
  values (target.id, caller.id, 'result_confirmed', jsonb_build_object(
    'match_id', target_match.id, 'winner_team_id', p_winner_team_id,
    'score_a', p_score_a, 'score_b', p_score_b
  ));
  return true;
end;
$$;

create or replace function public.undo_tournament_match_result(
  p_tournament_id uuid,
  p_match_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_match public.tournament_matches%rowtype;
  dependent public.tournament_matches%rowtype;
begin
  caller := public.require_active_user();
  if not exists (
    select 1 from public.tournaments
    where id = p_tournament_id and organizer_id = caller.id
  ) then raise exception using errcode = '42501', message = 'Tournament not owned'; end if;
  select * into target_match from public.tournament_matches
  where id = p_match_id and tournament_id = p_tournament_id for update;
  if not found or target_match.status <> 'completed' then
    raise exception using errcode = '55000', message = 'Result is not completed';
  end if;
  if target_match.next_match_id is not null then
    select * into dependent from public.tournament_matches
    where id = target_match.next_match_id for update;
    if dependent.status in ('live', 'completed') then
      raise exception using errcode = '55000', message = 'Dependent match already started';
    end if;
    update public.tournament_matches
    set team_a_id = case when target_match.next_slot = 0 then null else team_a_id end,
        team_b_id = case when target_match.next_slot = 1 then null else team_b_id end,
        status = 'pending'
    where id = dependent.id;
  end if;
  update public.tournament_matches
  set status = 'ready', score_a = null, score_b = null,
      winner_team_id = null, party_session_id = null,
      confirmed_by = null, confirmed_at = null
  where id = target_match.id;
  update public.tournaments
  set status = 'live', champion_team_id = null, completed_at = null
  where id = p_tournament_id;
  insert into public.tournament_events(tournament_id, actor_user_id, event_type, payload)
  values (p_tournament_id, caller.id, 'result_undone', jsonb_build_object('match_id', p_match_id));
  return true;
end;
$$;

create or replace function public.register_tournament_team(
  p_invite_code text,
  p_team_name text,
  p_roster jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target public.tournaments%rowtype;
  registration_id uuid;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'register_tournament_team', 20, interval '1 day');
  select * into target from public.tournaments
  where invite_code = trim(p_invite_code)::extensions.citext
    and visibility in ('invite', 'public') and status = 'registration';
  if not found then raise exception using errcode = 'P0002', message = 'Tournament registration not found'; end if;
  if jsonb_typeof(p_roster) <> 'array' or jsonb_array_length(p_roster) > target.players_per_team then
    raise exception using errcode = '22023', message = 'Invalid roster';
  end if;
  insert into public.tournament_registrations(tournament_id, requested_by, team_name, roster)
  values (target.id, caller.id, trim(p_team_name), p_roster)
  on conflict (tournament_id, requested_by) do update
  set team_name = excluded.team_name, roster = excluded.roster,
      status = 'pending', reviewed_by = null, reviewed_at = null
  returning id into registration_id;
  return registration_id;
end;
$$;

create or replace function public.review_tournament_registration(
  p_registration_id uuid,
  p_approve boolean
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  registration public.tournament_registrations%rowtype;
  target public.tournaments%rowtype;
  team_id uuid;
  player_value jsonb;
begin
  caller := public.require_active_user();
  select registration_row.* into registration
  from public.tournament_registrations registration_row
  join public.tournaments tournament on tournament.id = registration_row.tournament_id
  where registration_row.id = p_registration_id and tournament.organizer_id = caller.id
  for update of registration_row;
  if not found then raise exception using errcode = '42501', message = 'Registration not owned'; end if;
  select * into target from public.tournaments where id = registration.tournament_id for update;
  if target.status <> 'registration' then raise exception using errcode = '55000', message = 'Registration is closed'; end if;
  if p_approve and (select count(*) from public.tournament_teams where tournament_id = target.id and status = 'approved') >= target.capacity then
    raise exception using errcode = '22023', message = 'Tournament capacity reached';
  end if;
  update public.tournament_registrations
  set status = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by = caller.id, reviewed_at = clock_timestamp()
  where id = registration.id;
  if not p_approve then return null; end if;
  insert into public.tournament_teams(tournament_id, owner_user_id, name, status)
  values (target.id, registration.requested_by, registration.team_name, 'approved')
  returning id into team_id;
  for player_value in select value from jsonb_array_elements(registration.roster) loop
    insert into public.tournament_players(tournament_id, team_id, user_id, display_name, is_captain)
    values (
      target.id, team_id, (player_value ->> 'user_id')::uuid,
      trim(player_value ->> 'display_name'),
      coalesce((player_value ->> 'is_captain')::boolean, false)
    );
  end loop;
  return team_id;
end;
$$;

create or replace function public.get_my_tournament_stats()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select jsonb_build_object(
    'tournaments_played', count(distinct tournament.id),
    'tournaments_won', count(distinct tournament.id) filter (
      where tournament.champion_team_id = player.team_id
    )
  )
  from public.tournament_players player
  join public.tournaments tournament on tournament.id = player.tournament_id
  where player.user_id = auth.uid() and tournament.status = 'completed';
$$;

revoke all on function public.create_tournament(uuid, text, jsonb) from public;
revoke all on function public.save_tournament_bracket(uuid, jsonb, jsonb) from public;
revoke all on function public.confirm_tournament_match_result(uuid, uuid, integer, integer, uuid, uuid) from public;
revoke all on function public.undo_tournament_match_result(uuid, uuid) from public;
revoke all on function public.register_tournament_team(text, text, jsonb) from public;
revoke all on function public.review_tournament_registration(uuid, boolean) from public;
revoke all on function public.get_my_tournament_stats() from public;
grant execute on function public.create_tournament(uuid, text, jsonb) to authenticated;
grant execute on function public.save_tournament_bracket(uuid, jsonb, jsonb) to authenticated;
grant execute on function public.confirm_tournament_match_result(uuid, uuid, integer, integer, uuid, uuid) to authenticated;
grant execute on function public.undo_tournament_match_result(uuid, uuid) to authenticated;
grant execute on function public.register_tournament_team(text, text, jsonb) to authenticated;
grant execute on function public.review_tournament_registration(uuid, boolean) to authenticated;
grant execute on function public.get_my_tournament_stats() to authenticated;

-- The redesigned login consumes a dedicated CMS slot while reusing the already
-- published, generated asset. The local asset remains the offline-first fallback.
insert into public.app_content(
  key, section, content_type, label_ar, usage_ar,
  draft_media_id, published_media_id, is_active, version,
  draft_updated_by, published_by, draft_updated_at, published_at
)
select
  'auth.login.background', 'auth', 'image',
  'خلفية تسجيل الدخول', 'خلفية ممتدة لواجهة تسجيل الدخول',
  source.draft_media_id, source.published_media_id, true,
  greatest(source.version, 1), source.draft_updated_by, source.published_by,
  source.draft_updated_at, source.published_at
from public.app_content source
where source.key = 'branding.login.artwork'
on conflict (key) do update set
  published_media_id = excluded.published_media_id,
  is_active = true,
  version = greatest(public.app_content.version, excluded.version);

comment on table public.tournaments is
  'Organizer-owned single-elimination tournaments with immutable rule snapshots.';
comment on table public.tournament_events is
  'Append-only audit stream for bracket-sensitive actions.';
