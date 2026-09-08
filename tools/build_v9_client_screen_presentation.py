from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import Color, HexColor
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "ahdash_11_complete_screen_catalog_v10.pdf"

# A 16:9 client deck reads better on screen while remaining printable.
PAGE_W, PAGE_H = 960.0, 540.0

BLACK = HexColor("#0D0E0C")
BLACK_2 = HexColor("#151613")
PAPER = HexColor("#F8F3E8")
PAPER_2 = HexColor("#EFE5D2")
INK = HexColor("#171613")
MUTED = HexColor("#8D8B83")
MUTED_LIGHT = HexColor("#B9B7AF")
LINE = HexColor("#34352F")
LINE_LIGHT = HexColor("#DCCFB9")
GREEN = HexColor("#A6FF2E")
GREEN_DARK = HexColor("#638F2D")
GOLD = HexColor("#FFC54A")
WHITE = HexColor("#FFFDF8")

BRAND = ROOT / "mobile" / "assets" / "branding"
VISUALS = ROOT / "mobile" / "assets" / "visuals"
LOGO = BRAND / "logo-horizontal.png"
SYMBOL = BRAND / "logo-symbol.png"
PATTERN = BRAND / "brand-pattern.png"
HOME_HERO = VISUALS / "home-hero.png"


@dataclass(frozen=True)
class Screen:
    section: str
    title: str
    purpose: str
    light: Path
    dark: Path
    compact_light: Path
    compact_dark: Path


@dataclass(frozen=True)
class Section:
    number: str
    title: str
    subtitle: str
    start: int
    end: int
    representative: int


def _screen(
    folder: Path,
    name: str,
    section: str,
    title: str,
    purpose: str,
) -> Screen:
    return Screen(
        section=section,
        title=title,
        purpose=purpose,
        light=folder / f"{name}_1280x720_light.png",
        dark=folder / f"{name}_1280x720_dark.png",
        compact_light=folder / f"{name}_844x390_light.png",
        compact_dark=folder / f"{name}_844x390_dark.png",
    )


def checkpoint(name: str, section: str, title: str, purpose: str) -> Screen:
    return _screen(
        ROOT / "docs" / "visual-validation" / "v9-checkpoint",
        name,
        section,
        title,
        purpose,
    )


def core(name: str, section: str, title: str, purpose: str) -> Screen:
    return _screen(
        ROOT / "docs" / "visual-validation" / "goldens",
        name,
        section,
        title,
        purpose,
    )


def party(name: str, title: str, purpose: str) -> Screen:
    return _screen(
        ROOT / "docs" / "visual-validation" / "party",
        name,
        "PARTY GAME",
        title,
        purpose,
    )


def support(name: str, section: str, title: str, purpose: str) -> Screen:
    return _screen(
        ROOT / "docs" / "screenshots" / "mobile" / "pages",
        name,
        section,
        title,
        purpose,
    )


def tournament(name: str, title: str, purpose: str) -> Screen:
    return _screen(
        ROOT / "mobile" / "test" / "visual" / "goldens" / "tournament",
        name,
        "TOURNAMENT",
        title,
        purpose,
    )


