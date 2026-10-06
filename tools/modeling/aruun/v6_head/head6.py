"""ARUUN head v6: subdivision skull (ONE loft: cranium+muzzle, no seam) + separate mandible + features rooted on the skull surface (BVH-projected plates).
Coordinates (F fwd, U up, L lateral; head centre line L=HL) -> blender (L,-F,U).  Hard constraint = v2 side/back silhouettes; the skull core is hand-profiled from them,
plates/tines/crown supply the rest of the silhouette.  Optional soft relief from Depth Anything V2 small (depth_relief.py) via env DEPTH_AMP (m).
STEP env: 1 skull | 2 +eyes/brows/sockets | 3 +mandible/nose | 4 +plates/crown/tines."""
import os, sys, json, numpy as np, bpy, bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from scipy.interpolate import PchipInterpolator as PI
HL = 0.09
def B(F, U, L): return (L, -F, U)
def smooth_step(x): x = np.clip(x, 0, 1); return x * x * (3 - 2 * x)

# ---- hand profile (read off the v2 side crop + masks) ------------------------------------------------------------
SK_F  = [-0.088, -0.080, -0.065, -0.045, -0.020, 0.010, 0.040, 0.070, 0.100, 0.130, 0.155, 0.172]
SK_T  = [ 2.040,  2.070,  2.103,  2.125,  2.136, 2.138, 2.130, 2.112, 2.100, 2.101, 2.098, 2.082]
SK_B  = [ 2.030,  2.012,  1.990,  1.972,  1.962, 1.962, 1.975, 2.020, 2.036, 2.052, 2.064, 2.074]
SK_W  = [ 0.010,  0.050,  0.083,  0.100,  0.106, 0.107, 0.103, 0.085, 0.058, 0.046, 0.036, 0.024]
SK_EXP= [ 2.0,    2.0,    2.0,    2.0,    2.1,   2.2,   2.3,   2.5,   2.6,   2.6,   2.6,   2.4]
def prof(F, ys, kind='pchip'): return float(PI(SK_F, ys)(np.clip(F, SK_F[0], SK_F[-1])))

JW_F = [0.045, 0.070, 0.100, 0.130, 0.155, 0.178, 0.196]
JW_T = [2.034, 2.040, 2.048, 2.052, 2.046, 2.034, 2.028]     # hooked tip turns UP at the end
JW_B = [2.005, 2.002, 2.000, 1.994, 1.987, 1.983, 1.990]
JW_W = [0.040, 0.037, 0.031, 0.025, 0.018, 0.012, 0.006]
JAW_PIVOT = (0.03, 2.03, HL)

def loft(name, Fs, T, Bt, W, EXP, nring=28, apex=True, uc_shift=None):
    n = len(Fs); V = []
    for i in range(n):
        F = Fs[i]; Uc = 0.5 * (T[i] + Bt[i]); hu = 0.5 * (T[i] - Bt[i]); hw = W[i]; ex = EXP[i]
        sc = 1.0
        if apex and i in (0, n - 1): sc = 0.25
        for k in range(nring):
            a = 2 * np.pi * k / nring; c, s = np.cos(a), np.sin(a)
            e = lambda v: np.sign(v) * abs(v) ** (2.0 / ex)
            V.append(B(F, Uc + hu * e(s) * sc, HL + hw * e(c) * sc))
    Q = []
    for i in range(n - 1):
        for k in range(nring):
            a, b = i * nring + k, i * nring + (k + 1) % nring; Q.append([a, b, b + nring, a + nring])
    nv = len(V)
    V.append(B(Fs[0] - 0.006, 0.5 * (T[0] + Bt[0]), HL)); V.append(B(Fs[-1] + 0.006, 0.5 * (T[-1] + Bt[-1]), HL))
    for k in range(nring):
        k2 = (k + 1) % nring
        Q.append([nv, k2, k]); Q.append([nv + 1, (n - 1) * nring + k, (n - 1) * nring + k2])
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], Q); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    # fix normals outward
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    m = ob.modifiers.new('sub', 'SUBSURF'); m.levels = 3; m.render_levels = 3
    bpy.ops.object.modifier_apply(modifier='sub')
    for p in me.polygons: p.use_smooth = True
    return ob

def skull_loft():
    Fs = np.arange(-0.088, 0.1721, 0.0087).tolist()
    T = [prof(f, SK_T) for f in Fs]; Bt = [prof(f, SK_B) for f in Fs]; W = [prof(f, SK_W) for f in Fs]; E = [prof(f, SK_EXP) for f in Fs]
    return loft('skull', Fs, T, Bt, W, E)

def mandible_loft():
    Fs = np.arange(0.045, 0.1961, 0.0125).tolist()
    Fk = lambda ys: [float(PI(JW_F, ys)(f)) for f in Fs]
    ob = loft('mandible', Fs, Fk(JW_T), Fk(JW_B), Fk(JW_W), [2.3] * len(Fs), nring=20, apex=True)
    pv = Vector(B(*JAW_PIVOT))
    for v in ob.data.vertices: v.co -= pv
    ob.location = pv
    return ob

