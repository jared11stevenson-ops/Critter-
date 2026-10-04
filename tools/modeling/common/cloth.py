"""Draped cloth sheets for the HQ pipeline.

A Sheet is a parametric surface shape(u, v) -> (..., 3) (u across, v down, both 0..1), draped against a collider
SDF (points pushed out to `gap`, then Laplacian-smoothed, a few iterations). Two meshes are produced from the
SAME draped surface:
  low  : nu x nv grid, single-sided, per-vertex param (u, v) -> alpha (torn edges) is evaluated per texel later
  high : bicubic-refined grid + fine wrinkle displacement, solidified to `thick` (bake source)
"""
import numpy as np
import torch

from . import sdf2


class Sheet:
    def __init__(self, name, shape, kind="cloth", bind="auto", nu=8, nv=12, thick=0.005, gap=0.012,
                 folds=None, wrinkle=0.0015, alpha=None, iters=6, smooth=0.35, pin_top=True, budget=None):
        self.name, self.shape, self.kind, self.bind = name, shape, kind, bind
        self.nu, self.nv, self.thick, self.gap = nu, nv, thick, gap
        self.folds = folds              # fn(u, v) -> normal offset (m), large folds (in low AND high)
        self.wrinkle = wrinkle          # fine wrinkle amplitude (high only)
        self.alpha = alpha              # fn(u, v) -> 0/1 coverage (torn edges, leaf outlines)
        self.iters, self.smooth, self.pin_top = iters, smooth, pin_top


def _grid_normals(P):
    du = np.gradient(P, axis=1)
    dv = np.gradient(P, axis=0)
    n = np.cross(du, dv)
    return n / np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-12)


def _collide(P, collider, gap):
    flat = P.reshape(-1, 3)
    X = sdf2.T(flat)
    d = sdf2.evaluate(collider, X).numpy()
    bad = d < gap
    if bad.any():
        Q = X[bad]
        e = 1e-3
        g = np.zeros((int(bad.sum()), 3), np.float32)
        d0 = d[bad]
        for ax in range(3):
            Q2 = Q.clone()
            Q2[:, ax] += e
            g[:, ax] = (sdf2.evaluate(collider, Q2).numpy() - d0) / e
        g /= np.maximum(np.linalg.norm(g, axis=1, keepdims=True), 1e-9)
        flat = flat.copy()
        flat[bad] += g * (gap - d0)[:, None]
    return flat.reshape(P.shape)


def drape(sheet, collider, nu, nv):
    u = np.linspace(0, 1, nu)
    v = np.linspace(0, 1, nv)
    U, Vv = np.meshgrid(u, v)                    # (nv, nu)
    P = sheet.shape(U, Vv).astype(np.float64)
    top = P[0].copy()
    for it in range(sheet.iters):
        if collider is not None:
            P = _collide(P, collider, sheet.gap)
        # Laplacian smoothing (keeps the cloth from kinking where the collider pushed it)
        Q = P.copy()
        Q[1:-1, 1:-1] = (P[:-2, 1:-1] + P[2:, 1:-1] + P[1:-1, :-2] + P[1:-1, 2:]) / 4
        Q[1:-1, 0] = (P[:-2, 0] + P[2:, 0]) / 2
        Q[1:-1, -1] = (P[:-2, -1] + P[2:, -1]) / 2
        P = P + (Q - P) * sheet.smooth
        if sheet.pin_top:
            P[0] = top
    if collider is not None:
        P = _collide(P, collider, sheet.gap)
    if sheet.folds is not None:
        N = _grid_normals(P)
        P = P + N * sheet.folds(U, Vv)[..., None]
        if collider is not None:
            P = _collide(P, collider, sheet.gap * 0.6)
    return P, U, Vv


def _grid_faces(nv, nu, off=0, flip=False):
    i, j = np.meshgrid(np.arange(nv - 1), np.arange(nu - 1), indexing="ij")
    a = (i * nu + j).ravel() + off
    b = a + 1
    c = a + nu + 1
    d = a + nu
    if flip:
        return np.concatenate([np.stack([a, c, b], 1), np.stack([a, d, c], 1)])
    return np.concatenate([np.stack([a, b, c], 1), np.stack([a, c, d], 1)])


