# AHDASH 11 V9.2 — Phase 6 release report

Date: 2026-09-05. Local screens 38–43, awaiting Product Owner review. No remote deployment or device certification. Phase 5 production gate remains active.

## A. Screens implemented
38 Profile; 39 Notifications; 40 Settings; 41 Report a Problem; 42 Football Preferences; 43 Premium.

## B. Models/providers/repositories
PlayerProfile, ProfileRepository/playerProfileProvider; NotificationsRepository/notificationsProvider; AppPreferences/PreferenceStorage; notification preferences repository/controller; existing AppErrorReporter with ProblemReportController; FootballRepository/entities/controller; PurchaseService/RevenueCat with PremiumController. Existing routing, feedback, tokens and packaged assets reused.

## C. Profile fields
Actual public name/username, existing Player 11 identity, server Premium flag, visible league/club, and returned numeric matches/wins/tournament participation/titles. Unsupported history tabs are omitted.

## D. Demo fallback
Removed development-player and fake XP/Coins/rating fallback from playerProfileProvider. Missing profile fails truthfully; missing stats are not shown as successful zero queries. Legacy unused model defaults remain for compatibility.

## E. Player 11
Existing male/female Player 11 artwork and component reused. No user portrait URL is passed. Color priority: team → visible club → custom → shared fallback; no official kit generated.

## F. Profile privacy
Football choices require explicit visibility. No email, phone, OAuth metadata, private report, internal ID or invite token is displayed.

## G. Notifications
Actual account-filtered rows, loading, empty, data, safe error, unread/read, refresh, all/unread filters. Mark-read requires returned server row. No production samples or unsupported accept/reject actions.

## H. Deep links
Existing allowlist retained with validated UUID/code destinations; rejects arbitrary/absolute URLs, authorities, fragments and invalid codes. Extra join parameters are dropped. Unsafe destination returns /notifications.

## I. FCM
Locally inspected permission/token/event architecture and tested route policy. Actual foreground/background/terminated delivery was NOT tested and requires a physical device.

## J. Settings
Sound, haptics, reduced motion, notifications, account/identity, league/club, Premium, help/privacy; version and automatic-save copy. Sheets retain eight server notification preferences, device permission request, Player 11 variant, profile, sign-out, confirmed deletion, report, existing blocked-player navigation and HTTPS legal links. No theme selector.

## K. Persistence
Existing small preference keys, repository-wrapped SharedPreferences, serialized writes and post-success state updates. Safe read defaults; safe failure messages. No global Save, tokens, gameplay authority or entitlement stored there. Legacy theme infrastructure stays inactive.

## L. Sound/haptics
Existing centralized preferences and feedback service are used. Utility toggles do not emit repeated haptics. No new sound assets.

## M. Report fields
Supported category, optional description ≤1500 characters, allowlisted source, existing app version/build/platform metadata. No attachment UI. Safe Arabic errors and no PII in analytics.

## N. Report safety
Busy/sent guard, preserved draft on failure, account reset, and no false success for no-op. Existing backend limit: 5 per user per 24 hours. Timeout blocks automatic retry; server lacks idempotency, so cross-process exactly-once delivery is not claimed.

## O. Football data
Existing list/search/preferences RPCs. League-filtered/debounced search, stale-response guards, incompatible club cleared on league change, real save. Read-only remote audit: 6 published leagues, 114 clubs; no writes/seeding.

## P. Badge rights
All 114 audited clubs were fallback. Only licensed/custom may use remote logos; other states use the shared procedural badge.

## Q. Football privacy
show_publicly goes through existing RPC. Private profile hides league and club. No local private durable cache.

## R. RevenueCat mapping
Current offering monthly/annual → monthly/yearly PremiumPlan; existing configured entitlement and customer-info state.

## S. Prices
StoreProduct.priceString is displayed unchanged. No production price constants or manufactured savings; deterministic prices appear only in tests.

## T. Purchase
Current-account identity, busy guard across route rebuilds, real store result plus refreshed active status required. Cancellation/error never grants locally. Physical pending/resume behavior remains uncertified.

## U. Restore
Real restore followed by status query. Distinct confirmed/no-entitlement/error copy; no false restored message.

