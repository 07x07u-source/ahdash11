# Release gate

## Decision

**BLOCKED — do not deploy to staging or Production yet.**

Reason: the required disposable real PostgreSQL/Supabase environment is unavailable. Fresh history, existing-schema upgrade, real JWT/RLS, direct-table denial, two-connection concurrency, rate-limit and server-catalog ownership checks remain unexecuted. Static and PostgreSQL/WASM evidence cannot replace them.

## Per-pending-migration classification

| Migration | Risk | Classification | Reason |
|---|---|---|---|
| `20260902000100_gameplay_depth_v1.sql` | HIGH | BLOCKED | Broad constraints/data/settings changes require real preflight and upgrade preservation tests |
| `20260905000100_tournament_bracket_safety_v2.sql` | HIGH | BLOCKED | Positive 29/29 embedded evidence, but real auth/RLS and multi-connection mutation tests are missing |
| `20260907000100_premium_vouchers_v1.sql` | HIGH | BLOCKED | Positive static/embedded evidence, but real one-time concurrency, JWT/RLS, rate-limit and policy tests are missing |
| `20260908000100_fix_review_tournament_registration_enum.sql` | MEDIUM | BLOCKED | Local type/behavior tests pass; remote lint cannot clear until a separately approved deployment, and real DB regression is missing |

No migration is marked APPROVED FOR PRODUCTION.

## Application regression gate

- Flutter: complete unfiltered `flutter test` PASS — 1407/1407, 0 fail, 0 skip.
- Flutter analysis: PASS — No issues found.
- Admin: 55/55 tests PASS; lint, typecheck, and production build validation PASS.
- Goldens: no files regenerated or updated.

## Findings

### Resolved

- **HIGH:** stale client Promo access could outlive server expiry during a long-lived app session. Fixed with time-aware access, expiry timer and resume invalidation; unit regression added.
- **ERROR fixed locally:** `review_tournament_registration` inferred a text CASE for an enum column. A same-signature follow-up migration now casts both branches to the real enum; static 9/9 and PostgreSQL/WASM 8/8 pass.

### Outstanding

- **HIGH:** real local database gate unavailable; required security/integration/concurrency evidence is missing. Release gate remains blocked.
- **MEDIUM:** unused `SUPABASE_SERVICE_ROLE_KEY` variable exists in gitignored `admin/.env.local`. It is not read, bundled or printed. Remove it and rotate if real before staging.
- **MEDIUM:** voucher creator/redeemer/disabler profile FKs use RESTRICT; validate hard account-deletion workflow before staging.
- **LOW:** legacy organizer-only tournament undo RPC uses a different lock order; version and real-concurrency-test it before exposing current UI.
- **INFO:** two catalog-less parser `_record` warnings are pre-existing and unrelated; full SQL parses.
- **ERROR (remote remains):** linked lint still sees the historical Tournament text-to-enum body because the follow-up migration is local-only and no deployment was authorized.

No unresolved SQL source finding demonstrates a current privilege escalation, raw voucher leakage, Promo forgery or player deletion in the pending replacements. That positive result does not override the missing real DB gate.

## Required next gate

On an authorized disposable local Supabase stack only:

1. snapshot a baseline immediately before pending migrations;
2. apply each pending migration separately in timestamp order;
3. execute all nine pgTAP suites;
4. run direct anon/user/admin DML/RPC checks;
5. run two independent PostgreSQL connections for tournament and voucher races;
6. validate month/year/time/rate-limit and account deletion;
7. repeat from a fresh database and an existing-schema copy;
8. review evidence before any staging approval.

Production Voucher gates remain OFF and custom Voucher activation remains NOT APPROVED.
