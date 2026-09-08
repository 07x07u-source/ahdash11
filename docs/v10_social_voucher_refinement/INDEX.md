# AHDASH | 11 — V10 Social + Voucher Visual Evidence

Captured: 2026-09-08  
Status: local review pack; no deployment performed

## Provenance

- Mobile PNGs were rendered from the current Flutter widgets by
  `mobile/test/visual/v10_social_voucher_refinement_screenshot_test.dart`.
- Mobile fixtures are deterministic test data only. No fake presence, activity,
  last-seen value, XP, or production user is presented.
- Admin PNGs were captured from the current `PremiumVoucherManager` through a
  temporary development-only Next.js review harness. The harness was removed
  after capture and is not part of the production route tree.
- `before_after` uses the pre-update current V10 Goldens on the left and the
  reviewed implementation on the right. Archived V9/V9.2 Goldens were neither
  read as design authority nor modified.

## Friends and Add Friend

- `friends/friends_primary_390x844.png`
- `friends/friends_compact_360x800.png`
- `empty_states/friends_empty_390x844.png`
- `loading/friends_loading_390x844.png`
- `errors/friends_error_390x844.png`
- `add_friend/friends_search_390x844.png`
- `add_friend/friends_search_keyboard_390x844.png`
- `add_friend/friends_search_results_390x844.png`
- `add_friend/friends_no_results_390x844.png`
- `add_friend/add_friend_available_390x844.png`
- `add_friend/friend_added_390x844.png`
- `add_friend/already_friend_390x844.png`
- `loading/friends_search_loading_390x844.png`
- `errors/friends_search_error_390x844.png`

## Blocking and related Social surfaces

- `blocked/block_confirmation_390x844.png`
- `blocked/blocked_players_populated_390x844.png`
- `blocked/blocked_players_empty_390x844.png`
- `blocked/unblock_state_390x844.png`
- `team_detail/team_detail_390x844.png`
- `ranking/ranking_390x844.png`
- `profile/profile_social_connection_390x844.png`

## Premium Voucher

- `premium_voucher/premium_voucher_entry_390x844.png`
- `premium_voucher/voucher_form_390x844.png`
- `premium_voucher/voucher_typing_390x844.png`
- `premium_voucher/voucher_validating_390x844.png`
- `premium_voucher/voucher_invalid_390x844.png`
- `premium_voucher/voucher_used_390x844.png`
- `premium_voucher/voucher_success_monthly_390x844.png`
- `premium_voucher/voucher_success_annual_390x844.png`
- `premium_voucher/premium_active_via_voucher_390x844.png`
- `premium_voucher/voucher_auth_gate_guest_390x844.png`

## Admin Voucher Management

- `admin_vouchers/voucher_management_1440x1800.png`
- `admin_vouchers/create_voucher_monthly_1440x1800.png`
- `admin_vouchers/create_voucher_annual_1440x1800.png`
- `admin_vouchers/voucher_created_copy_code_1440x1800.png`
- `admin_vouchers/unused_voucher_table.png`
- `admin_vouchers/redeemed_voucher_table.png`
- `admin_vouchers/disabled_state.png`
- `admin_vouchers/admin_voucher_detail.png`

## Details and comparisons

- `details/friend_row_detail.png`
- `details/search_detail.png`
- `details/add_action_detail.png`
- `details/voucher_field_button_detail.png`
- `before_after/friends_before_after.png`
- `before_after/blocked_before_after.png`
- `before_after/team_detail_before_after.png`
- `before_after/ranking_before_after.png`
- `before_after/profile_before_after.png`
- `before_after/premium_voucher_before_after.png`

The pack contains 55 PNG files including deliberately duplicated state evidence
under `loading`, `errors`, and `empty_states` for reviewer navigation.

## Final local validation

- Full unfiltered Flutter suite: `1404/1404 PASS`, `0 FAIL`, `0 SKIP`.
- Focused Social/Voucher/Phase D/Phase E suite: `116/116 PASS`.
- Screenshot and responsive voucher suite: `18/18 PASS` after the final lint fix.
- `flutter analyze`: `No issues found`.
- Admin: `55/55 PASS`; lint, typecheck, and production build all pass.
- Migration parser: 26 migrations and 145 PL/pgSQL functions parsed successfully.
- Current V10 Goldens updated only after visual review: 10 Phase D Social
  images and 2 Phase E Profile images. Archived V9/V9.2 Goldens were untouched.
- No APK/AAB, Supabase deployment, RevenueCat publication, Admin publication,
  Online activation, or Production release was performed.
