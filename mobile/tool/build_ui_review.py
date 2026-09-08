"""Make labelled review sheets from actual Flutter exports, without changing sources."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[2] / "docs" / "v10_ui_refinement"
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)

def sheet(name, files, columns=4):
    tile_w, tile_h = 300, 700
    out = Image.new("RGB", (columns * tile_w, ((len(files) + columns - 1) // columns) * tile_h), "#DDD3C1")
    draw = ImageDraw.Draw(out)
    for i, (label, path) in enumerate(files):
        with Image.open(path) as source:
            image = source.convert("RGB")
            image.thumbnail((tile_w - 16, tile_h - 42))
        x, y = (i % columns) * tile_w, (i // columns) * tile_h
        draw.text((x+8, y+8), label, font=font, fill="#191714")
        out.paste(image, (x+(tile_w-image.width)//2, y+36))
    out.save(root / "before_after" / name)

(root/"guest").mkdir(exist_ok=True)
for p in (root/"home").glob("*guest*.png"):
    shutil.copy2(p, root/"guest"/p.name)
sheet("home_before_after.png", [
    ("BEFORE - 390x844", root/"before_after/before/home_account_390x844_scale1.0.png"),
    ("AFTER - 390x844", root/"home/home_account_390x844_scale1.0.png"),
    ("GUEST - 390x844", root/"guest/home_guest_390x844_scale1.0.png"),
    ("AUTH GATE - 390x844", root/"guest/guest_auth_gate_390x844_scale1.0.png"),
])
for group in ["party", "tournament", "account"]:
    files = sorted((root/group).glob("*_390x844_scale1.0.png"))
    if files:
        sheet(group+"_review.png", [(p.stem.split("_390x")[0], p) for p in files])

index = []
for group in ["home", "guest", "party", "tournament", "account"]:
    for p in sorted((root/group).glob("*scale*.png")):
        with Image.open(p) as im:
            size = im.size
        index.append(dict(path=str(p), width=size[0], height=size[1], sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
(root/"SCREENSHOTS.json").write_text(json.dumps(index, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"{len(index)} actual Flutter PNG exports indexed.")