SCREENS = (
    support("launch", "FOUNDATION", "Launch", "A confident first brand moment."),
    support("onboarding", "FOUNDATION", "Onboarding", "Teach the core loop with one clear action."),
    checkpoint("signIn", "FOUNDATION", "Sign in", "Enter the game through a focused auth experience."),
    checkpoint("createAccount", "FOUNDATION", "Create account", "Create the minimum player account."),
    core("home", "FOUNDATION", "Home", "Make starting a game immediately obvious."),
    core("play", "DISCOVERY", "Play modes", "Choose a playable format without live matchmaking."),
    core("categories", "DISCOVERY", "Category discovery", "Search, filter, preview and favorite football categories."),
    party("categories", "Category selection", "Choose six distinct football categories."),
    party("categoryDetail", "Category detail", "Understand one category before selecting it."),
    party("teams", "Team setup", "Build the match around two clear team identities."),
    party("teamSplitter", "Team splitter", "Divide a player list into balanced teams."),
    party("helpers", "Helpers", "Select meaningful tactical helpers for each team."),
    party("ready", "Ready", "Confirm the matchup and start the game."),
    party("board", "Game board", "Choose a category and point value at a glance."),
    party("textQuestion", "Text question", "Read and answer without losing score context."),
    party("imageQuestion", "Image question", "Inspect the visual and answer in one composition."),
    party("reveal", "Answer reveal", "Reveal the answer and award points clearly."),
    party("result", "Final result", "Celebrate the winner and close the session."),
    party("howTo", "How to play", "Explain the party flow in four visual steps."),
    support("partyGames", "PARTY GAME", "Saved games", "Resume a real saved match quickly."),
    tournament("hub", "Tournament hub", "See tournament progress and the next action."),
    tournament("create", "Create tournament", "Create a tournament through a focused step."),
    support("tournamentJoin", "TOURNAMENT", "Join tournament", "Register a team with an invitation code."),
    tournament("teams", "Tournament teams", "Review all participating team identities."),
    support("tournamentRegistrations", "TOURNAMENT", "Registration requests", "Review pending tournament registrations."),
    tournament("draw", "Tournament draw", "Confirm readiness and run the draw."),
    tournament("bracket", "Tournament bracket", "Read progression through an RTL bracket."),
    tournament("semifinal", "Semifinal state", "Focus the bracket on the semifinal round."),
    tournament("finalMatch", "Final state", "Focus the bracket on the decisive match."),
    tournament("match", "Tournament match", "Start and resolve the active fixture."),
    tournament("champion", "Champion", "Turn tournament completion into a victory moment."),
    support("gameSetup", "PLAY MODES", "Match setup", "Choose the format through one connected choice."),
    support("soloSetup", "PLAY MODES", "Ahdash challenge setup", "Start the signature eleven-question solo challenge."),
    core("question", "PLAY MODES", "Solo question", "Answer with score, time and progress in one composition."),
    core("results", "PLAY MODES", "Solo result", "Review accuracy, streak and personal score without a fake bot."),
    support("teamChallenge", "PLAY MODES", "Team challenge", "Answer a timed social challenge."),
    support("ranking", "SOCIAL & ACCOUNT", "Ranking", "Read the podium and the ranked list."),
    support("friends", "SOCIAL & ACCOUNT", "Friends", "Find and manage football friends."),
    support("blockedPlayers", "SOCIAL & ACCOUNT", "Blocked players", "Review privacy choices in a focused list."),
    core("teams", "SOCIAL & ACCOUNT", "Teams hub", "Enter a private team space or manage invitations."),
    support("socialJoinTeam", "SOCIAL & ACCOUNT", "Join team", "Join a private team with a code or invitation link."),
    support("socialTeam", "SOCIAL & ACCOUNT", "Team detail", "See team identity, members and challenges."),
    core("profile", "SOCIAL & ACCOUNT", "Profile", "Present Player11 identity and real stats."),
    support("notifications", "SOCIAL & ACCOUNT", "Notifications", "Read activity or a purposeful empty state."),
    core("settings", "SOCIAL & ACCOUNT", "Settings", "Manage preferences through clear groups."),
    support("reportProblem", "SOCIAL & ACCOUNT", "Report a problem", "Submit a concise, focused support report."),
    core("club_picker", "SOCIAL & ACCOUNT", "Football preferences", "Choose league and club visually."),
    core("premium", "SOCIAL & ACCOUNT", "Premium", "Understand value, price and subscription action."),
    core("store", "SOCIAL & ACCOUNT", "Cosmetic store", "Preview cosmetic inventory, balance and gift redemption."),
)


