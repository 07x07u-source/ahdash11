# AHDASH 11 — V10 Phase C Tournament Portrait Migration Report

Date: 2026-09-06  
Scope: Tournament screens 19–23 and 26–27. Screens 24/25 are bracket states only.  
Status: Complete locally; stopped after Phase C as requested.

## A. Screens migrated

- 19 — Tournament Hub
- 20 — Create Tournament
- 21 — Tournament Teams
- 22 — Tournament Draw
- 23 — Tournament Bracket
- 26 — Tournament Match
- 27 — Tournament Champion
- 24 — Semifinal and 25 — Final were implemented and verified as states inside screen 23.

All migrated surfaces use the shared V10 Portrait frame, header, input/button language, Paper/Ink/Green palette, shared spacing/radii, safe-area handling, and the existing Thmanyah Sans typography configuration. Obsolete active landscape tournament composition was removed where it conflicted with the portrait layout; domain, persistence, repository, security, and Party integration code was preserved.

## B. Tournament routes audited

The canonical routes remain:

- `/tournaments`
- `/tournaments/create`
- `/tournaments/join`
- `/tournaments/teams`
- `/tournaments/registrations`
- `/tournaments/draw`
- `/tournaments/bracket`
- `/tournaments/match/:matchId`
- `/tournaments/champion`

No routes were renamed merely to match Figma numbering, and no route migration was required.

## C. Confirmation that 24/25 are Bracket states only

Confirmed. Semifinal and Final are round-selected states rendered by `TournamentBracketScreen`. No `/tournament/semifinal`, `/tournament/final`, `/tournaments/semifinal`, or `/tournaments/final` production route was added.

## D. Tournament Hub real-data behavior

The Hub reads the actual `tournamentControllerProvider` state. Active/resumable cards, history, progress, completed matches, playable matches, next matchup, and champion are derived from real `Tournament` objects. It does not insert Figma sample tournaments or synthetic history. Actions resume the current domain state or enter the real creation flow.

## E. Empty/loading/error behavior

The Hub and dependent screens preserve truthful empty, loading, missing/unavailable, and safe Arabic error states. Missing tournament/bracket data does not produce a demo bracket. Controller errors are presented without raw Postgres, Supabase RPC, RLS, or stack-trace details. Blocked remote work does not display success language.

## F. Create Tournament fields and real domain constraints

The screen exposes only supported configuration:

- Tournament name: trimmed and validated by `TournamentEngine`; 3–60 characters.
- Capacity: the domain-supported values 4, 8, 16, 32, and 64.
- Players per team: 1–8.
- Visibility: the existing private/public choices exposed by this flow.
- Seeding: the existing draw/manual choices.

No league, group stage, double-elimination, third-place, home/away, betting, rating, or invented tournament setting was added. Arabic validation uses domain constraints rather than illustrative Figma values.

## G. Create Tournament keyboard behavior

The Create screen uses the shared keyboard-safe V10 frame and a scrollable form. The name field, validation, supported options, and primary CTA remain reachable with a 300 px test keyboard inset at both 360×800 and 390×844. Drag-to-dismiss is enabled, and there is no fixed footer trapped behind the keyboard. Dedicated widget tests and two keyboard Goldens pass.

## H. Teams implementation

Teams now use a portrait-first vertical list and vertical CTA area. Rows are sourced from the active tournament, preserve existing add/remove behavior, expose semantic labels, tolerate two-line long Arabic names, and remain scrollable/keyboard-dismissible. No club identity, logo, or team was fabricated.

## I. Team count validation source

Capacity and team validity remain governed by `TournamentEngine` and the active tournament rules. The UI reports the actual current count and required capacity; it does not hardcode a separate illustrative limit. Existing name/player validation and duplicate protections remain authoritative.

## J. Draw authority/stability

The Draw screen renders matchups already generated in authoritative tournament state. It does not create cosmetic random pairs and does not reshuffle during widget rebuild. Bracket generation, seeding, bye handling, persistence, and progression remain owned by the existing engine/controller boundaries.

## K. Reduced-motion draw behavior

The Phase C draw/bracket presentation is static and state-driven; no animation is used as state authority or as a prerequisite for persistence. Consequently reduced-motion users receive the same complete information without a blocking transition. No result is delayed until animation completion.

## L. Bracket Portrait strategy

The former desktop-style horizontal bracket was replaced with a round-focused portrait composition:

