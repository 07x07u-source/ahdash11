# Voucher Production security smoke

Status: **READ-ONLY SECURITY VERIFICATION PASS**.

Production metadata/configuration checks confirmed:

- `premium_vouchers` and `premium_promotional_entitlements` exist with RLS enabled by the applied migration.
- Both Production gates are exactly false: `premium_vouchers.enabled` and `premium_vouchers.policy_approved`.
- anon and authenticated have no direct SELECT privilege on either sensitive table.
- authenticated has no direct INSERT, UPDATE, or DELETE privilege on either sensitive table.
- anon cannot execute voucher generation, code hashing, or redemption functions.
- authenticated cannot execute the code-hash function.
- Authenticated redemption requires an active user and checks the runtime gate.
- Authenticated admin generation is a security-definer RPC protected by `auth.uid()`, an admin-role check, an explicit non-admin error, and the runtime gate.
- Direct anonymous GET attempts for both sensitive tables returned HTTP 404 without exposing rows.

No voucher was generated, redeemed, disabled, or exposed. No test entitlement was granted. Ordinary-user mutation was not attempted because no dedicated Production test identity was available; its direct table privileges and server-side guards were verified read-only instead.
