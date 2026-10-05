"""Bake CC0 Poly Haven scans into mobile kit pieces (game/art/world/kit/<name>.glb).

  python3 tools/modeling/world/import_scans.py [names...]

Pipeline per scan: import glTF -> join -> decimate (collapse) to a triangle budget -> scale/orient to the piece spec ->
sample the diffuse map into vertex colours (tinted toward the Reaches palette so scans sit with the procedural kit) ->
bake vertex AO -> export a plain "kit" GLB (vertex colour, blank-atlas UVs). No textures ship with the piece: the scan's
detail is baked into ~600-1500 vertices, which is what the toon kit shader expects. Source scans live in
$SCAN_DIR (default /tmp/scans, fetched by tools/assets/polyhaven.py); only the baked GLBs are committed.
"""
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from kitlib import mix, mul, DUST, cell_uv

OUT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "game", "art", "world", "kit"))
SCANS = os.environ.get("SCAN_DIR", "/tmp/scans")

# name: (scan id, target tris, height m (None: keep), tint colour, tint amount, dust on top, flatten_bottom)
SPEC = {
    "scan_rock_a": ("namaqualand_boulder_02", 700, 1.5, (0.62, 0.38, 0.28), 0.35, 0.25, True),
    "scan_rock_b": ("namaqualand_boulder_05", 700, 1.2, (0.66, 0.42, 0.30), 0.35, 0.25, True),
}


def srgb_img(path):
    im = bpy.data.images.load(path)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, im.channels)
    return px, w, h


def build(name):
    sid, tris, height, tint, tamt, dust, flat = SPEC[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    gl = os.path.join(SCANS, sid, sid + ".gltf")
    bpy.ops.import_scene.gltf(filepath=gl)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    # bake world transforms, then join
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(objs) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    n0 = len(ob.data.polygons)
    # keep first-material diffuse for sampling (sample per material slot)
    mats = []
    for slot in ob.material_slots:
        m = slot.material
        img = None
        if m and m.use_nodes:
            for nd in m.node_tree.nodes:
                if nd.type == "TEX_IMAGE" and nd.image and "diff" in nd.image.name.lower():
                    img = nd.image
        mats.append(img)
    # per-loop colour sampling BEFORE decimation is lossy on UV seams; decimate first (collapse keeps UVs), then sample
    me = ob.data
    ratio = min(1.0, tris / max(1, n0 * 1.0))
    bpy.ops.object.mode_set(mode="OBJECT")
    mod = ob.modifiers.new("dec", "DECIMATE")
    mod.ratio = ratio
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="dec")
    me = ob.data
    # centre on XY, rest on z=0, scale to height
    vs = np.array([v.co[:] for v in me.vertices])
    mn, mx = vs.min(0), vs.max(0)
    sc = (height / (mx[2] - mn[2])) if height else 1.0
    cx, cy = (mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2
    for v in me.vertices:
        v.co = Vector(((v.co.x - cx) * sc, (v.co.y - cy) * sc, (v.co.z - mn[2]) * sc))
    if flat:
        for v in me.vertices:
            if v.co.z < 0.08 * height:
                v.co.z = max(0.0, v.co.z * 0.3) - 0.04 * height
    me.update()
    # sample diffuse to vertex colours
    lay = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    uvl = me.uv_layers.active
    cache = {}
    def tex(i):
        if i not in cache:
            img = mats[i] if i < len(mats) else None
            cache[i] = srgb_img(img.filepath_from_user() if img.packed_file is None else img.filepath) if img else None
        return cache[i]
    for poly in me.polygons:
        t = tex(poly.material_index)
        for li in poly.loop_indices:
            u, v = uvl.data[li].uv
            if t is None:
                col = (0.5, 0.5, 0.45)
            else:
                px, w, h = t
                x = int((u % 1.0) * (w - 1)); y = int((v % 1.0) * (h - 1))
                col = tuple(float(c) for c in px[y, x, :3])
            lay.data[li].color = (*col, 1.0)
    # AO + tint + dust
    bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())
    rng = np.random.default_rng(7)
    dirs = []
    for i in range(14):
        u, v = rng.random(), rng.random()
        r = math.sqrt(u); th = math.tau * v
        dirs.append((r * math.cos(th), r * math.sin(th), math.sqrt(max(0.0, 1 - u))))
    me.calc_loop_triangles()
    for v in me.vertices:
        n = v.normal
        t = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))).normalized()
        b = n.cross(t)
        o = v.co + n * 0.02
        hit = sum(1 for d in dirs if bvh.ray_cast(o, t * d[0] + b * d[1] + n * d[2], 0.6 * (height or 2) / 1.5)[0] is not None)
        k = 1.0 - 0.45 * hit / len(dirs)
        k *= 0.82 + 0.18 * min(1.0, max(0.0, v.co.z / (height or 1.0)))
        up = max(0.0, n.z - 0.6) / 0.4
        for poly in me.polygons:
            pass
        v_ao = (k, up)
        v["ao"] = k; v["up"] = up
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            c = lay.data[li].color
            col = (c[0], c[1], c[2])
            if tint:
                luma = (col[0] * 0.3 + col[1] * 0.55 + col[2] * 0.15)
                col = mix(col, mul(tint, 0.55 + luma * 0.9), tamt)
            k = me.vertices[vi]["ao"]; up = me.vertices[vi]["up"]
            col = mul(col, k)
            if dust > 0:
                col = mix(col, mul(DUST, k), dust * up)
            lay.data[li].color = (*col, 1.0)
    # blank atlas UVs + kit material
    blank = cell_uv("blank", 0.5, 0.5)
    for li in range(len(uvl.data)):
        uvl.data[li].uv = blank
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = 0
    ob.data.materials.clear()
    ob.data.materials.append(bpy.data.materials.new("kit"))
    for p in me.polygons:
        p.use_smooth = True
    ob.name = name
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=f"{OUT}/{name}.glb", export_format="GLB", use_selection=True, export_vertex_color="ACTIVE",
                              export_materials="EXPORT", export_apply=True, export_yup=True, export_texcoords=True,
                              export_normals=True, export_animations=False, export_cameras=False, export_lights=False)
    return len(me.polygons)


if __name__ == "__main__":
    names = sys.argv[1:] or list(SPEC)
    for n in names:
        print("%-14s %5d tris" % (n, build(n)))
