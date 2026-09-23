# AHDASH | 11 — Documentation Cleanup Plan

**Plan date:** 12 September 2026  
**Scope:** documentation reorganization only. No files are moved, renamed, merged, archived, or deleted by this audit.

## Objective

Create a small, navigable documentation set in which product truth is separated from architecture, implementation detail, release evidence, experiments, and historical design work. The future hierarchy must prevent a route, enum, table, screenshot, or old passing report from being mistaken for a live product feature.

## Authority rules

1. Runtime source and verified deployed-state/operator evidence outrank prose. Provider-console facts may be `OPERATOR_VERIFIED` even when repository-only inspection cannot reconstruct them.
2. `01_PRODUCT_TRUTH.md` owns feature availability, approved Premium benefits, guest/auth scope, and deferred features.
3. Platform documents own implementation detail, not product-status definitions.
4. `07_RELEASE_STATUS.md` owns current release gates and must be date-stamped.
5. `08_DESIGN_SYSTEM.md` owns approved brand/runtime design; studies and Goldens are evidence, not authority.
6. `09_TESTING_STRATEGY.md` owns commands, suite boundaries, counts, and CI selection.
7. Historical reports must carry a visible “historical evidence—not current status” banner after reorganization. A dated successful release run remains valid evidence for that commit even when the later working tree fails.
8. Never duplicate volatile facts such as test counts, provider readiness, migration deployment, or store status across multiple authoritative documents; link to the owning document.

## Proposed documentation set

| Document | Purpose | Existing material to feed it | Must not duplicate | Source of truth |
|---|---|---|---|---|
| `00_MASTER_INDEX.md` | One-page map for product, engineering, operations, design, and history; shows document owner and last verified date | `docs/AHDASH11_MOBILE_DESKTOP_COMPLETE_GUIDE.md`; current docs directory inventory; this cleanup plan | Feature matrices, architecture detail, commands, long release blockers | Links and metadata only; validate every linked canonical file exists |
| `01_PRODUCT_TRUTH.md` | Concise answer to what exists, works, is gated, deferred, experimental, and approved | `docs/PRODUCT_TRUTH_DRAFT.md`; `docs/CURRENT_STATE_AUDIT.md`; `docs/ahdash-party-game-product-spec.md`; current source | Implementation walkthroughs, SQL/API catalogs, test logs, design measurements | Product owner approval plus current routes/controllers/enforcement code |
| `02_MOBILE_APP.md` | Flutter architecture and feature flows: bootstrap, routing, auth, guest policy, Party, solo, tournaments, social, persistence, notifications, Premium, errors | `docs/architecture.md`; current guide mobile sections; Party/profile/auth reports that still match code | Product availability wording owned by `01`; release/provider state owned by `06/07`; raw screenshot catalogs | `mobile/lib`, `mobile/pubspec.yaml`, Android/iOS runner configs |
| `03_DESKTOP_WEB.md` | Player-facing desktop website only: public routes, player auth, gameplay, championship and account surfaces, phone-download policy | Current guide computer sections; `admin/src/app/(website)`; relevant site CSS/components | Staff/Admin content; unsupported parity claims; release status | `admin/src/app/(website)`, `admin/src/components` player/site files, `admin/src/lib/auth/player.ts`, `admin/src/proxy.ts` |
| `04_ADMIN_PANEL.md` | Staff dashboard routes, roles, data sources, mutation permissions, operational workflows, and known UI-only/read-only gaps | `docs/admin-operations.md` if present; current guide admin sections; current audit; API inventory | Player website routes; backend DDL detail; claims that a read-only table is management | `admin/src/app/(dashboard)`, `admin/src/app/api`, `admin/src/lib/auth/context.ts`, Admin tests |
| `05_BACKEND_SUPABASE.md` | Database domains, migration order, RLS/RPC design, Edge Functions, deployment compatibility, and post-deployment validation | `docs/database.md`; `docs/security.md`; `docs/v10_supabase_security_migration_gate/*`; migration inventory/dependencies; operator-verified 27/27 deployment evidence | Provider setup steps owned by `06`; current release verdict owned by `07`; feature marketing | `supabase/migrations`, `supabase/functions`, `supabase/tests`, authorized deployed-schema/operator evidence |
| `06_INTEGRATIONS.md` | Contract and setup checklist for Supabase, Firebase/FCM/Analytics/Crashlytics, Google/Apple auth, RevenueCat, AdMob, Codemagic, and store consoles | `docs/deployment.md`; environment examples; validator; integration portions of release reports; dated operator evidence | Secret values; current release verdict; feature benefits | Configuration code, `scripts/check-release-integrations.mjs`, `codemagic.yaml`, dated provider-console/operator evidence maintained outside Git |
| `07_RELEASE_STATUS.md` | The only current platform readiness page: Android, iOS, Desktop, Admin, Backend; exact blockers and last evidence | `docs/RELEASE_STATUS_CURRENT.md`; signed-build reports; latest CI run links; post-deployment validation evidence | Architecture summaries, roadmap, superseded artifact hashes | Green CI artifacts, Production validator output, device/store/backend evidence, explicit approvals, and clearly dated operator attestations |
| `08_DESIGN_SYSTEM.md` | Approved identity, logo files, palette, typography, tokens, asset rights, component rules, and promotion process for new assets | `docs/ahdash-brand-v5.md`; `docs/assets.md`; `docs/v9_2_asset_map.md`; `mobile/assets/branding/ASSET_MAP.txt`; pictogram docs | Screen-by-screen audit history, rejected concepts, Goldens, whole UI atlases | Reference brand package, byte-matched runtime branding, current theme/token/font source |
| `09_TESTING_STRATEGY.md` | Suite taxonomy, exact safe commands, CI selection, visual environment, device matrix, database gate, ownership and required evidence | `docs/qa-matrix.md`; current audit results; `codemagic.yaml`; `scripts/verify.ps1`; Supabase gate docs | Product status and release verdict; stale pass counts | Test directories, CI commands, current run artifacts, approved device/backend test plans |
| `10_ROADMAP_DEFERRED.md` | Approved backlog only: online, inactive game types, Store/economy, vouchers, desktop parity and other deferred work | `docs/v8-open-decisions.md`; current audit; explicitly approved roadmap decisions | Current live features, speculative benefits, unapproved concept art as commitments | Product-owner decisions with date, owner, dependency and acceptance criteria |

