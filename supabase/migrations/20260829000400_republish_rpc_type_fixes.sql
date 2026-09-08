-- Re-publish corrected RPC definitions with explicit PostgreSQL casts.
-- No game, matchmaking, room, or import behavior changes.

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
