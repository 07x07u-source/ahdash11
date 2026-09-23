# AHDASH | 11 — Documentation Archive Policy

**Last verified:** 12 September 2026  
**Canonical index:** [../00_MASTER_INDEX.md](../00_MASTER_INDEX.md)

## Purpose

This file defines archive classification only. No document, screenshot, Golden, study, report, ZIP, or folder has been moved or deleted as part of creating this policy.

## Classifications

### `HISTORICAL_EVIDENCE`

Material that truthfully records a specific past commit, build, test run, release session, provider state, or dated decision. It remains valid only for that stated scope and date unless current canonical documentation explicitly carries it forward.

Examples include dated release reports, old audit outputs, physical-device reports, and the pre-deployment Supabase release gate. A historical report must not override later operator-verified evidence.

### `EXPERIMENTAL_NOT_APPROVED`

A prototype, fixture, design study, generated concept, UI exploration, unused source path, or validation artifact that has not received explicit product/design/runtime approval.

Its existence is not a feature commitment, release claim, design authority, or permission to expose it in navigation.

### `REJECTED_DO_NOT_REUSE`

An explicitly rejected creative or product direction. Preserve enough metadata to identify the rejected scope, reason, and decision date when known. Do not reuse, remix, or promote it without a new explicit decision.

Rejected Direction A, Direction B, and Direction C belong to this class and are not approved design sources.

## Evidence rules

- A file or folder name containing “final” does not make it canonical or approved.
- Goldens are testing evidence and are governed by [../09_TESTING_STRATEGY.md](../09_TESTING_STRATEGY.md).
- Screenshots and UI atlases are visual evidence, not product or design authority.
- Historical release reports are evidence only for their specific commit/date/session.
- Generated design studies, concepts, and temporary images are not approved unless explicitly promoted through [../08_DESIGN_SYSTEM.md](../08_DESIGN_SYSTEM.md).
- Demo rows, fixture data, and screenshot content do not prove live Production data.
- Retained code or schema for a deferred feature does not make the feature active.

## Canonical promotion

Archived material may influence current work only through an explicit review by the appropriate owner. Approved product truth must be recorded in [../01_PRODUCT_TRUTH.md](../01_PRODUCT_TRUTH.md); approved design must complete the lifecycle in [../08_DESIGN_SYSTEM.md](../08_DESIGN_SYSTEM.md); current release evidence must be recorded in [../07_RELEASE_STATUS.md](../07_RELEASE_STATUS.md).

Moving, renaming, archiving, or deleting existing material requires a separate reviewed documentation change. This policy performs none of those actions.
