"""Signed-distance anatomy (numba): smooth unions of round cones and ellipsoids, grouped by body part.

Used two ways:
  * high-poly: marching cubes of the union (+ procedural carapace detail) -> bake source
  * low-poly: game-topology loft vertices are projected onto their part's SDF surface so the clean quads
    follow the sculpted anatomy.
"""
import math
import numpy as np
from numba import njit, prange

RCONE, ELLIP, BOX = 0, 1, 2


class SDF:
    def __init__(self):
        self.prims = []      # rows: type, group, k, 18 params
        self.groups = []

    def gid(self, g):
        if g not in self.groups:
            self.groups.append(g)
        return self.groups.index(g)

    def rcone(self, a, b, ra, rb, group, k=0.03, sub=0.0):
        row = np.zeros(24)
        row[0], row[1], row[2], row[3] = RCONE, self.gid(group), k, sub
        row[4:7], row[7:10] = a, b
        row[10], row[11] = ra, rb
        self.prims.append(row)

    def ellip(self, c, r, group, k=0.03, rot=None, sub=0.0):
        row = np.zeros(24)
        row[0], row[1], row[2], row[3] = ELLIP, self.gid(group), k, sub
        row[4:7] = c
        row[7:10] = r
        R = np.eye(3) if rot is None else np.array(rot, dtype=np.float64).reshape(3, 3)
        row[10:19] = R.T.ravel()   # world -> local
        self.prims.append(row)

    def array(self):
        return np.array(self.prims, dtype=np.float64)

    def eval(self, P, groups=None, group_k=0.02):
        P = np.ascontiguousarray(P, dtype=np.float64)
        mask = np.ones(len(self.groups), dtype=np.int64)
        if groups is not None:
            mask[:] = 0
            for g in groups:
                if g in self.groups:
                    mask[self.groups.index(g)] = 1
        return _eval(P, self.array(), mask, len(self.groups), group_k)

    def project(self, P, groups, iters=6, group_k=0.02, max_move=0.08):
        """Move points onto the zero surface of the selected groups (Newton steps along the gradient)."""
        P = np.array(P, dtype=np.float64)
        P0 = P.copy()
        e = 1e-4
        for _ in range(iters):
            d = self.eval(P, groups, group_k)
            g = np.zeros_like(P)
            for ax in range(3):
                Q = P.copy()
                Q[:, ax] += e
                g[:, ax] = (self.eval(Q, groups, group_k) - d) / e
            n = np.linalg.norm(g, axis=1, keepdims=True) + 1e-9
            P = P - g / n * d[:, None]
        mv = P - P0
        L = np.linalg.norm(mv, axis=1, keepdims=True)
        P = P0 + mv * np.minimum(1.0, max_move / (L + 1e-9))
        return P


@njit(cache=True)
def _smin(a, b, k):
    if k <= 0.0:
        return min(a, b)
    h = max(k - abs(a - b), 0.0) / k
    return min(a, b) - h * h * k * 0.25


@njit(cache=True)
def _smax(a, b, k):
    return -_smin(-a, -b, k)


@njit(cache=True)
def _prim(p0, p1, p2, row):
    t = int(row[0])
    if t == 0:
        ax, ay, az = row[4], row[5], row[6]
        bx, by, bz = row[7], row[8], row[9]
        r1, r2 = row[10], row[11]
        # round cone (iq)
        bax, bay, baz = bx - ax, by - ay, bz - az
        l2 = bax * bax + bay * bay + baz * baz
        rr = r1 - r2
        a2 = l2 - rr * rr
        il2 = 1.0 / l2
        pax, pay, paz = p0 - ax, p1 - ay, p2 - az
        y = pax * bax + pay * bay + paz * baz
        z = y - l2
        xx = (pax * l2 - bax * y)
        xy = (pay * l2 - bay * y)
        xz = (paz * l2 - baz * y)
        x2 = xx * xx + xy * xy + xz * xz
        y2 = y * y * l2
        z2 = z * z * l2
        k = math.copysign(1.0, rr) * rr * rr * x2
        if math.copysign(1.0, z) * a2 * z2 > k:
            return math.sqrt(x2 + z2) * il2 - r2
        if math.copysign(1.0, y) * a2 * y2 < k:
            return math.sqrt(x2 + y2) * il2 - r1
        return (math.sqrt(x2 * a2 * il2) + y * rr) * il2 - r1
    elif t == 1:
        dx, dy, dz = p0 - row[4], p1 - row[5], p2 - row[6]
        lx = row[10] * dx + row[11] * dy + row[12] * dz
        ly = row[13] * dx + row[14] * dy + row[15] * dz
        lz = row[16] * dx + row[17] * dy + row[18] * dz
        rx, ry, rz = row[7], row[8], row[9]
        k0 = math.sqrt((lx / rx) ** 2 + (ly / ry) ** 2 + (lz / rz) ** 2)
        k1 = math.sqrt((lx / (rx * rx)) ** 2 + (ly / (ry * ry)) ** 2 + (lz / (rz * rz)) ** 2)
        if k1 < 1e-9:
            return -min(rx, min(ry, rz))
        return k0 * (k0 - 1.0) / k1
    return 1e9


@njit(parallel=True, cache=True)
def _eval(P, prims, mask, ngroups, group_k):
    n = P.shape[0]
    out = np.empty(n)
    for i in prange(n):
        p0, p1, p2 = P[i, 0], P[i, 1], P[i, 2]
        total = 1e9
        for g in range(ngroups):
            if mask[g] == 0:
                continue
            d = 1e9
            for j in range(prims.shape[0]):
                if int(prims[j, 1]) != g or prims[j, 3] != 0.0:
                    continue
                d = _smin(d, _prim(p0, p1, p2, prims[j]), prims[j, 2])
            for j in range(prims.shape[0]):
                if int(prims[j, 1]) != g or prims[j, 3] == 0.0:
                    continue
                d = _smax(d, -_prim(p0, p1, p2, prims[j]), prims[j, 3])
            total = _smin(total, d, group_k)
        out[i] = total
    return out


def marching(sdf, lo, hi, step, groups=None, group_k=0.02, detail=None):
    """Marching cubes over [lo,hi] with voxel size `step`. detail(P)->displacement added to the SDF."""
    from skimage import measure
    lo, hi = np.array(lo, float), np.array(hi, float)
    shape = np.ceil((hi - lo) / step).astype(int) + 1
    xs = lo[0] + np.arange(shape[0]) * step
    ys = lo[1] + np.arange(shape[1]) * step
    zs = lo[2] + np.arange(shape[2]) * step
    vol = np.empty(shape, dtype=np.float32)
    for k in range(shape[2]):
        X, Y = np.meshgrid(xs, ys, indexing="ij")
        P = np.stack([X.ravel(), Y.ravel(), np.full(X.size, zs[k])], 1)
        d = sdf.eval(P, groups, group_k)
        if detail is not None:
            d = d + detail(P, d)
        vol[:, :, k] = d.reshape(X.shape)
    verts, faces, normals, _ = measure.marching_cubes(vol, 0.0, spacing=(step, step, step))
    verts += lo
    return verts, faces
