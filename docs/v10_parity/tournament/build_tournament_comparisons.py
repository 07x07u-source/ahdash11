from __future__ import annotations

import argparse
import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
REFERENCE = ROOT / "docs" / "v10_figma_reference" / "tournament"
GOLDENS = ROOT / "mobile" / "test" / "visual" / "goldens" / "v10_phase_c"
OUTPUT = ROOT / "docs" / "v10_parity" / "tournament"

CASES = (
    ("19_tournament_hub", "primary", "hub", 390, 844),
    ("19_tournament_hub", "compact", "hub", 360, 800),
    ("20_create_tournament", "primary", "create", 390, 844),
    ("20_create_tournament_keyboard", "keyboard", "create_keyboard", 390, 844),
    ("21_tournament_teams", "primary", "teams", 390, 844),
    ("22_tournament_draw", "primary", "draw", 390, 844),
    ("23_tournament_bracket", "primary", "bracket", 390, 844),
    ("23_tournament_bracket", "compact", "bracket", 360, 800),
    ("26_tournament_match", "primary", "match", 390, 844),
    ("27_tournament_champion", "primary", "champion", 390, 844),
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
        result.paste(figma.crop((0, 560, figma.width, figma.height)), (0, 560))
    else:
        result.paste(
            figma.crop((0, figma.height - 34, figma.width, figma.height)),
            (0, figma.height - 34),
        )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", required=True, choices=("before", "after"))
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
        raw_flutter = Image.open(
            GOLDENS / f"{golden_stem}_{width}x{height}.png"
        ).convert("RGBA")
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
