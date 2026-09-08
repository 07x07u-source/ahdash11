-- Gameplay contract v2: retry-safe submissions, an explicit server clock,
-- and fair timeout accounting. The applied social/football migration remains untouched.

alter table public.questions
  add column offline_practice_eligible boolean not null default false,
  add column competitive_eligible boolean not null default true,
  add column gameplay_type text not null default 'classic',
  add constraint questions_answer_exposure_separation check (
    not (offline_practice_eligible and competitive_eligible)
  ),
  add constraint questions_gameplay_type_check check (
    gameplay_type in ('classic', 'true-false')
  );

comment on column public.questions.offline_practice_eligible is
  'May be exported with its answer key only to the explicitly unranked offline Practice path.';
comment on column public.questions.competitive_eligible is
  'May be snapshotted into server-authoritative matches; must never share the offline answer-key pool.';
comment on column public.questions.gameplay_type is
  'Gameplay renderer contract. This is intentionally separate from question_type, which describes text/image media.';

create index questions_gameplay_pool_idx
  on public.questions(gameplay_type, status, competitive_eligible, category_id);

create or replace function public.assert_question_publishable()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  target_question public.questions%rowtype;
  target_question_id uuid;
  option_count integer;
  expected_option_count integer;
  true_false_label_count integer := 0;
  correct_question_id uuid;
begin
  if tg_table_name = 'questions' then
    target_question_id := coalesce(new.id, old.id);
  else
    target_question_id := coalesce(new.question_id, old.question_id);
  end if;

  select * into target_question
  from public.questions
  where id = target_question_id;

  if not found or target_question.status <> 'published' then
    return null;
  end if;

  expected_option_count := case
    when target_question.gameplay_type = 'true-false' then 2
    else 4
  end;

  select count(*) into option_count
  from public.question_options
  where question_id = target_question.id;

  if target_question.gameplay_type = 'true-false' then
    select count(*) into true_false_label_count
    from public.question_options
    where question_id = target_question.id
      and (
        (position = 1 and option_text = 'صح')
        or (position = 2 and option_text = 'خطأ')
      );
  end if;

  select question_id into correct_question_id
  from public.question_options
  where id = target_question.correct_option_id;

  if option_count <> expected_option_count
     or target_question.correct_option_id is null
     or correct_question_id is distinct from target_question.id
     or (
       target_question.gameplay_type = 'true-false'
       and true_false_label_count <> 2
     ) then
    raise exception using
      errcode = '23514',
      message = format(
        'Published %s questions require exactly %s options and one owned correct option',
        target_question.gameplay_type,
        expected_option_count
      );
  end if;
  return null;
end;
$$;

create constraint trigger questions_publishable_after_gameplay_type
after update of gameplay_type on public.questions
deferrable initially deferred
for each row execute function public.assert_question_publishable();

