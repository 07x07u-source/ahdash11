# V10 Phase G — Autonomous Player Playtest Report

Date: 2026-09-06  
Build under test: local Flutter working tree, V10 portrait product baseline  
Verdict: **PASS WITH PHYSICAL-DEVICE FOLLOW-UP** — all locally actionable P0/P1/P2 findings are fixed; the maintained suite is 382/382 and analysis/build are clean.

## A–I — Environment, reference, and Party coverage

**A. Environment used for interactive playtest.** Flutter Web was rendered in the Codex in-app Chromium browser at 390×844 and controlled through real semantic controls. `flutter devices` exposed Windows/Chrome/Edge only; `flutter emulators` exposed no Android emulator, and the repository has no Windows runner. Android behavior was therefore covered by widget/domain tests and a debug APK build rather than a physical tap run.

**B. Figma direct-access status.** PASS. Direct browser access to file `1tbYuMwiC8b9vCj12TzbAA` succeeded. The current locked pages `V10 - Portrait Product`, `V10 — Portrait Foundation`, and `V10 — Portrait Complete Review` were confirmed as the governing reference. Archived V9/V9.2 pages were not treated as the target.

**C. Screens visually reviewed.** Interactive: launch/onboarding, sign-in and validation, guest entry, Home, Party category loading/error state, Tournament Create/name/rules. Automated portrait review: Party setup/gameplay/results, Solo, Team Challenge, Tournament hub/create/teams/draw/bracket/match/champion, ranking, friends, blocked players, team detail, profile, notifications, settings, report, football preferences, and Premium.

**D. Party sessions simulated.** One interactive entry/resume attempt plus the maintained Party controller/widget/flow scenarios. The browser journey reached category selection; the complete journey was replayed deterministically in tests because Drift web storage was unavailable in this ad-hoc web target.

**E. Number of Party questions played.** Three distinct controller question openings were exercised directly in outcome tests, with additional board/reveal/helper/format scenarios across the Party suite.

**F. Correct answers simulated.** Two authoritative correct-award paths, including opponent steal.

**G. Incorrect answers simulated.** One authoritative incorrect/penalty path plus undo/re-score durability.

**H. No-answer cases simulated.** One no-answer transition into the ten-second opponent steal window.

**I. All five helpers verification.** PASS: two chances, call a friend/timer, bench detail, pass/switch answering team, and risk. Their prerequisites, active/consumed states, persisted effects, and duplicate protection are covered.

## J–U — Core game and tournament findings

**J. Board findings.** Used cells, turn movement, team ownership, automatic/manual split, restore, and restart remain deterministic and durable.

**K. Question findings.** Released render formats fit portrait and landscape harnesses; question selection/reveal/score transitions remained authoritative.

**L. Reveal/security findings.** The answer remains absent from visible text and semantics before reveal; duplicate reveal and score submissions are rejected.

**M. Score findings.** Correct, incorrect, opponent-steal, undo, negative score, turn advance, and persisted score paths passed.

**N. Final Result/Play Again findings.** Result routing and Play Again create a real setup draft while preserving teams; covered by flow and gameplay widget tests.

**O. Saved-session findings.** Active board/question/reveal/result routes restore to the exact canonical step. A newly found indefinite-cache wait was fixed so an unavailable cache no longer disables starting Party.

**P. Solo findings.** Solo pool, setup, answer/reveal/result states and compact layouts passed maintained tests. No live-network claim is made.

**Q. Team Challenge findings.** Portrait composition and supported join/challenge behavior passed widget/contract coverage; remote multi-user delivery remains external QA.

**R. Tournament flows simulated.** Create → rules → teams → draw → bracket → match → champion, plus registration/join and Party handoff/restore paths.

**S. Tournament matches simulated.** Semifinal/final readiness, result confirmation, retry/idempotency, Party context and restore were exercised through tournament engine/controller scenarios.

**T. Bracket findings.** Draw safety, stable match identifiers, failure containment, undo, bracket progression and Party handoff remained correct.

**U. Champion findings.** Champion state and terminal routing fit the portrait matrix and retained the authoritative tournament result.

## V–AE — Utility surface findings

**V. Ranking findings.** PASS in maintained responsive/state coverage.

**W. Friends findings.** PASS for portrait, keyboard/search and supported actions.

**X. Blocked Players findings.** PASS for empty/populated and unblock presentation states.

**Y. Team Detail findings.** PASS for portrait layout and supported team actions.

