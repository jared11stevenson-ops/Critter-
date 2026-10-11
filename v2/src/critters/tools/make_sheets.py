#!/usr/bin/env python3
"""Compose shoot.gd tiles into labelled sheets (PIL). Usage: make_sheets.py <tiles_dir> <out_dir> [--ids a,b,c] [--max-kb N]"""
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont

IDS = ["haldor", "sessa", "weft", "cinder", "marro", "zell", "kragg"]
NAMES = {"haldor": "HALDOR - Quarry-Hammer", "sessa": "SESSA - Gentle Edge", "weft": "WEFT - Thread Between",
         "cinder": "CINDER - Pressure Cooker", "marro": "MARRO - We Are One", "zell": "ZELL - Short Summer", "kragg": "KRAGG - Main Event"}
BG = (34, 30, 36)

def font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def grid(files, cols, tile, labels=None, title=None):
    rows = (len(files) + cols - 1) // cols
    top = 34 if title else 0
    img = Image.new("RGB", (cols * tile, rows * tile + top), BG)
    d = ImageDraw.Draw(img)
    if title:
        d.text((10, 6), title, font=font(20), fill=(245, 215, 140))
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB").resize((tile, tile), Image.LANCZOS)
        x, y = (i % cols) * tile, top + (i // cols) * tile
        img.paste(im, (x, y))
        if labels:
            d.text((x + 8, y + tile - 22), labels[i], font=font(14), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    return img

def main():
    tiles, out = sys.argv[1], sys.argv[2]
    ids = IDS
    tile = 300
    for a in sys.argv[3:]:
        if a.startswith("--ids="): ids = a[6:].split(",")
        if a.startswith("--tile="): tile = int(a[7:])
    os.makedirs(out, exist_ok=True)
    for cid in ids:
        views = ["front", "three_quarter", "side", "back"]
        fs = [f"{tiles}/{cid}_turn_{v}.png" for v in views]
        if all(os.path.exists(f) for f in fs):
            grid(fs, 4, tile, [v.replace("_", " ") for v in views], NAMES[cid] + "  - turnaround").save(f"{out}/{cid}_turnaround.png", optimize=True)
        acts = sorted(glob.glob(f"{tiles}/{cid}_act_*.png"))
        if acts:
            labels = [os.path.basename(a)[len(cid) + 5:-4].split("_", 1)[1] for a in acts]
            grid(acts, 4, tile, labels, NAMES[cid] + "  - action poses").save(f"{out}/{cid}_actions.png", optimize=True)
        film = sorted(glob.glob(f"{tiles}/{cid}_film_*.png"), key=lambda x: int(os.path.basename(x).split("_film_")[1].split("_")[0]))
        if film:
            labels = [os.path.basename(a).split("_", 3)[3][:-4] for a in film]
            grid(film, 4, tile, labels, NAMES[cid] + "  - film").save(f"{out}/{cid}_film.png", optimize=True)
        ex = sorted(glob.glob(f"{tiles}/{cid}_expr_*.png"))
        if ex:
            labels = [os.path.basename(a)[len(cid) + 6:-4].split("_", 1)[1] for a in ex]
            grid(ex, 3, tile, labels, NAMES[cid] + "  - expressions").save(f"{out}/{cid}_expressions.png", optimize=True)
    if os.path.exists(f"{tiles}/lineup.png"):
        im = Image.open(f"{tiles}/lineup.png").convert("RGB")
        w = 1500
        im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
        im.save(f"{out}/the_seven.png", optimize=True)
    sil = [f"{tiles}/{c}_sil.png" for c in ids if os.path.exists(f"{tiles}/{c}_sil.png")]
    if sil:
        grid(sil, len(sil), 160, ids, "silhouettes").save(f"{out}/silhouettes.png", optimize=True)

main()
