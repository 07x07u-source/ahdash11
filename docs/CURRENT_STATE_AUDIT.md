# AHDASH | 11 — Current-State Audit

**Audit date:** 12 September 2026  
**Scope:** current working tree at `C:\dev\ahdash11` (including existing uncommitted work)  
**Base commit:** `4a9e275b7c71b0f68731373cd4add5f4a871084a` on `main`  
**Purpose:** reconciled current-state source of truth using repository evidence plus verified release-operator evidence; this is not a roadmap or an approval to release.

**Evidence reconciliation:** provider-console and release-session facts in this document were operator-verified on 12 September 2026. The repository alone cannot independently reconstruct that external state. Current-working-tree checks remain separate from the successful earlier release run.

## Executive conclusion

AHDASH | 11 is a substantial, coherent implementation, but it is not one uniformly release-ready product. The strongest current path is the Flutter local Party experience. The mobile app also contains real Supabase-backed tournament, social, notification, Premium, and reporting clients. All 27 migrations, including the four newest migrations, are operator-verified as deployed to the linked Production database; those authenticated paths still need client/device E2E and selected operational/security validation. The Next.js repository contains both a player-facing desktop website and a staff dashboard in one application. The staff dashboard is broadly data-backed; much of the player website beyond authentication, profile editing, reports, and tournament create/join is a local prototype or placeholder.

Android release infrastructure is proven, not merely defined in source. In a successful Codemagic release run from an earlier known commit on `main`, static analysis, the selected non-visual tests, Firebase Android injection, release signing, the Production configuration validator, and the signed AAB build passed. A later workflow revision also produced a signed APK. The downloaded AAB and its release certificate were independently verified. This does not make the current dirty working tree releasable: that tree's equivalent non-visual suite now fails three tests, Google Play publication is incomplete, and device/store validation remains pending. iOS is further behind.

Backend source is extensive: 27 migrations, 146 parsed PL/pgSQL function bodies, 11 Edge Functions, RLS declarations, and security tests. Operator evidence confirms local and linked-Production migration history matched 27/27, latest `20260908000100`, and `db lint --linked` completed with 0 errors and 16 warnings. No migration repair was used. This supersedes the earlier repository-only conclusion that the four newest migrations were undeployed. Deployment is distinct from full E2E validation: real client/device flows and selected PostgreSQL/JWT/RLS/concurrency checks remain pending, voucher gates remain off, and Online routes remain deferred.

## Status model

Every row below has exactly one primary status in **Production status**:

- `LIVE`: usable as intended without an unresolved release dependency in that row's scope.
- `IMPLEMENTED_NOT_RELEASE_READY`: real implementation exists but validation/configuration/release work remains.
- `CONFIGURED_EXTERNAL_SETUP_REQUIRED`: integration path exists but an external provider/platform must be configured.
- `DEFERRED`: explicitly postponed and should not be represented as current functionality.
- `EXPERIMENTAL`: prototype, fixture, study, or test-only implementation.
- `NOT_IMPLEMENTED`: no end-to-end production implementation exists.
- `UNKNOWN`: repository evidence cannot establish the state.

Secondary flags are written in **Notes**.

Evidence qualifiers used where helpful:

- `REPO_VERIFIED`: established from current source or a command run against the current working tree.
- `OPERATOR_VERIFIED`: established from the actual release/provider session on 12 September 2026; repository-only inspection cannot reconstruct the provider-console state.
- `DEVICE_VERIFICATION_PENDING`: physical-device runtime behavior is not yet accepted.
- `STORE_VERIFICATION_PENDING`: store account, products, listing, track, or review remains incomplete.
- `LEGAL_APPROVAL_PENDING`: configured legal links do not replace final legal approval.
- `CURRENT_TREE_TEST_GATE_FAILING`: the current working tree fails its release-equivalent non-visual test gate even though an earlier Codemagic release run succeeded.

## Feature matrix

