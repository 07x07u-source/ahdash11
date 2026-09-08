-- Phase 5 safety patch.
-- Never mutate the applied tournaments_v1 migration: old clients may still
-- know its function signatures.  The destructive bracket RPC is revoked and
-- the Flutter client is moved to these versioned, retry-safe RPCs.

revoke execute on function public.save_tournament_bracket(uuid, jsonb, jsonb)
  from public, anon, authenticated;
revoke execute on function public.confirm_tournament_match_result(
  uuid, uuid, integer, integer, uuid, uuid
) from public, anon, authenticated;

create or replace function public.save_tournament_bracket_v2(
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
  player_value jsonb;
  supplied_team_ids uuid[];
  team_was_present boolean;
  round_count smallint;
  expected_a uuid;
  expected_b uuid;
  expected_status text;
  feeders_settled boolean;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(
    caller.id::text,
    'save_tournament_bracket_v2',
    20,
    interval '1 hour'
  );

  select * into target
  from public.tournaments
  where id = p_tournament_id and organizer_id = caller.id
  for update;
  if not found then
    raise exception using errcode = '42501', message = 'Tournament not owned';
  end if;

  if jsonb_typeof(p_teams) is distinct from 'array'
     or jsonb_typeof(p_matches) is distinct from 'array' then
    raise exception using
      errcode = '22023', message = 'Teams and matches must be arrays';
  end if;
  if jsonb_array_length(p_teams) < 2
     or jsonb_array_length(p_teams) > target.capacity then
    raise exception using errcode = '22023', message = 'Invalid team count';
  end if;
  if jsonb_array_length(p_matches) <> target.capacity - 1 then
    raise exception using errcode = '22023', message = 'Invalid match count';
  end if;

  -- Cast once after the shape checks. Invalid UUIDs fail the transaction before
  -- any write, and duplicate IDs/names/seeds are rejected explicitly.
  select array_agg((value ->> 'id')::uuid order by value ->> 'id')
  into supplied_team_ids
  from jsonb_array_elements(p_teams);

  if exists (
    select 1
    from jsonb_array_elements(p_teams) value
    where jsonb_typeof(value) is distinct from 'object'
      or value ->> 'id' is null
      or nullif(trim(value ->> 'name'), '') is null
      or (value ->> 'approved')::boolean is distinct from true
      or char_length(trim(value ->> 'name')) not between 2 and 40
      or jsonb_typeof(coalesce(value -> 'players', '[]'::jsonb)) <> 'array'
      or jsonb_array_length(coalesce(value -> 'players', '[]'::jsonb))
           > target.players_per_team
  ) then
    raise exception using errcode = '22023', message = 'Invalid team payload';
  end if;
  if (
    select count(*)
    from (
      select value ->> 'id'
      from jsonb_array_elements(p_teams) value
      group by value ->> 'id'
      having count(*) > 1
    ) duplicates
  ) > 0 then
    raise exception using errcode = '22023', message = 'Duplicate team id';
  end if;
  if (
    select count(*)
    from (
      select lower(trim(value ->> 'name'))
      from jsonb_array_elements(p_teams) value
      group by lower(trim(value ->> 'name'))
      having count(*) > 1
    ) duplicates
  ) > 0 then
    raise exception using errcode = '22023', message = 'Duplicate team name';
  end if;
  if (
    select count(*)
    from (
      select (value ->> 'seed')::smallint
      from jsonb_array_elements(p_teams) value
      where value ->> 'seed' is not null
      group by (value ->> 'seed')::smallint
      having count(*) > 1
    ) duplicates
  ) > 0 then
    raise exception using errcode = '22023', message = 'Duplicate team seed';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_teams) value
    where value ->> 'seed' is null
      or (value ->> 'seed')::smallint not between 1 and jsonb_array_length(p_teams)
  ) then
    raise exception using errcode = '22023', message = 'Invalid team seed';
  end if;
  if exists (
    select 1 from public.tournament_teams team
    where team.id = any(supplied_team_ids) and team.status <> 'approved'
  ) then
    raise exception using errcode = '22023', message = 'Ineligible team';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_teams) team,
      jsonb_array_elements(coalesce(team -> 'players', '[]'::jsonb)) player
    where jsonb_typeof(player) is distinct from 'string'
      or char_length(trim(player #>> '{}')) not between 1 and 50
  ) or exists (
    select 1 from jsonb_array_elements(p_teams) team,
      jsonb_array_elements_text(coalesce(team -> 'players', '[]'::jsonb)) player
    group by team ->> 'id', lower(trim(player)) having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'Invalid player roster';
  end if;
  if exists (
    select 1
    from public.tournament_teams team
    where team.id = any(supplied_team_ids)
      and team.tournament_id <> target.id
  ) then
    raise exception using errcode = '22023', message = 'Team belongs to another tournament';
  end if;
  if exists (
    select 1
    from public.tournament_teams team
    where team.tournament_id = target.id
      and team.status = 'approved'
      and not (team.id = any(supplied_team_ids))
  ) then
    raise exception using
      errcode = '55000', message = 'Approved teams are missing from the bracket';
  end if;

  round_count := (ln(target.capacity::numeric) / ln(2::numeric))::smallint;
  if exists (
    select 1
    from jsonb_array_elements(p_matches) value
    where jsonb_typeof(value) is distinct from 'object'
      or value ->> 'id' is null or value ->> 'round' is null
      or value ->> 'position' is null or value ->> 'status' is null
      or (value ->> 'round')::smallint not between 1 and round_count
      or (value ->> 'position')::smallint < 0
      or (value ->> 'position')::smallint >=
           power(2, round_count - (value ->> 'round')::smallint)::integer
      or (value ->> 'status') not in ('pending', 'ready', 'bye')
      or (value ->> 'team_a_id')::uuid is not null
         and not ((value ->> 'team_a_id')::uuid = any(supplied_team_ids))
      or (value ->> 'team_b_id')::uuid is not null
         and not ((value ->> 'team_b_id')::uuid = any(supplied_team_ids))
      or (value ->> 'winner_id')::uuid is not null
         and not ((value ->> 'winner_id')::uuid = any(supplied_team_ids))
      or value ->> 'score_a' is not null
      or value ->> 'score_b' is not null
      or value ->> 'party_session_id' is not null
      or value ->> 'confirmed_at' is not null
  ) then
    raise exception using errcode = '22023', message = 'Invalid match payload';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_matches) value
    where (
      value ->> 'status' = 'ready'
      and ((value ->> 'team_a_id') is null or (value ->> 'team_b_id') is null)
    ) or (
      (value ->> 'round')::smallint = round_count
      and ((value ->> 'next_match_id') is not null or (value ->> 'next_slot') is not null)
    ) or (
      (value ->> 'round')::smallint < round_count
      and ((value ->> 'next_match_id') is null
        or (value ->> 'next_slot') is null
        or (value ->> 'next_slot')::smallint <> (value ->> 'position')::smallint % 2)
    )
  ) then
    raise exception using errcode = '22023', message = 'Invalid match state';
  end if;

  -- Every eligible identity appears exactly once in the first round, including
  -- sparse capacities. Higher slots must be the actual feeder's bye winner.
  if exists (
    select 1 from unnest(supplied_team_ids) team_id
    where (select count(*) from jsonb_array_elements(p_matches) value
      where (value ->> 'round')::integer = 1 and
        (team_id = (value ->> 'team_a_id')::uuid or
         team_id = (value ->> 'team_b_id')::uuid)) <> 1
  ) then
    raise exception using errcode = '22023', message = 'Missing or repeated first round team';
  end if;
  for match_value in select value from jsonb_array_elements(p_matches) loop
    expected_a := (match_value ->> 'team_a_id')::uuid;
    expected_b := (match_value ->> 'team_b_id')::uuid;
    feeders_settled := (match_value ->> 'round')::integer = 1;
    if not feeders_settled then
      select (value ->> 'winner_id')::uuid into expected_a
      from jsonb_array_elements(p_matches) value
      where value ->> 'next_match_id' = match_value ->> 'id'
        and (value ->> 'next_slot')::integer = 0;
      select (value ->> 'winner_id')::uuid into expected_b
      from jsonb_array_elements(p_matches) value
      where value ->> 'next_match_id' = match_value ->> 'id'
        and (value ->> 'next_slot')::integer = 1;
      select count(*) = 2 and bool_and(value ->> 'status' = 'bye')
      into feeders_settled from jsonb_array_elements(p_matches) value
      where value ->> 'next_match_id' = match_value ->> 'id';
    end if;
    expected_status := case when expected_a is not null and expected_b is not null
      then 'ready' when feeders_settled then 'bye' else 'pending' end;
    if expected_a is not distinct from expected_b and expected_a is not null
       or expected_a is distinct from (match_value ->> 'team_a_id')::uuid
       or expected_b is distinct from (match_value ->> 'team_b_id')::uuid
       or expected_status is distinct from match_value ->> 'status'
       or (case when expected_status = 'bye' then coalesce(expected_a, expected_b)
           else null end) is distinct from (match_value ->> 'winner_id')::uuid then
      raise exception using errcode = '22023', message = 'Invalid propagated bracket state';
    end if;
  end loop;
  if (
    select count(*)
    from (
      select value ->> 'id'
      from jsonb_array_elements(p_matches) value
      group by value ->> 'id'
      having count(*) > 1
    ) duplicates
  ) > 0 or (
    select count(*)
    from (
      select value ->> 'round', value ->> 'position'
      from jsonb_array_elements(p_matches) value
      group by value ->> 'round', value ->> 'position'
      having count(*) > 1
    ) duplicates
  ) > 0 then
    raise exception using errcode = '22023', message = 'Duplicate match slot';
  end if;
  if exists (
    select 1
    from public.tournament_matches match
    join jsonb_array_elements(p_matches) value
      on match.id = (value ->> 'id')::uuid
    where match.tournament_id <> target.id
  ) then
    raise exception using errcode = '22023', message = 'Match belongs to another tournament';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_matches) value
    where (value ->> 'round')::smallint < round_count
      and not exists (
        select 1
        from jsonb_array_elements(p_matches) dependent(node)
        where (dependent.node ->> 'id')::uuid = (value ->> 'next_match_id')::uuid
          and (dependent.node ->> 'round')::smallint = (value ->> 'round')::smallint + 1
          and (dependent.node ->> 'position')::smallint =
                (value ->> 'position')::smallint / 2
      )
  ) then
    raise exception using errcode = '22023', message = 'Invalid bracket edge';
  end if;

  -- A retry after the first commit is a no-op only when every supplied row is
  -- byte-for-byte equivalent on authoritative fields. Any conflict stays locked.
  if target.status in ('live', 'completed') then
    if (select count(*) from public.tournament_matches where tournament_id = target.id)
         = jsonb_array_length(p_matches)
       and not exists (
         select 1
         from jsonb_array_elements(p_teams) value
         where not exists (
           select 1
           from public.tournament_teams team
           where team.id = (value ->> 'id')::uuid
             and team.tournament_id = target.id
             and team.status = 'approved'
             and team.name = trim(value ->> 'name')
             and team.seed is not distinct from (value ->> 'seed')::smallint
         )
       )
       and not exists (
         select 1
         from jsonb_array_elements(p_matches) value
         where not exists (
           select 1
           from public.tournament_matches match
           where match.id = (value ->> 'id')::uuid
             and match.tournament_id = target.id
             and match.round_number = (value ->> 'round')::smallint
             and match.position = (value ->> 'position')::smallint
             and match.status::text = value ->> 'status'
             and match.team_a_id is not distinct from (value ->> 'team_a_id')::uuid
             and match.team_b_id is not distinct from (value ->> 'team_b_id')::uuid
             and match.winner_team_id is not distinct from (value ->> 'winner_id')::uuid
             and match.next_match_id is not distinct from (value ->> 'next_match_id')::uuid
             and match.next_slot is not distinct from (value ->> 'next_slot')::smallint
             and match.score_a is null and match.score_b is null
             and match.party_session_id is null and match.confirmed_at is null
         )
       ) then
      return true;
    end if;
    raise exception using errcode = '55000', message = 'Bracket is already locked';
  end if;
  if target.status not in ('draft', 'registration', 'ready') then
    raise exception using errcode = '55000', message = 'Bracket is already locked';
  end if;
  if exists (
    select 1
    from public.tournament_matches match
    where match.tournament_id = target.id
      and (
        match.status in ('live', 'completed')
        or match.confirmed_at is not null
        or match.confirmed_by is not null
        or match.party_session_id is not null
      )
  ) then
    raise exception using
      errcode = '55000', message = 'Confirmed matches prevent bracket replacement';
  end if;

  -- Preserve all registered team ownership and roster rows. New organizer teams
  -- are inserted, while existing approved teams receive only bracket metadata.
  update public.tournament_teams
  set seed = null, updated_at = clock_timestamp()
  where tournament_id = target.id and id = any(supplied_team_ids);

  for team_value in select value from jsonb_array_elements(p_teams) loop
    select exists (
      select 1 from public.tournament_teams
      where id = (team_value ->> 'id')::uuid and tournament_id = target.id
    ) into team_was_present;

    insert into public.tournament_teams(
      id, tournament_id, owner_user_id, name, status, seed
    ) values (
      (team_value ->> 'id')::uuid,
      target.id,
      caller.id,
      trim(team_value ->> 'name'),
      'approved',
      (team_value ->> 'seed')::smallint
    )
    on conflict (id) do update
    set name = excluded.name,
        seed = excluded.seed,
        updated_at = clock_timestamp()
    where public.tournament_teams.tournament_id = target.id
      and public.tournament_teams.status = 'approved';

    if not team_was_present then
      for player_value in
        select value
        from jsonb_array_elements(coalesce(team_value -> 'players', '[]'::jsonb))
      loop
        if nullif(trim(player_value #>> '{}'), '') is not null then
          insert into public.tournament_players(
            tournament_id, team_id, display_name, is_captain
          ) values (
            target.id,
            (team_value ->> 'id')::uuid,
            trim(player_value #>> '{}'),
            false
          );
        end if;
      end loop;
    end if;
  end loop;

  -- Only replace an unconfirmed draft graph. No team or player row is deleted.
  delete from public.tournament_matches
  where tournament_id = target.id;

  for match_value in select value from jsonb_array_elements(p_matches) loop
    insert into public.tournament_matches(
      id, tournament_id, round_number, position, status,
      team_a_id, team_b_id, winner_team_id
    ) values (
      (match_value ->> 'id')::uuid,
      target.id,
      (match_value ->> 'round')::smallint,
      (match_value ->> 'position')::smallint,
      (match_value ->> 'status')::public.tournament_match_status,
      (match_value ->> 'team_a_id')::uuid,
      (match_value ->> 'team_b_id')::uuid,
      (match_value ->> 'winner_id')::uuid
    );
  end loop;
  for match_value in select value from jsonb_array_elements(p_matches) loop
    if match_value ->> 'next_match_id' is not null then
      update public.tournament_matches
      set next_match_id = (match_value ->> 'next_match_id')::uuid,
          next_slot = (match_value ->> 'next_slot')::smallint
      where id = (match_value ->> 'id')::uuid
        and tournament_id = target.id;
    end if;
  end loop;

  update public.tournaments
  set status = 'live',
      started_at = coalesce(started_at, clock_timestamp()),
      updated_at = clock_timestamp()
  where id = target.id;
  insert into public.tournament_events(
    tournament_id, actor_user_id, event_type, payload
  ) values (
    target.id,
    caller.id,
    'bracket_locked_v2',
    jsonb_build_object('team_count', jsonb_array_length(p_teams))
  );
  return true;
end;
$$;

create or replace function public.confirm_tournament_match_result_v2(
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
  perform public.assert_rate_limit(
    caller.id::text,
    'confirm_tournament_result_v2',
    120,
    interval '1 hour'
  );
  select * into target
  from public.tournaments
  where id = p_tournament_id and organizer_id = caller.id
  for update;
  if not found then
    raise exception using errcode = '42501', message = 'Tournament not owned';
  end if;
  select * into target_match
  from public.tournament_matches
  where id = p_match_id and tournament_id = target.id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match not found';
  end if;
  if p_score_a is null or p_score_b is null or p_score_a < 0 or p_score_b < 0 then
    raise exception using errcode = '22023', message = 'Invalid score';
  end if;
  if p_winner_team_id is null or target_match.team_a_id is null or target_match.team_b_id is null
     or p_winner_team_id not in (target_match.team_a_id, target_match.team_b_id) then
    raise exception using errcode = '22023', message = 'Winner is not a participant';
  end if;
  if (p_score_a > p_score_b and p_winner_team_id <> target_match.team_a_id)
     or (p_score_b > p_score_a and p_winner_team_id <> target_match.team_b_id) then
    raise exception using errcode = '22023', message = 'Winner conflicts with score';
  end if;

  -- Network retries return the original success without advancing twice.
  if target_match.status = 'completed' then
    if target_match.score_a = p_score_a
       and target_match.score_b = p_score_b
       and target_match.winner_team_id = p_winner_team_id
       and target_match.party_session_id is not distinct from p_party_session_id then
      return true;
    end if;
    raise exception using errcode = '55000', message = 'Result conflicts with confirmed match';
  end if;
  if target.status <> 'live' or target_match.status not in ('ready', 'live') then
    raise exception using errcode = '55000', message = 'Match is not ready';
  end if;
  if p_score_a = p_score_b and not target.tiebreaker_enabled then
    raise exception using errcode = '22023', message = 'Tied result is not allowed';
  end if;

  if target_match.next_match_id is not null then
    select * into next_match
    from public.tournament_matches
    where id = target_match.next_match_id and tournament_id = target.id
    for update;
    if not found then
      raise exception using errcode = 'P0002', message = 'Dependent match not found';
    end if;
    if next_match.status in ('live', 'completed') then
      raise exception using errcode = '55000', message = 'Dependent match already started';
    end if;
    if (target_match.next_slot = 0 and next_match.team_a_id is not null)
       or (target_match.next_slot = 1 and next_match.team_b_id is not null) then
      raise exception using errcode = '55000', message = 'Dependent slot is already occupied';
    end if;
  end if;

  update public.tournament_matches
  set status = 'completed',
      score_a = p_score_a,
      score_b = p_score_b,
      winner_team_id = p_winner_team_id,
      party_session_id = p_party_session_id,
      confirmed_by = caller.id,
      confirmed_at = clock_timestamp(),
      updated_at = clock_timestamp()
  where id = target_match.id;

  if target_match.next_match_id is null then
    update public.tournaments
    set status = 'completed',
        champion_team_id = p_winner_team_id,
        completed_at = clock_timestamp(),
        updated_at = clock_timestamp()
    where id = target.id;
  else
    update public.tournament_matches
    set team_a_id = case
          when target_match.next_slot = 0 then p_winner_team_id else team_a_id end,
        team_b_id = case
          when target_match.next_slot = 1 then p_winner_team_id else team_b_id end,
        status = case
          when (case when target_match.next_slot = 0
                  then p_winner_team_id else team_a_id end) is not null
           and (case when target_match.next_slot = 1
                  then p_winner_team_id else team_b_id end) is not null
            then 'ready'::public.tournament_match_status
          else 'pending'::public.tournament_match_status
        end,
        updated_at = clock_timestamp()
    where id = next_match.id;
  end if;

  insert into public.tournament_events(
    tournament_id, actor_user_id, event_type, payload
  ) values (
    target.id,
    caller.id,
    'result_confirmed_v2',
    jsonb_build_object(
      'match_id', target_match.id,
      'winner_team_id', p_winner_team_id,
      'score_a', p_score_a,
      'score_b', p_score_b,
      'party_session_id', p_party_session_id
    )
  );
  return true;
end;
$$;

revoke all on function public.save_tournament_bracket_v2(uuid, jsonb, jsonb)
  from public;
revoke all on function public.confirm_tournament_match_result_v2(
  uuid, uuid, integer, integer, uuid, uuid
) from public;
grant execute on function public.save_tournament_bracket_v2(uuid, jsonb, jsonb)
  to authenticated;
grant execute on function public.confirm_tournament_match_result_v2(
  uuid, uuid, integer, integer, uuid, uuid
) to authenticated;
