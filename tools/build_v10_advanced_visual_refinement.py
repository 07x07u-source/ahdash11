from __future__ import annotations

import hashlib
import html
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PROJECT = Path(__file__).resolve().parents[1]
OUTPUT = PROJECT / "docs" / "v10_advanced_visual_refinement"
TEMP = PROJECT / "tmp" / "v10_advanced_visual"
MOBILE = PROJECT / "mobile"
GOLDENS = MOBILE / "test" / "visual" / "goldens"
PREVIOUS = PROJECT / "docs" / "v10_home_premium_design_refinement"

FOLDERS = (
    "home",
    "premium",
    "settings",
    "party",
    "tournament",
    "social",
    "account",
    "empty_states",
    "loading_states",
    "error_states",
    "artwork",
    "motion_keyframes",
    "details",
    "before_after",
)


def reset_output() -> None:
    docs = (PROJECT / "docs").resolve()
    target = OUTPUT.resolve()
    if target.parent != docs or target.name != "v10_advanced_visual_refinement":
        raise RuntimeError(f"Refusing to reset unexpected output: {target}")
    if target.exists():
        shutil.rmtree(target)
    for folder in FOLDERS:
        (OUTPUT / folder).mkdir(parents=True, exist_ok=True)


def copy(source: Path, relative: str) -> Path:
    if not source.is_file():
        raise FileNotFoundError(source)
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    return target


def crop(source: Path, relative: str, box: tuple[int, int, int, int]) -> Path:
    if not source.is_file():
        raise FileNotFoundError(source)
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        image.load()
        left, top, right, bottom = box
        if not (0 <= left < right <= image.width and 0 <= top < bottom <= image.height):
            raise ValueError(f"Invalid crop {box} for {source} ({image.size})")
        image.crop(box).save(target, optimize=True)
    return target