| Domain | Feature | Mobile | Desktop Web | Admin | Backend | Production status | Blocking dependency | Evidence / key files | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Entry | Launch | Routes from persisted onboarding/auth state | N/A | N/A | N/A | `LIVE` | None for local behavior | `mobile/lib/features/onboarding/presentation/launch_screen.dart`; `mobile/lib/core/routing/app_router.dart` | `MOBILE_ONLY` |
| Entry | Four-step onboarding and completion state | Real screens; completion stored in SharedPreferences | N/A | N/A | N/A | `LIVE` | None | `mobile/lib/features/onboarding/presentation/onboarding_screen.dart`; `mobile/lib/core/settings/app_preferences.dart` | `MOBILE_ONLY` |
| Auth | Email/password sign-in | Real Supabase path; development fallback without Supabase | Real Supabase browser path | Separate staff login | Auth/profile trigger and RLS exist | `IMPLEMENTED_NOT_RELEASE_READY` | Production account/device validation | `mobile/lib/features/auth/data/supabase_auth_repository.dart`; `admin/src/components/player-auth-form.tsx`; `supabase/migrations/20260827000200_profiles_and_questions.sql` | `NEEDS_PRODUCTION_VALIDATION` |
| Auth | Account creation | Real Supabase sign-up/anonymous upgrade | Real Supabase sign-up | N/A | Profile creation trigger exists | `IMPLEMENTED_NOT_RELEASE_READY` | Email/provider and Production validation | Same auth files; `supabase/migrations/20260827000200_profiles_and_questions.sql` | `NEEDS_PRODUCTION_VALIDATION` |
| Auth | Google sign-in | Native Google token exchange; Android configuration and release SHA checks pass locally | Not exposed | N/A | Supabase provider must be configured | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Supabase/Firebase OAuth provider plus device validation | `mobile/lib/features/auth/data/native_google_auth_client.dart`; `mobile/lib/features/auth/data/supabase_auth_repository.dart`; `scripts/check-release-integrations.mjs` | `MOBILE_ONLY`, `NEEDS_DEVICE_TEST` |
| Auth | Apple sign-in | OAuth redirect code and UI gate exist | Not exposed | N/A | Supabase Apple provider required | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Apple capability/provider; CI does not enable `APPLE_AUTH_ENABLED`; entitlement lacks Sign in with Apple | `mobile/lib/features/auth/data/supabase_auth_repository.dart`; `mobile/ios/Runner/Runner.entitlements`; `codemagic.yaml` | `MOBILE_ONLY`, `NEEDS_DEVICE_TEST` |
| Auth | Password recovery/reset | No auth repository or UI flow | Recovery email and reset password are implemented | N/A | Supabase Auth | `NOT_IMPLEMENTED` | Mobile flow is absent | `mobile/lib/features/auth/domain/auth_repository.dart`; `admin/src/components/player-auth-form.tsx` | Desktop exists; mobile does not |
| Auth | Deep links | Login callback plus team/tournament Android links; iOS URL scheme | PKCE callback route | N/A | Supabase callback | `IMPLEMENTED_NOT_RELEASE_READY` | Physical-device and deployed-domain validation | `mobile/android/app/src/main/AndroidManifest.xml`; `mobile/ios/Runner/Info.plist`; `admin/src/app/(website)/auth/callback/route.ts` | `NEEDS_DEVICE_TEST` |
| Access | Guest entry and global gate | Anonymous/local guest supported; router blocks private destinations before mount | Player routes redirect server-side to login | Dashboard layout is server-protected | RLS/JWT remain authoritative | `LIVE` | None for local gate logic | `mobile/lib/features/auth/domain/guest_capability_policy.dart`; `admin/src/lib/auth/player.ts`; `admin/src/lib/auth/context.ts` | Guest is local-only |
| Access | Guest capabilities | Home, how-to, local Party, local solo, local settings | Public marketing/catalog/legal only; play requires auth | None | N/A | `LIVE` | None | `guest_capability_policy.dart`; `admin/src/app/(website)/play/page.tsx` | `GUEST_ONLY` |
| Home | Mobile home | Real navigation, resume only for a real Party session, account-aware cards | Separate website home | N/A | Optional remote content | `LIVE` | Remote cards still depend on services | `mobile/lib/features/home/presentation/home_screen.dart` | Local core works |
| Gameplay format | Local Party | Complete two-team, one-device flow | Simplified score toggle over four fixed questions | Party rules/content editor exists | Optional question-pack RPC | `LIVE` | Production content needed for non-demo release | `mobile/lib/features/party/**`; `supabase/migrations/20260830000100_party_game_content.sql` | `GUEST_ONLY` on mobile; desktop version is experimental |
| Gameplay format | Practice / solo | Complete local question/answer/result flow; personal best local | Four-question local prototype | N/A | Optional question pack/history | `LIVE` | Production content for release-quality breadth | `mobile/lib/features/match/presentation/solo_match_controller.dart`; `mobile/lib/features/match/presentation/question_screen.dart` | `GUEST_ONLY` on mobile |
| Gameplay format | Team challenge | Real authenticated server-backed challenge attempt and result flow | Only local two-score prototype | Social moderation exists | Challenge tables/RPCs exist; schema is deployed | `IMPLEMENTED_NOT_RELEASE_READY` | Production client/account E2E | `mobile/lib/features/social/presentation/team_challenge_screen.dart`; `mobile/lib/features/social/data/social_repository.dart`; `supabase/migrations/20260828000300_social_football_v1.sql` | `AUTH_REQUIRED`, `OPERATOR_VERIFIED` schema, `DEVICE_VERIFICATION_PENDING` |
| Gameplay format | Daily challenge | Enum/copy only; no route, controller, daily uniqueness, or persisted daily result | Same four-question engine under a label | N/A | No verified daily product contract | `NOT_IMPLEMENTED` | Product and backend implementation | `mobile/lib/features/game/domain/game_mode.dart`; `admin/src/lib/site/game-modes.ts` | Desktop label is not completion |
| Game type | Classic | Discoverable and completable | Four fixed prototype questions | Content editor supports question data | Content schema/RPCs exist | `LIVE` | Production catalog breadth is separate | `mobile/lib/features/play/presentation/play_screen.dart`; `mobile/lib/features/match/**` | Mobile local core |
| Game type | True/False | Engine, direct setup route, timer, and questions exist; no discoverable entry from current Play/Home UI | Four fixed two-option prototype questions | Editor supports format | Backend contracts exist | `IMPLEMENTED_NOT_RELEASE_READY` | Restore an approved user entry point and run E2E | `mobile/lib/features/game/domain/game_mode.dart`; `mobile/lib/features/game/presentation/game_setup_screen.dart`; `mobile/lib/features/play/presentation/play_screen.dart` | Direct route only |
| Game type | Speed | Engine, direct setup route, 7-second rules exist; no discoverable entry from current Play/Home UI | Label/hint only; no real countdown | Editor/contracts support metadata | Backend contracts exist | `IMPLEMENTED_NOT_RELEASE_READY` | Restore an approved user entry point and run E2E | Same files; `mobile/lib/features/match/presentation/solo_match_controller.dart` | Direct route only |
| Game type | Ordering | Disabled enum and generic mechanics contracts; no approved user flow | Multiple-choice sequence prototype | Some schema mechanics | Supporting contracts only | `DEFERRED` | Dedicated UX/content/validation | `mobile/lib/features/game/domain/game_mode.dart`; `admin/src/components/play-experience.tsx` | `FEATURE_GATED`; desktop is `EXPERIMENTAL` |
| Game type | Club Guess | Disabled enum; no playable mobile flow | Multiple-choice hint prototype | N/A | No verified end-to-end mode | `DEFERRED` | Dedicated UX/content/validation | Same game mode and desktop prototype files | `FEATURE_GATED` |
| Game type | Eagle Eye | Disabled enum; no playable image-observation flow | Text/multiple-choice prototype without real image mechanic | Media tooling exists | No verified end-to-end mode | `DEFERRED` | Licensed media and dedicated mechanic | Same files; `docs/football-data-sources.md` | `FEATURE_GATED` |
| Party | Category selection and entitlement gating | Search, detail, six selections, favorites, access tiers | No equivalent production flow | Category/content control exists | Category/question RPC and media rules | `LIVE` | Production catalog quality is operational | `mobile/lib/features/party/presentation/party_setup_screens.dart`; `mobile/lib/features/party/presentation/party_catalog_provider.dart` | Premium category gates are real |
| Party | Teams, automatic splitter, helpers, ready | Real validated sequence | Simplified team labels only | Helper configuration API/UI | Party settings/help tables | `LIVE` | None for local default rules | `mobile/lib/features/party/presentation/party_setup_screens.dart`; `mobile/lib/features/party/domain/party_game.dart` | Three helpers per team selected from five definitions |
| Party | Board, text/image question, timer, reveal, scoring | Real state machine, helpers, steal window, undo, final result | No equivalent | Content authoring | Exact pack RPC optional | `LIVE` | Production media/content validation | `mobile/lib/features/party/presentation/party_game_screens.dart`; `party_game_controller.dart`; `party_game_engine.dart` | Six categories × six unique questions |
| Party | Save/resume/history | Active session, draft and up to 30 completed sessions in Drift local settings | Stores only result summaries in browser localStorage | N/A | Not cloud-synced | `LIVE` | None for signed-in local use | `party_game_controller.dart`; `party_support_screens.dart`; `mobile/lib/core/storage/app_database.dart` | Mobile route is `AUTH_REQUIRED` despite local storage |
| Solo | Match depth | Category/difficulty/count, timer, scoring, result, replay, personal best; opponent score is deliberately zero | Four-question prototype | N/A | Question pack/history optional | `LIVE` | Production content breadth | `mobile/lib/features/match/presentation/solo_setup_screen.dart`; `solo_match_controller.dart` | No fake opponent |
| Tournament | Hub and available list | Real repository/controller UI | Public listing is four hard-coded cards and inactive filters | Real operations center | Tables/views/RPCs; 27/27 migrations deployed | `IMPLEMENTED_NOT_RELEASE_READY` | Production client/data E2E and removal of desktop fixture listing | `mobile/lib/features/tournament/**`; `admin/src/app/(website)/championships/page.tsx` | `AUTH_REQUIRED` mobile; `OPERATOR_VERIFIED` schema |
| Tournament | Create | Real mobile RPC flow | Auth-protected RPC form | Admin can inspect | `create_tournament`; rate limited | `IMPLEMENTED_NOT_RELEASE_READY` | Production DB validation; desktop advertises unsupported formats | `tournament_gateway.dart`; `admin/src/components/tournament-create-form.tsx`; `20260831000200_tournaments_v1.sql` | Backend is knockout-only |
| Tournament | Join/registration | Real code, roster UI, validation | Auth-protected RPC form sends an empty roster | Admin inspects pending counts | `register_tournament_team` | `IMPLEMENTED_NOT_RELEASE_READY` | Real account/roster/approval E2E | `tournament_join_screen.dart`; `tournament-join-form.tsx`; tournament migration | `AUTH_REQUIRED` |
| Tournament | Approve/reject registration | Organizer UI and RPC | No organizer review UI | Limited monitoring | Corrected enum RPC is deployed | `IMPLEMENTED_NOT_RELEASE_READY` | Real organizer/registration E2E against Production | `tournament_registrations_screen.dart`; `20260908000100_fix_review_tournament_registration_enum.sql` | `OPERATOR_VERIFIED` deployment; historical enum issue fixed by explicit cast |
| Tournament | Draw/bracket | Real knockout engine and screens | No management screens | Monitor/cancel/reopen only | Safe v2 bracket RPCs are deployed | `IMPLEMENTED_NOT_RELEASE_READY` | Real client E2E plus selected PostgreSQL/RLS/concurrency validation | `mobile/lib/features/tournament/domain/tournament_engine.dart`; `20260905000100_tournament_bracket_safety_v2.sql` | Knockout only; `OPERATOR_VERIFIED` deployment |
| Tournament | Match/result/champion | Real Party-linked match, result confirmation and champion screen | Not implemented | Match/tournament monitoring | v2 confirm result RPC | `IMPLEMENTED_NOT_RELEASE_READY` | Production E2E and device validation | `tournament_screens.dart`; `tournament_controller.dart`; v2 migration | `AUTH_REQUIRED` |
| Social | Ranking | Real `leaderboard` view query; truthful empty state | Hard-coded top three plus player rating | N/A | View and stats tables | `IMPLEMENTED_NOT_RELEASE_READY` | Production data validation; replace desktop fixture | `mobile/lib/features/ranking/presentation/ranking_controller.dart`; `account-feature-surface.tsx`; `20260827000500_rls_and_safe_views.sql` | `AUTH_REQUIRED` |
| Social | Friends/search/requests | Search, send, accept/reject, remove, inbox/outbox | Search and direct request insert only; no list/accept/remove | Moderation is separate | RPCs/RLS exist | `IMPLEMENTED_NOT_RELEASE_READY` | Production E2E; complete desktop workflow | `mobile/lib/features/social/data/social_repository.dart`; `mobile/lib/features/social/presentation/friends_screen.dart` | `AUTH_REQUIRED` |
| Social | Teams, invites, members | Create/join/invite/respond/roles/remove/code rotation and team detail | CTA to local team-challenge prototype only | Team moderation exists | Real team tables/RPCs | `IMPLEMENTED_NOT_RELEASE_READY` | Production E2E; desktop UI absent | `social_repository.dart`; `social_hub_screen.dart`; `social_team_screen.dart` | `AUTH_REQUIRED` |
| Social | Block/unblock/report players | Real list and RPC actions | Static empty state only | Social report review | RPCs/RLS/rate limiting | `IMPLEMENTED_NOT_RELEASE_READY` | Production E2E | `blocked_players_screen.dart`; `social_repository.dart`; social migration | `AUTH_REQUIRED` |
| Profile | Read identity/stats/preferences | Real server summary; no durable cache | Real server profile summary | User list is read-only | Summary/stat RPCs | `IMPLEMENTED_NOT_RELEASE_READY` | Production data validation | `mobile/lib/features/profile/presentation/profile_controller.dart`; `admin/src/lib/auth/player.ts` | `AUTH_REQUIRED` |
| Profile | Edit name/username/avatar | No server profile edit UI; local Player11 variant only | Name/username update exists | No user edit UI | Profile RLS/trigger protection | `NOT_IMPLEMENTED` | Mobile edit experience and safe RPC/API | `mobile/lib/features/profile/presentation/profile_screen.dart`; `admin/src/components/account-feature-surface.tsx` | Desktop edit is partial |
| Settings | Sound, haptics, reduced motion, Player11 variant | Persisted locally | Toggles are in-memory only | N/A | N/A | `LIVE` | None on mobile | `mobile/lib/core/settings/app_preferences.dart`; `mobile/lib/features/settings/presentation/settings_screen.dart` | Desktop settings are `EXPERIMENTAL` |
| Settings | Account logout/delete | Real logout and delete-account Edge Function | Logout exists; data-rights page only for deletion | Reviews operational reports | Deletion request + Edge Function | `IMPLEMENTED_NOT_RELEASE_READY` | Production deletion and data-preservation test | `auth_controller.dart`; `supabase/functions/delete-account/index.ts` | `AUTH_REQUIRED` |
| Notifications | Inbox/read state/preferences | Real Supabase data and preference writes | Hard-coded notification list | Real campaign queue form | Tables, delivery records, dispatch function | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | FCM service account, scheduler, device and Production delivery validation | `notification_service.dart`; `notifications_repository.dart`; `dispatch-notifications/index.ts` | `AUTH_REQUIRED`, `NEEDS_DEVICE_TEST` |
| Premium | Plans and entitlement | RevenueCat monthly + annual packages, purchase, restore, status | Static fake monthly price/selection; no checkout | No subscription-management surface | Subscription schema + RevenueCat webhook | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Google Play account/products and real purchase/restore/webhook/device tests | `mobile/lib/core/services/purchase_service.dart`; `revenuecat-webhook/index.ts` | Android SDK key and `premium` entitlement are `OPERATOR_VERIFIED`; `STORE_VERIFICATION_PENDING`, `AUTH_REQUIRED` |
| Premium | Approved benefits | Exclusive categories and ad-free are wired | Copy adds unsupported statistics/tournament options | N/A | Access tier and subscription data | `IMPLEMENTED_NOT_RELEASE_READY` | Remove contradictory desktop copy and validate entitlements | `premium_screen.dart`; `party_setup_screens.dart`; `results_screen.dart` | Approved truth is exactly two benefits |
| Premium | Promotional vouchers | UI/repository exists behind two gates | Fake voucher response in placeholder Store | Admin actions gated | Secure migration/RPCs are deployed | `DEFERRED` | Store-policy approval, both client/server gates, real concurrency/product validation | `app_config.dart`; `20260907000100_premium_vouchers_v1.sql`; `premium-voucher-manager.tsx` | Deployment is `OPERATOR_VERIFIED`; gates remain OFF; `FEATURE_GATED`, `LEGAL_APPROVAL_PENDING` |
| Store | Cosmetics/wallet/inventory | Substantial controller/screens exist but `/store` opens Premium and `/wallet` redirects there | Two static cards, no transaction | Read-only catalog table | Store/wallet/inventory schema + Edge Function | `DEFERRED` | Explicit product approval and route exposure | `mobile/lib/core/routing/app_router.dart`; `mobile/lib/features/store/**`; `wallet-transaction/index.ts` | Coins/Wallet explicitly inactive |
| Ads | Interstitial | Called after solo result and bypassed for Premium | No ads | N/A | N/A | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Physical-device consent, serving/fill, cadence, dismissal and failure validation | `mobile/lib/core/services/ads_service.dart`; `mobile/lib/features/match/presentation/results_screen.dart` | Android CI values and cadence 3 are `OPERATOR_VERIFIED`; `DEVICE_VERIFICATION_PENDING` |
| Ads | Rewarded reward | Service and signed SSV verification exist; only inactive Store would expose the economy use case | None | N/A | `admob-reward` verifies Google ECDSA and claims idempotently | `DEFERRED` | Store activation plus AdMob setup and policy review | `ads_service.dart`; `supabase/functions/admob-reward/index.ts` | Code exists but active user path does not |
| Offline | Drift/cache/local Party | Category/question cache, history, active Party, draft, usage, pending operations | Only local result summaries | N/A | Server remains authority | `LIVE` | Scope is local only | `mobile/lib/core/storage/app_database.dart`; question repositories; `party_game_controller.dart` | No general cloud offline mode |
| Offline | Automatic re-sync on reconnect | No global listener invokes `QuestionReportRepository.syncPending`; connectivity banner is visual | Not implemented | N/A | Pending queue schema only | `NOT_IMPLEMENTED` | Sync orchestrator/retry policy | `mobile/lib/features/support/data/question_report_repository.dart`; `mobile/lib/shared/presentation/connectivity_status_banner.dart` | Documentation currently overclaims this |
| Reporting | Question reports | Online submit plus offline queue | No question-report UI | Read-only report table | Table/RLS | `IMPLEMENTED_NOT_RELEASE_READY` | Auto-sync and admin resolution action | `question_report_repository.dart`; `admin/src/app/(dashboard)/reports/page.tsx` | `AUTH_REQUIRED` |
| Reporting | User problem reports | Real sanitized RPC submission | Real RPC form | Real review/status/note/link workflow | RPC/table/rate limit | `IMPLEMENTED_NOT_RELEASE_READY` | Production E2E | `app_error_reporter.dart`; `account-feature-surface.tsx`; `user-problem-reports.tsx` | `AUTH_REQUIRED` |
| Monitoring | App errors | Sanitized remote reporter | N/A | Error issue review API/UI | Occurrence/issues tables and RPC | `IMPLEMENTED_NOT_RELEASE_READY` | Production ingestion/review validation | `mobile/lib/core/services/app_error_reporter.dart`; `admin/src/app/(dashboard)/errors/page.tsx` | No raw secrets intended |
| Telemetry | Analytics/Crashlytics | Real Firebase wrappers; bootstrap-gated | No equivalent | Operational pages read server data | Firebase external | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Firebase project, consent/policy and real-device verification | `mobile/lib/core/bootstrap/app_bootstrap.dart`; `analytics_service.dart`; `crash_reporter.dart` | `NEEDS_DEVICE_TEST` |
| Online | 1v1/2v2 rooms and matchmaking | Product routes are compatibility tombstones redirecting to Home | Not exposed | Match monitoring only | Tables, RPCs and Edge Functions remain | `DEFERRED` | New product approval and complete E2E | `mobile/lib/core/routing/app_router.dart`; `supabase/functions/create-room`; `join-room`; `queue-matchmaking`; `submit-answer` | Do not call this live online play |
| Desktop | Device policy | Phone UA is rewritten to `/mobile-app`; CSS fallback hides full site below 768px | Full experience on desktop only | Dashboard not rewritten | N/A | `IMPLEMENTED_NOT_RELEASE_READY` | Official App Store/Google Play URLs are absent | `admin/src/proxy.ts`; `admin/src/app/(website)/layout.tsx`; `mobile-app-download.tsx` | `DESKTOP_ONLY`; phone download page works with disabled buttons |
| Desktop | Public site, games catalog, support | N/A | Routes render and Next build passes | N/A | Mostly static | `IMPLEMENTED_NOT_RELEASE_READY` | Deployment and removal of false claims/placeholders | `admin/src/app/(website)/**`; build result in this audit | Public pages exist, but content truth needs correction |
| Desktop | Player auth/recovery/account guard | N/A | Real Supabase login/register/recover/reset and server guards | N/A | Supabase Auth | `IMPLEMENTED_NOT_RELEASE_READY` | Deployed-domain/email flow validation | `player-auth-form.tsx`; `admin/src/lib/auth/player.ts` | `AUTH_REQUIRED` for play/account/tournament mutations |
| Desktop | Gameplay | N/A | Four hard-coded questions per type; all mechanics reduce to choosing an option; result localStorage | N/A | Not used | `EXPERIMENTAL` | Production content/mechanics/backend/session authority | `admin/src/components/play-experience.tsx` | Not parity with mobile or backend |
| Desktop | Account center | N/A | Real shell/guard; profile/report real, friends partial, saved results local, most other sections static/in-memory | N/A | Mixed | `EXPERIMENTAL` | Replace each placeholder with real data or remove it | `account-feature-surface.tsx`; `player-features.ts` | Do not market as feature parity |
| Desktop | Legal center | Mobile opens external configured URLs | Seven real Arabic documents/routes | N/A | N/A | `IMPLEMENTED_NOT_RELEASE_READY` | Named legal owner, entity/contact/effective dates and counsel review | `admin/src/lib/site/legal.ts`; `admin/src/app/(website)/legal/**` | `NEEDS_POLICY_APPROVAL` |
| Admin | Architecture and access | N/A | Same Next app | Dashboard layout requires moderator; APIs enforce role | Profile roles/RLS | `IMPLEMENTED_NOT_RELEASE_READY` | Real staff account/Production role testing | `admin/src/app/(dashboard)/layout.tsx`; `admin/src/lib/auth/context.ts` | Admin and player web are not separate deployments in code |
| Admin | Dashboard/system health/audit | N/A | N/A | Real data reads; explicit development fallback | Metrics, audit log, health probes | `IMPLEMENTED_NOT_RELEASE_READY` | Production DB and operational validation | `admin/src/app/(dashboard)/dashboard`; `system-health`; `audit`; `admin/src/lib/data/admin-data.ts` | `AUTH_REQUIRED` |
| Admin | Users | N/A | N/A | Searchable read-only table | Profile data | `IMPLEMENTED_NOT_RELEASE_READY` | Production validation | `admin/src/app/(dashboard)/users/page.tsx` | No mutation controls |
| Admin | Roles/status management | N/A | N/A | No UI/API for changing roles/status | `set_profile_role`/moderation functions exist | `NOT_IMPLEMENTED` | Approved privileged workflow and audit controls | `users/page.tsx`; `supabase/migrations/**` | Table existence is not admin functionality |
| Admin | Categories/content/branding | N/A | Published content may feed clients | Create/edit/delete/order/draft/publish UI and APIs | Tables/media/RPCs/RLS | `IMPLEMENTED_NOT_RELEASE_READY` | Production content workflow validation | `category-content-editor.tsx`; `branding-center.tsx`; API routes | Moderator/admin role split exists |
| Admin | Questions/options | N/A | N/A | Create, format/options/media, bulk publish/unpublish/archive | Question schema/RPCs/triggers | `IMPLEMENTED_NOT_RELEASE_READY` | Production editorial validation | `question-editor.tsx`; `question-table.tsx`; question APIs | Options are part of editor, not a separate page |
| Admin | CSV/Excel import | N/A | N/A | Parse/preview/commit workbench | Import tables/RPCs/Edge Functions | `IMPLEMENTED_NOT_RELEASE_READY` | Real Production batch/import validation | `import-workbench.tsx`; `/api/import/**`; `supabase/functions/import-*` | Limits and validation exist |
| Admin | Media library | N/A | N/A | Upload/replace/edit/delete UI/API | Storage metadata and rights rules | `IMPLEMENTED_NOT_RELEASE_READY` | Storage bucket, rights, and Production validation | `media-library.tsx`; `/api/media/**`; media migrations | Media rights are enforced in publish paths |
| Admin | Tournaments/matches | N/A | Player create/join separate | Tournament monitoring + cancel/reopen; matches read-only | Tournament/match schema deployed | `IMPLEMENTED_NOT_RELEASE_READY` | Production role/workflow E2E and fuller operations workflow | `tournament-center.tsx`; tournament API; `matches/page.tsx` | Not a full bracket operator console |
| Admin | Social moderation | N/A | N/A | Review reports and moderate teams | Moderation RPCs/audit | `IMPLEMENTED_NOT_RELEASE_READY` | Production RLS/role E2E | `social-moderation-manager.tsx`; `/api/social/moderate` | `AUTH_REQUIRED` |
| Admin | Notification campaigns | N/A | N/A | Queue/schedule campaign and request immediate dispatch | Notification tables + Edge Function | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | FCM service account, dispatch secret/scheduler, delivery validation | `notification-campaign-form.tsx`; `/api/notifications`; `dispatch-notifications` | `NEEDS_PRODUCTION_VALIDATION` |
| Admin | Premium | N/A | Placeholder only | No general subscription/customer management page | Subscription/event schema exists | `NOT_IMPLEMENTED` | Define approved support/management scope | Dashboard route inventory | Vouchers are separate |
| Admin | Vouchers | Gated client entry | Fake desktop form | Secure create/list/disable manager behind policy gate | Voucher migration/RPCs deployed | `DEFERRED` | Policy approval, deliberate gate activation, and real operational validation | `premium-voucher-manager.tsx`; voucher API/migration | Deployment is `OPERATOR_VERIFIED`; gates remain OFF; `FEATURE_GATED`, `LEGAL_APPROVAL_PENDING` |
| Admin | Store | Inactive | Placeholder | Read-only item catalog | Store/economy schema | `DEFERRED` | Product approval and management mutations | `admin/src/app/(dashboard)/store/page.tsx`; store migration | Page description overstates “إدارة” |
| Admin | Reports | Question reports read/queue | User problem report exists | Question reports read-only; user problem reports are actionable | Both report families exist | `IMPLEMENTED_NOT_RELEASE_READY` | Add question-report resolution path; Production E2E | reports pages/components/APIs | Distinguish the two report types |
| Admin | Settings | N/A | Desktop device toggles are separate | Real settings form/API | `game_settings` table | `IMPLEMENTED_NOT_RELEASE_READY` | Production role/audit validation | `settings-form.tsx`; `/api/settings` | `AUTH_REQUIRED` |
| Backend | Migration history | Client code targets latest RPCs | Same backend | Same backend | 27/27 deployed to linked Production; latest `20260908000100` | `IMPLEMENTED_NOT_RELEASE_READY` | Client/device E2E and selected operational/security validation | `supabase/migrations`; operator release-session evidence | `OPERATOR_VERIFIED`; linked lint 0 errors/16 warnings; no repair used |
| Backend | RLS/RPC/security model | Clients use JWT/RPC | Clients use JWT/RLS | Role-guarded APIs | 76 RLS-enable statements, 126 policy declarations, rate limits, fixed search paths in reviewed RPCs | `IMPLEMENTED_NOT_RELEASE_READY` | Real JWT/RLS/direct-DML tests on PostgreSQL | `supabase/migrations/**`; `supabase/tests/**` | Static evidence is positive, not Production approval |
| Backend | Edge Functions | Auth, notification, purchases, reporting clients depend on them | Some flows depend on them | Import/notifications depend on them | 11 functions for rooms, answers, imports, notifications, RevenueCat, AdMob, wallet, deletion | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Per-function deployment/version, secrets, scheduler/provider, and E2E validation | `supabase/functions/**` | Migration deployment evidence does not by itself prove every Edge Function runtime |

