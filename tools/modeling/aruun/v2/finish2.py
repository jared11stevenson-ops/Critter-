#!/usr/bin/env python3
"""Aruun v2 final stage (bpy): game_mesh.npz + textures -> skinned, animated glb in game/art/models/aruun.
  python3 tools/modeling/aruun/v2/finish2.py            (needs work/v2/{game_mesh.npz, fit.npz, old.npz, albedo_proj.png})
Rig = the legacy 36-bone armature with joints displaced by the sheet fit (same bone names / hierarchy / animation retarget).
Weights = nearest-vertex transfer from the legacy skin (smoothed) for the body/Morrow; analytic for new cloth cards; head for horns."""
import json, os, sys, shutil
import numpy as np
from scipy.spatial import cKDTree
HERE = os.path.dirname(os.path.abspath(__file__))
ARUUN = os.path.abspath(os.path.join(HERE, ".."))
sys.path.insert(0, ARUUN); sys.path.insert(0, os.path.join(ARUUN, ".."))
import bpy
from mathutils import Vector
from PIL import Image
import body as legacy_body
import finish as fin
from common import bpy_util as bu
import meshio

WORK = os.path.join(ARUUN, "work", "v2")
OUT = fin.OUT
TEXDIR = os.path.join(WORK, "tex")
os.makedirs(TEXDIR, exist_ok=True)


def shell_joints():
    """Joint table placed INSIDE the new shells: slice centroids at the legacy joint heights (rig hierarchy unchanged)."""
    hi = np.load(os.path.join(WORK, "shells_hi.npz"))
    def cen(g, z, dz=0.02):
        V = hi["V_" + g]; m = np.abs(V[:, 2] - z) < dz
        if m.sum() < 5:
            m = np.abs(V[:, 2] - z) < 0.06
        return V[m, :2].mean(0)
    old = legacy_body.J
    J = {}
    # spine / neck / head on the trunk centreline (head & neck from the head-zone slices)
    for n in ("hips", "spine1", "spine2", "chest", "neck1", "neck2", "neck3", "head", "jaw"):
        z = old[n].z
        if n == "hips":
            c = 0.5 * (cen("legL", 1.02, 0.05) + cen("legR", 1.02, 0.05))
        else:
            c = cen("trunk", z, 0.025)
        J[n] = np.array([c[0], c[1], z])
    # neck/head lean: use the neck shell centres directly (trunk slices include the head at z>1.9)
    J["head_end"] = J["head"] + np.array([0, -0.22, -0.03]); J["jaw_end"] = J["jaw"] + np.array([0, -0.2, -0.06])
    J["root"] = np.zeros(3)
    cx = J["chest"][0]
    for s, g, sg in ((".L", "armL", 1), (".R", "armR", -1)):
        z = old["shoulder.L"].z
        c = cen(g, 1.50, 0.04); J["shoulder" + s] = np.array([c[0], c[1], z])
        J["clavicle" + s] = np.array([cx + sg * 0.06, J["chest"][1] + 0.0, old["clavicle.L"].z])
        c = cen(g, old["elbow.L"].z, 0.03); J["elbow" + s] = np.array([c[0], c[1], old["elbow.L"].z])
        c = cen(g, old["wrist.L"].z, 0.03); J["wrist" + s] = np.array([c[0], c[1], old["wrist.L"].z])
        c = cen(g, old["hand_end.L"].z, 0.03); J["hand_end" + s] = np.array([c[0], c[1], old["hand_end.L"].z])
    for s, g in ((".L", "legL"), (".R", "legR")):
        c = cen(g, 1.02, 0.05); J["hip" + s] = np.array([c[0], c[1], old["hip.L"].z])
        c = cen(g, old["knee.L"].z, 0.03); J["knee" + s] = np.array([c[0], c[1], old["knee.L"].z])
        c = cen(g, old["ankle.L"].z, 0.03); J["ankle" + s] = np.array([c[0], c[1], old["ankle.L"].z])
        V = hi["V_" + g]; low = V[V[:, 2] < 0.12]
        ty = low[:, 1].min() + 0.02; tx = low[:, 0].mean()
        J["toe_end" + s] = np.array([tx, ty, 0.03]); J["toe" + s] = np.array([tx, ty + 0.13, 0.05])
    return J


def patch_joints():
    J = shell_joints()
    def jm(name):
        return Vector(np.asarray(J[name], float).tolist())
    legacy_body.jm = jm
    fin.body.jm = jm
    return J


