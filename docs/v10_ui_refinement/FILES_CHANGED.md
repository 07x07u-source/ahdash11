# Files changed

Paths below are under **C:/dev/ahdash11/mobile/**. Existing untracked/dirty work was preserved. No reset, checkout, commit or deletion of existing work.

## Flutter — 26 files

- lib/app.dart
- lib/core/routing/app_router.dart
- lib/core/services/notification_service.dart
- lib/core/theme/app_colors.dart
- lib/core/theme/app_theme.dart
- lib/features/auth/data/supabase_user_mapper.dart
- lib/features/auth/domain/guest_capability_policy.dart — new
- lib/features/auth/presentation/auth_controller.dart
- lib/features/auth/presentation/auth_screen.dart
- lib/features/auth/presentation/auth_gate.dart — new
- lib/features/auth/presentation/capability_provider.dart — new
- lib/features/home/presentation/home_screen.dart
- lib/features/party/presentation/party_game_screens.dart
- lib/features/party/presentation/party_setup_screens.dart
- lib/features/party/presentation/party_support_screens.dart
- lib/features/party/presentation/party_v2_ui.dart
- lib/features/premium/presentation/premium_screen.dart
- lib/features/profile/presentation/profile_screen.dart
- lib/features/settings/presentation/settings_screen.dart
- lib/features/social/data/social_repository.dart
- lib/features/support/data/question_report_repository.dart
- lib/features/support/domain/question_report.dart
- lib/features/support/presentation/problem_report_controller.dart
- lib/features/tournament/presentation/tournament_screens.dart
- lib/shared/presentation/utility_v9.dart
- lib/shared/presentation/v10_portrait.dart

## Tests — 14 files

- test/features/auth/guest_capability_policy_test.dart — new
- test/features/auth/guest_routing_test.dart — new
- test/features/auth/social_auth_test.dart
- test/features/home/home_refinement_test.dart — new
- test/features/home/home_screen_test.dart
- test/features/party/party_setup_widget_test.dart
- test/features/support/question_report_repository_test.dart
- test/helpers/test_app.dart
- test/helpers/visual_test_variant.dart — new
- test/visual/global_refinement_responsive_test.dart — new
- test/visual/v10_phase_b_golden_test.dart
- test/visual/v10_phase_d_golden_test.dart
- test/visual/v10_phase_e_golden_test.dart
- test/visual/tournament_golden_test.dart

Existing Golden assertions remain active. Reusable fixtures also register separate responsiveness checks. No comparator unconditionally passes.

The Premium loading fixture now uses an unresolved Completer: a non-nullable delayed Future without a computation was producing an error instead of loading. Helper assertions scroll the lazy list and still verify all five labels and their distinct pictograms.

## Review tooling — new

- tool/ui_refinement_capture.dart — exports actual pixels while preserving baseline comparison; refuses baseline update
- tool/build_ui_review.py — contact sheets and SHA-256 screenshot index; source PNGs unchanged

## Artifacts

- C:/dev/ahdash11/docs/v10_ui_refinement/FINAL_REPORT.md
- C:/dev/ahdash11/docs/v10_ui_refinement/GUEST_AUDIT.md
- C:/dev/ahdash11/docs/v10_ui_refinement/FILES_CHANGED.md
- C:/dev/ahdash11/docs/v10_ui_refinement/SCREENSHOTS.json
- home/, guest/, party/, tournament/, account/, before_after/ and test/analyze logs in the same folder.
- Flutter may also generate ordinary failed-Golden diagnostics under test/visual/failures/.

Canonical Figma PNGs, historic parity matrices, existing baseline PNGs, Party domain/engine files, Supabase files and release/signing configuration were not edited.
