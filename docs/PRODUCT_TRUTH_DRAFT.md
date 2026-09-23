# AHDASH | 11 — Product Truth Draft

**As reconciled on 12 September 2026.** This concise draft is the proposed future product source of truth. It combines current repository evidence with verified operator evidence from the actual release session. Provider-console facts marked as operator-verified cannot be independently reconstructed from the repository alone. Detailed evidence and exceptions are in `docs/CURRENT_STATE_AUDIT.md`.

## 1. Product identity

AHDASH | 11 is an Arabic, RTL-first Saudi football trivia game built around social, same-device Party play. The approved visual direction is an editorial digital product plus a premium Arabic game—not a neon dashboard. Runtime identity comes from `mobile/assets/branding` and `admin/public/branding`; the reference package is `brand-package/ahdash_11_brand_package/assets/branding`. Thmanyah Sans 400/500/700/900 is the active product font.

Primary product language is Arabic. The current Flutter production theme is Light only even though a dark theme definition remains in code.

## 2. Platforms

- **Flutter mobile:** Android and iOS codebase. This is the production-shaped gameplay experience.
- **Desktop Web:** player-facing Next.js routes inside `admin/src/app/(website)`.
- **Admin:** staff-only Next.js routes inside `admin/src/app/(dashboard)` and role-protected `/api` routes.
- **Backend:** Supabase/PostgreSQL migrations, RLS/RPCs, Storage metadata, Auth, and 11 Edge Functions.

Desktop Web and Admin are two products inside one Next.js application. The full player website is desktop-only; phone browsers receive `/mobile-app` with App Store/Google Play buttons. Both official store URLs are currently absent, so the buttons show “coming soon.”

## 3. Currently active features

`LIVE` without a remote dependency:

- Launch, four-step onboarding, and persisted completion state.
- Mobile guest entry and global guest capability gate.
- Mobile Home and how-to-play.
- Mobile same-device Party: category selection, teams, automatic/manual split, helpers, ready summary, board, text/image questions, timers, steal window, reveal, scoring, undo, final result, and replay.
- Six Party categories × six unique questions when the selected catalog contains the required tiers.
- Mobile local solo/practice with category/difficulty/count selection, scoring, result, replay, and local personal best.
- Mobile local sound, haptics, reduced-motion, and Player11 variant preferences.
- Local Drift caching and Party session/history persistence.

Authenticated/cloud features have real implementations but remain `IMPLEMENTED_NOT_RELEASE_READY` until Production client/device and operational validation passes. The linked Production schema is operator-verified at 27/27 migrations through `20260908000100`; schema deployment alone does not complete feature E2E validation:

- Email/password auth and account creation.
- Tournaments, social/friends/teams/challenges/blocks, ranking, profile summary, football preferences, notifications, account deletion, and reports.
- Desktop player authentication, profile edit, problem report, and tournament create/join.
- The data-backed Admin dashboard and content/operations tools.

## 4. Guest capabilities

Mobile guests may use only:

- Home.
- How to play.
- Local Party.
- Local solo/practice.
- Local settings.

Saved-games UI, tournaments, profile, friends, teams/challenges, blocked players, ranking, notifications, football preferences, Premium, problem reports, and cloud sync require a non-guest account. Party state is local, but its saved-games route is intentionally account-gated in the current router.

On Desktop Web, public marketing, games catalog, championship page, support, and legal pages are viewable without an account. `/play`, tournament create/join, `/account`, and every account subpage are server-protected.

## 5. Auth-required capabilities

`AUTH_REQUIRED`:

- Mobile: saved-games UI, tournaments, profile, ranking, friends, social teams, team challenges, blocks, notifications, football preferences, Premium/vouchers, problem reports, and cloud-backed operations.
- Desktop: play, championship create/join, account center and all account features.
- Admin: the complete dashboard route group; minimum role is moderator, with admin-only mutations where defined.

RLS/JWT and protected RPCs—not client visibility—are the authority for server data.

## 6. Game modes

| Mode | Truth |
|---|---|
| Local Party | `LIVE` on mobile; desktop version is `EXPERIMENTAL` |
| Practice / local solo | `LIVE` on mobile; desktop version is `EXPERIMENTAL` |
| Team challenge | `IMPLEMENTED_NOT_RELEASE_READY`, `AUTH_REQUIRED` on mobile; desktop is a local prototype |
| Daily challenge | `NOT_IMPLEMENTED`; labels/enums are not a product flow |
| Online 1v1/2v2/matchmaking | `DEFERRED`; backend code exists, but Flutter routes redirect to Home |

