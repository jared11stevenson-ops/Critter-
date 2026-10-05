#!/usr/bin/env python3
"""Cigarra v2 final (bpy): game_mesh + painted maps -> skinned, animated glb (same bone names as tools/animation/standin.py).
   python3 tools/modeling/cigarra/v2/finish2.py [--no-export]"""
import json, os, sys, copy, struct
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "animation")); sys.path.insert(0, os.path.join(ROOT, "tools", "modeling")); sys.path.insert(0, HERE)
import bpy
from PIL import Image
import standin
W2 = os.path.join(HERE, "..", "work", "v2")
OUT = os.path.join(ROOT, "game", "art", "models", "cigarra")
os.makedirs(OUT, exist_ok=True)
ARMS = {"shoulder.L": (0.165, 0.01, 1.335), "elbow.L": (0.222, 0.02, 1.085), "wrist.L": (0.288, -0.012, 0.850), "hand_end.L": (0.305, -0.02, 0.755)}


def seg_dist(P, a, b):
    a = np.asarray(a, float); b = np.asarray(b, float); ab = b - a
    t = np.clip(((P - a) @ ab) / (ab @ ab + 1e-12), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def material(name, albedo, orm=None, normal=None, emis=None, alpha=False, double=False):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; bs = nt.nodes["Principled BSDF"]
    def img(p, nc):
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(p)
        if nc: t.image.colorspace_settings.name = "Non-Color"
        return t
    a = img(albedo, False); nt.links.new(a.outputs["Color"], bs.inputs["Base Color"])
    if alpha: nt.links.new(a.outputs["Alpha"], bs.inputs["Alpha"])
    if orm:
        sep = nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(img(orm, True).outputs["Color"], sep.inputs["Color"])
        nt.links.new(sep.outputs["Green"], bs.inputs["Roughness"]); nt.links.new(sep.outputs["Blue"], bs.inputs["Metallic"])
    if normal:
        nm = nt.nodes.new("ShaderNodeNormalMap"); nt.links.new(img(normal, True).outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
    if emis:
        nt.links.new(img(emis, False).outputs["Color"], bs.inputs["Emission Color"]); bs.inputs["Emission Strength"].default_value = 1.0
    if alpha: m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    m.use_backface_culling = not double
    return m


def patch_alpha_mask(glb):
    data = open(glb, "rb").read(); n = struct.unpack("<I", data[12:16])[0]; js = json.loads(data[20:20 + n])
    for m in js.get("materials", []):
        if m.get("alphaMode") == "BLEND": m["alphaMode"] = "MASK"; m["alphaCutoff"] = 0.5
    nj = json.dumps(js, separators=(",", ":")).encode(); nj += b" " * ((4 - len(nj) % 4) % 4); rest = data[20 + n:]
    open(glb, "wb").write(data[:8] + struct.pack("<I", 12 + 8 + len(nj) + len(rest)) + struct.pack("<I", len(nj)) + b"JSON" + nj + rest)


def weights(gm, bones):
    """bone-name -> per-vertex weights; geometry-classified exponential nearest-bone weights for the body, rules for pieces"""
    V = gm["V"].astype(np.float64); n = len(V)
    kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]]); names = np.array([str(k).split("|")[0] for k in gm["facekinds"]])
    vk = np.full(n, "", object); vn = np.full(n, "", object)
    for t, (k, nm) in enumerate(zip(kinds, names)): vk[gm["T"][t]] = k; vn[gm["T"][t]] = nm
    bi = {b: i for i, b in enumerate(bones)}; names_b = list(bones)
    W = np.zeros((n, len(bones)), np.float32)
    seg = {b: (np.array(h), np.array(t)) for b, (h, t) in bones.items()}
    def dist(b, P): return seg_dist(P, *seg[b])
    def expw(P, cands, sig=0.02, rad=None):
        D = np.stack([dist(b, P) - (rad.get(b, 0) if rad else 0) for b in cands], 1)
        w = np.exp(-(D - D.min(1, keepdims=True)) / sig); w[D - D.min(1, keepdims=True) > 0.10] = 0
        return w / w.sum(1, keepdims=True)
    torso = ["hips", "spine1", "spine2", "chest", "neck1", "head"]
    for side in ("L", "R"):
        pass
    body = np.where(np.isin(vk, ["body", "hand", "skull"]))[0]
    P = V[body]
    chain_arm = lambda s: [np.array(J[f"shoulder.{s}"]), np.array(J[f"elbow.{s}"]), np.array(J[f"wrist.{s}"]), np.array(J[f"hand_end.{s}"])]
    def chain_d(P, pts): return np.min([seg_dist(P, pts[i], pts[i + 1]) for i in range(len(pts) - 1)], 0)
    dL = chain_d(P, chain_arm("L")) - 0.07; dR = chain_d(P, chain_arm("R")) - 0.07
    legL = [np.array(J["hip.L"]), np.array(J["knee.L"]), np.array(J["ankle.L"]), np.array(J["ball.L"])]; legR = [np.array(J["hip.R"]), np.array(J["knee.R"]), np.array(J["ankle.R"]), np.array(J["ball.R"])]
    lL = chain_d(P, legL) - 0.115; lR = chain_d(P, legR) - 0.115
    tor = chain_d(P, [np.array(J["hips"]), np.array(J["chest"]), np.array(J["head"]), np.array(J["head_end"])]) - 0.10
    stack = np.stack([dL, dR, lL, lR, tor], 1); grp = stack.argmin(1)
    # head/neck zone overrides
    zc = P[:, 2]
    cands = {0: ["clavicle.L", "upperarm.L", "forearm.L", "hand.L", "chest"], 1: ["clavicle.R", "upperarm.R", "forearm.R", "hand.R", "chest"],
             2: ["hips", "thigh.L", "shin.L", "foot.L", "toe.L"], 3: ["hips", "thigh.R", "shin.R", "foot.R", "toe.R"], 4: torso}
    for g, cd in cands.items():
        m = grp == g
        if m.any():
            w = expw(P[m], cd, 0.022 if g != 4 else 0.04)
            for j, b in enumerate(cd): W[body[m], bi[b]] = w[:, j]
    # tidy: torso vertices below the hips' height belong to hips only etc. handled by distance. head vertices: skull -> head bone with neck blend
    sk = np.where(vk == "skull")[0]
    t = np.clip((V[sk, 2] - 1.38) / 0.06, 0, 1)
    W[sk] = 0; W[sk, bi["head"]] = t; W[sk, bi["neck1"]] = 1 - t
    for i in np.where(vk == "eye")[0]: W[i, bi["head"]] = 1
    # pieces
    for i in np.where(vk == "card")[0]:
        nm = vn[i]; p = V[i]; sp = gm["sparam"][i]
        s = "L" if p[0] >= 0 else "R"
        if nm.startswith("hair_"):
            var_t = sp - 2.0 * np.floor(sp / 2.0 + 1e-4)
            if p[1] > 0.0 and p[2] < 1.66: W[i, bi["hair.B"]] = 0.85 * var_t; W[i, bi["head"]] = 1 - 0.85 * var_t
            else: W[i, bi["head"]] = 1
        elif nm.startswith("crowns_") or nm.startswith("crownb_"):
            side = nm.split("_")[1][0]
            if side == "C": W[i, bi["crown"]] = 0.7; W[i, bi["head"]] = 0.3
            else: W[i, bi["stalk." + side]] = 0.8; W[i, bi["head"]] = 0.2
        elif nm == "crown_trunk": W[i, bi["crown"]] = 0.5; W[i, bi["head"]] = 0.5
        elif nm in ("hood_roll", "collar"): W[i, bi["neck1"]] = 0.55; W[i, bi["chest"]] = 0.45
        elif nm == "hood_bag": u = float(np.clip((1.40 - p[2]) / 0.2, 0, 1)); W[i, bi["chest"]] = 0.5 + 0.5 * u; W[i, bi["neck1"]] = 0.5 - 0.5 * u
        elif nm == "cape": u = float(np.clip((1.40 - p[2]) / 0.5, 0, 1)); W[i, bi["chest"]] = 1 - 0.4 * u; W[i, bi["spine1"]] = 0.4 * u
        elif nm.startswith("wing_"):
            wb = "wing" if nm.startswith("wing_0") else "wing2"; sd = nm.split("_")[-1]
            u = sp; root = float(np.clip(1.0 - u / 0.16, 0, 1)); W[i, bi[f"{wb}.{sd}"]] = 1 - root; W[i, bi["chest"]] = root
        elif nm in ("belt", "buckle") or nm.startswith(("cord_", "leafb_")): W[i, bi["hips"]] = 0.8; W[i, bi["spine1"]] = 0.2
        elif nm.startswith("charm_"): W[i, bi["hips"]] = 0.6; W[i, bi["thigh." + s]] = 0.4
        elif nm.startswith("leafboot_"): W[i, bi["foot." + nm.split("_")[1][0]]] = 1.0
        else: W[i, bi["chest"]] = 1
    # wings (kind "wing")
    for i in np.where(vk == "wing")[0]:
        nm = vn[i]; sp = gm["sparam"][i]; wb = "wing" if nm.startswith("wing_0") else "wing2"; sd = nm.split("_")[-1]
        root = float(np.clip(1.0 - sp / 0.16, 0, 1)); W[i, bi[f"{wb}.{sd}"]] = 1 - root; W[i, bi["chest"]] = root
    for vi in range(n):
        row = W[vi]
        if (row > 0).sum() > 4:
            keep = np.argsort(row)[-4:]; mk = np.zeros_like(row); mk[keep] = row[keep]; row = mk
        s_ = row.sum(); W[vi] = row / s_ if s_ > 0 else row
    return W