## V. Entitlement
Existing access checks remain; Party entitlement now follows auth changes. No preference-based authority or competitive advantage.

## W. Coins/Wallet
/store renders PremiumScreen; /wallet redirects to /store; /premium remains supported. Old coin StoreScreen is inactive, not routed.

## X. Fairness
Benefits limited to existing Premium content and supported interstitial removal. No pay-to-win, point multiplier or answer advantage.

## Y. Account caches
Profile/inbox/football/Premium providers depend on auth; loading UI hides previous data, stale operations are rejected, report drafts reset. No new durable private cache. Account-independent UI preferences retained. SDK/server RLS certification remains manual.

## Z. Thmanyah
Original Sans 400/500/700/900 reused; icon fonts loaded in Goldens. Arabic/English identity, club labels and localized prices included. No Cairo/Serif replacement.

## AA. Sizes
All six screens at 800×360, 844×390, 915×412, 1280×720, 1366×768.

## AB. RTL/accessibility
17 widget tests cover compact RTL, reduced-motion settings, text scale 1.0/1.4, truthful states, exact price and full 48px purchase CTA, plus report keyboard/scroll reachability. Settings fully fits 1280 first viewport; compact lists scroll intentionally. Physical screen-reader/focus/keyboard testing remains outstanding.

## AC. Analytics/Crashlytics
Existing abstractions used for settings_changed, notification opening, football_preferences_saved, report_submitted and purchase/restore events. No names, body text, descriptions, search strings, receipt or token fields added. Purchase integration errors report a constant sanitized message; cancellation/empty/offline paths are not crash events. Tests use no-op analytics.

## AD. Tests
Phase 6 contracts/providers: 40/40. Phase 6 widgets: 17/17. Before-change broad baseline: 233/233. Final broad non-visual rerun: **290/290 across 50 files**, including the 57 new tests. The existing report submission test was updated for the intentional Phase 6 copy/auth contract and passed 1/1 separately and in the full rerun. dart format checked 26 files with 0 changes; flutter analyze --fatal-infos completed with no issues.

## AE. Goldens
35/35 Phase 6 baselines created, then passed without update. Combined unchanged Phase 2–5 plus Phase 6 run: 160/160 (125 previous + 35 new). No unrelated baseline regenerated.

## AF. Raw review
35/35 individual PNGs opened and reviewed. See v9_2_phase6_visual_review.md. This is local review, not Product Owner or device approval.

## AG. Files changed
Production: profile model/provider/screen; new notifications repository and screen; safe notification routing; app_preferences; Settings and notification preferences; report controller/screen; football entities/repository/controller/screen; Premium controller/screen; shared utility_v9; Party entitlement dependency; app router.
Tests: phase6_fixture; phase6_contracts_test; phase6_widgets_test; v9_2_phase6_golden_test; updated existing report_problem_screen_test; 35 PNGs.
Docs: implementation map, asset map, four Phase 6 contracts, visual review and this report. Existing untracked workspace files were preserved.

## AH. Backend/schema
None. No new/applied migration edits or remote mutation.

## AI. Phase 5 gate
Both pending migration SHA256 hashes remain unchanged:
20260902000100_gameplay_depth_v1.sql — C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1.
20260905000100_tournament_bracket_safety_v2.sql — E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14.
Tournament mutation remains fail-closed. Migration review, pgTAP/security execution, JWT/RLS, rate/concurrency testing and staging deployment approval remain required.

## AJ. Known limitations
Figma connector requested reauthentication; previously inspected browser/reference compositions were used. Existing packaged Player 11/background assets retained. No report attachments/backend idempotency, unsupported profile history or fake offerings. Football search retains existing 30-row page bound. Store offerings may change before the store confirmation; current service re-fetches the selected period. UI tests are not comprehensive SDK/network/device certification.

## AK. Manual device work
FCM delivery/permissions/token rotation in all app states; real sandbox prices/purchase/cancel/pending/restore/expiry/refund/reinstall/account switching; device keyboard, screen reader and focus; live report/network uncertainty; account deletion and RLS authorization. None claimed performed.

## AL. Scope confirmation
No Phase 7, Emulator, app installation, APK, Supabase push, migration, active Dark Mode, Rive, random SFX, fake profile/notification/football production data, hardcoded prices, Coins/Wallet active UX, pay-to-win or Online reactivation.

