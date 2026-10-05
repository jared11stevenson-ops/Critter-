#!/usr/bin/env python3
"""Sheet-vs-model board (Cycles, rest pose): python3 qa_board.py out.png [blend]   columns: sheet | model for side, back, front(3/4)"""
import os, sys
import numpy as np, bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); ARUUN = os.path.abspath(os.path.join(HERE, "..")); sys.path.insert(0, os.path.join(ARUUN, ".."))
from common import render as R
out = sys.argv[1]
blend = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ARUUN, "work", "v2", "aruun_v2_final.blend")
ROOT = os.path.abspath(os.path.join(ARUUN, "..", "..", ".."))
bpy.ops.wm.open_mainfile(filepath=blend)
for o in bpy.data.objects:
    if o.type == "ARMATURE": o.hide_render = True; o.hide_viewport = True
sc = R.setup_cycles(res=(560, 900), samples=32); R.add_lights()
cam = R.camera(ortho_scale=2.75, target=(0, 0, 1.2))
PX = 900 / 2.75        # px per metre in the render
views = [("side", -90, "side_x4.png"), ("back", 180, "back_x4.png"), ("front 3/4", -35, "front_clean_x4.png")]
if "--head" in sys.argv:
    pass
rows = []
for name, yaw, sheet in views:
    R.place_camera(cam, (0, 0, 1.2), yaw, 4, 10)
    p = "/tmp/claude-0/s/_qb.png"; R.render(p); mr = Image.open(p).convert("RGBA")
    sh = Image.open(os.path.join(ROOT, "design/model_sheets/aruun/hires", sheet)).convert("RGBA")
    a = np.asarray(sh)[:, :, 3] > 128; ys, xs = np.where(a)
    h = ys.max() - ys.min() + 1; s = 2.4 * PX / h
    sh = sh.crop((0, ys.min(), sh.width, ys.max() + 1)); sh = sh.resize((int(sh.width * s), int(sh.height * s)), Image.LANCZOS)
    tile = Image.new("RGBA", (560 * 2, 900), (236, 228, 214, 255))
    z0 = 900 / 2 + 1.2 * PX     # row of z=0 in the render
    tile.alpha_composite(sh, (int(280 - sh.width / 2 * (0.5 if name == "front 3/4" else 1.0)) - (180 if name == "front 3/4" else 0), int(z0 - sh.height)))
    bg = Image.new("RGBA", mr.size, (200, 190, 175, 255)); bg.alpha_composite(mr)
    tile.alpha_composite(bg, (560, 0))
    rows.append(tile)
W = sum(t.width for t in rows); im = Image.new("RGB", (W, 900), (255, 255, 255)); x = 0
for t in rows: im.paste(t.convert("RGB"), (x, 0)); x += t.width
im.save(out); print("wrote", out, im.size)