## 7. Game types

| Type | Truth |
|---|---|
| Classic | `LIVE` and discoverable on mobile |
| True/False | `IMPLEMENTED_NOT_RELEASE_READY`; engine/direct setup route exist, but current Play/Home has no discoverable type entry |
| Speed | `IMPLEMENTED_NOT_RELEASE_READY`; engine/direct setup route exist, but current Play/Home has no discoverable type entry |
| Ordering | `DEFERRED` on mobile; desktop multiple-choice prototype is `EXPERIMENTAL` |
| Club Guess | `DEFERRED` on mobile; desktop prototype is `EXPERIMENTAL` |
| Eagle Eye | `DEFERRED`; no approved image-observation flow or licensed production media set |

The Desktop Web “six modes” page is not feature parity. It runs four hard-coded local questions per type, reduces types to option selection, has no authoritative server session, and saves only result summaries in browser localStorage.

## 8. Party game truth

Party is the strongest complete product slice. It supports two teams on one device, exactly six selected categories, six unique questions per category, three selected helpers per team, configurable timer, text/image and other supported Party render formats, score/reveal/steal/undo, result and replay. It stores drafts, active session, favorites, recent question IDs, and up to 30 completed sessions in Drift local settings.

Production does not seed demo content. A Production release therefore needs a validated server/catalog or previously cached valid content. Favorite categories attempt remote sync for signed-in users but remain usable locally if unavailable.

## 9. Premium truth

Approved plans:

- Monthly.
- Annual.

Approved benefits—exactly:

- Exclusive categories.
- Ad-free play.

Mobile loads the current RevenueCat monthly and annual packages, checks the `premium` entitlement, supports purchase/restore/status/management, enforces category access, and skips interstitial ads for active access. Operator evidence confirms the Codemagic Android public SDK key and `REVENUECAT_ENTITLEMENT_ID=premium` are configured for the `AHDASH | 11` Play app (`com.ahdash.eleven`). This remains `CONFIGURED_EXTERNAL_SETUP_REQUIRED` until Google Play developer/account and monthly/annual product setup, offering/webhook behavior, sandbox purchase, restore, expiry, and physical-device behavior pass.

Broader tournament options, advanced statistics, profile appearance, Store benefits, and vouchers are not approved Premium benefits. Desktop text that says otherwise is inaccurate.

## 10. Ads truth

Interstitial and rewarded AdMob service code exists with consent handling. Solo results invoke the interstitial cadence, and Premium access bypasses it. Operator evidence confirms the Codemagic `admob` group contains the Android app, interstitial, and rewarded IDs, `ADMOB_ENABLED=true`, and an initial interstitial cadence of 3; the Production validator passed in the successful Android release run. AdMob remains `CONFIGURED_EXTERNAL_SETUP_REQUIRED` because real consent, fill, frequency, dismissal/failure, SSV, and physical-device behavior are unverified.

Rewarded SSV has signature verification and idempotent server claiming, but its product use is tied to the deferred Store/economy path; rewarded access is therefore `DEFERRED`.

## 11. Tournament truth

Mobile has real authenticated UI and clients for hub, create, join, registration review, teams, draw, knockout bracket, Party-linked match, result confirmation, and champion. The backend provides tournament tables, registration RPCs, a knockout model, and safe v2 bracket/result functions.

Status: `IMPLEMENTED_NOT_RELEASE_READY`. The v2 safety and registration-fix migrations are operator-verified as deployed, including the explicit enum-cast fix. Real organizer/player client E2E, device behavior, and selected PostgreSQL/RLS/concurrency validation are still missing.

Only **knockout** is implemented. Desktop choices for league and group formats are merely stored in `rules_snapshot`; no league/group engine exists. Desktop public championship cards are fixtures. Desktop create/join call real RPCs, but organizer review, bracket, match, result, and champion management are absent.

## 12. Social truth

Mobile contains real authenticated flows and RPC clients for ranking, player search, friend requests/inbox/outbox/accept/reject/remove, team creation/join/invites/member roles/removal/code rotation, team challenges/results, blocking/unblocking, and player reports. Admin contains social moderation.

Status: `IMPLEMENTED_NOT_RELEASE_READY`, `AUTH_REQUIRED`, `NEEDS_PRODUCTION_VALIDATION`.

