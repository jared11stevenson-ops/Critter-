#!/usr/bin/env python3
"""Aruun v2 stage 3: voxel-union the fitted legacy part shells into clean single-skin shells (trunk+head, 2 arms,
2 legs), marching cubes, light Laplacian clean.  -> work/v2/shells_hi.npz  (V_<g>, F_<g>)
  python3 tools/modeling/aruun/v2/shells.py"""
import os, sys, time
import numpy as np
from scipy import ndimage as ndi
from skimage.measure import marching_cubes

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(HERE, "..", "work", "v2")
H = 0.006

HEADP = {"head", "jaw", "fang", "eye", "brow", "crest", "tine", "neck", "torso", "belt", "pauldron.L", "pauldron.R",
         "fringe_cream", "fringe_olive", "buckle", "buckle_disc", "medallion", "gold"}
def groups(parts):
    g = {}
    for i, p in enumerate(parts):
        b = p.split(".")[0]; s = p[-1] if p.endswith((".L", ".R")) else ""
        if p in HEADP or p in ("head", "jaw"):
            g[i] = "trunk"
        elif b in ("upperarm", "forearm", "armplate", "bracer", "hand", "claw"):
            g[i] = "arm" + s
        elif b in ("thigh", "shin", "kneeplate", "foot", "toeclaw", "thighplate", "shinplate"):
            g[i] = "leg" + s
    return g


def surface_points(V, T, h, k=8):
    A = V[T[:, 0]]; B = V[T[:, 1]]; C = V[T[:, 2]]
    area = 0.5 * np.linalg.norm(np.cross(B - A, C - A), axis=1)
    n = np.maximum(1, np.ceil(area / (h * h) * k)).astype(int)
    idx = np.repeat(np.arange(len(T)), n)
    r1 = np.random.rand(len(idx)); r2 = np.random.rand(len(idx))
    s = np.sqrt(r1)
    return A[idx] * (1 - s)[:, None] + B[idx] * (s * (1 - r2))[:, None] + C[idx] * (s * r2)[:, None]


def solidify(V, T, h=H):
    P = surface_points(V, T, h)
    lo = P.min(0) - 6 * h; hi = P.max(0) + 6 * h
    dims = np.ceil((hi - lo) / h).astype(int)
    occ = np.zeros(dims, bool)
    ij = np.floor((P - lo) / h).astype(int)
    occ[ij[:, 0], ij[:, 1], ij[:, 2]] = True
    surf = occ.copy()
    st = ndi.generate_binary_structure(2, 1)
    disk = ndi.iterate_structure(st, 5)
    out = np.zeros_like(occ)
    for k in range(occ.shape[2]):
        sl = occ[:, :, k]
        if not sl.any():
            continue
        c = ndi.binary_closing(np.pad(sl, 8), structure=disk)[8:-8, 8:-8]
        out[:, :, k] = ndi.binary_fill_holes(c)
    occ = ndi.binary_fill_holes(ndi.binary_closing(out | surf, iterations=1))
    f = ndi.gaussian_filter(occ.astype(np.float32), 2.0)
    v, f_, n, _ = marching_cubes(f, 0.5, spacing=(h, h, h))
    return (v + lo + h * 0.5).astype(np.float32), f_[:, ::-1].astype(np.int32).copy()


def main():
    np.random.seed(7)
    m = np.load(os.path.join(WORK, "mesh_fit.npz"), allow_pickle=True)
    V, T, parts, pot = m["V"].astype(np.float64), m["T"], list(m["parts"]), m["part_of_tri"]
    g = groups(parts)
    out = {}
    for name in ("trunk", "arm.L", "arm.R", "leg.L", "leg.R"):
        key = name.replace(".", "")
        sel = np.array([g.get(p) == (name.replace(".", "") if False else name.replace(".L", ".L")) for p in pot])
    names = sorted(set(g.values()))
    for gn in names:
        sel = np.array([g.get(p) == gn for p in pot])
        t0 = time.time()
        v, f = solidify(V, T[sel])
        out["V_" + gn] = v; out["F_" + gn] = f
        print(gn, "tris", len(f), "verts", len(v), "%.1fs" % (time.time() - t0))
    np.savez(os.path.join(WORK, "shells_hi.npz"), **out)


if __name__ == "__main__":
    main()
