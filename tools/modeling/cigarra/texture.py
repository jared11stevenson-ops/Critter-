"""Cigarra body texture pipeline (round 2): UV unwrap of the body-material faces, region/pattern paint at 1024 px
(WebP), and a tangent-space normal bake from a higher-poly copy (Catmull-Clark x2 + relief displacement)."""
import os
import sys

import bmesh
import bpy
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from common.pnoise import noise3, worley  # noqa: E402
from common.raster import uv_raster, dilate  # noqa: E402

SIZE = 2048
BODY_SCALE = 0.72           # body UV islands occupy [0,0.72]^2; the face tile lives in the top-right corner
FACE_UV0, FACE_UV1 = 0.73, 0.99


def _sub_mesh(src):
    """Copy of src's mesh keeping only material-0 faces (face order preserved)."""
    me = src.data.copy()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != 0], context="FACES")
    bm.to_mesh(me)
    bm.free()
    return me


def unwrap_body(ob):
    """Smart-project + pack the material-0 faces on a temporary body-only copy, then write the UVs back (wings / face
    keep their own UVs and textures, and do not waste atlas space)."""
    sc = bpy.context.scene
    tmp = bpy.data.objects.new("cig_unwrap", _sub_mesh(ob))
    sc.collection.objects.link(tmp)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    tmp.select_set(True)
    bpy.context.view_layer.objects.active = tmp
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.2, island_margin=0.004, scale_to_bounds=False)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.uv.pack_islands(margin=0.004, rotate=True, scale=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    me, tm = ob.data, tmp.data
    tuv = np.zeros(len(tm.loops) * 2, np.float32)
    tm.uv_layers["UVMap"].data.foreach_get("uv", tuv)
    tuv = tuv.reshape(-1, 2)
    uv = np.zeros(len(me.loops) * 2, np.float32)
    me.uv_layers["UVMap"].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    k = 0
    for p in me.polygons:
        if p.material_index != 0:
            continue
        for l in p.loop_indices:
            uv[l] = tuv[k]
            k += 1
    assert k == len(tuv), (k, len(tuv))
    uv_b = uv.copy()
    for p in me.polygons:
        if p.material_index == 0:
            for l in p.loop_indices:
                uv[l] = uv_b[l] * BODY_SCALE
    me.uv_layers["UVMap"].data.foreach_set("uv", uv.ravel())
    sc.collection.objects.unlink(tmp)
    bpy.data.objects.remove(tmp)


def _hx(h):
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)], np.float32)


