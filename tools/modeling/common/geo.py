"""Procedural game-topology mesh builder (pure python + mathutils), used by the character build scripts.

A MeshBuilder accumulates quads/tris with per-corner UVs, a material slot and a named *part* per face.
Primitives:
  loft()     -- tube through rings (limbs, neck, torso, horns, haft). Superellipse / custom cross-sections.
  shell()    -- dome / plate (pauldrons, knee plates, carapace plates) as a lofted cap with thickness.
  ribbon()   -- single-sided strip along a curve (cloth strips, bandages, fringe, leaf panels).
  sphere()   -- UV sphere / ellipsoid.
  cone()     -- spikes / claws.
Parts are later used for rigid skinning, painting and UV density.
"""
import math
from mathutils import Vector, Matrix

TAU = math.tau


def V(*a):
    if len(a) == 1:
        return Vector(a[0])
    return Vector(a)


def lerp(a, b, t):
    return a + (b - a) * t


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a))) if b != a else 0.0
    return t * t * (3 - 2 * t)


def catmull(points, samples):
    """Catmull-Rom resample of a polyline (list of Vector) to `samples` points (uniform in parameter)."""
    pts = [Vector(p) for p in points]
    if len(pts) == 2:
        return [pts[0].lerp(pts[1], i / (samples - 1)) for i in range(samples)]
    ext = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
    segs = len(pts) - 1
    out = []
    for i in range(samples):
        t = i / (samples - 1) * segs
        k = min(int(t), segs - 1)
        u = t - k
        p0, p1, p2, p3 = ext[k], ext[k + 1], ext[k + 2], ext[k + 3]
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u +
                          (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u))
    return out


def interp(vals, t):
    """Piecewise-linear interpolation of a list of floats (or a single float) at t in [0,1]."""
    if not isinstance(vals, (list, tuple)):
        return vals
    if len(vals) == 1:
        return vals[0]
    x = t * (len(vals) - 1)
    k = min(int(x), len(vals) - 2)
    u = x - k
    a, b = vals[k], vals[k + 1]
    return a + (b - a) * (u * u * (3 - 2 * u)) if isinstance(a, float) or isinstance(a, int) else a.lerp(b, u)


def frames(path, side_hint, front_hint):
    """Parallel-transport frames along path. Returns list of (T, X, Y): X ~ side_hint, Y ~ front_hint."""
    n = len(path)
    Ts = []
    for i in range(n):
        if i == 0:
            t = path[1] - path[0]
        elif i == n - 1:
            t = path[-1] - path[-2]
        else:
            t = path[i + 1] - path[i - 1]
        Ts.append(t.normalized())
    out = []
    X = Vector(side_hint)
    X = (X - X.dot(Ts[0]) * Ts[0])
    if X.length < 1e-6:
        X = Vector(front_hint).cross(Ts[0])
    X.normalize()
    for i in range(n):
        T = Ts[i]
        if i > 0:
            # parallel transport
            X = X - X.dot(T) * T
            if X.length < 1e-8:
                X = out[-1][1]
            X.normalize()
        Y = T.cross(X).normalized()
        out.append((T, X.copy(), Y))
    # make Y point roughly along front_hint (flip X too to keep handedness consistent with winding fix)
    fh = Vector(front_hint)
    s = sum(f[2].dot(fh) for f in out)
    if s < 0:
        out = [(T, -X, -Y) for (T, X, Y) in out]
    return out