---

# Historical Phase 5 report (retained)

Date: 2026-09-05. Screens 19–27 are implemented and locally validated. **Awaiting Product Owner review; production draw/result writes remain gated by the undeployed v2 RPC patch and full Supabase security validation.** Phase 6 has not begun. The previous Phase 4 report is retained below as historical evidence.

## A. Screens implemented: 19–27

19 Hub, 20 Create, 21 Teams, 22 Draw, 23 Bracket, 24 Semifinal state, 25 Final state, 26 Match and 27 Champion. Seven standalone compositions and two embedded Bracket states use V9.2 Light styling and original Thmanyah Sans.

## B. Existing Tournament engine/models/RPCs reused

Retained Tournament, TournamentRules, TournamentTeam, TournamentMatch, TournamentEngine, registration repository, Drift storage and the shared Party engine/session architecture. No second advancement engine. Creation and registration use the existing RPCs. Unsafe legacy draw/result writes are replaced by versioned v2 RPCs through TournamentGateway, with no unsafe fallback.

## C. Actual Tournament statuses and flow resolver

Tournament statuses are draft, registration, ready, live, completed and cancelled. Match statuses are pending, ready, live, completed, bye and cancelled. TournamentFlowResolver deterministically selects current round/match, next destination, draw/edit eligibility, Party resume/confirmation and confirmed Champion. Corrupt/incomplete completion cannot invent a champion.

## D. Routes/deep-link/resume behavior

Preserved /tournaments, /create, /teams, /draw, /bracket, /match/:matchId and /champion under the existing Tournament prefix, plus existing join/registration paths. Guarded routes restore before canonical resolution. Unknown match links attempt an RLS-scoped owning-tournament lookup. Completed Match/Bracket remain reviewable; invalid states resolve safely without a redirect loop. Party uses its existing canonical setup/gameplay routes.

## E. Hub real-data states

Displays real empty, cached/loading/error, draft/registration, draw-ready, live and completed state. Continuation follows the resolver; upcoming match is sorted by actual round/position. Progress counts completed played matches and excludes byes. Local completed history remains real saved data, not Figma samples.

## F. Create Tournament real fields and validation

Two steps: name, then supported rules. UI exposes capacity, players per team, privacy and draw/manual seeding using domain values; existing timer/category/helper/tiebreaker defaults are preserved. Domain validates trimmed tournament name 3–60, capacities, player count, timer 10–120 and unique category IDs. Wizard values, step and stable UUID are separately persisted in Drift; creation retries reuse the same persisted candidate. Busy protection rejects repeated submits; uncertain creation does not silently change candidate values.

## G. Teams/player membership behavior

Existing server team IDs, owner, registration status, seeds and player roster IDs/user/captain metadata are hydrated and preserved. Registration approval refreshes that identity rather than creating a duplicate local team. Manually added entries are explicitly staged locally until draw commit; no fake captain/player is manufactured. Existing add/approval flows are used; no new unsupported removal/editor API is exposed.

## H. Exact supported capacities/team rules

Verified capacities: 4, 8, 16, 32, 64, centralized in TournamentRules. Players per team: 1–8. Eligible team count is 2 through capacity; sparse graphs use supported byes. Team names are 2–40 characters. Player names, when entered, are bounded to 50 characters and validated against duplicate names; rosters may be absent where the existing host-entered-team model permits that. IDs, not display names, define database identity.

## I. Draw authority and randomness model

Preserved client-generated domain draw with transactional server validation, not UI randomness. Injectable random seed is supported by the existing engine; the controller derives a stable seed from the persisted tournament UUID. Tests check complete/sparse graphs, unique teams, valid byes, positions and advancement. The server validates the graph but does not certify lottery fairness.

## J. Draw retry/idempotency behavior

The candidate graph is durably stored before submission. Double taps are blocked and uncertain retries restore identical team/match IDs, seeds, edges and slots across controller reconstruction. Edits are blocked while a draw outcome is uncertain. No successful bracket is revealed before server success in remote environments. The SQL replay guard accepts exact pre-play replay without another graph/event; a stale retry after results exist is rejected and requires refresh.

## K. Result of the save_tournament_bracket safety audit

