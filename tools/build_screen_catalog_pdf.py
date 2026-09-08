from __future__ import annotations

from pathlib import Path

from PIL import Image
from reportlab.lib.colors import Color, HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas


ROOT = Path(r"C:\dev\ahdash11")
V8_CHECKPOINT = ROOT / "docs" / "visual-validation" / "v8-checkpoint"
V8_PHASE_TWO = ROOT / "docs" / "visual-validation" / "v8-phase-two"
V8_PHASE_THREE = ROOT / "docs" / "visual-validation" / "v8-phase-three"
V8_PHASE_FOUR = ROOT / "docs" / "visual-validation" / "v8-phase-four"
V8_1_PICTOGRAMS = ROOT / "docs" / "visual-validation" / "v8-1-pictograms"
PICTOGRAM_CONTACT_SHEET = (
    ROOT / "docs" / "visual-validation" / "ahdash-pictograms-contact-sheet.png"
)
PAGES = ROOT / "docs" / "screenshots" / "mobile" / "pages"
GOLDENS = ROOT / "docs" / "visual-validation" / "goldens"
OUTPUT_DIR = ROOT / "output" / "pdf"
OUTPUT = OUTPUT_DIR / "ahdash11-all-screens-v8-1.pdf"

PAGE_W = 960
PAGE_H = 540
INK = HexColor("#14130F")
PAPER = HexColor("#F7F3E8")
MUTED = HexColor("#8C8476")
LINE = HexColor("#D9D0BF")
LIME = HexColor("#A7FF2F")
GOLD = HexColor("#FFC857")


PRIMARY_SCREENS = [
    (V8_CHECKPOINT, "signIn", "Sign in", "/auth"),
    (V8_CHECKPOINT, "createAccount", "Create account", "/auth · create account"),
    (V8_CHECKPOINT, "home", "Home", "/home"),
    (V8_CHECKPOINT, "categories", "Party category selection", "/party/categories"),
    (V8_PHASE_TWO, "teams", "Party team setup", "/party/teams"),
    (V8_1_PICTOGRAMS, "helpers", "Party helpers", "/party/helpers"),
    (V8_PHASE_TWO, "ready", "Party ready", "/party/ready"),
    (V8_CHECKPOINT, "board", "Party game board", "/party/board"),
    (V8_CHECKPOINT, "question", "Party question", "/party/question"),
    (V8_PHASE_TWO, "reveal", "Party answer reveal", "/party/reveal"),
    (V8_1_PICTOGRAMS, "result", "Party result", "/party/result"),
    (V8_PHASE_TWO, "howTo", "How to play", "/how-to-play"),
    (V8_1_PICTOGRAMS, "tournamentHub", "Tournament hub", "/tournaments"),
    (V8_1_PICTOGRAMS, "tournamentCreate", "Create tournament", "/tournaments/create"),
    (V8_PHASE_THREE, "tournamentTeams", "Tournament teams", "/tournaments/teams"),
    (V8_1_PICTOGRAMS, "tournamentDraw", "Tournament draw", "/tournaments/draw"),
    (V8_PHASE_THREE, "tournamentBracket", "Tournament bracket", "/tournaments/bracket"),
    (V8_CHECKPOINT, "tournamentMatch", "Tournament match", "/tournaments/match/:matchId"),
    (V8_1_PICTOGRAMS, "tournamentChampion", "Tournament champion", "/tournaments/champion"),
    (V8_CHECKPOINT, "profile", "Profile", "/profile"),
    (V8_1_PICTOGRAMS, "notifications", "Notifications", "/notifications"),
    (V8_PHASE_THREE, "settings", "Settings", "/settings"),
    (V8_1_PICTOGRAMS, "premium", "Premium", "/store"),
    (V8_PHASE_FOUR, "footballPreferences", "Football preferences", "/football-preferences"),
]

