# V10 Figma ↔ Flutter parity matrix

Source of truth: the locked frames on `V10 - Portrait Product`, with foundation tokens from `V10 — Portrait Foundation` and duplicate review coverage on `V10 — Portrait Complete Review`. Archive pages are excluded.

Status legend: **PASS** = direct comparison >=95%; **B/C** = approved, evidence-backed non-fixable/product-truth or reference-specific exception; **deferred** = intentionally outside Phase H implementation. Phase H.3 closed with 15/24 fresh-reference passes, 9 approved B/C exceptions, Category A=0, and no unexplained sub-95 reference.

| # | Figma frame | Node | Flutter route | Production widget / state | Harness | Status |
|---:|---|---|---|---|---|---|
| 01 | Launch | `126:22` | `/launch` | `LaunchScreen` | V10 Phase A | verified — 97.58% primary, 98.40% compact |
| 02 | Onboarding 1 | `126:40` | `/onboarding` | `OnboardingScreen`, page 0 | V10 Phase A | verified — 96.90% |
| 03 | Onboarding 2 | `126:71` | `/onboarding` | `OnboardingScreen`, page 1 | V10 Phase A deterministic state | verified — 97.06% |
| 04 | Onboarding 3 | `126:102` | `/onboarding` | `OnboardingScreen`, page 2 | V10 Phase A deterministic state | verified — 97.24% |
| 05 | Onboarding 4 | `126:133` | `/onboarding` | `OnboardingScreen`, page 3 | V10 Phase A deterministic state | verified — 97.21% |
| 06 | Sign In | `126:164` | `/auth` | `AuthScreen(signIn)` | Auth physical-device repair | B — Android UX override; warm-paper header/card removes dead dark region; 67.65 primary, 69.90 compact, 82.19 keyboard |
| 07 | Create Account | `126:289` | `/auth` | `AuthScreen(createAccount)` | Auth physical-device repair | B — complete accessible three-field form/provider truth; 69.09 primary, 72.17 compact, 90.95 keyboard |
| 08 | Home | `126:329` | `/home` | `HomeScreen` | V10 Phase A | verified — 95.37% primary, 94.68% compact; approved mode hierarchy preserved |
| 09 | Category Selection | `126:553` | `/party/categories` | `PartyCategorySelectionScreen` | V10 Phase B / H.3 | PASS primary 95.21%; C compact 89.76% and keyboard 85.18% due internally contradictory reference states |
| 10 | Category Detail | `126:622` | `/party/categories` | category-detail state in `PartyCategorySelectionScreen` | V10 Phase B / H.3 | B/C — 92.75% primary, 88.59% compact; real data/back navigation preserved |
| 11 | Team Setup | `126:661` | `/party/teams` | `PartyTeamSetupScreen` | V10 Phase B / H.3 | PASS — 96.83% primary, 96.53% compact |
| 12 | Team Splitter | `126:753` | `/party/splitter` | `PartyTeamSplitterScreen` | V10 Phase B | H.2 resolved — 96.78% primary, 96.00% compact, 95.58% keyboard; Category A closed |
| 13 | Helpers | `126:824` | `/party/helpers` | `PartyHelperSelectionScreen` | V10 Phase B / H.3 | PASS — 95.06% primary, 95.61% compact; corrected five-helper terminology |
| 14 | Ready | `126:889` | `/party/ready` | `PartyReadyScreen` | V10 Phase B / H.3 | PASS — 95.10% primary, 96.24% compact |
| 15 | Board | `126:952` | `/party/board` | `PartyBoardScreen` | V10 Phase B / H.3 | PASS — 96.78% primary, 95.87% compact |
| 16 | Text Question | `126:1191` | `/party/question` | `PartyQuestionScreen`, text question | V10 Phase B / H.3 | PASS — 95.83% primary, 95.35% compact |
| 17 | Image Question | `126:1236` | `/party/question` | `PartyQuestionScreen`, image question | V10 Phase B / H.3 | PASS — 96.44% primary, 95.89% compact |
| 18 | Reveal | `126:1282` | `/party/reveal` | `PartyRevealScreen` | V10 Phase B | verified; parity recovered — 97.58% primary, 97.15% compact |
| 19 | Result | `126:1321` | `/party/result` | `PartyResultScreen` | V10 Phase B | verified; parity recovered — 97.07% primary, 96.68% compact |
| 20 | How To | `126:1354` | `/how-to-play` | `HowToPlayScreen` | V10 Phase D | verified — 93.48%; real Party contract only |
| 21 | Saved | `126:1398` | `/party/games` | `PartyGamesScreen` | V10 Phase D / H.3 persisted session | C — 94.17%; canonical illustrative records cannot replace real persisted data |
| 22 | Tournament Hub | `126:1453` | `/tournaments` | `TournamentHubScreen` | V10 Phase C | verified; parity recovered — 97.38% primary, 95.36% compact |
| 23 | Create Tournament | `126:1511` | `/tournaments/create` | `TournamentCreateScreen` | V10 Phase C | verified; parity recovered — 98.32% primary, 97.88% keyboard |
| 24 | Tournament Teams | `126:1554` | `/tournaments/teams` | `TournamentTeamsScreen` | V10 Phase C | verified; parity recovered — 97.83% primary |
| 25 | Draw | `126:1632` | `/tournaments/draw` | `TournamentDrawScreen` | V10 Phase C | verified; parity recovered — 97.43% primary |
| 26 | Bracket | `126:1687` | `/tournaments/bracket` | `TournamentBracketScreen` | V10 Phase C | verified; parity recovered — 97.60% primary, 95.35% compact |
| 27 | Match | `126:1739` | `/tournaments/match/:matchId` | `TournamentMatchScreen` | V10 Phase C | verified; parity recovered — 97.91% primary |
| 28 | Champion | `126:1778` | `/tournaments/champion` | `TournamentChampionScreen` | V10 Phase C | verified; parity recovered — 97.41% primary |
| 29 | Match Setup | `126:1828` | `/play/setup/:gameType` | `PlayScreen` supported-mode selector | V10 Phase D | verified — 94.93%; Online disabled |
| 30 | Solo Setup | `126:1892` | `/solo` | `SoloSetupScreen` | V10 Phase D / H.3 | PASS — 96.81%; LIMITED truth preserved |
| 31 | Online | `126:1949` | `/online` → `/home` | compatibility tombstone | none | deferred |
| 32 | Online Match | `126:1985` | `/online/match/:matchId` → `/home` | compatibility tombstone | none | deferred |
| 33 | Room | `126:2027` | `/room/:roomId` → `/home` | compatibility tombstone | none | deferred |
| 34 | Team Challenge | `126:2073` | `/challenges/:challengeId` | `TeamChallengeScreen` | V10 Phase D / H.3 | PASS — 96.80%; no fake opponent/presence/rating |
| 35 | Ranking | `126:2127` | `/ranking` | `RankingScreen` | V10 Phase D | verified — 97.38% primary, 97.27% compact |
| 36 | Friends | `126:2205` | `/friends` | `FriendsScreen` | V10 Phase D / H.3 deterministic fixture | C — 92.65% primary, 93.03% keyboard; server truth/no avatar or presence fabrication |
| 37 | Blocked | `126:2264` | `/blocked-players` | `BlockedPlayersScreen` | V10 Phase D | verified — 96.59% primary |
| 38 | Team Detail | `126:2346` | `/teams/:teamId` | `SocialTeamScreen` | V10 Phase D deterministic fixture | verified — 91.61%; only real domain fields shown |
| 39 | Profile | `126:2440` | `/profile` | `ProfileScreen` | V10 Phase E | verified; parity recovered — 95.76% primary, 95.23% compact |
| 40 | Notifications | `126:2503` | `/notifications` | `NotificationsScreen` | V10 Phase E | verified; parity recovered — 95.24% primary |
| 41 | Settings | `126:2554` | `/settings` | `SettingsScreen` | V10 Phase E | verified; parity recovered — 97.51% primary |
| 42 | Report | `126:2625` | `/report-problem` | `ReportProblemScreen` | V10 Phase E | verified; parity recovered — 96.26% primary, 96.40% keyboard |
| 43 | Football Preferences | `126:2702` | `/football-preferences` | `FootballPreferencesScreen` | V10 Phase E | verified; parity recovered — 95.15% primary, 95.59% keyboard |
| 44 | Premium | `126:2761` | `/premium` (`/store` alias) | `PremiumScreen` | V10 Phase E | verified; parity recovered — 95.84% primary, 95.07% compact |

