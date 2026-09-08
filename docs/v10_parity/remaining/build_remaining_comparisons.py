from __future__ import annotations

import csv
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
REFERENCE = ROOT / "docs" / "v10_figma_reference" / "remaining"
GOLDENS = ROOT / "mobile" / "test" / "visual" / "goldens"
FAILURES = ROOT / "mobile" / "test" / "visual" / "failures"
LEGACY_EVIDENCE = ROOT / "docs" / "v10_parity" / "flutter"
OUTPUT = ROOT / "docs" / "v10_parity" / "remaining"

# reference stem, golden phase, golden stem, keyboard top (or None)
CASES = (
    ("01_launch_compact_360x800", "v10_phase_a", "launch_360x800", None),
    ("01_launch_primary_390x844", "v10_phase_a", "launch_390x844", None),
    ("02_onboarding_1_primary_390x844", "v10_phase_a", "onboarding1_390x844", None),
    ("02_onboarding_2_primary_390x844", "v10_phase_a", "onboarding2_390x844", None),
    ("02_onboarding_3_primary_390x844", "v10_phase_a", "onboarding3_390x844", None),
    ("02_onboarding_4_primary_390x844", "v10_phase_a", "onboarding4_390x844", None),
    ("03_sign_in_compact_360x800", "v10_phase_a", "signIn_360x800", None),
    ("03_sign_in_keyboard_390x844", "v10_phase_a", "signInKeyboard_390x844", 578),
    ("03_sign_in_primary_390x844", "v10_phase_a", "signIn_390x844", None),
    ("04_create_account_compact_360x800", "v10_phase_a", "create_360x800", None),
    ("04_create_account_keyboard_390x844", "v10_phase_a", "createKeyboard_390x844", 554),
    ("04_create_account_primary_390x844", "v10_phase_a", "create_390x844", None),
    ("05_home_compact_360x800", "v10_phase_a", "home_360x800", None),
    ("05_home_primary_390x844", "v10_phase_a", "home_390x844", None),
    ("06_category_search_keyboard_390x844", "v10_phase_b", "06_search_keyboard_390x844", 548),
    ("06_category_selection_compact_360x800", "v10_phase_b", "06_categories_360x800", None),
    ("06_category_selection_primary_390x844", "v10_phase_b", "06_categories_390x844", None),
    ("07_category_detail_compact_360x800", "v10_phase_b", "07_detail_360x800", None),
    ("07_category_detail_primary_390x844", "v10_phase_b", "07_detail_390x844", None),
    ("08_team_setup_compact_360x800", "v10_phase_b", "08_teams_360x800", None),
    ("08_team_setup_keyboard_390x844", "v10_phase_b", "08_teams_keyboard_390x844", 548),
    ("08_team_setup_primary_390x844", "v10_phase_b", "08_teams_390x844", None),
    ("09_team_splitter_compact_360x800", "v10_phase_b", "09_splitter_360x800", None),
    ("09_team_splitter_keyboard_390x844", "v10_phase_b", "09_splitter_keyboard_390x844", 555),
    ("09_team_splitter_primary_390x844", "v10_phase_b", "09_splitter_390x844", None),
    ("10_helpers_compact_360x800", "v10_phase_b", "10_helpers_360x800", None),
    ("10_helpers_primary_390x844", "v10_phase_b", "10_helpers_390x844", None),
    ("11_ready_compact_360x800", "v10_phase_b", "11_ready_360x800", None),
    ("11_ready_primary_390x844", "v10_phase_b", "11_ready_390x844", None),
    ("17_how_to_play_primary_390x844", "v10_phase_d", "howTo_390x844", None),
    ("18_saved_games_primary_390x844", "v10_phase_d", "savedGames_390x844", None),
    ("28_match_setup_primary_390x844", "v10_phase_d", "matchSetup_390x844", None),
    ("29_solo_setup_primary_390x844", "v10_phase_d", "solo_390x844", None),
    ("33_team_challenge_primary_390x844", "v10_phase_d", "teamChallenge_390x844", None),
    ("34_ranking_compact_360x800", "v10_phase_d", "ranking_360x800", None),
    ("34_ranking_primary_390x844", "v10_phase_d", "ranking_390x844", None),
    ("35_friends_primary_390x844", "v10_phase_d", "friends_390x844", None),
    ("35_friends_search_keyboard_390x844", "v10_phase_d", "friendsKeyboard_390x844", 560),
    ("36_blocked_players_primary_390x844", "v10_phase_d", "blocked_390x844", None),
    ("37_team_detail_primary_390x844", "v10_phase_d", "teamDetail_390x844", None),
)


