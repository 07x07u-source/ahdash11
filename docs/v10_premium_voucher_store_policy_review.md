# AHDASH | 11 — Premium Voucher Store Policy Review

Status: **Production disabled pending formal store-policy approval**  
Reviewed: 2026-09-07

## Decision

The custom server-issued voucher flow implemented in this repository must remain disabled in Production. It unlocks digital Premium benefits (`فئات حصرية` and `بدون إعلانات`), so distributing it as a substitute for store billing can create Apple App Store and Google Play compliance risk.

The implementation is protected by two independent client/admin configuration switches and two server settings. Production redemption must not be enabled until product/legal review approves a compliant distribution scenario:

- `PREMIUM_VOUCHERS_ENABLED=true`
- `PREMIUM_VOUCHERS_POLICY_APPROVED=true` in Production
- `premium_vouchers.enabled=true` on the server
- `premium_vouchers.policy_approved=true` on the server

No switch is enabled by the migration.

## Apple

Apple requires in-app purchase for digital features under App Review Guideline 3.1.1. Apple provides official subscription offer codes, including unique one-time-use codes, with StoreKit/App Store redemption and App Store Connect eligibility controls.

Recommended iOS production path: use Apple subscription offer codes and the system redemption flow instead of the custom voucher RPC unless Apple explicitly approves the intended custom distribution model.

Primary sources:

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Set up subscription offer codes](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes)
- [In-app purchase HIG — Supporting offer codes](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)

## Google Play

Google Play requires Play Billing for paid access to digital content, including ad-free functionality and subscription content. Google provides Play Console promo codes and subscription offers. Google documents subscription promo codes as trials applied through Play Billing; they may require a valid payment method and can auto-renew depending on the configured offer.

Recommended Android production path: use Play Console promo codes, offers, or an approved prepaid-plan mechanism. Do not present the custom voucher flow as an alternate paid checkout.

Primary sources:

- [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738)
- [Google Play Billing promo codes](https://developer.android.com/google/play/billing/promo)
- [About subscriptions and prepaid plans](https://developer.android.com/google/play/billing/subscriptions)

## Custom voucher implementation scope

The local implementation is suitable for security review and controlled non-production evaluation:

- promotional access is non-recurring;
- no price, discount, or renewal claim is shown;
- codes are 96-bit cryptographically random secrets;
- only SHA-256 hashes are stored;
- raw codes are returned once to an authorized admin response and are never written to audit logs;
- redemption requires an authenticated active account;
- `FOR UPDATE` plus a compare-and-set guard makes redemption one-time globally;
- expiry starts at successful redemption using server time;
- the existing two benefits are resolved centrally alongside RevenueCat access;
- no migration or RPC has been deployed by this work.

## Required approval before Production

1. Confirm the distribution scenario with Apple/Google policy specialists.
2. Prefer native store offer-code mechanisms for store-distributed promotions.
3. Review rate limits, incident revocation procedure, support copy, and regional availability.
4. Complete a database/RLS review and deploy the voucher migration independently from other pending migrations.
5. Enable all four gates only after written approval.

This document is a technical product-risk review, not legal advice.
