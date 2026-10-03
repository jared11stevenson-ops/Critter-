#!/usr/bin/env python3
"""Render clip frame strips of the retargeted animation on the real Aruun mesh (Cycles, low samples).

python3 tools/animation/preview.py out.png clip[:t0:t1:step] ... [--yaw 90] [--world] [--size 220x300] [--char aruun]
--world: re-adds the clip's root motion (speed) so planted feet must stay still on the ground grid.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "modeling"))

import bpy  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from common import render as R  # noqa: E402
from apply import apply_animations  # noqa: E402


def main(argv):
    out = argv[0]
    yaw, world, size, char, pitch, scale = 90.0, False, (220, 300), "aruun", 6.0, 3.2
    items = []
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--yaw":
            yaw = float(argv[i + 1]); i += 2; continue
        if a == "--pitch":
            pitch = float(argv[i + 1]); i += 2; continue
        if a == "--scale":
            scale = float(argv[i + 1]); i += 2; continue
        if a == "--world":
            world = True; i += 1; continue
        if a == "--size":
            size = tuple(int(x) for x in argv[i + 1].split("x")); i += 2; continue
        if a == "--char":
            char = argv[i + 1]; i += 2; continue
        items.append(a); i += 1
    blend = os.path.join(ROOT, "tools", "modeling", char, "work", "%s_final.blend" % char)
    bpy.ops.wm.open_mainfile(filepath=blend)
    rig = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    clips = sorted(set(it.split(":")[0] for it in items))
    meta = apply_animations(rig, char, clips)
    R.setup_cycles(size, samples=8)
    R.add_lights()
    # ground grid
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    g = bpy.context.object
    m = bpy.data.materials.new("grid")
    m.use_nodes = True
    nt = m.node_tree
    ch = nt.nodes.new("ShaderNodeTexChecker")
    ch.inputs["Scale"].default_value = 12.0
    ch.inputs["Color1"].default_value = (0.75, 0.72, 0.66, 1)
    ch.inputs["Color2"].default_value = (0.55, 0.52, 0.48, 1)
    nt.links.new(ch.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
    g.data.materials.append(m)
    cam = R.camera(ortho_scale=scale, target=(0, 0, 1.2))
    rows = []
    for it in items:
        p = it.split(":")
        clip = p[0]
        md = meta[clip]
        t0 = float(p[1]) if len(p) > 1 else 0.0
        t1 = float(p[2]) if len(p) > 2 else md["duration"]
        step = float(p[3]) if len(p) > 3 else 0.1
        act = bpy.data.actions[clip]
        rig.animation_data.action = act
        rig.animation_data.action_slot = act.slots[0]
        tiles = []
        t = t0
        while t <= t1 + 1e-6:
            f = 1 + round(t * 30)
            bpy.context.scene.frame_set(f)
            # treadmill: the ground moves back at the clip speed, so planted feet must move with the checkers
            g.location = (0, (md.get("speed", 0) * t) % 1.0 if world else 0, 0)
            R.place_camera(cam, (0, 0, 1.1), yaw, pitch, 8)
            pth = "/tmp/claude-0/_pv.png"
            R.render(pth)
            im = Image.open(pth).convert("RGBA")
            ImageDraw.Draw(im).text((4, 4), "%s %.2f" % (clip, t), fill=(0, 0, 0, 255))
            tiles.append(im)
            t += step
        W, H = tiles[0].size
        row = Image.new("RGBA", (W * len(tiles), H), (226, 220, 210, 255))
        for k, tl in enumerate(tiles):
            row.alpha_composite(tl, (k * W, 0))
        rows.append(row)
    W = max(r.width for r in rows)
    img = Image.new("RGB", (W, sum(r.height for r in rows)), (226, 220, 210))
    y = 0
    for r in rows:
        img.paste(r.convert("RGB"), (0, y)); y += r.height
    img.save(out)
    print("saved", out, meta)


if __name__ == "__main__":
    main(sys.argv[1:])
