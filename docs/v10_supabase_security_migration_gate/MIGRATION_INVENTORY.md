# Migration inventory

Audit date: 2026-09-08 (Asia/Riyadh). Updated after the separately authorized read-only remote preflight. No remote SQL or data mutation was performed.

The 2026-09-08 linked migration list now directly confirms remote/local parity through `20260831000300`. Gameplay, Tournament v2, Voucher, and the new Tournament registration enum fix are local-only and remain undeployed.

Risk uses the highest consequence of a defective migration, not a statement that a defect exists. “Rollback” assumes no backup and therefore treats data rewrites/deletes conservatively.

## Complete inventory — 27 files

### 20260827000100_extensions_and_types.sql — MEDIUM RISK

- Purpose: extensions, enums and generic helpers.
- Tables: none. Functions: `jsonb_setting_number`, `normalize_question_text`, `set_updated_at`.
- RLS / privileges / indexes / constraints: none.
- Dependencies: PostgreSQL plus `pgcrypto`, `citext`, `pg_trgm` extensions established here for later files.
- Data migration / destructive operations: none.
- Rollback: medium because later objects depend on its types/extensions.
- Status: historically applied per repository evidence; not remotely re-verified.

### 20260827000200_profiles_and_questions.sql — HIGH RISK

- Purpose: identity, taxonomy, question bank and per-player history.
- Tables: `profiles`, `player_stats`, `categories`, `questions`, `question_options`, `tags`, `question_tags`, `question_history`, `system_opponents`.
- Functions: `after_profile_created`, `assert_question_publishable`, `handle_new_auth_user`, `prepare_question_record`, `validate_question_taxonomy`.
- RLS / privileges: deferred to `20260827000500`. Indexes: 14 identity/question lookup, uniqueness and trigram indexes. Constraints: 18 checks/FKs.
- Dependencies: extensions/types from `20260827000100`, `auth.users`.
- Data migration: initial system-opponent rows and profile trigger behavior. Destructive operations: none.
- Rollback: high because identity/question data depends on these primary tables.
- Status: historically applied; not remotely re-verified.

### 20260827000300_matches_rooms_social.sql — CRITICAL RISK

- Purpose: ranked seasons, friendships, rooms and server-authoritative match state.
- Tables: `seasons`, `player_season_stats`, `friend_requests`, `friends`, `rooms`, `room_members`, `matches`, `match_players`, `match_questions`, `match_question_options`, `match_answers`, `match_events`, `matchmaking_queue`.
- Functions: `record_answer_aggregates`, `validate_match_status_transition`.
- RLS / privileges: deferred to `20260827000500`. Indexes: 18 match/social/queue indexes. Constraints: 11.
- Dependencies: profiles/questions/types.
- Data migration: initial active season and aggregate updates. Destructive operations: none.
- Rollback: high; authoritative game history is involved.
- Status: historically applied; not remotely re-verified.

### 20260827000400_economy_notifications_admin.sql — CRITICAL RISK

- Purpose: wallet ledger, inventory/store, subscriptions, notifications, reports, audit and imports.
- Tables: `wallets`, `wallet_transactions`, `store_items`, `user_inventory`, `subscriptions`, `notification_preferences`, `device_tokens`, `notifications`, `question_reports`, `import_batches`, `import_rows`, `game_settings`, `account_deletion_requests`, `audit_logs`.
- Functions: `after_profile_create_wallet`, `apply_wallet_balance`.
- RLS / privileges: deferred to `20260827000500`. Indexes: 18. Constraints: 11.
- Dependencies: profiles/questions.
- Data migration: initial store/settings rows and wallet updates. Destructive operations: none.
- Rollback: high due immutable ledger/subscription/audit data.
- Status: historically applied; not remotely re-verified.

### 20260827000500_rls_and_safe_views.sql — CRITICAL RISK

- Purpose: enable RLS, define role/ownership helpers, policies, safe column grants and storage policies.
- Tables affected: 37 existing public tables plus storage objects. Functions: `current_app_role`, `has_role`, `is_match_participant`, `is_room_member`, `owns_wallet`.
- RLS: enabled broadly; 64 table/storage policies. Privileges: 43 GRANT and 15 REVOKE statements, including removal of broad Supabase defaults.
- Indexes / constraints / data: none material; one settings insert.
- Dependencies: every preceding schema table, `auth.uid()`, storage schema.
- Destructive operations: privilege revocation only. Rollback: high because reverting can expose data.
- Status: historically applied; not remotely re-verified.

