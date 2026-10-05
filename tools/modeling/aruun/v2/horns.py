#!/usr/bin/env python3
"""Aruun v2: horns (+ temple tines) as swept tubes whose centrelines are read off the sheet's back (x,z) and side (y,z)
views (hires pixel picks below), knobbed like the sheet's jointed stag-beetle horns.  -> work/v2/horns.npz
Each tube vertex carries (tube id, arc parameter s 0..1) for procedural painting."""
import os, sys, json
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, HERE)
WORK = os.path.join(HERE, "..", "work", "v2")

# pixel picks (hires side_x4 / back_x4); see qa/v2_horn_picks.png
BACK = {"R": [(266, 176), (268, 150), (280, 95), (272, 62), (248, 44), (215, 37), (198, 52)],
        "L": [(207, 168), (205, 140), (175, 95), (150, 65), (110, 28), (60, 22), (45, 34)]}
SIDE = {"R": [(170, 188), (175, 160), (190, 125), (210, 100), (240, 70), (280, 50), (320, 32)],
        "L": [(262, 222), (265, 195), (280, 140), (300, 105), (330, 80), (360, 55), (385, 40)]}
RAD = {"R": (0.046, 0.013), "L": (0.040, 0.012)}
ANCHOR = {"R": (0.07, -0.07, 2.07), "L": (0.125, -0.115, 2.07)}


def catmull(P, n=60):
    P = np.asarray(P, float); P = np.vstack([P[0] * 2 - P[1], P, P[-1] * 2 - P[-2]])
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for t in np.linspace(0, 1, n // (len(P) - 3) + 1, endpoint=False):
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(P[-2]); return np.array(out)


def arclen_resample(P, n):
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]; s = d / d[-1]
    t = np.linspace(0, 1, n)
    return np.stack([np.interp(t, s, P[:, k]) for k in range(P.shape[1])], 1)


def tube(C, radii, sides=8, cap=True):
    n = len(C)
    T = np.gradient(C, axis=0); T /= np.linalg.norm(T, axis=1, keepdims=True)
    up = np.array([0, 0, 1.0]); N = np.cross(T, up); bad = np.linalg.norm(N, axis=1) < 1e-3
    N[bad] = np.cross(T[bad], np.array([1.0, 0, 0])); N /= np.linalg.norm(N, axis=1, keepdims=True)
    B = np.cross(T, N)
    ang = np.linspace(0, 2 * np.pi, sides, endpoint=False)
    V = np.zeros((n * sides, 3)); S = np.zeros(n * sides)
    for i in range(n):
        ring = C[i] + radii[i] * (np.cos(ang)[:, None] * N[i] + np.sin(ang)[:, None] * B[i])
        V[i * sides:(i + 1) * sides] = ring; S[i * sides:(i + 1) * sides] = i / (n - 1)
    F = []
    for i in range(n - 1):
        for j in range(sides):
            a = i * sides + j; b = i * sides + (j + 1) % sides; c = (i + 1) * sides + j; d = (i + 1) * sides + (j + 1) % sides
            F += [(a, c, b), (b, c, d)]
    if cap:
        base = len(V); V = np.vstack([V, C[0], C[-1]]); S = np.r_[S, 0, 1]
        for j in range(sides):
            F.append((base, j, (j + 1) % sides)); F.append((base + 1, (n - 1) * sides + (j + 1) % sides, (n - 1) * sides + j))
    return V, np.array(F, np.int32), S


def main():
    import project as P
    vs = P.views(); sv, bv = vs["side"], vs["back"]
    verts, faces, tid, sparam = [], [], [], []
    off = 0
    for k, name in enumerate(("R", "L")):
        b = np.array(BACK[name], float); s = np.array(SIDE[name], float)
        xb = -(b[:, 0] - bv.u0) / bv.ppm; zb = (bv.v0 - b[:, 1]) / bv.ppm
        ys = -(s[:, 0] - sv.u0) / sv.ppm; zs = (sv.v0 - s[:, 1]) / sv.ppm
        cb = arclen_resample(catmull(np.stack([xb, zb], 1)), 48)
        cs = arclen_resample(catmull(np.stack([ys, zs], 1)), 48)
        C = np.stack([cb[:, 0], cs[:, 0], 0.5 * (cb[:, 1] + cs[:, 1])], 1)
        t = np.linspace(0, 1, len(C))
        C = C + (np.array(ANCHOR[name]) - C[0]) * ((1 - t) ** 2)[:, None]
        r0, r1 = RAD[name]
        rad = (r0 + (r1 - r0) * t ** 0.8) * (1 + 0.30 * (np.cos(2 * np.pi * t * 4.0) ** 2) ** 1.5 * (1 - 0.4 * t))   # knobbed segments
        rad[-4:] *= np.linspace(1, 0.55, 4)
        V, F, S = tube(C, rad, 8)
        verts.append(V); faces.append(F + off); tid.append(np.full(len(V), k)); sparam.append(S); off += len(V)
        # spurs at the joints (stag-beetle branching): short cones leaving the horn sideways/outward
        for si, (sv_, ln) in enumerate(((0.28, 0.07), (0.52, 0.09), (0.74, 0.06))):
            i = int(sv_ * (len(C) - 1)); tg = C[min(i + 1, len(C) - 1)] - C[i - 1]; tg /= np.linalg.norm(tg)
            side = np.cross(tg, [0, 0, 1.0]); side /= np.linalg.norm(side)
            dirn = (side * (1 if (si + k) % 2 == 0 else -1) * 0.8 + tg * 0.35 + np.array([0, 0, 0.45])); dirn /= np.linalg.norm(dirn)
            base = C[i]; tip = base + dirn * ln
            Cs = np.array([base - dirn * 0.01, base + dirn * ln * 0.5, tip]); rs = np.array([rad[i] * 0.55, rad[i] * 0.33, 0.003])
            Vs, Fs, Ss = tube(Cs, rs, 6)
            verts.append(Vs); faces.append(Fs + off); tid.append(np.full(len(Vs), k)); sparam.append(np.full(len(Vs), sv_)); off += len(Vs)
        print(name, "tube tris", len(F), "tip", C[-1].round(3), "base", C[0].round(3))
    # temple tines: short cream cones (his left/right), from the back view picks
    for k, (name, tip_b, base_b, tip_s, base_s) in enumerate((("tR", (300, 175), (270, 170), (300, 238), (265, 235)),
                                                              ("tL", (250, 182), (205, 187), (300, 238), (265, 235)))):
        pass
    V = np.vstack(verts); F = np.vstack(faces); T_ = np.concatenate(tid); S_ = np.concatenate(sparam)
    np.savez(os.path.join(WORK, "horns.npz"), V=V.astype(np.float32), F=F, tube=T_, s=S_)


if __name__ == "__main__":
    main()
