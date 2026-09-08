# Data preservation and cascade audit

## Execution boundary

No disposable PostgreSQL server was available, so a full pre-migration fixture snapshot and existing-database upgrade were not executed. No Production data was accessed. Results are separated below.

## Static migration preservation

### Gameplay depth

- Additive columns use defaults; no row deletion.
- Existing empty category tags are copied from `keywords`; primary keys/ownership are untouched.
- Question/collection/gift constraints can reject incompatible existing data at migration time. This requires a preflight query on a disposable copy before staging.
- `party_game_settings` timer/risk/pass fields are intentionally updated.
- `party.rule_config` is upserted and overwrites its existing value. Preserve/export any environment-specific customization before applying.
- Existing question publish trigger/function is replaced; application is transactional if the migration runner uses PostgreSQL’s default transaction handling.

### Tournament safety

- No migration-time data rewrite.
- v2 save deletes only an unconfirmed match graph after all validation and locks.
- It never deletes `tournament_players` or `tournament_teams`.
- Existing team owner, registration state, player id, user id and captain state remain intact.

### Premium Voucher

- Additive tables/functions/settings only; no existing row changes beyond inserting missing private flags.
- Flags use `ON CONFLICT DO NOTHING`, so an existing explicit value is preserved.

## Foreign-key cascade review

| Relationship | Action | Assessment |
|---|---|---|
| tournament → teams/players/registrations/matches/events | `ON DELETE CASCADE` | Deleting a tournament intentionally deletes all children; tournament delete is not granted to ordinary users |
| tournament team → players | `ON DELETE CASCADE` | Sensitive historical reason the old bracket writer lost players; v2 never deletes teams |
| profile → tournament player/team/event reviewer fields | mostly `SET NULL` | preserves tournament history |
| voucher → Promo entitlement | `ON DELETE RESTRICT` | preserves audit/one-time relationship |
| profile → Promo entitlement | `ON DELETE CASCADE` | account deletion removes access grant; voucher `redeemed_by/created_by` RESTRICT may require explicit account-deletion handling |
| profile → voucher creator/redeemer/disabler | `ON DELETE RESTRICT` | audit preservation, but may block hard profile deletion; **MEDIUM operational finding** to validate against account-deletion workflow |
| gift code → redemption | `ON DELETE RESTRICT` | preserves redemption history |
| profile → gift redemption | `ON DELETE CASCADE` | removes per-user redemption when profile is hard-deleted |

## Embedded preservation result

- Tournament 29/29 function-body checks preserved representative player/team identities.
- Voucher 11/11 PostgreSQL/WASM checks enforced hash/redeemed-window/unique-entitlement invariants and rolled back a voucher update when entitlement insertion failed.

## Required real upgrade fixture

Before staging, capture counts, primary keys, owners and relationships for categories/questions/settings/inventory, tournament players/teams/matches/events, and profiles. Apply each pending migration individually, compare snapshots, then run invalid/retry/concurrent mutations. Current result: **BLOCKED**, not failed.