### 20260827000600_match_and_room_rpcs.sql — CRITICAL RISK

- Purpose: authenticated, rate-limited room and match mutation RPCs.
- Tables: creates `api_rate_limits`; alters `match_answers` and mutates match/room tables.
- Functions: `assert_rate_limit`, `require_active_user`, `populate_match_questions`, `apply_answer_aggregate`, `advance_match`, `start_solo_match`, `create_room`, `generate_room_code`, `join_room`, `set_room_ready`, `start_room_match`, `open_match_question`, `submit_match_answer`, `reveal_match_question`, `get_match_question_result`.
- RLS / privileges: RLS and all-direct-access revoke on rate limits; 16 REVOKE and 9 guarded EXECUTE grants. No new indexes.
- Dependencies: profiles, role helpers, questions, matches/rooms.
- Data/destructive: transactional gameplay writes; removes one legacy trigger, no row-delete migration.
- Rollback: high; clients depend on RPC contracts.
- Status: historically applied; not remotely re-verified.

### 20260827000700_economy_import_admin_rpcs.sql — CRITICAL RISK

- Purpose: economy, finalization, moderation, role administration, friendship and deterministic imports.
- Tables: mutates existing wallet/match/profile/import/question tables.
- Functions: `post_wallet_transaction`, `finalize_match`, `purchase_store_item`, `admin_adjust_wallet`, `accept_friend_request`, `set_profile_role`, `moderate_profile`, `request_account_deletion`, `validate_import_row_data`, `validate_import_batch`, `commit_import_batch`, `get_admin_question`, `recalculate_question_difficulty`, plus protection triggers.
- RLS / privileges: 13 SECURITY DEFINER functions; 13 REVOKE and 11 EXECUTE grants. No new indexes/constraints.
- Dependencies: role helpers, active-user/rate-limit helpers, economy/match/import tables.
- Data/destructive: RPC bodies can delete staged/options data by domain; migration itself does not bulk-delete production rows.
- Rollback: high. Parser catalog warning on local enum-array variable `_record`; full SQL grammar passes.
- Status: historically applied; not remotely re-verified.

### 20260827000800_client_contracts_and_matchmaking.sql — HIGH RISK

- Purpose: missing client-facing solo/matchmaking contracts.
- Tables: alters `matchmaking_queue`. Functions: `advance_match`, `cancel_matchmaking`, `enqueue_matchmaking`, `get_solo_question_pack`, `record_solo_answer`.
- RLS / privileges: 4 REVOKE and 4 EXECUTE grants; existing RLS remains. No new indexes/constraints.
- Dependencies: auth/rate-limit helpers, match and question schema.
- Data/destructive: queue cleanup deletes and gameplay updates are inside RPCs.
- Rollback: high because mobile contracts depend on signatures.
- Status: historically applied; not remotely re-verified.

### 20260827000900_provider_integrations.sql — HIGH RISK

- Purpose: RevenueCat, FCM delivery, AdMob claims and social dashboard RPCs.
- Tables: `ad_reward_claims`, `notification_deliveries`; subscription/social tables are mutated.
- Functions: provider event and social functions including `apply_revenuecat_subscription_event`, `claim_verified_admob_reward`, `get_friend_dashboard`, `search_players`, `send_friend_request`, `respond_friend_request`, `invite_friend_to_room`, `remove_friend`.
- RLS / privileges: one notification-delivery admin policy; 16 REVOKE and 11 grants. Indexes: 3. Constraints: provider idempotency/ownership FKs.
- Dependencies: service-side provider verification, profiles/subscriptions/social tables.
- Data/destructive: friendship removal is domain-scoped; no bulk migration delete.
- Rollback: high because billing/provider state is involved.
- Status: historically applied; not remotely re-verified.

### 20260827001000_service_role_notification_grants.sql — HIGH RISK

- Purpose: least-privilege notification-dispatch permissions for `service_role`.
- Tables/functions: grants schema/table/sequence access needed by notification dispatcher; no new objects.
- RLS / privileges: 6 service-role grants. Indexes/constraints/data/destructive: none.
- Dependencies: notification tables and trusted server-only service role.
- Rollback: low technically, high operational impact.
- Status: historically applied; not remotely re-verified.

### 20260827001100_service_role_role_helpers.sql — HIGH RISK

- Purpose: allow trusted server functions to evaluate role helpers.
- Tables/functions: grants EXECUTE on `current_app_role` and `has_role`; no new objects.
- RLS / privileges: 2 service-role grants. No data/index/constraint/destructive operation.
- Dependencies: `20260827000500` helpers.
- Rollback: low technically.
- Status: historically applied; not remotely re-verified.

