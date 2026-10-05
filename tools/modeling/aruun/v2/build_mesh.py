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
sel_names = [i for i, p in enumerate(parts) if p.startswith(CARD_PARTS) or p.startswith("morrow")]
for pi in sel_names:
    t = T[pot == pi]
    if len(t) == 0: continue
    used = np.unique(t); remap = -np.ones(len(V), int); remap[used] = np.arange(len(used))
    ob = add("legacy_" + parts[pi], V[used], remap[t], "morrow" if parts[pi].startswith("morrow") else "card")
for ob in objs:
    bu.set_active(ob)
    for p in ob.data.polygons: p.use_smooth = True
bpy.ops.object.select_all(action="DESELECT")
for ob in objs: ob.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
kind_of_obj = [(ob.name, ob["kind"], len(ob.data.polygons)) for ob in objs]
bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active; ob.name = "Aruun"
# per-face kind
me = ob.data
cnt = []; 
for n, k, c in kind_of_obj: cnt += [(n, k)] * c
print("faces", len(me.polygons), "tris", sum(len(p.vertices) - 2 for p in me.polygons))
ob["facekinds"] = [f"{n}|{k}" for n, k in cnt]
bu.set_active(ob)
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.quads_convert_to_tris()
bpy.ops.object.mode_set(mode="OBJECT")
me.calc_loop_triangles(); n = len(me.vertices)
co = np.zeros(n * 3, np.float32); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
tri = np.array([t.vertices[:] for t in me.loop_triangles], np.int32)
kinds = np.array(ob["facekinds"])
np.savez(os.path.join(WORK, "raw_mesh.npz"), V=co, T=tri, facekinds=kinds)
print("tris total", len(tri))
