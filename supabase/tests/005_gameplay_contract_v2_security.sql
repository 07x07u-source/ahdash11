begin;

create extension if not exists pgtap with schema extensions;
select plan(42);

select has_column('public', 'questions', 'offline_practice_eligible', 'offline answer-key export is explicit');
select has_column('public', 'questions', 'competitive_eligible', 'competitive eligibility is explicit');
select has_column('public', 'questions', 'gameplay_type', 'question gameplay type is separate from text/image media');
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.questions'::regclass
      and conname = 'questions_gameplay_type_check'
  ),
  'only implemented question gameplay contracts can be stored'
);
select ok(
  exists (
    select 1 from pg_trigger
    where tgrelid = 'public.questions'::regclass
      and tgname = 'questions_publishable_after_gameplay_type'
      and not tgisinternal
  ),
  'changing gameplay type revalidates published option shape'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.create_admin_question_v2(text,text,uuid,public.question_difficulty,text[],smallint,boolean,boolean)',
    'EXECUTE'
  ),
  true,
  'authenticated staff can reach the role-checked atomic question editor'
);
select is(
  has_function_privilege('authenticated', 'public.get_my_football_preferences()', 'EXECUTE'),
  true,
  'authenticated players can read their own private football preference ids'
);
select is(
  has_function_privilege('anon', 'public.get_my_football_preferences()', 'EXECUTE'),
  false,
  'anonymous callers cannot inspect football preference ids'
);
select has_column(
  'public',
  'team_challenge_answers',
  'idempotency_key',
  'challenge retries have an idempotency key'
);
select has_column(
  'public',
  'team_challenge_answers',
  'client_sequence',
  'challenge retries carry a client sequence'
);
select has_column(
  'public',
  'team_challenge_answers',
  'total_score_after',
  'challenge retries return the original stored score receipt'
);
select ok(
  to_regclass('public.team_challenge_answers_attempt_idempotency_uidx') is not null,
  'challenge idempotency index exists'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.submit_team_challenge_answer_v2(uuid,uuid,text,integer)',
    'EXECUTE'
  ),
  true,
  'authenticated players can submit retry-safe challenge answers'
);
select is(
  has_function_privilege(
    'anon',
    'public.submit_team_challenge_answer_v2(uuid,uuid,text,integer)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot submit challenge answers'
);
select ok(
  position('server_now' in pg_get_functiondef(
    'public.get_team_challenge_question(uuid)'::regprocedure
  )) > 0,
  'challenge question payload includes a server clock sample'
);
select ok(
  position('true-false' in pg_get_functiondef(
    'public.assert_question_publishable()'::regprocedure
  )) > 0,
  'publish validation enforces the two-option True/False contract'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.questions'::regclass
      and conname = 'questions_answer_exposure_separation'
  ),
  'one question cannot expose an answer offline and enter competition'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.matches'::regclass
      and conname = 'matches_minimum_competitive_questions'
  ),
  'new matches cannot use a reward-farming question count'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.rooms'::regclass
      and conname = 'rooms_minimum_competitive_questions'
  ),
  'new rooms cannot use a reward-farming question count'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.matchmaking_queue'::regclass
      and conname = 'matchmaking_minimum_competitive_questions'
  ),
  'new queue entries cannot request reward-farming matches'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.matches'::regclass
      and conname = 'matches_settings_allowlist'
  ),
  'match settings reject client-controlled score fields and unknown keys'
);
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.rooms'::regclass
      and conname = 'rooms_settings_allowlist'
  ),
  'room settings reject client-controlled score fields and unknown keys'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.enqueue_matchmaking_v2(uuid[],smallint,text,integer,text)',
    'EXECUTE'
  ),
  true,
  'authenticated players can reach type-aware matchmaking'
);
select is(
  has_function_privilege(
    'anon',
    'public.enqueue_matchmaking_v2(uuid[],smallint,text,integer,text)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot enter type-aware matchmaking'
);
select ok(
  position('speed_duration_ms' in pg_get_functiondef(
    'public.enqueue_matchmaking_v2(uuid[],smallint,text,integer,text)'::regprocedure
  )) > 0,
  'Speed duration is assigned by the server wrapper'
);
select ok(
  position('true_false_duration_ms' in pg_get_functiondef(
    'public.enqueue_matchmaking_v2(uuid[],smallint,text,integer,text)'::regprocedure
  )) > 0,
  'True/False duration and repopulation are assigned by the server wrapper'
);

select has_column('public', 'match_answers', 'idempotency_key', 'answer retries have an idempotency key');
select has_column('public', 'match_answers', 'client_sequence', 'answer retries carry a client sequence');
select has_column('public', 'match_answers', 'is_timeout', 'server timeouts are explicit');

select is(
  (select is_nullable from information_schema.columns
   where table_schema = 'public' and table_name = 'match_answers'
     and column_name = 'selected_match_option_id'),
  'YES',
  'timeout rows do not invent a selected option'
);

select ok(
  to_regclass('public.match_answers_player_idempotency_uidx') is not null,
  'idempotency index exists'
);

select is(
  has_function_privilege('authenticated', 'public.submit_match_answer_v2(uuid,uuid,text,integer)', 'EXECUTE'),
  true,
  'authenticated players can call v2 submission'
);
select is(
  has_function_privilege('anon', 'public.submit_match_answer_v2(uuid,uuid,text,integer)', 'EXECUTE'),
  false,
  'anonymous callers cannot submit answers'
);
select is(
  has_table_privilege('authenticated', 'public.match_answers', 'INSERT'),
  false,
  'clients still cannot forge answer rows'
);
select is(
  has_table_privilege('authenticated', 'public.match_answers', 'SELECT'),
  false,
  'clients still cannot inspect scored answers'
);

select ok(
  position('idempotency_key = p_idempotency_key' in pg_get_functiondef(
    'public.submit_match_answer_v2(uuid,uuid,text,integer)'::regprocedure
  )) > 0,
  'v2 returns the stored receipt for the same key'
);
select ok(
  position('is_timeout' in pg_get_functiondef(
    'public.reveal_match_question(uuid)'::regprocedure
  )) > 0,
  'reveal persists authoritative timeout answers'
);
select ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'match_question_payloads'
      and column_name = 'server_now'
  ),
  'safe question payload includes the server clock sample'
);

select ok(
  position('offline_practice_eligible' in pg_get_functiondef(
    'public.get_solo_question_pack(integer,uuid[],public.question_difficulty)'::regprocedure
  )) > 0,
  'offline pack is restricted to explicitly safe practice questions'
);
select ok(
  position('competitive_eligible' in pg_get_functiondef(
    'public.populate_match_questions(uuid)'::regprocedure
  )) > 0,
  'server match population uses only competitive questions'
);
select ok(
  position('settings ->> ''base_score''' in pg_get_functiondef(
    'public.populate_match_questions(uuid)'::regprocedure
  )) = 0
  and position('settings ->> ''max_speed_bonus''' in pg_get_functiondef(
    'public.populate_match_questions(uuid)'::regprocedure
  )) = 0,
  'legacy room settings cannot control authoritative score constants'
);
select ok(
  position('offline_practice_eligible' in pg_get_functiondef(
    'public.record_solo_answer(uuid,smallint)'::regprocedure
  )) > 0,
  'practice history cannot be recorded against competitive questions'
);

select * from finish();
rollback;