### 20260828000100_app_content_and_media.sql — HIGH RISK

- Purpose: managed application copy/media and publication workflow.
- Tables: `media_assets`, `app_content`; alters `categories`, `store_items`.
- Functions: nine draft/publish/media mutation and audit functions.
- RLS / privileges: 8 staff/public policies; 10 REVOKE and 13 grants. Indexes: 7. Constraints: 9.
- Dependencies: profiles, categories, store, audit logs, storage.
- Data migration: 10 content inserts and 8 updates. Destructive: none.
- Rollback: high because published content references change.
- Status: historically applied; not remotely re-verified.

### 20260828000200_operational_monitoring_and_branding.sql — HIGH RISK

- Purpose: error monitoring, user reports and safe branding controls.
- Tables: `app_error_issues`, `app_error_occurrences`, `user_problem_reports`; alters `media_assets`.
- Functions: seven reporting, sanitization, review and dashboard functions.
- RLS / privileges: 5 staff policies, 8 REVOKE, 6 grants. Indexes: 8. Constraints: 6.
- Dependencies: app content/media, profiles, audit helpers.
- Data migration: settings/content updates. Destructive: replaces a media constraint, not rows.
- Rollback: medium/high.
- Status: historically applied; not remotely re-verified.

### 20260828000300_social_football_v1.sql — HIGH RISK

- Purpose: football catalog, private teams, blocks/reports, challenges and achievements.
- Tables: 18 social/football/challenge tables; alters profiles and notification preferences.
- Functions: 32 role-protected social/football/challenge functions.
- RLS / privileges: 17 policies, 31 REVOKE and 30 grants. Indexes: 24. Constraints: 10.
- Dependencies: profiles, friends, notifications, audit/rate-limit helpers.
- Data migration: football/achievement/settings seeds and domain updates. Destructive: domain-scoped deletes in functions.
- Rollback: high due social memberships and moderation data.
- Status: historically applied; not remotely re-verified.

### 20260828000400_gameplay_contract_v2.sql — CRITICAL RISK

- Purpose: retry-safe submissions, explicit server clock and stronger gameplay validation.
- Tables: alters `questions`, `matches`, `match_answers`, `matchmaking_queue`, `rooms`, `team_challenge_answers`.
- Functions: 13 gameplay/admin functions, including idempotent v2 submissions.
- RLS / privileges: 5 REVOKE and 5 grants; existing RLS. Indexes: 3 idempotency/pool indexes. Constraints: 16.
- Dependencies: core gameplay and social challenge objects.
- Data migration: corrective updates; one domain-scoped delete in function body.
- Rollback: high due authority and idempotency contracts.
- Status: historically applied; not remotely re-verified.

### 20260829000100_visual_store_v1.sql — HIGH RISK

- Purpose: server-authoritative cosmetic purchase/equip contracts.
- Tables: `store_action_receipts`. Functions: `purchase_store_item_v2`, `equip_store_item_v2`.
- RLS / privileges: direct access revoked; 3 REVOKE and 2 grants. Index: receipt user/time. Constraints/FKs enforce idempotency.
- Dependencies: wallet, store, inventory, auth/rate-limit helpers.
- Data migration: receipt-backed purchase/equip writes only. Destructive: none.
- Rollback: high because purchase receipts are involved.
- Status: historically applied; not remotely re-verified.

### 20260829000200_landscape_premium_football.sql — HIGH RISK

- Purpose: 2026/27 football catalog, Premium metadata and media slots.
- Tables: alters `football_leagues`, `football_clubs`, `media_assets`.
- Functions: `bump_media_asset_version`, `football_catalog_2026_27_counts`.
- RLS / privileges: existing policies; 1 REVOKE/1 grant. Index: media slot. Constraints: 7.
- Dependencies: football/media schema.
- Data migration: large league/club/media insert/update set. Destructive: none.
- Rollback: high for content provenance and catalog rollback.
- Status: explicitly recorded as applied on 2026-08-29; not remotely re-verified now.

### 20260829000300_publish_landscape_assets.sql — MEDIUM RISK

- Purpose: register uploaded visual objects and publish 14 content slots.
- Tables: existing media/content tables. Function: `landscape_visual_asset_counts`.
- RLS / privileges: 1 REVOKE/1 grant. No indexes/constraints.
- Dependencies: uploaded storage objects and app-content/media schema.
- Data migration: media insert/content update. Destructive: none.
- Rollback: medium because published references can be restored.
- Status: explicitly recorded as applied on 2026-08-29; not remotely re-verified now.