The inspected original SQL body deletes tournament_matches, tournament_players and tournament_teams, then reinserts teams/matches but not the roster. This is a concrete data-loss risk in the repository SQL and original client path. A live remote pg_get_functiondef dump was not obtained, so remote manual drift is not certified. See v9_2_phase5_tournament_contract.md.

## L. Whether tournament_players can be deleted

**Yes by the inspected old function; no roster delete/update exists in the new v2 save function.** Existing players and membership are preserved. Only newly staged teams insert new roster rows. Until migration deployment the old function still exists on the server; the new client does not call it. The patch revokes its client execution when deployed.

## M. Patch migration: filename and purpose

supabase/migrations/20260905000100_tournament_bracket_safety_v2.sql adds safe bracket persistence and result confirmation, preserves roster identity, validates graphs, locks authority/status, rejects destructive redraw and makes exact replay safe. It also revokes authenticated/public/anon execution of the old unsafe mutation functions.

## N. Applied migrations

No already-applied migration was edited. The fix is a new migration only.

## O. Redraw restrictions

No new Redraw action is exposed. The engine rejects an existing/live/completed graph. SQL allows safe draft/registration/ready graph replacement only before playing/session-bound/confirmed matches, while preserving roster data. Locked/live/completed conflicting payloads and stale post-result draw replays are rejected.

## P. Bracket entity mapping

Widgets consume actual round, position, teamAId/teamBId, scoreA/scoreB, winnerId, status, nextMatchId and nextSlot. Matches are deterministically sorted. Paired feeder connectors require the same actual destination and opposing slots. Page/tab selection changes focus, never advancement. Pending/BYE matches cannot launch gameplay; current/winner/score states are derived from entities.

## Q. Semifinal/Final merged-state behavior

24 and 25 are round selections inside TournamentBracketScreen at /tournaments/bracket. No duplicate Semifinal/Final route or engine was added. Both have their own five-size Golden states.

## R. Tournament Match → Party session integration

Launch binds tournament ID, match ID, both team IDs, real roster names, timer, category and tiebreaker context to shared Party setup. It reuses the same PartyGameSession and existing gameplay engines. Re-launch resumes the matching draft/session; a different unfinished game cannot be silently replaced. Unsupported helper-disabled/non-six fixed-category rules are explicitly blocked from Party launch, not emulated.

## S. Tournament context restoration

PartyTournamentContext round-trips through draft/session JSON and copy operations; the selected Tournament match is persisted separately. Restore returns to the existing Party setup/board/question/reveal/result state without regenerating the board or session UUID. Bound team identity cannot be changed by normal Party setup/splitter controls. Standalone Party behavior remains compatible.

## T. Result confirmation

Tournament-bound Party Result returns to Match review. Confirmation requires a complete matching session and exact scores/context; it is not triggered by rendering Result. The organizer separately may enter an external non-tied result. Remote failure preserves the prior match result/advancement and keeps a safe retryable Arabic error. Client and SQL reject invalid participants/winner/score combinations.

## U. Tie/tiebreaker behavior

Party ties remain in its existing tiebreaker flow when allowed. Tied Party scores cannot confirm Tournament advancement. SQL/domain honor the tournament tiebreaker contract; winner/score disagreement is rejected. The external-result sheet does not invent a tied-score winner. There is no coin-flip or fabricated champion.

## V. Duplicate-result protection

Busy guards plus matching completed-result checks protect the client. SQL locks the tournament/match and treats exact completed replay as a no-op; a conflicting replay is rejected. No duplicate advancement or confirmation event is produced. Reopening Champion/exact local replay does not replay win feedback.

## W. Winner advancement behavior

The existing domain engine computes the candidate; SQL validates and atomically writes the winner into the actual next-match slot. Missing/occupied/started dependents are rejected. The transaction records confirmation/advancement once. Presentation widgets never change bracket winners.

## X. Champion completion behavior

Champion requires a completed tournament, actual final match, confirmedAt, matching real final winner and champion team. Final result, champion identity and tournament completion are committed transactionally on the server. An incomplete snapshot displays a safe non-champion destination.

## Y. Organizer/participant authorization

