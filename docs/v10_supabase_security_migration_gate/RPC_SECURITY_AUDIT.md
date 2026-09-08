# RPC and SECURITY DEFINER audit

## Pending security-sensitive functions

| Function | SECURITY DEFINER rationale | Caller/authorization | `search_path` | EXECUTE |
|---|---|---|---|---|
| `get_party_question_pack` | Must expose host-evaluated answers without granting direct answer-column access | `require_active_user`; published, reviewed, non-competitive, rights-safe pool only | `pg_catalog, public` | authenticated only |
| `redeem_gift_code` | Locks and writes protected code/inventory tables atomically | `require_active_user`; 12/hour | `pg_catalog, public` | authenticated only |
| `save_tournament_bracket_v2` | Writes protected bracket tables | active user + organizer ownership; 20/hour; tournament row lock | `pg_catalog, public` | authenticated only; legacy v1 revoked |
| `confirm_tournament_match_result_v2` | Writes match/advancement/champion atomically | active user + organizer ownership; 120/hour; tournament/match locks | `pg_catalog, public` | authenticated only; legacy confirm revoked |
| `premium_voucher_runtime_enabled` | Reads private server settings while callers have no private setting access | no caller data; AND of two fail-closed flags | `pg_catalog, public` | revoked from public/anon/authenticated |
| `get_my_premium_access` | Reads deny-all entitlement table | rejects null `auth.uid`; filters only caller row | `pg_catalog, public` | authenticated only |
| `redeem_premium_voucher` | Reads/writes deny-all voucher/entitlement/audit tables | `require_active_user`; 8/hour | `pg_catalog, public, extensions` | authenticated only |
| `admin_create_premium_vouchers` | generates/stores protected secrets | non-null `auth.uid` + `has_role('admin')` + server feature gate | `pg_catalog, public, extensions` | authenticated may call, role checked inside |
| `admin_list_premium_vouchers` | reads protected management data | non-null `auth.uid` + admin | `pg_catalog, public` | authenticated may call, role checked inside |
| `admin_disable_premium_voucher` | updates protected unused voucher | non-null `auth.uid` + admin | `pg_catalog, public` | authenticated may call, role checked inside |

`normalize_premium_voucher_code` and `premium_voucher_code_hash` are invoker-rights immutable helpers with explicit search paths; public/anon/authenticated EXECUTE is revoked.

## Findings

- All 10 SECURITY DEFINER functions introduced/replaced by pending migrations have explicit fixed search paths.
- All object references in sensitive bodies are schema-qualified; there is no dynamic SQL, caller-provided identifier, `EXECUTE format`, or unsafe interpolation.
- SECURITY DEFINER is justified for each function because direct table/answer access is intentionally unavailable.
- Function owner suitability cannot be proven without catalog access; expected migration-owner ownership is a real-local/staging verification item.
- Revokes occur before narrow authenticated grants. Admin RPCs are reachable by `authenticated` only so that the function can evaluate `auth.uid`; database role checks remain authoritative.
- Error responses contain product states/messages, never hashes, partial matches, SQL internals or voucher IDs.

## Service role

- Flutter: **SAFE** — only anon configuration exists; no service-role key name or service client.
- Browser Admin source: **SAFE** — the server client uses anon key plus the signed-in user cookie. No source reads `SUPABASE_SERVICE_ROLE_KEY` and it is not `NEXT_PUBLIC_`.
- Edge Functions: **SAFE** — service role is read only from server environment by `_shared/http.ts` and used in provider/dispatcher/delete server functions.
- Local secret hygiene: **FOUND ISSUE (MEDIUM)** — `admin/.env.local` contains an unused variable named `SUPABASE_SERVICE_ROLE_KEY`. Its value was not read or printed, the file is gitignored, and code does not bundle/use it. Remove it from the Admin environment and rotate it if it may be real before staging.
