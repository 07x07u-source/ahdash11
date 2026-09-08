# Remote migration state

Command: cached CLI `migration list --linked`.

Result: PASS, exit 0. The CLI authenticated and connected to the linked remote database using its existing local state. No row data or private content was queried.

## Exact comparison

| Version | Local | Remote |
|---|---|---|
| `20260827000100` | present | applied |
| `20260827000200` | present | applied |
| `20260827000300` | present | applied |
| `20260827000400` | present | applied |
| `20260827000500` | present | applied |
| `20260827000600` | present | applied |
| `20260827000700` | present | applied |
| `20260827000800` | present | applied |
| `20260827000900` | present | applied |
| `20260827001000` | present | applied |
| `20260827001100` | present | applied |
| `20260828000100` | present | applied |
| `20260828000200` | present | applied |
| `20260828000300` | present | applied |
| `20260828000400` | present | applied |
| `20260829000100` | present | applied |
| `20260829000200` | present | applied |
| `20260829000300` | present | applied |
| `20260829000400` | present | applied |
| `20260830000100` | present | applied |
| `20260831000100` | present | applied |
| `20260831000200` | present | applied |
| `20260831000300` | present | applied |
| `20260902000100` | present | not applied |
| `20260905000100` | present | not applied |
| `20260907000100` | present | not applied |

## Summary

- Local migration count: 26.
- Matching local/remote versions: 23.
- Verified remote baseline: through `20260831000300`.
- Expected local-only versions: 3.
- Unexpected local-only versions: 0.
- Unexpected remote-only versions: 0.

The three exact pending files are:

1. `20260902000100_gameplay_depth_v1.sql`
2. `20260905000100_tournament_bracket_safety_v2.sql`
3. `20260907000100_premium_vouchers_v1.sql`

The remote migration ledger is consistent with repository history. This does not prove runtime correctness or authorize deployment.

## Post-fix local update

After creating `20260908000100_fix_review_tournament_registration_enum.sql`, a second read-only list reported 27 total entries: 23 matching, 4 local-only, and 0 remote-only. The remote baseline remains unchanged through `20260831000300`.

## Schema observation boundary

Migration metadata confirms the historical baseline is recorded remotely. The linked lint also resolved historical functions in the `public` schema. No schema dump, user-table query, private row inspection, or mutation was performed.