## Architecture truth

`admin` is one Next.js application containing two distinct products:

1. Player-facing desktop website under `admin/src/app/(website)` plus `/mobile-app`.
2. Staff dashboard under `admin/src/app/(dashboard)` plus role-protected `/api/*` routes.

They share the Supabase client/configuration and build pipeline. They must be named separately in documentation even though they ship from one codebase.

The Flutter app is the only production-shaped gameplay client. Local Party and solo can operate without authenticated cloud services. Authenticated features use Supabase. Online rooms/matchmaking remain in schema and Edge Functions, but their Flutter routes intentionally redirect to Home.

## Premium product truth

The approved mobile product is:

- **Plans:** monthly and annual only, loaded from the current RevenueCat offering.
- **Benefits:** exclusive categories and ad-free only.
- **Entitlement:** RevenueCat entitlement ID defaults to `premium`; purchase, restore, billing/expiry states, and management URL are implemented.
- **Category access:** free rotation/access tier and Premium checks are implemented in Party category selection.
- **Ad-free:** interstitial display is skipped when Premium access is active.
- **Vouchers:** promotional monthly/annual grants exist in code and the migration is deployed, but both client and server gates remain off. Production activation is explicitly not policy-approved.

The desktop claims for broader statistics, tournament options, account appearance, and store benefits are not approved Premium truth. They are static marketing copy without a corresponding checkout or entitlement enforcement.

