# AHDASH | 11 — V10 Global UI/UX Refinement

Final implementation and visual-review report — 2026-09-07

Scope: Home-first refinement, centralized Guest least-privilege access, active Party/Tournament/account surfaces, responsive and accessibility validation. This report stops before Android build or any backend/release operation.

## 1. Home problems found

- The previous composition treated several destinations as peers, so the primary Party action did not dominate clearly enough.
- The large upper card and repeated card language consumed space without creating a strong editorial hierarchy.
- Brand/account state, discovery, and game modes lacked a clear visual rhythm.
- Guest restrictions were not communicated consistently at the point of intent.
- Some affordances risked implying data or availability that was not product truth.

## 2. Home improvements made

- Rebuilt Home around a single dominant Party hero and a clear `ابدأ لعبة` CTA.
- Added an original, code-native football-pitch motif and stronger AHDASH identity without copyrighted club artwork.
- Moved Tournament into the strongest supporting position, followed by Solo/Team Challenge and Saved Games.
- Reduced discovery destinations to a quieter row below gameplay.
- Removed active Online, fake XP/coins/wallet/stats, fake progress, and fabricated availability claims.
- Made real resumable Party state the only source of the resume treatment.
- Added a restrained Guest badge and clean `يتطلب حساب` states.
- Normalized spacing, typography, controls, SafeArea behavior, RTL, and compact layout.

## 3. Home before/after evidence

- Composite: `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/home_before_after.png`
- Preserved before capture: `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/before/home_account_390x844_scale1.0.png`
- Final signed-in primary: `C:/dev/ahdash11/docs/v10_ui_refinement/home/home_account_390x844_scale1.0.png`
- Final signed-in compact: `C:/dev/ahdash11/docs/v10_ui_refinement/home/home_account_360x800_scale1.0.png`
- Final signed-in at 1.3 text scale: `C:/dev/ahdash11/docs/v10_ui_refinement/home/home_account_390x844_scale1.3.png`

## 4. New Home hierarchy

1. Brand/account header and truthful identity state.
2. Dominant local Party hero.
3. Tournament as the primary supporting mode.
4. Solo and Team Challenge as paired supporting modes.
5. Saved Games as a separate archive action.
6. Ranking, Friends, and How to Play as low-weight discovery.

Online 30–32 remains absent and deferred.

## 5. Guest permissions before

- There was no global route-level capability guard.
- Protected destinations could mount before downstream providers rejected anonymous identity.
- Social calls did not fail early at the anonymous-client boundary.
- A queued report without an owner could later be associated with another signed-in identity.
- Anonymous users could reach notification/purchase identification code paths.
- Restrictions and return-to-intent behavior were fragmented.

Full audit: `C:/dev/ahdash11/docs/v10_ui_refinement/GUEST_AUDIT.md`.

## 6. Guest permissions after

- One fail-closed policy now controls navigation and UI capability decisions.
- Restricted deep links are intercepted before private providers mount.
- A contextual Auth Gate explains the restriction and offers Sign In, Create Account, and Back.
- Successful authentication resumes only a validated internal destination.
- The exact current local Party controller/session survives the conversion flow.
- Anonymous notification/store identification, protected social access, and report submission are rejected defensively.
- Offline reports retain their original account owner and cannot be rebound.
- No backend security, RLS, JWT, or RPC rule was weakened.

## 7. Exact Guest allowed capabilities

- Home.
- How to Play.
- Local Party setup, current gameplay, and current result.
- Existing limited local Solo.
- Local settings: sound, haptics, and reduced motion.

## 8. Exact Guest restricted capabilities

- Saved-games archive.
- Tournaments.
- Profile and account management.
- Friends and blocked players.
- Teams and Team Challenge.
- Account-specific notifications.
- Ranking.
- Football preferences.
- Premium and Restore Purchases.
- Reports.
- Cloud sync.
- Unknown or newly introduced destinations by default.

## 9. Centralized Guest policy implementation

- `lib/features/auth/domain/guest_capability_policy.dart` defines capabilities, route mapping, fail-closed decisions, and safe return destinations.
- `lib/features/auth/presentation/capability_provider.dart` exposes the policy to Riverpod UI.
- `lib/core/routing/app_router.dart` applies the guard globally and refreshes on authentication changes.
- `lib/features/auth/presentation/auth_gate.dart` provides contextual conversion UX.
- `safeReturnTo` accepts supported internal routes/queries and rejects external URLs, traversal, fragments, backslashes, unknown routes, and auth loops.

## 10. Auth Gate examples and screenshots

- Guest Home: `C:/dev/ahdash11/docs/v10_ui_refinement/guest/home_guest_390x844_scale1.0.png`
- Friends Auth Gate: `C:/dev/ahdash11/docs/v10_ui_refinement/guest/guest_auth_gate_390x844_scale1.0.png`
- Auth Gate at 1.3 text scale: `C:/dev/ahdash11/docs/v10_ui_refinement/guest/guest_auth_gate_390x844_scale1.3.png`

The gate copy is contextual to the requested capability. Authentication resumes the safe intended destination; report authentication returns to the question and never auto-submits.

## 11. Screens visually refined

- Home: signed-in, Guest, resume, restricted state, Auth Gate.
- Auth: Sign In/Create Account responsiveness, Guest-limit explanation, safe destination resume.
- Party: Categories, search/keyboard, category detail, Team Setup, Team Splitter, Helpers, Ready, Board, text/image Question, Reveal, Result.
- Tournament: Hub, Create/keyboard, Teams, Draw, Bracket rounds, Match, Champion.
- Account/utility: Profile, Friends/keyboard, Blocked Players, Notifications, Settings, Football Preferences/keyboard, Report/keyboard, Premium/loading, Ranking, Saved Games, How to Play, Solo, Team Challenge, Team Detail, Match Setup.

