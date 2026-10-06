#!/usr/bin/env python3
"""Aruun v3 final stage (bpy): v3 game_mesh + painted maps -> skinned, animated glb (same 36 bones / API).
   python3 tools/modeling/aruun/v3/finish3.py [--no-export]"""
import json, os, sys
import numpy as np
from scipy.spatial import cKDTree
HERE = os.path.dirname(os.path.abspath(__file__)); V2 = os.path.join(HERE, "..", "v2")
sys.path.insert(0, V2); sys.path.insert(0, HERE)
import finish2 as F2
import bpy
from PIL import Image
import finish as fin
from common import bpy_util as bu
import meshio
W3 = os.path.join(HERE, "..", "work", "v3")
OUT = fin.OUT
_H = np.load(os.path.join(W3, "head_raw.npz")); _O, _SC = _H["origin"], float(_H["scale"])
HEAD_J = np.array([0.085, -0.085, 1.915]); JAW_J = _O + _SC * np.array([0.0, 0.03, -0.05])
_orig_sj = F2.shell_joints


def shell_joints3():
    J = _orig_sj()
    J["head"] = HEAD_J.copy(); J["head_end"] = HEAD_J + np.array([0, -0.22, 0.06])
    J["jaw"] = JAW_J.copy(); J["jaw_end"] = JAW_J + np.array([0, -0.2, -0.05])
    return J


F2.shell_joints = shell_joints3


def weights3(gm):
    F2.WORK = os.path.join(HERE, "..", "work", "v2")      # old.npz / fit.npz live in v2
    Wn, bones = F2.build_weights(None, gm)
    bi = {b: i for i, b in enumerate(bones)}
    Vn = gm["V"].astype(np.float64); T_ = gm["T"]
    kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]])
    vk = np.full(len(Vn), "", object)
    for t, k in enumerate(kinds): vk[T_[t]] = k
    trunk = np.where(vk == "trunk")[0]
    neckv = trunk[Vn[trunk, 2] > 1.74]
    kd = cKDTree(Vn[neckv])
    for k in ("skull", "eye", "tooth_up", "tine", "fringe_head"):
        m = np.where(vk == k)[0]
        _, ii = kd.query(Vn[m], k=4)
        wneck = Wn[neckv][ii].mean(1)
        t = np.clip((Vn[m, 2] - 1.855) / 0.075, 0, 1)[:, None]
        if k != "skull": t = np.ones_like(t)
        wh = np.zeros_like(wneck); wh[:, bi["head"]] = 1
        Wn[m] = t * wh + (1 - t) * wneck
    for k in ("jaw", "tooth_lo", "tongue"):
        m = np.where(vk == k)[0]
        Wn[m] = 0; Wn[m, bi["jaw"]] = 1.0
    # horns / mane -> head
    for kk in ("horn", "mane"):
        m = vk == kk; Wn[m] = 0; Wn[m, bi["head"]] = 1
    nm_v = np.full(len(Vn), "", object)
    for t, k in enumerate(gm["facekinds"]): nm_v[T_[t]] = str(k).split("|")[0]
    for i in np.where(vk == "leaf")[0]:
        z = Vn[i, 2]; a_ = float(np.clip((1.05 - z) / 0.3, 0, 1)) * 0.97; Wn[i] = 0; x_ = Vn[i, 0]
        Wn[i, bi["hips"]] = 1 - a_
        th_ = "thigh.L" if x_ > 0.02 else "thigh.R" if x_ < -0.02 else None
        if th_ is None: Wn[i, bi["thigh.L"]] = a_ / 2; Wn[i, bi["thigh.R"]] = a_ / 2
        else: Wn[i, bi[th_]] = max(a_, 1e-3)
    for i in np.where(np.isin(vk, ["claw", "trinket"]))[0]:
        nm = nm_v[i]; Wn[i] = 0
        if nm.startswith(("claw_hand_L", "claw_thumb_L")): Wn[i, bi["hand.L"]] = 1
        elif nm.startswith("claw_hand_R"): Wn[i, bi["hand.R"]] = 1
        elif nm.startswith(("claw_toe_L", "claw_heel_L")): Wn[i, bi["foot.L"]] = 1
        elif nm.startswith(("claw_toe_R", "claw_heel_R")): Wn[i, bi["foot.R"]] = 1
        else: Wn[i, bi["hips"]] = 0.6; Wn[i, bi["spine1"]] = 0.4
    for vi in range(len(Wn)):
        row = Wn[vi]
        if (row > 0).sum() > 4:
            keep = np.argsort(row)[-4:]; mask = np.zeros_like(row); mask[keep] = row[keep]; row = mask
        s = row.sum(); Wn[vi] = row / s if s > 0 else row
    return Wn, bones


