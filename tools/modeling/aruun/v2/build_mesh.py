#!/usr/bin/env python3
"""Aruun v2 stage 4 (bpy): decimate the hi shells to game budget, add legacy cards/Morrow from the fitted mesh,
unwrap, write work/v2/game_mesh.npz (+ .blend).   python3 build_mesh.py"""
import os, sys, json
import numpy as np
import bpy, bmesh
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import bpy_util as bu
WORK = os.path.join(HERE, "..", "work", "v2")
TARGET = {"trunk": 5200, "armL": 1300, "armR": 1300, "legL": 1700, "legR": 1700}
CARD_PARTS = ("cloak_hood", "cloak_back", "cloak_tail", "leaf_dark", "leaf_olive", "strip_cord", "strip_cream",
              "strip_olive", "band_cream", "talisman", "beads", "cloth_sash", "pommel")
bpy.ops.wm.read_factory_settings(use_empty=True)
hi = np.load(os.path.join(WORK, "shells_hi.npz"))
mf = np.load(os.path.join(WORK, "mesh_fit.npz"), allow_pickle=True)
parts = list(mf["parts"]); pot = mf["part_of_tri"]; V = mf["V"]; T = mf["T"]
objs = []; kinds = []
def add(name, v, f, kind):
    me = bpy.data.meshes.new(name); me.from_pydata(v.tolist(), [], f.tolist()); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    objs.append(ob); ob["kind"] = kind; return ob
for g, tgt in TARGET.items():
    ob = add(g, hi["V_" + g], hi["F_" + g], g)
    bu.set_active(ob)
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-5); bpy.ops.object.mode_set(mode="OBJECT")
    md = ob.modifiers.new("d", "DECIMATE"); md.ratio = min(1.0, tgt / max(1, len(ob.data.polygons)))
    bpy.ops.object.modifier_apply(modifier="d")
    sm = ob.modifiers.new("s", "CORRECTIVE_SMOOTH"); sm.iterations = 8; sm.factor = 0.5; sm.smooth_type = "SIMPLE"
    bpy.ops.object.modifier_apply(modifier="s")
    print(g, len(ob.data.polygons), "tris")
# legacy parts as separate pieces: cards + morrow
sel_names = [i for i, p in enumerate(parts) if p.startswith("morrow")]
for pi in sel_names:
    t = T[pot == pi]
    if len(t) == 0: continue
    used = np.unique(t); remap = -np.ones(len(V), int); remap[used] = np.arange(len(used))
    ob = add("legacy_" + parts[pi], V[used], remap[t], "morrow" if parts[pi].startswith("morrow") else "card")
cd = np.load(os.path.join(WORK, "cards.npz")); hd = np.load(os.path.join(WORK, "horns.npz"))
INV = {1: "mantle", 2: "fringe", 3: "leaf_olive", 4: "leaf_dark", 5: "tassel", 6: "cord"}
extra_s = []
for code in sorted(set(cd["kind"].tolist())):
    ft = cd["F"][cd["kind"] == code]
    used = np.unique(ft); remap = -np.ones(len(cd["V"]), int); remap[used] = np.arange(len(used))
    ob = add("card_" + INV[code], cd["V"][used], remap[ft], "card"); ob["sparam"] = cd["s"][used].tolist()
hp = np.load(os.path.join(WORK, "headparts.npz"))
names = sorted(set(hp["name"].tolist()))
for nm in names:
    fm = hp["name"] == nm; ft = hp["F"][fm]; used = np.unique(ft); remap = -np.ones(len(hp["V"]), int); remap[used] = np.arange(len(used))
    ob = add("hp_" + nm, hp["V"][used], remap[ft], "headpart"); ob["sparam"] = hp["s"][used].tolist()
for t in (0, 1):
    vsel = hd["tube"] == t
    idx = np.where(vsel)[0]
    # faces of this tube (cap verts carry tube id too)
    fm = vsel[hd["F"]].all(1)
    ft = hd["F"][fm]; remap = -np.ones(len(hd["V"]), int); remap[idx] = np.arange(len(idx))
    ob = add("horn_" + "RL"[t], hd["V"][idx], remap[ft], "horn"); ob["sparam"] = hd["s"][idx].tolist()
Vs, Fs, KS, SPs = [], [], [], []
off = 0
for ob in objs:
    me = ob.data
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=bm.faces[:]); bm.to_mesh(me); bm.free()
    n = len(me.vertices)
    co = np.zeros(n * 3, np.float32); me.vertices.foreach_get("co", co)
    me.calc_loop_triangles()
    tri = np.array([t.vertices[:] for t in me.loop_triangles], np.int32)
    Vs.append(co.reshape(-1, 3)); Fs.append(tri + off); off += n
    KS += [f"{ob.name}|{ob['kind']}"] * len(tri)
    SPs.append(np.array(ob["sparam"], np.float32) if "sparam" in ob.keys() else np.zeros(n, np.float32))
    print(ob.name, len(tri))
np.savez(os.path.join(WORK, "raw_mesh.npz"), V=np.vstack(Vs), T=np.vstack(Fs), facekinds=np.array(KS), sparam=np.concatenate(SPs))
print("tris total", sum(len(f) for f in Fs))
