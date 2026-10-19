"""Bramvex skinned build from the standing T-pose Tripo model (/tmp/cu/br2/plain.glb, decoded with gltf-transform copy).
Stages (python3 bramvex_skin.py STAGE):  prep  -> decimate the 1.9M-tri mesh to ~55k tris and save /tmp/rg/br2_low.blend
                                          rig   -> armature + region weights, renders rest + test poses to /tmp/rg/p2_*.png
                                          final -> rig + normal bake from the full mesh + skinned GLB to v2/art/models/bramvex_skin.glb
Frame (model units, feet z=0, height 0.98): faces +x, left = +y.  Game scale S=3.4."""
import bpy, bmesh, math, sys, os, json
import numpy as np
from mathutils import Vector, Euler, Quaternion
STAGE = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[-1]
S = 3.4
REPO_SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "source_art", "bramvex_standing.glb")
SRC = "/tmp/cu/br2/plain.glb"
if not os.path.exists(SRC):                      # fresh container: decode the meshopt-compressed source once
    os.makedirs(os.path.dirname(SRC), exist_ok=True)
    os.system('cd %s && cp "%s" src.glb && npx --yes @gltf-transform/cli copy src.glb plain.glb' % (os.path.dirname(SRC), REPO_SRC))
LOW = "/tmp/rg/br2_low.blend"; TRIS = 55000
# bones: name -> (head, tail, parent) in model units (x fwd, y left, z up). Measured from the mesh (see design/v2/anatomy/bramvex.md).
def mir(n, h, t, p):
    return {n + "_L": ((h[0], h[1], h[2]), (t[0], t[1], t[2]), (p + "_L") if p.endswith(("up", "lo", "hand", "th", "sh", "ft", "wing", "wing2", "shoulder")) else p),
            n + "_R": ((h[0], -h[1], h[2]), (t[0], -t[1], t[2]), (p + "_R") if p.endswith(("up", "lo", "hand", "th", "sh", "ft", "wing", "wing2", "shoulder")) else p)}
B = {"hips": ((0.02, 0, 0.50), (0.02, 0, 0.58), None), "spine": ((0.02, 0, 0.58), (0.015, 0, 0.66), "hips"), "chest": ((0.015, 0, 0.66), (0.015, 0, 0.74), "spine"),
     "neck": ((0.015, 0, 0.74), (0.04, 0, 0.80), "chest"), "head": ((0.04, 0, 0.80), (0.04, 0, 0.90), "neck")}
for d in (mir("shoulder", (0.01, 0.04, 0.68), (0.01, 0.09, 0.68), "chest"), mir("arm_up", (0.01, 0.09, 0.68), (0.02, 0.20, 0.68), "shoulder"),
          mir("arm_lo", (0.02, 0.20, 0.68), (0.03, 0.31, 0.67), "arm_up"), mir("hand", (0.03, 0.31, 0.67), (0.04, 0.36, 0.66), "arm_lo"),
          mir("th", (0.02, 0.055, 0.50), (0.02, 0.06, 0.30), "hips"), mir("sh", (0.02, 0.06, 0.30), (0.0, 0.085, 0.13), "th"),
          mir("ft", (0.0, 0.085, 0.13), (0.07, 0.10, 0.02), "sh"),
          mir("wing", (-0.05, 0.05, 0.71), (-0.09, 0.16, 0.58), "chest"), mir("wing2", (-0.09, 0.16, 0.58), (-0.10, 0.27, 0.46), "wing")):
    B.update(d)

# cloth chains hanging from the pelvis (front banner / back shreds) and club grips on the hands; Godot drives the chains with spring bones
for col, cx in (("cf", 0.06), ("cb", -0.05)):
    B[col + "1"] = ((cx, 0, 0.50), (cx, 0, 0.36), "hips")
    B[col + "2"] = ((cx, 0, 0.36), (cx, 0, 0.20), col + "1")
    B[col + "3"] = ((cx, 0, 0.20), (cx, 0, 0.03), col + "2")
