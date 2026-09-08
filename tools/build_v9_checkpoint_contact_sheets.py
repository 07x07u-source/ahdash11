from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"C:\dev\ahdash11\docs\visual-validation\v9-checkpoint")
GROUPS = ("844x390_light", "844x390_dark", "1280x720_light", "1280x720_dark")
THUMBNAIL = (320, 180)
COLS = 3
GAP = 12
MARGIN = 16
LABEL_HEIGHT = 24


def screen_name(path: Path, group: str) -> str:
    return path.stem.removesuffix(f"_{group}")


def build(group: str) -> Path:
    images = sorted(ROOT.glob(f"*_{group}.png"))
    if not images:
        raise FileNotFoundError(f"No V9 images found for {group}")
    rows = (len(images) + COLS - 1) // COLS
    width = MARGIN * 2 + COLS * THUMBNAIL[0] + (COLS - 1) * GAP
    height = (
        MARGIN * 2
        + rows * (THUMBNAIL[1] + LABEL_HEIGHT)
        + (rows - 1) * GAP
    )
    sheet = Image.new("RGB", (width, height), "#171613")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, path in enumerate(images):
        row, column = divmod(index, COLS)
        x = MARGIN + column * (THUMBNAIL[0] + GAP)
        y = MARGIN + row * (THUMBNAIL[1] + LABEL_HEIGHT + GAP)
        with Image.open(path) as source:
            image = source.convert("RGB")
            image.thumbnail(THUMBNAIL, Image.Resampling.LANCZOS)
            offset_x = x + (THUMBNAIL[0] - image.width) // 2
            offset_y = y + (THUMBNAIL[1] - image.height) // 2
            sheet.paste(image, (offset_x, offset_y))
        draw.text(
            (x + 4, y + THUMBNAIL[1] + 5),
            screen_name(path, group),
            fill="#F4EBDD",
            font=font,
        )
    output = ROOT / f"contact-sheet_{group}.png"
    sheet.save(output, optimize=True)
    return output


if __name__ == "__main__":
    for group_name in GROUPS:
        print(build(group_name))
