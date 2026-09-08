# Migration test results

## Environment discovery

| Capability | Result |
|---|---|
| Docker | unavailable |
| local Supabase CLI | no global/project install; historical cached CLI 2.116.0 is available for linked read-only metadata, not a local DB runtime |
| PostgreSQL server / `psql` / `pg_isready` | unavailable |
| WSL | not installed |
| PostgreSQL/WASM (`PGlite`) | available as an existing isolated test dependency |

No remote fallback was attempted.

## Results

| Test | Evidence class | Result |
|---|---|---|
| `python supabase/tests/parse_migrations.py` | STATIC | PASS — 27 migrations, 146 PL/pgSQL functions |
| pgTAP SQL grammar parse | STATIC | PASS — 9 suites, 319 SQL statements |
| `pending_security_gate_static.mjs` | STATIC | PASS — 59/59 |
| `review_tournament_registration_enum_static.mjs` | STATIC | PASS — 9/9 |
| `review_tournament_registration_enum_behavior.mjs` | PostgreSQL/WASM | PASS — 8/8 |
| `tournament_v2_behavior.mjs` | PostgreSQL/WASM | PASS — 29/29 |
| `voucher_postgres_wasm_behavior.mjs` | PostgreSQL/WASM | PASS — 11/11 |
| focused Premium resolver tests | Flutter unit | PASS — 24/24 |
| complete unfiltered `flutter test` | Flutter regression | PASS — 1407/1407, 0 fail, 0 skip |
| `flutter analyze` | Flutter static analysis | PASS — No issues found |
| Admin `npm test` | Admin regression | PASS — 55/55 |
| Admin lint / typecheck / production build validation | Admin regression | PASS / PASS / PASS |
| pgTAP execution | REAL LOCAL DB | BLOCKED |
| fresh complete migration history | REAL LOCAL DB | BLOCKED |
| existing-schema upgrade, one migration at a time | REAL LOCAL DB | BLOCKED |
| actual JWT/RLS direct-DML matrix | REAL LOCAL DB | BLOCKED |
| two-connection tournament/voucher concurrency | REAL LOCAL DB | BLOCKED |

## Parser warnings retained

1. `20260827000700_economy_import_admin_rpcs.sql:760`: local enum-array `mode_values` appears to libpg_query as pseudo-type `_record`.
2. `20260830000100_party_game_content.sql:617`: same catalog-less `_record` limitation.

Both source files and full SQL statements parse. The warning comes from parsing PL/pgSQL without the project catalog, is pre-existing, does not concern the four pending migrations and is not release-blocking. It was not suppressed.

## Migration-specific execution status

- Gameplay depth: static review PASS; individual real apply/data/RLS test BLOCKED.
- Tournament safety: static + embedded behavior PASS; real apply/auth/concurrency BLOCKED.
- Premium Voucher: static + embedded constraints/time/rollback PASS; real apply/RLS/RPC/concurrency/rate-limit BLOCKED.
- Tournament registration enum fix: static 9/9 and PostgreSQL/WASM behavior 8/8 PASS. Linked lint still reports the historical remote body because the fix is intentionally not deployed.

PostgreSQL migration atomicity must be confirmed using the actual local Supabase migration runner. No failed real migration was manufactured or claimed.

No Flutter Golden was regenerated or updated. The initially observed full-suite failure was a compile-only error in a new V10 screenshot fixture (`DateTime.utc` nested in a `const` object); removing that invalid `const` made the fixture compile without changing its rendered state. Its focused suite then passed 18/18, followed by the clean 1407/1407 unfiltered run.
