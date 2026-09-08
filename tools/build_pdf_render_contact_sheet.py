from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont


SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    r"C:\dev\ahdash11\tmp\pdfs\v8-2-catalog-render"
)
OUTPUT = SOURCE / "all-pages-contact-sheet.png"
COLS = 5
THUMBNAIL = (288, 162)
LABEL_HEIGHT = 20
GAP = 8
MARGIN = 12


def page_number(path: Path) -> int:
    return int(path.stem.rsplit("-", 1)[-1])


def main() -> None:
    pages = sorted(SOURCE.glob("page-*.png"), key=page_number)
    if not pages:
        raise FileNotFoundError("No rendered PDF pages found")
    rows = (len(pages) + COLS - 1) // COLS
    width = MARGIN * 2 + COLS * THUMBNAIL[0] + (COLS - 1) * GAP
    height = MARGIN * 2 + rows * (THUMBNAIL[1] + LABEL_HEIGHT) + (rows - 1) * GAP
    sheet = Image.new("RGB", (width, height), "#24211c")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for index, path in enumerate(pages):
        column = index % COLS
        row = index // COLS
        x = MARGIN + column * (THUMBNAIL[0] + GAP)
        y = MARGIN + row * (THUMBNAIL[1] + LABEL_HEIGHT + GAP)
        with Image.open(path) as page:
            image = page.convert("RGB")
            image.thumbnail(THUMBNAIL, Image.Resampling.LANCZOS)
            offset_x = x + (THUMBNAIL[0] - image.width) // 2
            offset_y = y + (THUMBNAIL[1] - image.height) // 2
            sheet.paste(image, (offset_x, offset_y))
        draw.text(
            (x + 4, y + THUMBNAIL[1] + 4),
            f"PAGE {index + 1:02d}",
            fill="#f7f3e8",
            font=font,
        )

    sheet.save(OUTPUT, optimize=True)
    print(f"OUTPUT={OUTPUT}")
    print(f"PAGES={len(pages)}")

    batch_size = 10
    for batch_index, start in enumerate(range(0, len(pages), batch_size), start=1):
        batch_pages = pages[start : start + batch_size]
        batch_rows = (len(batch_pages) + COLS - 1) // COLS
        batch_height = (
            MARGIN * 2
            + batch_rows * (THUMBNAIL[1] + LABEL_HEIGHT)
            + (batch_rows - 1) * GAP
        )
        batch_sheet = Image.new("RGB", (width, batch_height), "#24211c")
        batch_draw = ImageDraw.Draw(batch_sheet)

        for local_index, path in enumerate(batch_pages):
            column = local_index % COLS
            row = local_index // COLS
            x = MARGIN + column * (THUMBNAIL[0] + GAP)
            y = MARGIN + row * (THUMBNAIL[1] + LABEL_HEIGHT + GAP)
            with Image.open(path) as page:
                image = page.convert("RGB")
                image.thumbnail(THUMBNAIL, Image.Resampling.LANCZOS)
                offset_x = x + (THUMBNAIL[0] - image.width) // 2
                offset_y = y + (THUMBNAIL[1] - image.height) // 2
                batch_sheet.paste(image, (offset_x, offset_y))
            batch_draw.text(
                (x + 4, y + THUMBNAIL[1] + 4),
                f"PAGE {page_number(path):02d}",
                fill="#f7f3e8",
                font=font,
            )

        batch_output = SOURCE / f"pages-{start + 1:02d}-{start + len(batch_pages):02d}.png"
        batch_sheet.save(batch_output, optimize=True)
        print(f"BATCH_{batch_index}={batch_output}")


if __name__ == "__main__":
    main()
