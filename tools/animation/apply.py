"""Animation integration hook for the character build scripts (Blender 5.0, bpy module).

    from apply import apply_animations          # sys.path += tools/animation
    meta = apply_animations(rig_obj, "aruun")    # creates one Action per clip on the armature, returns
                                                 # {clip: {duration, loop, impact, ...}} for <id>_anim.json

Clips are built by tools/animation/characters/<id>.py (mocap retarget + style layers + hand polish), see
tools/animation/README section in SOURCES.md.
"""
import importlib
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from retarget import FPS, Skeleton  # noqa: E402


def apply_animations(armature_obj, character_id, clips=None, verbose=True):
    cfg = importlib.import_module("characters." + character_id)
    sk = Skeleton.from_blender(armature_obj)
    meta = {}
    names = clips or cfg.CLIPS
    for name in names:
        tr, m = cfg.build(name, sk)
        bake(armature_obj, name, tr)
        meta[name] = m
        if verbose:
            print("[anim] %-16s %5.2fs loop=%s impact=%s" % (name, m["duration"], m["loop"], m.get("impact")))
    armature_obj.animation_data.action = None
    return meta


def bake(rig, name, tr):
    import bpy
    from bpy_extras.anim_utils import action_ensure_channelbag_for_slot
    Q, locs = tr.local_quats()
    old = bpy.data.actions.get(name)
    if old is not None:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    slot = act.slots.new(id_type="OBJECT", name=rig.name)
    rig.animation_data.action = act
    rig.animation_data.action_slot = slot
    cb = action_ensure_channelbag_for_slot(act, slot)
    F = tr.F
    frames = 1 + np.arange(F, dtype=np.float64)
    sk = tr.sk
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"

    def put(path, idx, vals, group):
        fc = cb.fcurves.new(path, index=idx, group_name=group)
        fc.keyframe_points.add(F)
        co = np.empty(F * 2)
        co[0::2] = frames
        co[1::2] = vals
        fc.keyframe_points.foreach_set("co", co)
        fc.keyframe_points.foreach_set("interpolation", [1] * F)   # LINEAR (data is per-frame)
        fc.update()
    for i, n in enumerate(sk.names):
        if n == "root":
            continue
        dp = 'pose.bones["%s"]' % n
        for c in range(4):
            put(dp + ".rotation_quaternion", c, Q[:, i, c], n)
        if n in locs or n in ("hips", "weapon_ext1", "weapon_ext2"):
            L = locs.get(n, np.zeros((F, 3)))
            for c in range(3):
                put(dp + ".location", c, L[:, c], n)
    return act
