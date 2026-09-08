from __future__ import annotations

import csv
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[3]
REF = ROOT / "docs/v10_figma_reference/phase_h3_final"
GOLD = ROOT / "mobile/test/visual/goldens"
OUT = ROOT / "docs/v10_parity/phase_h3_final"

# reference folder, reference stem, golden phase, golden stem, keyboard top
CASES = (
    ("category_c", "03_sign_in_compact_360x800", "v10_phase_a", "signIn_360x800", None),
    ("category_c", "04_create_account_compact_360x800", "v10_phase_a", "create_360x800", None),
    ("category_c", "06_category_search_keyboard_390x844", "v10_phase_b", "06_search_keyboard_390x844", 548),
    ("category_c", "06_category_selection_compact_360x800", "v10_phase_b", "06_categories_360x800", None),
    ("category_c", "06_category_selection_primary_390x844", "v10_phase_b", "06_categories_390x844", None),
    ("category_c", "07_category_detail_compact_360x800", "v10_phase_b", "07_detail_360x800", None),
    ("category_c", "07_category_detail_primary_390x844", "v10_phase_b", "07_detail_390x844", None),
    ("category_c", "08_team_setup_compact_360x800", "v10_phase_b", "08_teams_360x800", None),
    ("category_c", "08_team_setup_primary_390x844", "v10_phase_b", "08_teams_390x844", None),
    ("category_c", "10_helpers_compact_360x800", "v10_phase_b", "10_helpers_360x800", None),
    ("category_c", "10_helpers_primary_390x844", "v10_phase_b", "10_helpers_390x844", None),
    ("category_c", "11_ready_compact_360x800", "v10_phase_b", "11_ready_360x800", None),
    ("category_c", "11_ready_primary_390x844", "v10_phase_b", "11_ready_390x844", None),
    ("category_c", "18_saved_games_primary_390x844", "v10_phase_d", "savedGames_390x844", None),
    ("category_c", "29_solo_setup_primary_390x844", "v10_phase_d", "solo_390x844", None),
    ("category_c", "33_team_challenge_primary_390x844", "v10_phase_d", "teamChallenge_390x844", None),
    ("category_c", "35_friends_primary_390x844", "v10_phase_d", "friends_390x844", None),
    ("category_c", "35_friends_search_keyboard_390x844", "v10_phase_d", "friendsKeyboard_390x844", 560),
    ("party_helper_delta", "12_game_board_primary_390x844", "v10_phase_b", "12_board_390x844", None),
    ("party_helper_delta", "12_game_board_compact_360x800", "v10_phase_b", "12_board_360x800", None),
    ("party_helper_delta", "13_text_question_primary_390x844", "v10_phase_b", "13_text_390x844", None),
    ("party_helper_delta", "13_text_question_compact_360x800", "v10_phase_b", "13_text_360x800", None),
    ("party_helper_delta", "14_image_question_primary_390x844", "v10_phase_b", "14_image_390x844", None),
    ("party_helper_delta", "14_image_question_compact_360x800", "v10_phase_b", "14_image_360x800", None),
)


def normalize(flutter: Image.Image, figma: Image.Image, keyboard_top: int | None) -> Image.Image:
    result = flutter.convert("RGB").copy()
    figma = figma.convert("RGB")
    result.paste(figma.crop((0, 0, figma.width, 47)), (0, 0))
    if keyboard_top is None:
        bottom = figma.height - 34
        result.paste(figma.crop((0, bottom, figma.width, figma.height)), (0, bottom))
    else:
        result.paste(figma.crop((0, keyboard_top, figma.width, figma.height)), (0, keyboard_top))
    return result


def metrics(figma: Image.Image, flutter: Image.Image) -> tuple[float, float, float]:
    diff = ImageChops.difference(figma.convert("RGB"), flutter.convert("RGB"))
    stat = ImageStat.Stat(diff)
    mean = sum(stat.mean) / 3
    rms = (sum(v * v for v in stat.rms) / 3) ** 0.5
    return max(0.0, 100 * (1 - mean / 255)), mean, rms


def main() -> None:
    for name in ("before", "after", "side_by_side", "overlay", "diff"):
        (OUT / name).mkdir(parents=True, exist_ok=True)
    rows = []
    for folder, stem, phase, golden_stem, keyboard_top in CASES:
        ref_path = REF / folder / f"{stem}.png"
        golden_path = GOLD / phase / f"{golden_stem}.png"
        if not ref_path.exists() or not golden_path.exists():
            raise FileNotFoundError(ref_path if not ref_path.exists() else golden_path)
        figma = Image.open(ref_path).convert("RGB")
        flutter = Image.open(golden_path).convert("RGB")
        if figma.size != flutter.size:
            raise ValueError(f"{stem}: Figma {figma.size}, Flutter {flutter.size}")
        normalized = normalize(flutter, figma, keyboard_top)
        before_path = OUT / "before" / f"{stem}.png"
        if not before_path.exists():
            normalized.save(before_path)
        before = Image.open(before_path).convert("RGB")
        shutil.copy2(golden_path, OUT / "after" / f"{stem}.png")
        normalized.save(OUT / "after" / f"{stem}.png")
        side = Image.new("RGB", (figma.width * 2, figma.height))
        side.paste(figma, (0, 0)); side.paste(normalized, (figma.width, 0))
        side.save(OUT / "side_by_side" / f"{stem}.png")
        Image.blend(figma, normalized, 0.5).save(OUT / "overlay" / f"{stem}.png")
        ImageChops.difference(figma, normalized).save(OUT / "diff" / f"{stem}.png")
        before_score, _, _ = metrics(figma, before)
        after_score, mean, rms = metrics(figma, normalized)
        rows.append({"reference": stem, "before_score": f"{before_score:.2f}", "after_score": f"{after_score:.2f}", "mean_abs_difference": f"{mean:.3f}", "rms_difference": f"{rms:.3f}", "policy": "safe-area + canonical keyboard normalization"})
    with (OUT / "metrics.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader(); writer.writerows(rows)


if __name__ == "__main__":
    main()
