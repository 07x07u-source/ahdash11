# AHDASH 11 V9.2 — Figma to Flutter implementation map

## Phase 6 override — screens 38–43 (2026-09-05)

The following local implementations supersede the earlier audit-only status for these six entries. Earlier Phase 0–5 history below is retained.

| Screen | Wide / compact nodes | Route | Real state |
|---|---|---|---|
| 38 Profile | 81:3767 / 81:3838 | /profile | ProfileRepository / playerProfileProvider; no demo fallback |
| 39 Notifications | 81:3897 / 81:3979 | /notifications | NotificationsRepository; target_user_id, safe navigation |
| 40 Settings | 81:4042 / 81:4077 | /settings | PreferenceStorage, notification preferences, existing account actions |
| 41 Report | 81:4149 / 81:4194 | /report-problem | ProblemReportController / existing reporting RPC |
| 42 Football | 81:4235 / 81:4310 | /football-preferences | Existing catalog/preferences RPCs, rights-safe logos |
| 43 Premium | 81:4393 / 81:4433 | /premium, /store | RevenueCatPurchaseService / PremiumController; /wallet redirect |

See the Phase 6 contracts and visual review. No Phase 7 work, no remote migration, and Phase 5 production gate remains active.

Checkpoint scope: Phase 0 audit, Phase 1 foundation, Phase 2 screens 01–05, Phase 3 screens 06–11, Phase 4 screens 12–16, and Phase 5 screens 19–27. Figma file `1tbYuMwiC8b9vCj12TzbAA`; visual page `47:2` (`V9.2 — Complete Product Review`); specification page `81:2` (`V9.2 — Flutter Handoff`). The review contains 41 standalone screens at wide and compact sizes (82 frames). Functional entries 24 and 25 are states of entry 23, so mapping coverage remains 43/43 without duplicate routes. Phase 5 production draw/result writes require the new v2 RPC deployment and Supabase security verification; no deployment was performed.

Status vocabulary: **Existing** means a real Flutter implementation is present; **Embedded state** means it is intentionally hosted by another route; **Compatibility redirect** means the old implementation is not reachable from the active router. Actions are for later phases and do not mean the screen was rebuilt in this checkpoint.

