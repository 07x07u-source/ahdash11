// Deterministic PostgreSQL/WASM checks. This supplements, but does not replace,
// a real multi-connection Supabase/PostgreSQL security and concurrency run.
import assert from 'node:assert/strict';
import { PGlite } from '../../.codex-temp/phase5-sql/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite();
let count = 0;
async function check(name, fn) {
  await fn();
  console.log(`PASS ${++count}: ${name}`);
}

const scalar = async (sql, args = []) => (await db.query(sql, args)).rows[0].value;

await check('normalization removes separators, whitespace, and RTL marks', async () => {
  const value = await scalar(
    "select upper(regexp_replace(btrim($1), '[^A-Za-z0-9]', '', 'g')) value",
    [' \u200FAB12-cd34 EF56-7890-ABCD-EF12\u200E '],
  );
  assert.equal(value, 'AB12CD34EF567890ABCDEF12');
});

for (const [name, start, interval, expected] of [
  ['non-leap January month end', '2025-01-31T12:00:00Z', '1 month', '2025-02-28T12:00:00.000Z'],
  ['leap January month end', '2024-01-31T12:00:00Z', '1 month', '2024-02-29T12:00:00.000Z'],
  ['February plus one month', '2025-02-28T12:00:00Z', '1 month', '2025-03-28T12:00:00.000Z'],
  ['March month end', '2025-03-31T12:00:00Z', '1 month', '2025-04-30T12:00:00.000Z'],
  ['leap day plus one year', '2024-02-29T12:00:00Z', '1 year', '2025-02-28T12:00:00.000Z'],
]) {
  await check(name, async () => {
    const value = await scalar('select ($1::timestamptz + $2::interval) value', [start, interval]);
    assert.equal(new Date(value).toISOString(), expected);
  });
}

await db.exec(`
  create table vouchers(
    id integer primary key,
    code_hash text not null unique check (code_hash ~ '^[0-9a-f]{64}$'),
    redeemed_at timestamptz,
    redeemed_by integer,
    promo_expires_at timestamptz,
    check (
      (redeemed_at is null and redeemed_by is null and promo_expires_at is null)
      or (redeemed_at is not null and redeemed_by is not null and promo_expires_at > redeemed_at)
    )
  );
  create table entitlements(
    id integer primary key,
    voucher_id integer not null unique references vouchers(id) on delete restrict,
    starts_at timestamptz not null,
    expires_at timestamptz not null check (expires_at > starts_at)
  );
  insert into vouchers(id, code_hash) values (1, repeat('a', 64));
`);

await check('invalid hash shape is rejected', async () => {
  await assert.rejects(() => db.query("insert into vouchers values (2, 'raw-secret')"));
});
await check('duplicate hash is rejected', async () => {
  await assert.rejects(() => db.query("insert into vouchers(id, code_hash) values (2, repeat('a',64))"));
});
await check('partial redeemed state is rejected', async () => {
  await assert.rejects(() => db.query("update vouchers set redeemed_at=now() where id=1"));
});
await check('one entitlement per voucher is enforced', async () => {
  await db.query("update vouchers set redeemed_at=now(), redeemed_by=11, promo_expires_at=now()+interval '1 month' where id=1");
  await db.query("insert into entitlements values (1,1,now(),now()+interval '1 month')");
  await assert.rejects(() => db.query("insert into entitlements values (2,1,now(),now()+interval '1 month')"));
});

await check('failed entitlement write rolls the voucher update back', async () => {
  await db.exec("insert into vouchers(id, code_hash) values (3, repeat('b',64));");
  await assert.rejects(() => db.exec(`
    begin;
    update vouchers set redeemed_at=now(), redeemed_by=12,
      promo_expires_at=now()+interval '1 month' where id=3;
    insert into entitlements values (3,3,now(),now()-interval '1 day');
    commit;
  `));
  await db.exec('rollback;');
  const row = (await db.query('select redeemed_at, redeemed_by, promo_expires_at from vouchers where id=3')).rows[0];
  assert.equal(row.redeemed_at, null);
  assert.equal(row.redeemed_by, null);
  assert.equal(row.promo_expires_at, null);
});

console.log(`${count}/${count} embedded PostgreSQL/WASM behavior checks passed.`);
console.log('REAL MULTI-CONNECTION POSTGRESQL CONCURRENCY: NOT EXECUTED');
await db.close();
