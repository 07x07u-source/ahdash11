from __future__ import annotations

import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "docs/v10_parity/auth_ux_repair"

CASES = (
    (
        "03_sign_in_primary_390x844",
        "docs/v10_figma_reference/remaining/03_sign_in_primary_390x844.png",
        "mobile/test/visual/goldens/auth_ux_repair/03_sign_in_primary_390x844.png",
        "docs/v10_parity/remaining/after/03_sign_in_primary_390x844.png",
        None,
    ),
    (
        "03_sign_in_compact_360x800",
        "docs/v10_figma_reference/phase_h3_final/category_c/03_sign_in_compact_360x800.png",
        "mobile/test/visual/goldens/auth_ux_repair/03_sign_in_compact_360x800.png",
        "docs/v10_parity/phase_h3_final/after/03_sign_in_compact_360x800.png",
        None,
    ),
    (
        "03_sign_in_keyboard_390x844",
        "docs/v10_figma_reference/remaining/03_sign_in_keyboard_390x844.png",
        "mobile/test/visual/goldens/auth_ux_repair/03_sign_in_keyboard_390x844.png",
        "docs/v10_parity/remaining/after/03_sign_in_keyboard_390x844.png",
        578,
    ),
    (
        "04_create_account_primary_390x844",
        "docs/v10_figma_reference/remaining/04_create_account_primary_390x844.png",
        "mobile/test/visual/goldens/auth_ux_repair/04_create_account_primary_390x844.png",
        "docs/v10_parity/remaining/after/04_create_account_primary_390x844.png",
        None,
    ),
    (
        "04_create_account_compact_360x800",
        "docs/v10_figma_reference/phase_h3_final/category_c/04_create_account_compact_360x800.png",
        "mobile/test/visual/goldens/auth_ux_repair/04_create_account_compact_360x800.png",
        "docs/v10_parity/phase_h3_final/after/04_create_account_compact_360x800.png",
        None,
    ),
    (
        "04_create_account_keyboard_390x844",
        "docs/v10_figma_reference/remaining/04_create_account_keyboard_390x844.png",
        "mobile/test/visual/goldens/auth_ux_repair/04_create_account_keyboard_390x844.png",
        "docs/v10_parity/remaining/after/04_create_account_keyboard_390x844.png",
        554,
    ),
)


def normalized(flutter: Image.Image, figma: Image.Image, keyboard_top: int | None) -> Image.Image:
    result = flutter.convert("RGB").copy()
    figma = figma.convert("RGB")
    result.paste(figma.crop((0, 0, figma.width, 47)), (0, 0))
    if keyboard_top is None:
        bottom = figma.height - 34
        result.paste(figma.crop((0, bottom, figma.width, figma.height)), (0, bottom))
    else:
        result.paste(figma.crop((0, keyboard_top, figma.width, figma.height)), (0, keyboard_top))
    return result


def score(figma: Image.Image, flutter: Image.Image) -> tuple[float, float, float]:
    diff = ImageChops.difference(figma.convert("RGB"), flutter.convert("RGB"))
    stat = ImageStat.Stat(diff)
    mean = sum(stat.mean) / 3
    rms = (sum(value * value for value in stat.rms) / 3) ** 0.5
    return max(0.0, 100 * (1 - mean / 255)), mean, rms


def main() -> None:
    for directory in ("before", "after", "side_by_side", "overlay", "diff"):
        (OUT / directory).mkdir(parents=True, exist_ok=True)

    rows = []
    for stem, ref_name, golden_name, before_name, keyboard_top in CASES:
        ref = Image.open(ROOT / ref_name).convert("RGB")
        current = Image.open(ROOT / golden_name).convert("RGB")
        before = Image.open(ROOT / before_name).convert("RGB")
        if ref.size != current.size or ref.size != before.size:
            raise ValueError(f"{stem}: size mismatch {ref.size}, {current.size}, {before.size}")
        current = normalized(current, ref, keyboard_top)
        before = normalized(before, ref, keyboard_top)
        before.save(OUT / "before" / f"{stem}.png")
        current.save(OUT / "after" / f"{stem}.png")

        side = Image.new("RGB", (ref.width * 2, ref.height))
        side.paste(ref, (0, 0))
        side.paste(current, (ref.width, 0))
        side.save(OUT / "side_by_side" / f"{stem}.png")
        Image.blend(ref, current, 0.5).save(OUT / "overlay" / f"{stem}.png")
        ImageChops.difference(ref, current).save(OUT / "diff" / f"{stem}.png")

        before_score, _, _ = score(ref, before)
        after_score, mean, rms = score(ref, current)
        rows.append(
            {
                "reference": stem,
                "before_score": f"{before_score:.2f}",
                "after_score": f"{after_score:.2f}",
                "mean_abs_difference": f"{mean:.3f}",
                "rms_difference": f"{rms:.3f}",
                "policy": "safe-area + canonical keyboard normalization",
            }
        )

    with (OUT / "metrics.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