Client mutation actions check authenticated non-guest organizer identity; non-organizers receive read-only UI. Staging/production missing auth/config or RPC failure never becomes local success. Explicit no-Supabase development retains the existing local mode. SQL v2 uses require_active_user, rate limiting, organizer checks, fixed search_path and row locks. Existing RLS-scoped reads/registration functions remain in place.

## Z. Responsive sizes tested

800×360, 844×390, 915×412, 1280×720 and 1366×768. All seven main states were exercised at text scales 1.0 and 1.3. Match and Champion need no ordinary vertical scrolling at standard scale; Teams/Draw have intentional internal scrolling and Bracket has round/page focus.

## AA. RTL/accessibility results

Reviewed RTL headers/back controls, tabs, team order, real advancement connections and score labels. Long/mixed Arabic-English names fit the tested scaled layouts without Flutter overflow. Shared touch/focus policies and explicit disabled/status/winner semantics are retained; color is not the only signal. Champion history-link contrast was corrected to Ink. Static layouts work with Reduced Motion. Physical screen-reader traversal and native keyboard/device accessibility certification were not performed.

## AB. Security/RLS validation

SQL parser: 25 migrations and 140 PL/pgSQL bodies passed, with two pre-existing catalog-type warnings in older migrations. Exact new SQL bodies executed locally in PostgreSQL/WASM: 29/29 behavioral checks passed. The 21-check pgTAP structural/security file was added but **not run on Supabase**. Local lint could not connect to 127.0.0.1:54322. JWT/RLS integration, rate limits and concurrent-connection behavior remain an explicit release gate; a simulated auth helper is not RLS certification.

## AC. Tests with exact counts

- Pre-change broad nonvisual baseline: 205/205 passed across 44 test files.
- Phase 5 Tournament suite: 37/37 passed: engine 10, controller 7, resolver 4, Party context 3, registration model 2, widgets 11.
- Broad nonvisual suite after implementation: 233/233 passed across 48 test files, including the existing Party tests.
- Existing Party suite: 70/70 passed in the focused compatibility run.
- SQL behavioral driver: 29/29 passed; pgTAP 21 checks authored, not executed against Supabase.
- Final targeted formatting: 21 files checked, no changes required. flutter analyze --no-pub --fatal-infos: no issues.

These are overlapping suites, not additive totals. The 11 widget tests cover the five-size/two-scale matrix and read-only permissions; they are not a claim of a separate test for every modal/network branch.

## AD. Goldens with exact counts and update status

45/45 Phase 5 Light comparisons passed after intentional Tournament-only baseline updates, including 35 core and 10 Semifinal/Final states. The final five Champion updates corrected link contrast; the complete 45 suite then passed without update mode. Phase 3 30/30 and Phase 4 25/25 unchanged comparisons passed together (55/55). No unrelated baselines were regenerated; historical Dark files remain inactive.

## AE. Raw screenshot review count

45/45 final raw Phase 5 PNGs opened individually and reviewed. The exact matrix, observations, intentional changes and review limits are in v9_2_phase5_visual_review.md. Product Owner visual approval remains pending; this is not a claim of pixel-perfect identity.

## AF. Files changed

Production Dart:
- mobile/lib/core/routing/app_router.dart
- mobile/lib/features/tournament/data/tournament_gateway.dart (new)
- mobile/lib/features/tournament/domain/tournament.dart
- mobile/lib/features/tournament/domain/tournament_engine.dart
- mobile/lib/features/tournament/presentation/tournament_controller.dart
- mobile/lib/features/tournament/presentation/tournament_flow.dart (new)
- mobile/lib/features/tournament/presentation/tournament_screens.dart
- mobile/lib/features/tournament/presentation/tournament_registrations_screen.dart
- mobile/lib/features/party/domain/party_tournament_context.dart (new)
- mobile/lib/features/party/domain/party_game.dart
- mobile/lib/features/party/presentation/party_game_controller.dart
- mobile/lib/features/party/presentation/party_game_screens.dart (bound Tournament result return only)

