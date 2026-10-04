#!/usr/bin/env python3
"""Sheet vs model board: python3 tools/modeling/cigarra/qa_compare.py [pose_action] -> design/model_sheets/cigarra/qa/compare_cycles.png"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import bpy  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from common import render as R  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SHEET = os.path.join(ROOT, "design", "model_sheets", "cigarra")
H = 650


def main(out, action=None, frame=0, views=("front", "side", "back"), compare=True):
    bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "work", "cigarra_final.blend"))
    rig = bpy.data.objects["Cigarra_Rig"]
    if action:
        rig.animation_data.action = bpy.data.actions[action]
        bpy.context.scene.frame_set(frame)
    R.setup_cycles((420, H), samples=24)
    R.add_lights()
    cam = R.camera(ortho_scale=1.9 * H / H, target=(0, 0, 0.84))
    cols = []
    for v in views:
        yaw = {"front": 0, "side": -90, "back": 180, "q34": 35}[v]
        R.place_camera(cam, (0, 0, 0.84), yaw, 0, 8)
        p = "/tmp/_cig_%s.png" % v
        R.render(p)
        r = Image.open(p).convert("RGBA")
        s = None
        if compare:
            s = Image.open(os.path.join(SHEET, "hires", {"front": "front_x4.png", "side": "side_x4.png", "back": "back_x4.png", "q34": "front_x4.png"}[v])).convert("RGBA")
            a = s.getchannel("A")
            bb = a.point(lambda x: 255 if x > 128 else 0).getbbox()
            s = s.crop(bb)
            s = s.resize((int(s.width * H / s.height), H), Image.LANCZOS)
        cols.append((v, s, r))
    W = sum((s.width if s else 0) + r.width + 20 for _, s, r in cols)
    img = Image.new("RGBA", (W, H + 30), (238, 230, 218, 255))
    d = ImageDraw.Draw(img)
    x = 0
    for v, s, r in cols:
        if s:
            img.alpha_composite(s, (x, 28))
            x += s.width
        img.alpha_composite(r, (x, 28))
        d.text((x - (s.width if s else 0) + 4, 6), v + (": sheet | model" if s else ""), fill=(30, 20, 20, 255))
        x += r.width + 20
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(SHEET, "qa", "compare_cycles.png"))
