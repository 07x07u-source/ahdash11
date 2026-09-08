# AHDASH 11 - V8 Implementation Evidence

Purpose: freeze what the current product actually supports before V8 presentation code changes. This is a local, read-only audit. No backend migration, remote push or new dependency is authorized by this document.

## 1. Authentication evidence

| Capability | Evidence | V8 implementation boundary |
|---|---|---|
| Existing-account email sign-in | `AuthRepository.signIn(email, password)` and Supabase `signInWithPassword` | Keep email + password only. |
| Create account | `AuthRepository.signUp(email, password, username)`; anonymous accounts are upgraded through `updateUser` | Dedicated visual state with username + email + password only. |
| Guest | `continueAsGuest`, Supabase anonymous sign-in and development repository | Keep visible as a secondary entry. |
| Native Google | `GoogleSignInAuthClient` and Supabase `signInWithIdToken`; UI gate uses `GOOGLE_AUTH_ENABLED` and native mobile | Show only when configuration and platform gate are true. |
| Apple | Supabase OAuth redirect; UI gate uses `APPLE_AUTH_ENABLED` and iOS | Preserve iOS/config gate; no readiness claim without remote verification. |
| Loading | `AsyncLoading` plus social-provider in-progress set | Stable layout, disabled controls and local progress indicator. |
| Validation errors | Form validators for username length, email shape and password length | Error remains next to form; compact layout may not ellipsize critical text. |
| Safe auth errors | `_friendlyError` maps product-safe copy; controller reports sanitized operational context | Never display raw provider/Supabase details. |
| Forgot password | No repository/controller/route/test found | Not implemented in V8 checkpoint. |
| Email verification | No explicit app state; local Supabase confirmation disabled | Not implemented until remote policy is confirmed. |

## 2. Public route inventory

### Primary routes retained

- `/launch`
- `/onboarding`
- `/auth`
- `/home`
- `/party/categories`
- `/party/teams`
- `/party/helpers`
- `/party/ready`
- `/party/board`
- `/party/question`
- `/party/reveal`
- `/party/result`
- `/party/games`
- `/how-to-play`
- `/tournaments`
- `/tournaments/create`
- `/tournaments/teams`
- `/tournaments/draw`
- `/tournaments/bracket`
- `/tournaments/match/:matchId`
- `/tournaments/champion`
- `/profile`
- `/ranking`
- `/notifications`
- `/settings`
- `/store`
- `/football-preferences`

### Functional supporting/additional routes retained until owner decision

- `/play`
- `/play/setup/:gameType`
- `/categories`
- `/solo`
- `/solo/match`
- `/solo/result`
- `/online`
- `/online/match/:matchId`
- `/room/:roomId`
- `/friends`
- `/teams`
- `/teams/:teamId`
- `/blocked-players`
- `/challenges/:challengeId`
- `/report-problem`

### Alias/legacy behavior

- `/wallet` redirects to `/store` and does not render a public wallet screen.
- No duplicate GoRoute path was found in `app_router.dart`.
- Existing Party back paths are coherent: categories -> teams -> helpers -> ready -> board -> question -> reveal -> board/result.
- Existing Tournament progression is coherent: create -> teams -> draw -> bracket -> match -> bracket/champion.
- Legacy/additional modes remain linked from `/play` and setup screens. Moving their prominence is allowed; deleting the routes is not.

## 3. Data support by V8 area

| Area | Verified current data/state | Must not be invented |
|---|---|---|
| Home | Active Party session/resume route, active tournament state, admin content hero/category data, profile state | Live users, fake featured metrics, fake tournament progress. |
| Party categories | Category ID/name/description/image/accent/season/taxonomy/favourite eligibility and selected IDs | Unique art when admin media is absent; fake popularity. |
| Team setup | Two names, colours and optional player lists in Party session state | Captains, online status, member roles. |
| Helpers | Five defined helper IDs, per-team selected sets and 3-per-team rule | New helper types or extra counts. |
| Board/question/reveal/result | 6 categories x 6 questions, points, scores, turn, timers, helper use, answer/explanation/report state | Derived “insights” not present in state. |
| Tournament | Name, organizer, capacity, players/team, visibility, seeding, categories, timer, helper/tiebreaker flags, teams, matches, round/position/status/scores/winner/champion | Captain, audience count, sponsor, venue, stream, fake progress. |
| Profile | Public name, avatar/jersey, level/XP/coins/rating, wins/losses/draws/matches/accuracy/streak/rank, football choices, social team, achievements, tournament counts | Activity feed, online-now, unsupported titles. |
| Premium | RevenueCat monthly/yearly packages, real localized price, real status/expiry/management URL, restore/purchase actions | Default price, fake discount, fake saving percentage, unverified benefits. |
| Notifications | Real notification repository data and contextual friend/room actions | Promotional notification content or fake invite count. |
| Football preferences | Real league/club entities and optional profile choice | Club logo when rights/data are missing. |
| Coins/store | Profile coins, reward fields, wallet/store domain and RPC paths exist, but public wallet route is redirected | Claim that Wallet is removed from backend or that Coins are deprecated. |

