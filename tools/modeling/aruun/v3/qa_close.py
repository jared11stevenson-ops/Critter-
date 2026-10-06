#!/usr/bin/env python3
"""python3 qa_close.py out.png x,y,z scale yaw1,yaw2,... [--open]  generic Cycles close-up board of the v3 blend"""
import os, sys, math
import numpy as np, bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); ARUUN = os.path.abspath(os.path.join(HERE, "..")); sys.path.insert(0, os.path.join(ARUUN, ".."))
from common import render as R
out = sys.argv[1]; tg = tuple(float(v) for v in sys.argv[2].split(",")); sc = float(sys.argv[3]); yaws = [float(v) for v in sys.argv[4].split(",")]
bpy.ops.wm.open_mainfile(filepath=os.path.join(ARUUN, "work", "v3", "aruun_v3.blend"))
rig = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]; rig.hide_render = True; rig.hide_viewport = True
R.setup_cycles(res=(500, 500), samples=32); R.add_lights()
cam = R.camera(ortho_scale=sc, target=tg); tiles = []
for yaw in yaws:
    R.place_camera(cam, tg, yaw, 8, 6); R.render("/tmp/claude-0/s/_qc.png")
    mr = Image.open("/tmp/claude-0/s/_qc.png").convert("RGBA"); bg = Image.new("RGBA", mr.size, (170, 160, 146, 255)); bg.alpha_composite(mr); tiles.append(bg.convert("RGB"))
im = Image.new("RGB", (500 * len(tiles), 500))
for i, t in enumerate(tiles): im.paste(t, (i * 500, 0))
im.save(out); print("wrote", out)
