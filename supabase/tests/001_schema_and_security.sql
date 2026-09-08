begin;

create extension if not exists pgtap with schema extensions;
select plan(54);

select has_table('public', 'profiles', 'profiles exists');
select has_table('public', 'categories', 'categories exists');
select has_table('public', 'questions', 'questions exists');
select has_table('public', 'question_options', 'question_options exists');
select has_table('public', 'match_answers', 'match_answers exists');
select has_table('public', 'wallet_transactions', 'wallet ledger exists');
select has_table('public', 'import_batches', 'import batches exist');
select has_table('public', 'import_rows', 'import rows exist');
select has_table('public', 'notification_deliveries', 'notification delivery audit exists');
select has_table('public', 'ad_reward_claims', 'verified ad reward claims exist');
select has_view('public', 'leaderboard', 'safe leaderboard view exists');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'profiles has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.questions'::regclass),
  'questions has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.match_answers'::regclass),
  'match answers has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.wallet_transactions'::regclass),
  'wallet transactions have RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.notification_deliveries'::regclass),
  'notification deliveries have RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.ad_reward_claims'::regclass),
  'ad reward claims have RLS enabled'
);

select is(
  has_column_privilege('authenticated', 'public.questions', 'question_text', 'SELECT'),
  true,
  'authenticated can read safe question text'
);
select is(
  has_column_privilege('authenticated', 'public.questions', 'correct_option_id', 'SELECT'),
  false,
  'authenticated cannot read the question answer key'
);
select is(
  has_column_privilege('authenticated', 'public.match_questions', 'question_id', 'SELECT'),
  false,
  'authenticated cannot map a match question back to its source question'
);
select is(
  has_column_privilege('authenticated', 'public.match_question_options', 'source_option_id', 'SELECT'),
  false,
  'authenticated cannot read source option ids'
);
select is(
  has_table_privilege('authenticated', 'public.match_answers', 'SELECT'),
  false,
  'authenticated has no direct access to scored answers'
);
select is(
  has_function_privilege('authenticated', 'public.submit_match_answer(uuid,uuid)', 'EXECUTE'),
  true,
  'authenticated can call the safe answer submission RPC'
);
select is(
  has_function_privilege('authenticated', 'public.post_wallet_transaction(uuid,bigint,public.wallet_transaction_type,text,text,text,text,jsonb,uuid)', 'EXECUTE'),
  false,
  'authenticated cannot call the internal wallet writer'
);
select is(
  has_function_privilege('authenticated', 'public.get_admin_question(uuid)', 'EXECUTE'),
  true,
  'authenticated role can reach the RPC whose body enforces moderator role'
);
select is(
  has_table_privilege('authenticated', 'public.notification_deliveries', 'INSERT'),
  false,
  'authenticated clients cannot forge notification deliveries'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.apply_revenuecat_subscription_event(uuid,text,text,text,text,text,timestamptz,timestamptz,timestamptz,timestamptz,jsonb)',
    'EXECUTE'
  ),
  false,
  'authenticated clients cannot forge RevenueCat state'
);
select is(
  has_function_privilege(
    'service_role',
    'public.apply_revenuecat_subscription_event(uuid,text,text,text,text,text,timestamptz,timestamptz,timestamptz,timestamptz,jsonb)',
    'EXECUTE'
  ),
  true,
  'only the service integration can apply RevenueCat state'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.claim_verified_admob_reward(text,uuid,text,text,numeric,timestamptz,jsonb)',
    'EXECUTE'
  ),
  false,
  'authenticated clients cannot mint rewarded-ad coins'
);
select is(
  has_function_privilege(
    'service_role',
    'public.claim_verified_admob_reward(text,uuid,text,text,numeric,timestamptz,jsonb)',
    'EXECUTE'
  ),
  true,
  'verified AdMob integration can grant its idempotent reward'
);
select is(
  has_table_privilege('authenticated', 'public.friend_requests', 'INSERT'),
  false,
  'friend requests cannot bypass the rate-limited RPC'
);
select is(
  has_table_privilege('authenticated', 'public.friends', 'DELETE'),
  false,
  'friend removal uses the canonical server RPC'
);
select is(
  has_table_privilege('authenticated', 'public.matchmaking_queue', 'INSERT'),
  false,
  'clients cannot forge queue rating or pairing inputs'
);
select is(
  has_function_privilege('authenticated', 'public.search_players(text,integer)', 'EXECUTE'),
  true,
  'authenticated players can search safe public profiles'
);
select is(
  has_function_privilege('authenticated', 'public.send_friend_request(uuid,text)', 'EXECUTE'),
  true,
  'authenticated players can send rate-limited friend requests'
);
select is(
  has_function_privilege('authenticated', 'public.respond_friend_request(uuid,boolean)', 'EXECUTE'),
  true,
  'authenticated players can respond to their requests'
);
select is(
  has_function_privilege('authenticated', 'public.accept_friend_request(uuid)', 'EXECUTE'),
  false,
  'legacy friend acceptance is hidden behind the unified response RPC'
);
select is(
  has_function_privilege('authenticated', 'public.get_friend_dashboard()', 'EXECUTE'),
  true,
  'authenticated players can read their friend dashboard'
);
select is(
  has_function_privilege('authenticated', 'public.invite_friend_to_room(uuid,uuid)', 'EXECUTE'),
  true,
  'friends can receive direct room invitations through the server'
);
select is(
  has_function_privilege('authenticated', 'public.get_my_profile_summary()', 'EXECUTE'),
  true,
  'profile summary composes safe stats, wallet, rank, and entitlement state'
);
select is(
  has_table_privilege('authenticated', 'public.leaderboard', 'SELECT'),
  true,
  'authenticated players can read the safe leaderboard projection'
);

