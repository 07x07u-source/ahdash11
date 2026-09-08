from __future__ import annotations

import argparse
import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[2]
PARITY = ROOT / "docs" / "v10_parity"

FLUTTER_SOURCES = {
    "01_launch": ROOT / "mobile/test/visual/goldens/v10_phase_a/launch_390x844.png",
    "03_sign_in": ROOT / "mobile/test/visual/goldens/v10_phase_a/signIn_390x844.png",
    "05_home": ROOT / "mobile/test/visual/goldens/v10_phase_a/home_390x844.png",
    "06_categories": ROOT / "mobile/test/visual/goldens/v10_phase_b/06_categories_390x844.png",
    "12_board": ROOT / "mobile/test/visual/goldens/v10_phase_b/12_board_390x844.png",
    "13_text_question": ROOT / "mobile/test/visual/goldens/v10_phase_b/13_text_390x844.png",
    "14_image_question": ROOT / "mobile/test/visual/goldens/v10_phase_b/14_image_390x844.png",
    "15_reveal": ROOT / "mobile/test/visual/goldens/v10_phase_b/15_reveal_390x844.png",
    "16_result": ROOT / "mobile/test/visual/goldens/v10_phase_b/16_result_390x844.png",
    "19_tournament_hub": ROOT / "mobile/test/visual/goldens/v10_phase_c/hub_390x844.png",
    "23_bracket": ROOT / "mobile/test/visual/goldens/v10_phase_c/bracket_390x844.png",
    "27_champion": ROOT / "mobile/test/visual/goldens/v10_phase_c/champion_390x844.png",
    "34_ranking": ROOT / "mobile/test/visual/goldens/v10_phase_d/ranking_390x844.png",
    "38_profile": ROOT / "mobile/test/visual/goldens/v10_phase_e/profile_390x844.png",
    "40_settings": ROOT / "mobile/test/visual/goldens/v10_phase_e/settings_390x844.png",
    "43_premium": ROOT / "mobile/test/visual/goldens/v10_phase_e/premium_390x844.png",
}


def align_to_figma_safe_area(image: Image.Image) -> Image.Image:
    """Place raw widget-harness content inside the locked 47/34 safe area."""
    if image.size != (390, 844):
        return image
    aligned = Image.new("RGBA", image.size, "#FBF7EF")
    content_height = image.height - 47 - 34
    aligned.paste(image.crop((0, 0, image.width, content_height)), (0, 47))
    return aligned


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", choices=("before", "after"), required=True)
    args = parser.parse_args()

    flutter_dir = PARITY / "flutter" / args.stage
    overlay_dir = PARITY / "overlay" / args.stage
    diff_dir = PARITY / "diff" / args.stage
    compare_dir = PARITY / "compare" / args.stage
    for directory in (flutter_dir, overlay_dir, diff_dir, compare_dir):
        directory.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, str]] = []
    for name, flutter_source in FLUTTER_SOURCES.items():
        figma_source = PARITY / "figma" / f"{name}_figma.png"
        figma = Image.open(figma_source).convert("RGBA")
        flutter = align_to_figma_safe_area(
            Image.open(flutter_source).convert("RGBA")
        )
        if figma.size != flutter.size:
            raise ValueError(f"{name}: Figma {figma.size} != Flutter {flutter.size}")

        flutter.save(flutter_dir / f"{name}_flutter_{args.stage}.png")
        Image.blend(figma, flutter, 0.5).save(
            overlay_dir / f"{name}_overlay_{args.stage}.png"
        )
        difference = ImageChops.difference(figma, flutter).convert("RGB")
        difference.save(diff_dir / f"{name}_diff_{args.stage}.png")
        comparison = Image.new("RGBA", (figma.width * 2, figma.height))
        comparison.paste(figma, (0, 0))
        comparison.paste(flutter, (figma.width, 0))
        comparison.save(compare_dir / f"{name}_side_by_side_{args.stage}.png")

        stat = ImageStat.Stat(difference)
        mean = sum(stat.mean) / 3
        rms = (sum(value * value for value in stat.rms) / 3) ** 0.5
        changed = sum(1 for pixel in difference.getdata() if pixel != (0, 0, 0))
        rows.append(
            {
                "screen": name,
                "mean_abs_difference": f"{mean:.3f}",
                "rms_difference": f"{rms:.3f}",
                "changed_pixels_percent": f"{changed * 100 / (figma.width * figma.height):.3f}",
            }
        )

    with (PARITY / f"metrics_{args.stage}.csv").open(
        "w", newline="", encoding="utf-8"
    ) as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
