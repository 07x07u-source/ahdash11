from __future__ import annotations

import html
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PROJECT = Path(__file__).resolve().parents[1]
MOBILE = PROJECT / "mobile"
SOURCE = PROJECT / "tmp" / "v10_gameplay_visual_refinement"
OUTPUT = PROJECT / "docs" / "v10_gameplay_visual_refinement"
GOLDENS = MOBILE / "test" / "visual" / "goldens" / "v10_phase_b"

FOLDERS = (
    "categories",
    "helpers",
    "ready",
    "board",
    "questions",
    "reveal",
    "result",
    "artwork",
    "motion_keyframes",
    "details",
    "before_after",
)


def reset_output() -> None:
    docs = (PROJECT / "docs").resolve()
    target = OUTPUT.resolve()
    if target.parent != docs or target.name != "v10_gameplay_visual_refinement":
        raise RuntimeError(f"Refusing to reset unexpected output: {target}")
    if target.exists():
        shutil.rmtree(target)
    for folder in FOLDERS:
        (OUTPUT / folder).mkdir(parents=True, exist_ok=True)


def copy_tree() -> list[Path]:
    copied: list[Path] = []
    for source in sorted(SOURCE.rglob("*.png")):
        relative = source.relative_to(SOURCE)
        target = OUTPUT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied.append(target)
    return copied


def crop(source_relative: str, target_relative: str, box: tuple[int, int, int, int]) -> Path:
    source = OUTPUT / source_relative
    target = OUTPUT / target_relative
    with Image.open(source) as image:
        image.load()
        left, top, right, bottom = box
        if not (0 <= left < right <= image.width and 0 <= top < bottom <= image.height):
            raise ValueError(f"Invalid crop {box} for {source} ({image.size})")
        image.crop(box).save(target, optimize=True)
    return target


def contact_sheet(before: Path, after: Path, target_relative: str) -> Path:
    with Image.open(before).convert("RGB") as first, Image.open(after).convert(
        "RGB"
    ) as second:
        if first.size != second.size:
            raise ValueError(f"Contact sheet size mismatch: {first.size} != {second.size}")
        gap, header = 20, 48
        sheet = Image.new(
            "RGB", (first.width * 2 + gap, first.height + header), "#FBF7EF"
        )
        sheet.paste(first, (0, header))
        sheet.paste(second, (first.width + gap, header))
        draw = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype("arialbd.ttf", 17)
        except OSError:
            font = ImageFont.load_default()
        draw.text((14, 14), "BEFORE", fill="#756E63", font=font)
        draw.text((first.width + gap + 14, 14), "REFINED", fill="#191714", font=font)
        target = OUTPUT / target_relative
        target.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(target, optimize=True)
        return target


def build_details() -> list[Path]:
    results = [
        crop(
            "categories/category_selection_6_selected_390x844.png",
            "categories/category_card_detail.png",
            (18, 270, 372, 592),
        ),
        crop(
            "helpers/helpers_selected_390x844.png",
            "helpers/helper_card_detail.png",
            (18, 198, 372, 466),
        ),
        crop(
            "ready/ready_primary_390x844.png",
            "ready/teams_detail.png",
            (18, 126, 372, 334),
        ),
        crop(
            "ready/ready_primary_390x844.png",
            "ready/start_cta_detail.png",
            (18, 726, 372, 818),
        ),
        crop(
            "board/board_mid_game_390x844.png",
            "board/board_detail.png",
            (18, 174, 372, 598),
        ),
        crop(
            "board/board_mid_game_390x844.png",
            "board/scoreboard_detail.png",
            (0, 42, 390, 126),
        ),
        crop(
            "questions/text_question_primary_390x844.png",
            "questions/question_card_detail.png",
            (18, 174, 372, 414),
        ),
        crop(
            "reveal/answer_reveal_390x844.png",
            "reveal/answer_detail.png",
            (18, 98, 372, 286),
        ),
        crop(
            "reveal/scoring_selected_390x844.png",
            "reveal/scoring_controls_detail.png",
            (18, 292, 372, 536),
        ),
        crop(
            "reveal/scoring_selected_390x844.png",
            "reveal/score_state_detail.png",
            (18, 328, 372, 456),
        ),
        crop(
            "result/final_result_winner_390x844.png",
            "result/result_artwork_detail.png",
            (18, 80, 372, 292),
        ),
        crop(
            "result/final_result_winner_390x844.png",
            "result/result_cta_area.png",
            (18, 664, 372, 828),
        ),
    ]
    selected = OUTPUT / "reveal" / "score_state_390x844.png"
    shutil.copy2(OUTPUT / "reveal" / "scoring_selected_390x844.png", selected)
    results.append(selected)
    return results


