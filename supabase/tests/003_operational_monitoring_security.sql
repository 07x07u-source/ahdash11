begin;

create extension if not exists pgtap with schema extensions;
select plan(26);

select has_table('public', 'app_error_issues', 'deduplicated app issues exist');
select has_table('public', 'app_error_occurrences', 'app issue occurrence timeline exists');
select has_table('public', 'user_problem_reports', 'user problem reports exist');

select ok((select relrowsecurity from pg_class where oid = 'public.app_error_issues'::regclass), 'app issues have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.app_error_occurrences'::regclass), 'occurrences have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.user_problem_reports'::regclass), 'problem reports have RLS');

select is(has_table_privilege('authenticated', 'public.app_error_issues', 'INSERT'), false, 'clients cannot insert issues directly');
select is(has_table_privilege('authenticated', 'public.app_error_occurrences', 'INSERT'), false, 'clients cannot insert occurrences directly');
select is(has_table_privilege('authenticated', 'public.user_problem_reports', 'INSERT'), false, 'clients cannot insert reports directly');
select is(has_table_privilege('anon', 'public.app_error_issues', 'SELECT'), false, 'anonymous clients cannot inspect issues');
select is(has_table_privilege('anon', 'public.user_problem_reports', 'SELECT'), false, 'anonymous clients cannot inspect reports');

select is(has_function_privilege('authenticated', 'public.report_app_error(text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb)', 'EXECUTE'), true, 'authenticated app sessions can call the constrained error RPC');
select is(has_function_privilege('anon', 'public.report_app_error(text,text,text,text,text,text,text,text,text,text,text,text,text,jsonb)', 'EXECUTE'), false, 'anon role cannot call error RPC without an authenticated session');
select is(has_function_privilege('authenticated', 'public.submit_user_problem_report(text,text,text,text,text,text)', 'EXECUTE'), true, 'authenticated app sessions can submit a report through RPC');
select is(has_function_privilege('anon', 'public.submit_user_problem_report(text,text,text,text,text,text)', 'EXECUTE'), false, 'anon role cannot submit arbitrary reports');
select is(has_function_privilege('authenticated', 'public.sanitize_app_error_text(text,integer)', 'EXECUTE'), false, 'sanitizer is internal only');
select is(has_function_privilege('authenticated', 'public.validate_managed_app_content_value()', 'EXECUTE'), false, 'managed content trigger is not callable');
select is(has_function_privilege('authenticated', 'public.get_admin_dashboard_metrics()', 'EXECUTE'), true, 'staff can reach role-checked dashboard metrics');
select is(has_function_privilege('anon', 'public.get_admin_dashboard_metrics()', 'EXECUTE'), false, 'anonymous clients cannot reach dashboard metrics');

select is(public.sanitize_app_error_text('Authorization: Bearer secret-value-123', 200), 'Authorization=[redacted] [redacted]', 'authorization data is sanitized');
select is(public.sanitize_app_error_text('user@example.com failed', 200), '[redacted-email] failed', 'email addresses are sanitized');

select ok(exists(select 1 from public.app_content where key = 'branding.appicon.master'), 'app icon source key is seeded');
select ok(exists(select 1 from public.app_content where key = 'appearance.accent.color'), 'safe accent key is seeded');
select ok(exists(select 1 from public.app_content where key = 'feature.home.promotion'), 'home promotion control is seeded');
select is((select default_text_ar from public.app_content where key = 'feature.home.promotion'), 'false', 'remote promotion is safely off by default');
select ok(exists(select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'app_content_staff_insert'), 'expanded storage policy remains installed');

select * from finish();
rollback;