- Horizontally scrollable, semantic round-choice chips select a round.
- Match cards for the selected round are listed vertically.
- Cards explicitly state pending, ready, live, completed, bye, or cancelled status.
- Winner/score information is read from the real match state and never inferred from color alone.
- Pending matches are not falsely actionable.
- Vertical scrolling handles genuine content growth; the bracket itself has no squeezed desktop grid or connector layout.

## M. Bracket 390×844 result

Passed widget coverage and raw Golden inspection. Round navigation, cards, team names, status text, and CTA remain readable with no horizontal clipping or tiny desktop bracket.

## N. Bracket 360×800 result

Passed widget coverage and raw Golden inspection. The compact layout remains portrait-native, vertically scrollable, readable, and free of overflow.

## O. Bracket results at 393×852 / 412×915 / 430×932

All three sizes passed the responsive widget matrix at text scales 1.0, 1.2, and 1.3. Together with 360×800 and 390×844, the bracket was exercised at all five required viewport sizes.

## P. Semifinal state

The Semifinal is selected and rendered within the canonical bracket screen using the real round/match data. Its 390×844 Golden passed and was manually inspected. It has no standalone production route.

## Q. Final state

The Final is selected and rendered within the canonical bracket screen using the real final-round match data. Its 390×844 Golden passed and was manually inspected. It has no standalone production route.

## R. Tournament Match implementation

Tournament Match now uses the V10 portrait frame and vertical team cards, with the existing tournament name, real matchup, round/status context, management gate, and primary action. It sets up and transitions into the existing Phase B Party gameplay; it does not introduce a second question engine.

## S. Party-context handoff

The existing `PartyTournamentContext` path is preserved. The handoff carries tournament ID, match ID, team IDs/names through Party teams, tiebreaker/category setup, and the tournament association used to derive round/bracket context. Return routing remains resolved from the real Party/tournament session rather than widget-local display state.

## T. Party-result return behavior

The existing result resolver remains intact: a tournament-scoped Party result is applied to its tournament match, then resolves to the bracket or Champion when the domain reports a confirmed champion. It is not redirected into the ordinary Home/standalone Party completion path.

## U. Duplicate match-result safety

Existing engine/controller duplicate protections were preserved. Result application uses the real match identity and current state, preventing repeated navigation/taps from advancing the same completed match twice, duplicating winners, or reapplying a saved result. The domain tests covering progression and duplicate safety remain green.

## V. Champion implementation

Champion uses the real resolved tournament, champion team, final match score, and tournament name. The portrait layout supports a two-line champion name and restrained Gold emphasis. Its CTA maps to the existing Done behavior. No MVP, percentage, statistics, XP, reward, coin, wallet, or unsupported share flow was added.

## W. Tournament restoration

No persistence or restoration boundary was rewritten. Hub resume/history, active-tournament recovery, Teams, Draw, Bracket, Match, post-match progression, and Champion continue to resolve from controller/repository state. The migration remained presentation-focused, and restoration/domain regression tests pass.

## X. RTL status

Arabic-first RTL behavior is preserved across headers, team rows, VS/match content, round selectors, status labels, numbers, and navigation. The portrait bracket avoids connector mirroring ambiguity. Mixed or long Arabic/team names wrap or truncate intentionally without changing matchup meaning.

## Y. Accessibility status

Semantics are present/preserved for tournament cards, team rows and actions, draw matchups, round tabs, actual match state, winners, and Champion CTA. Important names are not shrunk to illegible sizes. Touch controls use the shared V10 components, and status/winner meaning is conveyed with text and semantics rather than color alone. The matrix passed at text scales 1.0, 1.2, and 1.3.

## Z. Fake-data audit

Production Tournament UI was audited for fake scores, ratings, points, seeds, statistics, dates, waiting times, player counts, rankings, XP, coins, and wallet/reward claims. The migrated flow renders controller/domain values or truthful empty/unavailable state. No Figma sample data or cosmetic fallback bracket was added.

## AA. Remote mutation fail-closed status

Unsafe remote Tournament mutation remains fail-closed. Production guests cannot silently create a local-success tournament; a failed remote bracket operation does not promote a local draft; a failed result mutation leaves the ready authoritative match unchanged; and blocked draw UI does not claim success. No optimistic local success was introduced to disguise a remote failure.

## AB. Tournament focused tests count/results