def add_expressions(ob, gm):
    from paint_cig import local, seg_d2, smooth
    H = np.load(os.path.join(W2, "head_raw.npz")); O, sc = H["origin"], float(H["scale"])
    V = gm["V"].astype(np.float64); kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]])
    vk = np.full(len(V), "", object)
    for t, k in enumerate(kinds): vk[gm["T"][t]] = k
    L = local(V, O, sc); lx, ly, lz = L[:, 0], L[:, 1], L[:, 2]; s = np.where(lx >= 0, 1.0, -1.0); ax = np.abs(lx)
    sk = vk == "skull"; eye = vk == "eye"; n = len(V)
    wb = np.zeros(n)
    for sg in (-1, 1):
        d = seg_d2(lx, lz, (sg * 0.030, 0.038), (sg * 0.066, 0.046))
        wb = np.maximum(wb, smooth(0.028, 0.010, d) * (s == sg) * (ly < -0.02) * (lz > 0.018))
    inner = smooth(0.07, 0.03, ax)
    wmouth = smooth(0.02, 0.008, np.hypot(lx / 1.4, lz + 0.074)) * (ly < -0.05)
    if ob.data.shape_keys is None: ob.shape_key_add(name="Basis", from_mixed=False) if False else ob.shape_key_add(name="Basis", from_mix=False)
    def mk(name, d):
        dw = d * sc; k = ob.shape_key_add(name=name, from_mix=False); k.data.foreach_set("co", (V + dw).astype(np.float32).ravel()); k.value = 0.0; return k
    d = np.zeros((n, 3)); d[:, 2] -= wb * (0.004 + 0.007 * inner) * sk; d[:, 0] -= s * wb * 0.004 * inner * sk; d[:, 1] -= wb * 0.003 * sk
    d[:, 2] -= 0.0025 * (eye & (lz > 0.008)); mk("angry", d)
    d = np.zeros((n, 3)); d[:, 2] += wb * 0.004 * sk; mk("calm", d)
    d = np.zeros((n, 3)); d[:, 2] -= wmouth * 0.012 * sk * (lz < -0.0705) + 0.0; d[:, 1] -= wmouth * 0.002 * sk * (lz < -0.0705); mk("open", d)


