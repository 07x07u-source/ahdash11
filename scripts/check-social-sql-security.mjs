import { readFileSync } from 'node:fs';

const migrationUrl = new URL(
  '../supabase/migrations/20260828000300_social_football_v1.sql',
  import.meta.url,
);
const sql = readFileSync(migrationUrl, 'utf8').toLowerCase();

const createdTables = [
  ...sql.matchAll(/create\s+table\s+public\.([a-z0-9_]+)/g),
].map((match) => match[1]);

const checks = [];
const check = (name, condition) => checks.push({ name, condition });
const grantStatements = [...sql.matchAll(/\bgrant\s+[^;]+;/g)].map(
  (match) => match[0],
);

for (const table of createdTables) {
  check(
    `rls:${table}`,
    sql.includes(`alter table public.${table} enable row level security`),
  );
}

check(
  'challenge answer tables are revoked from authenticated',
  sql.includes(
    'revoke select on public.team_challenge_questions, public.team_challenge_options, public.team_challenge_answers from authenticated',
  ),
);
check(
  'challenge answer tables are absent from client select grant',
  !grantStatements.some(
    (statement) =>
      statement.startsWith('grant select ') &&
      statement.includes('to authenticated') &&
      [
        'team_challenge_questions',
        'team_challenge_options',
        'team_challenge_answers',
      ].some((table) => statement.includes(table)),
  ),
);
check(
  'invite codes are stored as hashes',
  sql.includes('invite_code_hash text not null unique') &&
    sql.includes("extensions.digest(convert_to(invite_code, 'utf8'), 'sha256')"),
);
check(
  'no plaintext invite-code column exists',
  !/\binvite_code\s+text\s+(?:not\s+null|null)/.test(sql),
);
check(
  'challenge timing uses the server clock',
  sql.includes('server_received_at timestamptz not null default clock_timestamp()') &&
    sql.includes("extract(epoch from (clock_timestamp() - attempt.question_opened_at))"),
);
check(
  'challenge scores are written through protected RPCs',
  sql.includes(
    "comment on table public.team_challenge_attempts is 'scores and ranks are written only by security definer challenge rpcs.'",
  ) &&
    !grantStatements.some(
      (statement) =>
        /^grant\s+(?:insert|update|delete|all)\b/.test(statement) &&
        statement.includes('public.team_challenge_attempts') &&
        statement.includes('to authenticated'),
    ),
);
check(
  'blocking cancels direct friend and team invitations',
  sql.includes("update public.friend_requests set status = 'cancelled'") &&
    sql.includes("update public.social_team_invites set status = 'cancelled'"),
);
check(
  'football artwork has explicit rights states',
  sql.includes("visual_status in ('fallback', 'custom', 'licensed')") &&
    sql.includes('license_reference'),
);

const functionChunks = sql
  .split(/(?=create\s+or\s+replace\s+function\s+public\.)/g)
  .filter((chunk) => chunk.startsWith('create or replace function public.'));
for (const chunk of functionChunks) {
  const name = chunk.match(/function\s+public\.([a-z0-9_]+)/)?.[1] ?? 'unknown';
  const definition = chunk.slice(0, chunk.indexOf('$$;') + 3);
  if (definition.includes('security definer')) {
    check(
      `fixed-search-path:${name}`,
      /set\s+search_path\s*=\s*pg_catalog,\s*public(?:,\s*extensions)?/.test(
        definition,
      ),
    );
  }
}

for (const { name, condition } of checks) {
  console.log(`${condition ? 'PASS' : 'FAIL'} ${name}`);
}

const failures = checks.filter(({ condition }) => !condition);
console.log(`SUMMARY ${checks.length - failures.length}/${checks.length} checks passed`);
if (failures.length) process.exitCode = 1;