`flutter test test/features/tournament test/v10_phase_c test/visual/tournament_golden_test.dart`

- Result: 69/69 passed.
- Composition: 49 focused non-visual/domain/widget tests plus 20 Phase C Golden tests.

## AC. Security regression tests count/results

4/4 explicit security/fail-closed regressions passed:

- Production guest cannot silently create a local tournament.
- Remote bracket failure never promotes a local draft.
- Remote result failure leaves a ready match unchanged.
- Blocked draw remains truthful and reports no false success.

The tests do not assume either pending migration has been deployed.

## AD. Party regression test count/results

`flutter test test/features/party test/features/tournament/tournament_party_context_test.dart test/v10_phase_b test/visual/v10_phase_b_golden_test.dart`

- Result: 103/103 passed.
- This includes the 79 Party functional tests and 24 Phase B Goldens.

## AE. Phase A/B regression test count/results

- Phase A command (`test/v10_phase_a` plus Phase A Goldens): 30/30 passed.
- Phase B coverage in the Party regression command, including 24/24 Phase B Goldens: passed.
- Auth, Home, Categories, Team Setup, Helpers, Board, Question, Reveal, and Result remained green in the broad suite.
- No Phase A/B regression was observed.

## AF. Phase C Golden count/results

20/20 passed. This exceeds the minimum 18 states and covers Hub, Create, Teams, Draw, Bracket, Semifinal, Final, Match, and Champion at 390×844 and 360×800, plus Create-with-keyboard at both sizes. Baselines are stored under `mobile/test/visual/goldens/v10_phase_c/`.

## AG. Raw Golden review result

Raw renders were manually inspected for:

- Create keyboard at 360×800
- Teams at 360×800 and 390×844
- Bracket at 360×800
- Semifinal at 390×844
- Final at 390×844
- Match at 390×844
- Champion at 390×844

The initial Teams header clipping found during review was corrected and the affected render was reviewed again. The final inspected renders are clean, portrait-native, readable, and free of observed overflow/clipping.

## AH. Broad test count/results

`flutter test test/contracts test/core test/features test/shared test/v10_phase_a test/v10_phase_b test/v10_phase_c`

- Result: 325/325 passed.
- Previous reported baseline: 313/313.
- No regression.

## AI. flutter analyze result

`dart format` was run on the touched Dart sources. `flutter analyze` completed with: `No issues found!` The final standalone Tournament Golden rerun also completed 20/20.

## AJ. Files changed

- `mobile/lib/features/tournament/presentation/tournament_screens.dart`
- `mobile/lib/shared/presentation/v10_portrait.dart`
- `mobile/test/features/tournament/tournament_widgets_test.dart`
- `mobile/test/visual/tournament_golden_test.dart`
- `mobile/test/v10_phase_c/v10_tournament_portrait_contract_test.dart`
- `mobile/test/visual/goldens/v10_phase_c/` — 20 PNG baselines
- `docs/v10_phase_c_tournament_portrait_migration_report.md`

No routing, domain model, repository, RPC, RLS, persistence, or migration file was changed for Phase C.

## AK. Known limitations

- Direct retrieval from Figma file `1tbYuMwiC8b9vCj12TzbAA` was attempted but the available Figma connection returned `UNAUTHORIZED` and required reauthentication. The implementation therefore used the locked written V10 specification, the documented local V9.2 mapping, and the already-established Phase A/B V10 shared foundation. This limitation is not represented as a successful direct Figma inspection.
- Physical-device testing is intentionally deferred to the later V10 QA phase.
- Remote unsafe Tournament mutations remain intentionally unavailable until backend safety review and migration deployment occur in a separately authorized phase.
- No release, publishing, or deployment verification was performed because it was outside Phase C scope.

Migration integrity was checked after implementation:

- `20260902000100_gameplay_depth_v1.sql` SHA-256: `C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1`
- `20260905000100_tournament_bracket_safety_v2.sql` SHA-256: `E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14`

Both match the recorded pre-Phase-C hashes; neither migration was modified.

## AL. Confirmation

- No Supabase db push.
- No migration deployment.
- No Online activation.
- No Dark Mode.
- No Coins/Wallet/XP.
- No Release APK/AAB.
- No `supabase migration up`, remote SQL execution, remote RPC replacement, or RLS deployment.
- No publishing or application deployment.

Phase C stops here pending report review.
