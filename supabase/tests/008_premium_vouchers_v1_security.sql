begin;

create extension if not exists pgtap with schema extensions;
select plan(31);

select has_table('public', 'premium_vouchers', 'premium voucher table exists');
select has_table('public', 'premium_promotional_entitlements', 'promotional entitlement table exists');
select col_is_unique('public', 'premium_vouchers', 'code_hash', 'voucher hashes are unique');
select col_is_unique('public', 'premium_promotional_entitlements', 'voucher_id', 'one entitlement per voucher');
select ok((select relrowsecurity from pg_class where oid = 'public.premium_vouchers'::regclass), 'voucher RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.premium_promotional_entitlements'::regclass), 'promo entitlement RLS enabled');

select is(has_table_privilege('anon', 'public.premium_vouchers', 'SELECT'), false, 'anon cannot read voucher hashes');
select is(has_table_privilege('authenticated', 'public.premium_vouchers', 'SELECT'), false, 'users cannot read voucher hashes');
select is(has_table_privilege('authenticated', 'public.premium_vouchers', 'INSERT'), false, 'users cannot create vouchers directly');
select is(has_table_privilege('authenticated', 'public.premium_vouchers', 'UPDATE'), false, 'users cannot mutate vouchers directly');
select is(has_table_privilege('authenticated', 'public.premium_promotional_entitlements', 'SELECT'), false, 'users cannot enumerate promo grants');
select is(has_table_privilege('authenticated', 'public.premium_promotional_entitlements', 'INSERT'), false, 'users cannot forge promo grants');

select is(has_function_privilege('anon', 'public.redeem_premium_voucher(text)', 'EXECUTE'), false, 'guests cannot redeem');
select is(has_function_privilege('authenticated', 'public.redeem_premium_voucher(text)', 'EXECUTE'), true, 'authenticated callers may invoke guarded redemption');
select is(has_function_privilege('authenticated', 'public.get_my_premium_access()', 'EXECUTE'), true, 'authenticated users may resolve own promo access');
select is(has_function_privilege('anon', 'public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)', 'EXECUTE'), false, 'anonymous callers cannot create vouchers');
select is(has_function_privilege('authenticated', 'public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)', 'EXECUTE'), true, 'admin RPC is callable then enforces role internally');
select is(has_function_privilege('authenticated', 'public.admin_list_premium_vouchers(integer)', 'EXECUTE'), true, 'admin list RPC is callable then enforces role internally');
select is(has_function_privilege('authenticated', 'public.admin_disable_premium_voucher(uuid)', 'EXECUTE'), true, 'admin disable RPC is callable then enforces role internally');

select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'for update', 'redemption locks voucher row');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'redeemed_at is null', 'redemption has compare-and-set guard');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'assert_rate_limit', 'redemption is rate limited');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'clock_timestamp', 'redemption uses server time');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'premium_voucher_runtime_enabled', 'redemption is feature gated');
select matches(pg_get_functiondef('public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)'::regprocedure), 'gen_random_bytes', 'codes use cryptographic randomness');
select matches(pg_get_functiondef('public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)'::regprocedure), 'has_role', 'creation checks admin role');
select matches(pg_get_functiondef('public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)'::regprocedure), 'premium_voucher_runtime_enabled', 'creation is server feature gated');
select matches(pg_get_functiondef('public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)'::regprocedure), 'between 1 and 50', 'bulk creation is bounded');
select matches(pg_get_functiondef('public.admin_create_premium_vouchers(public.premium_voucher_type,integer,text)'::regprocedure), 'Raw codes are returned exactly once', 'raw secret lifecycle is documented in function');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'interval ''1 month''', 'monthly promo uses one server month');
select matches(pg_get_functiondef('public.redeem_premium_voucher(text)'::regprocedure), 'interval ''1 year''', 'annual promo uses one server year');

select * from finish();
rollback;
