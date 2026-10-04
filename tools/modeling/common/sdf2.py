"""Torch (CPU) signed-distance sculpting kit for the HQ character pipeline.

A field is any callable f(P) -> d, with P an (N,3) float32 tensor (Blender space: Z up, character faces -Y,
his LEFT is +X) and d an (N,) tensor (negative inside). Fields compose with plain Python:

    body = smooth_union([ellipsoid(...), capsule(...)], k=0.03)
    plate = shell_cut(ellipsoid(...), thick=0.01, region=halfspace(...))

mesh(f, lo, hi, step) runs a coarse-to-fine evaluation (exact only inside a narrow band around the surface)
and marching cubes -> (verts float32 (V,3), faces int32 (F,3)).

Noise (value fbm, ridged, voronoi F1/F2) is deterministic (integer lattice hashing), so builds are reproducible.
"""
import math

import numpy as np
import torch

torch.set_num_threads(4)
DT = torch.float32


def T(x):
    return torch.as_tensor(np.asarray(x, dtype=np.float32))


# ------------------------------------------------------------------------------------------------ primitives
def sphere(c, r):
    c = T(c)
    return lambda P: torch.linalg.norm(P - c, dim=1) - r


def rot_to(axis_from, axis_to):
    """3x3 rotation taking unit vector a to b (numpy)."""
    a = np.asarray(axis_from, float)
    b = np.asarray(axis_to, float)
    a /= np.linalg.norm(a)
    b /= np.linalg.norm(b)
    v = np.cross(a, b)
    c = float(a @ b)
    if np.linalg.norm(v) < 1e-9:
        return np.eye(3) if c > 0 else np.diag([1.0, -1.0, -1.0])
    vx = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + vx + vx @ vx * (1 / (1 + c))


def euler(rx=0.0, ry=0.0, rz=0.0):
    """XYZ euler (radians) -> 3x3 (numpy), local->world."""
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Rz @ Ry @ Rx


def ellipsoid(c, r, R=None):
    """Ellipsoid, radii r along local axes; R local->world (3x3)."""
    c = T(c)
    r = T(r)
    Rt = T(np.eye(3) if R is None else np.asarray(R, float))   # world->local is R^T: p_local = (p-c) @ R

    def f(P):
        L = (P - c) @ Rt
        k0 = torch.linalg.norm(L / r, dim=1)
        k1 = torch.linalg.norm(L / (r * r), dim=1)
        return k0 * (k0 - 1.0) / torch.clamp(k1, min=1e-9)
    return f


def capsule(a, b, ra, rb=None):
    """Round cone from a (radius ra) to b (radius rb)."""
    rb = ra if rb is None else rb
    a_ = np.asarray(a, float)
    b_ = np.asarray(b, float)
    ba = T(b_ - a_)
    a = T(a_)
    l2 = float((b_ - a_) @ (b_ - a_))
    rr = ra - rb
    a2 = l2 - rr * rr
    il2 = 1.0 / l2

    def f(P):
        pa = P - a
        y = pa @ ba
        z = y - l2
        x = pa * l2 - ba[None, :] * y[:, None]
        x2 = (x * x).sum(1)
        y2 = y * y * l2
        z2 = z * z * l2
        k = math.copysign(1.0, rr) * rr * rr * x2
        d_mid = (torch.sqrt(x2 * a2 * il2) + y * rr) * il2 - ra
        d_b = torch.sqrt(x2 + z2) * il2 - rb
        d_a = torch.sqrt(x2 + y2) * il2 - ra
        out = d_mid
        out = torch.where(torch.sign(y) * a2 * y2 < k, d_a, out)
        out = torch.where(torch.sign(z) * a2 * z2 > k, d_b, out)
        return out
    return f


def tube(points, radii, k=0.0):
    """Polyline of round cones (horns, fingers, straps, haft)."""
    fs = [capsule(points[i], points[i + 1], radii[i], radii[i + 1]) for i in range(len(points) - 1)]
    return smooth_union(fs, k) if k > 0 else union(fs)


def rbox(c, half, r=0.0, R=None):
    c = T(c)
    h = T(np.asarray(half, float) - r)
    Rt = T(np.eye(3) if R is None else np.asarray(R, float))

    def f(P):
        q = torch.abs((P - c) @ Rt) - h
        return torch.linalg.norm(torch.clamp(q, min=0), dim=1) + torch.clamp(q.max(1).values, max=0) - r
    return f


def halfspace(n, p0):
    """Negative on the side the normal n points AWAY from (inside = {x: n.(x-p0) < 0})."""
    n = np.asarray(n, float)
    n = T(n / np.linalg.norm(n))
    p0 = T(p0)
    return lambda P: (P - p0) @ n


