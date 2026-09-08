# AHDASH 11 — V10 Supabase security and migration gate

Date: 2026-09-08 (Asia/Riyadh)

## Outcome

**RELEASE GATE: BLOCKED.** Static and embedded PostgreSQL/WASM evidence is positive, but this machine has no Docker or PostgreSQL server/runtime. A historical cached Supabase CLI can inspect the linked remote project read-only, but it cannot replace fresh-database, upgrade, JWT/RLS, or multi-connection validation. No migration is approved for Production.

The exact new voucher migration is `20260907000100_premium_vouchers_v1.sql`.

One client entitlement defect was found and fixed locally: a cached Promo boolean could remain trusted after its server `expires_at` while the app stayed alive. Access now validates expiry at every read, schedules provider invalidation at expiry, and refreshes on app resume. No SQL migration or visual design was changed.

## Evidence levels

- **STATIC PASS:** 27 migrations / 146 PL/pgSQL functions parse; base security 59/59 and enum fix 9/9 assertions pass.
- **SQL TEST PARSE PASS:** 9 pgTAP suites / 319 statements parse. They were not executed against Supabase.
- **POSTGRESQL/WASM PASS:** Tournament 29/29; voucher normalization/time/constraint/rollback 11/11; registration enum fix 8/8.
- **FLUTTER REGRESSION PASS:** complete unfiltered suite 1407/1407; `flutter analyze` reports no issues.
- **ADMIN REGRESSION PASS:** 55/55 tests; lint, typecheck, and production build validation pass.
- **REAL LOCAL DATABASE:** BLOCKED — required runtime unavailable.
- **REMOTE/PRODUCTION:** linked metadata/list/dry-run/lint inspected read-only under separate authorization; no SQL or mutation executed.

## Reports

- [Migration inventory](MIGRATION_INVENTORY.md)
- [Migration dependencies](MIGRATION_DEPENDENCIES.md)
- [RLS audit](RLS_AUDIT.md)
- [RPC security audit](RPC_SECURITY_AUDIT.md)
- [Voucher security](VOUCHER_SECURITY.md)
- [Tournament safety](TOURNAMENT_SAFETY.md)
- [Data preservation](DATA_PRESERVATION.md)
- [Concurrency results](CONCURRENCY_RESULTS.md)
- [Migration test results](MIGRATION_TEST_RESULTS.md)
- [Release gate](RELEASE_GATE.md)

No secret values are included in this report set.
