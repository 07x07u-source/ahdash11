-- Client-facing contracts missing from the initial vertical slice.
-- Solo packs may contain their answer key because they are explicitly offline-capable;
-- ranked/online questions continue to use match_question_payloads without an answer key.

create or replace function public.get_solo_question_pack(
  p_limit integer default 100,
  p_category_ids uuid[] default null,
  p_difficulty public.question_difficulty default null
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
begin
  caller := public.require_active_user();
  if p_limit not between 1 and 250 then
    raise exception using errcode = '22023', message = 'Solo pack limit must be between 1 and 250';
  end if;

  return query
  select jsonb_build_object(
    'id', q.id,
    'question_text', q.question_text,
    'question_type', q.question_type,
    'image_url', q.image_url,
    'category_id', q.category_id,
    'subcategory_id', q.subcategory_id,
    'difficulty', q.difficulty,
    'options', jsonb_agg(qo.option_text order by qo.position),
    'correct_option_index', max(case when qo.id = q.correct_option_id then qo.position - 1 end),
    'tags', coalesce((
      select jsonb_agg(t.slug order by t.slug)
      from public.question_tags qt
      join public.tags t on t.id = qt.tag_id
      where qt.question_id = q.id
    ), '[]'::jsonb),
    'season', q.season,
    'club', q.club,
    'player', q.player,
    'competition', q.competition,
    'country', q.country
  )
  from public.questions q
  join public.question_options qo on qo.question_id = q.id
  left join public.question_history h
    on h.question_id = q.id and h.user_id = caller.id
  where q.status = 'published'
    and q.needs_review = false
    and 'solo'::public.match_mode = any(q.suitable_modes)
    and (p_category_ids is null or cardinality(p_category_ids) = 0 or q.category_id = any(p_category_ids))
    and (p_difficulty is null or q.difficulty = p_difficulty)
  group by q.id, h.last_seen_at
  having count(qo.id) = 4 and max(case when qo.id = q.correct_option_id then 1 else 0 end) = 1
  order by h.last_seen_at nulls first, q.times_played, q.id
  limit p_limit;
end;
$$;

create or replace function public.record_solo_answer(
  p_question_id uuid,
  p_selected_position smallint
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_question public.questions%rowtype;
  selected_option_id uuid;
  answer_correct boolean;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'record_solo_answer', 180, interval '1 minute');
  if p_selected_position not between 0 and 4 then
    raise exception using errcode = '22023', message = 'Selected position must be between 0 (timeout) and 4';
  end if;

  select * into target_question
  from public.questions
  where id = p_question_id
    and status = 'published'
    and needs_review = false
    and 'solo'::public.match_mode = any(suitable_modes);
  if not found then
    raise exception using errcode = 'P0002', message = 'Solo question is unavailable';
  end if;

  if p_selected_position > 0 then
    select id into selected_option_id
    from public.question_options
    where question_id = target_question.id and position = p_selected_position;
    if not found then
      raise exception using errcode = '22023', message = 'Selected option is unavailable';
    end if;
  end if;
  answer_correct := coalesce(selected_option_id = target_question.correct_option_id, false);

  insert into public.question_history(
    user_id, question_id, times_seen, correct_count, wrong_count,
    last_was_correct, first_seen_at, last_seen_at
  ) values (
    caller.id, target_question.id, 1,
    case when answer_correct then 1 else 0 end,
    case when answer_correct then 0 else 1 end,
    answer_correct, clock_timestamp(), clock_timestamp()
  )
  on conflict (user_id, question_id) do update
  set times_seen = public.question_history.times_seen + 1,
      correct_count = public.question_history.correct_count + case when answer_correct then 1 else 0 end,
      wrong_count = public.question_history.wrong_count + case when answer_correct then 0 else 1 end,
      last_was_correct = answer_correct,
      last_seen_at = clock_timestamp();

  return jsonb_build_object(
    'question_id', target_question.id,
    'was_correct', answer_correct,
    'recorded_at', clock_timestamp()
  );
end;
$$;

alter table public.matchmaking_queue
  add column if not exists question_count smallint not null default 15
    check (question_count between 1 and 50),
  add column if not exists settings jsonb not null default '{}'::jsonb
    check (jsonb_typeof(settings) = 'object');

create or replace function public.enqueue_matchmaking(
  p_category_ids uuid[] default '{}'::uuid[],
  p_question_count smallint default 15,
  p_region text default null,
  p_initial_range integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  candidate record;
  existing_match_id uuid;
  target_match_id uuid;
  selected_categories uuid[] := '{}'::uuid[];
  selected_question_count smallint;
  caller_range integer;
  queue_position integer;
begin
  caller := public.require_active_user();
  p_category_ids := coalesce(p_category_ids, '{}'::uuid[]);
  perform public.assert_rate_limit(caller.id::text, 'enqueue_matchmaking', 30, interval '1 minute');
  if p_question_count not between 1 and 50 then
    raise exception using errcode = '22023', message = 'Question count must be between 1 and 50';
  end if;
  if p_initial_range not between 25 and 1000 then
    raise exception using errcode = '22023', message = 'Initial rating range must be between 25 and 1000';
  end if;
  if exists (
    select 1 from unnest(p_category_ids) as requested(category_id)
    where not exists (
      select 1 from public.categories c
      where c.id = requested.category_id and c.is_active
    )
  ) then
    raise exception using errcode = '22023', message = 'One or more categories are unavailable';
  end if;

  -- A queued player discovers a match created by the opponent on the next heartbeat.
  select m.id into existing_match_id
  from public.match_players mp
  join public.matches m on m.id = mp.match_id
  where mp.user_id = caller.id
    and m.mode = 'quick_1v1'
    and m.status not in ('finished', 'cancelled')
    and m.created_at > clock_timestamp() - interval '10 minutes'
  order by m.created_at desc
  limit 1;
  if existing_match_id is not null then
    delete from public.matchmaking_queue where user_id = caller.id;
    return jsonb_build_object('status', 'matched', 'match_id', existing_match_id);
  end if;

  -- Serialize the short pairing decision; question population remains transactional.
  perform pg_advisory_xact_lock(hashtext('ahdash.quick_1v1.matchmaking'));
  delete from public.matchmaking_queue where expires_at <= clock_timestamp();

  caller_range := p_initial_range;
  select
    q.user_id,
    q.rating,
    q.initial_range,
    q.category_ids,
    q.question_count,
    q.region,
    q.enqueued_at,
    p.username,
    p.display_name,
    p.avatar_url
  into candidate
  from public.matchmaking_queue q
  join public.profiles p on p.id = q.user_id
  where q.user_id <> caller.id
    and q.mode = 'quick_1v1'
    and q.expires_at > clock_timestamp()
    and p.status = 'active'
    and (p_region is null or q.region is null or q.region = p_region)
    and (
      cardinality(p_category_ids) = 0
      or cardinality(q.category_ids) = 0
      or p_category_ids && q.category_ids
    )
    and abs(q.rating - caller.rating) <= greatest(
      p_initial_range + least(500, floor(extract(epoch from (clock_timestamp() - q.enqueued_at)) / 10)::integer * 50),
      q.initial_range + least(500, floor(extract(epoch from (clock_timestamp() - q.enqueued_at)) / 10)::integer * 50)
    )
  order by abs(q.rating - caller.rating), q.enqueued_at
  for update of q skip locked
  limit 1;

  if candidate.user_id is null then
    insert into public.matchmaking_queue(
      user_id, mode, rating, initial_range, region, category_ids,
      question_count, enqueued_at, heartbeat_at, expires_at
    ) values (
      caller.id, 'quick_1v1', caller.rating, p_initial_range,
      nullif(btrim(p_region), ''), p_category_ids, p_question_count,
      clock_timestamp(), clock_timestamp(), clock_timestamp() + interval '2 minutes'
    )
    on conflict (user_id) do update
    set rating = excluded.rating,
        initial_range = excluded.initial_range,
        region = excluded.region,
        category_ids = excluded.category_ids,
        question_count = excluded.question_count,
        heartbeat_at = clock_timestamp(),
        expires_at = clock_timestamp() + interval '2 minutes';

    select count(*)::integer into queue_position
    from public.matchmaking_queue q
    where q.mode = 'quick_1v1' and q.enqueued_at <= (
      select mine.enqueued_at from public.matchmaking_queue mine where mine.user_id = caller.id
    );
    select initial_range + least(
      500,
      floor(extract(epoch from (clock_timestamp() - enqueued_at)) / 10)::integer * 50
    ) into caller_range
    from public.matchmaking_queue where user_id = caller.id;
    return jsonb_build_object(
      'status', 'queued',
      'queue_position', queue_position,
      'current_rating_range', caller_range,
      'expires_in_seconds', 120
    );
  end if;

  selected_categories := case
    when cardinality(p_category_ids) = 0 then candidate.category_ids
    when cardinality(candidate.category_ids) = 0 then p_category_ids
    else array(
      select requested.category_id
      from unnest(p_category_ids) as requested(category_id)
      where requested.category_id = any(candidate.category_ids)
      order by requested.category_id
    )
  end;
  selected_question_count := least(p_question_count, candidate.question_count)::smallint;

  insert into public.matches(
    mode, status, created_by, category_ids, question_count,
    settings
  ) values (
    'quick_1v1', 'created', candidate.user_id, selected_categories,
    selected_question_count,
    jsonb_build_object('matchmaking_region', coalesce(p_region, candidate.region))
  ) returning id into target_match_id;

  insert into public.match_players(
    match_id, user_id, team, seat, display_name_snapshot, avatar_url_snapshot,
    status, rating_before, ready_at, last_connected_at
  ) values
    (
      target_match_id, candidate.user_id, 'a', 1,
      coalesce(candidate.display_name, candidate.username), candidate.avatar_url,
      'playing', candidate.rating, clock_timestamp(), clock_timestamp()
    ),
    (
      target_match_id, caller.id, 'b', 1,
      coalesce(caller.display_name, caller.username), caller.avatar_url,
      'playing', caller.rating, clock_timestamp(), clock_timestamp()
    );

  delete from public.matchmaking_queue where user_id in (caller.id, candidate.user_id);
  perform public.populate_match_questions(target_match_id);
  update public.matches set status = 'lobby' where id = target_match_id;
  update public.matches set status = 'ready' where id = target_match_id;
  update public.matches set status = 'countdown' where id = target_match_id;
  update public.matches set status = 'question' where id = target_match_id;
  perform public.open_match_question(target_match_id, 1::smallint);

  return jsonb_build_object(
    'status', 'matched',
    'match_id', target_match_id,
    'opponent', jsonb_build_object(
      'display_name', coalesce(candidate.display_name, candidate.username),
      'rating', candidate.rating,
      'avatar_url', candidate.avatar_url
    )
  );
end;
$$;

create or replace function public.cancel_matchmaking()
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  delete from public.matchmaking_queue where user_id = caller_id;
  return found;
end;
$$;

-- Quick matches have no room host. Either participant may advance after reveal;
-- the row lock and state transition make the first successful call authoritative.
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
  ) or (
    target_match.mode = 'quick_1v1' and public.is_match_participant(target_match.id, caller.id)
  ) or exists (
    select 1 from public.rooms where match_id = target_match.id and host_user_id = caller.id
  ) or public.has_role('moderator') into is_authorized;
  if not is_authorized then
    raise exception using errcode = '42501', message = 'Only a match participant or room authority can advance state';
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

revoke all on function public.get_solo_question_pack(integer, uuid[], public.question_difficulty) from public;
revoke all on function public.record_solo_answer(uuid, smallint) from public;
revoke all on function public.enqueue_matchmaking(uuid[], smallint, text, integer) from public;
revoke all on function public.cancel_matchmaking() from public;

grant execute on function public.get_solo_question_pack(integer, uuid[], public.question_difficulty) to authenticated;
grant execute on function public.record_solo_answer(uuid, smallint) to authenticated;
grant execute on function public.enqueue_matchmaking(uuid[], smallint, text, integer) to authenticated;
grant execute on function public.cancel_matchmaking() to authenticated;

comment on function public.get_solo_question_pack(integer, uuid[], public.question_difficulty) is
  'Offline-capable solo pack. Contains an answer index by design and must never be used for ranked matches.';
comment on function public.enqueue_matchmaking(uuid[], smallint, text, integer) is
  'Atomic quick-1v1 enqueue/heartbeat/pair operation with progressively widening rating range.';
