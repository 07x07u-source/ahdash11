from __future__ import annotations

import argparse
import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
REFERENCE = ROOT / "docs" / "v10_figma_reference" / "account_premium"
GOLDENS = ROOT / "mobile" / "test" / "visual" / "goldens" / "v10_phase_e"
FAILURES = ROOT / "mobile" / "test" / "visual" / "failures"
OUTPUT = ROOT / "docs" / "v10_parity" / "account_premium"

CASES = (
    ("38_profile", "primary", "profile", 390, 844),
    ("38_profile", "compact", "profile", 360, 800),
    ("39_notifications", "primary", "notifications", 390, 844),
    ("40_settings", "primary", "settings", 390, 844),
    ("41_report", "primary", "report", 390, 844),
    ("41_report_keyboard", "keyboard", "reportKeyboard", 390, 844),
    ("42_football_preferences", "primary", "football", 390, 844),
    (
        "42_football_preferences_keyboard",
        "keyboard",
        "footballKeyboard",
        390,
        844,
    ),
    ("43_premium", "primary", "premium", 390, 844),
    ("43_premium", "compact", "premium", 360, 800),
)


def align_before(image: Image.Image, width: int, height: int) -> Image.Image:
    result = Image.new("RGBA", (width, height), "#FBF7EF")
    result.paste(image.crop((0, 0, width, height - 81)), (0, 47))
    return result


def mask_system_regions(
    image: Image.Image, figma: Image.Image, *, keyboard: bool
) -> Image.Image:
    result = image.copy()
    result.paste(figma.crop((0, 0, figma.width, 47)), (0, 0))
    if keyboard:
        result.paste(figma.crop((0, 578, figma.width, figma.height)), (0, 578))
    else:
        result.paste(
            figma.crop((0, figma.height - 34, figma.width, figma.height)),
            (0, figma.height - 34),
        )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", required=True, choices=("before", "after"))
    parser.add_argument("--actual-failures", action="store_true")
    args = parser.parse_args()

    stage_root = OUTPUT / args.stage
    dirs = {
        name: stage_root / name
        for name in ("figma", "flutter", "side_by_side", "overlay", "diff")
    }
    for directory in dirs.values():
        directory.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, str]] = []
    for screen, variant, golden_stem, width, height in CASES:
        label = f"{screen}_{width}x{height}"
        reference_name = f"{label}.png"
        figma = Image.open(REFERENCE / variant / reference_name).convert("RGBA")
        flutter_path = (
            FAILURES / f"{golden_stem}_{width}x{height}_testImage.png"
            if args.actual_failures
            else GOLDENS / f"{golden_stem}_{width}x{height}.png"
        )
        raw_flutter = Image.open(flutter_path).convert("RGBA")
        flutter = (
            align_before(raw_flutter, width, height)
            if args.stage == "before"
            else mask_system_regions(
                raw_flutter, figma, keyboard=variant == "keyboard"
            )
        )

        figma.save(dirs["figma"] / reference_name)
        flutter.save(dirs["flutter"] / reference_name)
        side = Image.new("RGBA", (width * 2, height), "white")
        side.paste(figma, (0, 0))
        side.paste(flutter, (width, 0))
        side.save(dirs["side_by_side"] / reference_name)
        Image.blend(figma, flutter, 0.5).save(dirs["overlay"] / reference_name)
        difference = ImageChops.difference(figma, flutter).convert("RGB")
        difference.save(dirs["diff"] / reference_name)
        stat = ImageStat.Stat(difference)
        mean = sum(stat.mean) / 3
        rms = (sum(value * value for value in stat.rms) / 3) ** 0.5
        changed = sum(
            1 for pixel in difference.get_flattened_data() if pixel != (0, 0, 0)
        )
        rows.append(
            {
                "screen": screen,
                "viewport": f"{width}x{height}",
                "mean_abs_difference": f"{mean:.3f}",
                "rms_difference": f"{rms:.3f}",
                "changed_pixels_percent": f"{changed * 100 / (width * height):.3f}",
                "parity_score": f"{max(0.0, 100 * (1 - mean / 255)):.2f}",
            }
        )

    with (stage_root / "metrics.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
