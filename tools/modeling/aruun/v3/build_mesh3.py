#!/usr/bin/env python3
"""Aruun v3 stage (bpy): decimate shells to budget, cut the old head off the trunk, add the dedicated head pieces (head.py),
v3 horns, cards, Morrow -> work/v3/raw_mesh.npz.   python3 build_mesh3.py"""
import os, sys
import numpy as np
import bpy, bmesh
HERE = os.path.dirname(os.path.abspath(__file__)); V2 = os.path.join(HERE, "..", "v2")
sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, V2)
from common import bpy_util as bu
W2 = os.path.join(HERE, "..", "work", "v2"); W3 = os.path.join(HERE, "..", "work", "v3")
TARGET = {"trunk": 2900, "armL": 700, "armR": 700, "legL": 1100, "legR": 1100}
CUT_Z = 1.874
bpy.ops.wm.read_factory_settings(use_empty=True)
hi = np.load(os.path.join(W2, "shells_hi.npz")); mf = np.load(os.path.join(W2, "mesh_fit.npz"), allow_pickle=True)
parts = list(mf["parts"]); pot = mf["part_of_tri"]; V = mf["V"]; T = mf["T"]
objs = []
def add(name, v, f, kind, sparam=None):
    me = bpy.data.meshes.new(name); me.from_pydata(np.asarray(v, float).tolist(), [], np.asarray(f).tolist()); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    objs.append(ob); ob["kind"] = kind
    if sparam is not None: ob["sparam"] = np.asarray(sparam, float).tolist()
    return ob
def decimate(ob, tgt, smooth=0):
    bu.set_active(ob)
    md = ob.modifiers.new("d", "DECIMATE"); md.ratio = min(1.0, tgt / max(1, len(ob.data.polygons)))
    bpy.ops.object.modifier_apply(modifier="d")
    if smooth:
        sm = ob.modifiers.new("s", "CORRECTIVE_SMOOTH"); sm.iterations = smooth; sm.factor = 0.5; sm.smooth_type = "SIMPLE"
        bpy.ops.object.modifier_apply(modifier="s")
for g, tgt in TARGET.items():
    v, f = hi["V_" + g], hi["F_" + g]
    if g == "trunk":
        keep = ~(v[f][:, :, 2] > CUT_Z).any(1); f = f[keep]
        used = np.unique(f); rm = -np.ones(len(v), int); rm[used] = np.arange(len(used)); v = v[used]; f = rm[f]
    ob = add(g, v, f, g)
    bu.set_active(ob); bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-5); bpy.ops.object.mode_set(mode="OBJECT")
    decimate(ob, tgt, 8); print(g, len(ob.data.polygons))
# Morrow (legacy)
for pi in [i for i, p in enumerate(parts) if p.startswith("morrow")]:
    t = T[pot == pi]
    if len(t) == 0: continue
    used = np.unique(t); remap = -np.ones(len(V), int); remap[used] = np.arange(len(used))
    ob = add("legacy_" + parts[pi], V[used], remap[t], "morrow")
    if len(t) > 120:
        decimate(ob, int(len(t) * 0.45))
# cards
cd = np.load(os.path.join(W2, "cards.npz"))
INV = {1: "mantle", 2: "fringe", 3: "leaf_olive", 4: "leaf_dark", 5: "tassel", 6: "cord"}
for code in sorted(set(cd["kind"].tolist())):
    if INV[code] in ("leaf_olive", "leaf_dark"): continue
    ft = cd["F"][cd["kind"] == code]; used = np.unique(ft); remap = -np.ones(len(cd["V"]), int); remap[used] = np.arange(len(used))
    ob = add("card_" + INV[code], cd["V"][used], remap[ft], "card", cd["s"][used])
    if INV[code] == "mantle":
        bu.set_active(ob); bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.subdivide(number_cuts=1); bpy.ops.object.mode_set(mode="OBJECT")
        co = np.array([v.co[:] for v in ob.data.vertices]); import math
        for i_, v in enumerate(ob.data.vertices):
            x, y, z = co[i_]; v.co = (x, y + 0.016 * math.sin(26 * x + 7 * z) + 0.010 * math.sin(41 * x - 9 * z), z)
        ob["sparam"] = np.interp(co[:, 2], [co[:, 2].min(), co[:, 2].max()], [1.0, 0.0]).tolist()
# horns
hd = np.load(os.path.join(W3, "horns3.npz"))
for t in (0, 1):
    idx = np.where(hd["tube"] == t)[0]; fm = (hd["tube"][hd["F"]] == t).all(1); ft = hd["F"][fm]
    remap = -np.ones(len(hd["V"]), int); remap[idx] = np.arange(len(idx))
    add("horn_" + "RL"[t], hd["V"][idx], remap[ft], "horn", hd["s"][idx])
# head
H = np.load(os.path.join(W3, "head_raw.npz"))
for nm, kind, tgt in (("s", "skull", 2300), ("j", "jaw", 650), ("e", "eye", 90), ("t", "tongue", 160)):
    ob = add("head_" + {"s": "skull", "j": "jaw", "e": "eye", "t": "tongue"}[nm], H["V" + nm], H["F" + nm], kind)
    bu.set_active(ob); bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.remove_doubles(threshold=1e-6); bpy.ops.object.mode_set(mode="OBJECT")
    if nm == "e":   # two eyes -> decimate each: split by loose parts
        bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.separate(type="LOOSE"); bpy.ops.object.mode_set(mode="OBJECT")
        for o in [o for o in bpy.data.objects if o.name.startswith("head_eye")]:
            if o not in objs: objs.append(o); o["kind"] = "eye"
            decimate(o, tgt)
    else:
        decimate(ob, tgt, 4 if nm in "sj" else 0)
add("head_tine", H["Vtn"], H["Ftn"], "tine"); add("head_tooth_up", H["Vu"], H["Fu"], "tooth_up"); add("head_tooth_lo", H["Vl"], H["Fl"], "tooth_lo")
ex = np.load(os.path.join(W3, "extras.npz"))
for i, nm in enumerate(ex["names"]):
    ft = ex["F"][ex["tri_piece"] == i]; used = np.unique(ft); remap = -np.ones(len(ex["V"]), int); remap[used] = np.arange(len(used))
    add(str(nm), ex["V"][used], remap[ft], str(ex["kinds"][i]), ex["sp"][used])
Vs, Fs, KS, SPs = [], [], [], []; off = 0
for ob in objs:
    me = ob.data
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=bm.faces[:]); bm.to_mesh(me); bm.free()
    n = len(me.vertices); co = np.zeros(n * 3, np.float32); me.vertices.foreach_get("co", co); me.calc_loop_triangles()
    tri = np.array([t.vertices[:] for t in me.loop_triangles], np.int32)
    Vs.append(co.reshape(-1, 3)); Fs.append(tri + off); off += n
    KS += [f"{ob.name}|{ob['kind']}"] * len(tri)
    SPs.append(np.array(ob["sparam"], np.float32) if "sparam" in ob.keys() and len(ob["sparam"]) == n else np.zeros(n, np.float32))
    print(ob.name, len(tri))
np.savez(os.path.join(W3, "raw_mesh.npz"), V=np.vstack(Vs), T=np.vstack(Fs), facekinds=np.array(KS), sparam=np.concatenate(SPs))
print("tris total", sum(len(f) for f in Fs))
