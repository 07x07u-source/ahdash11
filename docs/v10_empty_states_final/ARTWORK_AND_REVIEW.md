# Card-free illustrated states

Generated with the built-in ImageGen tool; no CLI fallback used.

## Assets

- Saved sessions: `mobile/assets/visuals/saved_games_empty_cutout_v1.png`
- Unavailable challenge: `mobile/assets/visuals/challenge_unavailable_cutout_v1.png`
- Empty leaderboard: `mobile/assets/visuals/ranking_empty_cutout_v1.png`

All three assets are 1536 × 1024 PNGs with real RGBA transparency. Corner and
outer-edge alpha values were verified as zero. Generated alpha is preserved;
there is no background tile, frame, or card in the consuming state layout.

## UI scope

Shared card-free state layout provides 204 × 136 decorative artwork, a 22px
heading, 14px explanatory copy with 1.65 line height, quiet wrapping trust notes,
and scrollable content on smaller displays. Saved-game start behavior and its
feedback remain intact. The unavailable challenge retains its existing pinned
back action. No gameplay, persistence, scoring, backend, or deployment changes.

## Screenshot files

Files use `<state>_<viewport>_scale<factor>.png` in this directory. States are
`savedGamesEmpty`, `challengeUnavailable`, and `rankingEmpty`; viewports are
390×844 and 360×800; text scales are 1.0, 1.3, and 2.0.
These are actual Flutter renders using deterministic fixture data, not Figma
exports or generated mockups.

## Validation

- 18 screenshot/accessibility checks: three states × two viewports × three
  text scales (100%, 130%, 200%). No overflow errors; state content can scroll.
- 14 widget and current golden checks: saved-session start behavior, existing
  saved-session states, challenge flow/result/unavailable states, and verified
  ranking behavior. All passed.
- 7 additional existing state-capture checks: saved-session empty/populated and
  ranking loading/error/empty/populated. All passed.
- Total across these scoped test commands: **39 passed, 0 failed, 0 skipped**.
- `flutter analyze --no-pub`: **No issues found**.
- Only the two current V10 `teamChallengeUnavailable` golden images were
  updated after visual inspection; a normal golden comparison then passed.
  No archived V9/V9.2 golden was changed.

This is scoped UI verification, not a complete unfiltered app test run or
live backend verification.

## Source changes

- `mobile/lib/shared/presentation/illustrated_state.dart`
- `mobile/lib/features/party/presentation/party_support_screens.dart`
- `mobile/lib/features/social/presentation/team_challenge_screen.dart`
- `mobile/lib/features/ranking/presentation/ranking_screen.dart`
- `mobile/test/features/party/saved_games_states_test.dart`
- `mobile/test/visual/illustrated_empty_states_screenshot_test.dart`
- `mobile/test/visual/team_challenge_states_golden_test.dart`
- `mobile/test/visual/v10_full_feature_state_screenshot_test.dart`

Plus the three new PNG assets, the two current golden images, screenshots,
and this report. Existing unrelated work was preserved.

## Generation prompts

### saved

Use case: stylized-concept. Asset for AHDASH 11, an Arabic football trivia mobile game. Create a single premium minimalist 3D cutout illustration, restrained matte soft-touch materials, rounded sculptural forms, soft studio highlights, charcoal #191714, vivid acid lime #B6FF3B, warm sand #EBDFC9 and limited muted champagne accents. Landscape 3:2 composition, centered, subject fills about 80 percent, readable at 190x126 pixels on an ivory app page. GENUINE TRANSPARENT PNG with preserved alpha outside the objects. No background card, no frame, no panel, no floor, no backplate, no gradient or colored backdrop, no drawn checkerboard transparency pattern, no text, no numbers, no logos, no watermark, no confetti, no random decoration. Shadow only subtle object self-shading; no opaque shadow rectangle. Subject: a refined chunky charcoal mini game controller with just a lime directional pad and two discreet round buttons, a single sculptural lime bookmark ribbon floating immediately behind it, and a small ivory-and-charcoal soccer ball nestled at its lower right. Communicates saved football game sessions waiting for a first game, calm and inviting. Three simple objects only, no playing cards, no actual saved-game data, no enclosing container.

### challenge

Use case: stylized-concept. Asset for AHDASH 11, an Arabic football trivia mobile game. Create a single premium minimalist 3D cutout illustration, restrained matte soft-touch materials, rounded sculptural forms, soft studio highlights, charcoal #191714, vivid acid lime #B6FF3B, warm sand #EBDFC9 and limited muted champagne accents. Landscape 3:2 composition, centered, subject fills about 80 percent, readable at 190x126 pixels on an ivory app page. GENUINE TRANSPARENT PNG with preserved alpha outside the objects. No background card, no frame, no panel, no floor, no backplate, no gradient or colored backdrop, no drawn checkerboard transparency pattern, no text, no numbers, no logos, no watermark, no confetti, no random decoration. Shadow only subtle object self-shading; no opaque shadow rectangle. Subject: a softly waving checkered starting flag in charcoal and acid lime on one elegant dark pole, with a small warm-sand hourglass and charcoal frame nestled next to it. Represents a game challenge currently unavailable, quietly waiting. Two objects only. Flag checks are part of the flag fabric only; the background is genuinely transparent. No warning triangle, no red X, no lock, no text, no circular icon container, no base platform.

### ranking

Use case: stylized-concept. Asset for AHDASH 11, an Arabic football trivia mobile game. Create a single premium minimalist 3D cutout illustration, restrained matte soft-touch materials, rounded sculptural forms, soft studio highlights, charcoal #191714, vivid acid lime #B6FF3B, warm sand #EBDFC9 and limited muted champagne accents. Landscape 3:2 composition, centered, subject fills about 80 percent, readable at 190x126 pixels on an ivory app page. GENUINE TRANSPARENT PNG with preserved alpha outside the objects. No background card, no frame, no panel, no floor, no backplate, no gradient or colored backdrop, no drawn checkerboard transparency pattern, no text, no numbers, no logos, no watermark, no confetti, no random decoration. Shadow only subtle object self-shading; no opaque shadow rectangle. Subject: three small freestanding rounded ranking columns (tall center in acid lime, shorter left in warm sand, shortest right in charcoal), a petite sculptural brushed champagne trophy with a subtle charcoal stem hovering just above the center column. Represents a leaderboard waiting for its first result. Simple clean composition with an aspirational but calm mood. No surrounding platform or black plaque, no square background, no rank numbers, no people, no medals, no bursts or fireworks.
