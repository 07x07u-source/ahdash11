-- Sensitive game operations. Every callable function derives identity from auth.uid().
alter table public.match_answers
  add column aggregated_at timestamptz;

drop trigger if exists match_answers_update_aggregates on public.match_answers;

create table public.api_rate_limits (
  subject text not null,
  bucket text not null,
  window_started_at timestamptz not null,
  request_count integer not null default 1 check (request_count > 0),
  primary key (subject, bucket)
);
alter table public.api_rate_limits enable row level security;
revoke all on public.api_rate_limits from public, anon, authenticated;

create or replace function public.assert_rate_limit(
  target_subject text,
  target_bucket text,
  max_requests integer,
  window_length interval
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_count integer;
begin
  if max_requests <= 0 or window_length <= interval '0 seconds' then
    raise exception using errcode = '22023', message = 'Invalid rate limit configuration';
  end if;

  insert into public.api_rate_limits(subject, bucket, window_started_at, request_count)
  values (target_subject, target_bucket, clock_timestamp(), 1)
  on conflict (subject, bucket) do update
  set window_started_at = case
        when public.api_rate_limits.window_started_at + window_length <= clock_timestamp()
          then clock_timestamp()
        else public.api_rate_limits.window_started_at
      end,
      request_count = case
        when public.api_rate_limits.window_started_at + window_length <= clock_timestamp()
          then 1
        else public.api_rate_limits.request_count + 1
      end
  returning request_count into current_count;

  if current_count > max_requests then
    raise exception using errcode = 'P0001', message = 'Rate limit exceeded';
  end if;
end;
$$;

create or replace function public.require_active_user()
returns public.profiles
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
begin
  if auth.uid() is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;

  select * into caller from public.profiles where id = auth.uid();
  if not found or caller.status <> 'active' or (caller.banned_until is not null and caller.banned_until > now()) then
    raise exception using errcode = '42501', message = 'Account is not active';
  end if;
  return caller;
end;
$$;

create or replace function public.populate_match_questions(target_match_id uuid)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_match public.matches%rowtype;
  selected record;
  inserted_count integer := 0;
begin
  select * into target_match from public.matches where id = target_match_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match not found';
  end if;
  if exists (select 1 from public.match_questions where match_id = target_match_id) then
    raise exception using errcode = '23505', message = 'Match questions already populated';
  end if;

  for selected in
    with eligible as (
      select
        q.*,
        h.last_seen_at,
        row_number() over (
          partition by q.category_id
          order by h.last_seen_at nulls first, q.times_played, random()
        ) as category_round
      from public.questions q
      left join public.question_history h
        on h.question_id = q.id and h.user_id = target_match.created_by
      where q.status = 'published'
        and q.needs_review = false
        and target_match.mode = any(q.suitable_modes)
        and (cardinality(target_match.category_ids) = 0 or q.category_id = any(target_match.category_ids))
        and (
          target_match.settings ->> 'difficulty' is null
          or q.difficulty::text = target_match.settings ->> 'difficulty'
        )
    )
    select * from eligible
    order by category_round, last_seen_at nulls first, times_played, random()
    limit target_match.question_count
  loop
    inserted_count := inserted_count + 1;
    insert into public.match_questions(
      match_id, question_id, sequence_number, question_text_snapshot,
      question_type_snapshot, image_url_snapshot, category_id_snapshot,
      duration_ms, base_score, max_speed_bonus
    ) values (
      target_match.id, selected.id, inserted_count, selected.question_text,
      selected.question_type, selected.image_url, selected.category_id,
      coalesce((target_match.settings ->> 'question_duration_ms')::integer, 15000),
      coalesce((target_match.settings ->> 'base_score')::integer, 100),
      coalesce((target_match.settings ->> 'max_speed_bonus')::integer, 50)
    );

    insert into public.match_question_options(
      match_question_id, source_option_id, option_text_snapshot, position
    )
    select
      mq.id,
      qo.id,
      qo.option_text,
      row_number() over (order by random())::smallint
    from public.match_questions mq
    join public.question_options qo on qo.question_id = mq.question_id
    where mq.match_id = target_match.id and mq.sequence_number = inserted_count;
  end loop;

  if inserted_count <> target_match.question_count then
    raise exception using errcode = 'P0001',
      message = format('Not enough eligible questions: requested %s, found %s', target_match.question_count, inserted_count);
  end if;
  return inserted_count;
end;
$$;

create or replace function public.open_match_question(target_match_id uuid, target_sequence smallint)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_question public.match_questions%rowtype;
  opened_time timestamptz := clock_timestamp();
begin
  select * into target_question
  from public.match_questions
  where match_id = target_match_id and sequence_number = target_sequence
  for update;

  if not found or target_question.status <> 'queued' then
    raise exception using errcode = 'P0001', message = 'Question is unavailable';
  end if;

  update public.match_questions
  set status = 'accepting',
      opened_at = opened_time,
      closes_at = opened_time + make_interval(secs => target_question.duration_ms / 1000.0)
  where id = target_question.id;

  update public.matches
  set current_question_number = target_sequence
  where id = target_match_id;
  return target_question.id;
end;
$$;

create or replace function public.start_solo_match(
  p_category_ids uuid[] default '{}',
  p_difficulty public.question_difficulty default null,
  p_question_count smallint default null,
  p_opponent_slug text default 'medium'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_match_id uuid;
  target_question_id uuid;
  bot public.system_opponents%rowtype;
  configured_count smallint;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'start_solo_match', 8, interval '1 minute');

  if exists (
    select 1 from unnest(coalesce(p_category_ids, '{}')) requested(id)
    left join public.categories c on c.id = requested.id and c.parent_id is null and c.is_active
    where c.id is null
  ) then
    raise exception using errcode = '22023', message = 'One or more categories are invalid';
  end if;

  configured_count := coalesce(
    p_question_count,
    (select (value #>> '{}')::smallint from public.game_settings where key = 'match.default_question_count'),
    15
  );
  if configured_count not between 1 and 50 then
    raise exception using errcode = '22023', message = 'question_count must be between 1 and 50';
  end if;

  select * into bot from public.system_opponents where slug = p_opponent_slug and is_active;
  if not found then
    raise exception using errcode = '22023', message = 'Unknown system opponent';
  end if;

  insert into public.matches(mode, status, created_by, category_ids, question_count, settings)
  values (
    'solo', 'created', caller.id, coalesce(p_category_ids, '{}'), configured_count,
    jsonb_strip_nulls(jsonb_build_object('difficulty', p_difficulty, 'opponent', bot.slug::text))
  ) returning id into target_match_id;

  insert into public.match_players(match_id, user_id, team, seat, display_name_snapshot, avatar_url_snapshot, rating_before)
  values (target_match_id, caller.id, 'a', 1, caller.display_name, caller.avatar_url, caller.rating);
  insert into public.match_players(match_id, system_opponent_id, team, seat, display_name_snapshot)
  values (target_match_id, bot.id, 'b', 1, bot.name_ar);

  update public.matches set status = 'lobby' where id = target_match_id;
  update public.matches set status = 'ready' where id = target_match_id;
  update public.matches set status = 'countdown' where id = target_match_id;
  perform public.populate_match_questions(target_match_id);
  target_question_id := public.open_match_question(target_match_id, 1::smallint);
  update public.matches set status = 'question' where id = target_match_id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select id, 'match_started', caller.id, state_version, jsonb_build_object('mode', mode)
  from public.matches where id = target_match_id;

  return jsonb_build_object(
    'match_id', target_match_id,
    'match_question_id', target_question_id,
    'state', 'question'
  );
end;
$$;

create or replace function public.generate_room_code()
returns text
language plpgsql
volatile
security definer
set search_path = pg_catalog, public
as $$
declare
  candidate text;
begin
  for attempt in 1..30 loop
    candidate := lpad(floor(random() * 1000000)::integer::text, 6, '0');
    if not exists (
      select 1 from public.rooms
      where code = candidate and status in ('open', 'locked') and expires_at > now()
    ) then
      return candidate;
    end if;
  end loop;
  raise exception using errcode = 'P0001', message = 'Could not allocate a room code';
end;
$$;

create or replace function public.create_room(
  p_mode public.match_mode,
  p_category_ids uuid[] default '{}',
  p_question_count smallint default null,
  p_settings jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_match_id uuid;
  target_room_id uuid;
  room_code text;
  member_limit smallint;
  configured_count smallint;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'create_room', 6, interval '1 minute');

  if p_mode not in ('friend_1v1', 'team_2v2') then
    raise exception using errcode = '22023', message = 'Private rooms support friend_1v1 or team_2v2';
  end if;
  if jsonb_typeof(coalesce(p_settings, '{}'::jsonb)) <> 'object' then
    raise exception using errcode = '22023', message = 'settings must be an object';
  end if;
  if exists (
    select 1 from unnest(coalesce(p_category_ids, '{}')) requested(id)
    left join public.categories c on c.id = requested.id and c.parent_id is null and c.is_active
    where c.id is null
  ) then
    raise exception using errcode = '22023', message = 'One or more categories are invalid';
  end if;

  configured_count := coalesce(
    p_question_count,
    (select (value #>> '{}')::smallint from public.game_settings where key = 'match.default_question_count'),
    15
  );
  if configured_count not between 1 and 50 then
    raise exception using errcode = '22023', message = 'question_count must be between 1 and 50';
  end if;

  member_limit := case when p_mode = 'team_2v2' then 4 else 2 end;
  room_code := public.generate_room_code();

  insert into public.matches(mode, status, created_by, category_ids, question_count, settings)
  values (p_mode, 'lobby', caller.id, coalesce(p_category_ids, '{}'), configured_count, coalesce(p_settings, '{}'))
  returning id into target_match_id;

  insert into public.match_players(match_id, user_id, team, seat, display_name_snapshot, avatar_url_snapshot, rating_before)
  values (target_match_id, caller.id, 'a', 1, caller.display_name, caller.avatar_url, caller.rating);

  insert into public.rooms(code, host_user_id, match_id, mode, max_members, category_ids, question_count, settings)
  values (room_code, caller.id, target_match_id, p_mode, member_limit, coalesce(p_category_ids, '{}'), configured_count, coalesce(p_settings, '{}'))
  returning id into target_room_id;

  insert into public.room_members(room_id, user_id, team, seat)
  values (target_room_id, caller.id, 'a', 1);

  return jsonb_build_object(
    'room_id', target_room_id,
    'room_code', room_code,
    'match_id', target_match_id,
    'mode', p_mode,
    'max_members', member_limit,
    'expires_at', (select expires_at from public.rooms where id = target_room_id)
  );
end;
$$;

create or replace function public.join_room(
  p_code text,
  p_preferred_team public.team_side default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_room public.rooms%rowtype;
  assigned_team public.team_side;
  assigned_seat smallint;
  member_count integer;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'join_room', 10, interval '1 minute');

  if coalesce(p_code, '') !~ '^[0-9]{6}$' then
    raise exception using errcode = '22023', message = 'Room code must contain six digits';
  end if;

  select * into target_room
  from public.rooms
  where code = p_code
  for update;

  if not found or target_room.status <> 'open' or target_room.expires_at <= now() then
    raise exception using errcode = 'P0002', message = 'Room is unavailable';
  end if;
  if exists (select 1 from public.room_members where room_id = target_room.id and user_id = caller.id) then
    return jsonb_build_object(
      'room_id', target_room.id,
      'match_id', target_room.match_id,
      'already_joined', true
    );
  end if;

  select count(*) into member_count
  from public.room_members
  where room_id = target_room.id and status not in ('left', 'kicked');
  if member_count >= target_room.max_members then
    raise exception using errcode = 'P0001', message = 'Room is full';
  end if;

  if target_room.mode = 'friend_1v1' then
    assigned_team := 'b';
    assigned_seat := 1;
  else
    assigned_team := case
      when p_preferred_team in ('a', 'b') and (
        select count(*) from public.room_members
        where room_id = target_room.id and team = p_preferred_team and status not in ('left', 'kicked')
      ) < 2 then p_preferred_team
      when (
        select count(*) from public.room_members
        where room_id = target_room.id and team = 'a' and status not in ('left', 'kicked')
      ) <= (
        select count(*) from public.room_members
        where room_id = target_room.id and team = 'b' and status not in ('left', 'kicked')
      ) then 'a'::public.team_side
      else 'b'::public.team_side
    end;
    select coalesce(max(seat), 0) + 1 into assigned_seat
    from public.room_members
    where room_id = target_room.id and team = assigned_team and status not in ('left', 'kicked');
  end if;

  insert into public.room_members(room_id, user_id, team, seat)
  values (target_room.id, caller.id, assigned_team, assigned_seat);
  insert into public.match_players(match_id, user_id, team, seat, display_name_snapshot, avatar_url_snapshot, rating_before)
  values (target_room.match_id, caller.id, assigned_team, assigned_seat, caller.display_name, caller.avatar_url, caller.rating);

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select id, 'player_joined', caller.id, state_version,
    jsonb_build_object('team', assigned_team, 'seat', assigned_seat)
  from public.matches where id = target_room.match_id;

  return jsonb_build_object(
    'room_id', target_room.id,
    'match_id', target_room.match_id,
    'team', assigned_team,
    'seat', assigned_seat,
    'already_joined', false
  );
end;
$$;

create or replace function public.set_room_ready(p_room_id uuid, p_ready boolean default true)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_member public.room_members%rowtype;
begin
  caller := public.require_active_user();
  select * into target_member
  from public.room_members
  where room_id = p_room_id and user_id = caller.id and status not in ('left', 'kicked')
  for update;
  if not found then
    raise exception using errcode = '42501', message = 'Not a room member';
  end if;

  update public.room_members
  set status = case when p_ready then 'ready'::public.room_member_status else 'joined'::public.room_member_status end,
      ready_at = case when p_ready then clock_timestamp() else null end,
      last_seen_at = clock_timestamp()
  where room_id = p_room_id and user_id = caller.id;
  update public.match_players
  set status = case when p_ready then 'ready'::public.match_player_status else 'joined'::public.match_player_status end,
      ready_at = case when p_ready then clock_timestamp() else null end
  where match_id = (select match_id from public.rooms where id = p_room_id)
    and user_id = caller.id;

  return jsonb_build_object('room_id', p_room_id, 'ready', p_ready);
end;
$$;

create or replace function public.start_room_match(p_room_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_room public.rooms%rowtype;
  active_members integer;
  ready_members integer;
  target_question_id uuid;
begin
  caller := public.require_active_user();
  select * into target_room from public.rooms where id = p_room_id for update;
  if not found or target_room.host_user_id <> caller.id then
    raise exception using errcode = '42501', message = 'Only the room host can start the match';
  end if;
  if target_room.status <> 'open' or target_room.expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'Room is unavailable';
  end if;

  select
    count(*) filter (where status not in ('left', 'kicked')),
    count(*) filter (where status = 'ready')
  into active_members, ready_members
  from public.room_members where room_id = target_room.id;

  if active_members <> target_room.max_members or ready_members <> active_members then
    raise exception using errcode = 'P0001', message = 'All room seats must be filled and ready';
  end if;

  update public.rooms set status = 'locked' where id = target_room.id;
  update public.matches set status = 'ready' where id = target_room.match_id;
  update public.matches set status = 'countdown' where id = target_room.match_id;
  perform public.populate_match_questions(target_room.match_id);
  target_question_id := public.open_match_question(target_room.match_id, 1::smallint);
  update public.matches set status = 'question' where id = target_room.match_id;
  update public.rooms set status = 'started' where id = target_room.id;
  update public.match_players set status = 'playing' where match_id = target_room.match_id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select id, 'match_started', caller.id, state_version, jsonb_build_object('room_id', target_room.id)
  from public.matches where id = target_room.match_id;

  return jsonb_build_object(
    'room_id', target_room.id,
    'match_id', target_room.match_id,
    'match_question_id', target_question_id,
    'state', 'question'
  );
end;
$$;

create or replace function public.submit_match_answer(
  p_match_question_id uuid,
  p_match_option_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_question public.match_questions%rowtype;
  target_match public.matches%rowtype;
  target_player public.match_players%rowtype;
  target_option public.match_question_options%rowtype;
  correct_source_option_id uuid;
  answer_id uuid;
  received_time timestamptz := clock_timestamp();
  elapsed_ms integer;
  calculated_score integer;
  answer_correct boolean;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'submit_match_answer', 120, interval '1 minute');

  select * into target_question
  from public.match_questions
  where id = p_match_question_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match question not found';
  end if;

  select * into target_match from public.matches where id = target_question.match_id;
  select * into target_player
  from public.match_players
  where match_id = target_question.match_id and user_id = caller.id
  for update;
  if not found then
    raise exception using errcode = '42501', message = 'Not a match participant';
  end if;

  select * into target_option
  from public.match_question_options
  where id = p_match_option_id and match_question_id = target_question.id;
  if not found then
    raise exception using errcode = '22023', message = 'Option does not belong to this match question';
  end if;

  select id into answer_id
  from public.match_answers
  where match_question_id = target_question.id and match_player_id = target_player.id;
  if found then
    return jsonb_build_object(
      'accepted', true,
      'duplicate', true,
      'answer_id', answer_id,
      'server_received_at', received_time
    );
  end if;

  if target_match.status <> 'question'
     or target_question.status <> 'accepting'
     or target_question.opened_at is null
     or target_question.closes_at is null
     or received_time > target_question.closes_at then
    raise exception using errcode = 'P0001', message = 'Answer window is closed';
  end if;

  select q.correct_option_id into correct_source_option_id
  from public.questions q where q.id = target_question.question_id;
  answer_correct := target_option.source_option_id = correct_source_option_id;
  elapsed_ms := least(
    target_question.duration_ms,
    greatest(0, floor(extract(epoch from (received_time - target_question.opened_at)) * 1000)::integer)
  );
  calculated_score := case when answer_correct then
    target_question.base_score + floor(
      target_question.max_speed_bonus * (target_question.duration_ms - elapsed_ms)::numeric
      / target_question.duration_ms
    )::integer
    else 0 end;

  insert into public.match_answers(
    match_question_id, match_player_id, selected_match_option_id,
    is_correct, score_awarded, response_time_ms, server_received_at
  ) values (
    target_question.id, target_player.id, target_option.id,
    answer_correct, calculated_score, elapsed_ms, received_time
  ) returning id into answer_id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  values (
    target_match.id, 'answer_received', caller.id, target_match.state_version,
    jsonb_build_object('match_question_id', target_question.id)
  );

  -- Deliberately omit correctness, score, and the correct option until reveal.
  return jsonb_build_object(
    'accepted', true,
    'duplicate', false,
    'answer_id', answer_id,
    'server_received_at', received_time,
    'question_closes_at', target_question.closes_at
  );
end;
$$;

create or replace function public.apply_answer_aggregate(target_answer_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  answer_row record;
begin
  select
    a.*, mq.question_id, mp.user_id
  into answer_row
  from public.match_answers a
  join public.match_questions mq on mq.id = a.match_question_id
  join public.match_players mp on mp.id = a.match_player_id
  where a.id = target_answer_id
  for update of a;

  if not found or answer_row.aggregated_at is not null then
    return;
  end if;

  update public.questions
  set times_played = times_played + 1,
      correct_answers = correct_answers + case when answer_row.is_correct then 1 else 0 end,
      wrong_answers = wrong_answers + case when answer_row.is_correct then 0 else 1 end,
      average_answer_time_ms =
        ((coalesce(average_answer_time_ms, 0) * difficulty_sample_size) + answer_row.response_time_ms)
        / (difficulty_sample_size + 1),
      difficulty_sample_size = difficulty_sample_size + 1
  where id = answer_row.question_id;

  update public.match_players
  set score = score + answer_row.score_awarded,
      correct_answers = correct_answers + case when answer_row.is_correct then 1 else 0 end,
      wrong_answers = wrong_answers + case when answer_row.is_correct then 0 else 1 end,
      total_answer_time_ms = total_answer_time_ms + answer_row.response_time_ms
  where id = answer_row.match_player_id;

  if answer_row.user_id is not null then
    insert into public.question_history(
      user_id, question_id, times_seen, correct_count, wrong_count,
      average_answer_time_ms, last_was_correct, first_seen_at, last_seen_at
    ) values (
      answer_row.user_id, answer_row.question_id, 1,
      case when answer_row.is_correct then 1 else 0 end,
      case when answer_row.is_correct then 0 else 1 end,
      answer_row.response_time_ms, answer_row.is_correct, now(), now()
    )
    on conflict (user_id, question_id) do update
    set times_seen = public.question_history.times_seen + 1,
        correct_count = public.question_history.correct_count + case when answer_row.is_correct then 1 else 0 end,
        wrong_count = public.question_history.wrong_count + case when answer_row.is_correct then 0 else 1 end,
        average_answer_time_ms =
          ((coalesce(public.question_history.average_answer_time_ms, 0) * public.question_history.times_seen) + answer_row.response_time_ms)
          / (public.question_history.times_seen + 1),
        last_was_correct = answer_row.is_correct,
        last_seen_at = now();
  end if;

  update public.match_answers set aggregated_at = clock_timestamp() where id = target_answer_id;
end;
$$;

create or replace function public.reveal_match_question(p_match_question_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_question public.match_questions%rowtype;
  target_match public.matches%rowtype;
  human_players integer;
  human_answers integer;
  bot_player public.match_players%rowtype;
  bot_config public.system_opponents%rowtype;
  bot_response_ms integer;
  bot_correct boolean;
  bot_option_id uuid;
  answer_row record;
begin
  caller := public.require_active_user();
  select * into target_question from public.match_questions where id = p_match_question_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match question not found';
  end if;
  if not public.is_match_participant(target_question.match_id, caller.id) and not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Not a match participant';
  end if;
  if target_question.status = 'revealed' then
    return public.get_match_question_result(target_question.id);
  end if;
  if target_question.status <> 'accepting' then
    raise exception using errcode = 'P0001', message = 'Question cannot be revealed';
  end if;

  select * into target_match from public.matches where id = target_question.match_id for update;
  select count(*) into human_players from public.match_players
  where match_id = target_match.id and user_id is not null and status not in ('left', 'invited');
  select count(*) into human_answers
  from public.match_answers a
  join public.match_players mp on mp.id = a.match_player_id
  where a.match_question_id = target_question.id and mp.user_id is not null;

  if clock_timestamp() < target_question.closes_at and human_answers < human_players then
    raise exception using errcode = 'P0001', message = 'Answer window is still open';
  end if;

  -- A solo bot answer is generated only on the server and never trusts the client.
  if target_match.mode = 'solo' then
    select mp.* into bot_player
    from public.match_players mp
    join public.system_opponents so on so.id = mp.system_opponent_id
    where mp.match_id = target_match.id and mp.system_opponent_id is not null;

    if found then
      select so.* into bot_config
      from public.system_opponents so
      where so.id = bot_player.system_opponent_id;
    end if;

    if bot_player.id is not null and not exists (
      select 1 from public.match_answers
      where match_question_id = target_question.id and match_player_id = bot_player.id
    ) then
      bot_response_ms := least(
        target_question.duration_ms,
        greatest(500, bot_config.average_response_ms + floor((random() - 0.5) * 2 * bot_config.response_jitter_ms)::integer)
      );
      bot_correct := random() <= bot_config.correct_probability;
      if bot_correct then
        select mqo.id into bot_option_id
        from public.match_question_options mqo
        join public.questions q on q.id = target_question.question_id
        where mqo.match_question_id = target_question.id and mqo.source_option_id = q.correct_option_id;
      else
        select mqo.id into bot_option_id
        from public.match_question_options mqo
        join public.questions q on q.id = target_question.question_id
        where mqo.match_question_id = target_question.id and mqo.source_option_id <> q.correct_option_id
        order by random() limit 1;
      end if;

      insert into public.match_answers(
        match_question_id, match_player_id, selected_match_option_id,
        is_correct, score_awarded, response_time_ms, server_received_at
      ) values (
        target_question.id, bot_player.id, bot_option_id, bot_correct,
        case when bot_correct then target_question.base_score + floor(
          target_question.max_speed_bonus * (target_question.duration_ms - bot_response_ms)::numeric
          / target_question.duration_ms
        )::integer else 0 end,
        bot_response_ms,
        target_question.opened_at + make_interval(secs => bot_response_ms / 1000.0)
      );
    end if;
  end if;

  update public.match_questions
  set status = 'locked'
  where id = target_question.id;
  update public.matches set status = 'answers_locked' where id = target_match.id;

  for answer_row in
    select id from public.match_answers where match_question_id = target_question.id order by created_at
  loop
    perform public.apply_answer_aggregate(answer_row.id);
  end loop;

  update public.match_questions
  set status = 'revealed', revealed_at = clock_timestamp()
  where id = target_question.id;
  update public.matches set status = 'result' where id = target_match.id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select id, 'question_revealed', caller.id, state_version,
    jsonb_build_object('match_question_id', target_question.id)
  from public.matches where id = target_match.id;

  return public.get_match_question_result(target_question.id);
end;
$$;

create or replace function public.get_match_question_result(p_match_question_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
  target_question public.match_questions%rowtype;
  correct_match_option_id uuid;
  answer_payload jsonb;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  select * into target_question from public.match_questions where id = p_match_question_id;
  if not found or (not public.is_match_participant(target_question.match_id, caller_id) and not public.has_role('moderator')) then
    raise exception using errcode = '42501', message = 'Result is unavailable';
  end if;
  if target_question.status <> 'revealed' or target_question.revealed_at is null then
    raise exception using errcode = 'P0001', message = 'Result is not revealed yet';
  end if;

  select mqo.id into correct_match_option_id
  from public.match_question_options mqo
  join public.questions q on q.id = target_question.question_id
  where mqo.match_question_id = target_question.id and mqo.source_option_id = q.correct_option_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'match_player_id', mp.id,
    'display_name', mp.display_name_snapshot,
    'team', mp.team,
    'selected_option_id', a.selected_match_option_id,
    'is_correct', a.is_correct,
    'score_awarded', a.score_awarded,
    'response_time_ms', a.response_time_ms
  ) order by mp.team, mp.seat), '[]'::jsonb)
  into answer_payload
  from public.match_players mp
  left join public.match_answers a
    on a.match_player_id = mp.id and a.match_question_id = target_question.id
  where mp.match_id = target_question.match_id and mp.status not in ('left', 'invited');

  return jsonb_build_object(
    'match_question_id', target_question.id,
    'correct_option_id', correct_match_option_id,
    'revealed_at', target_question.revealed_at,
    'answers', answer_payload
  );
end;
$$;

create or replace function public.advance_match(p_match_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_match public.matches%rowtype;
  next_number smallint;
  next_question_id uuid;
  is_authorized boolean;
begin
  caller := public.require_active_user();
  select * into target_match from public.matches where id = p_match_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match not found';
  end if;
  select (
    target_match.mode = 'solo' and target_match.created_by = caller.id
  ) or exists (
    select 1 from public.rooms where match_id = target_match.id and host_user_id = caller.id
  ) or public.has_role('moderator') into is_authorized;
  if not is_authorized then
    raise exception using errcode = '42501', message = 'Only the match authority can advance state';
  end if;
  if target_match.status <> 'result' then
    raise exception using errcode = 'P0001', message = 'Match is not ready to advance';
  end if;

  next_number := target_match.current_question_number + 1;
  if next_number <= target_match.question_count then
    update public.matches set status = 'next_question' where id = target_match.id;
    next_question_id := public.open_match_question(target_match.id, next_number);
    update public.matches set status = 'question' where id = target_match.id;
    return jsonb_build_object(
      'match_id', target_match.id,
      'state', 'question',
      'match_question_id', next_question_id,
      'sequence_number', next_number
    );
  end if;

  return public.finalize_match(target_match.id);
end;
$$;

revoke all on function public.assert_rate_limit(text, text, integer, interval) from public, anon, authenticated;
revoke all on function public.require_active_user() from public, anon, authenticated;
revoke all on function public.populate_match_questions(uuid) from public, anon, authenticated;
revoke all on function public.open_match_question(uuid, smallint) from public, anon, authenticated;
revoke all on function public.generate_room_code() from public, anon, authenticated;
revoke all on function public.apply_answer_aggregate(uuid) from public, anon, authenticated;

revoke all on function public.start_solo_match(uuid[], public.question_difficulty, smallint, text) from public;
revoke all on function public.create_room(public.match_mode, uuid[], smallint, jsonb) from public;
revoke all on function public.join_room(text, public.team_side) from public;
revoke all on function public.set_room_ready(uuid, boolean) from public;
revoke all on function public.start_room_match(uuid) from public;
revoke all on function public.submit_match_answer(uuid, uuid) from public;
revoke all on function public.reveal_match_question(uuid) from public;
revoke all on function public.get_match_question_result(uuid) from public;
revoke all on function public.advance_match(uuid) from public;

grant execute on function public.start_solo_match(uuid[], public.question_difficulty, smallint, text) to authenticated;
grant execute on function public.create_room(public.match_mode, uuid[], smallint, jsonb) to authenticated;
grant execute on function public.join_room(text, public.team_side) to authenticated;
grant execute on function public.set_room_ready(uuid, boolean) to authenticated;
grant execute on function public.start_room_match(uuid) to authenticated;
grant execute on function public.submit_match_answer(uuid, uuid) to authenticated;
grant execute on function public.reveal_match_question(uuid) to authenticated;
grant execute on function public.get_match_question_result(uuid) to authenticated;
grant execute on function public.advance_match(uuid) to authenticated;

comment on function public.submit_match_answer(uuid, uuid) is
  'First answer wins. Uses server receipt time and returns acceptance only; correctness and score remain secret until reveal.';
comment on function public.get_match_question_result(uuid) is
  'Returns the answer key and scored answers only after match_questions.status becomes revealed.';