for a in (1, -1):                                  # antennae: from the cap an arc outward, then a long thin stem hanging beside the head (measured from the red texture islands of the mesh); sprung in Godot
    sd = "_L" if a > 0 else "_R"
    pts = [(0.040, 0.066, 0.970), (0.036, 0.130, 0.935), (0.034, 0.138, 0.840), (0.033, 0.138, 0.735)]
    for k in range(3):
        B["ant%d%s" % (k + 1, sd)] = ((pts[k][0], a * pts[k][1], pts[k][2]), (pts[k + 1][0], a * pts[k + 1][1], pts[k + 1][2]), "head" if k == 0 else "ant%d%s" % (k, sd))
B["grip_L"] = ((0.035, 0.335, 0.665), (0.10, 0.335, 0.665), "hand_L")
B["grip_R"] = ((0.035, -0.335, 0.665), (0.10, -0.335, 0.665), "hand_R")

def load_src():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)
    ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
    ob.data.transform(ob.matrix_world); ob.matrix_world = ob.matrix_world.Identity(4)
    ob.data.transform(__import__("mathutils").Matrix.Translation((0, 0, 0.49)))       # feet to z=0
    ob.data.transform(__import__("mathutils").Matrix.Scale(S, 4))
    ob.name = "body"
    return ob

if STAGE == "prep":
    ob = load_src()
    t0 = len(ob.data.polygons)
    mod = ob.modifiers.new("d", "DECIMATE"); mod.decimate_type = "COLLAPSE"; mod.ratio = TRIS / max(t0, 1); mod.use_collapse_triangulate = True; mod.delimit = {"UV"}      # never collapse across UV seams: bridging triangles there sample the black gutter between texture islands (the dark shards)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="d")
    print("tris", t0, "->", len(ob.data.polygons))
    bpy.ops.wm.save_as_mainfile(filepath=LOW)
    sys.exit(0)

def load_src_into_scene():
    before = set(bpy.data.objects.keys())
    bpy.ops.import_scene.gltf(filepath=SRC)
    ob = [o for o in bpy.data.objects if o.type == "MESH" and o.name not in before][0]
    ob.data.transform(ob.matrix_world); ob.matrix_world = ob.matrix_world.Identity(4)
    ob.data.transform(__import__("mathutils").Matrix.Translation((0, 0, 0.49)))
    ob.data.transform(__import__("mathutils").Matrix.Scale(S, 4))
    ob.name = "body_hi"
    return ob