create or replace function public.create_admin_question_v2(
  p_question_text text,
  p_gameplay_type text,
  p_category_id uuid,
  p_difficulty public.question_difficulty,
  p_options text[],
  p_correct_position smallint,
  p_offline_practice_eligible boolean default false,
  p_competitive_eligible boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  clean_question_text text;
  clean_options text[];
  expected_option_count integer;
  question_id_value uuid;
  correct_option_id_value uuid;
  option_value text;
  option_position integer;
begin
  caller := public.require_active_user();
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator role required';
  end if;
  if p_gameplay_type not in ('classic', 'true-false') then
    raise exception using errcode = '22023', message = 'Unsupported gameplay type';
  end if;
  if p_offline_practice_eligible and p_competitive_eligible then
    raise exception using errcode = '22023', message = 'Practice answer-key content cannot enter competitive matches';
  end if;

  clean_question_text := btrim(
    regexp_replace(coalesce(p_question_text, ''), '[[:space:]]+', ' ', 'g')
  );
  if char_length(clean_question_text) not between 5 and 1000 then
    raise exception using errcode = '22023', message = 'Question text length is invalid';
  end if;

  select array_agg(
    btrim(regexp_replace(source.option_text, '[[:space:]]+', ' ', 'g'))
    order by source.ordinality
  )
  into clean_options
  from unnest(coalesce(p_options, '{}'::text[]))
    with ordinality as source(option_text, ordinality);

  expected_option_count := case when p_gameplay_type = 'true-false' then 2 else 4 end;
  if coalesce(cardinality(clean_options), 0) <> expected_option_count
     or p_correct_position not between 1 and expected_option_count then
    raise exception using errcode = '22023', message = 'Option count or correct position is invalid';
  end if;
  if exists (
    select 1 from unnest(clean_options) as cleaned(option_text)
    where char_length(cleaned.option_text) not between 1 and 300
  ) or (
    select count(distinct cleaned.option_text)
    from unnest(clean_options) as cleaned(option_text)
  ) <> expected_option_count then
    raise exception using errcode = '22023', message = 'Options must be non-empty and unique';
  end if;
  if p_gameplay_type = 'true-false'
     and clean_options is distinct from array['صح', 'خطأ']::text[] then
    raise exception using errcode = '22023', message = 'True/False options must be صح then خطأ';
  end if;

  insert into public.questions(
    question_text,
    question_type,
    category_id,
    difficulty,
    status,
    needs_review,
    created_by,
    gameplay_type,
    offline_practice_eligible,
    competitive_eligible
  ) values (
    clean_question_text,
    'text',
    p_category_id,
    p_difficulty,
    'draft',
    true,
    caller.id,
    p_gameplay_type,
    p_offline_practice_eligible,
    p_competitive_eligible
  ) returning id into question_id_value;

  for option_value, option_position in
    select source.option_text, source.ordinality::integer
    from unnest(clean_options) with ordinality as source(option_text, ordinality)
  loop
    insert into public.question_options(question_id, option_text, position)
    values (question_id_value, option_value, option_position::smallint)
    returning id into correct_option_id_value;
    if option_position = p_correct_position then
      update public.questions
      set correct_option_id = correct_option_id_value
      where id = question_id_value;
    end if;
  end loop;

  return jsonb_build_object(
    'id', question_id_value,
    'status', 'draft',
    'gameplay_type', p_gameplay_type,
    'needs_review', true
  );
end;
$$;

revoke all on function public.create_admin_question_v2(
  text,
  text,
  uuid,
  public.question_difficulty,
  text[],
  smallint,
  boolean,
  boolean
) from public, anon;
grant execute on function public.create_admin_question_v2(
  text,
  text,
  uuid,
  public.question_difficulty,
  text[],
  smallint,
  boolean,
  boolean
) to authenticated;

create or replace function public.get_my_football_preferences()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
begin
  caller := public.require_active_user();
  return jsonb_build_object(
    'league_id', caller.favorite_league_id,
    'club_id', caller.favorite_club_id,
    'show_publicly', caller.show_football_preferences
  );
end;
$$;

revoke all on function public.get_my_football_preferences()
  from public, anon;
grant execute on function public.get_my_football_preferences()
  to authenticated;

alter table public.team_challenge_answers
  add column idempotency_key text,
  add column client_sequence integer,
  add column total_score_after integer not null default 0,
  add column completed_after boolean not null default false,
  add column next_sequence_after smallint,
  add constraint team_challenge_answers_idempotency_pair check (
    (idempotency_key is null) = (client_sequence is null)
  ),
  add constraint team_challenge_answers_idempotency_key_length check (
    idempotency_key is null or char_length(idempotency_key) between 16 and 200
  ),
  add constraint team_challenge_answers_client_sequence_positive check (
    client_sequence is null or client_sequence > 0
  ),
  add constraint team_challenge_answers_receipt_shape check (
    total_score_after >= 0
    and (completed_after = false or next_sequence_after is null)
  );

create unique index team_challenge_answers_attempt_idempotency_uidx
  on public.team_challenge_answers(attempt_id, idempotency_key)
  where idempotency_key is not null;

create or replace function public.get_team_challenge_question(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  attempt public.team_challenge_attempts%rowtype;
  challenge public.team_challenges%rowtype;
  question public.team_challenge_questions%rowtype;
  options jsonb;
begin
  caller := public.require_active_user();
  select * into attempt
  from public.team_challenge_attempts
  where id = p_attempt_id and user_id = caller.id;
  if not found or attempt.status <> 'active' then
    raise exception using errcode = 'P0001', message = 'Attempt is not active';
  end if;
  select * into challenge
  from public.team_challenges
  where id = attempt.challenge_id;
  if challenge.team_id is not null
     and not public.is_social_team_member(challenge.team_id, caller.id) then
    raise exception using errcode = '42501', message = 'Team membership required';
  end if;
  select * into question
  from public.team_challenge_questions
  where challenge_id = challenge.id
    and sequence_number = attempt.current_sequence;
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', option.id,
        'text', option.option_text_snapshot,
        'position', option.position
      ) order by option.position
    ),
    '[]'::jsonb
  ) into options
  from public.team_challenge_options option
  where option.challenge_question_id = question.id;
  return jsonb_build_object(
    'attempt_id', attempt.id,
    'challenge_id', challenge.id,
    'challenge_title', challenge.title,
    'sequence', attempt.current_sequence,
    'question_count', challenge.question_count,
    'question_id', question.id,
    'question_text', question.question_text_snapshot,
    'question_type', question.question_type_snapshot,
    'image_url', question.image_url_snapshot,
    'duration_ms', challenge.question_duration_ms,
    'opened_at', attempt.question_opened_at,
    'closes_at', attempt.question_opened_at
      + make_interval(secs => challenge.question_duration_ms / 1000.0),
    'server_now', clock_timestamp(),
    'options', options,
    'score', attempt.score
  );
