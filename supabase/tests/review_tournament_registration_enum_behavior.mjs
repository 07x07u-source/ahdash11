// Exact follow-up migration behavior in ephemeral PostgreSQL/WASM.
// This supplements, but does not replace, real Supabase JWT/RLS validation.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '../../.codex-temp/phase5-sql/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite();
const owner = '10000000-0000-4000-8000-000000000001';
const requester = '10000000-0000-4000-8000-000000000002';
const outsider = '10000000-0000-4000-8000-000000000003';
const id = (n) => `20000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const historical = await readFile(
  new URL('../migrations/20260831000200_tournaments_v1.sql', import.meta.url),
  'utf8',
);
const followUp = await readFile(
  new URL(
    '../migrations/20260908000100_fix_review_tournament_registration_enum.sql',
    import.meta.url,
  ),
  'utf8',
);

const start = historical.indexOf(
  'create or replace function public.review_tournament_registration(',
);
const end = historical.indexOf('$$;', start) + 3;
assert.ok(start >= 0 && end > start, 'historical function body must be found');

await db.exec(`
  create role authenticated;
  create role anon;
  create type public.tournament_status as enum (
    'draft', 'registration', 'ready', 'live', 'completed', 'cancelled'
  );
  create type public.tournament_team_status as enum (
    'pending', 'approved', 'rejected', 'withdrawn'
  );
  create table public.profiles(id uuid primary key);
  create table public.tournaments(
    id uuid primary key,
    organizer_id uuid not null references public.profiles(id),
    status public.tournament_status not null default 'registration',
    capacity integer not null
  );
  create table public.tournament_registrations(
    id uuid primary key,
    tournament_id uuid not null references public.tournaments(id) on delete cascade,
    requested_by uuid not null references public.profiles(id),
    team_name text not null,
    roster jsonb not null default '[]'::jsonb,
    status public.tournament_team_status not null default 'pending',
    reviewed_by uuid references public.profiles(id),
    reviewed_at timestamptz
  );
  create table public.tournament_teams(
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid not null references public.tournaments(id),
    owner_user_id uuid references public.profiles(id),
    name text not null,
    status public.tournament_team_status not null default 'approved'
  );
  create table public.tournament_players(
    id uuid primary key default gen_random_uuid(),
    tournament_id uuid not null references public.tournaments(id),
    team_id uuid not null references public.tournament_teams(id),
    user_id uuid references public.profiles(id),
    display_name text not null,
    is_captain boolean not null default false
  );
  insert into public.profiles values ('${owner}'), ('${requester}'), ('${outsider}');
  create function public.require_active_user()
  returns public.profiles
  language sql
  as $$
    select * from public.profiles
    where id = current_setting('test.actor')::uuid
  $$;
  select set_config('test.actor', '${owner}', false);
`);

await db.exec(historical.slice(start, end));
await db.exec(`
  revoke all on function public.review_tournament_registration(uuid, boolean) from public;
  grant execute on function public.review_tournament_registration(uuid, boolean) to authenticated;
