# AHDASH | 11 — Home + Premium Design Refinement

## Visual direction

The Home now leads with a layered, rights-safe football composition: pitch geometry, question cards, the number 11, and a short ball path. The main Party action remains dominant. Tournament, Solo, Team Challenge, and Saved Games use distinct visual motifs inside one restrained system.

Premium uses a football-editorial treatment rather than a generic paywall: Paper, Ink, Green, and restrained Gold; original procedural cards and pitch/grid geometry; exactly two approved benefits; two store-backed plans; and separate loading, unavailable, purchasing, and active-entitlement states.

## Product truth

- Production prices are never hardcoded. `PremiumPlan.price` comes from the RevenueCat/Store localized `priceString`.
- The Arabic prices visible in screenshots 06, 07, and 11 are deterministic **test-only Store fixtures** from `test/helpers/phase6_fixture.dart`; production code never imports them.
- No savings percentage, discount, “best value”, or invented benefit is shown.
- The only benefits shown are Premium-only categories and No Ads.
- Existing ad presentation already checks the purchase entitlement before showing an interstitial; this task did not add or deploy ad configuration.
- The locked-category screenshot uses existing visual-test catalog content. In production, real `accessTier` and `freeRotation` metadata determine the lock; premium categories remain discoverable.
- A locked category opens a contextual gate, then “عرض Premium” navigates to the Premium page. It never starts purchase directly.

## Motion and accessibility

The Home/Premium artwork has one finite 950 ms entrance using small card offsets and a short ball-path movement. It does not loop. `MediaQuery.disableAnimations` switches to the complete static frame. Screenshot 05 captures an intermediate frame.

## Required screenshots

1. `home/01_home_signed_in_390x844.png`
2. `home/02_home_compact_360x800.png`
3. `home/03_home_guest_390x844.png`
4. `home/04_home_premium_discovery_390x844.png`
5. `motion_keyframes/05_home_motion_keyframe_390x844.png`
6. `premium/06_premium_monthly_selected_390x844.png`
7. `premium/07_premium_annual_selected_390x844.png`
8. `premium/08_premium_packages_loading_390x844.png`
9. `premium/09_premium_packages_unavailable_390x844.png`
10. `premium/10_premium_active_subscriber_390x844.png`
11. `premium/11_premium_purchase_loading_390x844.png`
12. `premium/12_premium_category_locked_390x844.png`
13. `premium/13_premium_category_gate_390x844.png`
14. `details/14_home_hero.png`
15. `details/15_motion_artwork.png`
16. `details/16_premium_hero.png`
17. `details/17_monthly_annual_selector.png`
18. `details/18_premium_benefits.png`
19. `details/19_subscribe_cta.png`
20. `details/20_premium_category_badge.png`

`before_after/` contains the untouched previous screenshots, the new screenshots, and 1:1 contact sheets. `IMAGE_INVENTORY.tsv` records dimensions and SHA-256 prefixes for verification.

## Scope guardrails

No APK or AAB was built. No Supabase or RevenueCat changes were deployed. Online remains deferred.
