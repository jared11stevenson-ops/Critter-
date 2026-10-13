"""CRITTER Blender modelling kit (bpy, headless). Author in GAME coordinates (x forward, y up, z toward the viewer's side, meters);
the helpers convert to Blender axes so the glTF export lands in Godot with the same numbers.

A critter is a set of RIGID PARTS named like the Godot rig (torso head arm_f arm_b leg_f leg_b weapon extra). Each part is built in body
space from primitives (blobs, tubes, blades, boxes, rings), optionally unioned by a voxel remesh into one smooth organic surface,
coloured per primitive (vertex colours: RGB = colour, A = emissive mask), then exported as ONE .glb whose node origins are the joint pivots.
Sockets are Empty nodes named sock_<name>. Run:  blender-less:  python3 tools/blender/build_<id>.py  (uses the bpy pip module).
"""
import math, os, sys
import bpy, bmesh
from mathutils import Vector, Matrix, Euler


def V(x, y, z):
    """game (x forward, y up, z side) -> blender"""
    return Vector((x, -z, y))


def hexc(h, a=0.0):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    # Blender -> glTF applies an sRGB decode to colour attributes; the toon shader wants the raw display values (like Prim),
    # so pre-encode: stored = sRGB_encode(raw) and the export hands the shader raw again.
    def enc(c):
        return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return (enc(r), enc(g), enc(b), a)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)