## Integration matrix

| Integration | Code integrated | Expected variables/config | Current repository/local evidence | Status / blockers |
|---|---|---|---|---|
| Supabase | Yes, mobile, website, admin, migrations, Edge Functions | `SUPABASE_URL`, `SUPABASE_ANON_KEY`; web public equivalents; service role only in server functions | Operator-verified on 12 September 2026: linked Production matches local 27/27 through `20260908000100`; linked lint 0 errors/16 warnings; no repair used. Repository-only inspection cannot reconstruct the console state | `IMPLEMENTED_NOT_RELEASE_READY`; deployed, with client/device and selected operational/security validation pending |
| Firebase Core | Yes | `FIREBASE_ENABLED`, platform config files | Android Release config injection passed in Codemagic; package `com.ahdash.eleven` and Release certificate fingerprints were verified. iOS was not improved by this evidence | Android `OPERATOR_VERIFIED`; runtime `DEVICE_VERIFICATION_PENDING`; iOS remains externally blocked |
| Google Sign-In | Yes on mobile | `GOOGLE_AUTH_ENABLED`, Firebase OAuth clients, Supabase provider, release SHA | Android Firebase config and Release SHA integration are operator-verified; actual account/device sign-in remains untested here | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `DEVICE_VERIFICATION_PENDING` |
| Apple Sign-In | Redirect code only | `APPLE_AUTH_ENABLED`, Apple/Supabase provider, capability/entitlement | CI does not enable it; entitlements only declare push | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`; currently blocked |
| FCM | Yes, token rotation/inbox/deep-link/dispatch | `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY`, `NOTIFICATION_DISPATCH_SECRET` | Code exists; external values and scheduled dispatch not validated | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `NEEDS_DEVICE_TEST` |
| Crashlytics | Yes | Firebase platform setup and `FIREBASE_ENABLED` | Bootstrap/wrapper exists; no current device event evidence | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `NEEDS_DEVICE_TEST` |
| Analytics | Yes | Firebase project/consent and `FIREBASE_ENABLED` | Event wrapper/calls exist; no Production event evidence | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `NEEDS_DEVICE_TEST` |
| RevenueCat | Yes, including webhook | Platform API keys, `REVENUECAT_ENTITLEMENT_ID`, `REVENUECAT_WEBHOOK_AUTH`, monthly/annual products | Operator-verified Codemagic configuration includes the Android public SDK key and entitlement `premium` for project/app AHDASH &#124; 11 / Play package `com.ahdash.eleven` | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`; Google Play account/products and real purchase/restore/webhook checks remain `STORE_VERIFICATION_PENDING` |
| AdMob | Yes, consent, interstitial, rewarded/SSV | App IDs, unit IDs, interval, reward item | Operator-verified Codemagic `admob` group includes Android app/interstitial/rewarded IDs, `ADMOB_ENABLED=true`, and cadence 3; Production validator passed in the successful Android run | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `DEVICE_VERIFICATION_PENDING` for consent/fill/frequency/dismissal/SSV |
| Google Play | Signed artifact path proven | Play Console app, App Signing/upload key, listing, products, privacy/data safety | Operator-verified signed AAB/APK outputs and intended Release certificate; no Google Play publication or official Play URL yet | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `STORE_VERIFICATION_PENDING` |
| App Store/TestFlight | Workflow exists | App Store Connect integration, signing, Firebase/AdMob/RevenueCat iOS, privacy/store listing | Workflow targets TestFlight, not App Store; external state unknown; Apple auth capability absent | `CONFIGURED_EXTERNAL_SETUP_REQUIRED`, `NEEDS_STORE_SETUP`, `NEEDS_DEVICE_TEST` |
| Codemagic | Yes | secret groups `ahdash_shared`, `firebase`, `revenuecat`, `admob`; signing integrations | Operator-verified successful Android release run on `main` from an earlier known commit: analysis, selected tests, Firebase injection, signing, Production validator and signed AAB passed; signed APK generation was subsequently proven | `OPERATOR_VERIFIED`; current dirty tree remains `CURRENT_TREE_TEST_GATE_FAILING` |

