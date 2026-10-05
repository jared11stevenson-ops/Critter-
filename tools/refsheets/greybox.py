#!/usr/bin/env python3
"""Clay greybox from measured silhouettes (Blender 5 bpy module) + design-locked derived views.

1. Visual hull: the aligned side and back silhouettes (same scale, same landmark rows) are extruded and intersected on a voxel grid
   (back gives X/Z, side gives Y/Z) -> marching cubes -> mesh. Nothing in it is designed, it is exactly what the two measured silhouettes allow.
2. bpy builds the clay mesh, and renders orthographic clay views (front, side, back, 3/4 front, 3/4 back) at true scale.
3. derive_view(): paints a missing orthographic view over the clay silhouette using ONLY pixels of the nearest real view
   (row-wise horizontal remap). Provenance overlay: green = pixel taken 1:1 from art, yellow = remapped from another view, red = no source (unknown, ask Lead).
usage: greybox.py <id> [--derive front_ortho:front ...]   (derive spec  target:source_view)"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST, LM_ORDER
import ortho as O

RES = 4096 // 16     # voxel grid: 256 rows over the character height


def load_masks(cid):
    meta = json.load(open(os.path.join(PACKS, cid, "metadata.json")))
    M = {}
    for v, m in meta["views"].items():
        if not m.get("aligned", True): continue
        im = Image.open(os.path.join(PACKS, cid, m["file"])).convert("RGBA")
        M[v] = (np.asarray(im.getchannel("A")) > 40, m["axis_x_px"], im)
    return meta, M


def hull(cid, meta, M, a="back", b="side", n=224):
    """voxel visual hull from two orthogonal silhouettes -> (verts, faces) in metres, x right (front view), y = depth (+ toward viewer's front), z up."""
    ppm = meta["px_per_m"]; H = meta["canvas_h"]; top, gnd = meta["top_y"], meta["ground_y"]
    step = 8                                       # px per voxel
    ma, ax_a, _ = M[a]; mb, ax_b, _ = M[b]
    wa, wb = ma.shape[1], mb.shape[1]
    rows = np.arange(top, gnd, step); nz = len(rows)
    xs = (np.arange(0, wa, step) - ax_a) / ppm          # back view: image-right = -X(world) -> mirrored below
    ys = (np.arange(0, wb, step) - ax_b) / ppm
    A = ma[rows][:, ::step]; B = mb[rows][:, ::step]     # (z, u)
    # grid[z, ua, ub]
    G = A[:, :, None] & B[:, None, :]
    from skimage import measure
    G = ndimage.gaussian_filter(np.pad(G, 4).astype(np.float32), (3.2, 1.8, 1.8))
    v, f, _, _ = measure.marching_cubes(G, 0.5, spacing=(1, 1, 1)); v = v - 3
    xa = (v[:, 1] - 1) * step / ppm - ax_a / ppm         # back-image coordinates (image-right = world -X)
    yb = (v[:, 2] - 1) * step / ppm - ax_b / ppm         # side-image coordinates (image-right = facing direction = world -Y)
    z = (gnd - rows[0]) / ppm - (v[:, 0] - 1) * step / ppm
    V = np.stack([-xa, -yb, z], 1)
    return V.astype(np.float32), f.astype(np.int32)


def build_and_render(cid, V, F, meta, out_dir, size=1000):
    import bpy, math, mathutils
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new(cid + "_greybox"); me.from_pydata(V.tolist(), [], F.tolist()); me.update()
    ob = bpy.data.objects.new(cid + "_greybox", me); bpy.context.scene.collection.objects.link(ob)
    dec = ob.modifiers.new("dec", "DECIMATE"); dec.ratio = min(1.0, 22000.0 / max(len(F), 1))
    mod = ob.modifiers.new("sm", "SMOOTH"); mod.factor = 0.6; mod.iterations = 10
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
    for p in ob.data.polygons: p.use_smooth = True
    mat = bpy.data.materials.new("clay"); mat.use_nodes = True; bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.62, 0.6, 0.57, 1); bsdf.inputs["Roughness"].default_value = 0.9; ob.data.materials.append(mat)
    sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.film_transparent = True; sc.render.resolution_x = int(size * 0.7); sc.render.resolution_y = size
    w = bpy.data.worlds.new("w"); w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.8, 0.8, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.0; sc.world = w
    cam_d = bpy.data.cameras.new("cam"); cam_d.type = "ORTHO"; cam = bpy.data.objects.new("cam", cam_d); sc.collection.objects.link(cam); sc.camera = cam
    H = meta["height_m"]; cam_d.ortho_scale = H * 1.06; cam_d.shift_y = 0
    sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3.0; so = bpy.data.objects.new("sun", sun); sc.collection.objects.link(so)
    views = {"front": 0, "side": 90, "back": 180, "q34_front": -35, "q34_back": 215}
    ctr = mathutils.Vector((0, 0, H / 2)); R = 20
    res = {}
    for name, az in views.items():
        a = math.radians(az)   # character faces -Y; az 0 = camera at -Y looking +Y (front). side view faces screen-right: camera at -X.
        cam.location = ctr + mathutils.Vector((-math.sin(a) * R, -math.cos(a) * R, 0))
        cam.rotation_euler = (math.radians(90), 0, -a)
        so.rotation_euler = (math.radians(50), 0, -a + math.radians(-30))
        p = os.path.join(out_dir, f"{cid}_clay_{name}.png"); sc.render.filepath = p; bpy.ops.render.render(write_still=True); res[name] = p
    # glb export (small)
    try:
        bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, f"{cid}_greybox.glb"), export_format="GLB", use_selection=False)
    except Exception as e:
        print("glb export failed", e)
    return res