| # | Figma frame | Wide node | Compact node | Existing Flutter route | Existing screen/widget | Provider/controller | Repository/service and backend dependency | Real data source | Status | Later action |
|---:|---|---|---|---|---|---|---|---|---|---|
| 01 | Launch | `81:131` | `81:147` | `/launch` | `LaunchScreen` | `appPreferencesProvider`, auth bootstrap | `AppServices`, local preferences; no screen RPC | app bootstrap, bundled branding | Implemented Phase 2 | COMPLETE |
| 02 | Onboarding | `81:168` | `81:215` | `/onboarding` | `OnboardingScreen` | `appPreferencesProvider` | `AppPreferencesController`; no backend authority | local onboarding flag | Implemented Phase 2 | COMPLETE |
| 03 | Sign In | `81:268` | `81:298` | `/auth` | `AuthScreen` sign-in state | `authControllerProvider` | `AuthRepository`, `SupabaseAuthRepository`, `NativeGoogleAuthClient` | Supabase Auth and configured native Google sign-in | Implemented Phase 2 | COMPLETE |
| 04 | Create Account | `81:327` | `81:362` | `/auth` | `AuthScreen` registration state | `authControllerProvider` | same auth stack as #03 | Supabase Auth validation/session | Implemented Phase 2 embedded state | COMPLETE |
| 05 | Home | `81:394` | `81:433` | `/home` | `HomeScreen` | `appContentProvider`, profile/party/tournament state | app-content repository, Drift and feature controllers; `get_published_app_content` | published Supabase content plus real resumable local/domain state | Implemented Phase 2 | COMPLETE |
| 06 | Category Selection | `81:466` | `81:537` | `/party/categories` | `PartyCategorySelectionScreen` | `partyGameControllerProvider`, `partyCatalogProvider`, entitlement provider | Supabase/Drift catalog; `get_party_question_pack`, `get_party_category_health` | published/content-ready categories, access rights, cache, existing favorites | Implemented Phase 3 | COMPLETE |
| 07 | Category Detail | `81:604` | `81:641` | `/party/categories` (detail sheet) | `PartyCategoryDetailPanel` | selected real catalog item | shared `AhdashImage` and category metadata | real cover/focal point, description, season, formats, subcategories and readiness | Implemented Phase 3 embedded state | COMPLETE |
| 08 | Team Setup | `81:675` | `81:743` | `/party/teams` | `PartyTeamSetupScreen` | `partyGameControllerProvider` | `PartyGameController`, versioned local setup draft | current draft team names/colors | Implemented Phase 3 | COMPLETE |
| 09 | Team Splitter | `81:805` | `81:847` | `/party/splitter` | `PartyTeamSplitterScreen`, shared `PartyTeamSplitterSheet` | `partyGameControllerProvider` | injectable/testable local split operation; no RPC | actual entered player names and manually adjusted assignments | Implemented Phase 3 optional route | COMPLETE |
| 10 | Helpers | `81:888` | `81:956` | `/party/helpers` | `PartyHelperSelectionScreen` | `partyHelperCatalogProvider`, `partyGameControllerProvider` | party helper catalog; `party_help_tools` | five domain IDs, real availability/rule config, local selected state | Implemented Phase 3 | COMPLETE |
| 11 | Ready | `81:1023` | `81:1105` | `/party/ready` | `PartyReadyScreen` | Party controller/catalog/helpers/runtime settings | canonical validation plus existing safe session creation/persistence | real draft summary and playable content only | Implemented Phase 3 | COMPLETE |
| 12 | Game Board | `81:1173` | `81:1271` | `/party/board` | `PartyBoardScreen` | `partyGameControllerProvider` | `PartyGameEngine`, Drift-backed session persistence | real 6×6 snapshot, point values, usage, turn, progress and scores | Implemented Phase 4 | COMPLETE |
| 13 | Text Question | `81:1362` | `81:1387` | `/party/question` | `PartyQuestionScreen` text state | `partyGameControllerProvider`, isolated `_QuestionTimer` | party engine; question pack originates at `get_party_question_pack` | current real question and safe secondary metadata; answer hidden | Implemented Phase 4 embedded state | COMPLETE |
| 14 | Image Question | `81:1413` | `81:1462` | `/party/question` | `PartyQuestionScreen` image state, `_PartyQuestionImage` | `partyGameControllerProvider` | party engine plus cached network image/error reporter | real media URL, aspect/focal metadata, retry and safe fallback | Implemented Phase 4 embedded state | COMPLETE |
| 15 | Answer Reveal | `81:1515` | `81:1559` | `/party/reveal` | `PartyRevealScreen` | `partyGameControllerProvider` | authoritative party score/state engine | revealed answer/explanation and host score choice | Implemented Phase 4 | COMPLETE |
| 16 | Final Result | `81:1611` | `81:1642` | `/party/result` | `PartyResultScreen` | `partyGameControllerProvider`, tournament context | party engine/session persistence | authoritatively completed winner/tie and actual scores | Implemented Phase 4 | COMPLETE |
| 17 | How to Play | `81:1686` | `81:1757` | `/how-to-play` | `HowToPlayScreen` | app content / static domain rules | published content where available; no score authority | supported Party rules and bundled pictograms | Existing | REFINE |
| 18 | Saved Party Games | `81:1829` | `81:1922` | `/party/games` | `PartyGamesScreen` | `partyGameControllerProvider` | `AppDatabase`/party persistence | real locally saved resumable sessions | Existing | REBUILD UI |
| 19 | Tournament Hub | `81:2009` | `81:2065` | `/tournaments` | `TournamentHubScreen` | Tournament controller/flow resolver | `TournamentGateway`, existing Drift cache | real current/history, counts, next match, cached/error states | Implemented Phase 5 | Owner review |
| 20 | Create Tournament | `81:2121` | `81:2156` | `/tournaments/create` | `TournamentCreateScreen` | Tournament controller | existing `create_tournament`; separate Drift wizard/candidate | real domain rules, two steps, stable retry UUID | Implemented Phase 5 | Owner review |
| 21 | Tournament Teams | `81:2189` | `81:2258` | `/tournaments/teams` | `TournamentTeamsScreen` | Tournament controller/registration providers | existing registration repository; server hydration | preserved approved team/player IDs; labelled staged manual entries | Implemented Phase 5 | Owner review |
| 22 | Tournament Draw | `81:2313` | `81:2360` | `/tournaments/draw` | `TournamentDrawScreen` | Tournament controller/flow resolver | existing engine; ONLY `save_tournament_bracket_v2` | durable candidate from actual eligible teams | Implemented Phase 5, release-gated | Deploy/retest safe RPC after approval |
| 23 | Tournament Bracket | `81:2408` | `81:2466` | `/tournaments/bracket` | `TournamentBracketScreen` | Tournament controller/flow resolver | existing engine; versioned draw/result gateway | real sorted rounds, positions, IDs, next slots, scores and winners | Implemented Phase 5 | Owner review |
| 24 | Tournament Semifinal | state of `81:2408` | state of `81:2466` | `/tournaments/bracket` | selected semifinal round | same as #23 | same as #23 | actual semifinal entities | Implemented Phase 5 embedded state | No duplicate route |
| 25 | Tournament Final | state of `81:2408` | state of `81:2466` | `/tournaments/bracket` | selected final round | same as #23 | same as #23 | actual final entity | Implemented Phase 5 embedded state | No duplicate route |
| 26 | Tournament Match | `81:2525` | `81:2571` | `/tournaments/match/:matchId` | `TournamentMatchScreen` | Tournament controller and shared Party controller/resolvers | existing Party engines/session storage; ONLY `confirm_tournament_match_result_v2` | bound real Party session or explicit organizer-entered external result | Implemented Phase 5, release-gated | Deploy/retest safe RPC after approval |
| 27 | Tournament Champion | `81:2617` | `81:2643` | `/tournaments/champion` | `TournamentChampionScreen` | Tournament controller/flow resolver | existing engine and confirmed server result | real completed final, confirmed winner, matching champion team | Implemented Phase 5 | Owner review |
| 28 | Match Setup | `81:2669` | `81:2742` | `/play/setup/:gameType` | `GameSetupScreen` | game settings/session state | `game_settings`, shared game domain | supported game type/format inputs | Existing | REFINE |
| 29 | Solo Setup | `81:2791` | `81:2863` | `/solo` | `SoloSetupScreen` | `soloMatchControllerProvider`, categories | question repository; `get_solo_question_pack`, `record_solo_answer` | real published solo pool and selected category | Existing | REFINE |
| 30 | Online Lobby | `81:2919` | `81:2970` | `/online` → `/home` | legacy `OnlineLobbyScreen` is unreachable | legacy local widget state | legacy Edge/RPC integrations | no active product data contract | Compatibility redirect | REDIRECT, HIDE LEGACY UI |
| 31 | Online Match | `81:3011` | `81:3075` | `/online/match/:matchId` → `/home` | legacy `OnlineMatchScreen` is unreachable | legacy match state/gateway | legacy `matches`, `match_players`, `reveal_match_question`, `advance_match` | disabled product surface | Compatibility redirect | REDIRECT, HIDE LEGACY UI |
| 32 | Private Room | `81:3127` | `81:3196` | `/room/:roomId` → `/home` | legacy `RoomLobbyScreen` is unreachable | legacy room widget state | legacy `rooms`, `room_members`, `set_room_ready`, `start_room_match` | disabled product surface | Compatibility redirect | REDIRECT, HIDE LEGACY UI |
| 33 | Team Challenge | `81:3264` | `81:3321` | `/challenges/:challengeId` | `TeamChallengeScreen` | `socialRepositoryProvider` | social repository; challenge start/question/answer/result RPCs | actual challenge attempt and server-scored answers | Existing | REFINE |
| 34 | Ranking | `81:3369` | `81:3449` | `/ranking` | `RankingScreen` | `leaderboardProvider` | Supabase `leaderboard` view | leaderboard rows; offline fallback currently unsafe | Existing with risk | REBUILD UI |
| 35 | Friends | `81:3518` | `81:3561` | `/friends` | `FriendsScreen` | screen async state, auth/config | `get_friend_dashboard`, `search_players`, request/remove RPCs | actual friends and requests | Existing | REBUILD UI |
| 36 | Blocked Players | `81:3602` | `81:3643` | `/blocked-players` | `BlockedPlayersScreen` | `blockedPlayersProvider`, `socialRepositoryProvider` | `get_blocked_players`, `unblock_player` | actual blocked users | Existing | REFINE |
| 37 | Team Detail | `81:3679` | `81:3716` | `/teams/:teamId` | `SocialTeamScreen` | `socialTeamDetailProvider`, `socialRepositoryProvider` | `get_social_team_detail` and team membership RPCs | actual team/members/invites | Existing | REBUILD UI |
| 38 | Profile | `81:3767` | `81:3838` | `/profile` | `ProfileScreen` | `playerProfileProvider` | `get_my_profile_summary`, `get_my_tournament_stats` | authenticated profile and real available stats | Existing with fallback risk | REBUILD UI |
| 39 | Notifications | `81:3897` | `81:3979` | `/notifications` | `NotificationsScreen` | screen async state/app services | Supabase `notifications`; FCM service for device token | actual notification rows/read state | Existing | REBUILD UI |
| 40 | Settings | `81:4042` | `81:4077` | `/settings` | `SettingsScreen` | `appPreferencesProvider`, notification/profile providers | SharedPreferences, notification preferences, app services | real immediate-save settings only | Existing; dark selector hidden | REFINE |
| 41 | Report a Problem | `81:4149` | `81:4194` | `/report-problem` | `ReportProblemScreen` | `questionReportRepositoryProvider`, error reporter | `QuestionReportRepository`; `question_reports` | validated user report and safe diagnostics | Existing | REFINE |
| 42 | Football Preferences | `81:4235` | `81:4310` | `/football-preferences` | `FootballPreferencesScreen` | `footballLeaguesProvider`, `footballRepositoryProvider` | list/search/get/set football preference RPCs | existing remote leagues/clubs and saved preferences | Existing | REBUILD UI |
| 43 | Premium | `81:4393` | `81:4433` | `/premium` | `PremiumScreen` | `appServicesProvider` purchase service | RevenueCat offerings/purchase/restore/entitlement | actual localized packages and entitlement | Existing | REBUILD UI |

## Additional routed production surfaces

The router also contains tournament join/registration, social hub/join-team, category discovery, solo match/result, play hub, and store routes. They remain functional dependencies or adjacent product surfaces but are not separate entries in the approved 43-screen inventory. `/wallet` redirects to `/store`; active Store/Coin affordances conflict with the V9.2 scope and are documented as a risk, not changed in Phase 1.

## Phase 4 flow decision

- The approved canonical Party setup is now Category → Team → optional Splitter → Helpers → Ready → Board.
- `PartySetupFlowResolver` is the single setup and gameplay navigation authority. It resolves saved drafts, old/deep links, setup validity, Board, Question, Reveal, and completed Result from the saved session state.
- Category Detail remains an intentional sheet within selection. Team Splitter now also has the canonical `/party/splitter` route while retaining its reusable sheet component; no second state machine was created.
- Text and Image Question intentionally share the format-aware `/party/question` route; no duplicate state machine was created.
- Tournament Semifinal/Final remain later-phase embedded bracket states. Existing tournament result handoff is preserved without visual Phase 5 work.
- Online Lobby, Online Match, and Private Room remain compatibility redirects; Phase 4 did not reactivate them.