SECONDARY_SCREENS = [
    ("launch", "Launch", "/launch", "1280x720"),
    ("onboarding", "Onboarding", "/onboarding", "1280x720"),
    ("gameSetup", "Match setup", "/play/setup/:gameType", "1280x720"),
    ("soloSetup", "Solo setup", "/solo", "1280x720"),
    ("onlineLobby", "Online lobby", "/online", "1280x720"),
    ("onlineMatch", "Online match", "/online/match/:matchId", "1280x720"),
    ("roomLobby", "Private room", "/room/:roomId", "1280x720"),
    ("friends", "Friends", "/friends", "1280x720"),
    ("blockedPlayers", "Blocked players", "/blocked-players", "1280x720"),
    ("socialTeam", "Team detail", "/teams/:teamId", "1280x720"),
    ("teamChallenge", "Team challenge", "/challenges/:challengeId", "1280x760"),
    ("reportProblem", "Report a problem", "/report-problem", "1280x720"),
    ("partyGames", "Saved party games", "/party/games", "1280x720"),
    ("ranking", "Ranking", "/ranking", "1280x720"),
]

ADDITIONAL_SCREENS = [
    ("play", "Game selection", "/play"),
    ("categories", "Classic categories", "/categories"),
    ("question", "Solo match question", "/solo/match"),
    ("results", "Solo match result", "/solo/result"),
    ("teams", "Social hub", "/teams"),
]