Party product truth remains unchanged: 6 categories, 36 questions, 2 teams, 3 categories per team, and the existing five helpers (`جاوب جوابين`, `اتصال بصديق`, `الحفرة`, `استريح`, `الفخ`). Party engine/domain behavior was not rewritten.

## 12. Components consolidated

- Shared portrait page scaffold/header and keyboard-safe body behavior.
- Responsive Party flow scaffold and bottom action treatment.
- Central Auth Gate and capability provider.
- Reused V10 cards, fields, buttons, section styling, states, tokens, and 44px+ control targets.
- Removed downstream text-scale suppression from active utility, Tournament, and Premium surfaces.

## 13. Responsive results

Validated at all required viewports:

- 360×800
- 390×844
- 393×852
- 412×915
- 430×932

The complete responsive visual fixture matrix passed **645/645** with no Flutter exception or overflow. Keyboard variants cover approximately 300px bottom inset on applicable forms. Critical standard-scale gameplay remains reachable without shrinking the whole screen.

## 14. Text-scale results

Validated at 1.0, 1.2, and 1.3 for all five viewports. The same 645/645 responsive matrix passed. Focused Party fixtures passed 210/210 and account/utility/Premium fixtures passed 135/135.

## 15. Test results

- Guest policy, real-router gates/resume, anonymous service behavior, reports, and Home: **58/58 passed**.
- Responsive visual fixture matrix: **645/645 passed**.
- Party matrix: **210/210 passed**.
- Account/utility/Premium matrix: **135/135 passed**.
- Full `flutter test`: **1,149 passed; 99 failed; 1,248 total**.

Every one of the 99 failures is an existing Golden pixel comparison after the intentional visual changes; there are **99 pixel-diff messages and 0 non-pixel failures**. Breakdown:

- Auth UX: 6.
- Tournament: 20.
- V10 Phase A: 16.
- V10 Phase B: 21.
- V10 Phase D: 18.
- V10 Phase E: 18.

No Golden was regenerated, accepted, or updated. Functional and responsive checks pass; baseline approval remains a deliberate visual-review gate.

Test evidence:

- `C:/dev/ahdash11/docs/v10_ui_refinement/focused_final.log`
- `C:/dev/ahdash11/docs/v10_ui_refinement/responsive_final.log`
- `C:/dev/ahdash11/docs/v10_ui_refinement/party_final.log`
- `C:/dev/ahdash11/docs/v10_ui_refinement/account_final.log`
- `C:/dev/ahdash11/docs/v10_ui_refinement/full_tests_final.jsonl`

## 16. Flutter analyze

`flutter analyze --no-pub`: **No issues found** in 47.2s.

Evidence: `C:/dev/ahdash11/docs/v10_ui_refinement/analyze_final.log`.

## 17. Screenshot paths

There are **694 actual Flutter PNG exports**. `SCREENSHOTS.json` is the exhaustive path and SHA-256 index:

- `C:/dev/ahdash11/docs/v10_ui_refinement/SCREENSHOTS.json`

Folders:

- Home: `C:/dev/ahdash11/docs/v10_ui_refinement/home/`
- Guest: `C:/dev/ahdash11/docs/v10_ui_refinement/guest/`
- Party: `C:/dev/ahdash11/docs/v10_ui_refinement/party/`
- Tournament: `C:/dev/ahdash11/docs/v10_ui_refinement/tournament/`
- Account/utility: `C:/dev/ahdash11/docs/v10_ui_refinement/account/`
- Before/after and contact sheets: `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/`

Representative review sheets:

- `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/home_before_after.png`
- `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/party_review.png`
- `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/tournament_review.png`
- `C:/dev/ahdash11/docs/v10_ui_refinement/before_after/account_review.png`

Required representative captures include:

- `party/06_categories_390x844_scale1.0.png`
- `party/08_teams_390x844_scale1.0.png`
- `party/10_helpers_390x844_scale1.0.png`
- `party/11_ready_390x844_scale1.0.png`
- `party/12_board_390x844_scale1.0.png`
- `party/13_text_390x844_scale1.0.png`
- `party/15_reveal_390x844_scale1.0.png`
- `party/16_result_390x844_scale1.0.png`
- `tournament/hub_390x844_scale1.0.png`
- `tournament/bracket_390x844_scale1.0.png`
- `account/profile_390x844_scale1.0.png`
- `account/friends_390x844_scale1.0.png`
- `account/settings_390x844_scale1.0.png`
- `account/premium_390x844_scale1.0.png`

## 18. Files changed

The exact implementation/test/tool inventory is in:

- `C:/dev/ahdash11/docs/v10_ui_refinement/FILES_CHANGED.md`

Summary: 26 Flutter files, 14 test files, 2 review tools, and review artifacts/logs. Existing unrelated dirty/untracked work was preserved. Canonical Figma references, existing Golden baselines, Party domain/engine files, Supabase files, and signing/release configuration were not edited.

## Release/backend confirmation

- No APK built.
- No Production AAB built.
- No signing or publishing performed.
- No Supabase operation, migration, SQL, RLS, RPC deployment, or remote mutation-security change performed.
- Online remains deferred.

Status: implementation and visual-review package are ready for visual approval. Stop here before Android build and before any Golden-baseline approval.