select has_column(
  'public', 'matchmaking_queue', 'question_count',
  'matchmaking queue stores the agreed question count'
);
select has_column(
  'public', 'matchmaking_queue', 'settings',
  'matchmaking queue is ready for data-driven mode settings'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.get_solo_question_pack(integer,uuid[],public.question_difficulty)',
    'EXECUTE'
  ),
  true,
  'authenticated users can fetch the explicitly offline-capable solo pack'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.enqueue_matchmaking(uuid[],smallint,text,integer)',
    'EXECUTE'
  ),
  true,
  'authenticated users can call atomic quick matchmaking'
);

select is(public.normalize_question_text('  Hello---WORLD!!  '), 'hello world', 'normalization is deterministic');

select ok(
  not exists (
    select 1
    from public.questions q
    join public.question_options qo on qo.id = q.correct_option_id
    where qo.question_id <> q.id
  ),
  'every answer key belongs to its question'
);
select ok(
  not exists (
    select 1
    from public.questions q
    left join public.question_options qo on qo.question_id = q.id
    where q.status = 'published'
    group by q.id
    having count(qo.id) <> 4
  ),
  'every published question has four options'
);
select ok(
  (select count(*) >= 50 from public.questions where question_text like '[تجريبي]%'),
  'at least fifty clearly labelled demo questions are seeded'
);

select is(
  (
    public.validate_import_row_data(
      jsonb_build_object(
        'السؤال', '[اختبار] ما لون القميص في هذا السيناريو؟',
        'الخيار الأول', 'أخضر',
        'الخيار الثاني', 'أزرق',
        'الخيار الثالث', 'أحمر',
        'الخيار الرابع', 'أبيض',
        'الإجابة الصحيحة', 'أخضر'
      ),
      'eagle-eye.csv',
      (select id from public.categories where slug = 'eagle-eye')
    ) ->> 'status'
  ),
  'valid',
  'Arabic import headers validate without an external AI service'
);
select is(
  (
    public.validate_import_row_data(
      '{"question_text":"A valid sample question?","option_1":"A","option_2":"B","option_3":"C","option_4":"D","correct_answer":"missing"}'::jsonb,
      'sample.csv',
      (select id from public.categories where slug = 'eagle-eye')
    ) ->> 'status'
  ),
  'invalid',
  'an answer not present in the four options is invalid'
);

select ok(
  exists (select 1 from public.game_settings where key = 'match.default_question_count'),
  'default question count is data-driven'
);
select ok(
  exists (select 1 from public.system_opponents where slug = 'legend'),
  'legend system opponent is configured'
);
select ok(
  exists (select 1 from public.store_items where type = 'hint' and ranked_allowed = false),
  'pay-to-win hints are disabled for ranked modes'
);

select * from finish();
rollback;