def paint_body(ob, names, COL, EMIT, work, face_albedo=None, face_emis=None):
    me = ob.data
    n_loops = len(me.loops)
    uv = np.zeros(n_loops * 2, np.float32)
    me.uv_layers["UVMap"].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    lv = np.zeros(n_loops, np.int32)
    me.loops.foreach_get("vertex_index", lv)
    co = np.zeros(len(me.vertices) * 3, np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    me.calc_loop_triangles()
    nt = len(me.loop_triangles)
    tl = np.zeros(nt * 3, np.int32)
    me.loop_triangles.foreach_get("loops", tl)
    tl = tl.reshape(-1, 3)
    tp = np.zeros(nt, np.int32)
    me.loop_triangles.foreach_get("polygon_index", tp)
    mat = np.zeros(len(me.polygons), np.int32)
    me.polygons.foreach_get("material_index", mat)
    pa = np.zeros(len(me.polygons), np.int32)
    me.attributes["part"].data.foreach_get("value", pa)
    sel = mat[tp] == 0
    tl_b = tl[sel]
    tp_b = tp[sel]
    tid, bary = uv_raster(uv, tl_b, SIZE)
    mask = tid >= 0
    t = tid[mask]
    b = bary[mask]
    P = (co[lv[tl_b[t, 0]]] * b[:, :1] + co[lv[tl_b[t, 1]]] * b[:, 1:2] + co[lv[tl_b[t, 2]]] * b[:, 2:3]).astype(np.float64)
    part = np.array(names)[pa[tp_b[t]]]
    N = len(P)
    n1, n2, n3 = noise3(P, 3.0, 5), noise3(P, 7.0, 9), noise3(P, 16.0, 13)
    A1, A2, Ah = worley(P, 0.06, 4)
    seam = np.clip(1 - (A2 - A1) / 0.1, 0, 1)
    B1, _, Bh = worley(P, 0.012, 8)
    col = np.zeros((N, 3), np.float32)
    for k, c in COL.items():
        col[part == k] = np.array(c, np.float32)
    h = np.zeros(N, np.float32)
    rough = np.full(N, 0.72, np.float32)
    metal = np.zeros(N, np.float32)
    emis = np.zeros((N, 3), np.float32)
    isin = lambda *ks: np.isin(part, ks)  # noqa: E731
    weave = (0.5 + 0.5 * np.sin(P[:, 2] * 520)) * (0.5 + 0.5 * np.sin(P[:, 0] * 520 + P[:, 1] * 300))
    # cloth: jackets / pants / sleeves
    m = isin("violet", "violet_d", "violet_l", "trim")
    fold = np.clip(0.5 + 0.5 * n1, 0, 1)
    shade = (0.82 + 0.28 * fold - 0.18 * seam + 0.05 * weave)[:, None]
    col[m] = (col * shade)[m]
    # lime paint drips low on the jacket / hood (sheet: moss + dye running down the fabric)
    drip = (n2 > 0.55) & m
    col[drip] = col[drip] * 0.55 + _hx("#9fb324") * 0.45
    h[m] = (0.25 * weave - 0.5 * seam + 0.15 * n2)[m]
    rough[m] = 0.88
    # skin: warm, faint blush, freckles
    m = isin("skin")
    col[m] = (col * (0.94 + 0.1 * n1[:, None]))[m]
    fr = (B1 < 0.08) & (Bh > 0.7) & m
    col[fr] *= 0.78
    rough[m] = 0.6
    # hair: strand streaks, ochre roots, pale tips
    m = isin("hair")
    st = (0.5 + 0.5 * np.sin((P[:, 0] * 160 + P[:, 1] * 120) + 4 * n2))[:, None]
    col[m] = (col * (0.86 + 0.16 * st) + _hx("#d9c27a") * 0.12 * np.clip(n1, 0, 1)[:, None])[m]
    h[m] = (0.3 * st[:, 0])[m]
    rough[m] = 0.55
    # cream: crop top + bandages (diagonal wraps + dirt)
    m = isin("crop", "cream", "gourd")
    wrap = (0.5 + 0.5 * np.sin(P[:, 2] * 240 + P[:, 0] * 80))[:, None]
    col[m] = (col * (0.82 + 0.2 * wrap) * (1 - 0.14 * np.clip(n2, 0, 1)[:, None]))[m]
    h[m] = (0.35 * wrap[:, 0] - 0.4 * seam)[m]
    rough[m] = 0.85
    g = isin("gourd")
    col[g] = (col * (1 - 0.25 * np.clip(-(P[:, 2] - 0.78) * 4, 0, 1)[:, None]))[g]
    # leather + boots: stitching + creases
    m = isin("leather", "boot")
    col[m] = (col * (0.85 + 0.22 * np.clip(0.5 + 0.5 * n2, 0, 1))[:, None] * (1 - 0.3 * seam)[:, None])[m]
    h[m] = (-0.4 * seam + 0.2 * n3)[m]
    rough[m] = 0.55
    # moss / lime trims: vein stripes
    m = isin("moss", "lime")
    vein = (0.5 + 0.5 * np.sin(P[:, 0] * 380 + P[:, 2] * 150 + 3 * n2))[:, None]
    col[m] = (col * (0.78 + 0.3 * vein))[m]
    h[m] = (0.3 * vein[:, 0])[m]
    emis[isin("lime")] = _hx("#b8d820") * 0.12
    # crown: glossy black, gold crescents + violet glints glow
    m = isin("black")
    col[m] = (col * (0.8 + 0.4 * np.clip(0.5 + 0.5 * n1, 0, 1))[:, None] + _hx("#2a1f40") * 0.25)[m]
    rough[m] = 0.2
    gm = isin("gold")
    metal[gm] = 0.8
    rough[gm] = 0.3
    emis[gm] = np.array(COL["gold"], np.float32) * EMIT["gold"]
    emis[isin("glow")] = np.array(COL["glow"], np.float32) * EMIT["glow"]
    col = np.clip(col, 0, 1)
    out = {}
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    himg = np.zeros((SIZE, SIZE), np.float32)
    orm = np.zeros((SIZE, SIZE, 3), np.float32)
    em_i = np.zeros((SIZE, SIZE, 3), np.float32)
    img[mask] = col
    himg[mask] = h
    orm[mask] = np.stack([np.ones(N), rough, metal], 1)
    em_i[mask] = emis
    img, _ = dilate(img, mask, 8)
    himg, _ = dilate(himg, mask, 8)
    orm, _ = dilate(orm, mask, 8)
    em_i, _ = dilate(em_i, mask, 8)
    if face_albedo is not None:                      # face tile -> top-right corner of the atlas (v up = image y down)
        x0 = int(FACE_UV0 * SIZE)
        w = int((FACE_UV1 - FACE_UV0) * SIZE)
        y0 = int((1 - FACE_UV1) * SIZE)
        for arr, tile in ((img, face_albedo), (em_i, face_emis)):
            t = np.asarray(tile.convert("RGB").resize((w, w), Image.LANCZOS)).astype(np.float32) / 255
            arr[y0:y0 + w, x0:x0 + w] = t
        orm[y0:y0 + w, x0:x0 + w] = np.array([1.0, 0.6, 0.0], np.float32)
        himg[y0:y0 + w, x0:x0 + w] = 0.0
    gy, gx = np.gradient(himg)
    nrm = np.stack([-gx * 5.0, gy * 5.0, np.ones_like(himg)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    for nm, arr in (("albedo", img), ("normal", nrm * 0.5 + 0.5), ("orm", orm), ("emissive", em_i)):
        p = os.path.join(work, "cigarra_body_%s.png" % nm)
        Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(p)
        out[nm] = p
    return out


def bake_normal(ob, work):
    """Bake body-material faces: low copy (mat 0 only) <- hi copy (subsurf x2 + relief displace). Returns png path or None."""
    sc = bpy.context.scene

    lo = bpy.data.objects.new("cig_lo", _sub_mesh(ob))
    hi = bpy.data.objects.new("cig_hi", _sub_mesh(ob))
    sc.collection.objects.link(lo)
    sc.collection.objects.link(hi)
    sub = hi.modifiers.new("sub", "SUBSURF")
    sub.levels = sub.render_levels = 2
    tex = bpy.data.textures.new("cig_disp", "VORONOI")
    tex.noise_scale = 0.05
    d = hi.modifiers.new("disp", "DISPLACE")
    d.texture = tex
    d.strength = 0.007
    d.mid_level = 0.35
    img = bpy.data.images.new("cig_bake_n", SIZE, SIZE)
    img.colorspace_settings.name = "Non-Color"
    m = bpy.data.materials.new("cig_bake")
    m.use_nodes = True
    n = m.node_tree.nodes.new("ShaderNodeTexImage")
    n.image = img
    m.node_tree.nodes.active = n
    lo.data.materials.clear()
    lo.data.materials.append(m)
    hi.data.materials.clear()
    hi.data.materials.append(m)
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 1
    sc.cycles.device = "CPU"
    sc.render.bake.margin = 8
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = 0.02
    sc.render.bake.max_ray_distance = 0.05
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    hi.select_set(True)
    lo.select_set(True)
    bpy.context.view_layer.objects.active = lo
    path = None
    try:
        bpy.ops.object.bake(type="NORMAL")
        path = os.path.join(work, "cigarra_bake_normal.png")
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
    except Exception as e:  # noqa: BLE001
        print("BAKE FAILED", e)
    for o in (lo, hi):
        o.select_set(False)
        sc.collection.objects.unlink(o)
        bpy.data.objects.remove(o)
    bpy.context.view_layer.update()
    return path


def merge_normals(paint_path, bake_path, out_path):
    a = np.asarray(Image.open(paint_path).convert("RGB")).astype(np.float32) / 255 * 2 - 1
    b = np.asarray(Image.open(bake_path).convert("RGB")).astype(np.float32) / 255 * 2 - 1
    bxy = np.clip(b[..., :2] * 0.6, -0.45, 0.45)
    n = np.stack([a[..., 0] + bxy[..., 0], a[..., 1] + bxy[..., 1], np.maximum(a[..., 2] * b[..., 2], 0.4)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save(out_path)


def merge_face_into_body(ob):
    """Face polygons (material 2): remap planar UVs into the atlas face tile and move them to the body material."""
    me = ob.data
    uv = np.zeros(len(me.loops) * 2, np.float32)
    me.uv_layers["UVMap"].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    for p in me.polygons:
        if p.material_index == 2:
            for l in p.loop_indices:
                uv[l] = FACE_UV0 + np.clip(uv[l], 0, 1) * (FACE_UV1 - FACE_UV0)
            p.material_index = 0
    me.uv_layers["UVMap"].data.foreach_set("uv", uv.ravel())
    me.materials.pop(index=2)
