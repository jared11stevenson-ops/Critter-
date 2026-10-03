#!/usr/bin/env python3
"""Cycles comparison board: textured, rigged model (rest pose) vs the sheet views at identical scale.
Usage: python3 tools/modeling/aruun/qa_compare.py  -> design/model_sheets/aruun/qa/compare_cycles.png"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import bpy  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from common import render as R  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SHEETDIR = os.path.join(ROOT, "design", "model_sheets", "aruun")
H = 650
# turnaround.png (3308 px wide) columns of each view, rows horn tip..sole
VIEWS = [("front", (240, 1300), 0), ("side", (1930, 2330), -90), ("back", (2430, 2990), 180)]
Y0, Y1 = 140, 1439
HIRES = {"front": "front_clean_x4.png", "side": "side_x4.png", "back": "back_x4.png"}


def main():
    bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "work", "aruun_final.blend"))
    sheet = Image.open(os.path.join(SHEETDIR, "turnaround.png")).convert("RGBA")
    R.setup_cycles((560, H), samples=32)
    R.add_lights()
    cam = R.camera(ortho_scale=2.4 * 560 / H if 560 > H else 2.4, target=(0, 0, 1.2))
    cols = []
    for name, (x0, x1), yaw in VIEWS:
        R.place_camera(cam, (0, 0, 1.2), yaw, 0, 8)
        p = "/tmp/_aruun_cmp_%s.png" % name
        R.render(p)
        r = Image.open(p).convert("RGBA")
        s = Image.open(os.path.join(SHEETDIR, "hires", HIRES[name])).convert("RGBA")
        s = s.crop(s.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox())
        s = s.resize((int(s.width * H / s.height), H), Image.LANCZOS)
        cols.append((name, s, r))
    W = sum(s.width + r.width + 30 for _, s, r in cols)
    img = Image.new("RGBA", (W, H + 50), (238, 230, 218, 255))
    d = ImageDraw.Draw(img)
    x = 0
    for name, s, r in cols:
        img.alpha_composite(s, (x, 40))
        img.alpha_composite(r, (x + s.width, 40))
        d.text((x + 6, 8), "%s: sheet | model (Cycles, rest pose)" % name, fill=(40, 30, 30, 255))
        for k in range(0, 25, 2):   # 0.2 m guide lines
            y = 40 + H - k / 24 * H
            d.line([(x, y), (x + s.width + r.width, y)], fill=(150, 120, 110, 90))
        x += s.width + r.width + 30
    out = os.path.join(SHEETDIR, "qa", "compare_cycles.png")
    img.convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