Tests/evidence:
- mobile/test/features/tournament/tournament_engine_test.dart
- mobile/test/features/tournament/tournament_controller_test.dart (new)
- mobile/test/features/tournament/tournament_flow_test.dart (new)
- mobile/test/features/tournament/tournament_party_context_test.dart (new)
- mobile/test/features/tournament/tournament_widgets_test.dart (new)
- mobile/test/visual/tournament_golden_test.dart and 45 Tournament Light PNGs
- supabase/migrations/20260905000100_tournament_bracket_safety_v2.sql (new)
- supabase/tests/007_tournament_bracket_safety_v2_security.sql (new)
- supabase/tests/tournament_v2_behavior.mjs (new)
- .codex-temp/phase5-sql/package.json and package-lock.json (isolated SQL test dependency only)

Documentation:
- docs/v9_2_figma_flutter_implementation_map.md
- docs/v9_2_tournament_flow.md (new)
- docs/v9_2_phase5_tournament_contract.md (new)
- docs/v9_2_phase5_visual_review.md (new)
- docs/v9_2_asset_map.md
- docs/v9_2_motion_haptics_audio.md
- docs/v9_2_release_report.md

The worktree was already wholly untracked, so git diff is not a reliable authored-change inventory. Unrelated pre-existing files were preserved.

## AG. Backend/schema changes

One necessary SQL patch adds two versioned functions/revokes unsafe legacy execution. No new product tables/columns, Edge Functions, app dependencies or production data were added. No remote mutation/deployment was performed.

## AH. Supabase dry-run result

npx supabase db push --dry-run succeeded and listed two pending migrations: pre-existing 20260902000100_gameplay_depth_v1.sql and new 20260905000100_tournament_bracket_safety_v2.sql. Neither was applied. The owner must review both; do not treat the earlier pending migration as implicitly approved for deployment.

## AI. Known limitations

- Production draw/result writes require deployment of the new v2 RPCs and successful full Supabase security testing; missing RPCs fail closed. No live function-body dump or PostgREST/JWT end-to-end test was obtained.
- Existing Tournament cache is not realtime multi-device synchronization. Refresh is authoritative; stale post-result draw retries require it. Local cache is not newly account-partitioned; organizer checks prevent another account from mutating a cached tournament.
- Manually entered teams are staged locally until draw commit. No new team/player editing/removal product surface or remote undo is introduced.
- Party launch blocks helper-disabled tournaments or a fixed category set other than six. External organizer-entered results remain supported.
- Host-judged/manual results retain the existing trust model; server verification of question-level Party scores was not added.
- Raw review and widget tests are not physical-device/screen-reader/keyboard testing or exhaustive network/modal coverage. Owner visual acceptance remains required.
- No approved custom SFX/Rive exists; the flow uses restrained shared/static visuals and preference-aware system feedback.

## AJ. Confirmation

No Phase 6. No Emulator. No APK. No Supabase remote push. No applied migration edited. No Rive. No random SFX. No fake Tournament data in production. No fake Champion. No Online reactivation.

# Historical checkpoint — Phase 4 release report

Historical status at the Phase 4 checkpoint: Phase 4 complete; stopped before Phase 5 pending review. The Phase 5 report above supersedes this scope boundary.

## A. Screens implemented

12 Game Board, 13 Text Question, 14 Image Question, 15 Answer Reveal, and 16 Final Result.

## B. Existing Party engine/state reused

The implementation keeps `PartyGameSession`, question snapshots, `PartyGameController`, `PartyGameEngine`, `PartyHelpEngine`, `PartyScoreEngine`, `TurnEngine`, existing repositories, Drift session/history storage, remote question-pack path, and tournament result context as the functional authority. Figma V9.2 is used only as the visual authority.

## C. Gameplay routes and resolver behavior

The existing routes remain `/party/board`, `/party/question`, `/party/reveal`, and `/party/result`. `PartySetupFlowResolver` now resolves setup and gameplay; `redirectGameplay` prevents deep links or rebuilds from displaying a state that does not match the saved session.

## D. Resume behavior for Board/Question/Reveal/Result

No open question resumes Board; an open unrevealed question resumes Question; a revealed question with a pending score resumes Reveal; an authoritatively complete session resumes Result. Used questions cannot reopen, and the pending score decision is not lost.

## E. Draft cleanup behavior

Start waits for pending draft writes, persists the new session/history, and clears `party_setup_draft_v2` in one Drift transaction. Failure keeps the draft intact; retry can succeed and then clear it. A new draft may take precedence without deleting the older resumable session until its replacement is safely persisted.

## F. Board real-data integration