def main():
    global J
    gm = np.load(os.path.join(W2, "game_mesh.npz"), allow_pickle=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cfg = copy.deepcopy(standin.STANDINS["cigarra"])
    cfg["joints"].update(ARMS)
    J, Bn, S = standin.mirror(cfg)
    rig = standin.build_armature("Cigarra", J, Bn)
    V, T, UVc = gm["V"], gm["T"], gm["UVc"]
    kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]])
    me = bpy.data.meshes.new("Cigarra"); me.from_pydata(V.tolist(), [], T.tolist()); me.update()
    uv = me.uv_layers.new(name="UVMap"); uv.data.foreach_set("uv", UVc.reshape(-1, 2).ravel().astype(np.float32))
    me.polygons.foreach_set("material_index", (kinds == "wing").astype(np.int32))
    for p in me.polygons: p.use_smooth = True
    ob = bpy.data.objects.new("Cigarra", me); bpy.context.scene.collection.objects.link(ob)
    add_expressions(ob, gm)
    vk = np.full(len(V), "", object)
    for t, k in enumerate(kinds): vk[T[t]] = k
    colr = np.ones((len(V), 4), np.float32); head = np.isin(vk, ["skull", "eye"]); colr[head] = (0.30, 0.45, 0.8, 1.0)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT"); ca.data.foreach_set("color", colr.ravel())
    me.materials.append(material("cigarra_body", os.path.join(W2, "albedo.png"), os.path.join(W2, "orm.png"), os.path.join(W2, "normal.png"), os.path.join(W2, "emissive.png")))
    me.materials.append(material("cigarra_wings", os.path.join(W2, "wing_rgba.png"), None, None, os.path.join(W2, "wing_emissive.png"), alpha=True, double=True))
    bones = {b.name: (tuple(b.head_local), tuple(b.tail_local)) for b in rig.data.bones}
    Wt = weights(gm, bones); names_b = list(bones)
    for b in names_b:
        if b != "root": ob.vertex_groups.new(name=b)
    for j, b in enumerate(names_b):
        if b == "root": continue
        idx = np.where(Wt[:, j] > 0.004)[0]; vg = ob.vertex_groups[b]
        for vi in idx: vg.add([int(vi)], float(Wt[vi, j]), "REPLACE")
    ob.parent = rig; mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = rig
    from apply import apply_animations
    meta = apply_animations(rig, "cigarra")
    for o in bpy.data.objects: o.select_set(o in (ob, rig))
    bpy.context.view_layer.objects.active = rig
    if "--no-export" not in sys.argv:
        glb = os.path.join(OUT, "cigarra.glb")
        bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True, export_animation_mode="ACTIONS",
                                  export_skins=True, export_apply=False, export_yup=True, export_force_sampling=True, export_image_format="WEBP", export_vertex_color="ACTIVE")
        patch_alpha_mask(glb)
        tris = len(T)
        json.dump({"height_m": 1.65, "tris": tris, "fps": 30, "animations": meta}, open(os.path.join(OUT, "cigarra_anim.json"), "w"), indent=1)
        print("TRIS", tris, glb)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(W2, "cigarra_v2.blend"))


if __name__ == "__main__":
    main()