## Proposed content ownership

### `00_MASTER_INDEX.md`

Keep it under roughly two pages. For every canonical document list purpose, owner, last verified date, and whether it is normative or operational. Add a separate “Historical and experimental archive” link; do not enumerate hundreds of images.

### `01_PRODUCT_TRUTH.md`

Promote `PRODUCT_TRUTH_DRAFT.md` only after product review. Preserve the exact status vocabulary. It should contain no code walkthrough and no environment values. Premium truth must remain monthly/annual plus exclusive categories/ad-free unless product enforcement and approval change together.

### `02_MOBILE_APP.md`

Document the actual current entry points. Explicitly say that current Play/Home navigation exposes Party and classic solo, while True/False and Speed have direct setup implementations but no discoverable entry. Keep guest policy and route table aligned with `GuestCapabilityPolicy` and `app_router.dart`. Treat Store/Wallet and online screen source as retained/deferred code.

### `03_DESKTOP_WEB.md`

Separate routes into public, auth, protected real functions, partial functions, and prototypes. The desktop gameplay fixture and hard-coded championship/account data must never be documented as parity. State the phone rewrite/CSS behavior and official store-link dependency.

### `04_ADMIN_PANEL.md`

Use a capability table with read/create/update/delete/publish/dispatch permissions and minimum roles. Mark Users, Matches, Store, and Question Reports as read-only where that remains true. Do not infer a workflow from a backend function unless a guarded Admin UI/API exposes it.

### `05_BACKEND_SUPABASE.md`

Link to an automatically produced migration/RPC/policy inventory rather than hand-copying all names. Keep separate “repository latest,” “operator-verified deployed latest,” and “last independently queried” fields. As reconciled on 12 September 2026, deployed latest is operator-verified as `20260908000100` with 27/27 history and linked lint at 0 errors/16 warnings; do not regress it to `UNKNOWN` merely because a later repository-only session lacks provider access. Add real PostgreSQL/client/security validation results only after authorized runs. Do not overwrite immutable migration history, reapply the four newest migrations, or recommend migration repair.

### `06_INTEGRATIONS.md`

For every provider record: owner, environments, variable names only, console setup, callback URLs, application IDs, validation command, device scenario, failure mode, evidence source/date, and rotation/runbook link. Distinguish local-workstation configuration from Codemagic groups so a missing local value does not erase operator-verified CI configuration. Never store tokens, private keys, webhook secrets, or keystore passwords in docs.

### `07_RELEASE_STATUS.md`

Replace `RELEASE_STATUS_CURRENT.md` only after review. Every status must be `READY`, `PARTIALLY READY`, or `BLOCKED`; every blocker must identify an exact test, variable, console object, approval, deployed migration, or device case. Preserve the distinction between the operator-verified earlier Android release and the failing later dirty tree. Link immutable CI/build evidence when available; retain a dated operator attestation when repository evidence alone cannot reconstruct the provider state.