The Board uses the real six category snapshots, all 36 question cells, per-question point values, used state, current turn/answering team, both scores, and session progress. No Figma category, score, question ID, point tier, or used cell is hardcoded into production presentation.

## G. Board cell states

Available, pressed/loading, used, disabled, and current-selection states are implemented. A focused cell loader guards rapid opens, all other cells disable during the request, and failure restores interaction with a safe Arabic retry message. Used cells have a check icon and semantic state, so color is not the sole signal.

## H. Text Question behavior

The real question is the dominant element; real category, points, timer/state, and available helpers remain secondary. Line-aware sizing supports short/long Arabic, mixed English, numbers, club/player names, multiline content, and tested 1.35 text scaling without truncating the question.

## I. Image Question ratios/loading/error/security

Portrait (`0.72`), square (`1.0`), and landscape (`1.78`) ratios are covered. Composition adapts rather than forcing one split, uses focal alignment, stable aspect ratio, cache-aware decode dimensions, loading feedback, branded fallback, and retry. Errors never auto-reveal or auto-score; semantics expose only `وسائط السؤال`, not URL, filename, debug metadata, or answer. Unexpected failures use the safe error reporter without PII.

## J. Timer authority and lifecycle behavior

The visible timer is isolated in its own stateful region. It derives remaining time from the persisted question start timestamp/duration, pauses local ticks during app backgrounding, and recomputes on resume. Timeout follows the existing steal/reveal contract and never awards a client-invented score.

## K. Exact behavior of all five helpers during gameplay

| ID | Real behavior |
|---|---|
| `two_chances` | Arms the engine's second-answer opportunity after question open; the UI does not fabricate multiple-choice behavior. |
| `call_friend` | Starts the definition/runtime-configured friend timer (current default 20 seconds). |
| `risk` | Arms before selection; the score engine applies the configured opponent deduction/wrong multiplier. |
| `bench` | Arms before selection, requires a real opponent roster, and records a selected real opponent player. |
| `pass` | Transfers the answering team to the opponent; award restrictions and correct/wrong trap multipliers remain engine-owned. |

All helpers render available/active/consumed states from persisted session data, use distinct Ahdash pictograms, and reject timing misuse or reuse.

## L. Confirmation that call_friend uses no Contacts/Phone permissions

Confirmed. It is an internal timed helper only. Android/iOS manifests and dependencies contain no Contacts/Phone permission or telephony integration added by Phase 4.

## M. Reveal authorization

The correct answer appears only when the active session has completed a successful `revealAnswer` transition. Duplicate reveal is rejected; direct/stale Reveal routes return to the truthful Question state; completed questions cannot be reopened.

## N. Score assignment and duplicate protection

Team A/Team B selection is local pending UI only. Confirmation calls the existing `award` operation; actions disable while submitting and haptic occurs only after success. The authoritative transition appends one score event and clears the active question synchronously, so rapid taps, rebuilds, resume, and retries cannot duplicate points.

## O. No-score behavior

No one calls `award(null)`. The score engine applies its real incorrect/steal/helper rules; the UI does not award zero to an arbitrary team.

## P. Completion/tie behavior

Completion is read from the session after Board/tiebreak rules finish. Result shows both actual scores and the actual winner. Equal scores render the real tie/draw state and never declare a winner or invent a tie-breaking rule.

## Q. Play Again behavior

Play Again calls `beginRematch`: it creates a real setup draft, preserves teams/players and timer, clears helper consumption for the next generated session, and returns through canonical category selection. The completed snapshot remains recoverable until the replacement session persists. New Game starts a clean draft.

## R. Tournament context preservation

Existing Party-to-tournament result confirmation/context remains intact. Result does not hardwire all tournament-origin sessions to Home. No Tournament visual screen was implemented.

## S. Thmanyah adjustments

Only the existing Thmanyah Sans 400/500/700/900 faces are used in active gameplay and deterministic Goldens. Compact layouts reduce secondary metadata/decorative scale before primary question, answer, score, winner, or CTA content.

## T. Responsive sizes tested

`800×360`, `844×390`, `915×412`, `1280×720`, and `1366×768`, all Light Mode. Core screens fit without normal-scale vertical scrolling.

## U. RTL/accessibility results

