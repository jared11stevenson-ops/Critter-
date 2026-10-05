"""Shared mesh-builder for the Reaches / world kit (bpy as a module, headless).

Pieces are authored Z-up in metres, vertex-colour painted (colour numbers are the game's ToonKit space, i.e. written to
COLOR_0 as-is), vertex-colour AO baked with BVH rays, atlas UVs only on decal faces (everything else points at the
blank atlas cell), exported one GLB per piece with <= 2k tris. Blender (x, y, z) -> Godot (x, z, -y).
"""
import math
import random
import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# ---- palette (ToonKit colour space) ----
STONE = (0.66, 0.42, 0.31)
STONE_D = (0.52, 0.32, 0.25)
OCHRE = (0.74, 0.47, 0.26)
SURVEY = (0.69, 0.60, 0.51)       # old cut survey stone #b09a82
VERMIL = (0.78, 0.41, 0.25)       # #c4683f
RUST = (0.54, 0.29, 0.20)         # #8a4a32
CREAM = (0.88, 0.69, 0.50)        # #e0b080
PLUM = (0.42, 0.24, 0.22)
BUFF = (0.80, 0.62, 0.44)
DEEP = (0.23, 0.13, 0.10)
GUN = (0.35, 0.31, 0.28)          # dominion gunmetal #5a5048
GUN_D = (0.22, 0.20, 0.20)
DOM_RED = (0.72, 0.10, 0.09)
THOUGHT = (0.50, 0.88, 1.0)       # #7fe0ff
WOOD = (0.48, 0.32, 0.22)
WOOD_D = (0.34, 0.22, 0.16)
ROPE = (0.80, 0.66, 0.42)
OLIVE = (0.50, 0.52, 0.28)
SAGE = (0.58, 0.60, 0.40)
LICHEN = (0.60, 0.58, 0.32)
LICHEN_O = (0.76, 0.50, 0.27)
SALT = (0.80, 0.74, 0.66)
BONE = (0.86, 0.80, 0.68)
DUST = (0.82, 0.62, 0.46)

CELLS = {"blank": (0, 0), "glyph": (1, 0), "tally": (2, 0), "hazard": (3, 0), "stencil": (0, 1), "wood": (1, 1),
         "rope": (2, 1), "salt": (3, 1), "rust": (0, 2), "cracks": (1, 2), "pulse": (2, 2), "chevron": (3, 2),
         "ashlar": (0, 3), "lichen": (1, 3), "plank": (2, 3), "scale": (3, 3)}


def cell_uv(name, u, v):
    """UV inside atlas cell `name`; u,v in 0..1 over the cell (v up), inset to avoid bleed."""
    cx, cy = CELLS[name]
    uu = (cx + 0.04 + 0.92 * u) / 4.0
    vv = 1.0 - (cy + 0.04 + 0.92 * (1.0 - v)) / 4.0
    return (uu, vv)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def mul(a, k):
    return tuple(min(1.0, max(0.0, a[i] * k)) for i in range(3))


def jit(c, rng, amt=0.06):
    k = 1.0 + rng.uniform(-amt, amt)
    return (c[0] * k * (1 + rng.uniform(-amt, amt) * 0.3), c[1] * k, c[2] * k * (1 + rng.uniform(-amt, amt) * 0.3))


