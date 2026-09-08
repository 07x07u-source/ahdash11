# AHDASH | 11 — Premium Voucher Security Review

## Trust boundary

Flutter and Admin are presentation clients. PostgreSQL RPCs are authoritative for voucher generation, role enforcement, one-time redemption, server timestamps, and promotional entitlement creation.

## Secret lifecycle

- Admin RPC generates 12 random bytes with `pgcrypto` (96 bits).
- The display format is six groups of four hexadecimal characters.
- The database stores only a normalized SHA-256 hash.
- The raw code is returned once from the creation RPC.
- Audit records include type, quantity, voucher ID, and expiry only—never the raw code or hash.

## One-time and concurrency control

`redeem_premium_voucher(text)` selects the matching voucher `FOR UPDATE`. Under concurrent calls, the second transaction waits, observes `redeemed_at`, and returns `used`. The update also includes `redeemed_at is null` as a compare-and-set guard, and `premium_promotional_entitlements.voucher_id` is unique as defense in depth.

## Authorization

- Anonymous execution is revoked.
- Redemption derives identity from `auth.uid()` through `require_active_user()`.
- Admin generation/list/disable functions check `has_role('admin')` inside the database.
- Direct table privileges are revoked for `anon` and `authenticated`.
- Admin HTTP routes independently require the `admin` role.

## Abuse resistance

- Eight attempts per account per hour through the existing atomic rate-limit helper.
- Fixed-length high-entropy codes.
- Safe response states do not reveal partial matches.
- Device time is ignored.
- Unused vouchers alone can be disabled.
- Redemption and production UI are feature-gated and disabled by default.

## Entitlement semantics

- Monthly promo: `redeemed_at + interval '1 month'`.
- Annual promo: `redeemed_at + interval '1 year'`.
- Both are non-recurring.
- Store and promotional access are combined by one Flutter resolver.
- Existing benefits remain `فئات حصرية` and `بدون إعلانات` only.
