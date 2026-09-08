from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import Color, HexColor
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen.canvas import Canvas

from build_v8_2_screen_catalog_pdf import SCREENS


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "ahdash_11_client_screen_presentation_v8_2.pdf"

PAGE_W, PAGE_H = landscape(A4)
BLACK = HexColor("#0B0F14")
INK = HexColor("#131922")
CREAM = HexColor("#F7F9FB")
WARM = HexColor("#F7F4EC")
MUTED = HexColor("#8E98A7")
GREEN = HexColor("#B6FF3B")
GOLD = HexColor("#FFC857")
LINE = HexColor("#2B323D")

BRAND = ROOT / "mobile" / "assets" / "branding"
VISUALS = ROOT / "mobile" / "assets" / "visuals"
LOGO = BRAND / "logo-horizontal.png"
SYMBOL = BRAND / "logo-symbol.png"
PATTERN = BRAND / "brand-pattern.png"
HOME_HERO = VISUALS / "home-hero.png"


@dataclass(frozen=True)
class Section:
    number: str
    title: str
    subtitle: str
    start: int
    end: int
    image: Path


SECTIONS = (
    Section("01", "FOUNDATION", "Entry, identity and the first product moment", 1, 5, HOME_HERO),
    Section("02", "PARTY GAME", "The shared football quiz experience", 6, 18, VISUALS / "player_11_stadium_hero.png"),
    Section("03", "TOURNAMENT", "From team creation to the final celebration", 19, 27, VISUALS / "results-backdrop.png"),
    Section("04", "PLAY MODES", "Solo, online and private competition", 28, 33, VISUALS / "eagle-eye-cover.png"),
    Section("05", "ACCOUNT & SOCIAL", "Profile, community, preferences and premium", 34, 43, PATTERN),
)


def ensure_inputs() -> None:
    if len(SCREENS) != 43:
        raise RuntimeError(f"Expected 43 screens, found {len(SCREENS)}")
    paths = [LOGO, SYMBOL, PATTERN, HOME_HERO]
    for section in SECTIONS:
        paths.append(section.image)
    for screen in SCREENS:
        paths.extend([screen.light, screen.dark])
        if screen.compact_light:
            paths.append(screen.compact_light)
        if screen.compact_dark:
            paths.append(screen.compact_dark)
    missing = sorted({path for path in paths if not path.is_file()})
    if missing:
        raise FileNotFoundError("Missing inputs:\n" + "\n".join(map(str, missing)))


def section_for(index: int) -> Section:
    return next(section for section in SECTIONS if section.start <= index <= section.end)


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
    image_w, image_h = image_size(path)
    scale = min(width / image_w, height / image_h)
    draw_w = image_w * scale
    draw_h = image_h * scale
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
    image_w, image_h = image_size(path)
    scale = max(width / image_w, height / image_h)
    draw_w = image_w * scale
    draw_h = image_h * scale
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