No secret value is included in this report.

## Release and CI truth

### Android

- `android-release` runs `flutter analyze --fatal-infos`.
- It discovers every `*_test.dart` outside `test/visual/**` and runs those tests with coverage.
- It injects `google-services.json` from `FIREBASE_ANDROID_CONFIG`.
- It uses Codemagic signing reference `ahdash11_keystore` and generates `mobile/android/key.properties` in CI.
- Gradle fails closed when release signing or a Production AdMob app ID is missing/test-only.
- It runs `scripts/check-release-integrations.mjs` in Production mode.
- It builds both a signed AAB and a signed APK and publishes them only as Codemagic artifacts.
- There is no Google Play publishing section.

Operator-verified release evidence from 12 September 2026 proves the Android release infrastructure and artifacts from an earlier known commit. The successful Codemagic run was on `main`: static analysis, selected non-visual tests, Firebase injection, Android signing, the Production validator, and signed AAB build passed. A later workflow revision also added and proved signed APK generation. The downloaded AAB SHA-256 is `4456CEBEA870B826D79B670267C3D587E42BA80A39D43FD4C59E089D5EC2D4E4`. Its signing certificate matches the intended Release certificate:

- SHA-1: `1E:25:C3:09:0A:F3:1E:20:54:46:C5:5D:6B:B2:7D:45:17:77:B8:C7`
- SHA-256: `43:47:5F:35:4B:73:F4:D2:C9:AD:45:66:3A:BF:D6:DF:FA:86:25:93:03:F9:1D:1B:2E:D6:A4:93:83:C1:86:47`

