#!/usr/bin/env python3
"""Head close-up board: sheet head crops | model head at side (-90), back (180), 3/4 (-35).  python3 qa_head.py out.png [blend]"""
import os, sys
import numpy as np, bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); ARUUN = os.path.abspath(os.path.join(HERE, "..")); sys.path.insert(0, os.path.join(ARUUN, ".."))
from common import render as R
out = sys.argv[1]; blend = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ARUUN, "work", "v2", "aruun_v2_final.blend")
ROOT = os.path.abspath(os.path.join(ARUUN, "..", "..", ".."))
bpy.ops.wm.open_mainfile(filepath=blend)
for o in bpy.data.objects:
    if o.type == "ARMATURE": o.hide_render = True; o.hide_viewport = True
R.setup_cycles(res=(600, 700), samples=32); R.add_lights()
cam = R.camera(ortho_scale=0.75, target=(0.09, -0.1, 2.12))
tiles = []
for yaw in (-90, 180, -35):
    R.place_camera(cam, (0.09, -0.1, 2.12), yaw, 4, 6); R.render("/tmp/claude-0/s/_qh.png")
    mr = Image.open("/tmp/claude-0/s/_qh.png").convert("RGBA"); bg = Image.new("RGBA", mr.size, (200, 190, 175, 255)); bg.alpha_composite(mr); tiles.append(bg.convert("RGB"))
det = Image.open(os.path.join(ROOT, "design/model_sheets/aruun/detail_head.png")).convert("RGB")
W = 600 * 3
im = Image.new("RGB", (W, 700 * 2), (255, 255, 255))
for i, t in enumerate(tiles): im.paste(t, (i * 600, 700))
# sheet refs: side head, back head, front head from detail panel crops
w, h = det.size
refs = [det.crop((int(w * 0.67), 100, int(w * 0.98), 620)), det.crop((int(w * 0.015), 690, int(w * 0.33), 1200)), det.crop((int(w * 0.34), 100, int(w * 0.66), 620))]
for i, r in enumerate(refs):
    r.thumbnail((600, 700)); im.paste(r, (i * 600, 0))
im.save(out); print("wrote", out)