**Z. Profile findings.** PASS for portrait composition and truthful local/remote states.

**AA. Notifications findings.** PASS for loading/empty/populated states; real push delivery still requires configured FCM and a device.

**AB. Settings findings.** PASS for toggles, persistence-failure truthfulness and legal-link availability rules.

**AC. Report findings.** PASS for valid submission, safe context, queued offline handling and keyboard reachability.

**AD. Football Preferences findings.** PASS for search, selection, visibility and keyboard reachability.

**AE. Premium findings.** PASS for safe disabled/fallback behavior; no purchase claim was made without store/RevenueCat configuration.

## AF–AP — Quality, defects, and improvements

**AF. Keyboard/scroll findings.** PASS at 360×800 and 390×844 with 300px keyboard inset for the maintained auth/tournament/report/football cases.

**AG. RTL/typography findings.** PASS across 360×800, 390×844, 393×852, 412×915 and 430×932 at text scales 1.0/1.2/1.3. The Tournament visibility value overflow found interactively at 390×844 was fixed with an expanded, single-line ellipsized dropdown.

**AH. Accessibility findings.** Semantic controls supported keyboard activation in the rendered app; answer secrecy and major button labels are covered. TalkBack/VoiceOver traversal remains physical-device QA.

**AI. Loading/empty/error findings.** Auth validation, Party catalog failure/retry, storage timeout fallback, and tournament draft fallback were exercised. Failures no longer leave primary actions permanently disabled.

**AJ. Performance findings.** No blocking UI exception was observed after timeouts were added. No FPS/jank metric is claimed without a profile-mode physical device.

**AK. Console/runtime exceptions found.** Product runtime exceptions after fixes: 0. One stale browser DDC reload message occurred during hot restart and was not reproducible as an app defect.

**AL. P0 defects found/fixed/remaining.** 0 / 0 / 0.

**AM. P1 defects found/fixed/remaining.** 2 / 2 / 0: Party restore could wait forever and disable the core CTA; Tournament restore/draft read could wait forever and disable Create progression.

**AN. P2 defects found/fixed/remaining.** 1 / 1 / 0: Tournament visibility dropdown overflow at 390px portrait.

**AO. P3 defects found/fixed/remaining.** 0 / 0 / 0.

**AP. Design/UX improvements made.** Core entry routes now fail open to usable local setup after bounded waits, with truthful Party feedback; compact Tournament choices now truncate safely instead of painting outside their field.

## AQ–AX — Delivery evidence and remaining external work

**AQ. Files changed.** `mobile/lib/core/routing/app_router.dart`; `mobile/lib/features/party/presentation/party_game_controller.dart`; `mobile/lib/features/tournament/presentation/tournament_controller.dart`; `mobile/lib/features/tournament/presentation/tournament_screens.dart`; Party and Tournament controller/widget tests; this report.

**AR. New tests added.** Three regressions: unavailable Party cache, unavailable Tournament cache/wizard, and compact 390×844 Tournament rules at text scale 1.3.

**AS. Final test count/results.** **382/382 PASS**, exit 0. Scope: `test/contracts`, `test/core`, `test/features`, `test/shared`, and `test/v10_phase_a` through `test/v10_phase_e`. A raw unscoped run was intentionally stopped after it entered archived V9/V9.2 golden baselines; those are not the maintained V10 suite or current Figma target.

**AT. `flutter analyze` result.** PASS — no issues found.

**AU. Debug build result.** PASS — `mobile/build/app/outputs/flutter-apk/app-debug.apk` built successfully. No release/AAB/publish action was performed.

**AV. Items still requiring physical manual QA.** Full Android tap session; soft-keyboard behavior on OEM devices; back gestures; TalkBack; haptics/audio; lifecycle/background restore; low-memory process recreation; profile-mode FPS/jank; real deep links; push delivery; purchases; and multi-device Tournament/Team Challenge coordination.

**AW. External configuration blockers.** No Android emulator or attached phone; no verified Apple provider, RevenueCat store products, production legal endpoints, or FCM delivery environment. These values were not invented.

**AX. Backend security blockers.** Online remains deferred. No Supabase deploy, migration, remote SQL, RLS change or RPC replacement was performed. In particular, `20260902000100_gameplay_depth_v1.sql` and `20260905000100_tournament_bracket_safety_v2.sql` were not deployed; their production security/contract validation remains backend-owner work.

