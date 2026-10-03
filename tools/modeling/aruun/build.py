#!/usr/bin/env python3
"""Aruun end-to-end build (Blender 5.0 as a python module, headless).

  python3 tools/modeling/aruun/build.py geo        # geometry only -> work/aruun_geo.npz + work/aruun_geo.blend
  python3 tools/modeling/aruun/build.py all        # geometry, UVs, textures, rig, animations, glb export

Stages live in sibling modules: body.py (geometry), paint.py (textures), rig.py (armature+weights),
anims.py (keyframed actions), export.py (glTF + Godot side files).
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from common.geo import MeshBuilder  # noqa: E402
from common import bpy_util as bu  # noqa: E402
import body  # noqa: E402

WORK = os.path.join(HERE, "work")
os.makedirs(WORK, exist_ok=True)


def snap_to_anatomy(mb, sdf):
    """Project low-poly vertices of the SNAP parts onto their anatomy SDF group."""
    vpart = {}
    for idx, _, _, pid in mb.faces:
        for i in idx:
            vpart.setdefault(i, mb.parts[pid])
    by_group = {}
    for i, nm in vpart.items():
        base = nm.split(".")[0]
        if base in body.SNAP:
            g = body.SNAP[base] + ("." + nm.split(".")[1] if "." in nm else "")
            by_group.setdefault(g, []).append(i)
    for g, ids in by_group.items():
        P = np.array([tuple(mb.verts[i]) for i in ids])
        d = sdf.eval(P, [g])
        keep = d > -0.025          # cap centres deep inside stay put
        Q = sdf.project(P, [g], iters=6, max_move=0.06)
        for k, i in enumerate(ids):
            if keep[k]:
                mb.verts[i] = body.V(*Q[k])


def build_geometry():
    bu.reset_scene()
    mb = MeshBuilder()
    body.build_body(mb)
    snap_to_anatomy(mb, body.anatomy())
    mm = MeshBuilder()
    body.build_morrow(mm)
    mats = [bu.principled("aruun_body", (0.5, 0.2, 0.15, 1)), bu.principled("aruun_gear", (0.6, 0.5, 0.35, 1))]
    mor = [bu.principled("morrow", (0.15, 0.12, 0.12, 1))]
    ob = bu.to_object(mb, "Aruun", mats)
    om = bu.to_object(mm, "Morrow", mats + mor)
    return mb, mm, ob, om


def tri_stats(mb):
    per = {}
    for idx, _, _, pid in mb.faces:
        n = mb.parts[pid].split(".")[0]
        per[n] = per.get(n, 0) + len(idx) - 2
    return per


def save_geo_npz(mb):
    V = np.array([tuple(v) for v in mb.verts])
    T = []
    for idx, _, _, _ in mb.faces:
        for k in range(1, len(idx) - 1):
            T.append((idx[0], idx[k], idx[k + 1]))
    np.savez(os.path.join(WORK, "aruun_geo.npz"), V=V, T=np.array(T, dtype=np.int32))


if __name__ == "__main__":
    stage = sys.argv[1] if len(sys.argv) > 1 else "all"
    mb, mm, ob, om = build_geometry()
    save_geo_npz(mb)
    st = tri_stats(mb)
    print("body tris", mb.tri_count(), "morrow tris", mm.tri_count())
    print(sorted(st.items(), key=lambda kv: -kv[1]))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "aruun_geo.blend"))