class Part:
    """One rigid part. Primitives are added in body space; finish() makes the mesh object with its origin at the pivot."""

    def __init__(self, name, pivot=(0, 0, 0), dy=0.0, sc=1.0):
        self.name = name
        self.sc = sc                              # uniform scale of the finished part about its pivot (e.g. a smaller head)
        self.dy = dy                              # whole part shifted up by dy (stretch the body without re-typing coordinates)
        self.pivot = V(pivot[0], pivot[1] + dy, pivot[2])
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.color.new("Col")
        self.hbm = bmesh.new()                     # geometry that must NOT be voxel-unioned (armour plates, horns, blades, gems)
        self.hcol = self.hbm.loops.layers.color.new("Col")
        self.scol = self.bm.loops.layers.color.new("Spec")     # r = specular/metal mask (0 matte .. 1 glossy), g = fur/fabric softness
        self.hscol = self.hbm.loops.layers.color.new("Spec")
        self._spec = 0.0
        self._soft = 0.0
        self._h = False
        self.obj = None

    def v(self, p):
        return V(p[0], p[1] + self.dy, p[2])

    def _b(self):
        return self.hbm if self._h else self.bm

    def _c(self):
        return self.hcol if self._h else self.col

    def hard(self, on=True):
        self._h = on
        return self

    # -- helpers
    def mat(self, spec=0.0, soft=0.0):
        """Material of the primitives added next: spec = glossy/metal highlight, soft = fur/cloth (no hard highlight)."""
        self._spec = spec
        self._soft = soft
        return self

    def _paint(self, verts, color):
        sl = self.hscol if self._h else self.scol
        sp_val = 0.0 if self._soft > 0 else self._spec if self._spec > 0 else (0.4 if (self._h and not getattr(self, '_ribbon', False)) else 0.0)
        for v in verts:
            for l in v.link_loops:
                l[self._c()] = color
                l[sl] = (sp_val, self._soft, 0.0, 1.0)

    def _xf(self, bm_verts, center, rot, scale):
        m = Matrix.Translation(V(*center)) @ Euler(tuple(math.radians(a) for a in rot), "XYZ").to_matrix().to_4x4() @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        bmesh.ops.transform(self._b(), matrix=m, verts=bm_verts)

    def _rot_game(self, rot):
        # rotate in GAME axes: rx about x, ry about y (up), rz about z; converted to blender axes
        rx, ry, rz = (math.radians(a) for a in rot)
        e = Euler((rx, -rz, ry), "XYZ")
        return e

    # -- primitives
    def blob(self, c, r, color, rot=(0, 0, 0), seg=14, ring=10, e=1.0):
        if self._h:   # hard geometry is exempt from decimation: build it light
            big = max(r) > 0.2
            seg = max(6, int(seg * (0.75 if big else 0.55)))
            ring = max(4, int(ring * (0.75 if big else 0.55)))
        res = bmesh.ops.create_uvsphere(self._b(), u_segments=seg, v_segments=ring, radius=1.0)
        vs = res["verts"]
        if e != 1.0:  # superellipsoid: e < 1 gives rounded-box plates, e > 1 pinches toward a diamond
            for v in vs:
                p = v.co.copy()
                for i in range(3):
                    a = abs(p[i])
                    p[i] = math.copysign(a ** e, p[i]) if a > 0 else 0.0
                v.co = p
        m = Matrix.Translation(self.v(c)) @ self._rot_game(rot).to_matrix().to_4x4() @ Matrix.Diagonal((r[0], r[2], r[1], 1.0))
        bmesh.ops.transform(self._b(), matrix=m, verts=vs)
        self._paint(vs, color)
        return vs

    def plate(self, c, size, color, trim=None, rot=(0, 0, 0), e=0.45, rivet=None, seg=10, ring=8):
        """A rounded-box armour plate with an optional darker/contrasting trim backing and rivets (rivet = colour). size = (x, y, z) full extents."""
        r = (size[0] / 2, size[1] / 2, size[2] / 2)
        if trim is not None:
            self.blob(c, (r[0] * 1.07, r[1] * 1.07, r[2] * 0.45), trim, rot=rot, seg=seg, ring=ring, e=e)
        vs = self.blob(c, r, color, rot=rot, seg=seg, ring=ring, e=e)
        if rivet is not None:
            was = self._h
            self._h = True
            for sx in (-0.72, 0.72):
                for sy in (-0.72, 0.72):
                    off = Vector((sx * r[0], sy * r[1], r[2] * 0.85))
                    q = (Euler(tuple(math.radians(a) for a in rot), "XYZ").to_matrix() @ off) if False else off
                    pos = (c[0] + sx * r[0] * math.cos(math.radians(rot[2])), c[1] + sy * r[1], c[2] + r[2] * 0.9)
                    self.blob(pos, (0.018, 0.018, 0.012), rivet, seg=6, ring=4)
            self._h = was
        return vs

    def tube(self, pts, radii, color, sides=8, caps=True, taper_pow=1.0, wide=None):
        """Smooth swept tube through game-space points; radii = r or (r0, r1) or list per point."""
        self._ribbon = wide is not None
        n = len(pts)
        if self._h:
            rm = max(radii) if isinstance(radii, (list, tuple)) and not isinstance(radii[0], (list, tuple)) else (radii if isinstance(radii, (int, float)) else 0.1)
            if isinstance(rm, (list, tuple)):
                rm = max(rm)
            sides = 4 if rm <= 0.045 else (5 if rm <= 0.09 else min(sides, 7))
        if isinstance(radii, (int, float)):
            radii = [radii] * n
        elif len(radii) == 2 and n != 2:
            radii = [radii[0] + (radii[1] - radii[0]) * (i / (n - 1)) ** taper_pow for i in range(n)]
        P = [self.v(p) for p in pts]
        rings = []
        prev_n = None
        for i, p in enumerate(P):
            t = (P[min(i + 1, n - 1)] - P[max(i - 1, 0)]).normalized()
            ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            if prev_n is not None:
                ref = prev_n
            if wide is not None:      # ribbon: the first radius runs along `wide` (game axes), the second is the thickness
                w = V(*wide)
                a = (w - t * w.dot(t)).normalized()
                b = t.cross(a).normalized()
            else:
                a = t.cross(ref).normalized()
                b = t.cross(a).normalized()
            prev_n = a
            ring = []
            rr = radii[i]
            rx, ry = (rr, rr) if isinstance(rr, (int, float)) else rr
            for k in range(sides):
                ang = 2 * math.pi * k / sides
                ring.append(self._b().verts.new(p + a * (math.cos(ang) * rx) + b * (math.sin(ang) * ry)))
            rings.append(ring)
        allv = [v for r in rings for v in r]
        for i in range(n - 1):
            for k in range(sides):
                try:
                    self._b().faces.new((rings[i][k], rings[i][(k + 1) % sides], rings[i + 1][(k + 1) % sides], rings[i + 1][k]))
                except ValueError:
                    pass
        if caps:
            for ring, end in ((rings[0], P[0]), (rings[-1], P[-1])):
                try:
                    f = self._b().faces.new(ring if ring is rings[-1] else list(reversed(ring)))
                    allv_f = f
                except ValueError:
                    pass
        bmesh.ops.recalc_face_normals(self._b(), faces=list(self._b().faces))
        self._paint(allv, color)
        self._ribbon = False
        return allv

    def box(self, c, size, color, rot=(0, 0, 0), bevel=0.0):
        res = bmesh.ops.create_cube(self._b(), size=1.0)
        vs = res["verts"]
        m = Matrix.Translation(self.v(c)) @ self._rot_game(rot).to_matrix().to_4x4() @ Matrix.Diagonal((size[0], size[2], size[1], 1.0))
        bmesh.ops.transform(self._b(), matrix=m, verts=vs)
        if bevel > 0:
            edges = list({e for v in vs for e in v.link_edges})
            bmesh.ops.bevel(self._b(), geom=edges, offset=bevel, segments=2, affect="EDGES")
            vs = list({v for e in edges if e.is_valid for v in e.verts})
        self._paint([v for v in self._b().verts if v in set(vs)] or vs, color)
        return vs

    def cone(self, base, tip, r0, r1, color, sides=8):
        return self.tube([base, tip], (r0, r1), color, sides=sides)

    def ring(self, c, big, small, color, rot=(0, 0, 0), seg=16, tseg=6):
        if self._h:
            seg = max(8, int(seg * 0.7))
            tseg = max(3, int(tseg * 0.6))
        vs = []
        verts = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            row = []
            for j in range(tseg):
                b = 2 * math.pi * j / tseg
                x = (big + small * math.cos(b)) * math.cos(a)
                zb = (big + small * math.cos(b)) * math.sin(a)      # ring plane = game XY (axis = game Z, like Prim.ring)
                yb = small * math.sin(b)
                row.append(self._b().verts.new(Vector((x, yb, zb))))
            verts.append(row)
        for i in range(seg):
            for j in range(tseg):
                try:
                    self._b().faces.new((verts[i][j], verts[(i + 1) % seg][j], verts[(i + 1) % seg][(j + 1) % tseg], verts[i][(j + 1) % tseg]))
                except ValueError:
                    pass
        allv = [v for r in verts for v in r]
        m = Matrix.Translation(self.v(c)) @ self._rot_game(rot).to_matrix().to_4x4()
        bmesh.ops.transform(self._b(), matrix=m, verts=allv)
        self._paint(allv, color)
        return allv

    def finish(self, voxel=0.0, smooth_passes=0, target_tris=0, parent_collection=None):
        """Turn the accumulated geometry into a mesh object at the pivot. voxel>0 unions everything into one smooth organic surface."""
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        hmesh = bpy.data.meshes.new(self.name + "_h")
        self.hbm.to_mesh(hmesh)
        self.hbm.free()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        for o in bpy.context.selected_objects:
            o.select_set(False)
        obj.select_set(True)
        if voxel > 0:
            mesh.remesh_voxel_size = voxel
            mesh.remesh_voxel_adaptivity = 0.0
            bpy.ops.object.voxel_remesh()
        hard_tris = sum(len(p.vertices) - 2 for p in hmesh.polygons)
        if target_tris:
            org_target = max(250, target_tris - hard_tris)
            tri = sum(len(p.vertices) - 2 for p in mesh.polygons)
            if tri > org_target:
                dm = obj.modifiers.new("dec", "DECIMATE")
                dm.ratio = org_target / tri
                bpy.ops.object.modifier_apply(modifier=dm.name)
        if smooth_passes and len(mesh.polygons):
            m = obj.modifiers.new("smooth", "SMOOTH")
            m.iterations = smooth_passes
            m.factor = 0.6
            bpy.ops.object.modifier_apply(modifier=m.name)
        if len(hmesh.polygons):
            hobj = bpy.data.objects.new(self.name + "_h", hmesh)
            bpy.context.scene.collection.objects.link(hobj)
            bpy.context.view_layer.objects.active = obj
            for o in bpy.context.selected_objects:
                o.select_set(False)
            obj.select_set(True)
            hobj.select_set(True)
            bpy.ops.object.join()
            obj = bpy.context.view_layer.objects.active
            mesh = obj.data
            mesh.name = self.name
        obj.name = self.name
        # origin to the joint pivot
        mesh.transform(Matrix.Translation(-self.pivot))
        if self.sc != 1.0:
            mesh.transform(Matrix.Scale(self.sc, 4))
        obj.location = self.pivot
        # triangulate for a predictable count
        tm = obj.modifiers.new("tri", "TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=tm.name)
        bpy.ops.object.shade_smooth()
        ca = mesh.color_attributes
        if len(ca):
            ca.active_color = ca[0]
            ca.render_color_index = 0
        self.obj = obj
        return obj


def socket(name, pos):
    e = bpy.data.objects.new("sock_" + name, None)
    e.empty_display_size = 0.05
    e.location = V(*pos)
    bpy.context.scene.collection.objects.link(e)
    return e


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def export(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True, export_apply=False,
                              export_vertex_color="ACTIVE", export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
                              export_materials="NONE", export_cameras=False, export_lights=False)


# ----------------------------------------------------------------------------------------------- finishing pass (the "2026" bake)
def bake(parts, ao_rays=24, ao_dist=0.55, ao_strength=0.4, curv_gain=0.9, seed=1):
    """Bakes ambient occlusion (the WHOLE critter occludes itself: arms shade the torso, cloaks shade the legs) into the vertex colours and writes a
    detail UV layer per mesh: u = specular mask, v = convex-edge highlight (curvature), so the toon shader can add sheen on armour and rim wear on edges."""
    import random
    from mathutils.bvhtree import BVHTree
    rnd = random.Random(seed)
    verts_w, polys = [], []
    for o in parts.values():
        base = len(verts_w)
        mw = o.matrix_world
        verts_w.extend(mw @ v.co for v in o.data.vertices)
        for p in o.data.polygons:
            polys.append(tuple(base + i for i in p.vertices))
    tree = BVHTree.FromPolygons(verts_w, polys, epsilon=0.0001)
    dirs = []
    for _ in range(ao_rays):
        while True:
            d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)))
            if 0.01 < d.length <= 1.0:
                dirs.append(d.normalized())
                break
    for name, o in parts.items():
        me = o.data
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.verts.ensure_lookup_table()
        col = bm.loops.layers.color.get("Col")
        spl = bm.loops.layers.color.get("Spec")
        uvl = bm.loops.layers.uv.get("detail") or bm.loops.layers.uv.new("detail")
        mw = o.matrix_world
        nmw = mw.to_3x3()
        ao = {}
        curv = {}
        for v in bm.verts:
            n = (nmw @ v.normal).normalized()
            p = mw @ v.co + n * 0.01
            hit = 0
            tot = 0
            for d in dirs:
                if d.dot(n) < 0:
                    d = -d
                # cosine-ish weighting toward the normal
                dd = (d + n * 0.6).normalized()
                tot += 1
                h = tree.ray_cast(p, dd, ao_dist)
                if h[0] is not None:
                    hit += 1
            ao[v.index] = 1.0 - hit / max(tot, 1)
            c = 0.0
            ne = 0
            for e in v.link_edges:
                o2 = e.other_vert(v)
                vec = o2.co - v.co
                L = vec.length
                if L > 1e-6:
                    c += -(vec.dot(v.normal)) / L
                    ne += 1
            curv[v.index] = (c / ne) if ne else 0.0
        for f in bm.faces:
            for l in f.loops:
                vi = l.vert.index
                a = ao[vi]
                k = (1.0 - ao_strength) + ao_strength * a
                cc = l[col]
                l[col] = (cc[0] * k, cc[1] * k, cc[2] * k, cc[3])
                sp = l[spl]
                edge = max(0.0, min(1.0, curv[vi] * curv_gain))
                l[uvl].uv = (sp[0], edge)
        bm.to_mesh(me)
        bm.free()
        ca = me.color_attributes
        if "Col" in ca:
            ca.active_color = ca["Col"]
            ca.render_color_index = list(ca.keys()).index("Col") if hasattr(ca, "keys") else 0