Codemagic also has `PRIVACY_POLICY_URL` and `TERMS_URL` in the shared Production environment; the verified privacy URL is `https://ahdash11.shaghafjob.com/privacy-policy`. These facts are `OPERATOR_VERIFIED`; repository-only inspection cannot independently reconstruct provider-console values. The present dirty working tree is a separate state: its Android-CI-equivalent non-visual run fails three tests and must return to green before a new release artifact is accepted. Google Play publication, store setup, physical-device E2E, and final legal/media review remain pending.

### iOS

The `ios-release` workflow configures App Store distribution, injects Firebase, sets AdMob, builds an IPA, and requests TestFlight upload only. It runs unfiltered `flutter test --coverage`, unlike Android, and may include visual tests. It does not enable `APPLE_AUTH_ENABLED`; the current entitlement file contains push entitlement only. No current IPA/TestFlight/device result was available. iOS is not release-ready.

### Pull requests

`pull-request-checks` runs format, analysis, and unfiltered `flutter test`. That differs from Android release and can include the visual suite. This inconsistency should be resolved deliberately, not by regenerating Goldens.

## Test results from this audit

| Layer | Command/scope | Result |
|---|---|---|
| Flutter static analysis | `flutter analyze --fatal-infos` | **PASS** — no issues; 281.6 s |
| Flutter non-visual | Same file selection as Android CI: 74 of 98 test files; 24 visual files excluded | **FAIL** — 580 passed, 3 failed |
| Failure 1 | `guest_routing_test.dart`: guest can use local settings and rules without upgrading | Expected text `الصوت والاهتزاز والحركة` not found |
| Failure 2 | `v10_phase_d_contract_test.dart`: Team Detail omits fake levels, points, and match stats | Source-contract assertion failed |
| Failure 3 | `v10_phase_e_contract_test.dart`: Profile exposes identity/preferences without fake statistics | Source-contract assertion failed |
| Flutter visual/golden | 24 files under `mobile/test/visual` | **NOT RUN** — explicitly excluded; no Goldens regenerated |
| Flutter integration/device | One smoke test in `mobile/integration_test` | **NOT RUN** — no physical device/provider validation |
| Admin typecheck | `npm run typecheck` | **PASS** |
| Admin lint | `npm run lint` | **PASS** |
| Admin unit tests | `npm test` | **PASS** — 12 files, 55 tests |
| Next production build | `npm run build` | **PASS** — route manifest produced successfully |
| SQL parser | `python supabase/tests/parse_migrations.py` | **PASS** — 27 migrations, 146 PL/pgSQL bodies; two pre-existing `_record` catalog warnings |
| Pending security static gate | `pending_security_gate_static.mjs` | **PASS** — 59/59 |
| Registration enum static/embedded | Two existing scripts | **PASS** — 9/9 and 8/8 |
| Tournament embedded behavior | `tournament_v2_behavior.mjs` | **PASS** — 29/29; auth/rate-limit stubs, no real concurrency |
| Voucher embedded behavior | `voucher_postgres_wasm_behavior.mjs` | **PASS** — 11/11; no real multi-connection concurrency |
| Real pgTAP/JWT/RLS/upgrade | Nine SQL suites exist | **NOT RUN** — Supabase CLI/PostgreSQL runtime unavailable |

