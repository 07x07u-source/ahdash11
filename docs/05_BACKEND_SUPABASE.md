# AHDASH | 11 — Supabase Backend

**Scope:** PostgreSQL/Supabase schema, migrations, RLS, RPCs, Edge Functions, and backend validation  
**Last verified:** 12 September 2026  
**Evidence:** repository source plus operator-verified linked-Production release session  
**Provider configuration:** [06_INTEGRATIONS.md](./06_INTEGRATIONS.md)  
**Release verdict:** [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)

## Current backend layers

| Layer | Current truth | Evidence state |
|---|---|---|
| Deployed schema | Linked Production migration history matches local history 27/27 through `20260908000100_fix_review_tournament_registration_enum.sql` | `OPERATOR_VERIFIED` |
| Validated client behavior | Source/static/embedded evidence is positive, but authenticated mobile, Desktop Web, and Admin E2E against Production remains incomplete | Validation pending |
| Edge Function/provider runtime | Function source exists; deployed versions, secrets, schedules, provider behavior, and per-function E2E are not established by migration evidence | External/operational validation pending |

These layers must never be collapsed into one status. A deployed schema is not proof that every client, function, scheduler, provider, or device flow is release-ready.

## Schema domains

The migration history covers:

- Profiles and authentication support.
- Categories, questions, options, content, media metadata, and rights enforcement.
- Local/remote gameplay support, matches, rooms, and answer submission.
- Friends, blocks, reports, social teams, members, invites, and challenges.
- Tournaments, registrations, draw/bracket, match result confirmation, and champion state.
- Notifications, preferences, tokens, campaigns, delivery records, and dispatch support.
- Subscriptions, entitlements/events, Store/economy data, wallet, inventory, and vouchers.
- Monitoring, application errors, user problem reports, audit data, and settings.

Schema presence does not activate a deferred product. Store/Wallet, vouchers, and Online remain governed by [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md) and [10_ROADMAP_DEFERRED.md](./10_ROADMAP_DEFERRED.md).

## Migration truth

Operator-verified facts from the 12 September 2026 Production session:

- Production migration history matches local history: **27/27**.
- Latest migration: `20260908000100_fix_review_tournament_registration_enum.sql`.
- The following four migrations are already deployed:
  - `20260902000100_gameplay_depth_v1.sql`
  - `20260905000100_tournament_bracket_safety_v2.sql`
  - `20260907000100_premium_vouchers_v1.sql`
  - `20260908000100_fix_review_tournament_registration_enum.sql`
- The explicit enum-cast migration fixed the historical tournament registration enum issue.
- No migration repair was used.
- `db lint --linked` completed with **0 errors** and **16 warnings**.

The older security release-gate document is historical pre-deployment evidence. It must not be used to claim these migrations remain blocked or undeployed.

Do not reapply these migrations. Do not recommend migration repair. Any future migration must be additive, reviewed, and independently authorized.

## RLS and authorization

Client visibility is never authorization. Remote access is governed by Supabase Auth identity, JWT claims, RLS policies, explicit grants/revokes, and guarded RPCs.

Repository evidence includes RLS enablement and policy declarations across the migration history. Reviewed sensitive RPCs use protections such as fixed `search_path`, explicit privilege boundaries, row locking, idempotency, compare-and-set behavior, and rate limiting where applicable.

Still required for release acceptance:

- Real anon/user/moderator/admin allow-and-deny scenarios.
- Direct DML denial checks outside approved RPC paths.
- Ownership, ACL, and `SECURITY DEFINER` verification against the deployed catalog.
- Account deletion and data-preservation behavior.
- Client E2E using real Production-shaped roles and records.

## RPC domains

RPCs support content/category packs, profiles and summaries, social/friends/teams/blocks/reports, tournaments and registration/bracket/result operations, notifications, subscriptions/vouchers/economy, monitoring/reporting, and protected administrative workflows.

The tournament backend supports knockout only. League/groups are not backend tournament engines. The corrected tournament registration review enum contract is deployed but still requires real organizer/player E2E.

## Edge Functions

The repository contains 11 Edge Functions, excluding shared code:

- `create-room`
- `join-room`
- `queue-matchmaking`
- `submit-answer`
- `import-validate`
- `import-commit`
- `dispatch-notifications`
- `revenuecat-webhook`
- `admob-reward`
- `wallet-transaction`
- `delete-account`

Function source does not establish deployed version or runtime readiness. Each active function requires its own deployment/version, authentication, secret, failure, idempotency, monitoring, and provider validation. Functions tied only to deferred Online or economy products must not be presented as active user features.

## Rate limiting and concurrency

Rate limiting exists in sensitive RPC paths including tournaments, reports, rooms/matches, vouchers, and economy operations. Tournament and voucher source/static/embedded tests cover important contracts, but real timing and multi-connection behavior remain separate validation work.

Selected pending checks include:

- Rate-limit boundaries under real database time/transactions.
- Tournament registration, draw, result, and replay/idempotency behavior.
- Voucher redemption race behavior while gates remain OFF.
- Two-connection row-lock and compare-and-set scenarios.
- Month/year/timezone boundary behavior where applicable.

## Feature gates

- Voucher client and server gates remain **OFF**. The deployed voucher schema does not authorize activation.
- Online matchmaking and 1v1/2v2 routes remain `DEFERRED` even though backend infrastructure exists.
- Store/Wallet/economy remains `DEFERRED`; inactive schema/function code is not a live product.

## Current validation gaps

- Real client/device E2E against the deployed Production schema.
- Selected pgTAP/JWT/RLS/direct-DML and real concurrency scenarios.
- Review and disposition of the 16 linked-lint warnings.
- Deployed Edge Function version and secret verification.
- Notification schedules and delivery, RevenueCat webhook, AdMob SSV, account deletion, imports, and wallet/function runtime validation as applicable to active scope.
- Storage buckets, media rights behavior, Auth providers, audit completeness, and failure recovery.

These gaps make Backend `PARTIALLY READY`; they do not make the 27/27 Production migration state unknown.
