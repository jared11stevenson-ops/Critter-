#!/usr/bin/env python3
"""Head close-up board (Cycles).  python3 qa_head3.py out.png [--open] [--blend path] [--persp]"""
import os, sys, math
import numpy as np, bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); ARUUN = os.path.abspath(os.path.join(HERE, "..")); sys.path.insert(0, os.path.join(ARUUN, ".."))
from common import render as R
out = sys.argv[1]
blend = os.path.join(ARUUN, "work", "v3", "aruun_v3.blend")
if "--blend" in sys.argv: blend = sys.argv[sys.argv.index("--blend") + 1]
bpy.ops.wm.open_mainfile(filepath=blend)
rig = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
rig.hide_render = True; rig.hide_viewport = True
if "--open" in sys.argv:
    pb = rig.pose.bones["jaw"]; pb.rotation_mode = "XYZ"; pb.rotation_euler = (math.radians(-34), 0, 0)
R.setup_cycles(res=(520, 560), samples=40); R.add_lights()
tg = (0.085, -0.15, 2.07)
cam = R.camera(ortho_scale=0.62, target=tg)
tiles = []
for yaw in (0, -30, -90, 40):
    R.place_camera(cam, tg, yaw, 8, 6); R.render("/tmp/claude-0/s/_qh.png")
    mr = Image.open("/tmp/claude-0/s/_qh.png").convert("RGBA"); bg = Image.new("RGBA", mr.size, (150, 140, 128, 255)); bg.alpha_composite(mr); tiles.append(bg.convert("RGB"))
im = Image.new("RGB", (520 * len(tiles), 560), (255, 255, 255))
for i, t in enumerate(tiles): im.paste(t, (i * 520, 0))
im.save(out); print("wrote", out)
