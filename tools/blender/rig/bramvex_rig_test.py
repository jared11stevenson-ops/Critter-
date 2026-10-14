"""Bramvex rig attempt 1 (experimental): hand-placed armature from side/front measurements + Blender automatic weights on the
decimated game body, then renders 4 test poses to check tearing. Usage: python3 bramvex_rig_test.py  (writes /tmp/rg/pose_*.png).
Frame: x forward, y across (right = -y), z up, metres (model height 3.3)."""
import bpy, math, mathutils
from mathutils import Vector, Euler
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="/home/user/critter/v2/art/models/bramvex.glb")
body = bpy.data.objects["torso"]; head = bpy.data.objects["head"]; weapon = bpy.data.objects["weapon"]; extra = bpy.data.objects["extra"]
for o in (body, head, weapon, extra):
    o.data.transform(o.matrix_world); o.matrix_world = mathutils.Matrix.Identity(4); o.parent = None
for n in ("arm_f", "arm_b", "leg_f", "leg_b"):
    bpy.data.objects.remove(bpy.data.objects[n])
arm = bpy.data.objects.new("rig", bpy.data.armatures.new("rig")); bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="EDIT")
E = arm.data.edit_bones
J = {   # name: (head, tail, parent)
 "hips": ((-0.55, 0, 1.3), (-0.5, 0, 1.6), None), "spine": ((-0.5, 0, 1.6), (-0.45, 0, 2.05), "hips"), "chest": ((-0.45, 0, 2.05), (-0.3, 0, 2.4), "spine"),
 "neck": ((-0.3, 0, 2.4), (-0.05, 0, 2.6), "chest"),
 "l_up": ((-0.4, 0.35, 2.3), (-0.4, 0.7, 2.1), "chest"), "l_lo": ((-0.4, 0.7, 2.1), (-0.4, 1.0, 2.0), "l_up"),
 "r_up": ((-0.4, -0.32, 2.2), (-0.35, -0.6, 1.6), "chest"), "r_lo": ((-0.35, -0.6, 1.6), (-0.1, -0.72, 1.25), "r_up"),
 "r_th": ((-0.55, -0.25, 1.3), (-0.2, -0.5, 0.85), "hips"), "r_sh": ((-0.2, -0.5, 0.85), (-0.5, -0.55, 0.15), "r_th"), "r_ft": ((-0.5, -0.55, 0.15), (-0.2, -0.55, 0.05), "r_sh"),
 "l_th": ((-0.55, 0.25, 1.3), (0.3, 0.5, 1.0), "hips"), "l_sh": ((0.3, 0.5, 1.0), (0.5, 0.6, 0.15), "l_th"), "l_ft": ((0.5, 0.6, 0.15), (0.8, 0.6, 0.05), "l_sh"),
}
for n, (h, t, p) in J.items():
    b = E.new(n); b.head = h; b.tail = t
    if p: b.parent = E[p]; b.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")
# rigid parts: head -> neck, weapon -> r_lo, extra (wing + lantern pole) -> chest; body: automatic weights
for o, bone in ((head, "neck"), (weapon, "r_lo"), (extra, "chest")):
    vg = o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    m = o.modifiers.new("a", "ARMATURE"); m.object = arm
# body: custom weights (not bone-heat): inverse-distance to bone segments with a sharp falloff, forearms/hands rigid with the club,
# and loose cloak (far from every bone, below the chest) follows the hips only so it never gets dragged by an arm or a leg
import numpy as np
body.parent = arm
m = body.modifiers.new("a", "ARMATURE"); m.object = arm
bones = {n: (np.array(h), np.array(t)) for n, (h, t, p) in J.items()}
def seg_d(p, a, b):
    ab = b - a; t = np.clip(np.dot(p - a, ab) / np.dot(ab, ab), 0, 1); return np.linalg.norm(p - (a + t * ab))
for n in J:
    body.vertex_groups.new(name=n)
hand = np.array(J["r_lo"][1])
for v in body.data.vertices:
    p = np.array(v.co)
    d = {n: seg_d(p, a, b) for n, (a, b) in bones.items()}
    dmin = min(d.values())
    if np.linalg.norm(p - hand) < 0.38:
        w = {"r_lo": 1.0}                                         # the hand and the club grip move as one
    elif dmin > 0.32 and p[2] < 1.6:
        w = {"hips": 1.0}                                         # loose cloak / shreds: pelvis only
    else:
        raw = {n: 1.0 / (dd + 0.03) ** 4 for n, dd in d.items() if dd < dmin + 0.12}
        tot = sum(raw.values()); w = {n: x / tot for n, x in raw.items()}
    for n, x in w.items():
        if x > 0.02:
            body.vertex_groups[n].add([v.index], float(x), "REPLACE")
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 6; sc.cycles.device = "CPU"; sc.render.resolution_x = 1000; sc.render.resolution_y = 800
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.8, 0.85, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.6
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 4.6; cam.location = (0, -10, 1.7); cam.rotation_euler = (math.radians(90), 0, 0)
POSES = {"rest": {}, "walk": {"r_th": (35, 0, 0), "r_sh": (-30, 0, 0), "l_th": (-25, 0, 0), "l_sh": (25, 0, 0), "r_up": (0, 0, 20), "spine": (0, 8, 0)},
         "strike": {"r_up": (-40, 0, 25), "r_lo": (-30, 0, 20), "spine": (0, 0, 15), "chest": (0, 0, 10), "l_up": (0, 0, -30)},
         "stand": {"hips": (0, 0, 0), "spine": (-15, 0, 0), "chest": (-10, 0, 0), "neck": (10, 0, 0), "r_th": (-20, 0, 0), "r_sh": (20, 0, 0), "l_th": (-20, 0, 0), "l_sh": (20, 0, 0)}}
bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
for pn, rots in POSES.items():
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"; pb.rotation_euler = Euler((0, 0, 0))
    for bn, r in rots.items():
        arm.pose.bones[bn].rotation_euler = Euler([math.radians(a) for a in r])
    bpy.context.view_layer.update()
    sc.render.filepath = f"/tmp/rg/pose_{pn}.png"; bpy.ops.render.render(write_still=True)
