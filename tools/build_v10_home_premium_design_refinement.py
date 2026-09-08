from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PROJECT = Path(__file__).resolve().parents[1]
OUTPUT = PROJECT / "docs" / "v10_home_premium_design_refinement"
HOME_REVIEW = PROJECT / "tmp" / "v10_home_premium_refinement" / "home_review"
GENERATED = PROJECT / "tmp" / "v10_home_premium_refinement" / "generated"
ATLAS = PROJECT / "docs" / "v10_complete_ui_atlas"


def checked_reset_output() -> None:
    docs = (PROJECT / "docs").resolve()
    target = OUTPUT.resolve()
    if target.parent != docs or target.name != "v10_home_premium_design_refinement":
        raise RuntimeError(f"Refusing to reset unexpected target: {target}")
    if target.exists():
        shutil.rmtree(target)
    for name in (
        "home",
        "premium",
        "details",
        "motion_keyframes",
        "before_after",
    ):
        (target / name).mkdir(parents=True, exist_ok=True)


def copy(source: Path, relative_target: str) -> Path:
    if not source.is_file():
        raise FileNotFoundError(source)
    target = OUTPUT / relative_target
    shutil.copy2(source, target)
    return target


def crop(source: Path, relative_target: str, box: tuple[int, int, int, int]) -> Path:
    target = OUTPUT / relative_target
    with Image.open(source) as image:
        image.load()
        if not (0 <= box[0] < box[2] <= image.width):
            raise ValueError(f"Invalid horizontal crop {box} for {source}")
        if not (0 <= box[1] < box[3] <= image.height):
            raise ValueError(f"Invalid vertical crop {box} for {source}")
        image.crop(box).save(target, optimize=True)
    return target


def contact_sheet(before: Path, after: Path, relative_target: str) -> Path:
    with Image.open(before).convert("RGB") as before_image, Image.open(after).convert(
        "RGB"
    ) as after_image:
        if before_image.size != (390, 844) or after_image.size != (390, 844):
            raise ValueError("Before/after sources must both be 390x844")
        top = 42
        gap = 18
        sheet = Image.new(
            "RGB",
            (before_image.width + after_image.width + gap, before_image.height + top),
            "#FBF7EF",
        )
        sheet.paste(before_image, (0, top))
        sheet.paste(after_image, (before_image.width + gap, top))
        draw = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype("arialbd.ttf", 18)
        except OSError:
            font = ImageFont.load_default()
        draw.text((12, 11), "BEFORE", fill="#191714", font=font)
        draw.text((before_image.width + gap + 12, 11), "AFTER", fill="#191714", font=font)
        target = OUTPUT / relative_target
        sheet.save(target, optimize=True)
        return target


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_pngs(expected: dict[str, tuple[int, int] | None]) -> list[str]:
    rows: list[str] = []
    for relative, size in expected.items():
        path = OUTPUT / relative
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            actual = image.size
        if size is not None and actual != size:
            raise ValueError(f"Unexpected dimensions for {relative}: {actual} != {size}")
        rows.append(f"{relative}\t{actual[0]}x{actual[1]}\t{sha256(path)[:16]}")
    return rows


def build() -> None:
    checked_reset_output()

    signed_home = HOME_REVIEW / "home_account_390x844_scale1.0.png"
    compact_home = HOME_REVIEW / "home_account_360x800_scale1.0.png"
    guest_home = HOME_REVIEW / "home_guest_390x844_scale1.0.png"
    discovery_home = GENERATED / "home_premium_discovery_390x844.png"
    motion_home = GENERATED / "home_motion_keyframe_390x844.png"
    monthly = GENERATED / "premium_monthly_selected_390x844.png"
    annual = GENERATED / "premium_annual_selected_390x844.png"
    locked = GENERATED / "premium_category_locked_390x844.png"

    expected: dict[str, tuple[int, int] | None] = {}

    full_screens = {
        "home/01_home_signed_in_390x844.png": signed_home,
        "home/02_home_compact_360x800.png": compact_home,
        "home/03_home_guest_390x844.png": guest_home,
        "home/04_home_premium_discovery_390x844.png": discovery_home,
        "motion_keyframes/05_home_motion_keyframe_390x844.png": motion_home,
        "premium/06_premium_monthly_selected_390x844.png": monthly,
        "premium/07_premium_annual_selected_390x844.png": annual,
        "premium/08_premium_packages_loading_390x844.png": GENERATED
        / "premium_packages_loading_390x844.png",
        "premium/09_premium_packages_unavailable_390x844.png": GENERATED
        / "premium_packages_unavailable_390x844.png",
        "premium/10_premium_active_subscriber_390x844.png": GENERATED
        / "premium_active_subscriber_390x844.png",
        "premium/11_premium_purchase_loading_390x844.png": GENERATED
        / "premium_purchase_loading_390x844.png",
        "premium/12_premium_category_locked_390x844.png": locked,
        "premium/13_premium_category_gate_390x844.png": GENERATED
        / "premium_category_gate_390x844.png",
    }
    for relative, source in full_screens.items():
        copy(source, relative)
        expected[relative] = (360, 800) if relative.startswith("home/02_") else (390, 844)

    detail_crops = {
        "details/14_home_hero.png": (signed_home, (20, 125, 370, 373)),
        "details/15_motion_artwork.png": (motion_home, (24, 136, 190, 270)),
        "details/16_premium_hero.png": (monthly, (24, 104, 366, 306)),
        "details/17_monthly_annual_selector.png": (monthly, (24, 500, 366, 652)),
        "details/18_premium_benefits.png": (monthly, (24, 315, 366, 486)),
        "details/19_subscribe_cta.png": (monthly, (24, 738, 366, 816)),
        "details/20_premium_category_badge.png": (locked, (254, 356, 366, 430)),
    }
    for relative, (source, box) in detail_crops.items():
        crop(source, relative, box)
        expected[relative] = None

    before_home = ATLAS / "03_home" / "05_home_signed_in_primary_390x844.png"
    before_premium = (
        ATLAS / "20_premium" / "43_premium_inactive_primary_390x844.png"
    )
    copy(before_home, "before_after/home_before_390x844.png")
    copy(signed_home, "before_after/home_after_390x844.png")
    copy(before_premium, "before_after/premium_before_390x844.png")
    copy(monthly, "before_after/premium_after_390x844.png")
    contact_sheet(
        before_home,
        signed_home,
        "before_after/home_before_after_798x886.png",
    )
    contact_sheet(
        before_premium,
        monthly,
        "before_after/premium_before_after_798x886.png",
    )
    expected.update(
        {
            "before_after/home_before_390x844.png": (390, 844),
            "before_after/home_after_390x844.png": (390, 844),
            "before_after/premium_before_390x844.png": (390, 844),
            "before_after/premium_after_390x844.png": (390, 844),
            "before_after/home_before_after_798x886.png": (798, 886),
            "before_after/premium_before_after_798x886.png": (798, 886),
        }
    )

    inventory = validate_pngs(expected)
    (OUTPUT / "IMAGE_INVENTORY.tsv").write_text(
        "relative_path\tdimensions\tsha256_prefix\n" + "\n".join(inventory) + "\n",
        encoding="utf-8",
    )

    readme = """# AHDASH | 11 — Home + Premium Design Refinement

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
"""
    (OUTPUT / "README.md").write_text(readme, encoding="utf-8")

    print(f"Built {OUTPUT}")
    print(f"Verified {len(expected)} PNG files")


if __name__ == "__main__":
    build()
