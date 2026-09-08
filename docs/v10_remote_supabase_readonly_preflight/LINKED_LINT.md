# Linked schema lint

Command: cached CLI `db lint --linked --level warning --fail-on none`.

The CLI documents `--linked` as linting the linked project for schema errors. No repair, migration, SQL write, or data-query command was used.

## Result

- Exit: 0 (`--fail-on none` preserves complete reporting).
- Schemas inspected by the CLI: `extensions`, `public`.
- Functions with findings: 11.
- Warning findings: 12.
- Error findings: 1.

| Function | Severity | Finding |
|---|---|---|
| `set_room_ready` | warning extra | unread `target_member` variable |
| `recalculate_question_difficulty` | warning extra | unread `caller` variable |
| `get_my_profile_summary` | warning | marked STABLE but uses a VOLATILE expression |
| `get_team_challenge_question` | warning | marked STABLE but uses a VOLATILE expression |
| `set_football_preferences` | warning extra | unread `target_league` variable |
| `get_social_hub` | 2 warnings | marked STABLE but uses VOLATILE expressions |
| `get_social_team_detail` | 2 warnings | marked STABLE but uses VOLATILE expressions |
| `purchase_store_item_v2` | warning extra | unread `target_wallet_id` variable |
| `equip_store_item_v2` | warning extra | unread `target_wallet_id` variable |
| `get_party_category_health` | warning extra | unread `caller` variable |
| `review_tournament_registration` | **error** | enum column `status` receives a `text` CASE expression |

## Error source and disposition

The error maps to the historically applied file `20260831000200_tournaments_v1.sql`, where `review_tournament_registration` assigns an uncast CASE expression to `tournament_team_status`. None of the three pending migrations replaces this function.

The historical migration must not be edited. The error requires review and, if confirmed, a new additive follow-up migration with a regression test before any Tournament staging approval. No fix was made during this read-only phase.

The 12 warnings are historical remote-schema findings and should be triaged separately. They do not change the exact three-file dry-run result.

## Post-fix linked result

A second linked lint after preparing the local follow-up still reports 12 warnings and the same single error. This is expected: `--linked` inspects the unchanged remote function, not local pending SQL. The local migration passes parser/static and PostgreSQL/WASM behavior checks; claiming the remote error is gone before deployment would be false.
