# AHDASH | 11 — Product Truth

**Authority:** primary normative product authority  
**Last verified:** 12 September 2026  
**Release status:** owned by [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)  
**Deferred decisions:** owned by [10_ROADMAP_DEFERRED.md](./10_ROADMAP_DEFERRED.md)

## Product identity

AHDASH | 11 is an Arabic, RTL-first Saudi football Party trivia game for two teams playing together on one shared device. Flutter mobile is the main production-shaped gameplay client, and Local Party is the dominant product identity and gameplay path. The active product language is Arabic, and the approved visual identity is governed by [08_DESIGN_SYSTEM.md](./08_DESIGN_SYSTEM.md).

## Platforms

- **Flutter mobile:** Android and iOS application and the primary gameplay experience.
- **Desktop Web:** player-facing Next.js website. It is desktop-oriented and is not feature parity with mobile.
- **Admin:** staff-only dashboard and protected APIs within the same Next.js application as Desktop Web.
- **Backend:** Supabase/PostgreSQL, Auth, RLS/RPCs, storage metadata, and Edge Functions.

Desktop Web and Admin are separate products within one codebase and must never be described as one user surface. Phone browsers receive the app-download experience rather than the full Desktop Web experience.

## Active product

The following are `LIVE` in their stated local mobile scope:

- Launch and persisted four-step onboarding.
- Guest entry and route-level guest capability enforcement.
- Home and how-to-play.
- Same-device Local Party through the primary flow: start, choose six football categories, configure two teams, choose three helpers per team, ready, 36-question board, question/reveal/scoring, final result, and replay.
- Local solo/practice and discoverable Classic play.
- Local sound, haptics, reduced-motion, and Player11 variant preferences.
- Local caching and Party session/history persistence.

Authenticated/cloud features have real implementations but are generally `IMPLEMENTED_NOT_RELEASE_READY` or `CONFIGURED_EXTERNAL_SETUP_REQUIRED` until their relevant Production, provider, or device validation is accepted. Schema deployment alone does not make a client feature release-ready.

## Guest scope

Mobile guests may use only:

- Home.
- How to play.
- Local Party.
- Local solo/practice.
- Local settings.

Saved-games UI, tournaments, profile, ranking, teams and team challenges, blocked players, notifications, football preferences, Premium, problem reports, and cloud-backed operations require a non-guest account. Party data is local, but the current saved-games route remains account-gated.

On Desktop Web, public marketing, the truthful game explainer, championship entry information, support, legal pages, Local Party, and local Solo/Classic are public. Entering local gameplay establishes the same real Supabase anonymous guest identity used to reach the existing authenticated content RPCs; that anonymous identity is explicitly rejected by account and tournament guards. Tournament create/join, the account center, and all account subpages require a non-anonymous account.

## Authenticated scope

`AUTH_REQUIRED` capabilities include:

- **Mobile:** saved-games UI, tournaments, profile summary, ranking, teams, team challenges, blocks and player reports, notifications, football preferences, Premium, problem reports, and cloud operations.
- **Desktop Web:** tournament create/join, account center, and account subfeatures. Local Party and Solo/Classic are guest-capable.
- **Admin:** the complete dashboard route group, with moderator/admin authorization applied by guarded pages and APIs.

Server RLS/JWT/RPC enforcement—not client visibility—is authoritative for remote data access.

Desktop Web implements real Supabase Email sign-in, registration, password recovery, and password reset. Its Google and Apple buttons also initiate real Supabase OAuth PKCE paths through `/auth/callback`, with allow-listed internal return paths. Both web OAuth providers remain `CONFIGURED_EXTERNAL_SETUP_REQUIRED` until Supabase/provider-console configuration and deployed-domain E2E are verified.

## Game modes

| Mode | Product truth |
|---|---|
| Local Party | `LIVE` on mobile and the strongest complete product slice. Desktop has a real local implementation using existing catalog/RPC contracts and mobile-compatible rules; it is `IMPLEMENTED_NOT_RELEASE_READY` pending deployed catalog and browser E2E. |
| Practice / local solo | `LIVE` on mobile. Desktop has real local Solo/Classic setup, content loading, timing, scoring, result/replay, and browser-local personal best; it is `IMPLEMENTED_NOT_RELEASE_READY`. |
| Team challenge | `IMPLEMENTED_NOT_RELEASE_READY` and `AUTH_REQUIRED` on mobile. Desktop has only a local prototype. |
| Daily Challenge | `NOT_IMPLEMENTED`; labels or enums are not a product flow. |
| Online 1v1/2v2/matchmaking | `REMOVED_FROM_ACTIVE_PRODUCT`; compatibility routes return to Home, and retained backend infrastructure does not imply support. |

## Game types