# ----------------------------------------------------------------------------------------------- creature helpers (v0.15 "toy-quality" kit)
def _unit(v):
    n = math.sqrt(sum(x * x for x in v))
    return tuple(x / n for x in v) if n else (0, 1, 0)


def eye(p, c, r, iris, white="f4f0e8", pupil="120a0c", look=(1.0, 0.0, 0.0), glow=0.0, lid=None, ps=1.0, ring_c=None):
    """A glossy cartoon-quality eye on the surface at c: eyeball, iris, pupil, two specular catch-lights (emissive) and an optional lid.
    look = outward facing direction of the eye (game axes)."""
    lk = _unit(look)
    # thin axis of the iris discs points along `look`: pick a dominant axis for the radii, rotate by yaw for in-between directions
    yaw = math.degrees(math.atan2(-lk[2], lk[0]))
    rot = (0, yaw, 0)
    p.hard().blob(c, (r, r, r), hexc(white), rot=rot, seg=10, ring=8)
    ic = (c[0] + lk[0] * r * 0.62, c[1] + lk[1] * r * 0.62, c[2] + lk[2] * r * 0.62)
    p.hard().blob(ic, (r * 0.42, r * 0.7, r * 0.7), hexc(iris, glow), rot=rot, seg=10, ring=8)
    pc = (c[0] + lk[0] * r * 0.8, c[1] + lk[1] * r * 0.8, c[2] + lk[2] * r * 0.8)
    p.hard().blob(pc, (r * 0.3, r * 0.45 * ps, r * 0.45 * ps), hexc(pupil), rot=rot, seg=8, ring=6)
    if ring_c:   # thick coloured eye-rim (gold / black lash line)
        p.hard().ring((c[0] + lk[0] * r * 0.15, c[1], c[2] + lk[2] * r * 0.15), r * 1.02, r * 0.16, hexc(ring_c), rot=(0, yaw + 90, 0), seg=14, tseg=4)
    up = (0.0, 1.0, 0.0)
    for k, (dy, dz, rr_) in enumerate(((0.4, 0.22, 0.2), (-0.2, -0.3, 0.1))):
        hc = (c[0] + lk[0] * r * 0.95, c[1] + r * dy, c[2] + r * dz * (1 if lk[2] >= 0 else -1) * (0.3 if abs(lk[2]) < 0.5 else 1.0) + lk[2] * 0.0)
        p.hard().blob(hc, (r * rr_, r * rr_, r * rr_), hexc("ffffff", 1.0), seg=6, ring=4)
    if lid is not None:
        p.hard().blob((c[0], c[1] + r * 0.55, c[2]), (r * 1.08, r * 0.55, r * 1.08), hexc(lid), rot=rot, seg=10, ring=6)


