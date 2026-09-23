# Friends final polish

Scope: Friends UI and its search/empty/retry illustration. No backend or
deployment changes. The approved main hero illustration remains in use.

## Improvements

- More legible status accents, search hint, summary labels, and 44px action targets.
- Hero art uses a larger, balanced scale. The text column sizes naturally.
- Search keeps focus while requests run. Older results cannot overwrite a newer
  query or reappear after clearing. Shortening a query clears obsolete results.
- Dashboard retry handles repeated errors without an unhandled callback error.
- With the keyboard open, the decorative hero and redundant search heading are
  hidden; keyboard padding is not counted twice. Reduced motion is respected.
- A generated, genuinely transparent friends-search cutout replaces the black
  artwork tile and SOCIAL 11 strip in empty, no-results, and retry states.
  These illustrations have no surrounding background card.

## Validation

- Final post-replacement run: **61 passed**, 0 failed, 0 skipped across
  `friends_block_workflow_test.dart`, `phase_d_widgets_test.dart`, and
  `v10_full_feature_state_screenshot_test.dart`.
- Responsive screenshot sweep: **30 passed** across five widths (360–430),
  text scales 1.0/1.2/1.3, with and without the keyboard. These populated
  scenarios are unchanged by the subsequent empty-state image replacement.
- Four current V10 Friends/FriendsKeyboard goldens were regenerated after
  visual inspection, then passed a normal comparison run. Archived baselines
  were not updated. Their populated fixtures do not show empty-state artwork.
- Final `flutter analyze --no-pub`: **No issues found**.
- Source diff whitespace check: clean.

These are scoped UI/widget checks with deterministic repository fixtures,
not a full application test run or live-server integration verification.

## Files changed in this iteration

- `mobile/lib/features/social/presentation/friends_screen.dart`
- `mobile/lib/features/social/presentation/social_visuals.dart`
- `mobile/test/features/social/friends_block_workflow_test.dart`
- `mobile/test/fixtures/fake_social_repository.dart`
- `mobile/test/visual/v10_full_feature_state_screenshot_test.dart`
- `mobile/assets/visuals/friends_discovery_cutout_v1.png`
- Four `mobile/test/visual/goldens/v10_phase_d/friends*.png` baselines.
- Friends screenshots in this directory and corresponding atlas destinations.
- This report and `DISCOVERY_ARTWORK.md` (generation prompt and asset provenance).

Screenshots are actual Flutter renders. Open `35_friends_empty_390x844.png`
or `35_friends_search_no_results_390x844.png` to review the new cutout in context.