| Type | Product truth |
|---|---|
| Classic | `LIVE` and discoverable on mobile. |
| True/False | `IMPLEMENTED_NOT_RELEASE_READY`; its engine and direct setup route exist, but it has no approved discoverable entry in current Home/Play. |
| Speed | `IMPLEMENTED_NOT_RELEASE_READY`; its engine and direct setup route exist, but it has no approved discoverable entry in current Home/Play. |
| Ordering | `DEFERRED` on mobile; Desktop's option-selection prototype is `EXPERIMENTAL`. |
| Club Guess | `DEFERRED` on mobile; Desktop's prototype is `EXPERIMENTAL`. |
| Eagle Eye | `DEFERRED`; there is no approved image-observation flow or licensed Production media set. |

## Party truth

Local Party is the strongest complete product slice. It supports two teams on one device, exactly six selected categories, six unique questions per category when the catalog satisfies the required tiers, three selected helpers per team, a configurable timer, supported text/image question rendering, reveal, steal, scoring, undo, final result, and replay.

Party stores drafts, the active session, favorites, recent question identifiers, and completed local sessions. Production does not seed demo content; a release-quality experience therefore requires a valid Production catalog or previously cached valid content.

Website Rebuild Phase 2 implements the same core shape on Desktop: exact six-category selection, team/player setup, three helpers per team, ready summary, deterministic 6 × 6 board, timer and steal phases, reveal and scoring, undo, versioned browser-local save/resume, final winner/tie, and replay. It uses `categories`, `get_party_category_health`, `get_party_question_pack`, `party_help_tools`, and `party.rule_config`; no Production fallback question bank exists. Browser-local persistence is not cloud sync.

## Premium truth

Approved plans—exactly:

- Monthly.
- Annual.

Approved benefits—exactly:

- Exclusive categories.
- Ad-free.

No additional Premium benefit is approved. Broader statistics, tournament options, profile appearance, Store benefits, and vouchers are not Premium product truth.

Mobile implements package loading, entitlement checking, purchase, restore, status/management, Premium category access, and ad bypass. It remains `CONFIGURED_EXTERNAL_SETUP_REQUIRED` until store products and real purchase/restore/expiry behavior are accepted.

Promotional vouchers are `DEFERRED`. Their schema is deployed, but client and server feature gates remain OFF and activation lacks policy approval.

## Ads truth

Interstitial and rewarded AdMob service code exists. Solo result flow invokes the interstitial cadence, and active Premium access bypasses interstitial display. Live consent, serving, fill, frequency, dismissal/failure, and device behavior still require validation.

Rewarded server verification exists, but the rewarded economy experience is tied to the deferred Store/economy product and is therefore `DEFERRED`.

## Tournament truth

Mobile has real authenticated flows for tournament hub, creation, join, registration review, team management, draw, knockout bracket, Party-linked match, result confirmation, and champion. The current schema supports knockout only.

Tournament is `IMPLEMENTED_NOT_RELEASE_READY`: its required migrations are deployed, including the explicit registration enum-cast fix, while client/device and selected operational validation remain. Desktop league and group selections are not real engines; Desktop public championship discovery contains fixtures.

## Teams, competition, and safety truth

Mobile contains real authenticated flows for ranking, team creation/join/member management/invite-code rotation, team challenges, blocking/unblocking, and player reports. These capabilities remain `IMPLEMENTED_NOT_RELEASE_READY`, `AUTH_REQUIRED`, and require Production client validation. Admin retains moderation capabilities.

Friends, friend search, friend requests, and the Friends dashboard are `REMOVED_FROM_ACTIVE_PRODUCT`. Approved mobile navigation, account surfaces, team actions, notification preferences, and notification deep links do not expose them. Retained client/backend code, schema, RPC history, and old test fixtures are dormant compatibility infrastructure and do not imply active support.

## Deferred and not implemented

The following are not current product promises:

- Online matchmaking, rooms, 1v1, and 2v2: `REMOVED_FROM_ACTIVE_PRODUCT`; legacy routes redirect to Home.
- Friends and the friend graph: `REMOVED_FROM_ACTIVE_PRODUCT`.
- Ordering, Club Guess, and Eagle Eye mobile flows: `DEFERRED`.
- Store, Wallet, Coins, Inventory, Cosmetics, and rewarded economy UX: `DEFERRED`.
- Voucher activation: `DEFERRED`, gates OFF.
- Daily Challenge: `NOT_IMPLEMENTED`.
- Mobile password recovery/reset: `NOT_IMPLEMENTED`.
- Mobile server profile editing for name/username/avatar: `NOT_IMPLEMENTED`.

## Experimental work

- Desktop non-parity account surfaces retained for later phases. Phase 2 local Party and Solo/Classic are implemented but remain release-unready pending real catalog/deployed browser validation.
- Desktop tournament creation/join remain partial; public fixture discovery and unsupported league/group selectors were removed in Website Rebuild Phase 1.
- Goldens, screenshots, generated UI atlases, temporary concepts, old creative studies, and rejected directions.
- Demo rows and screenshots as representations of live data.

Experimental artifacts do not become current product truth unless explicitly approved and promoted through the owning canonical document.
