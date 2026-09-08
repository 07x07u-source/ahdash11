from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import Color, HexColor
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "ahdash_11_all_screens_v8_2.pdf"

PAGE_W, PAGE_H = landscape(A4)
INK = HexColor("#171613")
BEIGE = HexColor("#F8F3E8")
MUTED = HexColor("#7C7468")
GREEN = HexColor("#9EFF2B")
GOLD = HexColor("#FFBE3D")
LINE = HexColor("#D8CCB8")


@dataclass(frozen=True)
class Screen:
    section: str
    title: str
    light: Path
    dark: Path
    compact_light: Path | None = None
    compact_dark: Path | None = None


def checkpoint(name: str, title: str, section: str) -> Screen:
    folder = ROOT / "docs" / "visual-validation" / "v8-2-checkpoint"
    return Screen(
        section,
        title,
        folder / f"{name}_1280x720_light.png",
        folder / f"{name}_1280x720_dark.png",
        folder / f"{name}_844x390_light.png",
        folder / f"{name}_844x390_dark.png",
    )


def party(name: str, title: str) -> Screen:
    folder = ROOT / "docs" / "visual-validation" / "party"
    return Screen(
        "PARTY GAME",
        title,
        folder / f"{name}_1280x720_light.png",
        folder / f"{name}_1280x720_dark.png",
    )


def support(name: str, title: str, *, height: int = 720) -> Screen:
    folder = ROOT / "docs" / "screenshots" / "mobile" / "pages"
    dimensions = f"1280x{height}"
    return Screen(
        "SUPPORTING ROUTES",
        title,
        folder / f"{name}_{dimensions}_light.png",
        folder / f"{name}_{dimensions}_dark.png",
    )


def tournament(name: str, title: str) -> Screen:
    folder = ROOT / "mobile" / "test" / "visual" / "goldens" / "tournament"
    return Screen(
        "TOURNAMENT",
        title,
        folder / f"{name}_1280x720_light.png",
        folder / f"{name}_1280x720_dark.png",
    )


def football_preferences() -> Screen:
    folder = ROOT / "docs" / "visual-validation" / "goldens"
    return Screen(
        "PROFILE & PREFERENCES",
        "Football preferences",
        folder / "club_picker_1280x720_light.png",
        folder / "club_picker_1280x720_dark.png",
    )


SCREENS = [
    support("launch", "Launch"),
    support("onboarding", "Onboarding"),
    checkpoint("signIn", "Sign in", "FOUNDATION"),
    checkpoint("createAccount", "Create account", "FOUNDATION"),
    checkpoint("home", "Home", "FOUNDATION"),
    party("categories", "Party - category selection"),
    party("categoryDetail", "Party - category detail"),
    party("teams", "Party - team setup"),
    party("teamSplitter", "Party - team splitter"),
    checkpoint("helpers", "Party - helpers", "PARTY GAME"),
    checkpoint("ready", "Party - ready", "PARTY GAME"),
    party("board", "Party - board"),
    party("textQuestion", "Party - text question"),
    party("imageQuestion", "Party - image question"),
    party("answer", "Party - answer reveal"),
    checkpoint("result", "Party - final result", "PARTY GAME"),
    party("howTo", "How to play"),
    support("partyGames", "Saved party games"),
    checkpoint("tournamentHub", "Tournament hub", "TOURNAMENT"),
    tournament("create", "Create tournament"),
    tournament("teams", "Tournament teams"),
    checkpoint("tournamentDraw", "Tournament draw", "TOURNAMENT"),
    tournament("bracket", "Tournament bracket"),
    tournament("semifinal", "Tournament semifinal"),
    tournament("finalMatch", "Tournament final"),
    checkpoint("tournamentMatch", "Tournament match", "TOURNAMENT"),
    checkpoint("tournamentChampion", "Tournament champion", "TOURNAMENT"),
    support("gameSetup", "Match setup"),
    support("soloSetup", "Solo setup"),
    support("onlineLobby", "Online lobby"),
    support("onlineMatch", "Online match"),
    support("roomLobby", "Private room"),
    support("teamChallenge", "Team challenge", height=760),
    support("ranking", "Ranking"),
    support("friends", "Friends"),
    support("blockedPlayers", "Blocked players"),
    support("socialTeam", "Team detail"),
    checkpoint("profile", "Profile", "PROFILE & PREFERENCES"),
    checkpoint("notifications", "Notifications", "PROFILE & PREFERENCES"),
    support("settings", "Settings"),
    support("reportProblem", "Report a problem"),
    football_preferences(),
    checkpoint("premium", "Premium", "PROFILE & PREFERENCES"),
]


def ensure_inputs() -> None:
    if len(SCREENS) != 43:
        raise RuntimeError(f"Expected 43 screens, found {len(SCREENS)}")
    missing = [
        path
        for screen in SCREENS
        for path in (
            screen.light,
            screen.dark,
            screen.compact_light,
            screen.compact_dark,
        )
        if path is not None and not path.is_file()
    ]
    if missing:
        formatted = "\n".join(str(path) for path in missing)
        raise FileNotFoundError(f"Missing screenshot inputs:\n{formatted}")