SECTIONS = (
    Section("01", "FOUNDATION", "Identity, entry and the first product moment", 1, 5, 5),
    Section("02", "DISCOVERY", "Playable modes and category discovery", 6, 7, 7),
    Section("03", "PARTY GAME", "The shared football quiz experience", 8, 20, 14),
    Section("04", "TOURNAMENT", "From invitation to the final celebration", 21, 31, 27),
    Section("05", "PLAY MODES", "Solo and asynchronous team competition", 32, 36, 34),
    Section("06", "SOCIAL & ACCOUNT", "Community, identity, settings and store", 37, 49, 40),
)


def ensure_inputs() -> None:
    if len(SCREENS) != 49:
        raise RuntimeError(f"Expected 49 screens, found {len(SCREENS)}")
    required = [LOGO, SYMBOL, PATTERN, HOME_HERO]
    for screen in SCREENS:
        required.extend(
            [screen.light, screen.dark, screen.compact_light, screen.compact_dark]
        )
    missing = sorted({path for path in required if not path.is_file()})
    if missing:
        raise FileNotFoundError("Missing inputs:\n" + "\n".join(map(str, missing)))


def image_size(path: Path) -> tuple[int, int]:
    with Image.open(path) as source:
        return source.size


def draw_image_contain(
    pdf: Canvas,
    path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
) -> tuple[float, float, float, float]:
    source_w, source_h = image_size(path)
    scale = min(width / source_w, height / source_h)
    draw_w = source_w * scale
    draw_h = source_h * scale
    draw_x = x + (width - draw_w) / 2
    draw_y = y + (height - draw_h) / 2
    pdf.drawImage(
        str(path),
        draw_x,
        draw_y,
        draw_w,
        draw_h,
        preserveAspectRatio=True,
        mask="auto",
    )
    return draw_x, draw_y, draw_w, draw_h


def draw_image_cover(
    pdf: Canvas,
    path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
) -> None:
    source_w, source_h = image_size(path)
    scale = max(width / source_w, height / source_h)
    draw_w = source_w * scale
    draw_h = source_h * scale
    draw_x = x + (width - draw_w) / 2
    draw_y = y + (height - draw_h) / 2
    pdf.saveState()
    clip = pdf.beginPath()
    clip.rect(x, y, width, height)
    pdf.clipPath(clip, stroke=0, fill=0)
    pdf.drawImage(
        str(path),
        draw_x,
        draw_y,
        draw_w,
        draw_h,
        preserveAspectRatio=True,
        mask="auto",
    )
    pdf.restoreState()


def overlay(
    pdf: Canvas,
    color: str,
    alpha: float,
    x: float,
    y: float,
    width: float,
    height: float,
) -> None:
    pdf.saveState()
    pdf.setFillColor(Color(*HexColor(color).rgb(), alpha=alpha))
    pdf.rect(x, y, width, height, fill=1, stroke=0)
    pdf.restoreState()


