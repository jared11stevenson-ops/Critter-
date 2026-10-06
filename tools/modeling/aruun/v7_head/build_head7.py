"""HEAD v7: landmark-driven faceted plate model. usage: python3 build_head7.py OUT.blend
Works in (F,U,s) space (s = lateral offset from the head line L=0.09, s<0 = his right); converted to blender world (L=0.09+s, -F, U) at bake.
Everything is flat shaded; plates are low-poly patches ray-projected onto a coarse 8-sided faceted cage, then solidified + bevelled."""
import sys, os, json, math
import bpy, bmesh
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
HERE = os.path.dirname(os.path.abspath(__file__))
LM = json.load(open(os.path.join(HERE, '../../../../design/model_sheets/aruun/fidelity/head_v7/landmarks.json')))
PX = 1626.667; FOFF = LM['FOFF']; FA = LM['FRONT_AXIS']; FS = LM['FRONT_SHIFT']; L0 = 0.09
FX = lambda x: (x - 436) / PX - FOFF
UY = lambda y: (4000 - y) / PX
SX = lambda x: (x - FA) / PX
UFY = lambda y: (4000 - (y + FS)) / PX
def W(p):  # (F,U,s) -> world
    return Vector((L0 + p[2], -p[0], p[1]))
def mat(name, col, rough=0.75):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; m.diffuse_color = (*col, 1)
    return m
def new_obj(name, bm, color, collection=None, flip=True):
    """bm in (F,U,s): convert to world, fix winding (axis triple is left-handed), outward normals, flat shade."""
    for v in bm.verts: v.co = W(v.co)
    bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat('m_' + name.split('_')[0] + '_' + name, color)); return ob
def recalc(ob):
    bm = bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(ob.data); bm.free()
    for p in ob.data.polygons: p.use_smooth = False

# ---------------- cage / loft ----------------
def loft(rings, nside=8, cap=True):
    """rings [x_px,top_y,bot_y,hw] -> bm in (F,U,s). flat-faced octagon sections."""
    bm = bmesh.new(); rs = []; k = 1 / math.cos(math.pi / nside)
    for x, ty, by, hw in rings:
        F = FX(x); Ut, Ub = UY(ty), UY(by); Uc = (Ut + Ub) / 2; hh = (Ut - Ub) / 2
        r = []
        for i in range(nside):
            a = math.pi / nside + 2 * math.pi * i / nside
            r.append(bm.verts.new((F, Uc + hh * k * math.sin(a), hw * k * math.cos(a))))
        rs.append(r)
    for a, b in zip(rs[:-1], rs[1:]):
        for i in range(nside): bm.faces.new((a[i], a[(i + 1) % nside], b[(i + 1) % nside], b[i]))
    if cap: bm.faces.new(rs[0][::-1]); bm.faces.new(rs[-1])
    return bm

class Cage:
    def __init__(self, bm):
        bm2 = bm.copy(); bmesh.ops.recalc_face_normals(bm2, faces=bm2.faces)
        self.bvh = BVHTree.FromBMesh(bm2); bm2.free()
    def hit(self, o, d, pull=None):
        """ray hit; if it misses, pull the origin toward `pull` (a point inside the cage) in small steps until it hits (= clamp the polygon inside the cage silhouette)."""
        o = Vector(o); d = Vector(d)
        r = self.bvh.ray_cast(o, d)
        if r[0] is None and pull is not None:
            for k in range(1, 60):
                q = o.lerp(pull, k / 60.0); q = q - d * 0.0  # keep ray origin outside: move only the lateral/vertical coords
                q = Vector(tuple((q[i] if d[i] == 0 else o[i]) for i in range(3)))
                r = self.bvh.ray_cast(q, d)
                if r[0] is not None: break
        if r[0] is None:
            n = self.bvh.find_nearest(o); return n[0], n[1]
        return r[0], r[1]