class KM:
    def __init__(self, name, seed=1):
        self.name = name
        self.rng = random.Random(seed)
        self.polys = []     # (pts, cols, uvs, mat)
        self.sharp = 38.0   # deg: edges sharper than this are hard
        self.ao_dist = 1.4
        self.ao_amt = 0.55
        self.dust = 0.0
        self.ground = 0.0   # contact darkening height

    # ---- low level ----
    def poly(self, pts, col, uv=None, mat=0, out=None):
        pts = [Vector(p) for p in pts]
        if out is not None:
            n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
            c = sum(pts, Vector()) / len(pts)
            if n.dot(c - Vector(out)) < 0:
                pts = pts[::-1]
                if uv is not None:
                    uv = uv[::-1]
                if isinstance(col, list):
                    col = col[::-1]
        cols = col if isinstance(col, list) else [col] * len(pts)
        self.polys.append((pts, cols, uv, mat))

    def quad(self, a, b, c, d, col, uv=None, mat=0, out=None):
        self.poly([a, b, c, d], col, uv, mat, out)

    def tri(self, a, b, c, col, mat=0, out=None):
        self.poly([a, b, c], col, None, mat, out)

    # ---- primitives ----
    def box(self, center, size, col, rot=0.0, taper=0.0, tilt=(0, 0), decal=None, decal_face="-y", mat=0,
            cols=None, jitter=0.0, decal_uv=None):
        """Box centred at `center`, size (x,y,z), yaw `rot` (rad about Z), taper = top shrink (0..1),
        tilt=(about x, about y) small lean. decal: atlas cell name painted on `decal_face`."""
        cx, cy, cz = center
        sx, sy, sz = [s * 0.5 for s in size]
        tp = 1.0 - taper
        corners = []
        for k, (zz, f) in enumerate(((-1, 1.0), (1, tp))):
            for (xx, yy) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                corners.append(Vector((xx * sx * f, yy * sy * f, zz * sz)))
        if jitter:
            corners = [c + Vector((self.rng.uniform(-jitter, jitter), self.rng.uniform(-jitter, jitter),
                                   self.rng.uniform(-jitter, jitter))) for c in corners]
        cr, sr = math.cos(rot), math.sin(rot)
        out = []
        for v in corners:
            # tilt
            ax, ay = tilt
            y2 = v.y * math.cos(ax) - v.z * math.sin(ax)
            z2 = v.y * math.sin(ax) + v.z * math.cos(ax)
            x2 = v.x * math.cos(ay) + z2 * math.sin(ay)
            z3 = -v.x * math.sin(ay) + z2 * math.cos(ay)
            out.append(Vector((cr * x2 - sr * y2 + cx, sr * x2 + cr * y2 + cy, z3 + cz)))
        faces = {"-z": (0, 3, 2, 1), "+z": (4, 5, 6, 7), "-y": (0, 1, 5, 4), "+x": (1, 2, 6, 5),
                 "+y": (2, 3, 7, 6), "-x": (3, 0, 4, 7)}
        for nm, idx in faces.items():
            c = col
            if cols and nm in cols:
                c = cols[nm]
            uv = None
            if decal and (nm == decal_face or decal_face == "all"):
                u0, v0, u1, v1 = decal_uv if decal_uv else (0, 0, 1, 1)
                uv = [cell_uv(decal, u0, v0), cell_uv(decal, u1, v0), cell_uv(decal, u1, v1), cell_uv(decal, u0, v1)]
            self.poly([out[i] for i in idx], c, uv, mat, out=(cx, cy, cz))

    def cyl(self, p0, p1, r0, r1, seg, col, caps=True, jitter=0.0, cols=None, rot0=0.0, mat=0):
        p0, p1 = Vector(p0), Vector(p1)
        ax = (p1 - p0)
        L = ax.length
        if L < 1e-6:
            return
        ax.normalize()
        ref = Vector((0, 0, 1)) if abs(ax.z) < 0.95 else Vector((1, 0, 0))
        u = ax.cross(ref).normalized()
        v = ax.cross(u).normalized()
        ring0, ring1 = [], []
        for i in range(seg):
            a = rot0 + math.tau * i / seg
            j = 1.0 + (self.rng.uniform(-jitter, jitter) if jitter else 0.0)
            d = (u * math.cos(a) + v * math.sin(a))
            ring0.append(p0 + d * r0 * j)
            ring1.append(p1 + d * r1 * j)
        mid = (p0 + p1) * 0.5
        for i in range(seg):
            k = (i + 1) % seg
            c = col if not cols else cols[i % len(cols)]
            self.poly([ring0[i], ring0[k], ring1[k], ring1[i]], c, None, mat, out=mid)
        if caps:
            if r1 > 1e-4:
                for i in range(seg):
                    self.poly([p1, ring1[(i + 1) % seg], ring1[i]], col, None, mat, out=mid)
            if r0 > 1e-4:
                for i in range(seg):
                    self.poly([p0, ring0[i], ring0[(i + 1) % seg]], col, None, mat, out=mid)

    def blob(self, center, radii, col, sub=1, noise=0.18, seed=0, colfn=None, flat_bottom=None, mat=0, facet=0.0):
        """Displaced icosphere. radii=(rx,ry,rz). colfn(p_local_normalised)->colour. flat_bottom: z below which verts clamp."""
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
        rng = random.Random(seed + 100)
        disp = {}
        for v in bm.verts:
            k = (round(v.co.x, 3), round(v.co.y, 3), round(v.co.z, 3))
            disp[k] = 1.0 + rng.uniform(-noise, noise)
        pts = {}
        for v in bm.verts:
            k = (round(v.co.x, 3), round(v.co.y, 3), round(v.co.z, 3))
            p = v.co * disp[k]
            p = Vector((p.x * radii[0], p.y * radii[1], p.z * radii[2]))
            if flat_bottom is not None:
                p.z = max(p.z, flat_bottom)
            pts[v.index] = p + Vector(center)
        for f in bm.faces:
            vs = [pts[v.index] for v in f.verts]
            nl = [v.co.normalized() for v in f.verts]
            if colfn:
                cs = [colfn(n) for n in nl]
            else:
                cs = col
            if facet:
                c = sum(vs, Vector()) / len(vs)
                vs = [c + (p - c) * (1.0 - facet) for p in vs]
            self.poly(vs, cs, None, mat, out=center)
        bm.free()

    def sheet(self, grid_pts, col, mat=0, flip=False):
        """Open grid of points [[Vector]] -> quads (no outward test)."""
        for i in range(len(grid_pts) - 1):
            for j in range(len(grid_pts[0]) - 1):
                q = [grid_pts[i][j], grid_pts[i + 1][j], grid_pts[i + 1][j + 1], grid_pts[i][j + 1]]
                if flip:
                    q = q[::-1]
                c = col(i, j) if callable(col) else col
                self.poly(q, c, None, mat)

    # ---- finalise ----
    def build(self, ao=True):
        bm = bmesh.new()
        vmap = {}
        lay = bm.loops.layers.float_color.new("Col") if hasattr(bm.loops.layers, "float_color") else None
        uvl = bm.loops.layers.uv.new("UVMap")
        blank = cell_uv("blank", 0.5, 0.5)
        for pts, cols, uv, mat in self.polys:
            vs = []
            cs2 = []
            uv2 = []
            for li, p in enumerate(pts):
                k = (round(p.x, 4), round(p.y, 4), round(p.z, 4))
                if k not in vmap:
                    vmap[k] = bm.verts.new(p)
                v_ = vmap[k]
                if v_ in vs:
                    continue
                vs.append(v_)
                cs2.append(cols[li])
                uv2.append(uv[li] if uv else None)
            if len(vs) < 3:
                continue
            cols = cs2
            uv = uv2 if uv else None
            try:
                f = bm.faces.new(vs)
            except ValueError:
                continue
            f.material_index = mat
            for li, lp in enumerate(f.loops):
                lp[lay] = (*cols[li], 1.0)
                lp[uvl].uv = uv[li] if uv else blank
        bm.normal_update()
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.normal_update()
        for e in bm.edges:
            if len(e.link_faces) == 2:
                e.smooth = e.calc_face_angle(0.0) < math.radians(self.sharp)
        bm.normal_update()
        if ao:
            self._bake_ao(bm, lay)
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        ntri = len(bm.faces)
        bm.free()
        for p in me.polygons:
            p.use_smooth = True
        return me, ntri

    def _bake_ao(self, bm, lay):
        bm.verts.ensure_lookup_table()
        tmp = bmesh.new()
        tmp.from_mesh(bpy.data.meshes.new("x")) if False else None
        bvh = BVHTree.FromBMesh(bm)
        rng = np.random.default_rng(5)
        dirs = []
        for i in range(14):
            u, v = rng.random(), rng.random()
            r = math.sqrt(u)
            th = math.tau * v
            dirs.append((r * math.cos(th), r * math.sin(th), math.sqrt(max(0.0, 1 - u))))
        for v in bm.verts:
            n = v.normal
            if n.length < 1e-6:
                continue
            t = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))).normalized()
            b = n.cross(t)
            hit = 0
            o = v.co + n * 0.03
            for d in dirs:
                w = t * d[0] + b * d[1] + n * d[2]
                if bvh.ray_cast(o, w, self.ao_dist)[0] is not None:
                    hit += 1
            ao = hit / len(dirs)
            k = 1.0 - self.ao_amt * ao
            if self.ground > 0:
                k *= 0.80 + 0.20 * min(1.0, max(0.0, v.co.z / self.ground))
            up = max(0.0, n.z - 0.6) / 0.4
            for lp in v.link_loops:
                c = lp[lay]
                col = (c[0] * k, c[1] * k, c[2] * k)
                if self.dust > 0:
                    col = mix(col, mul(DUST, k), self.dust * up)
                lp[lay] = (*col, 1.0)