def wrap_text(text: str, font: str, size: float, max_width: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if stringWidth(candidate, font, size) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_logo_plate(
    pdf: Canvas,
    x: float,
    y: float,
    width: float,
    height: float,
) -> None:
    pdf.setFillColor(PAPER)
    pdf.roundRect(x, y, width, height, 10, fill=1, stroke=0)
    draw_image_contain(pdf, LOGO, x + 14, y + 10, width - 28, height - 20)


def draw_picture_frame(
    pdf: Canvas,
    path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
    *,
    light: bool,
    radius: float = 8,
) -> None:
    pdf.saveState()
    pdf.setFillColor(HexColor("#070806") if not light else HexColor("#E6DCCB"))
    pdf.setStrokeColor(LINE_LIGHT if light else LINE)
    pdf.setLineWidth(0.8)
    pdf.roundRect(x - 4, y - 4, width + 8, height + 8, radius, fill=1, stroke=1)
    pdf.restoreState()
    draw_image_contain(pdf, path, x, y, width, height)


def section_for(index: int) -> Section:
    return next(section for section in SECTIONS if section.start <= index <= section.end)


def draw_cover(pdf: Canvas) -> None:
    draw_image_cover(pdf, HOME_HERO, 0, 0, PAGE_W, PAGE_H)
    overlay(pdf, "#070806", 0.64, 0, 0, PAGE_W, PAGE_H)
    overlay(pdf, "#070806", 0.36, PAGE_W * 0.48, 0, PAGE_W * 0.52, PAGE_H)

    draw_logo_plate(pdf, 54, PAGE_H - 116, 220, 58)
    pdf.setFillColor(GREEN)
    pdf.rect(54, PAGE_H - 224, 8, 76, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 33)
    pdf.drawString(82, PAGE_H - 176, "THE COMPLETE")
    pdf.drawString(82, PAGE_H - 216, "PRODUCT EXPERIENCE")
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(54, PAGE_H - 255, "COMPLETE SCREEN CATALOG  /  VISUAL SYSTEM V10")
    pdf.setFillColor(MUTED_LIGHT)
    pdf.setFont("Helvetica", 10)
    pdf.drawString(54, PAGE_H - 282, "Forty-three real Flutter screens and states.")
    pdf.drawString(54, PAGE_H - 298, "Two themes. Two verified landscape viewports.")

    preview = SCREENS[4].dark
    preview_x, preview_y, preview_w = 520, 118, 378
    preview_h = preview_w * 9 / 16
    draw_picture_frame(
        pdf,
        preview,
        preview_x,
        preview_y,
        preview_w,
        preview_h,
        light=False,
        radius=12,
    )
    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawString(preview_x, preview_y - 22, "ACTUAL PRODUCT UI  /  DARK THEME")

    chips = (("49", "SCREENS"), ("5", "DISPLAY CONDITIONS"), ("6", "PRODUCT AREAS"))
    chip_x = 54.0
    for value, label in chips:
        pdf.setFillColor(Color(*BLACK_2.rgb(), alpha=0.86))
        pdf.roundRect(chip_x, 58, 136, 56, 8, fill=1, stroke=0)
        pdf.setFillColor(GREEN)
        pdf.setFont("Helvetica-Bold", 19)
        pdf.drawString(chip_x + 14, 80, value)
        pdf.setFillColor(WHITE)
        pdf.setFont("Helvetica-Bold", 7)
        pdf.drawString(chip_x + 47, 84, label)
        chip_x += 148
    pdf.showPage()


def draw_overview(pdf: Canvas) -> None:
    pdf.setFillColor(PAPER)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 32)
    pdf.drawString(54, PAGE_H - 76, "ONE GAME. ONE VISUAL LANGUAGE.")
    pdf.setFillColor(GREEN_DARK)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(54, PAGE_H - 98, "AHDASH | 11  /  PRODUCT WALKTHROUGH")

    copy = (
        "This book presents the complete mobile experience as built in Flutter.",
        "Every view is a raster render of the real interface - not a concept frame.",
        "The sequence follows the player journey from launch to play, competition,",
        "community and account management.",
    )
    pdf.setFillColor(HexColor("#625E55"))
    pdf.setFont("Helvetica", 11)
    y = PAGE_H - 140
    for line in copy:
        pdf.drawString(54, y, line)
        y -= 17

    metrics = (
        ("49", "REAL SCREENS / STATES"),
        ("LIGHT + DARK", "THEME COVERAGE"),
        ("1280 x 720", "PRIMARY REVIEW"),
        ("844 x 390", "COMPACT REVIEW"),
    )
    y = 230.0
    for value, label in metrics:
        pdf.setStrokeColor(LINE_LIGHT)
        pdf.line(54, y + 40, 430, y + 40)
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 20)
        pdf.drawString(54, y + 12, value)
        pdf.setFillColor(HexColor("#777167"))
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawRightString(430, y + 17, label)
        y -= 52

    montage = (
        (SCREENS[10].dark, 520, 293, 378),
        (SCREENS[22].light, 520, 146, 240),
        (SCREENS[37].dark, 774, 146, 132),
    )
    for path, x, y, width in montage:
        height = width * image_size(path)[1] / image_size(path)[0]
        draw_picture_frame(
            pdf,
            path,
            x,
            y,
            width,
            height,
            light="light" in path.stem,
            radius=8,
        )
    pdf.setFillColor(GREEN_DARK)
    pdf.rect(520, 92, 386, 7, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawString(520, 70, "REAL UI  /  ARABIC-FIRST  /  PORTRAIT + LANDSCAPE")
    pdf.showPage()


def draw_orientation_proof(pdf: Canvas) -> None:
    pdf.setFillColor(PAPER)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(46, PAGE_H - 66, "PORTRAIT IS PART OF THE PRODUCT")
    pdf.setFillColor(GREEN_DARK)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(46, PAGE_H - 88, "REAL FLUTTER RENDERS  /  390 x 844  /  DARK THEME")
    pdf.setFillColor(HexColor("#625E55"))
    pdf.setFont("Helvetica", 10)
    pdf.drawString(
        46,
        PAGE_H - 112,
        "Core journeys adapt to phone portrait layouts while retaining the same Arabic-first visual system.",
    )

    portrait_names = (
        ("home", "HOME"),
        ("play", "PLAY"),
        ("categories", "DISCOVER"),
        ("question", "QUESTION"),
        ("results", "RESULT"),
        ("store", "STORE"),
    )
    x = 46.0
    phone_w = 116.0
    phone_h = phone_w * 844 / 390
    for name, label in portrait_names:
        path = ROOT / "docs" / "visual-validation" / "goldens" / f"{name}_390x844_dark.png"
        draw_picture_frame(pdf, path, x, 118, phone_w, phone_h, light=False, radius=9)
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 7)
        pdf.drawCentredString(x + phone_w / 2, 98, label)
        x += 145
    pdf.setFillColor(GREEN_DARK)
    pdf.rect(46, 70, PAGE_W - 92, 7, fill=1, stroke=0)
    pdf.setFillColor(HexColor("#625E55"))
    pdf.setFont("Helvetica-Bold", 7)
    pdf.drawString(46, 49, "NO EMULATOR CAPTURES  /  GOLDEN-TEST RASTER OUTPUT  /  RTL VERIFIED")
    pdf.showPage()


