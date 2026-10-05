#!/usr/bin/env python3
"""Aruun v3 horns: sheet-scale hooked lyre/antler horns. Centrelines from the sheet pixel picks (v2/horns.py BACK/SIDE),
rooted in the skull's horn cups, thick jointed stag-beetle shafts with knob rings, side tines and notched (forked) tips.
-> work/v3/horns3.npz (V, F, tube id, s)"""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, os.path.join(HERE, "..", "v2")); sys.path.insert(0, os.path.join(HERE, ".."))
import horns as H
import importlib
WORK = os.path.join(HERE, "..", "work", "v3")
ANCHOR = {"R": (0.040, -0.024, 2.11), "L": (0.130, -0.024, 2.11)}
RAD = {"R": (0.040, 0.014), "L": (0.036, 0.013)}


def main():
    import project as P
    vs = P.views(); sv, bv = vs["side"], vs["back"]
    verts, faces, tid, sparam = [], [], [], []; off = [0]
    def add(V, F, k, S):
        verts.append(V); faces.append(F + off[0]); tid.append(np.full(len(V), k)); sparam.append(S); off[0] += len(V)
    for k, name in enumerate(("R", "L")):
        b = np.array(H.BACK[name], float); s = np.array(H.SIDE[name], float)
        xb = -(b[:, 0] - bv.u0) / bv.ppm; zb = (bv.v0 - b[:, 1]) / bv.ppm
        ys = -(s[:, 0] - sv.u0) / sv.ppm; zs = (sv.v0 - s[:, 1]) / sv.ppm
        cb = H.arclen_resample(H.catmull(np.stack([xb, zb], 1)), 56)
        cs = H.arclen_resample(H.catmull(np.stack([ys, zs], 1)), 56)
        C = np.stack([cb[:, 0], cs[:, 0], 0.5 * (cb[:, 1] + cs[:, 1])], 1)
        t = np.linspace(0, 1, len(C))
        C = C + (np.array(ANCHOR[name]) - C[0]) * ((1 - t) ** 1.5)[:, None]
        r0, r1 = RAD[name]
        knob = 1 + 0.22 * (np.cos(2 * np.pi * t * 3.0) ** 2) ** 2.5
        rad = (r0 + (r1 - r0) * t ** 0.9) * knob
        rad[:3] *= np.array([1.25, 1.12, 1.05])      # flared root sits in the cup
        rad[-3:] *= np.array([1.0, 0.9, 0.8])          # blunt notched tip
        V, F, S = H.tube(C, rad, 8)
        add(V, F, k, S)
        for si, (sv_, ln) in enumerate(((0.22, 0.085), (0.45, 0.10), (0.68, 0.075), (0.88, 0.05))):
            i = int(sv_ * (len(C) - 1)); tg = C[min(i + 1, len(C) - 1)] - C[i - 1]; tg /= np.linalg.norm(tg)
            side = np.cross(tg, [0, 0, 1.0]); side /= np.linalg.norm(side)
            dirn = side * (1 if (si + k) % 2 == 0 else -1) * 0.75 + tg * 0.45 + np.array([0, 0, 0.35]); dirn /= np.linalg.norm(dirn)
            base = C[i]; tip = base + dirn * ln
            Cs = np.array([base - dirn * 0.012, base + dirn * ln * 0.5, tip]); rs = np.array([rad[i] * 0.62, rad[i] * 0.40, 0.004])
            Vs, Fs, Ss = H.tube(Cs, rs, 6); add(Vs, Fs, k, np.full(len(Vs), sv_))
        # forked tip: two short prongs
        tg = C[-1] - C[-3]; tg /= np.linalg.norm(tg); side = np.cross(tg, [0, 0, 1.0]); side /= np.linalg.norm(side)
        for sg in (-1, 1):
            d = tg * 0.8 + side * sg * 0.45; d /= np.linalg.norm(d)
            Cs = np.array([C[-1] - tg * 0.01, C[-1] + d * 0.02, C[-1] + d * 0.045]); rs = np.array([rad[-1] * 0.8, rad[-1] * 0.55, 0.004])
            Vs, Fs, Ss = H.tube(Cs, rs, 6); add(Vs, Fs, k, np.full(len(Vs), 1.0))
        print(name, "tip", C[-1].round(3), "span x", C[:, 0].min().round(3), C[:, 0].max().round(3), "z max", C[:, 2].max().round(3))
    np.savez(os.path.join(WORK, "horns3.npz"), V=np.vstack(verts).astype(np.float32), F=np.vstack(faces).astype(np.int32),
             tube=np.concatenate(tid), s=np.concatenate(sparam).astype(np.float32))


if __name__ == "__main__":
    main()
