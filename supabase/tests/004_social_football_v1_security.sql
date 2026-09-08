begin;

create extension if not exists pgtap with schema extensions;
select plan(46);

select has_table('public', 'football_countries', 'football countries exist');
select has_table('public', 'football_leagues', 'football leagues exist');
select has_table('public', 'football_clubs', 'rights-aware football clubs exist');
select has_table('public', 'user_blocks', 'player blocks exist');
select has_table('public', 'social_teams', 'private social teams exist');
select has_table('public', 'social_team_members', 'social memberships exist');
select has_table('public', 'social_team_invites', 'private team invites exist');
select has_table('public', 'team_challenges', 'team challenges exist');
select has_table('public', 'team_challenge_questions', 'challenge snapshots exist');
select has_table('public', 'team_challenge_options', 'server option snapshots exist');
select has_table('public', 'team_challenge_attempts', 'server attempts exist');
select has_table('public', 'team_challenge_answers', 'server answers exist');
select has_table('public', 'social_reports', 'social moderation reports exist');

select ok((select relrowsecurity from pg_class where oid = 'public.football_countries'::regclass), 'football countries have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.football_clubs'::regclass), 'football clubs have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.social_teams'::regclass), 'social teams have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.social_team_members'::regclass), 'memberships have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.team_challenges'::regclass), 'team challenges have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.team_challenge_attempts'::regclass), 'attempts have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.team_challenge_options'::regclass), 'option snapshots have RLS');

select is(has_table_privilege('anon', 'public.football_clubs', 'SELECT'), true, 'anonymous onboarding can read active catalog through RLS');
select is(has_table_privilege('authenticated', 'public.team_challenge_questions', 'SELECT'), false, 'clients cannot inspect question snapshots');
select is(has_table_privilege('authenticated', 'public.team_challenge_options', 'SELECT'), false, 'clients cannot inspect answer keys');
select is(has_table_privilege('authenticated', 'public.team_challenge_answers', 'SELECT'), false, 'clients cannot inspect scored answers');
select is(has_table_privilege('authenticated', 'public.team_challenge_attempts', 'INSERT'), false, 'clients cannot forge challenge attempts');
select is(has_table_privilege('authenticated', 'public.team_challenge_attempts', 'UPDATE'), false, 'clients cannot forge challenge scores');
select is(has_table_privilege('authenticated', 'public.social_teams', 'INSERT'), false, 'clients create teams only through RPC');
select is(has_table_privilege('authenticated', 'public.football_clubs', 'INSERT'), true, 'staff write grant remains guarded by admin RLS');

select is(has_function_privilege('anon', 'public.list_football_leagues(uuid)', 'EXECUTE'), true, 'onboarding can list leagues');
select is(has_function_privilege('anon', 'public.search_football_clubs(text,uuid,integer,integer)', 'EXECUTE'), true, 'onboarding can search clubs');
select is(has_function_privilege('anon', 'public.set_football_preferences(uuid,uuid,boolean)', 'EXECUTE'), false, 'anonymous users cannot save preferences');
select is(has_function_privilege('authenticated', 'public.set_football_preferences(uuid,uuid,boolean)', 'EXECUTE'), true, 'players can save preferences safely');
select is(has_function_privilege('authenticated', 'public.search_players(text,integer)', 'EXECUTE'), true, 'players can use block-aware search');
select is(has_function_privilege('authenticated', 'public.block_player(uuid)', 'EXECUTE'), true, 'players can block safely');
select is(has_function_privilege('authenticated', 'public.get_blocked_players()', 'EXECUTE'), true, 'players can review their own block list');
select is(has_function_privilege('authenticated', 'public.report_social_subject(text,uuid,text,text)', 'EXECUTE'), true, 'players can report safely');
select is(has_function_privilege('authenticated', 'public.create_social_team(text,text,text,text)', 'EXECUTE'), true, 'players can create a private team through RPC');
select is(has_function_privilege('authenticated', 'public.join_social_team(text)', 'EXECUTE'), true, 'players can join with a private code');
select is(has_function_privilege('authenticated', 'public.create_team_challenge(uuid,text,uuid,integer,timestamptz,timestamptz,integer,text)', 'EXECUTE'), true, 'team admins can reach role-checked challenge creation');
select is(has_function_privilege('authenticated', 'public.set_social_team_member_role(uuid,uuid,text)', 'EXECUTE'), true, 'team owners can reach role-checked member role updates');
select is(has_function_privilege('authenticated', 'public.review_social_report(uuid,text,text)', 'EXECUTE'), true, 'moderators can reach role-checked report review');
select is(has_function_privilege('authenticated', 'public.start_team_challenge_attempt(uuid)', 'EXECUTE'), true, 'members can start server attempts');
select is(has_function_privilege('authenticated', 'public.get_team_challenge_question(uuid)', 'EXECUTE'), true, 'members can fetch safe current questions');
select is(has_function_privilege('authenticated', 'public.submit_team_challenge_answer(uuid,uuid)', 'EXECUTE'), true, 'members can submit answers to the server');
select is(has_function_privilege('authenticated', 'public.get_team_challenge_result(uuid)', 'EXECUTE'), true, 'members can read verified results');
select is(has_function_privilege('anon', 'public.get_team_challenge_result(uuid)', 'EXECUTE'), false, 'anonymous users cannot read private results');

select * from finish();
rollback;
