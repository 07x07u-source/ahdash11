# Phase 6 — Premium contract

Date: 2026-09-05. Screen 43.

RevenueCatPurchaseService remains authoritative. Current offering monthly/annual packages map to PremiumPlan monthly/yearly; priceString and pricePerMonthString originate in StoreProduct. UI displays the localized price string unchanged, with no fallback price, savings claim, coin balance or pay-to-win benefit. Deterministic prices exist only in test fixtures.

Verified benefit copy is limited to existing Premium content access and suppression of supported interstitial ads. No point multiplier, answer advantage or unsupported cosmetic/statistics entitlement was promised.

PremiumController identifies the current authenticated actor, loads real status and plans, and exposes unavailable/empty/error/current entitlement states. A single auth-future dependency avoids pending-state rebuild loops. In-memory busy guards survive route rebuilds; double purchase/restore is rejected. Purchase returns true only when both store operation and reloaded status confirm access. Cancellation resets busy with no grant. Restore distinguishes entitlement found, none found and error. Status includes active, cancelled-active, billing issue, grace-period and expired semantics supported by the service.

Account changes invalidate Premium view; stale purchase completion cannot update another actor's UI. Party entitlement provider now watches auth and identifies the same actor rather than keeping an account-independent entitlement cache. No local preference stores Premium authority.

Routes: /store uses PremiumScreen; /premium remains canonical support; /wallet redirects to /store. Old StoreScreen is retained inactive, not publicly routed. No social/online migration.

Manual store certification remains required: real sandbox offerings and prices, purchase, cancellation, pending transaction, refund/expiry, restore, background/resume, reinstall and account switching. RevenueCat/store consistency and billing cannot be proven by fake-service tests. The existing service obtains the current package again for purchase; store confirmation remains authoritative if offerings change between display and purchase.