### 20260829000400_republish_rpc_type_fixes.sql — HIGH RISK

- Purpose: republish corrected RPC bodies with explicit casts.
- Tables: no new tables. Functions: `start_solo_match`, `enqueue_matchmaking`, `set_room_ready`, `start_room_match`, `validate_import_row_data`, `validate_import_batch`.
- RLS / privileges/indexes/constraints: no new policy/index/constraint; inherited EXECUTE grants remain.
- Dependencies: original RPCs/types and all gameplay/import tables.
- Data/destructive: function bodies perform domain writes/deletes; no migration-time bulk delete.
- Rollback: high because reverting reintroduces broken RPC definitions.
- Status: explicitly recorded as applied on 2026-08-29; not remotely re-verified now.

### 20260830000100_party_game_content.sql — HIGH RISK

- Purpose: Party question contract, favorites, helper inventory and runtime settings.
- Tables: alters `questions`; creates `party_category_favorites`, `party_help_tools`, `party_game_settings`.
- Functions: `assert_question_publishable`, `create_admin_party_question`, `commit_party_import_batch`, `get_party_question_pack`, `get_party_category_health`.
- RLS / privileges: 8 policies, 4 REVOKE and 7 grants. Index: Party question pool. Constraints: 8.
- Dependencies: questions/imports, profiles, game settings and role helpers.
- Data migration: question backfill plus helper/settings seeds. Destructive: none.
- Rollback: high because question constraints and Party configuration change.
- Parser note: pre-existing `_record` catalog warning; SQL grammar passes.
- Status: repository dry-run evidence implies applied before 2026-09-05; not remotely re-verified.

### 20260831000100_party_v2_category_controls.sql — MEDIUM RISK

- Purpose: Party merchandising/category metadata and report reasons.
- Tables: alters `categories` and related report configuration.
- Functions/RLS: none. Privileges: 1 column grant. Indexes: 2. Constraints: 8 replacements.
- Dependencies: Party/content/category schema.
- Data migration: defaults on new columns. Destructive: old constraints are replaced, no rows deleted.
- Rollback: medium; old validation contract would need restoration.
- Status: repository dry-run evidence implies applied; not remotely re-verified.

### 20260831000200_tournaments_v1.sql — CRITICAL RISK

- Purpose: organizer-owned single-elimination tournaments.
- Tables: `tournaments`, `tournament_teams`, `tournament_players`, `tournament_registrations`, `tournament_matches`, `tournament_events`.
- Functions: `can_view_tournament`, create/register/review/stats plus legacy bracket save/confirm/undo RPCs.
- RLS / privileges: RLS on all six tables; 12 read/admin policies; table SELECT only; 8 REVOKE and 9 EXECUTE grants. Indexes: 7. Constraints/FKs: 5 named plus composite/FK checks.
- Dependencies: profiles, role/auth/rate-limit helpers, Party sessions/app content.
- Data migration: auth content mapping. Destructive: legacy `save_tournament_bracket` deletes matches, players and teams.
- Rollback: high. Historical destructive RPC is the core known risk and is mitigated only when pending safety v2 is applied.
- Status: repository evidence says applied; remote definition/drift not re-verified.

### 20260831000300_editorial_brand_category_media_v5.sql — HIGH RISK

- Purpose: category/question image readiness, provenance and publication guards.
- Tables: alters `categories`, `media_assets`, `questions`.
- Functions: five attach/update/validation functions and triggers.
- RLS / privileges: existing RLS; 2 REVOKE/4 grants. Constraints: 14 replacements. No new indexes.
- Dependencies: media/content/question/category schema.
- Data migration: provenance/content updates. Destructive: constraint replacement only.
- Rollback: high because published-media invariants are affected.
- Status: repository dry-run evidence implies applied; not remotely re-verified.

### 20260902000100_gameplay_depth_v1.sql — HIGH RISK — PENDING