def fur(p, c, r, color, n=120, ln=0.12, flow=(-0.4, -0.7, 0.0), seed=1, width=0.05, spread=(1.0, 1.0, 1.0), skip_below=None):
    """Curved fur tufts scattered over an ellipsoid (centre c, radii r), leaning along `flow` (gravity / growth direction)."""
    import random
    rr = random.Random(seed)
    fl = _unit(flow)
    made = 0
    tries = 0
    while made < n and tries < n * 6:
        tries += 1
        a = rr.uniform(0, math.tau)
        y = rr.uniform(-1, 1)
        s = math.sqrt(max(0.0, 1 - y * y))
        d = (math.cos(a) * s * spread[0], y * spread[1], math.sin(a) * s * spread[2])
        if skip_below is not None and d[1] < skip_below:
            continue
        base = (c[0] + d[0] * r[0], c[1] + d[1] * r[1], c[2] + d[2] * r[2])
        n_ = _unit((d[0] / max(r[0], 1e-3), d[1] / max(r[1], 1e-3), d[2] / max(r[2], 1e-3)))
        dirn = _unit((n_[0] * 0.8 + fl[0] * 0.7, n_[1] * 0.8 + fl[1] * 0.7, n_[2] * 0.8 + fl[2] * 0.7))
        L = ln * rr.uniform(0.7, 1.3)
        mid = (base[0] + dirn[0] * L * 0.5 + n_[0] * L * 0.15, base[1] + dirn[1] * L * 0.5 + n_[1] * L * 0.15, base[2] + dirn[2] * L * 0.5 + n_[2] * L * 0.15)
        tip = (base[0] + dirn[0] * L + fl[0] * L * 0.25, base[1] + dirn[1] * L + fl[1] * L * 0.25, base[2] + dirn[2] * L + fl[2] * L * 0.25)
        shade = rr.uniform(0.9, 1.12)
        col = (min(1.0, color[0] * shade), min(1.0, color[1] * shade), min(1.0, color[2] * shade), color[3])
        p.hard().mat(0.0, 1.0).tube([base, mid, tip], (width, 0.0), col, sides=3)
        made += 1
    p.mat(0.0, 0.0)


