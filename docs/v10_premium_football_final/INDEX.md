# 19 — Football preferences / 20 — Premium

Final visual review for the V10 Arabic mobile surfaces.

## Football preferences

- A two-step league/club flow with published league and club identity data.
- Search, clear, empty, loading, retry, save feedback, and public-visibility states.
- A compact keyboard presentation that keeps search and save reachable.
- Verified at 360–430 px widths and text scales up to 1.3.

## Premium

- A restrained black/gold/green membership identity with shorter copy.
- Store-backed monthly/yearly plan cards with clear selection and a fixed purchase dock.
- Active, loading, unavailable, purchase-in-progress, voucher, and restore states.
- No fabricated fallback prices and no changes to purchase business logic.

## Verification

- `flutter analyze --no-pub`: clean.
- 66 focused regression and responsive widget tests: passed.
- 8 updated primary/compact/keyboard/loading golden baselines.

Four dedicated transparent bitmap illustrations now support these surfaces: a restrained lime/gold membership-pass composition, an original emerald football crest, a premium category case, and an uninterrupted-play ribbon. They contain no embedded copy, numbers, or third-party marks, so all product text and account data remain native and dynamic.
