"""Dump the legacy (v1) Aruun game mesh + skin weights + part names + armature joints from work/aruun_final.blend
-> work/v2/old.npz.  Used as (a) shape prior, (b) skin-weight donor, (c) Morrow source for the v2 build."""
import os, sys, json
import numpy as np
import bpy
HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(HERE, "..", "work", "v2"); os.makedirs(WORK, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "..", "work", "aruun_final.blend"))
ob = bpy.data.objects["Aruun"]; rig = bpy.data.objects["Aruun_Rig"]
me = ob.data
me.calc_loop_triangles()
n = len(me.vertices)
co = np.zeros(n * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
tri = np.array([t.vertices[:] for t in me.loop_triangles], dtype=np.int32)
tpoly = np.array([t.polygon_index for t in me.loop_triangles], dtype=np.int32)
pa = np.zeros(len(me.polygons), dtype=np.int32); me.attributes["part"].data.foreach_get("value", pa)
parts = list(ob["parts"])
bones = [b.name for b in rig.data.bones]
W = np.zeros((n, len(bones)), np.float32)
vg = {g.index: g.name for g in ob.vertex_groups}
for v in me.vertices:
    for g in v.groups:
        nm = vg[g.group]
        if nm in bones:
            W[v.index, bones.index(nm)] = g.weight
bj = {b.name: [list(b.head_local), list(b.tail_local)] for b in rig.data.bones}
np.savez(os.path.join(WORK, "old.npz"), V=co, T=tri, part_of_tri=pa[tpoly], parts=np.array(parts), W=W, bones=np.array(bones))
json.dump(bj, open(os.path.join(WORK, "old_bones.json"), "w"))
print("dumped", n, len(tri), parts[:60])
