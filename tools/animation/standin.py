#!/usr/bin/env python3
"""Stand-in humanoid rig + segmented mannequin for animating a character before its real model exists.

    python3 tools/animation/standin.py cigarra     # -> game/art/models/_standin/cigarra_standin.{glb,json,tscn}
                                                   #    tools/animation/characters/cigarra_skeleton.json

Bone names follow the Aruun rig convention (hips/spine1/spine2/chest/neck1/head, clavicle/upperarm/forearm/hand,
thigh/shin/foot/toe, local X = world +X roll), so a real model built later with the same bone names drops in and
tools/animation/apply.py bakes the same clip set onto it. Extra bones per character (wings, crown) are listed in
STANDINS. The mannequin is rigidly skinned tapered capsules: it exists to judge motion, not looks.
The scene file is deliberately *not* <id>_model.tscn, so the 3D-models setting never shows a mannequin in game.
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

# character frame: x = her left, -y = forward, z = up (metres)
STANDINS = {
    "cigarra": {
        "height": 1.65,
        "joints": {
            "hips": (0, 0.0, 0.90), "spine1": (0, 0.0, 1.00), "spine2": (0, 0.005, 1.11), "chest": (0, 0.0, 1.22),
            "neck1": (0, -0.005, 1.36), "head": (0, -0.02, 1.44), "head_end": (0, -0.03, 1.57),
            "crown_end": (0, 0.05, 1.68),
            "clav.L": (0.03, -0.0, 1.33), "shoulder.L": (0.165, 0.01, 1.335), "elbow.L": (0.195, 0.025, 1.08),
            "wrist.L": (0.215, -0.005, 0.845), "hand_end.L": (0.22, -0.015, 0.75),
            "hip.L": (0.085, 0.0, 0.89), "knee.L": (0.095, -0.015, 0.485), "ankle.L": (0.10, 0.02, 0.085),
            "ball.L": (0.105, -0.085, 0.02), "toe_end.L": (0.11, -0.15, 0.015),
            "wing_root.L": (0.05, 0.075, 1.31), "wing_end.L": (0.13, 0.13, 0.80),
        },
        # name, head joint, tail joint, parent
        "bones": [
            ("hips", "hips", "spine1", "root"), ("spine1", "spine1", "spine2", "hips"),
            ("spine2", "spine2", "chest", "spine1"), ("chest", "chest", "neck1", "spine2"),
            ("neck1", "neck1", "head", "chest"), ("head", "head", "head_end", "neck1"),
            ("crown", "head_end", "crown_end", "head"),
            ("clavicle.L", "clav.L", "shoulder.L", "chest"), ("upperarm.L", "shoulder.L", "elbow.L", "clavicle.L"),
            ("forearm.L", "elbow.L", "wrist.L", "upperarm.L"), ("hand.L", "wrist.L", "hand_end.L", "forearm.L"),
            ("thigh.L", "hip.L", "knee.L", "hips"), ("shin.L", "knee.L", "ankle.L", "thigh.L"),
            ("foot.L", "ankle.L", "ball.L", "shin.L"), ("toe.L", "ball.L", "toe_end.L", "foot.L"),
            ("wing.L", "wing_root.L", "wing_end.L", "chest"),
        ],
        # bone: (radius at head, radius at tail, colour)
        "shape": {
            "hips": (0.12, 0.10, "cloth"), "spine1": (0.10, 0.10, "cloth"), "spine2": (0.105, 0.115, "cloth"),
            "chest": (0.12, 0.07, "cloth"), "neck1": (0.04, 0.04, "skin"), "head": (0.075, 0.07, "skin"),
            "crown": (0.03, 0.01, "crown"), "clavicle.L": (0.04, 0.045, "collar"),
            "upperarm.L": (0.042, 0.034, "cloth"), "forearm.L": (0.032, 0.026, "skin"), "hand.L": (0.025, 0.018, "skin"),
            "thigh.L": (0.06, 0.042, "cloth"), "shin.L": (0.04, 0.03, "cloth"), "foot.L": (0.032, 0.026, "skin"),
            "toe.L": (0.024, 0.014, "skin"), "wing.L": (0.0, 0.0, "wing"),
        },
        # Bad Thought / abilities all call play_attack("cast"); the kit's ability_used picks the ability clip
        "tscn_extra": 'combo_clips = PackedStringArray("attack_1", "attack_1")\n'
                      'attack_map = {"cast": "attack_1", "heavy": "attack_1", "leap": "leap"}\nmax_speed = 5.4\n',
        "colours": {"cloth": (0.16, 0.13, 0.12, 1), "skin": (0.62, 0.72, 0.52, 1), "collar": (0.06, 0.05, 0.06, 1),
                    "crown": (0.05, 0.04, 0.05, 1), "wing": (0.45, 0.85, 0.45, 0.45), "eye": (0.85, 0.95, 0.2, 1)},
    }
}


def mirror(cfg):
    J = dict(cfg["joints"])
    for k, v in list(J.items()):
        if k.endswith(".L"):
            J[k[:-2] + ".R"] = (-v[0], v[1], v[2])
    B = list(cfg["bones"])
    for n, h, t, p in cfg["bones"]:
        if n.endswith(".L"):
            f = lambda s: s[:-2] + ".R" if s.endswith(".L") else s  # noqa: E731
            B.append((f(n), f(h), f(t), f(p)))
    S = dict(cfg["shape"])
    for k, v in cfg["shape"].items():
        if k.endswith(".L"):
            S[k[:-2] + ".R"] = v
    return J, B, S


def build_armature(name, J, B):
    arm = bpy.data.armatures.new(name + "Rig")
    ob = bpy.data.objects.new(name + "_Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones
    r = eb.new("root")
    r.head, r.tail = Vector((0, 0, 0)), Vector((0, 0.3, 0))
    for n, h, t, p in B:
        b = eb.new(n)
        b.head, b.tail = Vector(J[h]), Vector(J[t])
        b.parent = eb[p]
        if n not in ("thigh.L", "thigh.R", "clavicle.L", "clavicle.R", "wing.L", "wing.R", "hips") and \
                (b.head - eb[p].tail).length < 1e-4:
            b.use_connect = True
        b.align_roll(Vector((0, -1, 0)) if abs(b.vector.normalized().y) < 0.9 else Vector((0, 0, 1)))
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def build_mesh(name, J, B, S, colours):
    bm = bmesh.new()
    mats = list(colours)
    groups = []           # per vertex bone name
    mat_of_face = []

    def add_capsule(a, b, ra, rb, bone, col, seg=10, rings=6):
        a, b = np.array(a, float), np.array(b, float)
        ax = b - a
        L = np.linalg.norm(ax)
        z = ax / L
        x = np.cross(z, [0, 0, 1.0]) if abs(z[2]) < 0.9 else np.cross(z, [1.0, 0, 0])
        x /= np.linalg.norm(x)
        y = np.cross(z, x)
        prof = []   # (t along, radius)
        for k in range(rings + 1):          # hemisphere-ish caps + tapered body
            u = k / rings
            prof.append((-ra * math.cos(u * math.pi / 2) + 0.0, ra * math.sin(u * math.pi / 2)))
        for k in range(1, 6):
            u = k / 6
            prof.append((u * L, ra + (rb - ra) * u))
        for k in range(rings, -1, -1):
            u = k / rings
            prof.append((L + rb * math.cos(u * math.pi / 2), rb * math.sin(u * math.pi / 2)))
        vs = []
        for t, rr in prof:
            ring = []
            for s in range(seg):
                ang = 2 * math.pi * s / seg
                p = a + z * t + (x * math.cos(ang) + y * math.sin(ang)) * rr
                ring.append(bm.verts.new(p))
                groups.append(bone)
            vs.append(ring)
        for i in range(len(vs) - 1):
            for s in range(seg):
                f = bm.faces.new((vs[i][s], vs[i][(s + 1) % seg], vs[i + 1][(s + 1) % seg], vs[i + 1][s]))
                mat_of_face.append((f, mats.index(col)))

    def add_sphere(c, r, bone, col):
        add_capsule(np.array(c) - [0, 0, r * 0.3], np.array(c) + [0, 0, r * 0.3], r, r, bone, col, seg=8, rings=4)

    for n, h, t, p in B:
        ra, rb, col = S[n]
        if col == "wing":
            # treehopper-wing cloak: a long leaf (3 quads) hanging down the back, translucent green
            a, b = np.array(J[h]), np.array(J[t])
            side = np.sign(a[0]) or 1.0
            w = np.array([side * 0.11, 0.02, 0])
            pts = [a, a + w * 0.6, a + (b - a) * 0.5 + w, a + (b - a) * 0.5 - w * 0.2, b + w * 0.4, b]
            v = [bm.verts.new(q) for q in pts]
            groups.extend([n] * len(v))
            for quad in ((0, 1, 2, 3), (3, 2, 4, 5)):
                f = bm.faces.new([v[i] for i in quad])
                mat_of_face.append((f, mats.index("wing")))
            continue
        add_capsule(J[h], J[t], ra, rb, n, col)
    # crown spheres (branching black spheres) + eyes + oversized collar
    hc = np.array(J["head_end"])
    for dx, dy, dz in ((0, 0.06, 0.13), (0.07, 0.03, 0.08), (-0.07, 0.03, 0.08), (0, 0.12, 0.06)):
        add_sphere(hc + [dx, dy, dz], 0.028, "crown", "crown")
    hd = np.array(J["head"])
    for sx in (1, -1):
        add_sphere(hd + [sx * 0.035, -0.06, 0.07], 0.018, "head", "eye")
    nk = np.array(J["neck1"])
    add_capsule(nk + [0.0, 0.0, -0.02], nk + [0.0, 0.0, 0.03], 0.13, 0.11, "chest", "collar", seg=12, rings=2)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    order = {f.index: m for f, m in mat_of_face}
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for c in mats:
        m = bpy.data.materials.new("standin_" + c)
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        rgba = colours[c]
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Roughness"].default_value = 0.7
        if rgba[3] < 1:
            bsdf.inputs["Alpha"].default_value = rgba[3]
            m.surface_render_method = "BLENDED"
        ob.data.materials.append(m)
    me.polygons.foreach_set("material_index", np.array([order[i] for i in range(len(me.polygons))], dtype=np.int32))
    for pgn in me.polygons:
        pgn.use_smooth = True
    vg = {}
    for i, g in enumerate(groups):
        if g not in vg:
            vg[g] = ob.vertex_groups.new(name=g)
        vg[g].add([i], 1.0, "REPLACE")
    return ob


def main(cid):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cfg = STANDINS[cid]
    J, B, S = mirror(cfg)
    rig = build_armature(cid, J, B)
    ob = build_mesh(cid.capitalize(), J, B, S, cfg["colours"])
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    # skeleton json for offline clip building (same format as aruun_skeleton.json)
    from retarget import Skeleton
    sk = Skeleton.from_blender(rig)
    bones = [[n, (sk.names[p] if p >= 0 else None), sk.rest[i].tolist(), float(sk.length[i])]
             for i, (n, p) in enumerate(zip(sk.names, sk.parent))]
    json.dump(bones, open(os.path.join(HERE, "characters", cid + "_skeleton.json"), "w"))
    from apply import apply_animations
    meta = apply_animations(rig, cid)
    out = os.path.join(ROOT, "game", "art", "models", "_standin")
    os.makedirs(out, exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    glb = os.path.join(out, cid + "_standin.glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True)
    json.dump({"height_m": cfg["height"], "fps": 30, "standin": True, "animations": meta},
              open(os.path.join(out, cid + "_anim.json"), "w"), indent=1)
    tscn = os.path.join(out, cid + "_standin.tscn")
    open(tscn, "w").write(
        '[gd_scene load_steps=3 format=3]\n\n'
        '[ext_resource type="Script" path="res://game/art/models/character_model.gd" id="1"]\n'
        '[ext_resource type="PackedScene" path="res://game/art/models/_standin/%s_standin.glb" id="2"]\n\n'
        '[node name="%sStandin" type="Node3D"]\nscript = ExtResource("1")\nmodel_scene = ExtResource("2")\n'
        'anim_json = "res://game/art/models/_standin/%s_anim.json"\nheight_m = %.2f\ncharacter_id = "%s"\n%s'
        % (cid, cid.capitalize(), cid, cfg["height"], cid, cfg.get("tscn_extra", "")))
    print("STANDIN", glb)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "cigarra")