def contact_sheet(before: Path, after: Path, relative: str) -> Path:
    with Image.open(before).convert("RGB") as first, Image.open(after).convert(
        "RGB"
    ) as second:
        if first.size != second.size:
            raise ValueError(f"Contact-sheet size mismatch: {first.size} != {second.size}")
        gap, top = 18, 48
        sheet = Image.new(
            "RGB", (first.width * 2 + gap, first.height + top), "#FBF7EF"
        )
        sheet.paste(first, (0, top))
        sheet.paste(second, (first.width + gap, top))
        draw = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype("arialbd.ttf", 17)
        except OSError:
            font = ImageFont.load_default()
        draw.text((12, 14), "BEFORE", fill="#191714", font=font)
        draw.text((first.width + gap + 12, 14), "ADVANCED", fill="#174D3D", font=font)
        target = OUTPUT / relative
        sheet.save(target, optimize=True)
        return target


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build_index(images: list[Path]) -> None:
    sections: list[str] = []
    for folder in FOLDERS:
        rows = [path for path in images if path.parent.name == folder]
        if not rows:
            continue
        cards = "".join(
            f"""
            <article class="card">
              <a href="{html.escape(path.relative_to(OUTPUT).as_posix())}">
                <img loading="lazy" src="{html.escape(path.relative_to(OUTPUT).as_posix())}" alt="{html.escape(path.stem)}">
              </a>
              <p>{html.escape(path.stem.replace('_', ' '))}</p>
            </article>
            """
            for path in rows
        )
        sections.append(
            f'<section id="{folder}"><h2>{folder.replace("_", " ")}</h2>'
            f'<div class="grid">{cards}</div></section>'
        )
    nav = "".join(
        f'<a href="#{folder}">{folder.replace("_", " ")}</a>'
        for folder in FOLDERS
        if any(path.parent.name == folder for path in images)
    )
    document = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AHDASH | 11 — Advanced Visual Refinement</title>
  <style>
    :root {{ --paper:#fbf7ef; --surface:#f4ebdd; --ink:#191714; --muted:#756e63; --green:#174d3d; --lime:#b6ff3b; --gold:#ffc857; --line:#d3c6b2; }}
    * {{ box-sizing:border-box; }}
    body {{ margin:0; color:var(--ink); background:var(--paper); font-family:"Segoe UI",Tahoma,sans-serif; }}
    header {{ padding:46px clamp(22px,5vw,72px) 34px; background:var(--green); color:var(--paper); border-bottom:5px solid var(--lime); }}
    header small {{ color:var(--gold); font-weight:800; letter-spacing:.08em; }}
    h1 {{ margin:8px 0 10px; font-size:clamp(30px,5vw,58px); line-height:1; }}
    header p {{ margin:0; color:#ebdfc9; max-width:760px; line-height:1.7; }}
    nav {{ position:sticky; top:0; z-index:2; display:flex; gap:8px; overflow:auto; padding:10px clamp(16px,4vw,60px); background:rgba(251,247,239,.96); border-bottom:1px solid var(--line); direction:ltr; }}
    nav a {{ white-space:nowrap; text-decoration:none; color:var(--ink); background:var(--surface); border:1px solid var(--line); border-radius:999px; padding:7px 12px; font-size:12px; }}
    main {{ padding:22px clamp(16px,4vw,60px) 80px; }}
    section {{ margin:0 0 44px; scroll-margin-top:70px; }}
    h2 {{ margin:0 0 14px; font-size:22px; text-transform:capitalize; color:var(--green); }}
    .grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(230px,1fr)); gap:16px; align-items:start; }}
    .card {{ overflow:hidden; margin:0; background:white; border:1px solid var(--line); border-radius:18px; box-shadow:0 7px 22px rgba(25,23,20,.06); }}
    .card a {{ display:block; background:#eee6d8; }}
    .card img {{ display:block; width:100%; height:auto; max-height:640px; object-fit:contain; background:var(--paper); }}
    .card p {{ margin:0; padding:11px 13px; direction:ltr; color:var(--muted); font-size:12px; overflow-wrap:anywhere; }}
    footer {{ padding:24px; text-align:center; color:var(--muted); border-top:1px solid var(--line); }}
  </style>
</head>
<body>
  <header><small>AHDASH | 11 · V10</small><h1>التنقيح البصري المتقدم</h1><p>معرض محلي دون اتصال لمراجعة الشاشات الكاملة، الرسوم الإجرائية الأصلية، التفاصيل، الحركة، وحالات قبل/بعد.</p></header>
  <nav>{nav}</nav>
  <main>{''.join(sections)}</main>
  <footer>{len(images)} صورة · لا توجد تبعيات إنترنت</footer>
</body>
</html>
"""
    (OUTPUT / "INDEX.html").write_text(document, encoding="utf-8")


def build() -> None:
    reset_output()
    home = TEMP / "home_review"
    premium = TEMP / "home_premium"
    generated = TEMP / "generated"
    full = TEMP / "full_feature"

    mappings: dict[str, Path] = {
        "home/01_home_primary_390x844.png": home / "home_account_390x844_scale1.0.png",
        "home/02_home_compact_360x800.png": home / "home_account_360x800_scale1.0.png",
        "home/03_home_guest_390x844.png": home / "home_guest_390x844_scale1.0.png",
        "home/04_home_text_scale_1_3_390x844.png": home / "home_account_390x844_scale1.3.png",
        "home/05_home_premium_entry_390x844.png": premium / "home_premium_discovery_390x844.png",
        "premium/01_premium_monthly_390x844.png": premium / "premium_monthly_selected_390x844.png",
        "premium/02_premium_annual_390x844.png": premium / "premium_annual_selected_390x844.png",
        "premium/03_premium_loading_390x844.png": premium / "premium_packages_loading_390x844.png",
        "premium/04_premium_store_unavailable_390x844.png": premium / "premium_packages_unavailable_390x844.png",
        "premium/05_premium_purchase_loading_390x844.png": premium / "premium_purchase_loading_390x844.png",
        "premium/06_premium_active_subscriber_390x844.png": premium / "premium_active_subscriber_390x844.png",
        "premium/07_premium_category_locked_390x844.png": premium / "premium_category_locked_390x844.png",
        "premium/08_premium_category_unlocked_390x844.png": premium / "premium_category_unlocked_390x844.png",
        "premium/09_premium_contextual_gate_390x844.png": premium / "premium_category_gate_390x844.png",
        "settings/01_settings_signed_in_390x844.png": generated / "settings" / "settings_signed_in_390x844.png",
        "settings/02_settings_guest_390x844.png": generated / "settings" / "settings_guest_390x844.png",
        "settings/03_settings_subscriber_390x844.png": generated / "settings" / "settings_subscriber_390x844.png",
        "settings/04_settings_compact_360x800.png": generated / "settings" / "settings_compact_360x800.png",
        "settings/05_settings_support_session_390x844.png": generated / "settings" / "settings_signed_in_bottom_390x844.png",
    }

    party_names = {
        "01_category_selection": "06_categories_390x844.png",
        "02_team_setup": "08_teams_390x844.png",
        "03_team_splitter": "09_splitter_390x844.png",
        "04_helpers": "10_helpers_390x844.png",
        "05_ready": "11_ready_390x844.png",
        "06_game_board": "12_board_390x844.png",
        "07_text_question": "13_text_390x844.png",
        "08_image_question": "14_image_390x844.png",
        "09_answer_reveal": "15_reveal_390x844.png",
        "10_final_result": "16_result_390x844.png",
    }
    mappings.update(
        {
            f"party/{target}_390x844.png": GOLDENS / "v10_phase_b" / source
            for target, source in party_names.items()
        }
    )
    tournament_names = {
        "01_tournament_hub": "hub_390x844.png",
        "02_create_tournament": "create_390x844.png",
        "03_tournament_teams": "teams_390x844.png",
        "04_tournament_draw": "draw_390x844.png",
        "05_tournament_bracket": "bracket_390x844.png",
        "06_tournament_match": "match_390x844.png",
        "07_tournament_champion": "champion_390x844.png",
    }
    mappings.update(
        {
            f"tournament/{target}_390x844.png": GOLDENS / "v10_phase_c" / source
            for target, source in tournament_names.items()
        }
    )
    mappings.update(
        {
            "social/01_friends.png": full / "friends" / "friends_populated_fixture_390x844.png",
            "social/02_friends_search.png": full / "friends" / "friends_search_results_fixture_390x844.png",
            "social/03_blocked_players.png": full / "blocked" / "blocked_players_fixture_390x844.png",
            "account/01_profile_390x844.png": GOLDENS / "v10_phase_e" / "profile_390x844.png",
            "account/02_notifications_390x844.png": GOLDENS / "v10_phase_e" / "notifications_390x844.png",
            "account/03_report_problem_390x844.png": GOLDENS / "v10_phase_e" / "report_390x844.png",
            "account/04_football_preferences_390x844.png": GOLDENS / "v10_phase_e" / "football_390x844.png",
            "empty_states/01_saved_games_empty.png": full / "empty_states" / "saved_games_empty_390x844.png",
            "empty_states/02_friends_empty.png": full / "friends" / "friends_empty_390x844.png",
            "empty_states/03_notifications_empty.png": full / "empty_states" / "notifications_empty_390x844.png",
            "empty_states/04_ranking_empty.png": full / "empty_states" / "ranking_empty_390x844.png",
            "empty_states/05_editorial_state_detail.png": generated / "empty_states" / "editorial_empty_state.png",
            "loading_states/01_friends_loading.png": full / "loading" / "friends_loading_390x844.png",
            "loading_states/02_notifications_loading.png": full / "loading" / "notifications_loading_390x844.png",
            "loading_states/03_ranking_loading.png": full / "loading" / "ranking_loading_390x844.png",
            "loading_states/04_contextual_loading_detail.png": generated / "loading_states" / "contextual_loading.png",
            "error_states/01_friends_error.png": full / "errors" / "friends_error_390x844.png",
            "error_states/02_notifications_error.png": full / "errors" / "notifications_error_390x844.png",
            "error_states/03_blocked_players_error.png": full / "errors" / "blocked_players_error_390x844.png",
            "error_states/04_editorial_error_detail.png": generated / "error_states" / "editorial_error_state.png",
        }
    )
    for target, source in mappings.items():
        copy(source, target)

    for source in sorted((generated / "artwork").glob("*.png")):
        copy(source, f"artwork/{source.name}")
    for source in sorted((generated / "motion_keyframes").glob("*.png")):
        copy(source, f"motion_keyframes/{source.name}")
    copy(premium / "home_motion_keyframe_390x844.png", "motion_keyframes/home_full_motion_frame.png")

    home_after = OUTPUT / "home" / "01_home_primary_390x844.png"
    premium_after = OUTPUT / "premium" / "01_premium_monthly_390x844.png"
    settings_after = OUTPUT / "settings" / "01_settings_signed_in_390x844.png"
    detail_crops = {
        "details/home_party_hero.png": (home_after, (24, 128, 366, 370)),
        "details/home_secondary_modes.png": (home_after, (24, 468, 366, 836)),
        "details/home_premium_entry.png": (home_after, (24, 380, 366, 449)),
        "details/premium_hero_artwork.png": (premium_after, (24, 104, 366, 305)),
        "details/premium_benefits_artwork.png": (premium_after, (24, 315, 366, 482)),
        "details/premium_plan_selector.png": (premium_after, (24, 500, 366, 650)),
        "details/premium_cta.png": (premium_after, (24, 744, 366, 814)),
        "details/settings_identity.png": (settings_after, (24, 126, 366, 257)),
        "details/settings_account_section.png": (settings_after, (24, 390, 366, 605)),
        "details/settings_premium_row.png": (settings_after, (24, 615, 366, 685)),
    }
    for target, (source, box) in detail_crops.items():
        crop(source, target, box)
    settings_bottom = OUTPUT / "settings" / "05_settings_support_session_390x844.png"
    crop(settings_bottom, "details/settings_support_legal.png", (24, 238, 366, 624))
    crop(settings_bottom, "details/settings_logout.png", (24, 714, 366, 800))

    before_home = PREVIOUS / "home" / "01_home_signed_in_390x844.png"
    before_premium = PREVIOUS / "premium" / "06_premium_monthly_selected_390x844.png"
    before_settings = GOLDENS / "v10_phase_e" / "settings_390x844.png"
    for label, before, after in (
        ("home", before_home, home_after),
        ("premium", before_premium, premium_after),
        ("settings", before_settings, settings_after),
    ):
        copy(before, f"before_after/{label}_before.png")
        copy(after, f"before_after/{label}_after.png")
        contact_sheet(before, after, f"before_after/{label}_before_after.png")

    images = sorted(OUTPUT.rglob("*.png"))
    inventory = [
        f"{path.relative_to(OUTPUT).as_posix()}\t{Image.open(path).size[0]}x{Image.open(path).size[1]}\t{sha256(path)[:16]}"
        for path in images
    ]
    (OUTPUT / "IMAGE_INVENTORY.tsv").write_text(
        "relative_path\tdimensions\tsha256_prefix\n" + "\n".join(inventory) + "\n",
        encoding="utf-8",
    )
    (OUTPUT / "README.md").write_text(
        """# AHDASH | 11 — V10 Advanced Visual Refinement

This pack is generated from the current Flutter implementation and current V10 visual fixtures. `INDEX.html` is the offline review entry point.

The pass deepens Home, Premium, and Settings while preserving product truth. Artwork is procedural and rights-safe. Store prices remain localized values supplied by the store integration; screenshot prices are deterministic test fixtures only. Premium continues to expose Monthly and Annual only, with the two approved benefits: فئات حصرية and بدون إعلانات.

No APK/AAB, Supabase change, RevenueCat deployment, or Online activation is part of this pack.
""",
        encoding="utf-8",
    )
    build_index(images)
    print(f"Built {OUTPUT}")
    print(f"Verified {len(images)} PNG files")


if __name__ == "__main__":
    build()
