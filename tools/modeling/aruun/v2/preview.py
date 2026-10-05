#!/usr/bin/env python3
"""Cycles preview of the fitted v2 body with a given albedo: python3 preview.py albedo.png out.png [views csv yaw]"""
import os, sys, math
import numpy as np
import bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import render as R
WORK = os.path.join(HERE, "..", "work", "v2")
alb, out = sys.argv[1], sys.argv[2]
yaws = [float(x) for x in (sys.argv[3] if len(sys.argv) > 3 else "0,45,90,180").split(",")]
src = sys.argv[4] if len(sys.argv) > 4 else None
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "..", "work", "aruun_final.blend"))
ob = bpy.data.objects["Aruun"]; me = ob.data
if os.path.exists(os.path.join(WORK, "fit.npz")) and src != "old":
    V = np.load(os.path.join(WORK, "fit.npz"))["V"]
    me.vertices.foreach_set("co", V.astype(np.float32).ravel()); me.update()
for o in list(bpy.data.objects):
    if o.type == "ARMATURE": o.hide_viewport = True
img = bpy.data.images.load(os.path.abspath(alb)); img.colorspace_settings.name = "sRGB"
mat = bpy.data.materials.new("p"); mat.use_nodes = True
nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
tx = nt.nodes.new("ShaderNodeTexImage"); tx.image = img
nt.links.new(tx.outputs[0], bs.inputs["Base Color"]); bs.inputs["Roughness"].default_value = 0.6
me.materials.clear(); me.materials.append(mat)
for p in me.polygons: p.material_index = 0; p.use_smooth = True
for o in bpy.data.objects:
    if o.type == "MESH" and o != ob: o.hide_render = True
sc = R.setup_cycles(res=(500, 800), samples=24)
R.add_lights()
cam = R.camera(ortho_scale=2.7, target=(0, 0, 1.2), yaw_deg=0)
tiles = []
for i, y in enumerate(yaws):
    R.place_camera(cam, (0, 0, 1.2), y, 5, 10)
    p = "/tmp/claude-0/s/_pv_%d.png" % i
    R.render(p); tiles.append(Image.open(p).convert("RGBA"))
W = sum(t.width for t in tiles); im = Image.new("RGBA", (W, tiles[0].height), (200, 190, 175, 255)); x = 0
for t in tiles: im.alpha_composite(t, (x, 0)); x += t.width
im.convert("RGB").save(out); print("wrote", out)
