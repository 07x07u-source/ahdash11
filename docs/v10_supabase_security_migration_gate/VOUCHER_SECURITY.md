# Premium Voucher security review

Exact migration: `20260907000100_premium_vouchers_v1.sql`.

## Secret lifecycle and entropy

- Generator: `extensions.gen_random_bytes(12)` = 96 cryptographically random bits.
- Encoding: uppercase hexadecimal, 24 characters, displayed as six 4-character groups.
- No timestamp, sequence, user id, admin id or predictable prefix contributes to the secret.
- Database stores only lowercase 64-hex SHA-256 in unique `code_hash`.
- Raw code exists only in the one-time `admin_create_premium_vouchers` return value; it is not inserted into tables or audit logs.
- Admin list never returns raw codes or hashes. Admin POST source contains no console/debug/error logging of response codes.

Repository-wide logging search found no voucher raw-code logging. The only raw display is the intentional one-time Admin response/UI state.

## Canonical normalization

Database and Flutter both:

1. trim outer whitespace;
2. uppercase ASCII letters;
3. remove every non-ASCII alphanumeric character;
4. require exactly 24 normalized characters before lookup.

Canonical generated alphabet is `0-9A-F`; input accepts `A-Z` but only generated hex secrets can match a stored hash. Spaces, hyphens, paste whitespace and RTL/LTR marks are representation-only and normalize to the same secret. This intentionally does not reduce generator entropy or create a collision beyond those equivalent representations.

Embedded check confirmed: `AB12-cd34 EF56-7890-ABCD-EF12` with RTL/LTR marks normalizes to `AB12CD34EF567890ABCDEF12`.

## One-time atomic redemption

Static transaction path:

1. server authenticates active profile;
2. increments account/hour rate bucket;
3. requires both server feature flags;
4. validates normalized length;
5. locates hash and locks voucher `FOR UPDATE`;
6. checks disabled/used/deadline;
7. calculates duration from `clock_timestamp()`;
8. updates only where `redeemed_at is null`;
9. inserts a unique `voucher_id` entitlement;
10. inserts hash-free audit row and returns product state.

All steps execute in one PostgreSQL function statement/transaction. A later insert/audit failure rolls back the voucher update. PostgreSQL/WASM verified the representative rollback and uniqueness constraints. Real two-session execution remains BLOCKED.

## Authorization and least privilege

- unauthenticated redemption is rejected by `require_active_user`;
- normal users can invoke only redemption and own-access resolvers, not tables;
- create/list/disable require database `has_role('admin')`;
- raw hashes and entitlement rows are deny-all to public/anon/authenticated;
- Promo entitlements cannot be forged through direct DML from an ordinary user.

These are static/pgTAP assertions; real JWT/RLS execution remains BLOCKED.

## Time and duration

- Redemption timestamp and expiry use database `clock_timestamp()`, never Flutter/browser/device time.
- Monthly: `redeemed_at + interval '1 month'`, not 30 days.
- Annual: `redeemed_at + interval '1 year'`, not 365 days.
- PostgreSQL/WASM boundary results:
  - 2025-01-31 + 1 month → 2025-02-28
  - 2024-01-31 + 1 month → 2024-02-29
  - 2025-02-28 + 1 month → 2025-03-28
  - 2025-03-31 + 1 month → 2025-04-30
  - 2024-02-29 + 1 year → 2025-02-28

## Rate limit and oracle

- Intended and implemented bucket: account id + `redeem_premium_voucher`, maximum 8 in a rolling fixed one-hour window.
- Shared database row makes reinstall, storage clearing, device changes and client clock changes irrelevant.
- The primary brute-force defense remains 96-bit entropy. Residual risk is distributed multi-account traffic; no unnecessary anti-abuse system was added.
- Product states are `invalid`, `disabled`, `used`, `expired`, `redeemed`. There are no partial-match/hash/id/internal-exception details. Real attempts 1–9, window reset and concurrent multi-device behavior remain BLOCKED pending real DB.

## Disable behavior

Admin can disable only a voucher that is unused and not already disabled. Disabled vouchers cannot pass redemption. Used entitlement revocation is intentionally unsupported; disabling does not silently revoke an existing entitlement.

## Feature gates and store policy

- Flutter names: `PREMIUM_VOUCHERS_ENABLED`, `PREMIUM_VOUCHERS_POLICY_APPROVED`.
- Admin names: the same environment variables; Production requires both.
- Server names: `premium_vouchers.enabled`, `premium_vouchers.policy_approved`.
- Both server values are inserted as private `false`; missing/null values coalesce false. Malformed values error closed rather than enabling.
- Custom Voucher Production activation is **NOT APPROVED**.

## Central Premium resolver

Authoritative client truth is `storeStatus.hasAccess || promotional.isActiveAt(serverExpiry)`.

Scenarios covered by Flutter tests:

- neither source → locked and ads allowed;
- store only → open and ads suppressed;
- active Promo only → open and ads suppressed;
- both → open and ads suppressed;
- expired Promo/no store → locked and ads allowed;
- expired Promo/active store → open through store;
- missing Promo expiry → fails closed.

Party Premium categories and result-screen ad suppression consume `premiumAccessProvider`. No production direct RevenueCat entitlement bypass was found outside the purchase service/controller.

## Fixed issue

**HIGH — resolved locally:** cached Promo `active=true` previously ignored elapsed `expires_at`. The domain now checks expiry on every read, the provider invalidates itself at expiry, and the app invalidates Premium access on resume. App reopen already builds a fresh provider container. No visual or SQL change was required.
