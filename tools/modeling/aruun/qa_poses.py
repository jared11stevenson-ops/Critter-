#!/usr/bin/env python3
"""Contact sheet of animation key poses from work/aruun_final.blend.
Usage: python3 tools/modeling/aruun/qa_poses.py out.png [clip:time,...] [yaw]"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import bpy  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from common import render as R  # noqa: E402

DEFAULT = "idle:0,walk:0.27,run:0.16,dash:0.2,attack_1:0.15,attack_1:0.28,attack_2:0.2,attack_2:0.36,attack_3:0.46," \
          "reaching_strike:0.42,gravity_pull:0.3,gravity_pull:0.55,beetle_rage:0.35,beetle_rage:0.8,hit:0.07," \
          "downed:1.0,revive:0.55,burden_hold:0,talk_idle:0.8"


def main(out, spec, yaw):
    bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "work", "aruun_final.blend"))
    rig = bpy.data.objects["Aruun_Rig"]
    R.setup_cycles((300, 420), samples=12)
    R.add_lights()
    cam = R.camera(ortho_scale=3.0, target=(0, 0, 1.2))
    R.place_camera(cam, (0, -0.3, 1.2), yaw, 8, 8)
    tiles = []
    for item in spec.split(","):
        clip, t = item.split(":")
        rig.animation_data.action = bpy.data.actions[clip]
        if hasattr(rig.animation_data, "action_slot") and rig.animation_data.action_slot is None:
            rig.animation_data.action_slot = bpy.data.actions[clip].slots[0]
        bpy.context.scene.frame_set(1 + round(float(t) * 30))
        p = "/tmp/_aruun_pose.png"
        R.render(p)
        im = Image.open(p).convert("RGBA")
        ImageDraw.Draw(im).text((6, 6), item, fill=(0, 0, 0, 255))
        tiles.append(im)
    cols = 7
    rows = (len(tiles) + cols - 1) // cols
    W, H = tiles[0].size
    img = Image.new("RGBA", (W * cols, H * rows), (226, 220, 210, 255))
    for i, t in enumerate(tiles):
        img.alpha_composite(t, ((i % cols) * W, (i // cols) * H))
    img.convert("RGB").save(out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else DEFAULT, float(sys.argv[3]) if len(sys.argv) > 3 else 35)
