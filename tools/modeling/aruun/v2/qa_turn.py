#!/usr/bin/env python3
"""Model-only turntable board of the final blend: python3 qa_turn.py out.png yaw,yaw,... [blend]"""
import os, sys
import bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); ARUUN = os.path.abspath(os.path.join(HERE, "..")); sys.path.insert(0, os.path.join(ARUUN, ".."))
from common import render as R
out = sys.argv[1]; yaws = [float(x) for x in sys.argv[2].split(",")]
blend = sys.argv[3] if len(sys.argv) > 3 else os.path.join(ARUUN, "work", "v2", "aruun_v2_final.blend")
tz = float(os.environ.get("TZ_", "1.2")); sc_ = float(os.environ.get("SC_", "2.75"))
bpy.ops.wm.open_mainfile(filepath=blend)
for o in bpy.data.objects:
    if o.type == "ARMATURE": o.hide_render = True; o.hide_viewport = True
R.setup_cycles(res=(520, 760), samples=32); R.add_lights()
cam = R.camera(ortho_scale=sc_, target=(0, 0, tz))
tiles = []
for y in yaws:
    R.place_camera(cam, (0, 0, tz), y, 5, 10); R.render("/tmp/claude-0/s/_qt.png")
    m = Image.open("/tmp/claude-0/s/_qt.png").convert("RGBA"); bg = Image.new("RGBA", m.size, (200, 190, 175, 255)); bg.alpha_composite(m); tiles.append(bg.convert("RGB"))
im = Image.new("RGB", (520 * len(tiles), 760))
for i, t in enumerate(tiles): im.paste(t, (i * 520, 0))
im.save(out); print("wrote", out)
