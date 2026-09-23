# AHDASH | 11 — Flutter Mobile Application

**Scope:** Flutter mobile only  
**Last verified:** 12 September 2026  
**Product authority:** [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md)  
**Current test state:** [09_TESTING_STRATEGY.md](./09_TESTING_STRATEGY.md)  
**Provider setup:** [06_INTEGRATIONS.md](./06_INTEGRATIONS.md)

## Role of the mobile client

Flutter mobile is the main production-shaped gameplay client. Its dominant identity is a football Party trivia game for two teams sharing one device. It owns the full Local Party experience and the complete local solo/practice flow. Cloud-backed features use Supabase and external providers, while core local gameplay remains available to guests within the approved capability policy.

## Bootstrap and runtime

Bootstrap initializes application configuration, local preferences and storage, service wrappers, auth state, and routing dependencies. Provider-backed services are configuration-gated and must fail safely when unavailable. The current Production product theme is Light; visual authority is documented in [08_DESIGN_SYSTEM.md](./08_DESIGN_SYSTEM.md).

## Routing and access

Routing resolves persisted onboarding state, authenticated/guest state, public routes, and account-only destinations. `GuestCapabilityPolicy` is the mobile authority for guest access. Server authorization remains enforced by Supabase RLS/JWT/RPCs.

Current routing truths:

- Launch resolves onboarding/auth state before the main experience.
- Friends, Online, room, and matchmaking compatibility routes redirect to Home and are not active player features.
- `/store` currently resolves to Premium and `/wallet` redirects there; Store/Wallet product screens are not active.
- Saved-games UI is account-gated even though Party persistence itself is local.

## Capability status

| Area | Current behavior | Status | Access / validation note |
|---|---|---|---|
| Launch | Resolves persisted onboarding and auth state | `LIVE` | Local |
| Onboarding | Four steps with persisted completion | `LIVE` | Local |
| Email/password authentication | Real Supabase sign-in and account creation | `IMPLEMENTED_NOT_RELEASE_READY` | Production account/device validation |
| Google sign-in | Native token exchange path | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Android configuration is operator-verified; device flow pending |
| Apple sign-in | Redirect code and gated UI path | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | iOS capability/provider/CI setup incomplete |
| Password recovery/reset | No mobile repository/UI flow | `NOT_IMPLEMENTED` | Desktop availability does not change mobile truth |
| Guest capability gate | Blocks private destinations before protected UI mounts | `LIVE` | Local policy; server remains authoritative remotely |
| Home | Real account-aware navigation and valid Party resume | `LIVE` | Remote cards may depend on services |
| Play entry | Local Party is primary; classic solo remains discoverable | `LIVE` | No Online/Friends entry; True/False and Speed lack approved discoverable entries |
| Local Party | Complete two-team, one-device game | `LIVE` | Strongest complete slice |
| Solo/practice | Category/difficulty/count, questions, timer, score, result, replay, personal best | `LIVE` | No fake opponent |
| Saved games | Local active/draft/history persistence with account-gated UI | `LIVE` | `AUTH_REQUIRED` route; no cloud sync claim |
| Tournaments | Full authenticated knockout client flow | `IMPLEMENTED_NOT_RELEASE_READY` | Production schema deployed; client/device E2E pending |
| Ranking | Real leaderboard query and empty/error states | `IMPLEMENTED_NOT_RELEASE_READY` | `AUTH_REQUIRED` |
| Friends | Legacy route redirects to Home; no active cards, actions, claims, preferences, or notification deep links | `REMOVED_FROM_ACTIVE_PRODUCT` | Retained code/backend infrastructure is dormant |
| Teams | Create/join/member roles/remove/code rotation | `IMPLEMENTED_NOT_RELEASE_READY` | `AUTH_REQUIRED` |
| Team challenges | Server-backed challenge attempt/result flow | `IMPLEMENTED_NOT_RELEASE_READY` | `AUTH_REQUIRED` |
| Blocks and player reports | List, block/unblock, and report actions | `IMPLEMENTED_NOT_RELEASE_READY` | `AUTH_REQUIRED` |
| Profile summary | Server identity/stat/preference summary | `IMPLEMENTED_NOT_RELEASE_READY` | `AUTH_REQUIRED`; no durable cache claim |
| Server profile editing | No mobile name/username/avatar edit flow | `NOT_IMPLEMENTED` | Local Player11 variant is only a device preference |
| Settings | Sound, haptics, reduced motion, Player11 variant | `LIVE` | Local persistence |
| Logout/account deletion | Logout plus deletion-function client | `IMPLEMENTED_NOT_RELEASE_READY` | Deletion lifecycle needs Production validation |
| Notifications | Inbox, read state, preferences, token/deep-link client | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | FCM/scheduler/device delivery pending |
| Football preferences | Authenticated preference surface | `IMPLEMENTED_NOT_RELEASE_READY` | Production data validation pending |
| Premium | Monthly/annual packages, entitlement, purchase/restore/status | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Store/device validation pending |
| Interstitial ads | Invoked after solo result and bypassed for Premium | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Android CI config verified; device behavior pending |
| Rewarded economy | Service/SSV code retained | `DEFERRED` | Active product depends on deferred economy |
| Store/Wallet | Source exists but active routes do not expose the product | `DEFERRED` | Do not advertise as active |
| Online 1v1/2v2/matchmaking | Client routes are tombstones to Home and Play exposes only local modes | `REMOVED_FROM_ACTIVE_PRODUCT` | Retained backend code is not a live client feature |
| Daily Challenge | No route/controller/persisted daily product | `NOT_IMPLEMENTED` | Enum/copy is insufficient |