def normalized_flutter(flutter: Image.Image, figma: Image.Image, keyboard_top: int | None) -> Image.Image:
    result = flutter.copy()
    # Flutter golden tests reserve the exact safe areas but do not paint OS chrome.
    result.paste(figma.crop((0, 0, figma.width, 47)), (0, 0))
    if keyboard_top is None:
        bottom = figma.height - 34
        result.paste(figma.crop((0, bottom, figma.width, figma.height)), (0, bottom))
    else:
        result.paste(figma.crop((0, keyboard_top, figma.width, figma.height)), (0, keyboard_top))
    return result


def score(figma: Image.Image, flutter: Image.Image) -> tuple[float, float, float]:
    difference = ImageChops.difference(figma, flutter).convert("RGB")
    stat = ImageStat.Stat(difference)
    mean = sum(stat.mean) / 3
    rms = (sum(value * value for value in stat.rms) / 3) ** 0.5
    parity = max(0.0, 100 * (1 - mean / 255))
    return mean, rms, parity


def before_source(golden_stem: str, current: Path) -> Path:
    candidates = (
        FAILURES / f"{golden_stem}_masterImage.png",
        LEGACY_EVIDENCE / f"{golden_stem}_masterImage.png",
    )
    if golden_stem.startswith("onboarding"):
        candidates = (FAILURES / "onboarding_390x844_masterImage.png",) + candidates
    return next((path for path in candidates if path.exists()), current)


def main() -> None:
    for name in ("before", "after", "side_by_side", "overlay", "diff"):
        directory = OUTPUT / name
        directory.mkdir(parents=True, exist_ok=True)
        for old in directory.glob("*.png"):
            old.unlink()

    rows: list[dict[str, str]] = []
    for reference_stem, phase, golden_stem, keyboard_top in CASES:
        reference_path = REFERENCE / f"{reference_stem}.png"
        current_path = GOLDENS / phase / f"{golden_stem}.png"
        figma = Image.open(reference_path).convert("RGBA")
        current_raw = Image.open(current_path).convert("RGBA")
        current = normalized_flutter(current_raw, figma, keyboard_top)
        old_path = before_source(golden_stem, current_path)
        old_raw = Image.open(old_path).convert("RGBA").resize(figma.size)
        old = normalized_flutter(old_raw, figma, keyboard_top)

        old.save(OUTPUT / "before" / f"{reference_stem}.png")
        current.save(OUTPUT / "after" / f"{reference_stem}.png")
        side = Image.new("RGBA", (figma.width * 2, figma.height), "white")
        side.paste(figma, (0, 0))
        side.paste(current, (figma.width, 0))
        side.save(OUTPUT / "side_by_side" / f"{reference_stem}.png")
        Image.blend(figma, current, 0.5).save(OUTPUT / "overlay" / f"{reference_stem}.png")
        ImageChops.difference(figma, current).convert("RGB").save(
            OUTPUT / "diff" / f"{reference_stem}.png"
        )
        before_mean, _, before_parity = score(figma, old)
        mean, rms, parity = score(figma, current)
        rows.append(
            {
                "reference": reference_stem,
                "before_score": f"{before_parity:.2f}",
                "after_score": f"{parity:.2f}",
                "mean_abs_difference": f"{mean:.3f}",
                "rms_difference": f"{rms:.3f}",
                "comparison_policy": "safe-area + canonical keyboard normalization",
            }
        )

    with (OUTPUT / "metrics.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