`);
await db.exec(followUp);

let count = 0;
async function check(name, fn) {
  await fn();
  console.log(`PASS ${++count}: ${name}`);
}
async function rejects(sql, args, code) {
  await assert.rejects(
    () => db.query(sql, args),
    (error) => !code || error.code === code,
  );
}
async function seed(registrationNumber, options = {}) {
  const tournamentId = id(registrationNumber);
  const registrationId = id(registrationNumber + 100);
  await db.query(
    `insert into public.tournaments(id, organizer_id, capacity)
     values ($1, $2, $3)`,
    [tournamentId, options.organizer ?? owner, options.capacity ?? 4],
  );
  await db.query(
    `insert into public.tournament_registrations(
       id, tournament_id, requested_by, team_name, roster
     ) values ($1, $2, $3, $4, $5::jsonb)`,
    [
      registrationId,
      tournamentId,
      requester,
      `Team ${registrationNumber}`,
      JSON.stringify([
        {
          user_id: requester,
          display_name: 'Captain',
          is_captain: true,
        },
      ]),
    ],
  );
  return { tournamentId, registrationId };
}

await check('valid approval writes the enum and creates the approved roster', async () => {
  const fixture = await seed(1000);
  const result = await db.query(
    'select public.review_tournament_registration($1, true) as team_id',
    [fixture.registrationId],
  );
  assert.ok(result.rows[0].team_id);
  const registration = await db.query(
    'select status, reviewed_by from public.tournament_registrations where id = $1',
    [fixture.registrationId],
  );
  assert.equal(registration.rows[0].status, 'approved');
  assert.equal(registration.rows[0].reviewed_by, owner);
  const team = await db.query(
    'select status, owner_user_id from public.tournament_teams where id = $1',
    [result.rows[0].team_id],
  );
  assert.equal(team.rows[0].status, 'approved');
  assert.equal(team.rows[0].owner_user_id, requester);
  const players = await db.query(
    'select user_id, is_captain from public.tournament_players where team_id = $1',
    [result.rows[0].team_id],
  );
  assert.deepEqual(players.rows, [{ user_id: requester, is_captain: true }]);
});

await check('valid rejection writes the supported enum without creating a team', async () => {
  const fixture = await seed(2000);
  const result = await db.query(
    'select public.review_tournament_registration($1, false) as team_id',
    [fixture.registrationId],
  );
  assert.equal(result.rows[0].team_id, null);
  const registration = await db.query(
    'select status from public.tournament_registrations where id = $1',
    [fixture.registrationId],
  );
  assert.equal(registration.rows[0].status, 'rejected');
  const teams = await db.query(
    'select count(*)::int as count from public.tournament_teams where tournament_id = $1',
    [fixture.tournamentId],
  );
  assert.equal(teams.rows[0].count, 0);
});

await check('invalid boolean input is rejected before it can select an enum branch', async () => {
  const fixture = await seed(3000);
  await rejects(
    `select public.review_tournament_registration(
       '${fixture.registrationId}'::uuid,
       'not-a-boolean'
     )`,
    [],
    '22P02',
  );
});

await check('unsupported enum labels are rejected by the database type', async () => {
  const fixture = await seed(4000);
  await rejects(
    `update public.tournament_registrations
     set status = 'not-supported'
     where id = $1`,
    [fixture.registrationId],
    '22P02',
  );
});

await check('unauthorized caller cannot review another organizer registration', async () => {
  const fixture = await seed(5000);
  await db.query("select set_config('test.actor', $1, false)", [outsider]);
  await rejects(
    'select public.review_tournament_registration($1, true)',
    [fixture.registrationId],
    '42501',
  );
  await db.query("select set_config('test.actor', $1, false)", [owner]);
  const registration = await db.query(
    'select status from public.tournament_registrations where id = $1',
    [fixture.registrationId],
  );
  assert.equal(registration.rows[0].status, 'pending');
});

await check('missing registration fails with the existing safe authorization error', async () => {
  await rejects(
    'select public.review_tournament_registration($1, true)',
    [id(9999)],
    '42501',
  );
});

await check('CREATE OR REPLACE preserves the intended execute privileges', async () => {
  const authenticated = await db.query(
    `select has_function_privilege(
       'authenticated',
       'public.review_tournament_registration(uuid,boolean)',
       'execute'
     ) as allowed`,
  );
  const anonymous = await db.query(
    `select has_function_privilege(
       'anon',
       'public.review_tournament_registration(uuid,boolean)',
       'execute'
     ) as allowed`,
  );
  assert.equal(authenticated.rows[0].allowed, true);
  assert.equal(anonymous.rows[0].allowed, false);
});

await check('function remains SECURITY DEFINER with its fixed search path', async () => {
  const result = await db.query(`
    select prosecdef,
           proconfig @> array['search_path=pg_catalog, public'] as safe_path
    from pg_proc
    where oid = 'public.review_tournament_registration(uuid,boolean)'::regprocedure
  `);
  assert.equal(result.rows[0].prosecdef, true);
  assert.equal(result.rows[0].safe_path, true);
});

console.log(`${count}/${count} Tournament registration enum behavior checks passed.`);
await db.close();

