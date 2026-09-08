from __future__ import annotations

import argparse
import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
REFERENCE = ROOT / "docs" / "v10_figma_reference"
GOLDENS = ROOT / "mobile" / "test" / "visual" / "goldens" / "v10_phase_b"
OUTPUT = ROOT / "docs" / "v10_parity" / "party_core"

SCREENS = {
    "12_game_board": "12_board",
    "13_text_question": "13_text",
    "14_image_question": "14_image",
    "15_answer_reveal": "15_reveal",
    "16_final_result": "16_result",
}


def align_to_locked_safe_area(image: Image.Image, width: int, height: int) -> Image.Image:
    """Place the zero-padding widget harness inside the locked 47/34 safe area."""
    if image.size != (width, height):
        raise ValueError(f"Unexpected Flutter size {image.size}; expected {(width, height)}")
    result = Image.new("RGBA", image.size, "#FBF7EF")
    content_height = height - 47 - 34
    result.paste(image.crop((0, 0, width, content_height)), (0, 47))
    return result


def mask_system_owned_safe_areas(image: Image.Image, figma: Image.Image) -> Image.Image:
    """Exclude system status/home indicators from app-owned parity scoring."""
    result = image.copy()
    result.paste(figma.crop((0, 0, figma.width, 47)), (0, 0))
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
    for screen, golden_stem in SCREENS.items():
        for width, height, variant in ((390, 844, "primary"), (360, 800, "compact")):
            label = f"{screen}_{width}x{height}"
            figma_path = REFERENCE / variant / f"{label}.png"
            flutter_path = GOLDENS / f"{golden_stem}_{width}x{height}.png"
            figma = Image.open(figma_path).convert("RGBA")
            raw_flutter = Image.open(flutter_path).convert("RGBA")
            flutter = (
                mask_system_owned_safe_areas(raw_flutter, figma)
                if args.stage == "after"
                else align_to_locked_safe_area(raw_flutter, width, height)
            )
            if figma.size != flutter.size:
                raise ValueError(f"{label}: Figma {figma.size} != Flutter {flutter.size}")

            figma.save(dirs["figma"] / f"{label}.png")
            flutter.save(dirs["flutter"] / f"{label}.png")

            side = Image.new("RGBA", (width * 2, height), "white")
            side.paste(figma, (0, 0))
            side.paste(flutter, (width, 0))
            side.save(dirs["side_by_side"] / f"{label}.png")

            Image.blend(figma, flutter, 0.5).save(
                dirs["overlay"] / f"{label}.png"
            )
            difference = ImageChops.difference(figma, flutter).convert("RGB")
            difference.save(dirs["diff"] / f"{label}.png")
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