class Catalog:
    def __init__(self, output: Path):
        self.output = output
        self.page_number = 0
        self.pdf = canvas.Canvas(str(output), pagesize=(PAGE_W, PAGE_H), pageCompression=1)
        self.pdf.setTitle("AHDASH 11 - Complete Screen Catalog V8.1")
        self.pdf.setAuthor("AHDASH 11 Product Team")
        self.pdf.setSubject("Complete Flutter application screen catalog")
        self.pdf.setCreator("Codex")

    def _new_page(self, background=PAPER):
        self.pdf.setFillColor(background)
        self.pdf.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)

    def _finish_page(self):
        self.page_number += 1
        self.pdf.setFillColor(MUTED)
        self.pdf.setFont("Helvetica", 7)
        self.pdf.drawRightString(PAGE_W - 22, 14, f"AHDASH 11 · V8.1 · {self.page_number:02d}")
        self.pdf.showPage()

    def cover(self, logo: Path, screen_count: int):
        self._new_page(INK)
        self.pdf.setFillColor(LIME)
        self.pdf.rect(0, PAGE_H - 10, PAGE_W, 10, stroke=0, fill=1)
        self.pdf.setFillColor(GOLD)
        self.pdf.rect(PAGE_W - 14, 0, 14, PAGE_H, stroke=0, fill=1)
        if logo.exists():
            self.pdf.setFillColor(PAPER)
            self.pdf.roundRect(342, 312, 276, 76, 10, stroke=0, fill=1)
            self._draw_contained(logo, 364, 328, 232, 44)
        self.pdf.setFillColor(HexColor("#FFFFFF"))
        self.pdf.setFont("Helvetica-Bold", 29)
        self.pdf.drawCentredString(PAGE_W / 2, 252, "COMPLETE SCREEN CATALOG")
        self.pdf.setFillColor(LIME)
        self.pdf.setFont("Helvetica-Bold", 15)
        self.pdf.drawCentredString(PAGE_W / 2, 218, "VISUAL SYSTEM V8.1")
        self.pdf.setFillColor(HexColor("#BEB8AA"))
        self.pdf.setFont("Helvetica", 10)
        self.pdf.drawCentredString(
            PAGE_W / 2,
            176,
            f"{screen_count} screens and states · Light / Dark · Landscape coverage",
        )
        self.pdf.setStrokeColor(Color(1, 1, 1, alpha=0.16))
        self.pdf.line(190, 154, PAGE_W - 190, 154)
        self.pdf.setFillColor(HexColor("#7E786D"))
        self.pdf.setFont("Helvetica", 8)
        self.pdf.drawCentredString(PAGE_W / 2, 126, "Generated from Flutter golden renders · No emulator · No APK")
        self._finish_page()

    def contact_sheet(self, image: Path):
        if not image.exists():
            raise FileNotFoundError(image)
        self._new_page()
        self.pdf.setFillColor(INK)
        self.pdf.rect(0, PAGE_H - 66, PAGE_W, 66, stroke=0, fill=1)
        self.pdf.setFillColor(GOLD)
        self.pdf.rect(0, PAGE_H - 66, 8, 66, stroke=0, fill=1)
        self.pdf.setFillColor(HexColor("#FFFFFF"))
        self.pdf.setFont("Helvetica-Bold", 16)
        self.pdf.drawString(28, PAGE_H - 31, "AHDASH raster pictogram contact sheet")
        self.pdf.setFillColor(HexColor("#AAA397"))
        self.pdf.setFont("Helvetica", 8)
        self.pdf.drawString(
            29,
            PAGE_H - 49,
            "15 transparent PNG masters · Light Ink / Dark inverse / Gold",
        )
        self.pdf.setFillColor(HexColor("#E8E1D4"))
        self.pdf.roundRect(28, 30, PAGE_W - 56, PAGE_H - 116, 9, stroke=0, fill=1)
        self._draw_contained(image, 40, 42, PAGE_W - 80, PAGE_H - 140)
        self._finish_page()

    def divider(self, index: str, title: str, subtitle: str):
        self._new_page(INK)
        self.pdf.setFillColor(LIME)
        self.pdf.setFont("Helvetica-Bold", 92)
        self.pdf.drawString(58, 340, index)
        self.pdf.setFillColor(HexColor("#FFFFFF"))
        self.pdf.setFont("Helvetica-Bold", 30)
        self.pdf.drawString(62, 260, title.upper())
        self.pdf.setFillColor(HexColor("#A8A296"))
        self.pdf.setFont("Helvetica", 12)
        self.pdf.drawString(64, 222, subtitle)
        self.pdf.setFillColor(GOLD)
        self.pdf.rect(64, 192, 96, 5, stroke=0, fill=1)
        self._finish_page()

    def screen_page(
        self,
        title: str,
        route: str,
        viewport: str,
        light: Path,
        dark: Path,
        sequence: str,
    ):
        for path in (light, dark):
            if not path.exists():
                raise FileNotFoundError(path)
        self._new_page()
        self.pdf.setFillColor(INK)
        self.pdf.rect(0, PAGE_H - 66, PAGE_W, 66, stroke=0, fill=1)
        self.pdf.setFillColor(LIME)
        self.pdf.rect(0, PAGE_H - 66, 8, 66, stroke=0, fill=1)
        self.pdf.setFillColor(HexColor("#FFFFFF"))
        self.pdf.setFont("Helvetica-Bold", 16)
        self.pdf.drawString(28, PAGE_H - 31, title)
        self.pdf.setFillColor(HexColor("#AAA397"))
        self.pdf.setFont("Helvetica", 8)
        self.pdf.drawString(29, PAGE_H - 49, f"{route}   ·   {viewport}")
        self.pdf.setFillColor(GOLD)
        self.pdf.setFont("Helvetica-Bold", 12)
        self.pdf.drawRightString(PAGE_W - 26, PAGE_H - 37, sequence)

        margin_x = 28
        gap = 20
        frame_w = (PAGE_W - margin_x * 2 - gap) / 2
        frame_h = PAGE_H - 106
        self._image_frame(light, margin_x, 30, frame_w, frame_h, "LIGHT")
        self._image_frame(dark, margin_x + frame_w + gap, 30, frame_w, frame_h, "DARK")
        self._finish_page()

    def _image_frame(self, path: Path, x: float, y: float, w: float, h: float, label: str):
        self.pdf.setFillColor(HexColor("#E8E1D4"))
        self.pdf.roundRect(x, y, w, h, 9, stroke=0, fill=1)
        self.pdf.setFillColor(INK)
        self.pdf.roundRect(x + 8, y + h - 27, 54, 18, 5, stroke=0, fill=1)
        self.pdf.setFillColor(LIME if label == "LIGHT" else GOLD)
        self.pdf.setFont("Helvetica-Bold", 6.5)
        self.pdf.drawCentredString(x + 35, y + h - 21, label)
        self._draw_contained(path, x + 8, y + 8, w - 16, h - 42)

    def _draw_contained(self, path: Path, x: float, y: float, w: float, h: float):
        with Image.open(path) as source:
            image_w, image_h = source.size
        scale = min(w / image_w, h / image_h)
        draw_w = image_w * scale
        draw_h = image_h * scale
        draw_x = x + (w - draw_w) / 2
        draw_y = y + (h - draw_h) / 2
        self.pdf.drawImage(
            ImageReader(str(path)),
            draw_x,
            draw_y,
            width=draw_w,
            height=draw_h,
            preserveAspectRatio=True,
            mask="auto",
        )

    def save(self):
        self.pdf.save()