def translucent_rect(
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


def draw_logo_card(pdf: Canvas, x: float, y: float, width: float, height: float) -> None:
    pdf.setFillColor(WARM)
    pdf.roundRect(x, y, width, height, 12, fill=1, stroke=0)
    draw_image_contain(pdf, LOGO, x + 16, y + 11, width - 32, height - 22)


def draw_cover(pdf: Canvas) -> None:
    draw_image_cover(pdf, HOME_HERO, 0, 0, PAGE_W, PAGE_H)
    translucent_rect(pdf, "#050709", 0.55, 0, 0, PAGE_W, PAGE_H)
    translucent_rect(pdf, "#050709", 0.28, PAGE_W * 0.48, 0, PAGE_W * 0.52, PAGE_H)

    draw_logo_card(pdf, 54, PAGE_H - 120, 236, 64)
    pdf.setFillColor(GREEN)
    pdf.rect(54, PAGE_H - 210, 9, 62, fill=1, stroke=0)
    pdf.setFillColor(CREAM)
    pdf.setFont("Helvetica-Bold", 31)
    pdf.drawString(82, PAGE_H - 172, "PRODUCT EXPERIENCE")
    pdf.setFont("Helvetica-Bold", 31)
    pdf.drawString(82, PAGE_H - 208, "SCREEN PRESENTATION")
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 13)
    pdf.drawString(54, PAGE_H - 246, "A COMPLETE VISUAL WALKTHROUGH - V8.2")

    pdf.setFillColor(CREAM)
    pdf.setFont("Helvetica", 11)
    pdf.drawString(54, PAGE_H - 278, "Prepared for client review")
    pdf.setFillColor(HexColor("#C4CBD4"))
    pdf.drawString(54, PAGE_H - 297, "Mobile landscape experience - September 2026")

    chips = (("43", "SCREENS"), ("2", "THEMES"), ("5", "PRODUCT AREAS"))
    chip_x = 54
    for value, label in chips:
        pdf.setFillColor(Color(0.07, 0.09, 0.12, alpha=0.82))
        pdf.roundRect(chip_x, 62, 132, 58, 9, fill=1, stroke=0)
        pdf.setFillColor(GREEN)
        pdf.setFont("Helvetica-Bold", 18)
        pdf.drawString(chip_x + 15, 87, value)
        pdf.setFillColor(CREAM)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawString(chip_x + 48, 90, label)
        chip_x += 144
    pdf.showPage()


def draw_overview(pdf: Canvas) -> None:
    pdf.setFillColor(BLACK)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    draw_image_cover(pdf, PATTERN, PAGE_W * 0.52, 0, PAGE_W * 0.48, PAGE_H)
    translucent_rect(pdf, "#0B0F14", 0.38, PAGE_W * 0.52, 0, PAGE_W * 0.48, PAGE_H)

    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(54, PAGE_H - 64, "THE PRODUCT AT A GLANCE")
    pdf.setFillColor(CREAM)
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(54, PAGE_H - 108, "One football experience.")
    pdf.drawString(54, PAGE_H - 144, "Every important screen.")
    pdf.setFillColor(HexColor("#B7C0CB"))
    pdf.setFont("Helvetica", 11)
    lines = (
        "This presentation brings the complete AHDASH | 11 experience",
        "into one client-ready visual narrative - from first launch and",
        "authentication to party play, tournaments and social features.",
    )
    y = PAGE_H - 188
    for line in lines:
        pdf.drawString(54, y, line)
        y -= 18

    metrics = (("43", "REAL SCREENS / STATES"), ("LIGHT + DARK", "THEME COVERAGE"), ("1280 x 720", "PRIMARY VIEWPORT"))
    y = 178
    for value, label in metrics:
        pdf.setStrokeColor(LINE)
        pdf.line(54, y + 54, 394, y + 54)
        pdf.setFillColor(GREEN if value == "43" else GOLD)
        pdf.setFont("Helvetica-Bold", 20)
        pdf.drawString(54, y + 22, value)
        pdf.setFillColor(MUTED)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawRightString(394, y + 27, label)
        y -= 62
    pdf.showPage()


def draw_contents(pdf: Canvas) -> None:
    pdf.setFillColor(WARM)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(54, PAGE_H - 70, "CONTENTS")
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica", 10)
    pdf.drawString(54, PAGE_H - 92, "Five connected product areas - forty-three complete views")

    y = PAGE_H - 148
    for section in SECTIONS:
        pdf.setFillColor(INK)
        pdf.roundRect(54, y - 58, PAGE_W - 108, 70, 10, fill=1, stroke=0)
        pdf.setFillColor(GREEN)
        pdf.setFont("Helvetica-Bold", 22)
        pdf.drawString(72, y - 27, section.number)
        pdf.setFillColor(CREAM)
        pdf.setFont("Helvetica-Bold", 13)
        pdf.drawString(124, y - 19, section.title)
        pdf.setFillColor(HexColor("#9EA7B3"))
        pdf.setFont("Helvetica", 8.5)
        pdf.drawString(124, y - 38, section.subtitle)
        pdf.setFillColor(GOLD)
        pdf.setFont("Helvetica-Bold", 9)
        pdf.drawRightString(PAGE_W - 72, y - 25, f"SCREENS {section.start:02d}-{section.end:02d}")
        y -= 80
    pdf.showPage()


