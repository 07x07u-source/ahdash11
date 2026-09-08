import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const historical = await readFile(
  new URL('../migrations/20260831000200_tournaments_v1.sql', import.meta.url),
  'utf8',
);
const migration = await readFile(
  new URL(
    '../migrations/20260908000100_fix_review_tournament_registration_enum.sql',
    import.meta.url,
  ),
  'utf8',
);

let count = 0;
function check(name, condition) {
  assert.equal(Boolean(condition), true, name);
  console.log(`PASS ${++count}: ${name}`);
}

check(
  'historical enum has exactly the four supported labels',
  historical.includes(
    "create type public.tournament_team_status as enum ('pending', 'approved', 'rejected', 'withdrawn')",
  ),
);
check(
  'follow-up keeps the exact uuid boolean signature and uuid return',
  /review_tournament_registration\(\s*p_registration_id uuid,\s*p_approve boolean\s*\)\s*returns uuid/s.test(
    migration,
  ),
);
check(
  'approval CASE branch is explicitly typed as the real enum',
  migration.includes(
    "when p_approve then 'approved'::public.tournament_team_status",
  ),
);
check(
  'rejection CASE branch is explicitly typed as the real enum',
  migration.includes("else 'rejected'::public.tournament_team_status"),
);
check(
  'function remains SECURITY DEFINER with a fixed search path',
  /security definer\s+set search_path = pg_catalog, public/s.test(migration),
);
check(
  'active user and organizer ownership checks are preserved',
  migration.includes('caller := public.require_active_user()') &&
    migration.includes('tournament.organizer_id = caller.id'),
);
check(
  'follow-up does not add grants or weaken anonymous access',
  !/\bgrant\b/i.test(migration) && !/\brevoke\b/i.test(migration),
);
check(
  'follow-up contains no dynamic SQL',
  !/^\s*execute\s/m.test(migration),
);
check(
  'only the intended function is replaced',
  (migration.match(/create or replace function/gi) ?? []).length === 1 &&
    !/\b(?:create|alter|drop)\s+(?:table|type)\b/i.test(migration),
);

console.log(`${count}/${count} Tournament registration enum static checks passed.`);

