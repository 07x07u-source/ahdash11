# AHDASH | 11 — Staff Admin Panel

**Scope:** staff routes under `admin/src/app/(dashboard)` and protected routes under `admin/src/app/api`  
**Last verified:** 12 September 2026  
**Product authority:** [01_PRODUCT_TRUTH.md](./01_PRODUCT_TRUTH.md)  
**Backend authority:** [05_BACKEND_SUPABASE.md](./05_BACKEND_SUPABASE.md)  
**Release status:** [07_RELEASE_STATUS.md](./07_RELEASE_STATUS.md)

## Boundary and access model

Admin is the staff-only operational product inside the shared Next.js application. It is separate from player-facing Desktop Web. Dashboard pages require a moderator-or-higher server-side session, and APIs independently enforce role checks. Individual destructive or privileged mutations may require Admin even when a Moderator may read the page.

The table documents exposed Admin UI/API capability only. Backend tables or RPCs do not count as Admin capability unless a guarded staff workflow exposes them.

Capability values:

- **Yes:** an Admin UI/API path exists.
- **Limited:** only the noted subset exists.
- **Read-only:** inspection exists without the mutation.
- **Gated:** code exists but product/policy gates keep it inactive.
- **No:** no corresponding Admin UI/API capability.

## Capability table

| Feature | Read | Create | Update | Delete | Publish/Dispatch | Minimum role | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| Dashboard metrics | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Real data reads with an explicit development fallback; Production data validation pending. |
| System health | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Operational probes require Production verification. |
| Audit log | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Capture/completeness and staff-role behavior require validation. |
| Users | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Searchable read-only user table. |
| Roles/status management | No | No | No | No | No | N/A | `NOT_IMPLEMENTED` | Backend functions do not create an Admin UI/API workflow. |
| Categories/content/branding | Yes | Yes | Yes | Yes | Yes | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Draft/order/publish workflows exist; Production editorial validation pending. |
| Questions/options | Yes | Yes | Yes | Limited | Yes | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Supports format/options/media and bulk publish/unpublish/archive. Archive is not represented as destructive deletion. |
| CSV/Excel import | Yes | Yes | Limited | No | Commit | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Parse/preview/commit paths exist; Production batch/failure validation pending. |
| Media library | Yes | Yes | Yes | Yes | Limited | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Upload/replace/edit/delete exists; storage buckets, rights, and failure recovery require validation. |
| Party helpers/settings | Yes | Yes | Yes | Yes | Yes | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Data-backed configuration UI/API exists. |
| Tournament monitoring | Yes | No | Limited | No | No | Moderator; Admin for guarded action | `IMPLEMENTED_NOT_RELEASE_READY` | Cancel/reopen is available; this is not a full bracket operator console. |
| Matches | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Read-only. |
| Social moderation | Yes | No | Yes | No | No | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Report review/team moderation paths exist; role/RLS E2E pending. |
| Notification campaigns | Yes | Yes | Limited | No | Yes | Moderator; Admin where guarded | `CONFIGURED_EXTERNAL_SETUP_REQUIRED` | Queue/schedule/immediate dispatch path exists; FCM, secret, scheduler, delivery monitoring, and real send validation remain. |
| App errors | Yes | No | Yes | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Issue/occurrence review and status workflow exist; ingestion validation pending. |
| Question reports | Yes | No | No | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Read-only; resolution action is not implemented. |
| User problem reports | Yes | No | Yes | No | No | Moderator | `IMPLEMENTED_NOT_RELEASE_READY` | Actionable status, note, and linkage workflow exists. |
| Football data | Yes | Yes | Yes | Limited | Limited | Moderator; Admin where guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Operational data tools exist; rights/source and Production validation remain. |
| Admin settings | Yes | No | Yes | No | No | Admin where mutation is guarded | `IMPLEMENTED_NOT_RELEASE_READY` | Backed by game settings; role/audit behavior requires Production testing. |
| Premium subscription management | No | No | No | No | No | N/A | `NOT_IMPLEMENTED` | No general subscription/customer-support surface. |
| Premium vouchers | Gated | Gated | Gated disable | No | No | Admin | `DEFERRED` | Schema is deployed, but product and policy gates remain OFF. Do not count as live. |
| Store catalog | Yes | No | No | No | No | Moderator | `DEFERRED` | Read-only even if older copy says “manage”; Store product itself is deferred. |

## Read-only truth

The following areas must be described as read-only unless the Admin UI/API changes and is approved:

- Users.
- Matches.
- Store catalog.
- Question reports.

Roles/status management is not merely read-only; it is `NOT_IMPLEMENTED` in the Admin UI/API.

## Actionable operations

The strongest mutation workflows are content/categories/questions, imports, media, Party configuration, social moderation, notification campaign queuing/dispatch requests, user problem report handling, app-error triage, and settings. Their existence does not waive Production role, RLS, audit, failure-recovery, or provider validation.

## Deferred and absent operations

- Vouchers remain `DEFERRED` and gated OFF despite deployed schema support.
- Store is read-only and follows the deferred Store product decision.
- General Premium subscription/customer management is `NOT_IMPLEMENTED`.
- Matches are not editable.
- Tournament operations are limited to monitoring and cancel/reopen; they are not a complete organizer/bracket console.
- Question reports lack an Admin resolution action; user problem reports are the actionable report family.
