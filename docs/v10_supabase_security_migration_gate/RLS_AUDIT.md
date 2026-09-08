# RLS audit

Runtime policy behavior could not be exercised because no local Supabase/PostgreSQL server is available. Results below are **STATIC PASS** unless marked BLOCKED.

## Pending Gameplay tables

| Table | RLS | SELECT | INSERT/UPDATE/DELETE | Bypass assessment |
|---|---|---|---|---|
| `category_collections` | Enabled | anon/authenticated may read active rows; moderators may see inactive | authenticated receives DML privileges, but `category_collections_admin_manage` requires `has_role('admin')` | Normal user write denied by policy; runtime test BLOCKED |
| `gift_codes` | Enabled | only admin via all-policy | authenticated has table DML privileges, all operations require `has_role('admin')` | Normal user cannot read hash/create/update/delete statically; runtime test BLOCKED |
| `gift_redemptions` | Enabled | owner or moderator | no authenticated DML grant/policy | normal user cannot forge redemption directly; runtime test BLOCKED |

Existing `categories`, `questions`, `question_reports` and `user_inventory` remain under earlier RLS. Gameplay adds only safe column privileges to category/report fields. It does not grant direct writes to matches, scores, sessions or helper-consumption authority.

## Tournament tables

All six tables have RLS enabled in `tournaments_v1`.

| Table | Read policy | Direct mutation |
|---|---|---|
| `tournaments` | organizer, public tournament participant/viewer, or moderator | no authenticated DML table grant; admin policy exists but table privilege remains SELECT-only |
| `tournament_teams` | `can_view_tournament` or moderator | SELECT-only |
| `tournament_players` | `can_view_tournament` or moderator | SELECT-only; direct DELETE is explicitly absent in pgTAP contract |
| `tournament_registrations` | requester, organizer, or moderator | SELECT-only |
| `tournament_matches` | `can_view_tournament` or moderator | SELECT-only; direct INSERT is explicitly absent in pgTAP contract |
| `tournament_events` | `can_view_tournament` or moderator | SELECT-only |

Mutations are through SECURITY DEFINER RPCs that derive caller identity and enforce organizer ownership. Actual JWT/RLS matrix execution is BLOCKED.

## Premium Voucher tables

| Table | RLS | Policies | Grants |
|---|---|---|---|
| `premium_vouchers` | Enabled | none, intentionally deny-all | all revoked from public/anon/authenticated |
| `premium_promotional_entitlements` | Enabled | none, intentionally deny-all | all revoked from public/anon/authenticated |

Consequences from source:

- ordinary users cannot list vouchers or read `code_hash`, `created_by`, `redeemed_by`, internal notes or status rows;
- ordinary users cannot insert/update/delete voucher rows;
- ordinary users cannot insert, extend, transfer, duplicate, delete or replace Promo entitlements;
- even administrators use role-checking RPCs instead of direct table reads.

Actual `SET ROLE`/JWT direct SELECT/INSERT/UPDATE/DELETE attempts are BLOCKED until a real local database is available.

## Admin authority trust chain

`auth.uid()` → `profiles.id` → server-managed `profiles.role` → `current_app_role()` → `has_role()` → Admin RPC check.

The user cannot self-promote through the supported client path:

- authenticated users have UPDATE privilege only on named non-privileged profile columns;
- `role` is excluded;
- the `profiles_protect_privileged_fields` trigger rejects direct role/status/XP/rating changes by ordinary roles;
- `set_profile_role` requires an existing `super_admin` and prevents self-demotion.

Catalog-owner identity and live policies remain runtime-verification items.
