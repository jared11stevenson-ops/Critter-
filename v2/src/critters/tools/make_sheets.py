#!/usr/bin/env python3
"""Compose shoot.gd tiles into labelled sheets (PIL).
Usage: make_sheets.py <tiles_dir> <out_dir> [--ids=a,b,c] [--tile=N]
Sheets per critter: turnaround (4 views), actions (8 poses), expressions (6), fx, film; plus the_seven.png and silhouettes.png."""
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont

IDS = ["haldor", "sessa", "weft", "cinder", "marro", "zell", "kragg"]
NAMES = {"haldor": "HALDOR - Quarry-Hammer", "sessa": "SESSA - Gentle Edge", "weft": "WEFT - Thread Between",
         "cinder": "CINDER - Pressure Cooker", "marro": "MARRO - We Are One", "zell": "ZELL - Short Summer", "kragg": "KRAGG - Main Event"}
BG = (34, 30, 36)
KINDS = (("act", "actions", 4, "action poses", 1.0), ("expr", "expressions", 3, "expressions", 1.1),
         ("fx", "fx", 3, "fx: smear, spark, impact frame", 1.0), ("film", "film", 4, "heavy strike filmstrip", 1.0))


def font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def save(img, path):
    # 256-colour quantise keeps the cel look and the total under the 6 MB sheet budget
    img.convert("RGB").quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.FLOYDSTEINBERG).save(path, optimize=True)


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


def label_of(path, cid, kind):
    # <cid>_<kind>_<index>_<label>.png -> label
    name = os.path.basename(path)[:-4]
    rest = name[len(cid) + 1 + len(kind) + 1:]
    return rest.split("_", 1)[1] if "_" in rest else rest


def numkey(path):
    for p in os.path.basename(path).split("_"):
        if p.isdigit():
            return int(p)
    return 0


def main():
    tiles, out = sys.argv[1], sys.argv[2]
    ids, tile = IDS, 300
    for a in sys.argv[3:]:
        if a.startswith("--ids="):
            ids = a[6:].split(",")
        if a.startswith("--tile="):
            tile = int(a[7:])
    os.makedirs(out, exist_ok=True)
    for cid in ids:
        views = ["front", "three_quarter", "side", "back"]
        fs = [f"{tiles}/{cid}_turn_{v}.png" for v in views]
        if all(os.path.exists(f) for f in fs):
            save(grid(fs, 4, int(tile * 1.15), [v.replace("_", " ") for v in views], NAMES[cid] + "  -  turnaround"), f"{out}/{cid}_turnaround.png")
        for kind, fname, cols, title, mul in KINDS:
            files = sorted(glob.glob(f"{tiles}/{cid}_{kind}_*.png"), key=numkey)
            if files:
                save(grid(files, cols, int(tile * mul), [label_of(f, cid, kind) for f in files], NAMES[cid] + "  -  " + title),
                     f"{out}/{cid}_{fname}.png")
    if os.path.exists(f"{tiles}/lineup.png"):
        im = Image.open(f"{tiles}/lineup.png").convert("RGB")
        w = 1600
        save(im.resize((w, int(im.height * w / im.width)), Image.LANCZOS), f"{out}/the_seven.png")
    sil = [f"{tiles}/{c}_sil.png" for c in ids if os.path.exists(f"{tiles}/{c}_sil.png")]
    if sil:
        save(grid(sil, len(sil), 200, ids, "silhouettes (flat black)"), f"{out}/silhouettes.png")


main()
