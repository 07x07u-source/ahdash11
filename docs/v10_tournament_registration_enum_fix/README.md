# Tournament registration enum lint fix

Date: 2026-09-08 (Asia/Riyadh)

## Root cause

The only/latest definition is in the historically applied `20260831000200_tournaments_v1.sql`:

```sql
public.review_tournament_registration(uuid, boolean) returns uuid
```

It is a VOLATILE, CALLED ON NULL INPUT, PL/pgSQL SECURITY DEFINER function with `search_path = pg_catalog, public`. The historical migration revokes PUBLIC execution and grants EXECUTE to `authenticated`.

`tournament_registrations.status` is `public.tournament_team_status`, whose exact values are `pending`, `approved`, `rejected`, and `withdrawn`. The historical CASE returned untyped literals, which linked `plpgsql_check` resolved as `text` before assignment to the enum column.

## Fix

New local-only migration:

`20260908000100_fix_review_tournament_registration_enum.sql`

Both CASE branches now use explicit enum values:

```sql
when p_approve then 'approved'::public.tournament_team_status
else 'rejected'::public.tournament_team_status
```

No table/type/constraint, function signature, authorization behavior, search path, volatility, null-input behavior, or ACL was changed. The historical migration was not edited.

## Evidence

- Migration parser: 27 migrations / 146 PL/pgSQL functions PASS.
- Base security static suite: 59/59 PASS.
- Focused enum static suite: 9/9 PASS.
- PostgreSQL/WASM behavior: 8/8 PASS (approval, rejection, invalid boolean, invalid enum, unauthorized caller, missing registration, ACL preservation, SECURITY DEFINER/search path).
- pgTAP grammar: 9 suites / 319 SQL statements PASS; real pgTAP execution remains blocked without a disposable PostgreSQL/Supabase runtime.
- Linked migration list: 23 matches, four local-only, zero remote-only.
- Dry run: exactly Gameplay → Tournament v2 → Voucher → enum fix; no seeds/roles.
- Linked lint: still 12 warnings plus the historical error because the remote function is intentionally unchanged. No deployment was performed.

The enum fix depends only on the already-applied Tournament v1 schema and is independently valid after that baseline. Timestamp ordering places it after the three earlier pending migrations; none of those objects is referenced by the fix.

## Gate

Local preparation is complete. Remote lint clearance and staging approval require an authorized deployment only after real PostgreSQL regression validation. No real push, remote SQL, migration repair, or Production mutation occurred.