def torus(c, R_major, r_minor, Rm=None):
    c = T(c)
    Rt = T(np.eye(3) if Rm is None else np.asarray(Rm, float))

    def f(P):
        L = (P - c) @ Rt
        q = torch.sqrt(L[:, 0] ** 2 + L[:, 1] ** 2) - R_major
        return torch.sqrt(q * q + L[:, 2] ** 2) - r_minor
    return f


def cone_spike(base, tip, r_base, r_tip=0.002):
    return capsule(base, tip, r_base, r_tip)


# ------------------------------------------------------------------------------------------------ operators
def union(fs):
    def f(P):
        d = fs[0](P)
        for g in fs[1:]:
            d = torch.minimum(d, g(P))
        return d
    return f


def _smin(a, b, k):
    h = torch.clamp(k - torch.abs(a - b), min=0) / k
    return torch.minimum(a, b) - h * h * k * 0.25


def smooth_union(fs, k=0.02):
    if k <= 0:
        return union(fs)

    def f(P):
        d = fs[0](P)
        for g in fs[1:]:
            d = _smin(d, g(P), k)
        return d
    return f


def smin2(a, b, k):
    return lambda P: _smin(a(P), b(P), k)


def intersect(a, b, k=0.0):
    if k <= 0:
        return lambda P: torch.maximum(a(P), b(P))
    return lambda P: -_smin(-a(P), -b(P), k)


def subtract(a, b, k=0.0):
    """a minus b."""
    if k <= 0:
        return lambda P: torch.maximum(a(P), -b(P))
    return lambda P: -_smin(-a(P), b(P), k)


def offset(a, o):
    return lambda P: a(P) - o


def shell(a, thick):
    """Thick shell centred on a's surface."""
    return lambda P: torch.abs(a(P)) - thick * 0.5


def shell_cut(base, thick, region, k=0.006, lift=0.0):
    """Plate: a shell of thickness `thick` whose INNER face sits `lift` outside base's surface, clipped to region
    (negative inside) with rounded (bevelled) edges of radius k."""
    sh = lambda P: torch.abs(base(P) - lift - thick * 0.5) - thick * 0.5
    return intersect(sh, region, k)


def displace(a, fn, amp=1.0):
    return lambda P: a(P) - amp * fn(P)


def mirror_x(a):
    def f(P):
        Q = P.clone()
        Q[:, 0] = torch.abs(Q[:, 0])
        return a(Q)
    return f


def transform(a, R=None, t=(0, 0, 0)):
    """Field a defined in local coords, placed at world x = R @ local + t."""
    Rt = T(np.eye(3) if R is None else np.asarray(R, float))
    t = T(t)
    return lambda P: a((P - t) @ Rt)


def bbox_guard(a, lo, hi, pad=0.05):
    """Skip evaluation of `a` for points well outside its bounding box (returns the box distance instead)."""
    lo = T(np.asarray(lo) - pad)
    hi = T(np.asarray(hi) + pad)

    def f(P):
        q = torch.maximum(lo - P, P - hi)
        out = torch.linalg.norm(torch.clamp(q, min=0), dim=1) + pad
        m = (q.max(1).values <= 0)
        if m.any():
            out[m] = a(P[m])
        return out
    return f


# ------------------------------------------------------------------------------------------------ noise
_PERM = None


def _table():
    global _PERM
    if _PERM is None:
        rng = np.random.default_rng(1234)
        _PERM = T(rng.uniform(-1, 1, size=(65536, 3)))
    return _PERM


def _hash(ix, iy, iz, seed):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)
    h = h ^ (h >> 13)
    h = h * 1274126177
    h = h ^ (h >> 16)
    return h & 65535


def vnoise(P, freq=1.0, seed=0):
    """Value noise in [-1,1] (quintic interpolation)."""
    tab = _table()
    Q = P * freq
    i0 = torch.floor(Q)
    fq = Q - i0
    u = fq * fq * fq * (fq * (fq * 6 - 15) + 10)
    i0 = i0.to(torch.int64)
    out = torch.zeros(len(P), dtype=DT)
    for dx in (0, 1):
        wx = u[:, 0] if dx else 1 - u[:, 0]
        for dy in (0, 1):
            wy = u[:, 1] if dy else 1 - u[:, 1]
            for dz in (0, 1):
                wz = u[:, 2] if dz else 1 - u[:, 2]
                h = _hash(i0[:, 0] + dx, i0[:, 1] + dy, i0[:, 2] + dz, seed)
                out = out + wx * wy * wz * tab[h, 0]
    return out