def export_piece(km, outdir, ao=True, materials=("kit",)):
    me, ntri = km.build(ao=ao)
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = 0
    ob = bpy.data.objects.new(km.name, me)
    bpy.context.scene.collection.objects.link(ob)
    for mn in materials:
        m = bpy.data.materials.get(mn) or bpy.data.materials.new(mn)
        ob.data.materials.append(m)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=f"{outdir}/{km.name}.glb", export_format="GLB", use_selection=True,
                              export_vertex_color="ACTIVE", export_materials="EXPORT", export_apply=True,
                              export_yup=True, export_texcoords=True, export_normals=True,
                              export_animations=False, export_cameras=False, export_lights=False)
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    return ntri


def noise2(rng_seed, n=64):
    r = np.random.default_rng(rng_seed)
    return r.random(n)


def _torus(self, center, R, r, seg, sides, col, axis="z", mat=0):
    cx, cy, cz = center
    for i in range(seg):
        for j in range(sides):
            def P(ii, jj):
                a = math.tau * ii / seg
                b = math.tau * jj / sides
                rr = R + r * math.cos(b)
                x, y, z = rr * math.cos(a), rr * math.sin(a), r * math.sin(b)
                if axis == "y":
                    y, z = z, y
                elif axis == "x":
                    x, y, z = z, x, y
                return Vector((cx + x, cy + y, cz + z))
            self.poly([P(i, j), P(i + 1, j), P(i + 1, j + 1), P(i, j + 1)], col, None, mat, out=None)

KM.torus = _torus


def _lathe(self, center, prof, seg, col, mat=0, rot0=0.0, jitter=0.0, colfn=None):
    """Revolve [(radius, z), ...] about Z. col may be a colour or fn(z_frac)->colour."""
    cx, cy, cz = center
    rings = []
    for (r, z) in prof:
        ring = []
        for i in range(seg):
            a = rot0 + math.tau * i / seg
            q = r * (1.0 + (self.rng.uniform(-jitter, jitter) if jitter else 0.0))
            ring.append(Vector((cx + math.cos(a) * q, cy + math.sin(a) * q, cz + z)))
        rings.append(ring)
    zmax = max(p[1] for p in prof) or 1.0
    for k in range(len(prof) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            c = col(prof[k][1] / zmax) if callable(col) else col
            q = [rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]]
            if prof[k][0] < 1e-5:
                q = [rings[k][i], rings[k + 1][j], rings[k + 1][i]]
            elif prof[k + 1][0] < 1e-5:
                q = [rings[k][i], rings[k][j], rings[k + 1][i]]
            self.poly(q, c, None, mat, out=(cx, cy, cz + zmax * 0.5))

KM.lathe = _lathe
