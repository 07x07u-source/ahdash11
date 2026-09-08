begin;

create extension if not exists pgtap with schema extensions;
select plan(10);

select is(
  (select prorettype::regtype::text from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  'uuid',
  'registration review keeps its uuid return type'
);
select is(
  (select proargtypes::regtype[]::text from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  '[0:1]={uuid,boolean}',
  'registration review keeps the exact uuid/boolean parameter signature'
);
select is(
  (select enum_range(null::public.tournament_team_status)::text),
  '{pending,approved,rejected,withdrawn}',
  'the Tournament team status enum retains its supported labels'
);
select is(
  (select prosecdef from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  true,
  'registration review remains SECURITY DEFINER'
);
select is(
  (select provolatile from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  'v'::"char",
  'registration review retains the default VOLATILE behavior'
);
select is(
  (select proisstrict from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  false,
  'registration review retains CALLED ON NULL INPUT behavior'
);
select is(
  (select proconfig @> array['search_path=pg_catalog, public']
   from pg_proc
   where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure),
  true,
  'registration review retains its fixed search path'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.review_tournament_registration(uuid,boolean)',
    'EXECUTE'
  ),
  true,
  'authenticated callers retain the intended RPC entry point'
);
select is(
  has_function_privilege(
    'anon',
    'public.review_tournament_registration(uuid,boolean)',
    'EXECUTE'
  ),
  false,
  'anonymous callers do not gain RPC execution'
);
select ok(
  position('''approved''::public.tournament_team_status' in pg_get_functiondef(
    'public.review_tournament_registration(uuid,boolean)'::regprocedure
  )) > 0
  and position('''rejected''::public.tournament_team_status' in pg_get_functiondef(
    'public.review_tournament_registration(uuid,boolean)'::regprocedure
  )) > 0,
  'both CASE branches are explicitly type-correct enum values'
);

select * from finish();
rollback;

