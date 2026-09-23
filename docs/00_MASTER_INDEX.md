# AHDASH | 11 — Canonical Documentation Index

**Project:** AHDASH | 11  
**Last verified:** 12 September 2026  
**Purpose:** this numbered set is the official documentation entry point for product, engineering, design, operations, and release work.

## Required reading

- Every implementation task must read [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md) before making product decisions.
- Every design task must also read [08_DESIGN_SYSTEM.md](./08_DESIGN_SYSTEM.md).
- Every release task must also read [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md) and [09_TESTING_STRATEGY.md](./09_TESTING_STRATEGY.md).
- Deferred ideas and retained inactive code are governed by [10_ROADMAP_DEFERRED.md](./10_ROADMAP_DEFERRED.md); their existence does not authorize implementation or launch.

## Authority map

| Document | Classification | What it owns |
|---|---|---|
| [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md) | Normative | Primary product authority: platforms, live/gated/deferred/removed features, game modes/types, guest/auth scope, Party, Premium, Ads, tournaments, teams, and safety. |
| [02_MOBILE_APP.md](./02_MOBILE_APP.md) | Normative implementation reference | Current Flutter mobile architecture, routes, access rules, feature flows, persistence, and status by area. |
| [03_DESKTOP_WEB.md](./03_DESKTOP_WEB.md) | Normative implementation reference | Player-facing Desktop Web only, separated into real, partial, experimental, and placeholder capabilities. |
| [04_ADMIN_PANEL.md](./04_ADMIN_PANEL.md) | Normative implementation reference | Staff Admin capabilities, role boundaries, mutations, read-only areas, and operational gaps. |
| [05_BACKEND_SUPABASE.md](./05_BACKEND_SUPABASE.md) | Normative implementation reference | Supabase schema, migration truth, RLS/RPC model, Edge Functions, rate limiting, and validation layers. |
| [06_INTEGRATIONS.md](./06_INTEGRATIONS.md) | Operational | Integration contracts, required variable names, repository/operator evidence, and remaining provider/device/store work. |
| [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md) | Operational authority | The only current release-readiness verdict for Android, iOS, Desktop Web, Admin, and Backend. |
| [08_DESIGN_SYSTEM.md](./08_DESIGN_SYSTEM.md) | Normative design authority | Approved identity, assets, typography, palette, RTL rules, runtime ownership, and asset-promotion lifecycle. |
| [09_TESTING_STRATEGY.md](./09_TESTING_STRATEGY.md) | Operational authority | Test layers, CI suite selection, current gate state, commands, controlled visual policy, and pending validation. |
| [10_ROADMAP_DEFERRED.md](./10_ROADMAP_DEFERRED.md) | Normative decision log | Approved deferred/not-implemented work, prerequisites, acceptance criteria, and non-goals without delivery promises. |

## Product status vocabulary

- `LIVE`: usable as intended without an unresolved dependency inside the stated scope.
- `IMPLEMENTED_NOT_RELEASE_READY`: real implementation exists, but validation, configuration, or release work remains.
- `CONFIGURED_EXTERNAL_SETUP_REQUIRED`: the integration path exists, but provider/platform setup or runtime proof remains.
- `DEFERRED`: intentionally postponed and not a current product feature.
- `REMOVED_FROM_ACTIVE_PRODUCT`: retained code or infrastructure may exist for compatibility, but approved player navigation and product claims must not expose the feature.
- `EXPERIMENTAL`: prototype, fixture, study, or test-only implementation.
- `NOT_IMPLEMENTED`: no end-to-end production implementation exists.
- `UNKNOWN`: available approved evidence cannot establish the state. Do not use this for an operator-verified fact.

## Evidence vocabulary

- `REPO_VERIFIED`: established from current repository source or a recorded current-tree command.
- `OPERATOR_VERIFIED`: established in the verified 12 September 2026 release/provider session; repository-only inspection may not reconstruct the external console state.
- `DEVICE_VERIFICATION_PENDING`: required physical-device behavior is not accepted.
- `STORE_VERIFICATION_PENDING`: store account, products, listing, track, publication, or review is incomplete.
- `LEGAL_APPROVAL_PENDING`: configuration exists, but final legal approval is outstanding.
- `CURRENT_TREE_TEST_GATE_FAILING`: the current dirty working tree fails a required test gate even though an earlier release run may have succeeded.

## Historical and experimental policy

Only the numbered `00–10` set is canonical current documentation. The four reconciled source documents remain preserved as approved source material, not competing authorities:

- [CURRENT_STATE_AUDIT.md](./CURRENT_STATE_AUDIT.md)
- [PRODUCT_TRUTH_DRAFT.md](./PRODUCT_TRUTH_DRAFT.md)
- [RELEASE_STATUS_CURRENT.md](./RELEASE_STATUS_CURRENT.md)
- [DOCUMENTATION_CLEANUP_PLAN.md](./DOCUMENTATION_CLEANUP_PLAN.md)

Old reports, screenshots, Goldens, atlases, generated concepts, and folders whose names contain “final” do not become canonical by filename or age. They are governed by [archive/README.md](./archive/README.md) and may only affect current truth through an explicit review and promotion into the appropriate canonical document.