def build_rig(body):
    arm = bpy.data.objects.new("rig", bpy.data.armatures.new("rig")); bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="EDIT")
    E = arm.data.edit_bones
    for n, (h, t, p) in B.items():
        b = E.new(n); b.head = Vector(h) * S; b.tail = Vector(t) * S
        if p: b.parent = E[p]
    bpy.ops.object.mode_set(mode="OBJECT")
    # weights: region rules first (head / wings / loose cloth / arms), then inverse-distance to bone segments
    n = len(body.data.vertices); co = np.empty(n * 3, dtype=np.float32); body.data.vertices.foreach_get("co", co); V = co.reshape(-1, 3) / S
    seg = {k: (np.array(h), np.array(t)) for k, (h, t, p) in B.items()}
    def dist(P, a, b):
        ab = b - a; t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1); return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)
    names = list(B.keys())
    D = np.stack([dist(V, *seg[k]) for k in names], axis=1)                    # (n, bones)
    W = np.zeros((n, len(names)), dtype=np.float32)
    ix = {k: i for i, k in enumerate(names)}
    P = 6.0
    def generic_w(i, x, y, z, d):
        dg = d.copy()
        for k2 in names:
            if k2.startswith(("cf", "cb", "grip", "ant")):
                dg[ix[k2]] = 9.0                                           # cloth chains and grips only get weights from their own explicit rules (otherwise toe claws near the centre line stick to the cloth)
        cand = np.argsort(dg)[:4]
        raw = {names[c]: 1.0 / (dg[c] + 0.012) ** P for c in cand if dg[c] < dg[cand[0]] + 0.04}
        dleg = min(d[ix[k]] for k in ("th_L", "th_R", "sh_L", "sh_R", "ft_L", "ft_R"))
        if abs(y) < 0.02 and z < 0.50 and dleg > 0.03:                      # central banner strip / back shreds only: the cloth chain of its side (never leg skin, toe claws or ankle thorns)
            col = "cf" if x > 0.02 else "cb"
            cb = [col + "1", col + "2", col + "3"]
            raw = {k: 1.0 / (d[ix[k]] + 0.01) ** 4 for k in cb}
            if z > 0.44:
                raw["hips"] = 1.0 / (d[ix["hips"]] + 0.01) ** 4
        elif dg[cand[0]] > 0.075 and z < 0.52 and z > 0.30:                  # skirt panels beside the legs: pelvis and thighs
            f = float(np.clip((0.50 - z) / 0.30, 0.0, 0.7))
            raw = {"hips": 1.0 - f, "th_L": f * 0.5, "th_R": f * 0.5}
        tot = sum(raw.values()); return {k: v / tot for k, v in raw.items()}

    for i in range(n):
        x, y, z = V[i]
        side = "_L" if y >= 0 else "_R"
        d = D[i]
        ca = ["ant%d%s" % (k, side) for k in (1, 2, 3)]
        dstem = min(d[ix[k]] for k in ca)
        if z > 0.72 and abs(y) > 0.055 and dstem < 0.011:                      # the thin antenna stem itself: only the stem chain moves it (the cap brim and shoulder fur stay on head / shoulders)
            raw = {k: 1.0 / (d[ix[k]] + 0.006) ** 4 for k in ca}
            if z > 0.955:
                raw["head"] = 1.0 / (d[ix["head"]] + 0.006) ** 4 * 0.4
            tot = sum(raw.values()); w = {k: v / tot for k, v in raw.items()}
            fz = float(np.clip((z - 0.77) / 0.05, 0.0, 1.0))                   # the stem's lower tip is fused to the shoulder fur: it follows the shoulder there
            w = {k: v * fz for k, v in w.items()}
            w["arm_up" + side] = w.get("arm_up" + side, 0.0) + 0.86 * (1 - fz)
            w["shoulder" + side] = w.get("shoulder" + side, 0.0) + 0.14 * (1 - fz)
        elif z > 0.76 and not (abs(y) > 0.10 and z < 0.92):                      # head, cap, antennae, bridge to neck (shoulder fur out to the sides belongs to the shoulders)
            w = {"head": 1.0} if z > 0.79 else {"neck": 0.5, "head": 0.5}
        elif abs(y) > 0.085 and 0.52 < z < (0.92 if abs(y) > 0.10 else 0.80):                               # arms (T-pose), banners hanging from the forearm follow the forearm; a soft band blends them into the body so no triangle is stretched across the chest
            u = abs(y)
            aw = {"arm_up" + side: 1.0} if u < 0.20 else ({"arm_lo" + side: 1.0} if u < 0.31 else {"hand" + side: 1.0})
            t = float(np.clip((u - 0.085) / 0.08, 0.0, 1.0)); t = t * t * (3 - 2 * t)
            gw = generic_w(i, x, y, z, d)
            w = {}
            for k, v in gw.items():
                w[k] = w.get(k, 0.0) + (1 - t) * v
            for k, v in aw.items():
                w[k] = w.get(k, 0.0) + t * v
        else:
            w = generic_w(i, x, y, z, d)
        if abs(y) > 0.10 and 0.80 < z < 0.92:                                   # shoulder fur rises into the cap brim: ease from the arm weights up to the head so nothing spans both
            h = float(np.clip((z - 0.80) / 0.10, 0.0, 1.0)); h = h * h * (3 - 2 * h)
            w2 = {}
            for k, v in w.items():
                w2[k] = w2.get(k, 0.0) + (1 - h) * v
            w2["head"] = w2.get("head", 0.0) + h
            w = w2
        if (z <= 0.76 or abs(y) > 0.10) and abs(y) > 0.025 and 0.34 < z < 0.80 and x < -0.045:     # folded bat wings behind the shoulders, eased into whatever sits next to them (arm / body) so no triangle spans two rigid parts
            wf = float(np.clip((-0.045 - x) / 0.035, 0.0, 1.0)); wf = wf * wf * (3 - 2 * wf)
            t2 = float(np.clip((abs(y) - 0.115) / 0.05, 0.0, 1.0)); t2 = t2 * t2 * (3 - 2 * t2)
            ww = {"wing" + side: 1.0 - t2, "wing2" + side: t2}
            mixed = {}
            for k, v in w.items():
                mixed[k] = mixed.get(k, 0.0) + (1 - wf) * v
            for k, v in ww.items():
                mixed[k] = mixed.get(k, 0.0) + wf * v
            w = mixed
        for k, v in w.items():
            W[i, ix[k]] = v
    for k in names:
        body.vertex_groups.new(name=k)
    for j, k in enumerate(names):
        idx = np.nonzero(W[:, j] > 0.02)[0]
        for i in idx:
            body.vertex_groups[k].add([int(i)], float(W[i, j]), "REPLACE")
    body.parent = arm
    m = body.modifiers.new("a", "ARMATURE"); m.object = arm
    return arm

