begin;

create extension if not exists pgtap with schema extensions;
select plan(21);

select is(has_function_privilege('authenticated',
  'public.confirm_tournament_match_result(uuid,uuid,integer,integer,uuid,uuid)',
  'EXECUTE'), false, 'legacy result writer cannot bypass v2 validation');

select is(
  has_function_privilege(
    'authenticated',
    'public.save_tournament_bracket(uuid,jsonb,jsonb)',
    'EXECUTE'
  ),
  false,
  'the destructive v1 bracket writer is disabled for clients'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)',
    'EXECUTE'
  ),
  true,
  'authenticated organizers can reach the safe bracket writer'
);
select is(
  has_function_privilege(
    'anon',
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot save brackets'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)',
    'EXECUTE'
  ),
  true,
  'authenticated organizers can reach retry-safe result confirmation'
);
select is(
  has_function_privilege(
    'anon',
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)',
    'EXECUTE'
  ),
  false,
  'anonymous callers cannot confirm tournament results'
);
select is(
  (select prosecdef from pg_proc
   where oid = 'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure),
  true,
  'bracket writes run through the role-checking security definer'
);
select is(
  (select proconfig @> array['search_path=pg_catalog, public']
   from pg_proc
   where oid = 'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure),
  true,
  'bracket writer has a fixed search path'
);
select is(
  (select prosecdef from pg_proc
   where oid = 'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure),
  true,
  'result confirmation runs through the role-checking security definer'
);
select is(
  (select proconfig @> array['search_path=pg_catalog, public']
   from pg_proc
   where oid = 'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure),
  true,
  'result confirmation has a fixed search path'
);
select ok(
  position('delete from public.tournament_players' in pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  )) = 0,
  'safe bracket writer never deletes player membership'
);
select ok(
  position('delete from public.tournament_teams' in pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  )) = 0,
  'safe bracket writer never deletes teams or their ownership'
);
select ok(
  position('confirmed_at is not null' in pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  )) > 0,
  'confirmed brackets cannot be replaced'
);
select ok(
  position('approved teams are missing from the bracket' in lower(pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  ))) > 0,
  'approved registrations cannot disappear from a draw'
);
select ok(
  position('return true' in pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  )) > 0
  and position('target.status in (''live'', ''completed'')' in pg_get_functiondef(
    'public.save_tournament_bracket_v2(uuid,jsonb,jsonb)'::regprocedure
  )) > 0,
  'an exact bracket retry is idempotent after the lock'
);
select ok(
  position('target_match.status = ''completed''' in pg_get_functiondef(
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure
  )) > 0,
  'completed result retries are recognized'
);
select ok(
  position('result conflicts with confirmed match' in lower(pg_get_functiondef(
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure
  ))) > 0,
  'conflicting result retries are rejected'
);
select ok(
  position('dependent match already started' in lower(pg_get_functiondef(
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure
  ))) > 0,
  'advancement cannot overwrite a started dependent match'
);
select ok(
  position('champion_team_id = p_winner_team_id' in pg_get_functiondef(
    'public.confirm_tournament_match_result_v2(uuid,uuid,integer,integer,uuid,uuid)'::regprocedure
  )) > 0,
  'the final result records the champion transactionally'
);
select is(
  has_table_privilege('authenticated', 'public.tournament_players', 'DELETE'),
  false,
  'clients cannot delete tournament players directly'
);
select is(
  has_table_privilege('authenticated', 'public.tournament_matches', 'INSERT'),
  false,
  'clients cannot forge tournament match rows directly'
);

select * from finish();
rollback;