def _c(x):
    return hexc(x) if isinstance(x, str) else x


def _lat(look):
    lk = _unit(look)
    return (-lk[2], 0.0, lk[0])    # horizontal axis across the face (game axes)


def brow(p, c, w, tilt, color, th=0.045, look=(1, 0, 0), arch=0.02):
    """Thick cartoon eyebrow centred on c, width w, tilt = rise (+) of the OUTER end relative to the inner end (angry = negative, worried = positive).
    side is decided by the sign of c.z along the lateral axis; call once per eye."""
    lat = _lat(look)
    side = 1.0 if (c[2] * lat[2] + c[0] * lat[0] * 0.0) >= 0 else -1.0
    a = (c[0] - lat[0] * w * 0.5 * side, c[1] - tilt * 0.5, c[2] - lat[2] * w * 0.5 * side)   # inner end
    b = (c[0] + lat[0] * w * 0.5 * side, c[1] + tilt * 0.5, c[2] + lat[2] * w * 0.5 * side)       # outer end
    m = ((a[0] + b[0]) / 2 + look[0] * 0.015, (a[1] + b[1]) / 2 + arch, (a[2] + b[2]) / 2 + look[2] * 0.015)
    p.hard().tube([a, m, b], ((th * 0.5, th), (th, th), (th, th * 0.4)), _c(color), sides=5)