Desktop social parity does not exist. Friends only searches and sends a request; teams are a CTA; ranking and notifications are fixtures; blocked players is a static empty state.

## 13. Deferred features

- Online matchmaking, rooms, and 1v1/2v2 gameplay, despite retained backend infrastructure.
- Ordering, Club Guess, and Eagle Eye mobile flows.
- Store, wallet, coins, inventory, cosmetics, and rewarded-economy UX. Store/Wallet screens exist but are unreachable; `/store` is Premium and `/wallet` redirects there.
- Premium promotional vouchers until legal/store-policy approval and real DB/security validation.

## 14. Experimental/rejected work

- Desktop local gameplay engine and most Desktop account subfeatures.
- Desktop fixture championship discovery.
- Desktop league/group tournament selectors.
- Old Goldens, screenshots, generated UI atlases, creative studies, and `docs/v8_*`, `docs/v9-*`, `docs/v10_*_refinement`, `docs/visual-validation`, and packaged screen ZIPs unless a current approved runtime handoff explicitly references an asset.
- Any demo rows or screenshots are validation artifacts, not proof of live data.

Do not delete these in an audit. Do not treat them as production truth.

## 15. External dependencies

- Supabase Production schema is operator-verified at 27/27 migrations through `20260908000100`, with linked lint at 0 errors/16 warnings. Client/device E2E, selected RLS/RPC/security checks, Edge Function versions, server secrets, and scheduled operations still require validation.
- Firebase Android/iOS apps, FCM service account/scheduler, Crashlytics and Analytics verification.
- Google OAuth/Supabase provider and real-device sign-in.
- Apple Sign-In capability, entitlement, provider, and CI enablement.
- RevenueCat Android SDK key and `premium` entitlement are operator-verified in Codemagic; monthly/annual Play products, offering/webhook behavior, and sandbox/device validation remain.
- AdMob Android IDs, enablement, and cadence 3 are operator-verified in Codemagic; consent, live serving/fill, SSV, and device validation remain.
- Google Play/App Store accounts, listings, privacy declarations, signing, screenshots, review, and official URLs.
- Codemagic Android release infrastructure, signing, Firebase injection, Production validation, signed AAB, and signed APK are operator-verified from the release session. A new green run is still required for the later dirty working tree.

## 16. Release readiness

| Platform | State | Truth |
|---|---|---|
| Android | **PARTIALLY READY** | Release infrastructure and signed AAB/APK are operator-verified from an earlier known commit; the current dirty tree fails three non-visual tests, and physical-device, Google Play, purchase, push/telemetry/ads, and final review gates remain |
| iOS | **BLOCKED** | Workflow exists, but Apple capability/provider, complete configuration, green CI/TestFlight/device proof and App Store submission are absent |
| Desktop Web | **PARTIALLY READY** | Build/type/lint/tests pass; core auth/profile/report work, but gameplay/account/championship placeholders and false claims block launch |
| Admin | **PARTIALLY READY** | Broad data-backed tools and guards build successfully; several surfaces are read-only/absent and Production role/data validation is missing |
| Backend | **PARTIALLY READY** | Linked Production is operator-verified at 27/27 migrations through `20260908000100` and linked lint is 0 errors/16 warnings; real client/device E2E plus selected operational/security/Edge Function validation remain |

## 17. Known blockers

1. Fix—not in this audit—the three failing non-visual Flutter tests and re-run the exact Android CI selection.
2. Validate the already-deployed Production schema with the required client contracts and selected authorized pgTAP/JWT/RLS/direct-DML/two-connection checks. Do not reapply or repair the four newest migrations.
3. Verify mobile, Desktop Web, and Admin contracts against linked Production, including the corrected tournament registration enum flow; verify relevant Edge Function versions separately.
4. Validate Android Firebase/OAuth/FCM/RevenueCat/AdMob on physical devices; complete the still-unproven iOS provider configuration independently.
5. Keep Premium copy to the two approved benefits and remove unsupported Desktop claims.
6. Decide whether to finish or remove Desktop prototypes before public deployment.
7. Keep Store/Wallet/Vouchers/online modes out of active product navigation until separately approved.
8. Complete Google Play developer verification, app/listing, Data Safety, rating, track, monthly/annual products, review, and official Play URL; complete the corresponding iOS/App Store work separately.
9. Complete legal and sports-content/media-rights review.
10. Preserve the earlier operator-verified Android release evidence, then capture a new green Codemagic run for the later working tree and end-to-end release evidence per platform.