Android excludes visual tests because Goldens are controlled rendering baselines and the repository has a separate `test/visual` suite; release CI intentionally selects non-visual files. This avoids accidental baseline regeneration or platform-rendering noise. It does not make visual QA optional: it moves it to a separately controlled gate. The iOS and PR workflows currently do not make the same separation.

## Backend truth

- Migration count: **27**. Latest file: `supabase/migrations/20260908000100_fix_review_tournament_registration_enum.sql`.
- Edge Function count: **11** excluding `_shared`: AdMob reward verification, room create/join, account deletion, notification dispatch, import validate/commit, matchmaking, RevenueCat webhook, answer submission, and wallet transaction.
- Schema covers profiles, questions/content/media, matches/rooms, social teams/friends/blocks, tournaments, notifications, subscriptions, store/economy, vouchers, monitoring, reports, and admin/audit data.
- Repository scan finds 76 RLS-enable statements and 126 policy declarations across migration history. These are migration statements, not a claim that 76 distinct deployed tables exist.
- Rate limiting exists in RPCs including tournament creation/registration, voucher redemption, reports, rooms/matches, and economy paths.
- Reviewed sensitive RPCs use `SECURITY DEFINER` with fixed `search_path`, explicit grants/revokes, row locks, idempotency, or compare-and-set where applicable.
- Operator-verified on 12 September 2026: all four newest migrations (`20260902000100`, `20260905000100`, `20260907000100`, `20260908000100`) were successfully deployed to linked Production; local and remote history matched 27/27 and latest was `20260908000100`.
- `db lint --linked` completed with 0 errors and 16 warnings. The historical tournament registration enum issue was fixed through the explicit enum-cast migration. No migration repair was used.
- The earlier `docs/v10_supabase_security_migration_gate/RELEASE_GATE.md` is historical pre-deployment gate evidence and must not be used to claim the migrations are still undeployed.
- Deployment does not prove all live behavior: real client/device E2E and selected operational/security/concurrency validation remain pending. Edge Function deployed versions were not established by the supplied migration evidence.
- Voucher Production gates remain OFF. Deferred Online routes remain deferred.

## Design and brand truth

Approved identity sources:

- Reference package: `brand-package/ahdash_11_brand_package/assets/branding/`.
- Runtime copies: `mobile/assets/branding/` and `admin/public/branding/`.
- Canonical packaged PNGs: `logo-symbol.png`, `logo-wordmark.png`, `logo-horizontal.png`, `app-icon.png`, `brand-pattern.png`, and `brand-guidelines.png`.
- There is no canonical SVG in the package.
- Font: local **Thmanyah Sans** weights 400/500/700/900. Flutter registers only `ThmanyahSans` for current production typography.
- Approved V5 palette centers on paper `#F4EBDD`, surface `#FBF7EF`, ink `#1B1916`, interaction green `#5F8F0F`, limited legacy lime `#B6FF3B`, and achievement/Premium gold `#FFC857`. The runtime tokens are close variants in `mobile/lib/core/theme/app_colors.dart`.
- The Flutter production theme is currently forced to `ThemeMode.light`; a dark theme definition exists but is not active product truth.

`docs/ahdash-brand-v5.md`, `mobile/assets/branding/ASSET_MAP.txt`, and `docs/v9_2_asset_map.md` are the strongest current brand evidence. The many `docs/v8_*`, `docs/v9-screen-audit`, `docs/v10_*_refinement`, `docs/visual-validation`, generated atlases, zipped screen packs, screenshot fixtures, and `mobile/test/visual/goldens` are `EXPERIMENTAL`/`TEST_ONLY` evidence unless an approved handoff explicitly promotes a runtime asset. They are not alternate logos or automatic product approval. Existing uncommitted visual changes were present before this audit and were not touched.

## DOCUMENTATION_CONTRADICTIONS

