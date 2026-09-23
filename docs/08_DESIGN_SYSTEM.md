# AHDASH | 11 — Approved Design System

**Authority:** sole canonical design authority  
**Last verified:** 12 September 2026  
**Scope:** approved identity and runtime design rules only; this document does not redesign the product.

## Approved identity sources

Authority order:

1. Reference package: `brand-package/ahdash_11_brand_package/assets/branding/`
2. Mobile runtime copy: `mobile/assets/branding/`
3. Desktop/Admin runtime copy: `admin/public/branding/`

Supporting approved evidence includes `docs/ahdash-brand-v5.md`, `mobile/assets/branding/ASSET_MAP.txt`, and `docs/v9_2_asset_map.md`. Runtime source owns implementation details only when it remains consistent with the approved identity package.

## Canonical assets

- `logo-symbol.png`
- `logo-wordmark.png`
- `logo-horizontal.png`
- `app-icon.png`
- `brand-pattern.png`
- `brand-guidelines.png`

There is no canonical SVG in the approved package. Do not recreate or substitute a vector logo and call it canonical without the promotion process below.

## Identity use

- Use the provided symbol, wordmark, or horizontal lockup according to the available composition; do not manually rebuild the mark from text or icons.
- Preserve asset aspect ratio, transparency, visual integrity, and approved color treatment.
- Do not distort, crop through the mark, recolor arbitrarily, add unapproved effects, or place it on a background that destroys legibility.
- Use `app-icon.png` for application icon contexts and the supplied brand pattern as a supporting texture, not as an alternate logo.
- If a required placement is not covered by the approved assets/guidelines, treat the result as a study until reviewed; do not invent permanent measurements here.

## Typography

Approved product typeface: **Thmanyah Sans**.

Approved local weights:

- 400
- 500
- 700
- 900

Flutter's active family name is `ThmanyahSans`. Typography must support Arabic legibility, clear hierarchy, RTL reading order, and stable layout under larger text. Do not substitute a typeface merely because it appears in a screenshot or generated concept.

## Approved palette

| Role | Color | Use |
|---|---|---|
| Paper | `#F4EBDD` | Primary warm page/background foundation |
| Surface | `#FBF7EF` | Raised or contained light surfaces |
| Ink | `#1B1916` | Primary text and dark structural color |
| Interaction green | `#5F8F0F` | Primary interactive/accent state |
| Legacy lime | `#B6FF3B` | Limited high-energy accent; not a default full-surface replacement |
| Achievement/Premium gold | `#FFC857` | Achievement and approved Premium emphasis |

Runtime tokens may use close, implementation-specific variants. Flutter token ownership lives in `mobile/lib/core/theme/app_colors.dart`; platform component/theme source owns the actual runtime mapping. Any palette change that alters brand meaning requires review and approval, not merely a screenshot update.

The current Flutter Production product is Light only. A dark theme definition in code is not active product truth.

## Spacing and component principles

Use the established runtime spacing, typography, radius, control, and surface tokens consistently. Existing numeric token definitions in platform source own the current implementation; this document does not invent new measurements.

Approved principles:

- Calm editorial hierarchy with clear primary action and restrained decoration.
- Consistent spacing rhythm within and between sections.
- Comfortable touch/click targets and clear focus, pressed, disabled, loading, error, and empty states.
- Legible contrast and semantic color use; do not rely on color alone for meaning.
- Reusable components instead of screen-specific visual exceptions.
- Premium/achievement gold is purposeful and limited; interaction green remains the primary action language.
- Motion must respect reduced-motion preference and must not obscure state.

## RTL-first rules

- Arabic and RTL are the primary layout direction, not a mirrored afterthought.
- Reading order, alignment, navigation direction, progress, icon directionality, and mixed Arabic/Latin content must be tested in RTL.
- Numeric scores, timers, handles, IDs, and Latin product/provider names must remain readable without corrupting surrounding RTL order.
- Icons with semantic direction must follow the action's RTL meaning; neutral icons must not be mirrored automatically.
- Text must wrap without clipping at supported widths and enlarged text settings.

## Asset promotion lifecycle

Every new visual follows this lifecycle:

`STUDY` → `REVIEW` → `APPROVAL` → `RUNTIME ASSET` → `VISUAL/ACCESSIBILITY VALIDATION`

Definitions:

- `STUDY`: exploration with no product authority.
- `REVIEW`: evaluated for product fit, brand consistency, rights, accessibility, and technical use.
- `APPROVAL`: explicit decision by the appropriate owner; approval must identify the asset and intended scope.
- `RUNTIME ASSET`: optimized, named, placed in the approved runtime location, and referenced by product code.
- `VISUAL/ACCESSIBILITY VALIDATION`: verified in supported layouts, RTL, text scale, contrast, and relevant states.

A generated image, screenshot, Golden, or filename containing “final” cannot approve itself.

## Not design authority

The following are explicitly not approved design authority:

- Goldens.
- Screenshots.
- UI atlases.
- Generated concepts.
- Temporary images.
- Old creative studies.
- Rejected Direction A.
- Rejected Direction B.
- Rejected Direction C.

These materials may be historical, experimental, or rejected evidence. They must not override the approved sources above or be promoted into runtime without completing the lifecycle. Archive classification is defined in [archive/README.md](./archive/README.md).
