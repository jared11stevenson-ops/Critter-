#!/usr/bin/env python3
"""Quick flat-colour Cycles preview of work/aruun_geo.blend (part colours from the sampled palette).
Usage: python3 tools/modeling/aruun/preview.py out.png [views=front,q34,side,back]"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402
from common import render as R  # noqa: E402
from PIL import Image  # noqa: E402

PART_COL = {
    "head": "#8a3a2e", "jaw": "#352f32", "fang": "#e8e0d0", "eye": "#d7ca79", "brow": "#933c31", "crest": "#933c31",
    "horn": "#903d2d", "tine": "#c69e7c", "fringe_cream": "#c29f5d", "fringe_olive": "#6f6a4c", "neck": "#b35c42",
    "torso": "#34282a", "upperarm": "#34282a", "forearm": "#34282a", "hand": "#2e2628", "claw": "#c69e7c",
    "pauldron": "#933c31", "armplate": "#933c31", "bracer": "#933c31", "thigh": "#34282a", "shin": "#34282a",
    "kneeplate": "#c69e7c", "foot": "#a77d5c", "toeclaw": "#c69e7c", "belt": "#8f4336", "cloth_sash": "#8f4336",
    "buckle": "#d9c3a9", "buckle_disc": "#2c2218", "medallion": "#d9c3a9", "gold": "#c79a3a", "strip_cord": "#5a4432",
    "strip_cream": "#bd996f", "beads": "#8f2a22", "leaf_olive": "#7a6341", "leaf_dark": "#4e4235", "band_cream": "#c8ad88",
    "talisman": "#6f6a4c", "strip_olive": "#6f6a4c", "cloak_hood": "#4e4235", "cloak_back": "#4e4235",
    "cloak_tail": "#2c2420", "morrow_head": "#2f2526", "morrow_stud": "#bd9073", "morrow_spike": "#a0755b",
    "morrow_rim": "#3a2a26", "morrow_core": "#d34f49", "morrow_seg0": "#3a2c24", "morrow_seg1": "#3a2c24",
    "morrow_seg2": "#3a2c24", "morrow_pommel": "#bd9073",
}


def hex2(h):
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))


def colorize(ob):
    me = ob.data
    names = ob["parts"]
    pa = np.zeros(len(me.polygons), dtype=np.int32)
    me.attributes["part"].data.foreach_get("value", pa)
    ca = me.color_attributes.new("pcol", "FLOAT_COLOR", "CORNER")
    cols = np.zeros((len(me.loops), 4), dtype=np.float32)
    ls = np.zeros(len(me.polygons), dtype=np.int32)
    lt = np.zeros(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("loop_start", ls)
    me.polygons.foreach_get("loop_total", lt)
    for i in range(len(me.polygons)):
        nm = names[pa[i]].split(".")[0]
        c = hex2(PART_COL.get(nm, "#ff00ff"))
        c = [v ** 2.2 for v in c]
        cols[ls[i]:ls[i] + lt[i]] = (*c, 1)
    ca.data.foreach_set("color", cols.ravel())
    m = bpy.data.materials.new("pcol")
    m.use_nodes = True
    nt = m.node_tree
    a = nt.nodes.new("ShaderNodeAttribute")
    a.attribute_name = "pcol"
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.55
    nt.links.new(a.outputs["Color"], b.inputs["Base Color"])
    me.materials.clear()
    me.materials.append(m)
    for p in me.polygons:
        p.material_index = 0


def main(out, views):
    bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "work", "aruun_geo.blend"))
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            colorize(ob)
    mor = bpy.data.objects.get("Morrow")
    if mor:
        # hold Morrow in the right hand, head resting forward-right on the ground (front view pose)
        import body
        wr = body.jm("wrist.R")
        mor.matrix_world = Matrix.Translation(wr + Vector((-0.02, -0.02, -0.06))) @ Matrix.Rotation(0.5, 4, "Y") @ \
            Matrix.Rotation(-0.25, 4, "X")
    R.setup_cycles((520, 760), samples=24)
    R.add_lights()
    cam = R.camera(ortho_scale=2.75, target=(0, 0, 1.2))
    tiles = []
    for v in views:
        yaw = {"front": 0, "q34": 35, "side": -90, "back": 180, "q34b": 145, "sideL": 90}[v]
        R.place_camera(cam, (0, 0, 1.22), yaw, 4, 8)
        p = "/tmp/_aruun_prev_%s.png" % v
        R.render(p)
        tiles.append(Image.open(p).convert("RGBA"))
    W = sum(t.width for t in tiles)
    img = Image.new("RGBA", (W, tiles[0].height), (226, 220, 210, 255))
    x = 0
    for t in tiles:
        img.alpha_composite(t, (x, 0))
        x += t.width
    img.convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/aruun_prev.png"
    views = sys.argv[2].split(",") if len(sys.argv) > 2 else ["front", "q34", "side", "back"]
    main(out, views)