def draw_contents(pdf: Canvas) -> None:
    pdf.setFillColor(BLACK)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    draw_image_cover(pdf, PATTERN, 610, 0, 350, PAGE_H)
    overlay(pdf, "#0D0E0C", 0.48, 610, 0, 350, PAGE_H)

    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 32)
    pdf.drawString(54, PAGE_H - 70, "CONTENTS")
    pdf.setFillColor(MUTED_LIGHT)
    pdf.setFont("Helvetica", 10)
    pdf.drawString(54, PAGE_H - 92, "Six connected product areas / forty-nine complete views")

    y = PAGE_H - 144
    for section in SECTIONS:
        pdf.setStrokeColor(LINE)
        pdf.setLineWidth(0.8)
        pdf.line(54, y - 44, 574, y - 44)
        pdf.setFillColor(GREEN)
        pdf.setFont("Helvetica-Bold", 22)
        pdf.drawString(54, y - 20, section.number)
        pdf.setFillColor(WHITE)
        pdf.setFont("Helvetica-Bold", 13)
        pdf.drawString(112, y - 14, section.title)
        pdf.setFillColor(MUTED_LIGHT)
        pdf.setFont("Helvetica", 8.5)
        pdf.drawString(112, y - 31, section.subtitle)
        pdf.setFillColor(GOLD)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawRightString(574, y - 19, f"SCREENS {section.start:02d}-{section.end:02d}")
        y -= 72
    pdf.showPage()


