begin;

create extension if not exists pgtap with schema extensions;
select plan(18);

select has_table('public', 'store_action_receipts', 'retry receipts exist');
select is(
  (select relrowsecurity from pg_class where oid = 'public.store_action_receipts'::regclass),
  true,
  'receipt table has RLS enabled'
);
select is(
  has_table_privilege('authenticated', 'public.store_action_receipts', 'SELECT'),
  false,
  'clients cannot inspect internal purchase receipts'
);
select is(
  has_table_privilege('authenticated', 'public.store_action_receipts', 'INSERT'),
  false,
  'clients cannot forge purchase receipts'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.purchase_store_item_v2(uuid,text,bigint)',
    'EXECUTE'
  ),
  true,
  'authenticated players can reach the purchase contract'
);
select is(
  has_function_privilege(
    'anon',
    'public.purchase_store_item_v2(uuid,text,bigint)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot purchase'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.equip_store_item_v2(uuid,text,bigint)',
    'EXECUTE'
  ),
  true,
  'authenticated players can equip owned cosmetics'
);
select is(
  has_function_privilege(
    'anon',
    'public.equip_store_item_v2(uuid,text,bigint)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot equip cosmetics'
);
select is(
  (select prosecdef from pg_proc
   where oid = 'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure),
  true,
  'purchase contract is security definer'
);
select is(
  (select prosecdef from pg_proc
   where oid = 'public.equip_store_item_v2(uuid,text,bigint)'::regprocedure),
  true,
  'equip contract is security definer'
);
select ok(
  'search_path=pg_catalog, public' = any(
    (select proconfig from pg_proc
     where oid = 'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure)
  ),
  'purchase contract pins search_path'
);
select ok(
  position('already_owned' in pg_get_functiondef(
    'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure
  )) > 0,
  'double purchase is detected before a second debit'
);
select ok(
  position('target_balance < target_item.price_coins' in pg_get_functiondef(
    'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure
  )) > 0,
  'insufficient balance is handled without a client-provided price'
);
select ok(
  position('post_wallet_transaction' in pg_get_functiondef(
    'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure
  )) > 0,
  'purchase debits through the append-only wallet ledger'
);
select ok(
  position('p_price' in pg_get_functiondef(
    'public.purchase_store_item_v2(uuid,text,bigint)'::regprocedure
  )) = 0,
  'purchase contract accepts no client price'
);
select is(
  (select count(*)::integer from public.store_items
   where metadata ->> 'asset_rights' = 'original-generated-safe'
     and metadata ->> 'cosmetic_only' = 'true'
     and type = 'cosmetic'
     and not consumable),
  20,
  'launch catalog contains twenty non-consumable cosmetics'
);
select is(
  (select count(*)::integer from public.store_items
   where metadata ->> 'asset_rights' = 'original-generated-safe'
     and not ranked_allowed),
  0,
  'cosmetics do not alter ranked gameplay eligibility'
);
select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.store_action_receipts'::regclass
      and contype = 'u'
      and pg_get_constraintdef(oid) like '%user_id%action%idempotency_key%'
  ),
  'one retry receipt exists per user, action, and key'
);

select * from finish();
rollback;