# ---------------- plates ----------------
def plate(name, polyF, cage, view, lift, thick, color, mirror_s=False, subd=0.045):
    """polyF: list of 2D points: view 'side' -> (F,U) (hit from s=-1), 'front' -> (s,U) (hit from F=+1). Returns object (solid)."""
    bm = bmesh.new()
    vs = [bm.verts.new((p[0], p[1], 0)) for p in polyF]
    f = bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=[f], quad_method='BEAUTY', ngon_method='EAR_CLIP')
    for _ in range(3):
        es = [e for e in bm.edges if (e.verts[0].co - e.verts[1].co).length > subd]
        if not es: break
        bmesh.ops.subdivide_edges(bm, edges=es, cuts=1, use_grid_fill=False, use_single_edge=False)
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
    nrm = {}
    for v in bm.verts:
        a, b = v.co.x, v.co.y
        if view == 'side': o, d = (a, b, -1.0), (0, 0, 1)
        else: o, d = (1.0, b, a), (-1, 0, 0)
        p, n = cage.hit(o, d, pull=Vector((a if view == 'side' else 0.0, 2.075 if view == 'side' else 2.075, 0.0)) if view == 'side' else Vector((0.0, 2.075, 0.0)))
        n = Vector(n).normalized()
        if view == 'side' and n.z > 0: n = -n
        if view == 'front' and n.x < 0: n = -n
        v.co = Vector(p) + n * lift; nrm[v.index] = n
    bm.normal_update()
    for fc in bm.faces:
        avg = sum((nrm[v.index] for v in fc.verts), Vector()) / len(fc.verts)
        if fc.normal.dot(avg) < 0: fc.normal_flip()
    if mirror_s:
        for v in bm.verts: v.co.z = -v.co.z
        bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
    ob = new_obj(name, bm, color)
    # reverse_faces in new_obj reverses ALL, which is the left-handed fix; recalc not used (open sheet)
    solid(ob, thick)
    return ob
def solid(ob, thick, bevel=0.0012):
    m = ob.modifiers.new('sol', 'SOLIDIFY'); m.thickness = thick; m.offset = -1; m.use_even_offset = False
    b = ob.modifiers.new('bev', 'BEVEL'); b.width = bevel; b.segments = 1; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(35)
def bake(ob):
    dg = bpy.context.evaluated_depsgraph_get(); ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev); ob.modifiers.clear(); ob.data = me
    for p in ob.data.polygons: p.use_smooth = False

def main(out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = []
    # cage
    bmc = loft(LM['cage']['rings'])
    cage = Cage(bmc)
    # skull_cage object (world conversion consumes bmc)
    sk = new_obj('skull_cage', bmc.copy(), (0.085, 0.08, 0.10)); recalc(sk); objs.append(sk)
    # plates
    for pl in LM['plates']:
        view = pl['view']; mir = pl['mirror']; pts = pl['pts']
        if view == 'side': P = [(FX(x), UY(y)) for x, y in pts]
        else:
            if mir == 'front_half':
                full = list(pts) + [(2 * FA - x, y) for x, y in pts[::-1] if x != FA]
                pts = full
            P = [(SX(x), UFY(y)) for x, y in pts]
        if mir == 'side':
            objs.append(plate(pl['name'] + '_R', P, cage, 'side', pl['lift'], pl['thick'], pl['color']))
            objs.append(plate(pl['name'] + '_L', P, cage, 'side', pl['lift'], pl['thick'], pl['color'], mirror_s=True))
        elif mir == 'front_pair':
            objs.append(plate(pl['name'] + '_R', P, cage, 'front', pl['lift'], pl['thick'], pl['color']))
            P2 = [(-a, b) for a, b in P][::-1]
            objs.append(plate(pl['name'] + '_L', P2, cage, 'front', pl['lift'], pl['thick'], pl['color']))
        else:
            objs.append(plate(pl['name'], P, cage, 'front', pl['lift'], pl['thick'], pl['color']))
    import extras7
    objs += extras7.make(cage, LM, sys.modules[__name__])
    for o in objs:
        if o.modifiers: bake(o)
        recalc_ok = o.name.startswith(('skull', 'mandible', 'tine', 'horn_cup', 'eye', 'socket', 'nostril'))
        if recalc_ok: recalc(o)
        o.data.update()
    for n, pn in extras7.PARENT.items():
        o = bpy.data.objects[n]; p = bpy.data.objects[pn]; o.parent = p; o.matrix_parent_inverse = p.matrix_world.inverted()
    bpy.ops.wm.save_as_mainfile(filepath=out); print('saved', out, 'tris', sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons))
if __name__ == '__main__':
    sys.path.insert(0, HERE); main(sys.argv[-1])