## Play and game types

- **Classic:** `LIVE` and discoverable.
- **True/False:** engine, questions, timer, and direct setup route exist; `IMPLEMENTED_NOT_RELEASE_READY` because there is no approved discoverable Home/Play entry.
- **Speed:** engine, seven-second rules, and direct setup route exist; `IMPLEMENTED_NOT_RELEASE_READY` because there is no approved discoverable Home/Play entry.
- **Ordering, Club Guess, Eagle Eye:** `DEFERRED`.

## Local Party

Party covers category search/detail and entitlement gating, exactly six selected football categories, team naming and distribution for two teams, helpers, ready summary, a 36-question board, text/image questions, timer, reveal, opponent opportunity, scoring, undo, final result, and replay. Each team selects three helpers from the available definitions. A valid game uses six unique questions per selected category when the catalog provides the required tiers.

State handling includes drafts, active session resume, local favorites, recent question identifiers, and completed-session history. Remote content is optional to the local state machine but required for release-quality catalog breadth when no valid cache exists.

## Solo

Solo/practice supports category, difficulty, and question-count setup, timed questions, scoring, result, replay, and local personal best. It deliberately does not fabricate an opponent score. Ad cadence may be evaluated after results, subject to Premium bypass and provider/device readiness.

## Tournaments, teams, and safety

Authenticated tournament screens cover hub, creation, join, registration review, team list, draw, knockout bracket, Party-linked match, result confirmation, and champion. Authenticated account screens cover ranking, teams, code-based team joining, member operations, team challenges, blocks, and reports. These are real clients but remain `IMPLEMENTED_NOT_RELEASE_READY` pending Production account/device E2E. Friends code may remain in the repository for compatibility, but it has no approved mobile entry point.

## Premium and ads

Premium exposes only Monthly and Annual plans. Approved benefits are only Exclusive categories and Ad-free. Vouchers remain `DEFERRED` with both gates OFF. AdMob and RevenueCat code/configuration status is owned by [06_INTEGRATIONS.md](./06_INTEGRATIONS.md); release acceptance is owned by [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md).

## Persistence and offline behavior

Drift/local settings store category and question cache, Party draft/active/history data, favorites, usage data, preferences, and pending operations. Local Party and solo behavior should not be described as general cloud-offline support.

A callable pending question-report sync exists, but no global reconnect orchestrator invokes it. Automatic reconnect re-sync is therefore `NOT_IMPLEMENTED`. The connectivity banner is visual feedback only.

## Error and problem reporting

- Question reports can submit online and queue locally when needed; automatic reconnect submission is not complete.
- User problem reports use a sanitized remote submission path and require authentication.
- Application error reporting is sanitized and service-gated; operational ingestion still requires Production validation.

No error report should contain secrets or raw sensitive credentials.