class MeshBuilder:
    def __init__(self):
        self.verts = []
        self.faces = []      # (idx tuple, uv tuple, mat, part)
        self.parts = []
        self.island_scale = {}

    def part_id(self, part):
        if part not in self.parts:
            self.parts.append(part)
        return self.parts.index(part)

    def add_v(self, p):
        self.verts.append(Vector(p))
        return len(self.verts) - 1

    def face(self, idx, uvs, mat, part):
        self.faces.append((tuple(idx), tuple(tuple(u) for u in uvs), mat, self.part_id(part)))

    # ------------------------------------------------------------------ loft
    def loft(self, path, rx, ry, n=12, part="part", mat=0, side=(1, 0, 0), front=(0, -1, 0), power=2.0,
             cap0="flat", cap1="flat", shape=None, samples=None, twist=0.0, seam=0.5, ring_fn=None,
             offset=None):
        """Tube along `path` (list of points). rx/ry: radius along frame X (side) / Y (front), float or list
        (interpolated along length). power: superellipse exponent (2 = ellipse, >2 boxier).
        shape(t_along, theta, x, y) -> (x, y) custom deformation.  seam: angle fraction where the UV seam sits
        (0.5 = +Y side... i.e. theta=pi). Returns list of ring vertex index lists."""
        path = [Vector(p) for p in path]
        if samples:
            path = catmull(path, samples)
        fr = frames(path, side, front)
        m = len(path)
        lens = [0.0]
        for i in range(1, m):
            lens.append(lens[-1] + (path[i] - path[i - 1]).length)
        L = lens[-1] if lens[-1] > 0 else 1.0
        rings = []
        circ = []
        for k in range(m):
            t = lens[k] / L
            T, X, Y = fr[k]
            a = interp(rx, t)
            b = interp(ry, t)
            pw = interp(power, t)
            tw = interp(twist, t)
            off = Vector(interp(offset, t)) if offset is not None else Vector((0, 0, 0))
            ring = []
            pts2 = []
            for i in range(n):
                th = TAU * (i / n + seam) + tw
                c, s = math.cos(th), math.sin(th)
                x = math.copysign(abs(c) ** (2.0 / pw), c) * a
                y = math.copysign(abs(s) ** (2.0 / pw), s) * b
                if shape:
                    x, y = shape(t, th % TAU, x, y)
                p = path[k] + X * x + Y * y + off
                if ring_fn:
                    p = ring_fn(t, th % TAU, p)
                pts2.append(p)
            per = sum((pts2[i] - pts2[(i + 1) % n]).length for i in range(n))
            circ.append(per)
            ring = [self.add_v(p) for p in pts2]
            rings.append(ring)
        C = sum(circ) / len(circ)
        # orientation check: first quad normal should point outward
        flip = False
        if m > 1:
            p0, p1, p2 = self.verts[rings[0][0]], self.verts[rings[0][1]], self.verts[rings[1][0]]
            nrm = (p1 - p0).cross(p2 - p0)
            if nrm.dot(p0 - path[0]) < 0:
                flip = True
        for k in range(m - 1):
            for i in range(n):
                j = (i + 1) % n
                a, b, c, d = rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]
                u0, u1 = i / n * C, (i + 1) / n * C
                v0, v1 = lens[k], lens[k + 1]
                q = [a, b, c, d]
                uv = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
                if flip:
                    q.reverse()
                    uv.reverse()
                self.face(q, uv, mat, part)
        self._cap(rings[0], path[0], fr[0][0], cap0, mat, part, flip, start=True, L=lens)
        self._cap(rings[-1], path[-1], fr[-1][0], cap1, mat, part, flip, start=False, L=lens)
        return rings

    def _cap(self, ring, center, T, kind, mat, part, flip, start, L):
        if not kind:
            return
        n = len(ring)
        pts = [self.verts[i] for i in ring]
        cen = sum(pts, Vector()) / n
        r = max((p - cen).length for p in pts) or 1.0
        if kind == "point" or isinstance(kind, (int, float)) and not isinstance(kind, bool):
            ext = 0.0 if kind == "point" else float(kind)
            tip = self.add_v(cen + (-T if start else T) * ext)
            for i in range(n):
                j = (i + 1) % n
                tri = [ring[i], ring[j], tip]
                uvs = [(0.5 + 0.5 * (pts[i] - cen).length / r * math.cos(TAU * i / n) * 0.0 + i / n, 0.0),
                       ((i + 1) / n, 0.0), ((i + 0.5) / n, 0.2)]
                if start != flip:
                    tri.reverse()
                    uvs.reverse()
                self.face(tri, uvs, mat, part)
            return
        # flat fan cap (triangles) with planar UVs
        c = self.add_v(cen)
        axis = T
        X = (pts[0] - cen)
        X = (X - X.dot(axis) * axis).normalized()
        Y = axis.cross(X)
        def puv(p):
            d = p - cen
            return (d.dot(X) + r, d.dot(Y) + r)
        for i in range(n):
            j = (i + 1) % n
            tri = [ring[i], ring[j], c]
            uvs = [puv(pts[i]), puv(pts[j]), (r, r)]
            if start != flip:
                tri.reverse()
                uvs.reverse()
            self.face(tri, uvs, mat, part)

    # ------------------------------------------------------------------ ribbon
    def ribbon(self, path, width, part, mat=1, normal_hint=(0, -1, 0), samples=None, across=1,
               curl=0.0, width_fn=None, offset_fn=None):
        """Strip along path; `width` float/list; across = quads across. normal_hint: which side faces out.
        curl: bends the strip cross-section (fraction of width as sag)."""
        path = [Vector(p) for p in path]
        if samples:
            path = catmull(path, samples)
        m = len(path)
        lens = [0.0]
        for i in range(1, m):
            lens.append(lens[-1] + (path[i] - path[i - 1]).length)
        L = lens[-1] or 1.0
        nh = Vector(normal_hint).normalized()
        rows = []
        Wmax = 0.0
        for k in range(m):
            t = lens[k] / L
            T = (path[min(k + 1, m - 1)] - path[max(k - 1, 0)]).normalized()
            S = T.cross(nh)
            if S.length < 1e-6:
                S = T.orthogonal()
            S.normalize()
            N = S.cross(T).normalized()
            if N.dot(nh) < 0:
                S = -S
                N = -N
            w = interp(width, t)
            if width_fn:
                w = width_fn(t, w)
            Wmax = max(Wmax, w)
            row = []
            for a in range(across + 1):
                s = a / across - 0.5
                p = path[k] + S * (s * w) + N * (curl * w * (0.25 - s * s))
                if offset_fn:
                    p = offset_fn(t, s, p)
                row.append(self.add_v(p))
            rows.append((row, w))
        for k in range(m - 1):
            for a in range(across):
                q = [rows[k][0][a], rows[k][0][a + 1], rows[k + 1][0][a + 1], rows[k + 1][0][a]]
                uv = [(a / across * Wmax, lens[k]), ((a + 1) / across * Wmax, lens[k]),
                      ((a + 1) / across * Wmax, lens[k + 1]), (a / across * Wmax, lens[k + 1])]
                # want normal along N: (b-a)x(d-a) = S x T ... S x T = -N -> reverse
                q.reverse()
                uv.reverse()
                self.face(q, uv, mat, part)
        return rows

    # ------------------------------------------------------------------ sphere / ellipsoid
    def sphere(self, center, radii, part, mat=0, n=12, rings=8, rot=None, deform=None):
        c = Vector(center)
        R = rot if rot is not None else Matrix.Identity(3)
        if isinstance(radii, (int, float)):
            radii = (radii, radii, radii)
        top = self.add_v(c + R @ Vector((0, 0, radii[2])))
        bot = self.add_v(c + R @ Vector((0, 0, -radii[2])))
        grid = []
        for r in range(1, rings):
            ph = math.pi * r / rings
            row = []
            for i in range(n):
                th = TAU * i / n
                d = Vector((math.sin(ph) * math.cos(th) * radii[0], math.sin(ph) * math.sin(th) * radii[1],
                            math.cos(ph) * radii[2]))
                if deform:
                    d = deform(ph, th, d)
                row.append(self.add_v(c + R @ d))
            grid.append(row)
        C = TAU * max(radii[0], radii[1])
        H = math.pi * radii[2]
        def uv(i, r):
            return (i / n * C, (1 - r / rings) * H)
        for i in range(n):
            j = (i + 1) % n
            self.face([top, grid[0][j], grid[0][i]][::-1][::-1], [uv(i + 0.5, 0), uv(i + 1, 1), uv(i, 1)], mat, part)
        for r in range(len(grid) - 1):
            for i in range(n):
                j = (i + 1) % n
                self.face([grid[r][i], grid[r][j], grid[r + 1][j], grid[r + 1][i]][::-1],
                          [uv(i, r + 1), uv(i + 1, r + 1), uv(i + 1, r + 2), uv(i, r + 2)][::-1], mat, part)
        last = grid[-1]
        for i in range(n):
            j = (i + 1) % n
            self.face([last[i], last[j], bot][::-1], [uv(i, rings - 1), uv(i + 1, rings - 1), uv(i + 0.5, rings)][::-1],
                      mat, part)
        return grid

    # ------------------------------------------------------------------ cone (spike / claw)
    def cone(self, base, tip, r, part, mat=0, n=6, bend=None, segs=3, r_tip=0.0, side=(1, 0, 0), front=(0, -1, 0),
             cap0="flat"):
        base, tip = Vector(base), Vector(tip)
        segs = max(segs, 2)
        pts = [base.lerp(tip, i / segs) for i in range(segs + 1)]
        if bend is not None:
            b = Vector(bend)
            pts = [p + b * math.sin(math.pi * 0.5 * i / segs) ** 2 for i, p in enumerate(pts)]
        rs = [r * (1 - i / segs) + r_tip * (i / segs) for i in range(segs + 1)]
        if r_tip <= 0:
            rings = self.loft(pts[:-1], rs[:-1], rs[:-1], n=n, part=part, mat=mat, side=side, front=front,
                              cap0=cap0, cap1=None)
            # tip
            tipi = self.add_v(pts[-1])
            ring = rings[-1]
            p0 = self.verts[ring[0]]
            for i in range(n):
                j = (i + 1) % n
                tri = [ring[i], ring[j], tipi]
                a, b2, c = self.verts[ring[i]], self.verts[ring[j]], pts[-1]
                if (b2 - a).cross(c - a).dot(a - pts[-2]) < 0:
                    tri = tri[::-1]
                self.face(tri, [(i / n * r * 6, 0), ((i + 1) / n * r * 6, 0), ((i + .5) / n * r * 6, r * 3)], mat, part)
            return rings
        return self.loft(pts, rs, rs, n=n, part=part, mat=mat, side=side, front=front, cap0=cap0, cap1="flat")

    # ------------------------------------------------------------------ transforms / merge
    def transform_part_verts(self, start_v, M):
        for i in range(start_v, len(self.verts)):
            self.verts[i] = M @ self.verts[i]

    def mirror_from(self, start_v, start_f, part_map):
        """Duplicate verts/faces added since (start_v, start_f) mirrored in X; part names remapped."""
        off = len(self.verts) - start_v
        for i in range(start_v, len(self.verts) - 0 if False else start_v + off):
            p = self.verts[i]
            self.verts.append(Vector((-p.x, p.y, p.z)))
        nf = len(self.faces)
        for f in self.faces[start_f:nf]:
            idx, uvs, mat, pid = f
            name = self.parts[pid]
            self.faces.append((tuple(i + off for i in idx[::-1]), tuple(uvs[::-1]), mat,
                               self.part_id(part_map(name))))

    def tri_count(self, part_prefix=None):
        n = 0
        for idx, _, _, pid in self.faces:
            if part_prefix and not self.parts[pid].startswith(part_prefix):
                continue
            n += len(idx) - 2
        return n