## 4. Tournament wizard evidence

The requested six-step composition can be expressed without changing the Tournament model:

1. Name -> `Tournament.name`.
2. Teams -> existing separate team add/edit flow.
3. Rules -> capacity, players/team, visibility, timer, helpers and tiebreaker.
4. Categories -> `categoryIds`.
5. Draw -> `TournamentSeeding.draw` and current engine generation.
6. Review -> derived summary of the same draft.

`captain` is excluded. `member count` is shown only as `players.length` when players are populated. Draft persistence semantics remain unchanged until OD-13 is resolved.

## 5. V7 token audit versus V8 target

| Token family | Current | V8 finding |
|---|---|---|
| Spacing | 4, 8, 12, 16, 20, 24, 32, 40, 48 | Already follows the requested 4px rhythm. Keep and rename/document only where needed; no broad refactor. |
| Radius | 5, 8, 12, 16, pill | V8 target is 8, 12, 16, pill. Current 5 is a legacy small radius; migrate shared V8 controls to 8 without bulk-changing unrelated legacy UI. |
| Motion | 120, 180, 200, 300, 520 ms plus operational timers | Presentation durations are acceptable. Keep motion event-bound; operational timers are not visual animation tokens. |
| Typography | Thmanyah Sans, Serif Display and Serif Text; body 14-15, question 21, display 34 | V8 primary game typography needs adaptive role sizes, not global scaling. Existing font families remain. |
| V7 frame gutter | 16 / 28 / 48 based on width | Replace in V8 frame with constraint-derived 20 / 24 / 32 / 40. |
| Top bar | 48 | Keep 48 compact; 52 wide. Current tiny child content must use full 44-48 hit targets. |
| Icon target | V7 shared icon button 44 with glyph 21 | Meets minimum. Prefer 48 for new V8 surfaces; glyph remains 20-24. |
| Primary action | V7 46 compact / 54 wide | Normalize to 48 compact / 52 wide; no giant or web-thin CTAs. |
| Material 3 | ThemeData/ColorScheme/component themes in place | Preserve as technical base; V8 shared components must prevent generic Material leakage. |

## 6. Media and cache evidence

- Home, Auth and Profile can load admin content URLs and have local fallback assets.
- Profile uses `CachedNetworkImage` with constraint-derived decode dimensions, a stable local placeholder and error fallback.
- Party question media supports local assets and cached remote images.
- Category tiles support `imageUrl`, but several fixtures/fallbacks reuse one generic cover.
- V8 can change crop, focal alignment and scrim without adding media. New category art is blocked by OD-07.

## 7. Release/debug boundary

- The debug `DEV` marker appears only when all are true: `kDebugMode`, development environment and missing Supabase configuration.
- V8 golden fixtures must use production-style configuration so debug-only labels are absent.
- No V8 visual change authorizes an APK build, emulator run, installation, remote Supabase push or applied migration edit.

## 8. Approved checkpoint implementation scope

Only presentation/layout work for these states is evidence-ready:

1. Sign In
2. Create Account
3. Home
4. Party Category Selection
5. Party Board
6. Party Question
7. Profile
8. Tournament Match

Permitted supporting edits: shared V8 frame/measurement tokens, existing semantic icons, golden fixtures and presentation-only helpers. State, repository, RPC, table and route behavior must remain unchanged.

## 9. Final V8 implementation evidence

- The checkpoint scope was extended through the remaining Party, Tournament, settings, notifications, premium and football-preference states without changing routes, repositories, tables or game rules.
- Supporting screens were audited as a complete catalog. Onboarding was consolidated into one concise three-step state; Friends and Blocked Players received explicit empty/privacy states.
- Responsive behavior is verified at 800×360, 844×390, 915×412, 1280×720 and 1366×768 in light and dark themes across the dedicated visual suites.
- Final passing visual checks: Party 130, Tournament 90, image-first 110, V7/V8 checkpoint 188, and supporting-page catalog 34.
- Authentication/Home widget checks pass after copy and compact-layout updates.
- The primary visual scorecard is recorded in `docs/v8-primary-scorecard.md`; all 24 primary states meet the 4/5 acceptance floor in every category.
- The complete screen catalog is generated at `output/pdf/ahdash11-all-screens-v8.pdf`. It contains current light/dark pairs and was rendered page-by-page with Poppler for visual inspection.
- No APK was built, no emulator was launched, and no Supabase migration or remote push was performed during this round.