# poses: bone -> list of (global axis, degrees). x = forward axis, y = left axis, z = up. Pitch (bend forward/back) is about y, roll (lean sideways) about x, yaw about z.
POSES = {"rest": {},
         "walk": {"th_L": [("y", -35)], "sh_L": [("y", 30)], "th_R": [("y", 25)], "sh_R": [("y", -10)], "arm_up_L": [("z", 20)], "arm_up_R": [("z", -20)], "spine": [("z", 8)]},
         "strike": {"spine": [("z", 25)], "chest": [("z", 15)], "arm_up_R": [("x", 70), ("z", 20)], "arm_lo_R": [("x", 40)], "arm_up_L": [("z", -40)], "wing_L": [("x", -20)], "wing_R": [("x", 20)]},
         "crouch": {"th_L": [("y", -60)], "sh_L": [("y", 100)], "th_R": [("y", -60)], "sh_R": [("y", 100)], "spine": [("y", 25)], "chest": [("y", 15)], "neck": [("y", -25)]},
         "wingflare": {"wing_L": [("x", -60)], "wing_R": [("x", 60)], "wing2_L": [("x", -40)], "wing2_R": [("x", 40)], "arm_up_L": [("x", -30)], "arm_up_R": [("x", 30)]}}

def render_poses(arm, prefix):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 6; sc.cycles.device = "CPU"; sc.render.resolution_x = 800; sc.render.resolution_y = 800
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.8, 0.85, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.6
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.9
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    for pn, rots in POSES.items():
        for pb in arm.pose.bones:
            pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = Quaternion()
        for bn, steps in rots.items():
            pb = arm.pose.bones[bn]
            q = Quaternion()
            for ax, deg in steps:
                gv = Vector({"x": (1, 0, 0), "y": (0, 1, 0), "z": (0, 0, 1)}[ax])
                lv = pb.bone.matrix_local.to_3x3().inverted() @ gv
                q = Quaternion(lv.normalized(), math.radians(deg)) @ q
            pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = q
        bpy.context.view_layer.update()
        for vn, (loc, rot) in {"f": ((10, 0, 1.65), (90, 0, 90)), "s": ((0, -10, 1.65), (90, 0, 0))}.items():
            cam.location = loc; cam.rotation_euler = [math.radians(a) for a in rot]
            sc.render.filepath = f"/tmp/rg/{prefix}_{pn}_{vn}.png"; bpy.ops.render.render(write_still=True)
    bpy.ops.object.mode_set(mode="OBJECT")