def build_weights(rig, gm):
    old = np.load(os.path.join(WORK, "old.npz"), allow_pickle=True)
    fit = np.load(os.path.join(WORK, "fit.npz"))
    parts = list(old["parts"]); pot = old["part_of_tri"]; T = old["T"]; W = old["W"]; bones = list(old["bones"])
    V1 = fit["V1"] if "V1" in fit.files else fit["V"]
    def verts_of(pred):
        sel = [i for i, p in enumerate(parts) if pred(p)]
        return np.unique(T[np.isin(pot, sel)])
    mor = verts_of(lambda p: p.startswith("morrow"))
    cardp = ("cloak", "leaf", "strip", "band", "talisman", "beads", "cloth")
    bodyv = verts_of(lambda p: not p.startswith(("morrow",) + cardp))
    Vn = gm["V"].astype(np.float64)
    kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]]); names = np.array([str(k).split("|")[0] for k in gm["facekinds"]])
    T_ = gm["T"]
    vk = np.full(len(Vn), "", object); vn_ = np.full(len(Vn), "", object)
    for t, (k, n) in enumerate(zip(kinds, names)):
        vk[T_[t]] = k; vn_[T_[t]] = n
    Wn = np.zeros((len(Vn), len(bones)), np.float32)
    bi = {b: i for i, b in enumerate(bones)}
    def transfer(sel, cand, power=2.0, k=6):
        kd = cKDTree(V1[cand]); d, ii = kd.query(Vn[sel], k=k)
        w = 1.0 / (d + 0.01) ** power; w /= w.sum(1, keepdims=True)
        return np.einsum("nk,nkb->nb", w, W[cand][ii])
    m = vk == "morrow"; Wn[m] = transfer(np.where(m)[0], mor, k=3)
    m = np.isin(vk, ["trunk", "armL", "armR", "legL", "legR"]); Wn[m] = transfer(np.where(m)[0], bodyv)
    # smooth body weights over spatial neighbours (same kind)
    for _ in range(2):
        idx = np.where(m)[0]; kd = cKDTree(Vn[idx]); nb = kd.query_ball_point(Vn[idx], 0.025)
        Wc = Wn[idx].copy()
        for a, lst in enumerate(nb):
            Wn[idx[a]] = 0.5 * Wc[a] + 0.5 * Wc[lst].mean(0)
    # horns -> head
    m = np.isin(vk, ["horn", "headpart"]); Wn[m] = 0; Wn[m, bi["head"]] = 1.0
    # cloth cards: analytic (same ramps as the legacy rig)
    cl = vk == "card"
    body_w = np.zeros_like(Wn)
    if cl.any():
        body_w[cl] = transfer(np.where(cl)[0], bodyv, k=8)
    hip = Vn[(Vn[:, 2] > 1.1) & (Vn[:, 2] < 1.3) & np.isin(vk, ["trunk"])]
    xc = hip[:, 0].mean()
    for vi in np.where(cl)[0]:
        n = vn_[vi]; z = Vn[vi, 2]; x = Vn[vi, 0]
        if n in ("card_mantle", "card_fringe"):
            a = float(np.clip((1.62 - z) / 0.5, 0, 0.9)) if n == "card_fringe" else float(np.clip((1.62 - z) / 0.9, 0, 0.5))
            t = float(np.clip((1.15 - z) / 0.55, 0, 1))
            w = body_w[vi] * (1 - a); w[bi["cloak"]] += a * (1 - t); w[bi["cloak2"]] += a * t
            Wn[vi] = w
        else:       # skirt leaves / tassels
            a = float(np.clip((1.05 - z) / 0.3, 0, 1)) * 0.97
            w = np.zeros(len(bones), np.float32)
            th = "thigh.L" if x > xc + 0.02 else "thigh.R" if x < xc - 0.02 else None
            w[bi["hips"]] = 1 - a
            if th is None:
                w[bi["thigh.L"]] = a / 2; w[bi["thigh.R"]] = a / 2
            else:
                w[bi[th]] = max(a, 1e-3)
            Wn[vi] = w
    # head ownership for the head part of the trunk shell: zone above neck top gets head bone smoothly via transfer already
    # prune to 4 influences
    for vi in range(len(Wn)):
        row = Wn[vi]
        if (row > 0).sum() > 4:
            keep = np.argsort(row)[-4:]; mask = np.zeros_like(row); mask[keep] = row[keep]; row = mask
        s = row.sum()
        Wn[vi] = row / s if s > 0 else row
    return Wn, bones


def main():
    gm = np.load(os.path.join(WORK, "game_mesh.npz"), allow_pickle=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    patch_joints()
    ob = meshio.make_object(os.path.join(WORK, "game_mesh.npz"), "Aruun")
    # textures
    paths = {}
    alb = Image.open(os.path.join(WORK, "albedo_proj.png")).convert("RGB")
    for nm, im in (("albedo", alb),):
        p = os.path.join(TEXDIR, f"aruun_{nm}.png"); im.save(p); paths[nm] = p
    for nm in ("normal", "orm", "emissive"):
        src = os.path.join(WORK, f"{nm}.png")
        if not os.path.exists(src):
            base = {"normal": (128, 128, 255), "orm": (255, 190, 0), "emissive": (0, 0, 0)}[nm]
            Image.new("RGB", alb.size, base).save(src)
        paths[nm] = src
    mat = fin.make_material(paths)
    ob.data.materials.append(mat)
    for p in ob.data.polygons: p.material_index = 0
    rig = fin.build_armature()
    Wn, bones = build_weights(rig, gm)
    for bn in bones:
        if bn != "root":
            ob.vertex_groups.new(name=bn)
    for bj, bn in enumerate(bones):
        if bn == "root":
            continue
        idx = np.where(Wn[:, bj] > 0.004)[0]
        vg = ob.vertex_groups[bn]
        for vi in idx:
            vg.add([int(vi)], float(Wn[vi, bj]), "REPLACE")
    mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = rig; ob.parent = rig
    impacts = fin.build_animations(rig)
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    bpy.context.view_layer.objects.active = rig
    glb = os.path.join(OUT, "aruun.glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True, export_image_format="WEBP")
    tris = bu.tri_count(ob)
    meta = {"height_m": 2.4, "tris": tris, "texture_px": 2048, "fps": fin.anims.FPS, "animations": impacts}
    json.dump(meta, open(os.path.join(OUT, "aruun_anim.json"), "w"), indent=1)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "aruun_v2_final.blend"))
    print("TRIS", tris, "->", glb)


if __name__ == "__main__":
    main()