| Documentation claim | Actual implementation | Evidence | Recommended corrected wording |
|---|---|---|---|
| Mobile account includes recovery | Mobile has no recovery/reset contract or screen; desktop does | `mobile/lib/features/auth/domain/auth_repository.dart`; desktop `player-auth-form.tsx` | “Recovery/reset is available on desktop web; mobile recovery is not implemented.” |
| True/False and Speed are simply “enabled” on mobile | Engines and direct routes work, but current Home/Play UI exposes only Party vs solo and starts classic | `features/play/presentation/play_screen.dart`; `/play/setup/:gameType` route | “Implemented behind direct setup routes; approved discoverable entry is missing.” |
| Desktop has six playable game types and four methods | It has four fixed local questions per type; types mostly reuse multiple-choice mechanics, formats mostly change labels/team score | `admin/src/components/play-experience.tsx` | “Desktop gameplay is an experimental local prototype, not feature parity.” |
| Daily challenge is a current game method | No mobile daily route/controller/persistence or verified backend contract exists | Router and `game_mode.dart` | “Daily challenge is not implemented.” |
| Premium includes wider statistics and tournament options | Approved mobile UI/enforcement contains only exclusive categories and ad-free | `premium_screen.dart`; `purchase_service.dart`; category gate and result ad call | “Premium offers monthly/annual access to exclusive categories and ad-free play.” |
| Mobile Premium and store are one active area | `/store` opens Premium; `/wallet` redirects there; Store/Wallet screens are unreferenced | `mobile/lib/core/routing/app_router.dart`; `mobile/lib/features/store/**` | “Store/Wallet are deferred code and not exposed.” |
| Premium vouchers are a current product feature | UI/schema/admin exist and the schema migration is deployed, but client and server gates remain off and policy approval is explicitly absent | `app_config.dart`; voucher migration; operator deployment evidence | “Voucher schema is deployed; the product remains deferred and feature-gated pending policy approval and deliberate activation.” |
| Mobile automatically re-syncs when connectivity returns | Only a visual connectivity banner and a callable `syncPending()` exist; no global invocation was found | `connectivity_status_banner.dart`; `question_report_repository.dart` | “Local caches persist; automatic pending-operation re-sync is not implemented.” |
| Desktop tournament creation supports knockout, league, and groups | UI stores `format` in `rules_snapshot`, but schema/bracket engine implements knockout only | `tournament-create-form.tsx`; tournament migrations/engine | “Only knockout is implemented; league/groups are UI-only choices.” |
| Desktop championship list shows available tournaments | Cards and filters are hard-coded; filters have no handlers | `admin/src/app/(website)/championships/page.tsx` | “Championship discovery page is a fixture prototype.” |
| Desktop account center contains working ranking, notifications, teams, Premium, store, block list and settings | Most are hard-coded, empty, or in-memory; only profile/report are real, friends is partial, saved results are local | `account-feature-surface.tsx` | Name each live subsection; mark the rest experimental/placeholder. |
| Mobile profile provides image/name/username editing | Current profile is read-only; local Player11 variant is a device preference | `profile_screen.dart`; `profile_controller.dart` | “Profile displays identity/stats; server profile editing is not implemented on mobile.” |
| Admin “users and roles/statuses” implies management | Users page is read-only; no role/status mutation API/UI exists | `admin/src/app/(dashboard)/users/page.tsx`; API inventory | “Admin can inspect users; role/status management is not implemented.” |
| Admin store page manages items/prices/availability | Page is a read-only searchable table | `admin/src/app/(dashboard)/store/page.tsx` | “Admin Store is read-only and deferred with the Store product.” |
| Question reports are reviewable from admin | The page is read-only; user problem reports have the actionable review workflow | `reports/page.tsx`; `user-problem-reports.tsx` | “Question reports can be inspected; resolution action is not implemented.” |
| Website is “without download” and “supports mobile” | Phone UA and narrow screens show only the app-download page | website home; `admin/src/proxy.ts`; website layout | “The full website is desktop-only; phones receive the app-download page.” |
| Site can send users to both stores | Both official store URLs are absent in current local website configuration | `mobile-app-download.tsx`; environment status check | “Store buttons remain ‘coming soon’ until official URLs are configured.” |
| Android section reads as a list of future build requirements only | Codemagic successfully ran the release workflow and produced verified signed artifacts from an earlier known commit | `codemagic.yaml`; operator release-session evidence | “Android release infrastructure and signed AAB/APK are proven; the current tree must restore green tests and store/device gates remain.” |
| iOS readiness follows from a workflow | Workflow exists, but Apple auth is not enabled/capable, external signing/provider state is unknown, tests are unfiltered, App Store submit is false | `codemagic.yaml`; `Runner.entitlements` | “iOS is blocked pending capability, provider, CI, TestFlight/device and store validation.” |
| Backend descriptions say the four newest migrations are blocked or Production state is unknown | Operator release evidence confirms 27/27 migrations deployed through `20260908000100`; linked lint returned 0 errors/16 warnings | Operator release session; migration inventory | “Production schema is operator-verified current; client/device and selected operational/security validation remain pending.” |
| “Admin on desktop” can be read as the player website | Both products live in one Next app but have separate route groups and auth models | `(website)`, `(dashboard)`, auth guards | Always use “Desktop Web” for players and “Admin” for staff. |

## Known blockers

1. Three Android-CI-equivalent Flutter tests fail in the current working tree.
2. The current dirty tree has not been accepted through a new Codemagic artifact; the earlier successful release run does not cover later UI/product changes.
3. Physical-device Production E2E remains pending for auth, tournaments/social, deep links, account deletion, weak networks, push, Analytics, Crashlytics, ads, and purchase/restore.
4. Google Play developer identity/address verification, app/listing, metadata, Data Safety, content rating, release track, monthly/annual products, official Play URL, and review remain incomplete.
5. RevenueCat is configured in Codemagic, but Google Play developer/product completion and real purchase/restore/webhook validation remain pending.
6. AdMob is configured in Codemagic, but consent, live serving/fill, cadence, dismissal/failure, and SSV require physical-device validation.
7. iOS Apple Sign-In capability/provider enablement is absent; green CI, signed IPA/TestFlight/App Store and device proof are absent.
8. Selected real PostgreSQL/JWT/RLS/direct-DML/concurrency and per-Edge-Function Production validation remains to be completed; this is not a request to reapply or repair migrations.
9. FCM dispatch scheduler/service account and real delivery are unverified.
10. Desktop player experience includes material placeholders and unsupported product claims.
11. Legal URLs are configured in Codemagic, but documents still require named ownership, dates/contact details, market-specific review, and final approval.

## Audit limitations

- No product code, test, migration, configuration, CI file, asset, or remote service was changed.
- No Supabase CLI was available in the repository-audit environment. Production migration state is nevertheless operator-verified for the 12 September 2026 release session; repository-only inspection cannot independently reconstruct it. Edge Function version/runtime state remains outside the supplied migration evidence.
- No physical Android/iOS device, store sandbox purchase, OAuth provider, push delivery, or deployed desktop URL was exercised.
- Existing documentation reports and screenshots were treated as supporting evidence only when current source agreed.
- The repository was already heavily dirty, including product code, generated screenshots/Goldens, assets, and the latest guide. Those changes were preserved.
