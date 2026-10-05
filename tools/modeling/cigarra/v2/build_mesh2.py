#!/usr/bin/env python3
"""Cigarra v2 (bpy): decimate the SDF shells to budget and assemble head + body + hands + pieces -> work/v2/raw_mesh.npz"""
import os, sys
import numpy as np
import bpy, bmesh
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import bpy_util as bu
W2 = os.path.join(HERE, "..", "work", "v2")
TARGET = {"skull": 3000, "body": 4700, "hand_L": 420, "hand_R": 420, "eye": 100}
bpy.ops.wm.read_factory_settings(use_empty=True)
objs = []
def add(name, v, f, kind, sp=None, uv2=None):
    me = bpy.data.meshes.new(name); me.from_pydata(np.asarray(v, float).tolist(), [], np.asarray(f).tolist()); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob); ob["kind"] = kind; objs.append(ob)
    if sp is not None: ob["sparam"] = np.asarray(sp, float).tolist()
    if uv2 is not None: ob["uv2"] = np.asarray(uv2, float).ravel().tolist()
    return ob
def clean(ob):
    bu.set_active(ob); bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-6); bpy.ops.object.mode_set(mode="OBJECT")
def decimate(ob, tgt, smooth=0):
    bu.set_active(ob); md = ob.modifiers.new("d", "DECIMATE"); md.ratio = min(1.0, tgt / max(1, len(ob.data.polygons)))
    bpy.ops.object.modifier_apply(modifier="d")
    if smooth:
        sm = ob.modifiers.new("s", "CORRECTIVE_SMOOTH"); sm.iterations = smooth; sm.factor = 0.5; sm.smooth_type = "SIMPLE"; bpy.ops.object.modifier_apply(modifier="s")
H = np.load(os.path.join(W2, "head_raw.npz")); B = np.load(os.path.join(W2, "body_raw.npz")); P = np.load(os.path.join(W2, "pieces.npz"))
ob = add("skull", H["Vs"], H["Fs"], "skull"); clean(ob); decimate(ob, TARGET["skull"], 4)
ob = add("eyes", H["Ve"], H["Fe"], "eye"); clean(ob)
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.separate(type="LOOSE"); bpy.ops.object.mode_set(mode="OBJECT")
for o in [o for o in bpy.data.objects if o.name.startswith("eyes")]:
    if o not in objs: objs.append(o)
    o["kind"] = "eye"; decimate(o, TARGET["eye"])
ob = add("body", B["Vb"], B["Fb"], "body"); clean(ob); decimate(ob, TARGET["body"], 6)
for nm in ("L", "R"):
    ob = add("hand_" + nm, B["Vh_" + nm], B["Fh_" + nm], "hand"); clean(ob); decimate(ob, TARGET["hand_" + nm], 3)
names = list(P["names"]); tp = P["tri_piece"]
for i, nm in enumerate(names):
    ft = P["F"][tp == i]; used = np.unique(ft); remap = -np.ones(len(P["V"]), int); remap[used] = np.arange(len(used))
    kind = "wing" if nm.startswith("wing_") else "card"
    add(nm, P["V"][used], remap[ft], kind, P["sp"][used], P["uv"][used])
Vs, Fs, KS, SPs, UVs = [], [], [], [], []; off = 0
for ob in objs:
    me = ob.data; bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=bm.faces[:]); bm.to_mesh(me); bm.free()
    n = len(me.vertices); co = np.zeros(n * 3, np.float32); me.vertices.foreach_get("co", co); me.calc_loop_triangles()
    tri = np.array([t.vertices[:] for t in me.loop_triangles], np.int32)
    Vs.append(co.reshape(-1, 3)); Fs.append(tri + off); off += n
    KS += [f"{ob.name}|{ob['kind']}"] * len(tri)
    SPs.append(np.array(ob["sparam"], np.float32) if "sparam" in ob.keys() and len(ob["sparam"]) == n else np.zeros(n, np.float32))
    UVs.append(np.array(ob["uv2"], np.float32).reshape(-1, 2) if "uv2" in ob.keys() and len(ob["uv2"]) == 2 * n else np.zeros((n, 2), np.float32))
np.savez(os.path.join(W2, "raw_mesh.npz"), V=np.vstack(Vs), T=np.vstack(Fs), facekinds=np.array(KS), sparam=np.concatenate(SPs), uv2=np.vstack(UVs))
from collections import Counter
c = Counter(k.split("|")[1] for k in KS); print(dict(c), "total", sum(c.values()))
