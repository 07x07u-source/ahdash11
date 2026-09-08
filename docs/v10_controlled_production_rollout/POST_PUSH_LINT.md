# Post-push linked lint

Status: **PASS WITH WARNINGS**.

`db lint --linked` exited 0.

- Errors: 0
- Warnings: 16 findings across 13 functions
- The previous `review_tournament_registration` enum assignment error is gone.

Remaining findings are warnings only:

- Unread variables: `set_room_ready`, `recalculate_question_difficulty`, `set_football_preferences`, `purchase_store_item_v2`, `equip_store_item_v2`, `get_party_category_health`.
- STABLE routines containing volatile expressions: `get_my_profile_summary`, `get_team_challenge_question`, `get_social_hub` (2), `get_social_team_detail` (2), `get_my_premium_access`, `admin_list_premium_vouchers`.
- `admin_create_premium_vouchers`: one shadowed loop-variable warning and one unused-variable warning.

Warnings were not suppressed and no corrective schema change was made during the rollout.