def draw_section_divider(pdf: Canvas, section: Section) -> None:
    screen = SCREENS[section.representative - 1]
    draw_image_cover(pdf, screen.dark, 0, 0, PAGE_W, PAGE_H)
    overlay(pdf, "#080906", 0.72, 0, 0, PAGE_W, PAGE_H)
    overlay(pdf, "#080906", 0.32, 0, 0, PAGE_W * 0.60, PAGE_H)

    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(58, PAGE_H - 78, f"SECTION {section.number}")
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 42)
    pdf.drawString(58, PAGE_H - 136, section.title)
    pdf.setFillColor(MUTED_LIGHT)
    pdf.setFont("Helvetica", 13)
    pdf.drawString(58, PAGE_H - 168, section.subtitle)

    image_w = 392.0
    image_h = image_w * 9 / 16
    draw_picture_frame(
        pdf,
        screen.light,
        PAGE_W - image_w - 58,
        84,
        image_w,
        image_h,
        light=True,
        radius=12,
    )
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(
        58,
        66,
        f"{section.end - section.start + 1} SCREENS  /  {section.start:02d}-{section.end:02d}",
    )
    pdf.showPage()


def draw_screen_page(pdf: Canvas, screen: Screen, index: int) -> None:
    section = section_for(index)
    pdf.setFillColor(BLACK)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    pdf.setFillColor(GREEN)
    pdf.rect(32, PAGE_H - 58, 7, 30, fill=1, stroke=0)
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 23)
    pdf.drawString(54, PAGE_H - 50, screen.title.upper())
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(PAGE_W - 32, PAGE_H - 38, screen.section)
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(PAGE_W - 32, PAGE_H - 52, f"SCREEN {index:02d} / 49")
    pdf.setStrokeColor(LINE)
    pdf.line(32, PAGE_H - 69, PAGE_W - 32, PAGE_H - 69)

    main_y = 210.0
    main_w = 432.0
    main_h = main_w * 9 / 16
    left_x = 32.0
    right_x = PAGE_W - 32.0 - main_w

    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 7.5)
    pdf.drawString(left_x, main_y + main_h + 12, "DARK THEME  /  1280 x 720")
    pdf.setFillColor(GOLD)
    pdf.drawString(right_x, main_y + main_h + 12, "LIGHT THEME  /  1280 x 720")
    draw_picture_frame(pdf, screen.dark, left_x, main_y, main_w, main_h, light=False)
    draw_picture_frame(pdf, screen.light, right_x, main_y, main_w, main_h, light=True)

    compact_y = 43.0
    compact_w = 300.0
    compact_h = compact_w * 390 / 844
    compact_dark_x = 32.0
    compact_light_x = 348.0

    pdf.setFillColor(MUTED_LIGHT)
    pdf.setFont("Helvetica-Bold", 7)
    pdf.drawString(compact_dark_x, compact_y + compact_h + 10, "COMPACT DARK  /  844 x 390")
    pdf.drawString(compact_light_x, compact_y + compact_h + 10, "COMPACT LIGHT  /  844 x 390")
    draw_picture_frame(
        pdf,
        screen.compact_dark,
        compact_dark_x,
        compact_y,
        compact_w,
        compact_h,
        light=False,
        radius=6,
    )
    draw_picture_frame(
        pdf,
        screen.compact_light,
        compact_light_x,
        compact_y,
        compact_w,
        compact_h,
        light=True,
        radius=6,
    )

    info_x = 676.0
    info_w = PAGE_W - info_x - 32
    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(info_x, compact_y + compact_h - 3, f"{index:02d}")
    pdf.setFillColor(WHITE)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(info_x, compact_y + compact_h - 29, "PLAYER PURPOSE")
    pdf.setFillColor(MUTED_LIGHT)
    pdf.setFont("Helvetica", 8.5)
    purpose_lines = wrap_text(screen.purpose, "Helvetica", 8.5, info_w)
    y = compact_y + compact_h - 47
    for line in purpose_lines[:3]:
        pdf.drawString(info_x, y, line)
        y -= 13

    tag_y = 62.0
    tags = ("REAL FLUTTER UI", "RTL", "LIGHT + DARK", "RESPONSIVE")
    tag_x = info_x
    for tag in tags:
        tag_w = stringWidth(tag, "Helvetica-Bold", 6.7) + 18
        if tag_x + tag_w > PAGE_W - 32:
            tag_x = info_x
            tag_y -= 25
        pdf.setStrokeColor(LINE)
        pdf.setFillColor(BLACK_2)
        pdf.roundRect(tag_x, tag_y, tag_w, 19, 4, fill=1, stroke=1)
        pdf.setFillColor(MUTED_LIGHT)
        pdf.setFont("Helvetica-Bold", 6.7)
        pdf.drawCentredString(tag_x + tag_w / 2, tag_y + 6.5, tag)
        tag_x += tag_w + 6

    pdf.setFillColor(HexColor("#666861"))
    pdf.setFont("Helvetica", 6.8)
    pdf.drawString(32, 25, "AHDASH | 11  /  CLIENT EXPERIENCE BOOK  /  SEPTEMBER 2026")
    pdf.drawRightString(PAGE_W - 32, 25, f"{section.number}  /  {section.title}")
    pdf.showPage()


