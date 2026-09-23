# AHDASH | 11 — Player Desktop Web

**Scope:** player-facing routes under `admin/src/app/(website)` only  
**Last verified:** 12 September 2026  
**Product authority:** [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md)  
**Release status:** [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)

## Boundary

Desktop Web is the player-facing portion of the Next.js application. It must not be mixed with the staff Admin documented in [04_ADMIN_PANEL.md](./04_ADMIN_PANEL.md). The full experience is desktop-oriented: phone user agents are rewritten to `/mobile-app`, and narrow-screen layout provides the same download-oriented fallback.

Official App Store and Google Play URLs are not yet available, so phone download actions remain incomplete. A browser build is not evidence of mobile parity or store publication.

## Classification model

- `REAL`: a data-backed, guarded product path exists, subject to its release validation.
- `PARTIAL`: a real path exists, but the user workflow is incomplete.
- `EXPERIMENTAL`: local prototype or fixture that is not production parity.
- `PLACEHOLDER`: static, empty, in-memory, or nonfunctional representation.
- `NOT_IMPLEMENTED`: no production workflow exists for the named capability.
- `NOT_ACTIVE`: retained code may exist, but the website does not expose the capability as a player feature.

## Phase 1 identity and boundary

Website Rebuild Phase 1 aligns the player-facing website with the approved AHDASH identity: Arabic-first and RTL, Thmanyah Sans, warm Paper/Surface composition, Ink structure, interaction green for primary actions, limited legacy lime, Premium gold only for Premium meaning, and approved runtime logo/pattern assets. Player-site components remain separate from the staff Admin shell and dashboard routes.

Phase 1 did not implement gameplay, tournament, or account parity. Website Rebuild Phase 2 now replaces the four-question prototype with real local Party and Solo/Classic flows while preserving the Phase 1 shell and design language. This does not complete tournament, account, provider, or cloud-feature parity.

## Current capability map

| Area | Classification | Current truth |
|---|---|---|
| Public website shell | `REAL` | Approved AHDASH identity, truthful Local Party story, public support/legal pages, desktop navigation, and the phone-download policy render in the Next.js application. |
| Email sign-in and registration | `REAL` | Supabase browser authentication is implemented. Production-domain/account E2E is still a release gate. |
| Password recovery/reset | `REAL` | Recovery email, callback, and reset flow exist on Desktop Web. This does not imply mobile recovery exists. |
| Google sign-in | `PARTIAL` | The website initiates Supabase OAuth with provider `google`, uses the shared PKCE callback, and preserves only safe internal return paths. Supabase/Google console configuration and deployed-domain E2E remain required. |
| Apple sign-in | `PARTIAL` | The website initiates Supabase OAuth with provider `apple` through the same safe callback/session path. Supabase/Apple configuration and deployed-domain E2E remain required. |
| Protected player routing | `REAL` | Account and tournament mutation pages use server-side non-anonymous session guards. Local `/play` is intentionally guest-capable. |
| Problem reporting | `REAL` | Authenticated user problem reports use a real RPC submission path. |
| Profile edit | `PARTIAL` | Name and username updates are real; this is not full cross-platform identity/avatar management. |
| Tournament create | `PARTIAL` | The form calls a real RPC and now exposes knockout only. Full organizer review/draw/bracket/match/result/champion parity is absent. |
| Tournament join | `PARTIAL` | The form calls a real registration RPC but sends an empty roster and lacks the full organizer lifecycle. |
| Party save/resume | `REAL` local | The versioned active Party session is validated and stored in browser localStorage; malformed state is rejected. It is explicitly not cloud sync. |
| Football preferences | `PARTIAL` | A limited hard-coded selection writes a profile field; it is not a complete shared catalog workflow. |
| Legal center | `PARTIAL` | Seven Arabic legal routes exist; final entity/contact/effective-date and counsel review remains. |
| Local Party gameplay | `REAL` local / `PARTIAL` release | Exact six-category setup, two teams, optional player split, three helpers per team, ready state, validated 36-question pack, 6 × 6 board, text/image question rendering, timer, steal, reveal, scoring, undo, local resume, result, and replay use existing Supabase contracts and mobile-compatible rules. Deployed catalog/browser E2E remains. |
| Solo / Classic | `REAL` local / `PARTIAL` release | Category, difficulty, and count setup loads `get_solo_question_pack`; the browser implements a 15-second timer, answer/reveal, base/speed scoring, result, replay, and browser-local personal best. |
| Game-type visibility | `PARTIAL` | Classic is the only active website game entry; True/False and Speed remain non-discoverable until approved, while Ordering, Club Guess, and Eagle Eye remain deferred. |
| Championship discovery | `NOT_IMPLEMENTED` | Fixture cards and inert filters were removed. The public page now exposes only truthful create/join entry information. |
| Premium | `PLACEHOLDER` | The informational surface lists only Monthly/Annual and Exclusive categories/Ad-free. It has no checkout or entitlement enforcement. |
| Deferred/removed account areas | `NOT_ACTIVE` | Friends and Store are not exposed. Ranking, notifications, teams, blocked players, and settings placeholders are hidden pending later parity decisions. |

## Authentication and access

Public users may view marketing, the game catalog, championship entry information, support, legal pages, Local Party, and Solo/Classic. Local gameplay creates a real Supabase anonymous guest session so the existing authenticated content RPCs and their RLS/RPC rules remain authoritative; it is not a fabricated question/data account. `getPlayerContext` rejects anonymous identities, so tournament create/join, the account center, and its child routes still require a non-anonymous account.

## Gameplay limitation

Desktop local Party and Solo/Classic are implemented through browser-safe Supabase adapters and deterministic website-only domain engines. Categories come from published active root `categories`; Party readiness and questions come from `get_party_category_health` and `get_party_question_pack`; Solo content comes from `get_solo_question_pack`, and answers are recorded best-effort through `record_solo_answer`. No service-role code or Production hard-coded question bank enters the client.

Release validation is still partial. During local visual QA on 12 September 2026, the currently connected environment returned no displayable published category rows, so a real full-catalog start-to-result E2E could not be accepted. Board, question, timer, reveal, score, and result compositions were visually checked with test-only browser-state fixtures that cannot reach Production. Deployed catalog population/access, cross-browser/accessibility, interruption/resume, and real user E2E remain required.

## Tournament limitation

Create/join use real RPCs, but the Desktop Web flow does not provide organizer registration review, draw, bracket management, Party-linked matches, result confirmation, or champion completion. The backend implements knockout only, and Website Rebuild Phase 1 removed the unsupported league/group choices and fixture discovery.

## Account-center limitation

Profile update and problem reporting are the strongest real account functions. Tournament entry, browser-local saved previews, and the limited football preference are partial. The account center no longer exposes Friends, Store, or the placeholder ranking/notifications/teams/blocked/settings areas. Premium remains informational only. Later phases must complete or deliberately remove remaining partial areas before a parity claim.

## Product claims that are not allowed

- “Full mobile parity” or equivalent.
- Six production-ready game types or four complete game methods; only Local Party and Solo/Classic are discoverable.
- Live championship discovery; no such discovery is implemented.
- League/group tournament support.
- Premium benefits beyond Exclusive categories and Ad-free.
- Working Store, Wallet, voucher redemption, ranking, notifications, Friends, Online, or team lifecycle based on retained infrastructure or placeholders.
- Phone support for the full site; phones receive the app-download experience.