def mouth(p, c, w, curve, color="1a0e10", look=(1, 0, 0), th=0.03, teeth=0, tooth="fff6e0", tongue=None, fang=False):
    """Cartoon mouth line centred on c, width w, curve>0 = smile (ends rise), <0 = frown. Optional row of teeth and a tongue blob."""
    lat = _lat(look)
    n = 7
    pts = []
    for i in range(n):
        t = i / (n - 1) * 2 - 1
        y = c[1] + curve * (t * t - 0.5) * 1.0 * (1 if curve >= 0 else 1)
        pts.append((c[0] + lat[0] * w * 0.5 * t + look[0] * 0.02 * (1 - t * t), y, c[2] + lat[2] * w * 0.5 * t + look[2] * 0.02 * (1 - t * t)))
    p.hard().tube(pts, th, _c(color), sides=4)
    for k in range(teeth):
        t = (k + 0.5) / teeth * 1.2 - 0.6
        y = c[1] + curve * (t * t - 0.5) - th
        pos = (c[0] + lat[0] * w * 0.5 * t + look[0] * 0.03, y, c[2] + lat[2] * w * 0.5 * t + look[2] * 0.03)
        p.hard().blob(pos, (w * 0.05, w * (0.09 if fang else 0.065), w * 0.05), _c(tooth), seg=6, ring=4)
    if tongue:
        p.hard().blob((c[0] + look[0] * 0.03, c[1] - w * 0.08, c[2] + look[2] * 0.03), (w * 0.12, w * 0.07, w * 0.14), _c(tongue), seg=6, ring=4)


def rivets(p, pts, r=0.02, color="e8c050"):
    for q in pts:
        p.hard().blob(q, (r, r, r), hexc(color, 0.3), seg=6, ring=4)


def pauldron(p, c, r, color, trim, spikes=0, sd=1.0):
    """Layered shoulder armour: a domed plate, a rim band and an optional row of spikes."""
    p.hard().blob(c, (r, r * 0.7, r * 1.05), _c(color), e=0.75, seg=12, ring=8)
    p.hard().blob((c[0], c[1] - r * 0.55, c[2]), (r * 1.05, r * 0.28, r * 1.1), _c(trim), e=0.7, seg=12, ring=6)
    for k in range(spikes):
        a = (k - (spikes - 1) / 2) * 0.55
        q = (c[0] + math.sin(a) * r * 0.5, c[1] + r * 0.6, c[2] + math.cos(a) * r * 0.2 * sd)
        p.hard().tube([q, (q[0], q[1] + r * 0.55, q[2])], (r * 0.2, 0.0), _c(trim), sides=4)
    rivets(p, [(c[0] + r * 0.4, c[1] + r * 0.45, c[2] + r * 0.5 * sd), (c[0] - r * 0.4, c[1] + r * 0.45, c[2] + r * 0.5 * sd)], r * 0.12)


def bracer(p, a, b, r, color, trim, rivet=True):
    """Armoured sleeve / greave on a roughly vertical limb segment a->b: tapered plate tube with trim rings and rivets."""
    p.hard().tube([a, b], (r, r * 0.88), _c(color), sides=10)
    for q, rr in ((a, r * 1.06), (b, r * 0.95)):
        p.hard().ring(q, rr, r * 0.16, _c(trim), rot=(90, 0, 0), seg=14, tseg=4)
    if rivet:
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2)
        rivets(p, [(mid[0] + r * 0.95, mid[1] + 0.03, mid[2]), (mid[0] + r * 0.95, mid[1] - 0.05, mid[2])], r * 0.14)