def draw_closing(pdf: Canvas) -> None:
    draw_image_cover(pdf, PATTERN, 0, 0, PAGE_W, PAGE_H)
    overlay(pdf, "#070806", 0.67, 0, 0, PAGE_W, PAGE_H)

    pdf.setFillColor(PAPER)
    pdf.roundRect(54, 72, PAGE_W - 108, PAGE_H - 144, 18, fill=1, stroke=0)
    draw_image_contain(pdf, SYMBOL, 82, PAGE_H - 228, 108, 132)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 34)
    pdf.drawString(218, PAGE_H - 150, "READY FOR CLIENT REVIEW")
    pdf.setFillColor(HexColor("#69645A"))
    pdf.setFont("Helvetica", 11)
    pdf.drawString(218, PAGE_H - 179, "The complete AHDASH | 11 mobile experience in one visual narrative.")
    pdf.setStrokeColor(LINE_LIGHT)
    pdf.line(218, PAGE_H - 204, PAGE_W - 82, PAGE_H - 204)

    values = (("49", "SCREENS"), ("2", "THEMES"), ("6", "VIEWPORTS INCLUDING PORTRAIT"))
    x = 218.0
    for value, label in values:
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 24)
        pdf.drawString(x, PAGE_H - 259, value)
        pdf.setFillColor(HexColor("#777167"))
        pdf.setFont("Helvetica-Bold", 7)
        pdf.drawString(x, PAGE_H - 278, label)
        x += 190

    thumb_y = 116.0
    thumb_w = 138.0
    thumb_h = thumb_w * 9 / 16
    for i, screen_index in enumerate((5, 12, 23, 31, 37)):
        draw_picture_frame(
            pdf,
            SCREENS[screen_index - 1].dark,
            218 + (i * 142),
            thumb_y,
            thumb_w,
            thumb_h,
            light=False,
            radius=4,
        )
    pdf.setFillColor(GREEN_DARK)
    pdf.rect(218, 92, PAGE_W - 300, 7, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawString(218, 76, "AHDASH | 11  /  PRODUCT EXPERIENCE V10  /  SEPTEMBER 2026")
    pdf.showPage()


def main() -> None:
    ensure_inputs()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf = Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H), pageCompression=1)
    pdf.setTitle("AHDASH | 11 - Complete Screen Catalog V10")
    pdf.setAuthor("AHDASH | 11")
    pdf.setSubject("Client-ready catalog of 49 real Flutter screens and states")
    pdf.setCreator("Codex / ReportLab")

    draw_cover(pdf)
    draw_overview(pdf)
    draw_orientation_proof(pdf)
    draw_contents(pdf)
    for section in SECTIONS:
        draw_section_divider(pdf, section)
        for index in range(section.start, section.end + 1):
            draw_screen_page(pdf, SCREENS[index - 1], index)
    draw_closing(pdf)
    pdf.save()
    print(OUTPUT)


if __name__ == "__main__":
    main()
