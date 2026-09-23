# AHDASH | 11 — Deferred and Not-Implemented Roadmap

**Authority:** canonical decision log for deferred/not-yet-approved product work  
**Last verified:** 12 September 2026  
**Product authority:** [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md)

## Rules

- This document records boundaries, not delivery promises.
- No delivery date is approved or implied.
- A table, enum, route, RPC, Edge Function, screen, asset, or prototype does not activate a feature.
- Moving an item out of this document requires an explicit product decision, implementation contract, validation plan, and synchronized update to [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md).
- Design work must follow [08_DESIGN_SYSTEM.md](./08_DESIGN_SYSTEM.md); release work must satisfy [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md) and [09_TESTING_STRATEGY.md](./09_TESTING_STRATEGY.md).

## Deferred decision table

The original decision date is not recorded unless stated. “Verified 12 September 2026” means the status was confirmed on that date, not that delivery was approved.

| Item | Status | Decision date | Prerequisite | Acceptance criteria | Non-goals |
|---|---|---|---|---|---|
| Friends graph | `REMOVED_FROM_ACTIVE_PRODUCT` | Product direction changed 12 Sep 2026 | A new explicit product decision, privacy/moderation contract, navigation approval, and Production E2E | Independently approved player value; discoverable but non-dominant flow; account/privacy/block/report lifecycle; abuse controls; device and backend validation | Retained screen, RPC, schema, fixtures, or notification keys as evidence of support |
| Online matchmaking | `REMOVED_FROM_ACTIVE_PRODUCT` | Product direction changed 12 Sep 2026 | A new explicit product/security/session decision, operational ownership, abuse controls, and network architecture | Discoverable approved flow; authoritative matchmaking/session lifecycle; reconnect/timeout/cancel; RLS/rate-limit/concurrency/device/load validation; monitoring and support runbook | Retained queue/function/schema code is not evidence of launch; do not expose compatibility routes alone |
| 1v1 | `REMOVED_FROM_ACTIVE_PRODUCT` | Product direction changed 12 Sep 2026 | Online matchmaking approval plus complete competitive rules and result authority | Real two-player session, synchronized questions/timers/scores/results, disconnect handling, anti-abuse controls, device E2E | Local solo with a fabricated opponent; relabeling Party; backend tables alone |
| 2v2 | `REMOVED_FROM_ACTIVE_PRODUCT` | Product direction changed 12 Sep 2026 | Online foundation plus team matchmaking, roster, captain, scoring, and moderation decisions | Four-player authoritative session, team lifecycle, reconnect/substitution policy, synchronized results, load/security/device validation | Same-device Party relabeled as online; static team scores |
| Daily Challenge | `NOT_IMPLEMENTED` | Original unknown; verified 12 Sep 2026 | Product rules for daily identity/timezone/content, eligibility, replay, rewards, persistence, and abuse prevention | Discoverable daily flow; authoritative daily selection; timezone/reset rules; persisted completion/result; offline/retry behavior; tests and monitoring | Enum/copy only; reusing ordinary solo without daily guarantees |
| Ordering | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved ordering mechanic, input UX, content model, scoring, and authoring support | Distinct reorder interaction; valid content/editor contract; scoring/timing; RTL/accessibility/device validation | Multiple-choice questions labeled “Ordering” |
| Club Guess | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved clue progression, club dataset/rights, answer handling, scoring, and authoring | Distinct clue/guess flow; licensed data; localized answer variants; editor and gameplay tests | Generic option selection with a new label |
| Eagle Eye | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Licensed Production imagery, observation mechanic, crop/display rules, accessibility alternative, and editor support | Image-first observation flow; rights metadata; responsive media; answer/scoring rules; device/visual/accessibility validation | Text-only or generic multiple-choice prototype; unlicensed generated/borrowed media |
| Store | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Product/economy approval, catalog ownership, pricing/legal/store-policy review, fraud/support model | Discoverable authorized Store; server-authoritative catalog and transactions; inventory reflection; failure/refund/idempotency/security/device validation | Current `/store` Premium destination; Desktop static cards; schema or read-only Admin table alone |
| Wallet | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved Store/economy plus balance ledger, transaction rules, support and reconciliation | Server-authoritative balance/ledger; transaction history; atomic/idempotent operations; recovery/audit/security E2E | Redirect to Store/Premium; client-calculated balance |
| Coins | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved economy purpose, issuance/sink rules, accounting, policy, abuse prevention | Documented source/sink lifecycle; server authority; limits; audit/reconciliation; clear user disclosure | Decorative counters or implied real-money value |
| Inventory | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved items/ownership model, Store/economy, entitlement conflict rules | Durable server-owned inventory; acquisition/use/equip/revoke lifecycle; reconciliation and client E2E | Local-only ownership or schema rows without active product flow |
| Cosmetics | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved cosmetic scope, asset rights/design promotion, inventory/equip model | Approved runtime assets; preview/acquire/equip/unequip; cross-client persistence; accessibility/performance validation | Unapproved generated concepts; cosmetics as hidden Premium benefits |
| Rewarded economy UX | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Approved Store/economy, AdMob policy/consent, reward definition, SSV runtime, abuse controls | Clear opt-in UX; verified ad completion and SSV claim; idempotent reward; failure/cooldown/consent/device tests | Showing rewarded ads without an approved reward economy; client-only rewards |
| Voucher activation | `DEFERRED`; gates OFF | Original unknown; verified 12 Sep 2026 | Store/legal policy approval, operational ownership, support/revocation rules, real security/concurrency validation, explicit gate-change approval | Both gates deliberately enabled under change control; issuance/redemption/expiry/disable/audit E2E; rate-limit/race/support evidence | Deployed migration as launch approval; turning on one gate; replacing store purchase without policy review |
| Desktop parity | `DEFERRED` | Original unknown; verified 12 Sep 2026 | Define approved parity scope and whether each mobile feature should exist on Desktop | Remove fixtures/placeholders or implement approved server-backed flows; distinct game mechanics; tournament lifecycle; account/social/Premium truth; browser/accessibility/security E2E | Treat current four-question prototypes, localStorage results, or static account sections as parity |

## Explicit boundaries

- True/False and Speed are not roadmap items here: they are implemented but lack approved discoverable entries. Their status is owned by [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md).
- Mobile password recovery/reset and mobile server profile editing are `NOT_IMPLEMENTED`; they are current product gaps, not silently scheduled commitments.
- Voucher schema deployment does not change voucher product status. Gates remain OFF.
- Friends and Online backend/client code may remain retained, but approved product routes, navigation, claims, and notifications keep them inactive.
- No item above may be marketed, enabled, or bundled into Premium solely because implementation fragments already exist.
