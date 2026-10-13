#!/usr/bin/env python3
"""Round character icons: crops the head-and-shoulders renders (src/critters/tools/shoot.gd --mode=portrait) into
v2/art/portraits/<id>.png (192 px, circular, ringed in the critter's signature colour).
Usage: python3 v2/tools/gen/make_portraits.py <dir with <id>_portrait.png>"""
import os, sys
from PIL import Image, ImageDraw
SIG = {"aruun": "e8582a", "cigarra": "7a4fc0", "bramvex": "7b8a2a", "scarlith": "b01c2c", "mollusk": "3aa86a", "zephyr": "d63a9c", "nyxaris": "6cc4e6", "pharilux": "ffb83a"}
SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "art", "portraits")
os.makedirs(OUT, exist_ok=True)
S = 192; K = 4
for cid, hexcol in SIG.items():
    if not os.path.exists(os.path.join(SRC, f"{cid}_portrait.png")):
        continue
    im = Image.open(os.path.join(SRC, f"{cid}_portrait.png")).convert("RGBA").resize((S * K, S * K), Image.LANCZOS)
    mask = Image.new("L", (S * K, S * K), 0)
    ImageDraw.Draw(mask).ellipse([10 * K, 10 * K, (S - 10) * K, (S - 10) * K], fill=255)
    out = Image.new("RGBA", (S * K, S * K), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    d = ImageDraw.Draw(out)
    col = tuple(int(hexcol[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    d.ellipse([10 * K, 10 * K, (S - 10) * K, (S - 10) * K], outline=(22, 18, 26, 255), width=9 * K)
    d.ellipse([15 * K, 15 * K, (S - 15) * K, (S - 15) * K], outline=col, width=5 * K)
    out.resize((S, S), Image.LANCZOS).save(os.path.join(OUT, f"{cid}.png"), optimize=True)
print("portraits ->", os.path.abspath(OUT))