## Responsive and keyboard coverage

- The Product page contains 20 compact 360×800 frames (`130:2`–`130:1094`) and nine keyboard frames (`126:204`, `126:709`, `126:2667`, `130:1158`, `130:1204`, `130:1278`, `130:1357`, `130:1399`, `130:1458`).
- Party Core frames 12–16 are verified at both 390×844 and 360×800 against the canonical local V10 exports. Tournament Hub and Bracket are also verified at 390×844 and 360×800; Create Tournament is verified at 390×844 in normal and keyboard states. Account/Premium frames 38–43 are verified at every locally supplied primary, compact, and keyboard viewport.
- The primary comparison set currently has direct captures for Launch, Sign In, Home, Category Selection, Board, Text Question, Image Question, Reveal, Result, Tournament Hub, Bracket, Champion, Ranking, Profile, Settings, and Premium.

## Current foundation contract

- Canvas: Paper 0 `#FBF7EF`; surfaces: Paper 1 `#F4EBDD`, Paper 2 `#EBDFC9`, Paper 3 `#DDCEB5`.
- Text: Ink `#191714`, Ink Soft `#35312B`, Muted `#756E63`; border Hairline `#D3C6B2`; accents Green `#B6FF3B`, Gold `#FFC857`.
- Primary 390×844 uses 24 px content gutters, 47 px top safe area, and 34 px bottom safe area. Compact 360×800 uses 20 px gutters.
- Touch targets: 44 minimum, 48 standard, 52 input, 56 primary CTA. Radii: 8, 12, 16, with larger screen-specific hero radii only where the locked frame specifies them.
