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

    def __init__(self, name, pivot=(0, 0, 0), dy=0.0):
        self.name = name
        self.dy = dy                              # whole part shifted up by dy (stretch the body without re-typing coordinates)
        self.pivot = V(pivot[0], pivot[1] + dy, pivot[2])
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.color.new("Col")
        self.hbm = bmesh.new()                     # geometry that must NOT be voxel-unioned (armour plates, horns, blades, gems)
        self.hcol = self.hbm.loops.layers.color.new("Col")
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
    def _paint(self, verts, color):
        for v in verts:
            for l in v.link_loops:
                l[self._c()] = color

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
        res = bmesh.ops.create_uvsphere(self._b(), u_segments=seg, v_segments=ring, radius=1.0)
        vs = res["verts"]
        if e != 1.0:  # superellipsoid-ish squarer shape
            for v in vs:
                p = v.co.copy()
                for i in range(3):
                    p[i] = math.copysign(abs(p[i]) ** (1.0 / e) if p[i] != 0 else 0.0, p[i]) if False else p[i]
        m = Matrix.Translation(self.v(c)) @ self._rot_game(rot).to_matrix().to_4x4() @ Matrix.Diagonal((r[0], r[2], r[1], 1.0))
        bmesh.ops.transform(self._b(), matrix=m, verts=vs)
        self._paint(vs, color)
        return vs

    def tube(self, pts, radii, color, sides=8, caps=True, taper_pow=1.0):
        """Smooth swept tube through game-space points; radii = r or (r0, r1) or list per point."""
        n = len(pts)
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
        vs = []
        verts = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            row = []
            for j in range(tseg):
                b = 2 * math.pi * j / tseg
                x = (big + small * math.cos(b)) * math.cos(a)
                y = (big + small * math.cos(b)) * math.sin(a)
                z = small * math.sin(b)
                row.append(self._b().verts.new(Vector((x, y, z))))
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
        if len(hmesh.polygons):
            hobj = bpy.data.objects.new(self.name + "_h", hmesh)
            bpy.context.scene.collection.objects.link(hobj)
            if smooth_passes:
                hm = hobj.modifiers.new("hs", "SMOOTH")
                hm.iterations = max(1, smooth_passes // 2)
                hm.factor = 0.4
                bpy.context.view_layer.objects.active = hobj
                bpy.ops.object.modifier_apply(modifier=hm.name)
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
        obj.location = self.pivot
        if smooth_passes:
            m = obj.modifiers.new("smooth", "SMOOTH")
            m.iterations = smooth_passes
            m.factor = 0.6
            bpy.ops.object.modifier_apply(modifier=m.name)
        if target_tris and len(mesh.polygons) * 2 > target_tris:
            tri = sum(len(p.vertices) - 2 for p in mesh.polygons)
            if tri > target_tris:
                dm = obj.modifiers.new("dec", "DECIMATE")
                dm.ratio = target_tris / tri
                bpy.ops.object.modifier_apply(modifier=dm.name)
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