def draw_section_divider(pdf: Canvas, section: Section) -> None:
    draw_image_cover(pdf, section.image, 0, 0, PAGE_W, PAGE_H)
    translucent_rect(pdf, "#080B0F", 0.72, 0, 0, PAGE_W, PAGE_H)
    translucent_rect(pdf, "#080B0F", 0.30, 0, 0, PAGE_W * 0.58, PAGE_H)

    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(56, PAGE_H - 86, f"SECTION {section.number}")
    pdf.setFillColor(CREAM)
    pdf.setFont("Helvetica-Bold", 38)
    pdf.drawString(56, PAGE_H - 144, section.title)
    pdf.setFillColor(HexColor("#C4CBD4"))
    pdf.setFont("Helvetica", 13)
    pdf.drawString(56, PAGE_H - 176, section.subtitle)
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(56, 70, f"{section.end - section.start + 1} SCREENS  /  {section.start:02d}-{section.end:02d}")
    pdf.showPage()


def draw_framed_image(
    pdf: Canvas,
    path: Path,
    x: float,
    y: float,
    width: float,
    height: float,
    *,
    border: object = LINE,
    radius: float = 8,
) -> None:
    pdf.setFillColor(HexColor("#080B0F"))
    pdf.setStrokeColor(border)
    pdf.setLineWidth(1)
    pdf.roundRect(x - 3, y - 3, width + 6, height + 6, radius, fill=1, stroke=1)
    draw_image_contain(pdf, path, x, y, width, height)


def draw_screen_page(pdf: Canvas, screen, index: int) -> None:
    section = section_for(index)
    pdf.setFillColor(BLACK)
    pdf.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    pdf.setFillColor(GREEN)
    pdf.rect(34, PAGE_H - 53, 7, 25, fill=1, stroke=0)
    pdf.setFillColor(CREAM)
    pdf.setFont("Helvetica-Bold", 22)
    pdf.drawString(55, PAGE_H - 47, screen.title.upper())
    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(PAGE_W - 34, PAGE_H - 38, section.title)
    pdf.setStrokeColor(LINE)
    pdf.line(34, PAGE_H - 65, PAGE_W - 34, PAGE_H - 65)

    main_x, main_y, main_w, main_h = 34, 118, 620, 348.75
    pdf.setFillColor(GOLD)
    pdf.setFont("Helvetica-Bold", 7.5)
    pdf.drawString(main_x, main_y + main_h + 10, "PRIMARY VIEW / DARK THEME / 1280 x 720")
    draw_framed_image(pdf, screen.dark, main_x, main_y, main_w, main_h, border=HexColor("#343C48"))

    rail_x = 686
    rail_w = PAGE_W - rail_x - 34
    pdf.setFillColor(GREEN)
    pdf.setFont("Helvetica-Bold", 32)
    pdf.drawString(rail_x, PAGE_H - 112, f"{index:02d}")
    pdf.setFillColor(HexColor("#606B78"))
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(PAGE_W - 34, PAGE_H - 101, "/ 43")

    pdf.setFillColor(MUTED)
    pdf.setFont("Helvetica-Bold", 7)
    pdf.drawString(rail_x, PAGE_H - 155, "LIGHT THEME")
    light_h = rail_w * 9 / 16
    draw_framed_image(pdf, screen.light, rail_x, PAGE_H - 164 - light_h, rail_w, light_h, border=HexColor("#E8E0D2"), radius=5)

    cursor_y = PAGE_H - 190 - light_h
    if screen.compact_light is not None and screen.compact_dark is not None:
        pdf.setFillColor(MUTED)
        pdf.setFont("Helvetica-Bold", 7)
        pdf.drawString(rail_x, cursor_y, "COMPACT 844 x 390")
        compact_h = rail_w * 390 / 844
        draw_framed_image(pdf, screen.compact_dark, rail_x, cursor_y - compact_h - 10, rail_w, compact_h, border=HexColor("#343C48"), radius=5)
        draw_framed_image(pdf, screen.compact_light, rail_x, cursor_y - (compact_h * 2) - 18, rail_w, compact_h, border=HexColor("#E8E0D2"), radius=5)
    else:
        tags = ("LANDSCAPE", "RTL READY", "REAL UI")
        tag_y = cursor_y - 6
        for tag in tags:
            pdf.setStrokeColor(LINE)
            pdf.setFillColor(INK)
            pdf.roundRect(rail_x, tag_y - 23, rail_w, 23, 5, fill=1, stroke=1)
            pdf.setFillColor(HexColor("#C5CCD5"))
            pdf.setFont("Helvetica-Bold", 7)
            pdf.drawCentredString(rail_x + rail_w / 2, tag_y - 15, tag)
            tag_y -= 31

    pdf.setFillColor(HexColor("#6D7784"))
    pdf.setFont("Helvetica", 7)
    pdf.drawString(34, 35, "CLIENT SCREEN REVIEW")
    pdf.drawCentredString(PAGE_W / 2, 35, "AHDASH | 11 - PRODUCT EXPERIENCE V8.2")
    pdf.drawRightString(PAGE_W - 34, 35, f"{section.number} / {section.title}")
    pdf.showPage()


