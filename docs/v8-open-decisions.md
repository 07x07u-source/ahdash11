# AHDASH 11 - V8 Open Decisions

This file contains only items that failed at least one part of the V8 Evidence Gate. None of these items is approved for implementation by this audit.

## OD-01 - First-launch onboarding versus How to Play

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** Four onboarding pages teach category selection, teams, question choice and victory. `/how-to-play` teaches the same four concepts.
- **Decision required:** Keep a shortened first-launch flow, rely on How to Play, or retain both for distinct contexts.
- **Safe current action:** Do not delete either route. Design the reusable four-step content model so one decision can be applied without duplicating layouts.

## OD-02 - Visibility of legacy/additional game modes

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** `/play` exposes six equal modes; Party is now the primary product. `/solo`, `/online` and their setup/match/result routes are functional and tested.
- **Decision required:** Move them under `أوضاع إضافية`, hide selected modes behind existing feature policy, or keep them visible with reduced hierarchy.
- **Safe current action:** Do not delete routes or controllers. V8 Home and Party can be rebuilt without promoting these modes.

## OD-03 - Public Coins/Wallet terminology

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** `/wallet` redirects to `/store`, while wallet/store presentation and domain code still exist and real `coins` data is used by profile, rewards and store RPC flows.
- **Decision required:** Whether Coins remain a public game currency, become store-only terminology, or are hidden while backend compatibility remains.
- **Safe current action:** Remove “wallet” only from the Premium catalog/title context; do not delete wallet tables, ledger logic, rewards or compatibility code.

## OD-04 - Forgot Password

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** No repository, controller, route or test for password recovery was found.
- **Decision required:** Approve a complete Supabase password-recovery product flow, including redirect/deep-link handling and success/error states.
- **Safe current action:** Do not show a non-functional `نسيت كلمة المرور؟` action in V8 Auth.

## OD-05 - Email confirmation state

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** Current sign-up maps the returned user directly; there is no explicit `email sent` or `verify email` state. Local Supabase config has confirmations disabled, but remote project policy was not inspected here.
- **Decision required:** Confirm the real production Supabase Auth email-confirmation policy and the expected post-sign-up navigation.
- **Safe current action:** Keep V8 Create Account compatible with immediate sign-up and do not claim an email was sent.

## OD-06 - Apple authentication readiness

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** UI gating and Supabase OAuth redirect code exist and the button is iOS-only, but remote provider credentials and redirect registration are outside this local audit.
- **Decision required:** Confirm production Apple provider configuration before adding Apple-specific visual goldens or claims.
- **Safe current action:** Preserve the existing platform/configuration gate.

## OD-07 - Category cover uniqueness and media rights

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** Several unrelated categories reuse `eagle-eye-cover.png` in V7 fixtures/fallbacks. Category models support `imageUrl`, but real published asset coverage and rights are not proven for every category.
- **Decision required:** Supply or approve an admin-controlled, rights-cleared cover set and focal-point policy.
- **Safe current action:** Improve tile layout and fallbacks without fabricating club/player artwork.

## OD-08 - Tournament team captain and member status

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** `TournamentTeam` supports `name`, `players`, `seed` and `approved`; it does not have a captain field. A member count can be derived from `players.length` only when that list is populated.
- **Decision required:** Whether captain is a real product concept and how team membership is authored.
- **Safe current action:** V8 team rows show name, derived player count when non-empty, approval status and supported actions only.

## OD-09 - Champion sharing

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** No share package/service or tournament share behavior was found.
- **Decision required:** Approve native share behavior, the shared payload/artwork and privacy rules.
- **Safe current action:** Champion V8 exposes `تم` and existing navigation only; no dead share button.

## OD-10 - Premium benefit entitlement mapping

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** The Premium screen lists six benefits, while RevenueCat exposes plan/status access but no local per-benefit entitlement contract was found in this audit.
- **Decision required:** Confirm each benefit is implemented and gated by the Premium entitlement.
- **Safe current action:** Keep only benefits whose code/data path is verified during the dedicated Premium implementation audit. Do not add savings claims; prices must come from the store.

## OD-11 - Home secondary content

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** App content supports a home hero and content/category imagery, but the owner requires a game launcher first and no article-style feed.
- **Decision required:** Which maximum 2-3 real contextual items may appear below Start Game / Create Tournament: active game, active tournament, new category or current football category.
- **Safe current action:** Priority is deterministic: active session, Start Game, Create Tournament. Secondary content remains hidden until backed by real state.

## OD-12 - Profile achievements/tabs

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** `PlayerProfile` exposes achievements, football choices, social team and real stats; the V7 screen does not expose a true tab model.
- **Decision required:** Which content groups deserve tabs and which are secondary details.
- **Safe current action:** Rebuild identity and the verified stat strip first. Do not invent a new activity feed.

## OD-13 - Tournament create wizard persistence

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** The engine supports name, capacity, players per team, visibility, seeding, category IDs, timer, helpers and tiebreaker. The current screen creates the tournament before the separate teams/draw routes.
- **Decision required:** Whether wizard steps persist a draft after each step or keep local state until review.
- **Safe current action:** Preserve current controller/engine behavior; V8 may present steps progressively without changing persistence semantics.

## OD-14 - Notification empty-state action

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** The empty sample has no required recovery action; refresh exists in the top bar.
- **Decision required:** Whether an empty state should offer `العب الآن`, `ادعُ ربعك`, or no CTA.
- **Safe current action:** Scale the existing empty message proportionally and retain refresh only.

## OD-15 - Remote production configuration checks

- **Status:** UNCERTAIN - NOT IMPLEMENTED - REQUIRES OWNER DECISION
- **Evidence:** This phase is local and read-only. No remote Supabase push or production-provider verification was authorized.
- **Decision required:** Approve remote read-only verification where necessary before claims about Auth, category media, Premium plans or notifications.
- **Safe current action:** No remote mutation, no migration, no Supabase push.