def build_before_after() -> list[Path]:
    mappings = {
        "category_selection": (
            "06_categories_390x844.png",
            "categories/category_selection_6_selected_390x844.png",
        ),
        "helpers": (
            "10_helpers_390x844.png",
            "helpers/helpers_selected_390x844.png",
        ),
        "game_board": (
            "12_board_390x844.png",
            "board/board_mid_game_390x844.png",
        ),
        "text_question": (
            "13_text_390x844.png",
            "questions/text_question_primary_390x844.png",
        ),
        "image_question": (
            "14_image_390x844.png",
            "questions/image_question_primary_390x844.png",
        ),
        "answer_reveal": (
            "15_reveal_390x844.png",
            "reveal/answer_reveal_390x844.png",
        ),
        "final_result": (
            "16_result_390x844.png",
            "result/final_result_winner_390x844.png",
        ),
    }
    return [
        contact_sheet(
            GOLDENS / before,
            OUTPUT / after,
            f"before_after/{name}_before_after.png",
        )
        for name, (before, after) in mappings.items()
    ]


def build_index(images: list[Path]) -> None:
    sections: list[str] = []
    for folder in FOLDERS:
        rows = sorted(path for path in images if path.parent.name == folder)
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
  <title>AHDASH | 11 — V10 Gameplay Visual Refinement</title>
  <style>
    :root {{ --paper:#fbf7ef; --surface:#f4ebdd; --ink:#191714; --muted:#756e63; --green:#b6ff3b; --deep:#174d3d; --gold:#ffc857; --line:#d3c6b2; }}
    * {{ box-sizing:border-box; }}
    body {{ margin:0; color:var(--ink); background:var(--paper); font-family:"Segoe UI",Tahoma,sans-serif; }}
    header {{ padding:46px clamp(22px,5vw,72px) 34px; background:var(--deep); color:var(--paper); border-bottom:5px solid var(--green); }}
    header small {{ color:var(--gold); font-weight:900; letter-spacing:.08em; }}
    h1 {{ margin:8px 0 10px; font-size:clamp(30px,5vw,58px); line-height:1.05; }}
    header p {{ margin:0; color:#ebdfc9; max-width:780px; line-height:1.7; }}
    nav {{ position:sticky; top:0; z-index:2; display:flex; gap:8px; overflow:auto; padding:10px clamp(16px,4vw,60px); background:rgba(251,247,239,.96); border-bottom:1px solid var(--line); direction:ltr; }}
    nav a {{ white-space:nowrap; text-decoration:none; color:var(--ink); background:var(--surface); border:1px solid var(--line); border-radius:999px; padding:7px 12px; font-size:12px; }}
    main {{ padding:22px clamp(16px,4vw,60px) 80px; }}
    section {{ margin:0 0 44px; scroll-margin-top:70px; }}
    h2 {{ margin:0 0 14px; font-size:22px; text-transform:capitalize; color:var(--deep); }}
    .grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(230px,1fr)); gap:16px; align-items:start; }}
    .card {{ overflow:hidden; background:white; border:1px solid var(--line); border-radius:18px; box-shadow:0 7px 22px rgba(25,23,20,.06); }}
    .card a {{ display:block; background:#eee6d8; }}
    .card img {{ display:block; width:100%; height:auto; max-height:680px; object-fit:contain; background:var(--paper); }}
    .card p {{ margin:0; padding:11px 13px; direction:ltr; color:var(--muted); font-size:12px; overflow-wrap:anywhere; }}
    footer {{ padding:24px; text-align:center; color:var(--muted); border-top:1px solid var(--line); }}
  </style>
</head>
<body>
  <header><small>AHDASH | 11 · V10</small><h1>تنقيح تجربة اللعب</h1><p>معرض محلي دون اتصال للفئات، المساعدات، الاستعداد، لوحة اللعب، الأسئلة، كشف الإجابة، والنتيجة النهائية.</p></header>
  <nav>{nav}</nav>
  <main>{''.join(sections)}</main>
  <footer>{len(images)} صورة · مولّدة من كود Flutter الحالي · دون تبعيات إنترنت</footer>
</body>
</html>
"""
    (OUTPUT / "INDEX.html").write_text(document, encoding="utf-8")


def build_manifest(images: list[Path]) -> None:
    text = f"""# AHDASH | 11 — V10 Gameplay Visual Refinement

- Generated from the current Flutter implementation.
- Full-screen viewports: 390x844 and 360x800.
- Includes component crops, original procedural football artwork, motion keyframes, primary CTA states, and seven before/after comparisons.
- The source V10 Goldens were used only as the historical BEFORE side, never as design authority.
- Image count: {len(images)}
- Offline gallery: INDEX.html

Product truth preserved: 6 categories / 36 questions / 2 teams / 3 categories per team / 3 helpers per team.
"""
    (OUTPUT / "MANIFEST.md").write_text(text, encoding="utf-8")


def build() -> None:
    if not SOURCE.is_dir():
        raise FileNotFoundError(SOURCE)
    reset_output()
    images = copy_tree()
    images.extend(build_details())
    images.extend(build_before_after())
    images = sorted(set(images))
    build_index(images)
    build_manifest(images)
    print(f"Built {len(images)} images at {OUTPUT}")


if __name__ == "__main__":
    build()