def draw_closing(pdf: Canvas) -> None:
    draw_image_cover(pdf, PATTERN, 0, 0, PAGE_W, PAGE_H)
    translucent_rect(pdf, "#080B0F", 0.58, 0, 0, PAGE_W, PAGE_H)
    pdf.setFillColor(WARM)
    pdf.roundRect(54, 80, PAGE_W - 108, PAGE_H - 160, 18, fill=1, stroke=0)
    draw_image_contain(pdf, SYMBOL, 76, PAGE_H - 228, 96, 120)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 32)
    pdf.drawString(200, PAGE_H - 148, "READY FOR CLIENT REVIEW")
    pdf.setFillColor(HexColor("#59616D"))
    pdf.setFont("Helvetica", 12)
    pdf.drawString(200, PAGE_H - 178, "A complete visual presentation of the AHDASH | 11 mobile experience.")
    pdf.setStrokeColor(HexColor("#D9DDE2"))
    pdf.line(200, PAGE_H - 205, PAGE_W - 82, PAGE_H - 205)

    items = (("43", "screens and states"), ("2", "visual themes"), ("5", "connected product areas"))
    x = 200
    for value, label in items:
        pdf.setFillColor(INK)
        pdf.setFont("Helvetica-Bold", 24)
        pdf.drawString(x, PAGE_H - 258, value)
        pdf.setFillColor(HexColor("#737B86"))
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawString(x, PAGE_H - 276, label.upper())
        x += 165
    pdf.setFillColor(GREEN)
    pdf.rect(200, 118, PAGE_W - 282, 8, fill=1, stroke=0)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(200, 97, "AHDASH | 11  /  PRODUCT EXPERIENCE V8.2  /  SEPTEMBER 2026")
    pdf.showPage()


def main() -> None:
    ensure_inputs()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf = Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H), pageCompression=1)
    pdf.setTitle("AHDASH | 11 - Client Screen Presentation V8.2")
    pdf.setAuthor("AHDASH | 11")
    pdf.setSubject("Client-ready presentation of 43 Flutter screens and states")

    draw_cover(pdf)
    draw_overview(pdf)
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