end;
$$;

create or replace function public.submit_team_challenge_answer_v2(
  p_attempt_id uuid,
  p_option_id uuid,
  p_idempotency_key text,
  p_client_sequence integer
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  attempt public.team_challenge_attempts%rowtype;
  challenge public.team_challenges%rowtype;
  question public.team_challenge_questions%rowtype;
  selected_option public.team_challenge_options%rowtype;
  existing_answer public.team_challenge_answers%rowtype;
  correct_option_id uuid;
  answer_id uuid;
  elapsed_ms integer;
  answer_correct boolean := false;
  awarded integer := 0;
  finished boolean;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(
    caller.id::text,
    'submit_team_challenge_answer',
    120,
    interval '1 minute'
  );
  if p_idempotency_key is null
     or char_length(p_idempotency_key) not between 16 and 200 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;
  if p_client_sequence is null or p_client_sequence <= 0 then
    raise exception using errcode = '22023', message = 'client_sequence must be positive';
  end if;

  select answer.* into existing_answer
  from public.team_challenge_answers answer
  join public.team_challenge_attempts owner_attempt
    on owner_attempt.id = answer.attempt_id
  where answer.attempt_id = p_attempt_id
    and answer.idempotency_key = p_idempotency_key
    and owner_attempt.user_id = caller.id;
  if found then
    if existing_answer.selected_option_id is distinct from p_option_id
       or existing_answer.client_sequence <> p_client_sequence then
      raise exception using errcode = '22023', message = 'Idempotency key was reused with a different challenge payload';
    end if;
    select id into correct_option_id
    from public.team_challenge_options
    where challenge_question_id = existing_answer.challenge_question_id
      and is_correct;
    return jsonb_build_object(
      'duplicate', true,
      'correct', existing_answer.is_correct,
      'score_awarded', existing_answer.score_awarded,
      'total_score', existing_answer.total_score_after,
      'correct_option_id', correct_option_id,
      'completed', existing_answer.completed_after,
      'next_sequence', existing_answer.next_sequence_after
    );
  end if;

  select * into attempt
  from public.team_challenge_attempts
  where id = p_attempt_id and user_id = caller.id
  for update;
  if not found or attempt.status <> 'active' then
    raise exception using errcode = 'P0001', message = 'Attempt is not active';
  end if;
  select * into challenge
  from public.team_challenges
  where id = attempt.challenge_id;
  if clock_timestamp() > challenge.ends_at then
    update public.team_challenge_attempts
    set status = 'expired'
    where id = attempt.id;
    return jsonb_build_object(
      'expired', true,
      'completed', false,
      'total_score', attempt.score,
      'duplicate', false
    );
  end if;
  select * into question
  from public.team_challenge_questions
  where challenge_id = challenge.id
    and sequence_number = attempt.current_sequence;
  if p_option_id is not null then
    select * into selected_option
    from public.team_challenge_options
    where id = p_option_id
      and challenge_question_id = question.id;
    if not found then
      raise exception using errcode = '22023', message = 'Option does not belong to question';
    end if;
  end if;

  elapsed_ms := greatest(
    0,
    floor(
      extract(epoch from (clock_timestamp() - attempt.question_opened_at)) * 1000
    )::integer
  );
  elapsed_ms := least(elapsed_ms, challenge.question_duration_ms);
  answer_correct := p_option_id is not null
    and selected_option.is_correct
    and clock_timestamp() <= attempt.question_opened_at
      + make_interval(secs => challenge.question_duration_ms / 1000.0);
  if answer_correct then
    awarded := 100 + floor(
      50 * (1 - elapsed_ms::numeric / challenge.question_duration_ms)
    )::integer;
  end if;
  select id into correct_option_id
  from public.team_challenge_options
  where challenge_question_id = question.id and is_correct;

  insert into public.team_challenge_answers(
    attempt_id,
    challenge_question_id,
    selected_option_id,
    is_correct,
    score_awarded,
    response_time_ms,
    idempotency_key,
    client_sequence
  ) values (
    attempt.id,
    question.id,
    p_option_id,
    answer_correct,
    awarded,
    elapsed_ms,
    p_idempotency_key,
    p_client_sequence
  ) returning id into answer_id;

  finished := attempt.current_sequence >= challenge.question_count;
  update public.team_challenge_attempts
  set score = score + awarded,
      correct_answers = correct_answers
        + case when answer_correct then 1 else 0 end,
      wrong_answers = wrong_answers
        + case when answer_correct then 0 else 1 end,
      total_response_time_ms = total_response_time_ms + elapsed_ms,
      status = case when finished then 'completed' else 'active' end,
      completed_at = case when finished then clock_timestamp() else null end,
      current_sequence = case
        when finished then current_sequence
        else current_sequence + 1
      end,
      question_opened_at = case
        when finished then question_opened_at
        else clock_timestamp()
      end
  where id = attempt.id
  returning * into attempt;

  update public.team_challenge_answers
  set total_score_after = attempt.score,
      completed_after = finished,
      next_sequence_after = case
        when finished then null
        else attempt.current_sequence
      end
  where id = answer_id;

  if finished then
    perform public.award_player_achievement(
      caller.id,
      'first_team_challenge',
      'challenge',
      attempt.challenge_id
    );
    if attempt.correct_answers >= 5 and attempt.wrong_answers = 0 then
      perform public.award_player_achievement(
        caller.id,
        'perfect_five',
        'challenge',
        attempt.challenge_id
      );
    end if;
  end if;

  return jsonb_build_object(
    'duplicate', false,
    'correct', answer_correct,
    'score_awarded', awarded,
    'total_score', attempt.score,
    'correct_option_id', correct_option_id,
    'completed', finished,
    'next_sequence', case when finished then null else attempt.current_sequence end
  );
end;
$$;

create or replace function public.submit_team_challenge_answer(
  p_attempt_id uuid,
  p_option_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  active_sequence integer;
begin
  select current_sequence into active_sequence
  from public.team_challenge_attempts
  where id = p_attempt_id;
  return public.submit_team_challenge_answer_v2(
    p_attempt_id,
    p_option_id,
    'legacy-challenge:' || p_attempt_id::text || ':' || coalesce(active_sequence, 0)::text,
    greatest(coalesce(active_sequence, 0), 1)
  );
end;
$$;

revoke all on function public.submit_team_challenge_answer_v2(
  uuid,
  uuid,
  text,
  integer
) from public, anon;
grant execute on function public.submit_team_challenge_answer_v2(
  uuid,
  uuid,
  text,
  integer
) to authenticated;

-- Reward-bearing matches must not be created as one-question farming loops.
-- NOT VALID preserves already-created rows while enforcing the rule for every new row.
alter table public.matches
  add constraint matches_minimum_competitive_questions check (
    question_count between 10 and 50
  ) not valid,
  add constraint matches_settings_allowlist check (
    settings - array[
      'difficulty',
      'opponent',
      'matchmaking_region',
      'question_duration_ms',
      'game_type'
    ]::text[] = '{}'::jsonb
    and (
      not (settings ? 'difficulty')
      or settings ->> 'difficulty' in ('easy', 'medium', 'hard', 'expert')
    )
    and (
      not (settings ? 'question_duration_ms')
      or case
        when settings ->> 'question_duration_ms' ~ '^[0-9]{4,6}$'
          then (settings ->> 'question_duration_ms')::integer between 5000 and 30000
        else false
      end
    )
    and (
      not (settings ? 'game_type')
      or settings ->> 'game_type' in ('classic', 'true-false', 'speed')
    )
  ) not valid;

alter table public.rooms
  add constraint rooms_minimum_competitive_questions check (
    question_count between 10 and 50
  ) not valid,
  add constraint rooms_settings_allowlist check (
    settings - array[
      'difficulty',
      'question_duration_ms',
      'game_type'
    ]::text[] = '{}'::jsonb
    and (
      not (settings ? 'difficulty')
      or settings ->> 'difficulty' in ('easy', 'medium', 'hard', 'expert')
    )
    and (
      not (settings ? 'question_duration_ms')
      or case
        when settings ->> 'question_duration_ms' ~ '^[0-9]{4,6}$'
          then (settings ->> 'question_duration_ms')::integer between 5000 and 30000
        else false
      end
    )
    and (
      not (settings ? 'game_type')
      or settings ->> 'game_type' in ('classic', 'true-false', 'speed')
    )
  ) not valid;

alter table public.matchmaking_queue
  add constraint matchmaking_minimum_competitive_questions check (
    question_count between 10 and 50
  ) not valid;

alter table public.match_answers
  add column idempotency_key text,
  add column client_sequence integer,
  add column is_timeout boolean not null default false;

alter table public.match_answers
  alter column selected_match_option_id drop not null,
  add constraint match_answers_idempotency_pair check (
    (idempotency_key is null) = (client_sequence is null)
  ),
  add constraint match_answers_idempotency_key_length check (
    idempotency_key is null or char_length(idempotency_key) between 16 and 200
  ),
  add constraint match_answers_client_sequence_positive check (
    client_sequence is null or client_sequence > 0
  ),
  add constraint match_answers_timeout_shape check (
    (
      is_timeout
      and selected_match_option_id is null
      and is_correct = false
      and score_awarded = 0
    )
    or (
      is_timeout = false
      and selected_match_option_id is not null
    )
  );

create unique index match_answers_player_idempotency_uidx
  on public.match_answers(match_player_id, idempotency_key)
  where idempotency_key is not null;

create or replace view public.match_question_payloads
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
  ) as options,
  clock_timestamp() as server_now,
  coalesce(m.settings ->> 'game_type', 'classic') as game_type
from public.match_questions mq
join public.matches m on m.id = mq.match_id
left join public.match_question_options mqo on mqo.match_question_id = mq.id
group by mq.id, m.settings;

comment on view public.match_question_payloads is
  'Client-safe online DTO with an authoritative clock sample. It deliberately contains no answer key or source option ids.';

create or replace function public.submit_match_answer_v2(
  p_match_question_id uuid,
  p_match_option_id uuid,
  p_idempotency_key text,
  p_client_sequence integer
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
  existing_answer public.match_answers%rowtype;
  correct_source_option_id uuid;
  answer_id uuid;
  received_time timestamptz := clock_timestamp();
  elapsed_ms integer;
  calculated_score integer;
  answer_correct boolean;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'submit_match_answer', 120, interval '1 minute');

  if p_idempotency_key is null
     or char_length(p_idempotency_key) not between 16 and 200 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;
  if p_client_sequence is null or p_client_sequence <= 0 then
    raise exception using errcode = '22023', message = 'client_sequence must be positive';
  end if;

  select * into target_question
  from public.match_questions
  where id = p_match_question_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match question not found';
  end if;

  select * into target_match
  from public.matches
  where id = target_question.match_id;

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

  select * into existing_answer
  from public.match_answers
  where match_player_id = target_player.id
    and idempotency_key = p_idempotency_key;
  if found then
    if existing_answer.match_question_id <> target_question.id
       or existing_answer.selected_match_option_id <> target_option.id
       or existing_answer.client_sequence <> p_client_sequence then
      raise exception using errcode = '22023', message = 'Idempotency key was reused with a different answer payload';
    end if;
    return jsonb_build_object(
      'accepted', true,
      'duplicate', true,
      'answer_id', existing_answer.id,
      'server_received_at', existing_answer.server_received_at,
      'question_closes_at', target_question.closes_at,
      'client_sequence', existing_answer.client_sequence
    );
  end if;

  select * into existing_answer
  from public.match_answers
  where match_question_id = target_question.id
    and match_player_id = target_player.id;
  if found then
    if existing_answer.is_timeout
       or existing_answer.selected_match_option_id is distinct from target_option.id then
      raise exception using errcode = 'P0001', message = 'Question already has a different final answer';
    end if;
    return jsonb_build_object(
      'accepted', true,
      'duplicate', true,
      'answer_id', existing_answer.id,
      'server_received_at', existing_answer.server_received_at,
      'question_closes_at', target_question.closes_at,
      'client_sequence', existing_answer.client_sequence
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
  from public.questions q
  where q.id = target_question.question_id;
  answer_correct := target_option.source_option_id = correct_source_option_id;
  elapsed_ms := least(
    target_question.duration_ms,
    greatest(
      0,
      floor(extract(epoch from (received_time - target_question.opened_at)) * 1000)::integer
    )
  );
  calculated_score := case when answer_correct then
    target_question.base_score + floor(
      target_question.max_speed_bonus * (target_question.duration_ms - elapsed_ms)::numeric
      / target_question.duration_ms
    )::integer
    else 0
  end;

  insert into public.match_answers(
    match_question_id,
    match_player_id,
    selected_match_option_id,
    is_correct,
    score_awarded,
    response_time_ms,
    server_received_at,
    idempotency_key,
    client_sequence
  ) values (
    target_question.id,
    target_player.id,
    target_option.id,
    answer_correct,
    calculated_score,
    elapsed_ms,
    received_time,
    p_idempotency_key,
    p_client_sequence
  )
  returning id into answer_id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  values (
    target_match.id,
    'answer_received',
    caller.id,
    target_match.state_version,
    jsonb_build_object(
      'match_question_id', target_question.id,
      'client_sequence', p_client_sequence
    )
  );

  return jsonb_build_object(
    'accepted', true,
    'duplicate', false,
    'answer_id', answer_id,
    'server_received_at', received_time,
    'question_closes_at', target_question.closes_at,
    'client_sequence', p_client_sequence
  );
end;
$$;

-- Keep the v1 signature compatible while routing every old client through the
-- same retry-safe implementation. The derived key is stable per user/question.
create or replace function public.submit_match_answer(
  p_match_question_id uuid,
  p_match_option_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;
  return public.submit_match_answer_v2(
    p_match_question_id,
    p_match_option_id,
    'legacy:' || auth.uid()::text || ':' || p_match_question_id::text,
    1
  );
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
  select * into target_question
  from public.match_questions
  where id = p_match_question_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match question not found';
  end if;
  if not public.is_match_participant(target_question.match_id, caller.id)
     and not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Not a match participant';
  end if;
  if target_question.status = 'revealed' then
    return public.get_match_question_result(target_question.id);
  end if;
  if target_question.status <> 'accepting' then
    raise exception using errcode = 'P0001', message = 'Question cannot be revealed';
  end if;

  select * into target_match
  from public.matches
  where id = target_question.match_id
  for update;

  select count(*) into human_players
  from public.match_players
  where match_id = target_match.id
    and user_id is not null
    and status not in ('left', 'invited');

  select count(*) into human_answers
  from public.match_answers a
  join public.match_players mp on mp.id = a.match_player_id
  where a.match_question_id = target_question.id
    and mp.user_id is not null;

  if clock_timestamp() < target_question.closes_at
     and human_answers < human_players then
    raise exception using errcode = 'P0001', message = 'Answer window is still open';
  end if;

  -- A missing human answer is an authoritative full-duration wrong answer.
  -- This prevents a timeout from winning the final tie-break with zero time.
  insert into public.match_answers(
    match_question_id,
    match_player_id,
    selected_match_option_id,
    is_correct,
    score_awarded,
    response_time_ms,
    server_received_at,
    is_timeout
  )
  select
    target_question.id,
    mp.id,
    null,
    false,
    0,
    target_question.duration_ms,
    target_question.closes_at,
    true
  from public.match_players mp
  where mp.match_id = target_match.id
    and mp.user_id is not null
    and mp.status not in ('left', 'invited')
    and not exists (
      select 1
      from public.match_answers a
      where a.match_question_id = target_question.id
        and a.match_player_id = mp.id
    )
  on conflict (match_question_id, match_player_id) do nothing;

  if target_match.mode = 'solo' then
    select mp.* into bot_player
    from public.match_players mp
    where mp.match_id = target_match.id
      and mp.system_opponent_id is not null;

    if found then
      select so.* into bot_config
      from public.system_opponents so
      where so.id = bot_player.system_opponent_id;
    end if;

    if bot_player.id is not null and not exists (
      select 1
      from public.match_answers
      where match_question_id = target_question.id
        and match_player_id = bot_player.id
    ) then
      bot_response_ms := least(
        target_question.duration_ms,
        greatest(
          500,
          bot_config.average_response_ms
            + floor((random() - 0.5) * 2 * bot_config.response_jitter_ms)::integer
        )
      );
      bot_correct := random() <= bot_config.correct_probability;
      if bot_correct then
        select mqo.id into bot_option_id
        from public.match_question_options mqo
        join public.questions q on q.id = target_question.question_id
        where mqo.match_question_id = target_question.id
          and mqo.source_option_id = q.correct_option_id;
      else
        select mqo.id into bot_option_id
        from public.match_question_options mqo
        join public.questions q on q.id = target_question.question_id
        where mqo.match_question_id = target_question.id
          and mqo.source_option_id <> q.correct_option_id
        order by random()
        limit 1;
      end if;

      insert into public.match_answers(
        match_question_id,
        match_player_id,
        selected_match_option_id,
        is_correct,
        score_awarded,
        response_time_ms,
        server_received_at
      ) values (
        target_question.id,
        bot_player.id,
        bot_option_id,
        bot_correct,
        case when bot_correct then
          target_question.base_score + floor(
            target_question.max_speed_bonus
              * (target_question.duration_ms - bot_response_ms)::numeric
              / target_question.duration_ms
          )::integer
          else 0
        end,
        bot_response_ms,
        target_question.opened_at + make_interval(secs => bot_response_ms / 1000.0)
      );
    end if;
  end if;

  update public.match_questions
  set status = 'locked'
  where id = target_question.id;
  update public.matches
  set status = 'answers_locked'
  where id = target_match.id;

  for answer_row in
    select id
    from public.match_answers
    where match_question_id = target_question.id
    order by created_at
  loop
    perform public.apply_answer_aggregate(answer_row.id);
  end loop;

  update public.match_questions
  set status = 'revealed', revealed_at = clock_timestamp()
  where id = target_question.id;
  update public.matches
  set status = 'result'
  where id = target_match.id;

  insert into public.match_events(match_id, event_type, actor_user_id, state_version, payload)
  select
    id,
    'question_revealed',
    caller.id,
    state_version,
    jsonb_build_object('match_question_id', target_question.id)
  from public.matches
  where id = target_match.id;

  return public.get_match_question_result(target_question.id);
end;
$$;

revoke all on function public.submit_match_answer_v2(uuid, uuid, text, integer)
  from public, anon;
grant execute on function public.submit_match_answer_v2(uuid, uuid, text, integer)
  to authenticated;

comment on function public.submit_match_answer_v2(uuid, uuid, text, integer) is
  'Retry-safe first-answer-wins RPC. Server time determines score; correctness remains secret until reveal.';

comment on function public.reveal_match_question(uuid) is
  'Reveals only after all humans answer or the server deadline passes; timeouts receive full-duration wrong-answer accounting.';

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
  select * into target_match
  from public.matches
  where id = target_match_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Match not found';
  end if;
  if exists (
    select 1 from public.match_questions where match_id = target_match_id
  ) then
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
        on h.question_id = q.id
        and h.user_id = target_match.created_by
      where q.status = 'published'
        and q.needs_review = false
        and q.competitive_eligible
        and q.gameplay_type = case
          when coalesce(target_match.settings ->> 'game_type', 'classic') = 'speed'
            then 'classic'
          else coalesce(target_match.settings ->> 'game_type', 'classic')
        end
        and target_match.mode = any(q.suitable_modes)
        and (
          cardinality(target_match.category_ids) = 0
          or q.category_id = any(target_match.category_ids)
        )
        and (
          target_match.settings ->> 'difficulty' is null
          or q.difficulty::text = target_match.settings ->> 'difficulty'
        )
    )
    select *
    from eligible
    order by category_round, last_seen_at nulls first, times_played, random()
    limit target_match.question_count
  loop
    inserted_count := inserted_count + 1;
    insert into public.match_questions(
      match_id,
      question_id,
      sequence_number,
      question_text_snapshot,
      question_type_snapshot,
      image_url_snapshot,
      category_id_snapshot,
      duration_ms,
      base_score,
      max_speed_bonus
    ) values (
      target_match.id,
      selected.id,
      inserted_count,
      selected.question_text,
      selected.question_type,
      selected.image_url,
      selected.category_id,
      case
        when target_match.settings ->> 'question_duration_ms' ~ '^[0-9]{4,6}$'
          then least(
            30000,
            greatest(
              5000,
              (target_match.settings ->> 'question_duration_ms')::integer
            )
          )
        else 15000
      end,
      100,
      50
    );

    insert into public.match_question_options(
      match_question_id,
      source_option_id,
      option_text_snapshot,
      position
    )
    select
      mq.id,
      qo.id,
      qo.option_text,
      row_number() over (order by random())::smallint
    from public.match_questions mq
    join public.question_options qo on qo.question_id = mq.question_id
    where mq.match_id = target_match.id
      and mq.sequence_number = inserted_count;
  end loop;

  if inserted_count <> target_match.question_count then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Not enough eligible questions: requested %s, found %s',
        target_match.question_count,
        inserted_count
      );
  end if;
  return inserted_count;
end;
$$;

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
    'gameplay_type', q.gameplay_type,
    'image_url', q.image_url,
    'category_id', q.category_id,
    'subcategory_id', q.subcategory_id,
    'difficulty', q.difficulty,
    'options', jsonb_agg(qo.option_text order by qo.position),
    'correct_option_index', max(
      case when qo.id = q.correct_option_id then qo.position - 1 end
    ),
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
    on h.question_id = q.id
    and h.user_id = caller.id
  where q.status = 'published'
    and q.needs_review = false
    and q.offline_practice_eligible
    and not q.competitive_eligible
    and 'solo'::public.match_mode = any(q.suitable_modes)
    and (
      p_category_ids is null
      or cardinality(p_category_ids) = 0
      or q.category_id = any(p_category_ids)
    )
    and (p_difficulty is null or q.difficulty = p_difficulty)
  group by q.id, h.last_seen_at
  having count(qo.id) = case when q.gameplay_type = 'true-false' then 2 else 4 end
    and max(case when qo.id = q.correct_option_id then 1 else 0 end) = 1
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
    and offline_practice_eligible
    and not competitive_eligible
    and 'solo'::public.match_mode = any(suitable_modes);
  if not found then
    raise exception using errcode = 'P0002', message = 'Solo practice question is unavailable';
  end if;

  if p_selected_position > 0 then
    select id into selected_option_id
    from public.question_options
    where question_id = target_question.id
      and position = p_selected_position;
    if not found then
      raise exception using errcode = '22023', message = 'Selected option is unavailable';
    end if;
  end if;
  answer_correct := coalesce(
    selected_option_id = target_question.correct_option_id,
    false
  );

  insert into public.question_history(
    user_id,
    question_id,
    times_seen,
    correct_count,
    wrong_count,
    last_was_correct,
    first_seen_at,
    last_seen_at
  ) values (
    caller.id,
    target_question.id,
    1,
    case when answer_correct then 1 else 0 end,
    case when answer_correct then 0 else 1 end,
    answer_correct,
    clock_timestamp(),
    clock_timestamp()
  )
  on conflict (user_id, question_id) do update
  set times_seen = public.question_history.times_seen + 1,
      correct_count = public.question_history.correct_count
        + case when answer_correct then 1 else 0 end,
      wrong_count = public.question_history.wrong_count
        + case when answer_correct then 0 else 1 end,
      last_was_correct = answer_correct,
      last_seen_at = clock_timestamp();

  return jsonb_build_object(
    'question_id', target_question.id,
    'was_correct', answer_correct,
    'recorded_at', clock_timestamp()
  );
end;
$$;

create or replace function public.enqueue_matchmaking_v2(
  p_category_ids uuid[] default '{}'::uuid[],
  p_question_count smallint default 15,
  p_region text default null,
  p_initial_range integer default 100,
  p_game_type text default 'classic'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  result_value jsonb;
  typed_region text;
  target_match_id uuid;
  speed_duration_ms constant integer := 7000;
  true_false_duration_ms constant integer := 10000;
  selected_duration_ms integer;
begin
  if p_game_type not in ('classic', 'true-false', 'speed') then
    raise exception using errcode = '22023', message = 'Unsupported game type';
  end if;

  -- The existing queue already matches equal regions. A server-owned type
  -- prefix keeps Classic and Speed players in separate pools without changing
  -- the applied queue table or duplicating its pairing algorithm.
  typed_region := p_game_type || ':' || coalesce(nullif(btrim(p_region), ''), '*');
  result_value := public.enqueue_matchmaking(
    p_category_ids,
    p_question_count,
    typed_region,
    p_initial_range
  );

  if result_value ->> 'status' = 'matched'
     and result_value ->> 'match_id' is not null then
    target_match_id := (result_value ->> 'match_id')::uuid;
    selected_duration_ms := case
      when p_game_type = 'speed' then speed_duration_ms
      when p_game_type = 'true-false' then true_false_duration_ms
      else 15000
    end;
    update public.matches
    set settings = settings || jsonb_build_object(
      'game_type',
      p_game_type,
      'question_duration_ms',
      selected_duration_ms
    )
    where id = target_match_id;

    if p_game_type = 'true-false' then
      -- The legacy matcher populates before its type-aware wrapper returns.
      -- Replace those still-invisible rows in the same transaction, now that
      -- the server-owned match settings select the two-option content pool.
      delete from public.match_questions where match_id = target_match_id;
      update public.matches
      set current_question_number = 0
      where id = target_match_id;
      perform public.populate_match_questions(target_match_id);
      perform public.open_match_question(target_match_id, 1::smallint);
    elsif p_game_type = 'speed' then
      update public.match_questions
      set duration_ms = selected_duration_ms,
          closes_at = case
            when opened_at is null then null
            else opened_at + make_interval(secs => selected_duration_ms / 1000.0)
          end
      where match_id = target_match_id;
    end if;
  end if;

  return result_value || jsonb_build_object('game_type', p_game_type);
end;
$$;

revoke all on function public.enqueue_matchmaking_v2(
  uuid[],
  smallint,
  text,
  integer,
  text
) from public, anon;
grant execute on function public.enqueue_matchmaking_v2(
  uuid[],
  smallint,
  text,
  integer,
  text
) to authenticated;

comment on function public.enqueue_matchmaking_v2(uuid[], smallint, text, integer, text) is
  'Type-aware matchmaking wrapper. Classic and Speed queues are isolated; Speed deadlines are written by the server.';