RTL category/team/score/turn meaning, mixed-language question wrapping, helper placement, Reveal order, result actions, and exit controls were checked. Effective interaction targets are at least 44–48px where required; semantics identify current turn, cell availability/usage, safe image media, helper state, revealed answer, score actions, and winner/tie without relying on color alone. Reduced Motion and safe system Back are respected.

## V. Security/answer-leakage tests

Tests prove the answer is absent before reveal, image failure/semantics leak neither answer nor URL, used/completed questions reject reopening, consumed helpers reject reuse, and duplicate scoring creates one score event. Widgets never directly mutate score values. No competitive answer key was added to Board presentation or media labels.

## W. Tests with exact counts

- Pre-change broad non-visual baseline: **178/178 passed**.
- Phase 4 focused domain/controller/resolver/renderer: **33/33 passed**.
- Phase 4 gameplay widget tests: **22/22 passed**.
- Combined Phase 4 focused suite: **55/55 passed**.
- All relevant Party non-visual tests, including Phase 3 setup: **70/70 passed**.
- Final broad non-visual suite: **205/205 passed** across 44 files.
- `flutter analyze --fatal-infos`: **passed; no issues**.
- `dart format`: **13 inspected files; formatted successfully**.

## X. Goldens with exact counts and whether baselines changed

Phase 4 Light Goldens: **25/25 passed** (5 screens × 5 sizes). These are deliberate new/updated Phase 4 baselines; the final update included the explicit Board used check, bounded Reveal score card, and bounded Result CTA, followed by a clean **25/25** run without regeneration. Phase 3 Goldens also passed **30/30 unchanged**.

## Y. Raw visual review count

**25/25 reviewed** after the final baseline update. All raw PNGs were opened in five full-resolution size-grouped contact sheets and checked against the live V9.2 Figma handoff nodes. See `docs/v9_2_phase4_visual_review.md`.

## Z. Files changed

Production Flutter:

- `mobile/lib/core/routing/app_router.dart`
- `mobile/lib/features/home/presentation/home_screen.dart`
- `mobile/lib/features/party/presentation/party_game_controller.dart`
- `mobile/lib/features/party/presentation/party_game_screens.dart`
- `mobile/lib/features/party/presentation/party_setup_flow.dart`
- `mobile/lib/features/party/presentation/party_support_screens.dart`
- `mobile/lib/features/party/presentation/party_v2_ui.dart`

Tests and visual evidence:

- `mobile/test/helpers/party_phase4_fixture.dart`
- `mobile/test/features/party/party_game_controller_test.dart`
- `mobile/test/features/party/party_gameplay_widget_test.dart`
- `mobile/test/features/party/party_setup_flow_test.dart`
- `mobile/test/visual/party_game_golden_test.dart` (legacy suite now excludes Phase 4 duplicates)
- `mobile/test/visual/v9_2_phase4_golden_test.dart`
- 25 PNGs under `docs/visual-validation/v9_2_phase4/`

Documentation:

- `docs/v9_2_figma_flutter_implementation_map.md`
- `docs/v9_2_party_flow.md`
- `docs/v9_2_phase4_gameplay_contract.md`
- `docs/v9_2_phase4_visual_review.md`
- `docs/v9_2_asset_map.md`
- `docs/v9_2_motion_haptics_audio.md`
- `docs/v9_2_release_report.md`

## AA. Backend/schema changes

None. No schema change, migration, applied-migration edit, remote write, Supabase push, RPC replacement, or deployment was performed.

## AB. Known limitations

- Party remains the existing host-judged verbal-answer model; Phase 4 intentionally adds no player text-entry system.
- Remote question images still require their existing network/cache path in production; media failure remains a safe retry state rather than substituting unrelated content.
- `two_chances` remains an engine opportunity/state indicator for supported contexts; Phase 4 does not invent a new answer-input mechanic.
- Phase 5 Tournament visuals, Profile, Settings, Premium, Football Preferences, and Social/Online migration remain out of scope.

## AC. Confirmation

- No Phase 5.
- No Emulator.
- No APK.
- No Supabase push.
- No migration.
- No Rive.
- No random SFX.
- No fake data.
- No answer leakage.
- No Contacts permission.
- No Phone permission.
- No Online reactivation.