def fbm(P, freq=1.0, octaves=4, seed=0, gain=0.5, lac=2.03):
    amp, tot = 1.0, 0.0
    out = torch.zeros(len(P), dtype=DT)
    for o in range(octaves):
        out = out + amp * vnoise(P, freq * lac ** o, seed + 17 * o)
        tot += amp
        amp *= gain
    return out / tot


def ridged(P, freq=1.0, octaves=3, seed=0):
    amp, tot = 1.0, 0.0
    out = torch.zeros(len(P), dtype=DT)
    for o in range(octaves):
        out = out + amp * (1 - torch.abs(vnoise(P, freq * 2.0 ** o, seed + 31 * o)))
        tot += amp
        amp *= 0.5
    return out / tot


def voronoi(P, freq=1.0, seed=0, jitter=0.9):
    """Returns (F1, F2) distances (in cell units)."""
    tab = _table()
    Q = P * freq
    i0 = torch.floor(Q).to(torch.int64)
    f1 = torch.full((len(P),), 9.0, dtype=DT)
    f2 = torch.full((len(P),), 9.0, dtype=DT)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                cx, cy, cz = i0[:, 0] + dx, i0[:, 1] + dy, i0[:, 2] + dz
                h = _hash(cx, cy, cz, seed)
                fp = torch.stack([cx, cy, cz], 1).to(DT) + 0.5 + 0.5 * jitter * tab[h]
                d = torch.linalg.norm(Q - fp, dim=1)
                f2 = torch.where(d < f1, f1, torch.minimum(f2, d))
                f1 = torch.minimum(f1, d)
    return f1, f2


# ------------------------------------------------------------------------------------------------ meshing
def _grid(lo, step, shape):
    xs = lo[0] + np.arange(shape[0]) * step
    ys = lo[1] + np.arange(shape[1]) * step
    zs = lo[2] + np.arange(shape[2]) * step
    return xs, ys, zs


def evaluate(f, P, chunk=400000):
    out = torch.empty(len(P), dtype=DT)
    with torch.no_grad():
        for s in range(0, len(P), chunk):
            out[s:s + chunk] = f(P[s:s + chunk])
    return out


def volume(f, lo, hi, step, coarse=4):
    """Coarse-to-fine sampled SDF volume (numpy float32, shape (nx,ny,nz))."""
    lo = np.asarray(lo, float)
    hi = np.asarray(hi, float)
    cstep = step * coarse
    cshape = np.ceil((hi - lo) / cstep).astype(int) + 2
    xs, ys, zs = _grid(lo, cstep, cshape)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    P = T(np.stack([X.ravel(), Y.ravel(), Z.ravel()], 1))
    dc = evaluate(f, P).reshape(tuple(cshape))
    shape = (cshape - 1) * coarse + 1
    fine = torch.nn.functional.interpolate(dc[None, None], size=tuple(int(s) for s in shape), mode="trilinear",
                                           align_corners=True)[0, 0]
    band = fine.abs() < cstep * 1.8
    idx = torch.nonzero(band)
    if len(idx):
        Pf = idx.to(DT) * step + T(lo)
        fine[band] = evaluate(f, Pf)
    return fine.numpy(), lo


def mesh(f, lo, hi, step, coarse=4):
    from skimage import measure
    vol, lo = volume(f, lo, hi, step, coarse)
    if vol.min() > 0 or vol.max() < 0:
        return np.zeros((0, 3), np.float32), np.zeros((0, 3), np.int32)
    v, fc, _, _ = measure.marching_cubes(vol, 0.0, spacing=(step, step, step))
    v = (v + lo).astype(np.float32)
    # skimage winding (descent) is already CCW-outward for an SDF (negative inside)
    return v, fc.astype(np.int32)


def auto_bounds(f, lo, hi, step=0.02):
    """Tighten a bbox to the field's negative region (coarse)."""
    lo = np.asarray(lo, float)
    hi = np.asarray(hi, float)
    shape = np.ceil((hi - lo) / step).astype(int) + 1
    xs, ys, zs = _grid(lo, step, shape)
    X, Y, Z = np.meshgrid(xs, ys, zs, indexing="ij")
    P = T(np.stack([X.ravel(), Y.ravel(), Z.ravel()], 1))
    d = evaluate(f, P).numpy().reshape(tuple(shape))
    m = d < step
    if not m.any():
        return None
    ii = [np.where(m.any(axis=tuple(a for a in range(3) if a != ax)))[0] for ax in range(3)]
    blo = np.array([xs[ii[0][0]], ys[ii[1][0]], zs[ii[2][0]]]) - 2 * step
    bhi = np.array([xs[ii[0][-1]], ys[ii[1][-1]], zs[ii[2][-1]]]) + 2 * step
    return np.maximum(blo, lo), np.minimum(bhi, hi)
