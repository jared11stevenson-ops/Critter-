#!/usr/bin/env python3
"""python3 preview2.py albedo.png out.png [yaws csv] [mesh npz]  -- Cycles board of the game_mesh with an albedo"""
import os, sys
import numpy as np, bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."), ); sys.path.insert(0, HERE)
from common import render as R
import meshio
alb, out = sys.argv[1], sys.argv[2]
yaws = [float(x) for x in (sys.argv[3] if len(sys.argv) > 3 else "0,45,90,180").split(",")]
mesh = sys.argv[4] if len(sys.argv) > 4 else os.path.join(HERE, "..", "work", "v2", "game_mesh.npz")
bpy.ops.wm.read_factory_settings(use_empty=True)
ob = meshio.make_object(mesh)
img = bpy.data.images.load(os.path.abspath(alb)); img.colorspace_settings.name = "sRGB"
mat = bpy.data.materials.new("p"); mat.use_nodes = True
nt = mat.node_tree; bs = nt.nodes["Principled BSDF"]
tx = nt.nodes.new("ShaderNodeTexImage"); tx.image = img
nt.links.new(tx.outputs[0], bs.inputs["Base Color"]); bs.inputs["Roughness"].default_value = 0.6
mat.use_backface_culling = False
ob.data.materials.append(mat)
sc = R.setup_cycles(res=(500, 800), samples=24); R.add_lights()
cam = R.camera(ortho_scale=2.7, target=(0, 0, 1.2))
tiles = []
for i, y in enumerate(yaws):
    R.place_camera(cam, (0, 0, 1.2), y, 5, 10)
    p = "/tmp/claude-0/s/_pv_%d.png" % i
    R.render(p); tiles.append(Image.open(p).convert("RGBA"))
W = sum(t.width for t in tiles); im = Image.new("RGBA", (W, tiles[0].height), (200, 190, 175, 255)); x = 0
for t in tiles: im.alpha_composite(t, (x, 0)); x += t.width
im.convert("RGB").save(out); print("wrote", out)