def add_expressions(ob, gm):
    """Shape keys on the head: angry (brows down/in, lip snarl), calm (brows up, lids heavy). Driven via CharacterModel.set_expression."""
    from paint_head import local, seg_d, smooth
    H = np.load(os.path.join(W3, "head_raw.npz")); O, sc = H["origin"], float(H["scale"])
    V = gm["V"].astype(np.float64)
    kinds = np.array([str(k).split("|")[1] for k in gm["facekinds"]]); T_ = gm["T"]
    vk = np.full(len(V), "", object)
    for t, k in enumerate(kinds): vk[T_[t]] = k
    L = local(V, O, sc); lx, lf, lz = L[:, 0], L[:, 1], L[:, 2]; s = np.where(lx >= 0, 1.0, -1.0)
    sk = vk == "skull"; eye = vk == "eye"
    wb = np.zeros(len(V)); inner = np.zeros(len(V))
    for sg in (-1, 1):
        a = np.array([sg * 0.030, 0.100, 0.030]); b = np.array([sg * 0.072, 0.040, 0.050]); c = np.array([sg * 0.074, -0.020, 0.030])
        d = np.minimum(seg_d(L, a, b), seg_d(L, b, c))
        w = smooth(0.034, 0.016, d) * (s == sg) * (lz > 0.012)
        wb = np.maximum(wb, w)
    inner = smooth(0.075, 0.03, np.abs(lx))
    lip = lz - (-0.034 - 0.06 * lf)
    wl = smooth(0.016, 0.004, np.abs(lip)) * smooth(0.04, 0.09, lf) * smooth(0.26, 0.2, lf) * (lip > -0.002)
    def mk(name, dloc):
        # dloc in head-local (x, f, z) -> world (x, -f, z) * scale
        dw = np.stack([dloc[:, 0], -dloc[:, 1], dloc[:, 2]], 1) * sc
        sk_ = ob.shape_key_add(name=name, from_mix=False)
        co = np.array([v.co[:] for v in ob.data.vertices], np.float64) if False else V
        sk_.data.foreach_set("co", (V + dw).astype(np.float32).ravel())
        sk_.value = 0.0
    if ob.data.shape_keys is None:
        ob.shape_key_add(name="Basis", from_mix=False)
    n = len(V)
    d = np.zeros((n, 3))
    # angry: brows low and knit, brow ridge forward, upper lip pulled up (snarl), eyes set back
    d[:, 2] -= wb * (0.006 + 0.010 * inner) * sk
    d[:, 0] -= s * wb * 0.005 * inner * sk
    d[:, 1] += wb * 0.004 * sk
    d[:, 2] += wl * 0.007 * sk
    d[:, 1] -= 0.004 * eye
    mk("angry", d)
    d = np.zeros((n, 3))
    d[:, 2] += wb * 0.006 * sk                       # calm: brow lifted, relaxed
    ez = np.zeros(n); ec = np.array([0.0, 0.0, 0.005])
    d[:, 2] -= 0.0 * eye
    mk("calm", d)
    # sleepy/heavy lids on the calm key: flatten eyeballs vertically about their centres
    sk2 = ob.data.shape_keys.key_blocks["calm"]
    co = np.array(sk2.data[:].__len__() * [0]) if False else None
    d2 = np.zeros((n, 3))
    for sg in (-1, 1):
        sel = eye & (s == sg)
        cz = lz[sel].mean(); d2[sel, 2] = (cz - lz[sel]) * 0.38 * sc
    sk2.data.foreach_set("co", (V + np.stack([d[:, 0], -d[:, 1], d[:, 2]], 1) * sc + d2).astype(np.float32).ravel())


def main():
    gm = np.load(os.path.join(W3, "game_mesh.npz"), allow_pickle=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    F2.patch_joints()
    ob = meshio.make_object(os.path.join(W3, "game_mesh.npz"), "Aruun")
    paths = {}
    for nm in ("albedo", "normal", "orm", "emissive"):
        paths[nm] = os.path.join(W3, nm + ".png")
    add_expressions(ob, gm)
    # per-vertex shader control (glb COLOR_0): r = outline width scale, g = rim scale, b = shade-floor boost
    kinds_t = np.array([str(k).split("|")[1] for k in gm["facekinds"]])
    vk = np.full(len(gm["V"]), "", object)
    for t, k in enumerate(kinds_t): vk[gm["T"][t]] = k
    headk = np.isin(vk, ["skull", "jaw", "eye", "tooth_up", "tooth_lo", "tongue", "tine", "fringe_head"])
    colr = np.ones((len(vk), 4), np.float32)
    colr[headk] = (0.22, 0.30, 1.0, 1.0); colr[vk == "horn"] = (0.45, 0.6, 0.4, 1.0); colr[vk == "mane"] = (0.15, 0.4, 0.3, 1.0); colr[vk == "claw"] = (0.4, 0.8, 0.0, 1.0); colr[vk == "trinket"] = (0.4, 0.8, 0.0, 1.0)
    ca = ob.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT"); ca.data.foreach_set("color", colr.ravel())
    mat = fin.make_material(paths)
    ob.data.materials.append(mat)
    for p in ob.data.polygons: p.material_index = 0
    rig = fin.build_armature()
    Wn, bones = weights3(gm)
    for bn in bones:
        if bn != "root": ob.vertex_groups.new(name=bn)
    for bj, bn in enumerate(bones):
        if bn == "root": continue
        idx = np.where(Wn[:, bj] > 0.004)[0]
        vg = ob.vertex_groups[bn]
        for vi in idx: vg.add([int(vi)], float(Wn[vi, bj]), "REPLACE")
    mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = rig; ob.parent = rig
    impacts = fin.build_animations(rig)
    for o in bpy.data.objects: o.select_set(o in (ob, rig))
    bpy.context.view_layer.objects.active = rig
    if "--no-export" not in sys.argv:
        glb = os.path.join(OUT, "aruun.glb")
        bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                                  export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                                  export_yup=True, export_force_sampling=True, export_image_format="WEBP", export_vertex_color="ACTIVE")
        tris = bu.tri_count(ob)
        meta = {"height_m": 2.4, "tris": tris, "texture_px": 2048, "fps": fin.anims.FPS, "animations": impacts}
        json.dump(meta, open(os.path.join(OUT, "aruun_anim.json"), "w"), indent=1)
        print("TRIS", tris, "->", glb)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(W3, "aruun_v3.blend"))


if __name__ == "__main__":
    main()
