# AHDASH | 11 — Testing Strategy

**Authority:** canonical test taxonomy, CI selection, and current gate state  
**Last verified:** 12 September 2026  
**Release verdict:** [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)

## Current gate state

The current dirty working tree completed a new local shared Android/iOS Release-equivalent validation on 12 September 2026 after the iOS integration/auth readiness changes:

- `flutter analyze --fatal-infos`: **PASS**, no issues found, 112.0 seconds.
- Shared Android/iOS Release-equivalent non-visual suite with coverage: **PASS / GREEN**.
- Selection: 74 non-visual test files selected and 24 files under `test/visual/**` excluded.
- Result: **584 passed / 0 failed / 0 skipped** in 306.3 seconds.
- Focused social-auth suite: **11 passed / 0 failed**, including external OAuth callback-to-session synchronization.
- Release-validator Node suite: **7 passed / 0 failed / 0 skipped**; iOS public configuration and plist parsing contracts are covered.
- Coverage includes contracts proving that approved mobile navigation does not expose Friends, Online, matchmaking, 1v1, or 2v2; legacy Friends/Online/room routes return to Home; Party remains discoverable; and guest Party access remains allowed.
- `git diff --check`: **PASS** after implementation and validation.

This is `LOCAL_NON_VISUAL_TEST_GATE_GREEN` evidence for the current local tree. It does not prove visual, iOS compilation/signing, device, provider, store, or release-artifact readiness. Visual/Golden tests were not run or regenerated in this gate.

### Resolved gate failures

The earlier failures in `guest_routing_test.dart`, `v10_phase_d_contract_test.dart`, and `v10_phase_e_contract_test.dart` now pass. All three were resolved through test-contract corrections only; no Production Flutter UI, design, or copy change was required.

The successful earlier Codemagic Android release remains `OPERATOR_VERIFIED` for its known commit and artifacts. The earlier local **661 passed / 0 failed** gate is historical and superseded by the new 584/0 result. The current local tree has no corresponding Codemagic iOS artifact yet; macOS CI remains required.

## 1. Format and static analysis

| Scope | Canonical command/source | Current approved evidence |
|---|---|---|
| Flutter formatting | `dart format --output=none --set-exit-if-changed .` in PR checks | Defined in CI; not rerun in this documentation task |
| Flutter analysis | `flutter analyze --fatal-infos` | Current local tree: PASS with no issues, 112.0 seconds |
| Desktop/Admin types | `npm run typecheck` | Phase 2 local tree: PASS on 12 September 2026 |
| Desktop/Admin lint | `npm run lint` | Phase 2 local tree: PASS on 12 September 2026 |

Formatting and analysis are required gates but do not replace functional, visual, integration, device, database, or store validation.

## 2. Flutter non-visual unit/widget tests

Android and iOS Release CI intentionally discover all Flutter test files except `test/visual/**` and run them with coverage:

```sh
cd mobile
tests=$(find test -type f -name '*_test.dart' ! -path 'test/visual/*')
test -n "$tests" || { echo "No non-visual tests found"; exit 1; }
flutter test --coverage $tests
```

This selection is the shared Android/iOS Release-equivalent non-visual gate. The current local tree passed this exact logical selection with coverage: 74 files selected, 24 visual files excluded, 584 tests passed, 0 failed, and 0 skipped in 306.3 seconds. The visual files were excluded rather than validated; no Golden was run or regenerated.

## 3. Flutter visual/Golden tests

Visual tests under `mobile/test/visual/**` are controlled rendering baselines and are deliberately excluded from Android Release's non-visual suite. Exclusion prevents platform-rendering noise and accidental baseline replacement; it does not make visual QA optional.

Rules:

- Run Goldens only in the approved rendering environment.
- Never regenerate baselines simply to make a failure disappear.
- Review the visual difference, source change, brand authority, RTL, text scale, and accessibility effect first.
- Goldens are testing evidence, not product or design authority.
- Baseline promotion requires an intentional reviewed change.

No Golden was run or regenerated during this iOS readiness task.

## 4. Integration and physical-device tests

Integration/device validation is separate from unit/widget and Golden tests. Required scenarios include:

