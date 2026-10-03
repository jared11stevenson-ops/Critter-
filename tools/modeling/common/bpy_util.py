"""Blender (bpy as a module) helpers shared by the character build scripts."""
import math
import bmesh
import bpy
import numpy as np
from mathutils import Vector


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "METRIC"
    return sc


def to_object(mb, name, materials, recalc_skip_prefixes=("cloth_", "fringe_", "strip_", "leaf_", "band_", "cloak_")):
    """MeshBuilder -> bpy object with UV map 'UVMap', material slots, int face attribute 'part'."""
    me = bpy.data.meshes.new(name)
    verts = [tuple(v) for v in mb.verts]
    faces = [f[0] for f in mb.faces]
    me.from_pydata(verts, [], faces)
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    loops_uv = []
    for f in mb.faces:
        loops_uv.extend(f[1])
    uv.data.foreach_set("uv", np.array(loops_uv, dtype=np.float32).ravel())
    me.polygons.foreach_set("material_index", np.array([f[2] for f in mb.faces], dtype=np.int32))
    attr = me.attributes.new("part", "INT", "FACE")
    attr.data.foreach_set("value", np.array([f[3] for f in mb.faces], dtype=np.int32))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for m in materials:
        ob.data.materials.append(m)
    # consistent outward normals on closed parts (ribbons keep authored winding)
    bm = bmesh.new()
    bm.from_mesh(me)
    pl = bm.faces.layers.int.get("part")
    skip = {i for i, p in enumerate(mb.parts) if p.startswith(recalc_skip_prefixes)}
    fs = [f for f in bm.faces if f[pl] not in skip]
    bmesh.ops.recalc_face_normals(bm, faces=fs)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    ob["parts"] = list(mb.parts)
    return ob


def set_active(ob):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


def pack_uvs(ob, density=None, margin=0.004, parts=None):
    """Average island scale (texel density), apply per-part density multipliers, pack into 0..1."""
    set_active(ob)
    me = ob.data
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.average_islands_scale()
    bpy.ops.object.mode_set(mode="OBJECT")
    if density:
        names = ob["parts"]
        pa = np.zeros(len(me.polygons), dtype=np.int32)
        me.attributes["part"].data.foreach_get("value", pa)
        uvd = np.zeros(len(me.loops) * 2, dtype=np.float32)
        me.uv_layers["UVMap"].data.foreach_get("uv", uvd)
        uvd = uvd.reshape(-1, 2)
        ls = np.zeros(len(me.polygons), dtype=np.int32)
        lt = np.zeros(len(me.polygons), dtype=np.int32)
        me.polygons.foreach_get("loop_start", ls)
        me.polygons.foreach_get("loop_total", lt)
        for fi in range(len(me.polygons)):
            nm = names[pa[fi]]
            s = 1.0
            for key, mul in density.items():
                if nm.startswith(key):
                    s = mul
            if s != 1.0:
                sl = slice(ls[fi], ls[fi] + lt[fi])
                # scale about the face's own first uv is wrong for islands; scale about origin works
                # because pack_islands re-translates islands (it keeps relative scale when scale=True)
                uvd[sl] *= s
        me.uv_layers["UVMap"].data.foreach_set("uv", uvd.ravel())
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(margin=margin, rotate=True, scale=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def principled(name, color=(0.5, 0.5, 0.5, 1), rough=0.6, metal=0.0, emission=None, image=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emission:
        b.inputs["Emission Color"].default_value = emission
        b.inputs["Emission Strength"].default_value = 1.0
    return m