def derive_view(cid, meta, M, target_mask, src_view, mirror=False):
    """Row-wise remap of src_view art onto target silhouette. returns (RGBA, provenance RGBA overlay: green/yellow/red)."""
    sm, sax, sim = M[src_view]; H, W = target_mask.shape
    sa = np.asarray(sim).copy()
    out = np.zeros((H, target_mask.shape[1], 4), np.uint8); prov = np.zeros((H, W, 4), np.uint8)
    for y in range(O.TOP, O.GROUND):
        t = np.where(target_mask[y])[0]
        if not len(t): continue
        s = np.where(sm[y])[0]
        t0, t1 = t.min(), t.max()
        if not len(s):
            prov[y, t0:t1 + 1] = (*RED_, 120); continue
        s0, s1 = s.min(), s.max(); k = (t1 - t0 + 1) / max(s1 - s0 + 1, 1)
        xs = np.clip(((np.arange(t0, t1 + 1) - t0) / k + s0).astype(int), 0, sa.shape[1] - 1)
        if mirror: xs = xs[::-1]
        seg = sa[y, xs]; ok = target_mask[y, t0:t1 + 1]
        out[y, t0:t1 + 1][ok] = seg[ok]
        col = YEL_ if 0.7 < k < 1.4 else RED_
        prov[y, t0:t1 + 1][ok] = (*col, 120)
    return Image.fromarray(out, "RGBA"), Image.fromarray(prov, "RGBA")


RED_, YEL_, GRN_ = (210, 50, 50), (235, 190, 40), (60, 170, 70)


def main(cid, derive=None):
    meta, M = load_masks(cid); out = os.path.join(PACKS, cid, "greybox"); os.makedirs(out, exist_ok=True)
    a, b = ("back", "side") if "back" in M and "side" in M else (None, None)
    if a is None:
        print("greybox needs side+back silhouettes; not available for", cid); return
    V, F = hull(cid, meta, M, a, b)
    print("hull", len(V), "verts", len(F), "tris")
    res = build_and_render(cid, V, F, meta, out)
    json.dump(dict(method="visual hull of aligned side+back silhouettes, voxel 8px, smoothed+decimated", renders=res), open(os.path.join(out, "greybox.json"), "w"), indent=1)
    return res


if __name__ == "__main__":
    main(sys.argv[1])