# ---- surface utilities ---------------------------------------------------------------------------------------------
def bvh_of(ob):
    dg = bpy.context.evaluated_depsgraph_get(); me = ob.evaluated_get(dg).to_mesh()
    verts = [ob.matrix_world @ v.co for v in me.vertices]; tris = [tuple(p.vertices) for p in me.polygons]
    return BVHTree.FromPolygons(verts, tris)

def hit(bvh, F, U, L_or_none, axis, side=1):
    """ray onto skull. axis 'L': from the outside at side, along -L.  'U': from above, down.  returns (point_vec, normal) or None"""
    if axis == 'L': o = Vector(B(F, U, HL + side * 0.4)); d = Vector((-side, 0, 0))
    elif axis == 'U': o = Vector(B(F, 2.6, L_or_none)); d = Vector((0, 0, -1))
    else: o = Vector(B(F, U, HL - 0.4 * 0 + 0.0)); d = Vector((0, 0, 1))
    r = bvh.ray_cast(o, d)
    return (r[0], r[1]) if r[0] is not None else None

def plate(name, poly, bvh, axis, side, off, thick, cuts=3, L_of=None):
    """angular plate: 2D polygon (F,U) [axis L] or (F,L-HL) [axis U] triangulated/subdivided, projected on the skull surface, lifted by `off` along the surface normal, solidified by `thick` (inward)."""
    bm = bmesh.new(); vs = [bm.verts.new((p[0], p[1], 0)) for p in poly]; bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    for _ in range(cuts): bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    for v in bm.verts:
        a, b = v.co.x, v.co.y
        h = hit(bvh, a, b, HL + b, 'U') if axis == 'U' else hit(bvh, a, b, None, 'L', side)
        if h is None: v.co = Vector((0, 0, -9)); continue
        p, n = h; v.co = p + n * off
    bm.verts.ensure_lookup_table()
    bad = [v for v in bm.verts if v.co.z < -5]; bmesh.ops.delete(bm, geom=bad, context='VERTS')
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bm2 = bmesh.new(); bm2.from_mesh(me); bmesh.ops.recalc_face_normals(bm2, faces=bm2.faces)
    # make normals point away from the head centre
    c = Vector((HL, 0, 2.05)); fl = sum(((f.calc_center_median() - c).dot(f.normal) < 0) for f in bm2.faces) > len(bm2.faces) / 2
    if fl: bmesh.ops.reverse_faces(bm2, faces=bm2.faces[:])
    bm2.to_mesh(me); bm2.free()
    s = ob.modifiers.new('sol', 'SOLIDIFY'); s.thickness = thick; s.offset = -1
    bpy.ops.object.modifier_apply(modifier='sol')
    sm = ob.modifiers.new('sub', 'SUBSURF'); sm.levels = 1; sm.subdivision_type = 'SIMPLE'
    bpy.ops.object.modifier_apply(modifier='sub')
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def tube(name, pts, rads, nring=10, up=(0, 0, 1)):
    """swept elliptical tube; pts blender-space Vectors, rads (r_a, r_b) per pt"""
    pts = [Vector(p) for p in pts]; V = []; Q = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = t.cross(Vector(up));
        if a.length < 1e-4: a = t.cross(Vector((1, 0, 0)))
        a.normalize(); b = t.cross(a).normalized()
        for k in range(nring):
            th = 2 * np.pi * k / nring; V.append(p + a * np.cos(th) * rads[i][0] + b * np.sin(th) * rads[i][1])
    for i in range(len(pts) - 1):
        for k in range(nring):
            a_, b_ = i * nring + k, i * nring + (k + 1) % nring; Q.append([a_, b_, b_ + nring, a_ + nring])
    n = len(pts) * nring; V.append(pts[0] - (pts[1] - pts[0]).normalized() * rads[0][0] * 0.5); V.append(pts[-1] + (pts[-1] - pts[-2]).normalized() * rads[-1][0] * 1.2)
    for k in range(nring):
        k2 = (k + 1) % nring; Q.append([n, k2, k]); Q.append([n + 1, n - nring + k, n - nring + k2])
    me = bpy.data.meshes.new(name); me.from_pydata([tuple(v) for v in V], [], Q); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob); bpy.context.view_layer.objects.active = ob
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    m = ob.modifiers.new('sub', 'SUBSURF'); m.levels = 2; bpy.ops.object.modifier_apply(modifier='sub')
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def ell(name, c, r, seg=24):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=1.0)
    for v in bm.verts: v.co = Vector((v.co.x * r[0], v.co.y * r[1], v.co.z * r[2]))
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob); ob.location = Vector(c)
    for p in me.polygons: p.use_smooth = True
    return ob

def displace(ob, fn):
    """fn(P (n,3) blender coords) -> offset along the vertex normal (n,) (m); vectorised"""
    me = ob.data; n = len(me.vertices)
    co = np.zeros(n * 3); me.vertices.foreach_get('co', co); co = co.reshape(-1, 3)
    nr = np.zeros(n * 3); me.vertices.foreach_get('normal', nr); nr = nr.reshape(-1, 3)
    co = co + nr * fn(co)[:, None]
    me.vertices.foreach_set('co', co.ravel()); me.update()