- Launch, onboarding, guest gates, authentication, logout, deletion, callbacks, and deep links.
- Local Party and solo on supported device sizes, text scale, RTL, interruptions, and weak/offline transitions.
- Supabase-backed tournaments, teams, ranking, profile, reporting, and preferences with real roles/data.
- FCM foreground/background/terminated delivery and navigation.
- RevenueCat product load, purchase, restore, cancellation, expiry, entitlement refresh, and webhook reflection.
- AdMob consent, fill/no-fill, cadence, dismissal/failure, Premium bypass, and SSV where active.
- Analytics and Crashlytics delivery without leaking sensitive data.
- iOS Google/Apple authentication and platform-specific lifecycle behavior.

The available smoke integration test and provider wrappers are not equivalent to completed physical-device validation.

## 5. Desktop Web and Admin tests

Canonical checks:

- `npm run typecheck`
- `npm run lint`
- `npm test`
- `npm run build`

Website Rebuild Phase 2 records all four as passing on 12 September 2026: typecheck, lint, **16 unit-test files / 81 tests**, and a successful Next.js Production build (`Generating static pages … 27/27`). The Phase 2 additions contribute 18 focused tests across `party-gameplay.test.ts`, `solo-gameplay.test.ts`, and `player-website-phase-two.test.ts`; the updated Phase 1 suite also remains green.

Party coverage includes exact six-category selection/cap, deterministic valid 36-question packs, unique IDs, invalid-pack rejection, team/player/helper validation, helper timing and one-use behavior, used-question state, timer expiry, steal, reveal, deterministic score application, double-score prevention, undo, completion, winner/tie, replay/reset, serialization round-trip, and malformed/version-mismatched save rejection.

Solo coverage includes current RPC-row parsing, unsupported-format rejection, category/difficulty/count setup, pack insufficiency, timer expiry, correct/wrong scoring and speed bonus, double-answer prevention, result, accuracy/streak, replay, and personal-best state. Website-boundary tests prove guest `/play`, continued account/tournament guards, anonymous identity rejection from private context, existing RPC names, and continued removal of Friends/Online/1v1/2v2 entry copy.

Production gameplay-source searches found no hard-coded question arrays, demo/fallback question banks, fake standings, or demo usernames in the active Party/Solo path. Tests deliberately contain synthetic question fixtures for deterministic domain verification; these fixtures are under `admin/tests/**` and cannot enter the Production client bundle.

Desktop visual QA covered the live setup/empty-catalog state at 1440 × 1100 and 1024 × 900. The currently connected environment returned no displayable published categories. Test-only localStorage fixtures were therefore used to inspect the 6 × 6 board at both widths and the question, timer, helpers, reveal/score, and result compositions at desktop width. This is presentation evidence only and does not replace real-catalog or deployed E2E.

These checks do not validate real user/staff E2E, cross-browser/accessibility coverage, provider delivery, deployed catalog population, or Production role/RLS behavior.

Desktop player and staff Admin must be tested as separate products even though they share one Next.js application.

## 6. Database validation layers

| Layer | Purpose | Current approved evidence |
|---|---|---|
| Migration parser | Parse ordered SQL and function bodies | Passed for 27 migrations and 146 PL/pgSQL bodies; two catalog-less `_record` warnings were pre-existing |
| Static security checks | Inspect required security contracts | Passed 59/59 |
| Registration enum static/embedded | Protect corrected review enum contract | Passed 9/9 and 8/8 |
| Tournament embedded behavior | Exercise bracket/result contracts with stubs | Passed 29/29; not real concurrency |
| Voucher embedded behavior | Exercise voucher contracts with stubs | Passed 11/11; not real multi-connection behavior |
| pgTAP/JWT/RLS/upgrade | Real database authorization and compatibility | Nine suites exist; not run in the approved repository audit environment |
| Real concurrency | Two-connection locking/idempotency/races | Still pending where required |
| Linked Production lint | Inspect deployed database | `OPERATOR_VERIFIED`: 0 errors, 16 warnings |

Production migration history is already 27/27. Database testing must validate the deployed behavior; it must not recommend reapplying the four newest migrations or migration repair.

## CI suite boundaries

- Android Release CI excludes `test/visual/**` and runs the selected non-visual files explicitly.
- iOS Release CI now uses the same explicit non-visual selection and coverage policy.
- Pull-request checks currently run unfiltered `flutter test`.

Release pipelines therefore do not depend on unapproved/stale visual baselines. Pull-request checks still have a broader command and may include visual tests; any future PR-policy change must remain explicit. Do not “resolve” visual differences by silently regenerating Goldens.

## Release acceptance principle

A platform release requires the appropriate combination of static, non-visual, controlled visual, integration/device, backend, provider, security, store, and legal evidence. One passing layer cannot be used to infer another.