def low_mesh(sheet, collider):
    P, U, Vv = drape(sheet, collider, sheet.nu, sheet.nv)
    V = P.reshape(-1, 3).astype(np.float32)
    F = _grid_faces(sheet.nv, sheet.nu)
    UV = np.stack([U.ravel(), Vv.ravel()], 1).astype(np.float32)
    return V, F.astype(np.int32), UV, P


def _refine(P, k):
    """Bicubic-ish refinement of a (nv, nu, 3) grid by factor k (Catmull-Rom along each axis)."""
    import scipy.interpolate as si
    nv, nu, _ = P.shape
    v0 = np.linspace(0, 1, nv)
    u0 = np.linspace(0, 1, nu)
    v1 = np.linspace(0, 1, (nv - 1) * k + 1)
    u1 = np.linspace(0, 1, (nu - 1) * k + 1)
    out = np.zeros((len(v1), len(u1), 3))
    for c in range(3):
        kx = min(3, nu - 1)
        ky = min(3, nv - 1)
        sp = si.RectBivariateSpline(v0, u0, P[..., c], kx=ky, ky=kx, s=0)
        out[..., c] = sp(v1, u1)
    return out, v1, u1


def high_mesh(sheet, low_grid, k=8, seed=0):
    P, v1, u1 = _refine(low_grid, k)
    U, Vv = np.meshgrid(u1, v1)
    N = _grid_normals(P)
    if sheet.wrinkle > 0:
        X = sdf2.T(P.reshape(-1, 3))
        # stretched noise: wrinkles run mostly along v (hanging) -> compress the noise along the gravity axis
        Xs = X * sdf2.T([1.0, 1.0, 0.35])
        w = (sdf2.fbm(Xs, 30.0, 3, seed) + 0.6 * sdf2.ridged(Xs, 55.0, 2, seed + 1) - 0.4).numpy()
        P = P + N * (w.reshape(P.shape[:2]) * sheet.wrinkle)[..., None]
        N = _grid_normals(P)
    nv, nu = P.shape[:2]
    t = sheet.thick * 0.5
    A = (P + N * t).reshape(-1, 3)
    B = (P - N * t).reshape(-1, 3)
    V = np.concatenate([A, B]).astype(np.float32)
    n = nv * nu
    F = [_grid_faces(nv, nu), _grid_faces(nv, nu, n, flip=True)]
    # side walls
    idx = np.arange(n).reshape(nv, nu)
    rims = [idx[0, :], idx[-1, ::-1], idx[::-1, 0], idx[:, -1]]
    for r in rims:
        a, b = r[:-1], r[1:]
        F.append(np.stack([a, b + n, b], 1))
        F.append(np.stack([a, a + n, b + n], 1))
    UV = np.stack([U.ravel(), Vv.ravel()], 1)
    UV = np.concatenate([UV, UV]).astype(np.float32)
    return V, np.concatenate(F).astype(np.int32), UV


def torn_edge(seed, depth=0.08, freq=9.0, bottom=1.0, sides=0.0):
    """alpha(u, v): jagged torn bottom edge (v near `bottom`) + optional ragged sides + a few holes."""
    rng = np.random.default_rng(seed)
    ph = rng.uniform(0, 6.28, 4)

    def a(u, v):
        jag = depth * (0.5 + 0.3 * np.sin(u * freq * 6.28 + ph[0]) + 0.2 * np.sin(u * freq * 2.3 * 6.28 + ph[1])
                       + 0.25 * np.abs(np.sin(u * freq * 5.1 * 6.28 + ph[2])))
        ok = v < bottom - jag
        if sides > 0:
            sj = sides * (0.5 + 0.5 * np.sin(v * 23 + ph[3]))
            ok &= (u > sj) & (u < 1 - sj)
        return ok.astype(np.float32)
    return a
