#!/usr/bin/env python3
"""Frame-by-frame skirt clipping check: per clip/frame, count skirt ('leaf'/cloak_tail) vertices that sit inside
the evaluated thigh/shin surface (distance to the deformed thigh/shin vertex cloud along the bone < local radius).
Usage: python3 tools/modeling/aruun/qa_skirt.py [clip ...]"""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
import bpy  # noqa
from scipy.spatial import cKDTree

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "work", "aruun_final.blend"))
ob = bpy.data.objects["Aruun"]; rig = bpy.data.objects["Aruun_Rig"]
names = ob["parts"]; me = ob.data
pa = np.zeros(len(me.polygons), dtype=np.int32); me.attributes["part"].data.foreach_get("value", pa)
vp = [""] * len(me.vertices)
for p in me.polygons:
    for v in p.vertices:
        vp[v] = names[pa[p.index]].split(".")[0]
vp = np.array(vp)
skirt = np.isin(vp, ["leaf", "cloak_tail", "strip_olive", "strip_cream"])
leg = np.isin(vp, ["thigh", "shin"])
clips = sys.argv[1:] or ["run", "downed"]
for clip in clips:
    act = bpy.data.actions.get(clip)
    if act is None:
        print(clip, "missing"); continue
    rig.animation_data.action = act
    f0, f1 = map(int, act.frame_range)
    worst = []
    for f in range(f0, f1 + 1):
        bpy.context.scene.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        em = ob.evaluated_get(dg).to_mesh()
        co = np.array([v.co[:] for v in em.vertices]); nr = np.array([v.normal[:] for v in em.vertices])
        ob.evaluated_get(dg).to_mesh_clear()
        L = co[leg]; tree = cKDTree(L)
        d, i = tree.query(co[skirt])
        inside = ((co[skirt] - L[i]) * nr[leg][i]).sum(1) < -0.004
        n = int((inside & (d < 0.05)).sum())
        worst.append((n, f))
        if n and f in (11, 17, 31): print("  f%d" % f, dict(zip(*np.unique(vp[skirt][inside & (d < 0.05)], return_counts=True))))
    worst.sort(reverse=True)
    print(clip, "frames", f1 - f0 + 1, "skirt verts inside legs: max %d @f%d, mean %.1f" % (worst[0][0], worst[0][1], np.mean([w[0] for w in worst])))