def primary_pair(directory: Path, name: str, viewport: str) -> tuple[Path, Path]:
    return (
        directory / f"{name}_{viewport}_light.png",
        directory / f"{name}_{viewport}_dark.png",
    )


def secondary_pair(name: str, viewport: str) -> tuple[Path, Path]:
    return (
        PAGES / f"{name}_{viewport}_light.png",
        PAGES / f"{name}_{viewport}_dark.png",
    )


def additional_pair(name: str) -> tuple[Path, Path]:
    return (
        GOLDENS / f"{name}_1280x720_light.png",
        GOLDENS / f"{name}_1280x720_dark.png",
    )


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    catalog = Catalog(OUTPUT)
    screen_count = (
        len(PRIMARY_SCREENS) + len(SECONDARY_SCREENS) + len(ADDITIONAL_SCREENS)
    )
    catalog.cover(
        ROOT / "mobile" / "assets" / "branding" / "logo-horizontal.png",
        screen_count,
    )

    catalog.divider(
        "01",
        "Core experience",
        "Primary V8 screens · paired Light and Dark renders",
    )
    for index, (directory, name, title, route) in enumerate(
        PRIMARY_SCREENS, start=1
    ):
        light, dark = primary_pair(directory, name, "1280x720")
        catalog.screen_page(title, route, "1280 × 720", light, dark, f"01.{index:02d}A")

    catalog.divider("02", "Entry and match modes", "Onboarding, solo, online, rooms, and retained party games")
    for index, (name, title, route, viewport) in enumerate(SECONDARY_SCREENS, start=1):
        light, dark = secondary_pair(name, viewport)
        catalog.screen_page(title, route, viewport.replace("x", " × "), light, dark, f"02.{index:02d}")

    catalog.divider("03", "Supporting routes", "Classic, social, and preference screens")
    for index, (name, title, route) in enumerate(ADDITIONAL_SCREENS, start=1):
        light, dark = additional_pair(name)
        catalog.screen_page(title, route, "1280 × 720", light, dark, f"03.{index:02d}")

    catalog.divider(
        "04",
        "AHDASH pictogram system",
        "15 original transparent raster masters · one-color runtime tint",
    )
    catalog.contact_sheet(PICTOGRAM_CONTACT_SHEET)

    catalog.divider(
        "END",
        "Catalog complete",
        f"{screen_count} current screens and states · rendered from Flutter tests",
    )
    catalog.save()
    print(f"OUTPUT={OUTPUT}")
    print(f"SCREENS={screen_count}")
    print(f"PAGES={catalog.page_number}")


if __name__ == "__main__":
    main()