def draw_image_contain(
    pdf: Canvas,
    image_path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
) -> None:
    with Image.open(image_path) as source:
        image_w, image_h = source.size
    scale = min(width / image_w, height / image_h)
    draw_w = image_w * scale
    draw_h = image_h * scale
    draw_x = x + (width - draw_w) / 2
    draw_y = y + (height - draw_h) / 2
    # Keep the translucent frame isolated. ReportLab otherwise retains the
    # 4% alpha in the graphics state and applies it to the screenshot too.
    pdf.saveState()
    pdf.setFillColor(Color(0, 0, 0, alpha=0.04))
    pdf.roundRect(draw_x - 2, draw_y - 2, draw_w + 4, draw_h + 4, 5, fill=1, stroke=0)
    pdf.restoreState()
    pdf.setFillAlpha(1)
    pdf.drawImage(
        str(image_path),
        draw_x,
        draw_y,
        draw_w,
        draw_h,
        preserveAspectRatio=True,
    )


def draw_cover(pdf: Canvas) -> None:
    pdf.setFillColor(INK)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pdf.setFillColor(GREEN)
    pdf.rect(54, PAGE_H - 104, 12, 46, fill=1, stroke=0)
    pdf.setFillColor(BEIGE)
    pdf.setFont("Helvetica-Bold", 34)
    pdf.drawString(86, PAGE_H - 91, "AHDASH | 11")
    pdf.setFont("Helvetica-Bold", 22)
    pdf.drawString(54, PAGE_H - 166, "COMPLETE SCREEN CATALOG - V8.2")
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 13)
    pdf.drawString(54, PAGE_H - 196, "43 REAL FLUTTER SCREENS / STATES")
    pdf.setFillColor(HexColor("#CFC7BA"))
    pdf.setFont("Helvetica", 11)
    pdf.drawString(54, PAGE_H - 230, "Rendered from Flutter golden tests - PNG assets only")
    pdf.drawString(54, PAGE_H - 248, "Light and dark themes - 1280 x 720 landscape")
    pdf.drawString(54, PAGE_H - 266, "Core checkpoints also include 844 x 390 compact validation")
    pdf.setStrokeColor(HexColor("#3E3A33"))
    pdf.line(54, 76, PAGE_W - 54, 76)
    pdf.setFillColor(HexColor("#8F897F"))
    pdf.setFont("Helvetica", 9)
    pdf.drawString(54, 56, "No emulator - No APK - No SVG screenshots")
    pdf.showPage()


def draw_header(pdf: Canvas, screen: Screen, index: int) -> None:
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 17)
    pdf.drawString(34, PAGE_H - 36, screen.title)
    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(PAGE_W - 34, PAGE_H - 30, screen.section)
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica", 8)
    pdf.drawRightString(PAGE_W - 34, PAGE_H - 42, f"{index:02d} / 43")
    pdf.setStrokeColor(LINE)
    pdf.line(34, PAGE_H - 51, PAGE_W - 34, PAGE_H - 51)


def draw_page(pdf: Canvas, screen: Screen, index: int) -> None:
    pdf.setFillColor(BEIGE)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    draw_header(pdf, screen, index)

    margin = 34
    gap = 14
    content_top = PAGE_H - 68
    footer_h = 18
    content_h = content_top - margin - footer_h
    panel_w = (PAGE_W - (margin * 2) - gap) / 2

    if screen.compact_light is not None and screen.compact_dark is not None:
        row_gap = 10
        row_h = (content_h - row_gap - 28) / 2
        upper_y = margin + footer_h + row_h + row_gap
        lower_y = margin + footer_h
        for label, path, x in (
            ("1280 x 720 - LIGHT", screen.light, margin),
            ("1280 x 720 - DARK", screen.dark, margin + panel_w + gap),
        ):
            pdf.setFillColor(MUTED)
            pdf.setFont("Helvetica-Bold", 7)
            pdf.drawString(x, upper_y + row_h + 4, label)
            draw_image_contain(pdf, path, x, upper_y, panel_w, row_h)
        for label, path, x in (
            ("844 x 390 - LIGHT", screen.compact_light, margin),
            ("844 x 390 - DARK", screen.compact_dark, margin + panel_w + gap),
        ):
            pdf.setFillColor(MUTED)
            pdf.setFont("Helvetica-Bold", 7)
            pdf.drawString(x, lower_y + row_h + 4, label)
            draw_image_contain(pdf, path, x, lower_y, panel_w, row_h)
    else:
        image_y = margin + footer_h + 72
        image_h = min(content_h - 84, panel_w * 9 / 16)
        for label, path, x in (
            ("LIGHT", screen.light, margin),
            ("DARK", screen.dark, margin + panel_w + gap),
        ):
            pdf.setFillColor(MUTED)
            pdf.setFont("Helvetica-Bold", 8)
            pdf.drawString(x, image_y + image_h + 8, label)
            draw_image_contain(pdf, path, x, image_y, panel_w, image_h)

    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica", 7.5)
    pdf.drawString(34, 22, "Source: Flutter golden render - raster PNG")
    pdf.drawRightString(PAGE_W - 34, 22, "AHDASH | 11 - V8.2")
    pdf.showPage()


def main() -> None:
    ensure_inputs()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf = Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H), pageCompression=1)
    pdf.setTitle("AHDASH | 11 - Complete Screen Catalog V8.2")
    pdf.setAuthor("AHDASH | 11")
    pdf.setSubject("43-screen Flutter visual validation catalog")
    draw_cover(pdf)
    for index, screen in enumerate(SCREENS, start=1):
        draw_page(pdf, screen, index)
    pdf.save()
    print(OUTPUT)


if __name__ == "__main__":
    main()