if STAGE == "diag":
    bpy.ops.wm.open_mainfile(filepath=LOW)
    body = bpy.data.objects["body"]
    arm = build_rig(body)
    n0 = np.array([v.co[:] for v in body.data.vertices]) / S
    T = np.array([p.vertices[:] for p in body.data.polygons])
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode="POSE")
    for bn, steps in {"arm_up_L": [("x", -74)], "arm_up_R": [("x", 74)], "arm_lo_L": [("z", -16)], "arm_lo_R": [("z", 38)]}.items():
        pb = arm.pose.bones[bn]; q = Quaternion()
        for ax, deg in steps:
            gv = Vector({"x": (1, 0, 0), "y": (0, 1, 0), "z": (0, 0, 1)}[ax])
            lv = pb.bone.matrix_local.to_3x3().inverted() @ gv
            q = Quaternion(lv.normalized(), math.radians(deg)) @ q
        pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = q
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); ev = body.evaluated_get(dg)
    n1 = np.array([v.co[:] for v in ev.data.vertices]) / S
    def el(V):
        return np.stack([np.linalg.norm(V[T[:, 0]] - V[T[:, 1]], axis=1), np.linalg.norm(V[T[:, 1]] - V[T[:, 2]], axis=1), np.linalg.norm(V[T[:, 2]] - V[T[:, 0]], axis=1)], 1).max(1)
    e0, e1 = el(n0), el(n1)
    bad = np.where((e1 > 0.06) & (e1 > 2.5 * e0))[0]
    print("STRETCHED", len(bad))
    vg = {g.index: g.name for g in body.vertex_groups}
    for i in bad[:200]:
        ws = []
        for vi in T[i]:
            top = sorted(body.data.vertices[vi].groups, key=lambda g: -g.weight)[:2]
            ws.append("/".join("%s:%.2f" % (vg[g.group], g.weight) for g in top))
        print(round(e0[i], 3), "->", round(e1[i], 3), n0[T[i]].mean(0).round(2), ws)
    sys.exit(0)
if STAGE == "rig":
    bpy.ops.wm.open_mainfile(filepath=LOW)
    body = bpy.data.objects["body"]
    arm = build_rig(body)
    render_poses(arm, "p2")
    sys.exit(0)

if STAGE == "final":
    OUT = "/home/user/critter/v2/art/models"
    bpy.ops.wm.open_mainfile(filepath=LOW)
    body = bpy.data.objects["body"]
    arm = build_rig(body)
    render_poses(arm, "p5")
    # high-poly source for the normal bake (the full-detail mesh, same transform)
    for o in list(bpy.data.objects):
        o.select_set(False)
    hi = load_src_into_scene()
    mat = body.data.materials[0]
    tex = None
    for n in mat.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image:
            tex = n.image
    print("colour texture", tex.name if tex else None, tex.size[:] if tex else None)
    if tex.size[0] != 4096:
        tex.scale(4096, 4096)
    nrm = bpy.data.images.new("bramvex_normal", 4096, 4096, alpha=False); nrm.generated_color = (0.5, 0.5, 1.0, 1.0); nrm.colorspace_settings.name = "Non-Color"
    bm_ = bpy.data.materials.new("bake"); bm_.use_nodes = True
    tn = bm_.node_tree.nodes.new("ShaderNodeTexImage"); tn.image = nrm; bm_.node_tree.nodes.active = tn
    body.data.materials.clear(); body.data.materials.append(bm_)
    sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 1
    bpy.ops.object.select_all(action="DESELECT"); hi.select_set(True); body.select_set(True); bpy.context.view_layer.objects.active = body
    # bake in the REST pose (the armature is at rest after render_poses sets the last pose; reset it)
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = Quaternion()
    bpy.context.view_layer.update()
    bpy.ops.object.bake(type="NORMAL", use_selected_to_active=True, cage_extrusion=0.03, max_ray_distance=0.08, normal_space="TANGENT", margin=10, use_clear=False)
    print("baked")
    bpy.data.objects.remove(hi)
    body.data.materials.clear(); body.data.materials.append(mat)
    nn = mat.node_tree.nodes.new("ShaderNodeTexImage"); nn.image = nrm
    nm = mat.node_tree.nodes.new("ShaderNodeNormalMap")
    bsdf = [n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"][0]
    mat.node_tree.links.new(nn.outputs["Color"], nm.inputs["Color"]); mat.node_tree.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "bramvex_skin.glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=False,
                              export_materials="EXPORT", export_image_format="JPEG", export_jpeg_quality=90, export_tangents=True, export_skins=True, export_cameras=False, export_lights=False)
    print("done", os.path.getsize(os.path.join(OUT, "bramvex_skin.glb")))