- Purpose: discovery metadata, advanced question mechanics, Party rule update and gift-code inventory grants.
- Tables: alters `categories`, `questions`, `question_reports`, `user_inventory`; creates `category_collections`, `gift_codes`, `gift_redemptions`.
- Functions: replaces `assert_question_publishable`/`get_party_question_pack`; adds `redeem_gift_code`.
- RLS / privileges: RLS on the three new tables; public-active collection read, admin management, gift owner/moderator read; 2 function REVOKE and 8 grants. Indexes: 7. Constraints: 34 additions/replacements.
- Dependencies: all schema through `20260831000300`, specifically questions/categories, Party settings, store/inventory, `has_role`, `require_active_user`, `assert_rate_limit`, `pgcrypto`.
- Data migration: copies `categories.keywords` to empty `tags`; updates Party timers/rules; upserts `party.rule_config`. No row deletes.
- Destructive/rollback: constraint/function replacement and configuration overwrite make rollback high; representative existing data must be tested first.
- Status: pending per prior dry-run evidence. Gate: **BLOCKED** until real fresh/upgrade database and RLS tests run.

### 20260905000100_tournament_bracket_safety_v2.sql — HIGH RISK — PENDING

- Purpose: revoke destructive v1 writers and add validated, retry-safe v2 bracket/result RPCs.
- Tables: no DDL; transactionally updates tournament tables and intentionally replaces only unconfirmed match graphs.
- Functions: `save_tournament_bracket_v2`, `confirm_tournament_match_result_v2`.
- RLS / privileges: no policy change; 4 revokes including legacy RPCs and 2 authenticated EXECUTE grants. No indexes/constraints/data migration.
- Dependencies: `20260831000200_tournaments_v1`, profiles, auth/rate-limit helpers. No object dependency on gameplay-depth despite timestamp order.
- Destructive/rollback: deletes only unconfirmed `tournament_matches`; never teams/players. Rolling back would re-expose the dangerous legacy RPC.
- Status: pending per prior dry-run evidence. Embedded behavior 29/29 and static checks pass; **BLOCKED** until real multi-connection PostgreSQL/Supabase authorization/concurrency tests run.

### 20260907000100_premium_vouchers_v1.sql — HIGH RISK — PENDING

- Purpose: one-time monthly/annual promotional Premium vouchers and central promo access RPC.
- Tables: `premium_vouchers`, `premium_promotional_entitlements`.
- Functions: runtime gate, normalization/hash, own access, redemption, admin create/list/disable.
- RLS / privileges: RLS enabled with no table policies; all direct access revoked from public/anon/authenticated. Five authenticated EXECUTE grants invoke internally guarded RPCs; helpers remain uncallable. Indexes: 2. Constraints: hash shape, note length, redemption/disable shape, expiry window and unique voucher entitlement.
- Dependencies: `pgcrypto`, profiles, `game_settings`, `audit_logs`, `has_role`, `require_active_user`, `assert_rate_limit`. No tournament/gameplay object dependency.
- Data migration: inserts two private feature flags defaulting false. No row deletes.
- Destructive/rollback: additive; rollback becomes high after any voucher is issued because audit/entitlement history must be preserved.
- Status: new pending migration identified exactly from repository. Gate: **BLOCKED** until real PostgreSQL RLS/RPC/concurrency/time/rate-limit execution and separate store-policy approval.

### 20260908000100_fix_review_tournament_registration_enum.sql — MEDIUM RISK — PENDING

- Purpose: replace the historically applied `review_tournament_registration(uuid, boolean)` body so its approval/rejection CASE branches return `public.tournament_team_status`, not inferred `text`.
- Tables: no DDL; the function updates registrations and may create an approved team/roster exactly as before.
- Functions: replaces one existing SECURITY DEFINER function with the same signature, return type, volatility/null-input defaults, authorization checks, and fixed search path.
- RLS / privileges: no policy, GRANT, or REVOKE change. Same-signature `CREATE OR REPLACE` preserves the existing ACL (PUBLIC revoked; authenticated EXECUTE granted).
- Dependencies: historical `20260831000200_tournaments_v1` types/tables and `require_active_user`; no dependency on the three earlier pending migrations.
- Data migration/destructive operations: none. Rollback difficulty: low before deployment, medium after deployment because reverting restores a runtime type error.
- Status: local-only per linked migration list. Static 9/9 and PostgreSQL/WASM behavior 8/8 pass; real PostgreSQL/linked lint after deployment remains gated.

## Pending hashes

- `20260902000100_gameplay_depth_v1.sql`: `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1`
- `20260905000100_tournament_bracket_safety_v2.sql`: `E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`
- `20260907000100_premium_vouchers_v1.sql`: `0F292A2403902B38C240A26195645EB170C7E7A9DEF69F19E9FDE9D1812FCAFC`
- `20260908000100_fix_review_tournament_registration_enum.sql`: `16DB50AF51B41CE18542E92408404B8E7E477F80005A796A357DDE0DAB2949F2`
