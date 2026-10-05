"""Object-space texture painting kit (Aruun v3 / Cigarra v2).
bake(): rasterise the mesh into UV space once -> per-texel world position/normal/triangle (seams are invisible because every
colour is a function of 3D position, never of UV).  Then paint with plain numpy functions of (P, N, kind) and write the maps."""
import os, sys
import numpy as np
from scipy.spatial import cKDTree
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
from common import raster


def vertex_normals(V, T):
    n = np.zeros_like(V, dtype=np.float64)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for k in range(3):
        np.add.at(n, T[:, k], fn)
    return (n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)).astype(np.float32)


class Bake:
    def __init__(self, V, T, UV, size=2048, sparam=None):
        self.S = size
        tid, bary = raster.uv_raster(UV.astype(np.float64), T, size)
        ys, xs = np.where(tid >= 0)
        self.ys, self.xs = ys, xs
        t = tid[ys, xs]; b = bary[ys, xs]
        self.tri = t
        tv = T[t]
        self.P = np.einsum("nk,nkc->nc", b, V[tv]).astype(np.float64)
        N = vertex_normals(V, T)
        n = np.einsum("nk,nkc->nc", b, N[tv]); self.N = n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        self.sp = np.einsum("nk,nk->n", b, sparam[tv]) if sparam is not None else np.zeros(len(t))
        self.mask = tid >= 0
        self.n = len(t)

    def image(self, col, dtype=np.uint8, ch=3):
        img = np.zeros((self.S, self.S, ch), np.float32)
        img[self.ys, self.xs] = col
        return img

    def finish(self, col, dil=10):
        img = self.image(col)
        img, m = raster.dilate(img, self.mask, dil)
        return np.clip(img, 0, 255).astype(np.uint8)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a + 1e-12), 0, 1)
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) == 1 else t
    return a * (1 - t) + b * t


def hash1(i, seed=0):
    x = np.sin(i.astype(np.float64) * 12.9898 + seed * 78.233) * 43758.5453
    return x - np.floor(x)


def worley(P, L, seed=0, jitter=0.85, bounds=None):
    """3D Worley on a jittered lattice of spacing L. Returns f1, f2 (distances), id (nearest cell index), centre (nearest point)."""
    lo = (P.min(0) - 2 * L) if bounds is None else bounds[0]; hi = (P.max(0) + 2 * L) if bounds is None else bounds[1]
    g = [np.arange(lo[k], hi[k], L) for k in range(3)]
    X, Y, Z = np.meshgrid(*g, indexing="ij")
    pts = np.stack([X.ravel(), Y.ravel(), Z.ravel()], 1)
    rng = np.random.default_rng(seed)
    pts = pts + (rng.random(pts.shape) - 0.5) * L * jitter
    kd = cKDTree(pts)
    d, i = kd.query(P, k=2)
    return d[:, 0], d[:, 1], i[:, 0], pts[i[:, 0]]


def vnoise(P, freq, seed=0):
    """smooth value-ish noise in [0,1] via random-direction sines (cheap, deterministic)"""
    rng = np.random.default_rng(seed)
    acc = np.zeros(len(P)); tot = 0
    for o in range(3):
        for _ in range(3):
            d = rng.normal(size=3); d /= np.linalg.norm(d)
            acc += np.sin(P @ d * freq * 2 ** o * 6.2832 + rng.uniform(0, 6.2832)) * 0.55 ** o; tot += 0.55 ** o
    return 0.5 + 0.5 * acc / tot * 1.4


def height_to_normal(h, strength=2.0):
    """h: (S,S) float height (texel units ~ arbitrary). tangent-space normal map (OpenGL, +Y up in image)."""
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5      # +row = down in image
    n = np.stack([-gx * strength, gy * strength, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)