### `08_DESIGN_SYSTEM.md`

Name the reference package and runtime copies, including hashes where useful. Record that the current Flutter production theme is Light. Define a promotion rule: study → reviewed asset → approved source → optimized runtime copy → visual/accessibility test. A screenshot or generated asset cannot approve itself.

### `09_TESTING_STRATEGY.md`

Separate:

1. Static analysis/format.
2. Non-visual unit/widget tests.
3. Visual/Golden tests under a controlled renderer.
4. Integration/device tests.
5. Admin type/lint/unit/build checks.
6. Database parser/static/embedded/pgTAP/concurrency tests.

Document the exact Android file-selection command. Resolve deliberately that iOS and PR workflows currently run unfiltered Flutter tests while Android excludes `test/visual`. Never solve a failing visual gate by silently regenerating Goldens.

### `10_ROADMAP_DEFERRED.md`

Each entry needs a status, owner, decision date, prerequisite, acceptance criteria, and explicit non-goals. Do not include feature ideas merely because tables, enums, screens, or art exist.

## Historical and experimental material

After the canonical set is approved, create an archive index and classify—but do not immediately delete—the following:

- `docs/v8_*`: decision studies and open questions.
- `docs/v9-screen-audit`, other `docs/v9-*`, and `docs/visual-validation`: design/measurement evidence.
- `docs/v10_*_refinement`, `docs/v10_*_final`, complete UI atlases, screen ZIPs, and screenshot sets: iteration handoffs or generated validation artifacts.
- Older `release-report*`, Party execution reports, and physical/playtest reports: dated historical evidence only.
- `docs/v10_supabase_security_migration_gate/RELEASE_GATE.md`: historical pre-deployment gate evidence; it must not override the operator-verified 27/27 Production history after deployment.
- `mobile/test/visual/goldens`: test baselines, not brand/product documentation.
- Unused Store/coin assets and concept imagery: runtime/deferred asset inventory, not a current feature promise.

Use three archive labels:

- `HISTORICAL_EVIDENCE`: true for a past commit/build only.
- `EXPERIMENTAL_NOT_APPROVED`: study/prototype not approved for runtime.
- `REJECTED_DO_NOT_REUSE`: explicitly rejected direction with the reason and decision date.

Do not label all `v10_*_final` folders as approved merely because “final” appears in the name. Approval must trace to the canonical Design System and current runtime use.

## Contradiction-prevention checks

Before accepting future documentation changes, automatically or manually check:

- Active routes versus documented features.
- Discoverable navigation versus direct/deep-link-only routes.
- Enum presence versus a completable flow.
- Premium copy versus entitlement/category/ad enforcement.
- `/store` and `/wallet` route destinations versus Store claims.
- Guest claims versus `GuestCapabilityPolicy` and server guards.
- Desktop data sources for hard-coded arrays/localStorage.
- Admin mutation APIs versus read-only pages.
- Repository migration latest versus deployed migration latest.
- Android/iOS/PR CI test selections.
- Official store links versus “download now” copy.
- Current green test/CI evidence versus historical release reports.
- Repository-only evidence versus dated `OPERATOR_VERIFIED` provider/deployment facts.
- Deployed schema versus fully E2E-validated clients and Edge Functions.
- Local workstation validator gaps versus Codemagic secret-group configuration.

## Suggested migration sequence

1. Review and approve the reconciled `PRODUCT_TRUTH_DRAFT.md` with Product, Engineering, Design, Legal, and Operations owners.
2. Resolve factual errors in user-facing website/guide copy before promoting it into canonical docs.
3. Create `00_MASTER_INDEX.md` and the ten empty canonical headings with owners.
4. Promote the approved Product Truth and current Release Status first, preserving the 27/27 Production deployment and signed Android artifact evidence without implying full E2E/store readiness.
5. Consolidate Mobile, Desktop Web, Admin, and Backend details from current source and only still-valid historical docs.
6. Consolidate Integration and Testing commands; validate them in a clean environment and record local, CI, device, provider-console, and store evidence as separate layers.
7. Consolidate Design System and record hashes/promotion rules.
8. Move explicit deferred decisions into the Roadmap; remove them from current-feature lists.
9. Add archive banners/indexes to historical reports and studies.
10. Only after link checking and stakeholder sign-off, propose deletion of exact duplicate/generated documentation in a separate, reviewed change.

## What this plan intentionally does not do

- It does not modify or delete the current comprehensive guide.
- It does not declare experimental assets rejected without an explicit decision.
- It does not move files or rewrite history.
- It does not update tests, Goldens, code, migrations, CI, secrets, or provider settings.
- It does not turn the audit's next actions into implementation work.
