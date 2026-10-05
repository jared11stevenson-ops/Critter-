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
HEAD_J = np.array([0.085, -0.085, 1.915]); JAW_J = np.array([0.085, -0.022, 1.999])
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
    for k in ("skull", "eye", "tooth_up"):
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
    # horns -> head
    m = vk == "horn"; Wn[m] = 0; Wn[m, bi["head"]] = 1
    for vi in range(len(Wn)):
        row = Wn[vi]
        if (row > 0).sum() > 4:
            keep = np.argsort(row)[-4:]; mask = np.zeros_like(row); mask[keep] = row[keep]; row = mask
        s = row.sum(); Wn[vi] = row / s if s > 0 else row
    return Wn, bones


def main():
    gm = np.load(os.path.join(W3, "game_mesh.npz"), allow_pickle=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    F2.patch_joints()
    ob = meshio.make_object(os.path.join(W3, "game_mesh.npz"), "Aruun")
    paths = {}
    for nm in ("albedo", "normal", "orm", "emissive"):
        paths[nm] = os.path.join(W3, nm + ".png")
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
                                  export_yup=True, export_force_sampling=True, export_image_format="WEBP")
        tris = bu.tri_count(ob)
        meta = {"height_m": 2.4, "tris": tris, "texture_px": 2048, "fps": fin.anims.FPS, "animations": impacts}
        json.dump(meta, open(os.path.join(OUT, "aruun_anim.json"), "w"), indent=1)
        print("TRIS", tris, "->", glb)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(W3, "aruun_v3.blend"))


if __name__ == "__main__":
    main()
