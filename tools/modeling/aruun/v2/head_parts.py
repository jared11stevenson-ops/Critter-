#!/usr/bin/env python3
"""Aruun v2: head furniture built on the voxel head: yellow eyes (+dark liner), cream temple tines, red crest spikes,
fringe tufts (pale-yellow/olive, sweeping back).  -> work/v2/headparts.npz (V,F,name per tri, s per vert)"""
import os, sys
import numpy as np
from scipy.spatial import cKDTree
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, HERE)
import horns as H
import cards as C
WORK = os.path.join(HERE, "..", "work", "v2")


def sphere(c, r, sq=(1, 1, 1), n=10, m=7):
    V = []; F = []
    for i in range(m + 1):
        th = np.pi * i / m
        for j in range(n):
            ph = 2 * np.pi * j / n
            V.append(c + np.array([r * sq[0] * np.sin(th) * np.cos(ph), r * sq[1] * np.sin(th) * np.sin(ph), r * sq[2] * np.cos(th)]))
    for i in range(m):
        for j in range(n):
            a = i * n + j; b = i * n + (j + 1) % n
            F += [(a, a + n, b), (b, a + n, b + n)]
    return np.array(V), np.array(F)


def cone(base, tip, r, sides=6):
    C_ = np.array([base, base + (np.asarray(tip) - base) * 0.5, tip])
    V, F, S = H.tube(C_, np.array([r, r * 0.55, 0.002]), sides)
    return V, F, S


def main():
    hi = np.load(os.path.join(WORK, "shells_hi.npz")); B = hi["V_trunk"]
    head = B[B[:, 2] > 1.9]
    xc = 0.095
    out = {"V": [], "F": [], "name": [], "s": []}; off = [0]
    def add(V, F, name, S=None):
        out["V"].append(V); out["F"].append(np.asarray(F) + off[0]); out["name"] += [name] * len(F)
        out["s"].append(np.zeros(len(V)) if S is None else S); off[0] += len(V)
    # eyes: sheet side px (245, 236) -> y,z ; surface x from the head verts
    import project as P
    vs = P.views(); sv = vs["side"]
    ey = -(247 - sv.u0) / sv.ppm; ez = (sv.v0 - 236) / sv.ppm
    for sgn in (-1, 1):
        sel = head[(np.abs(head[:, 1] - ey) < 0.012) & (np.abs(head[:, 2] - ez) < 0.012)]
        xs = sel[:, 0]; xsurf = (xs.max() if sgn > 0 else xs.min()) if len(xs) else xc + sgn * 0.065
        c = np.array([xsurf, ey, ez])
        V, F = sphere(c + np.array([sgn * 0.002, 0, 0]), 0.021, (0.45, 1.0, 1.0)); add(V, F, "eye_liner")
        V, F = sphere(c + np.array([sgn * 0.007, -0.003, 0]), 0.0155, (0.4, 1.0, 1.0)); add(V, F, "eye")
    # temple tines (cream, sweep sideways/up) + crest spikes (red) + nape spurs
    top = head[head[:, 2] > 2.08]
    for sgn in (-1, 1):
        base = np.array([xc + sgn * 0.075, -0.115, 2.095]); tip = base + np.array([sgn * 0.085, 0.01, 0.06])
        V, F, S = cone(base, tip, 0.011); add(V, F, "tine", S)
    for k, dy in enumerate((-0.06, -0.11, -0.16)):
        base = np.array([xc, dy, 2.115 - 0.01 * k]); tip = base + np.array([0.0, 0.03 + 0.012 * k, 0.07 - 0.012 * k])
        V, F, S = cone(base, tip, 0.016); add(V, F, "crest", S)
    # fringe tufts at the nape sides: strips sweeping back/out
    for sgn in (-1, 1):
        for k, (dz, ln) in enumerate(((0.0, 0.16), (-0.03, 0.13), (0.03, 0.12))):
            base = np.array([xc + sgn * 0.07, -0.02, 2.04 + dz]); tip = base + np.array([sgn * 0.07, 0.11 + 0.1 * (ln - 0.12), -0.03 - 0.4 * (0.16 - ln)])
            V, F, S = C.strip(base, tip, 0.04, 0.01, np.array([sgn * 1.0, 0.0, 0.3]), nseg=3, taper=0.8)
            add(V, F, "fringe_head", S)
    np.savez(os.path.join(WORK, "headparts.npz"), V=np.vstack(out["V"]).astype(np.float32), F=np.vstack(out["F"]).astype(np.int32),
             name=np.array(out["name"]), s=np.concatenate(out["s"]).astype(np.float32))
    print("headparts tris", sum(len(f) for f in out["F"]))


if __name__ == "__main__":
    main()
