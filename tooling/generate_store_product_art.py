"""Build the original local launch-catalog previews for Ahdash 11.

The source panels are original/generated-safe project assets. This script crops
and composes them into distinct, optimized product previews; it does not fetch
remote images or embed third-party marks.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "mobile" / "assets" / "images"
OUT = ASSETS / "store" / "products"
SIZE = 720
CHARCOAL = (11, 15, 20)
LIME = (182, 255, 59)
GOLD = (234, 182, 75)
SAND = (232, 216, 181)


def source(relative: str) -> Image.Image:
    return Image.open(ASSETS / relative).convert("RGB")


def square(image: Image.Image, box: tuple[int, int, int, int] | None = None) -> Image.Image:
    if box is not None:
        image = image.crop(box)
    return ImageOps.fit(image, (SIZE, SIZE), Image.Resampling.LANCZOS)


def shade(image: Image.Image, amount: int = 92) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (*CHARCOAL, amount))
    return Image.alpha_composite(image.convert("RGBA"), overlay)


def vignette(image: Image.Image) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    for inset in range(0, 150, 3):
        alpha = int(215 * (inset / 150) ** 1.6)
        draw.rounded_rectangle(
            (inset, inset, SIZE - inset, SIZE - inset),
            radius=max(12, 74 - inset // 3),
            outline=alpha,
            width=5,
        )
    dark = Image.new("RGBA", image.size, (*CHARCOAL, 0))
    dark.putalpha(mask.filter(ImageFilter.GaussianBlur(20)))
    return Image.alpha_composite(image.convert("RGBA"), dark)


def accent_frame(
    image: Image.Image,
    color: tuple[int, int, int],
    variant: int,
) -> Image.Image:
    canvas = shade(vignette(image), 52)
    draw = ImageDraw.Draw(canvas)
    if variant == 0:
        points = [(88, 102), (604, 102), (644, 146), (644, 590), (600, 632), (118, 632), (76, 588), (76, 150)]
        draw.line(points + [points[0]], fill=(*color, 245), width=18, joint="curve")
        draw.line([(112, 132), (582, 132), (614, 164)], fill=(*SAND, 155), width=5)
    elif variant == 1:
        for inset, width, alpha in ((72, 18, 245), (100, 8, 190), (124, 3, 130)):
            draw.rounded_rectangle(
                (inset, inset + 16, SIZE - inset, SIZE - inset - 16),
                radius=42 - inset // 5,
                outline=(*color, alpha),
                width=width,
            )
        draw.polygon([(260, 72), (460, 72), (424, 116), (296, 116)], fill=(*color, 230))
    else:
        points = [(118, 78), (602, 78), (654, 136), (654, 548), (584, 642), (136, 642), (66, 548), (66, 136)]
        draw.line(points + [points[0]], fill=(*color, 240), width=20, joint="curve")
        for x, y in ((94, 112), (626, 112), (94, 582), (626, 582)):
            draw.polygon([(x - 28, y), (x, y - 28), (x + 28, y), (x, y + 28)], fill=(*GOLD, 205))
    return canvas


def overlay_pattern(image: Image.Image, variant: int) -> Image.Image:
    canvas = shade(vignette(image), 66)
    draw = ImageDraw.Draw(canvas)
    if variant == 0:
        draw.polygon([(0, 540), (520, 0), (720, 0), (184, 720), (0, 720)], fill=(*LIME, 92))
        draw.line([(42, 642), (610, 74)], fill=(*SAND, 190), width=12)
    elif variant == 1:
        draw.polygon([(0, 0), (360, 0), (250, 720), (0, 720)], fill=(34, 61, 91, 116))
        draw.polygon([(360, 0), (720, 0), (720, 720), (470, 720)], fill=(*GOLD, 74))
        draw.line([(360, 40), (360, 680)], fill=(*SAND, 170), width=6)
    elif variant == 2:
        for idx in range(6):
            y = 96 + idx * 88
            offset = 34 if idx % 2 else 0
            step_color = GOLD if idx % 2 else SAND
            draw.polygon(
                [(80 + offset, y), (352 + offset, y), (410 + offset, y + 52), (136 + offset, y + 52)],
                fill=(*step_color, 86),
            )
    else:
        for idx in range(5):
            y = 126 + idx * 102
            draw.arc((60, y - 70, 660, y + 90), 200, 345, fill=(*LIME, 180 - idx * 18), width=16)
        draw.line([(110, 598), (610, 122)], fill=(*GOLD, 155), width=8)
    return canvas


def crop_panel(relative: str, column: int, columns: int = 3) -> Image.Image:
    image = source(relative)
    width = image.width // columns
    start = max(0, min(image.width - width, column * width))
    return square(image, (start, 0, start + width, image.height))


def save(name: str, image: Image.Image) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(OUT / f"{name}.webp", "WEBP", quality=82, method=6)


def main() -> None:
    backgrounds = [
        ("card_tunnel_lime", "backgrounds/home_background.webp", 1.12),
        ("card_night_pitch", "backgrounds/leaderboard_background.webp", 0.78),
        ("card_gold_stage", "backgrounds/profile_background.webp", 1.0),
        ("card_sand_geometry", "backgrounds/team_background.webp", 0.88),
    ]
    for index, (name, relative, saturation) in enumerate(backgrounds):
        image = square(source(relative))
        image = ImageEnhance.Color(image).enhance(saturation)
        draw = ImageDraw.Draw(image, "RGBA")
        draw.rounded_rectangle((86, 82, 634, 652), radius=72, outline=(*SAND, 105), width=8)
        line_color = LIME if index % 2 == 0 else GOLD
        draw.line([(118, 600 - index * 18), (602, 124 + index * 22)], fill=(*line_color, 104), width=10)
        save(name, vignette(image))

    frames_source = source("store/player_frames.webp")
    for index, (name, color) in enumerate(
        (("frame_tactical", LIME), ("frame_gold_step", GOLD), ("frame_sand_cut", SAND))
    ):
        save(name, accent_frame(crop_panel("store/player_frames.webp", index), color, index))

    player = source("store/player11_cosmetics.webp")
    for index, name in enumerate(
        ("style_pitch_diagonal", "style_nocturne_split", "style_desert_blocks", "style_stadium_wave")
    ):
        base = square(player.crop((0 if index % 2 == 0 else player.width // 3, 0, player.width if index % 2 == 0 else player.width, player.height)))
        save(name, overlay_pattern(base, index))

    for index, name in enumerate(("team_tactics", "team_sadu_step", "team_stadium_wave")):
        panel = crop_panel("store/team_patterns.webp", index)
        save(name, vignette(ImageEnhance.Contrast(panel).enhance(1.08)))

    effect = source("store/victory_effects.webp")
    half = effect.width // 2
    save("victory_lime_spiral", vignette(square(effect, (0, 0, half, effect.height))))
    save("victory_gold_prism", vignette(square(effect, (half, 0, effect.width, effect.height))))

    plates = source("store/nameplates.webp")
    half_h = plates.height // 2
    save("nameplate_tactical", vignette(square(plates, (0, 0, plates.width, half_h))))
    save("nameplate_majlis_gold", vignette(square(plates, (0, half_h, plates.width, plates.height))))

    answer = shade(square(source("modes/classic_mode_art.webp")), 62)
    draw = ImageDraw.Draw(answer)
    for radius, alpha, width in ((220, 170, 16), (164, 135, 11), (108, 105, 7)):
        draw.ellipse(
            (SIZE // 2 - radius, SIZE // 2 - radius, SIZE // 2 + radius, SIZE // 2 + radius),
            outline=(*LIME, alpha),
            width=width,
        )
    save("answer_effect_pitch_pulse", vignette(answer))

    lobby = shade(square(source("backgrounds/play_hub_background.webp")), 42)
    draw = ImageDraw.Draw(lobby)
    draw.rounded_rectangle((92, 94, 628, 626), radius=64, outline=(*GOLD, 165), width=12)
    draw.line([(126, 548), (594, 176)], fill=(*LIME, 180), width=13)
    draw.ellipse((274, 274, 446, 446), outline=(*SAND, 150), width=7)
    save("lobby_tactical_room", vignette(lobby))


if __name__ == "__main__":
    main()
