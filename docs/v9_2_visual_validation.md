# AHDASH 11 V9.2 — Visual validation plan

## Current checkpoint

Figma access succeeded. The Complete Product Review metadata, wide/compact node pairs, Flutter Handoff tokens, and representative raw frames were inspected. Representative pairs included Sign In, Home, Category Selection, Team Setup, Game Board, Tournament Bracket, Settings, Profile, and Premium. This confirmed that compact is a distinct composition rather than a scaled wide frame.

Phase 1 validates tokens, font packaging, responsive metrics, and source analysis only. It intentionally does not regenerate the screen golden suite and does not claim screen-level visual parity.

Checkpoint evidence: the two targeted test files completed with 6 passing tests, and `flutter analyze --fatal-infos` completed with no issues.

## Later screen-level procedure

1. Use deterministic providers/fixtures and local deterministic images; no live network in goldens.
2. Load registered Thmanyah Sans and required icon fonts.
3. Render every one of the 41 standalone screens at 844×390 and 1280×720.
4. Render critical screens additionally at 800×360, 915×412, and 1366×768.
5. Open the raw PNG output and compare hierarchy, spacing, wrapping, imagery, pictogram scale, initial CTA visibility, RTL, safe areas, state clarity, and overflow against the exact Figma node pair.
6. Treat goldens as regression evidence, not product approval.

Critical screens: Sign In, Home, Category Selection, Team Setup, Helpers, Ready, Game Board, Text Question, Image Question, Answer Reveal, Final Result, Tournament Hub, Draw, Bracket, Tournament Match, Champion, Profile, Settings, Football Preferences, and Premium.

## Functional-state fixtures

Later goldens must include only deterministic representations of actual supported states: loading, empty, safe error/retry, selected, disabled, completed, consumed, unread, long Arabic copy, mixed Arabic/English football names, and large scores. They must not introduce fake production data. Placeholder fixtures stay test-only.

## Accessibility and performance checks

- Verify semantic labels/focus order, selected/disabled state beyond color, minimum targets, AA text contrast, RTL direction, enlarged text, and Reduced Motion.
- Profile list rebuilds, image decode/cache size, blur/shadow cost, animation-controller lifecycle, and timers during implementation.
- Core gameplay receives special no-scroll/no-overflow inspection at compact heights.

## Release gate

Only after Phases 2–8: run formatting, fatal-info analysis, full unit/widget/routing/provider tests, relevant goldens, and raw-image review. APK creation belongs to Phase 9 and is explicitly outside this checkpoint.
