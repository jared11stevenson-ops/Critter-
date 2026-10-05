#!/usr/bin/env python3
"""Aruun v2: cloth cards rebuilt clean from the sheet: hooded mantle over his RIGHT shoulder (back view), fringe strips,
waist leaf skirt + cream tassels (front).  -> work/v2/cards.npz  (V, F, kind[tri], s[vert] gradient param)"""
import os, sys
import numpy as np
from scipy.spatial import cKDTree
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, HERE)
WORK = os.path.join(HERE, "..", "work", "v2")
KIND = {"mantle": 1, "fringe": 2, "leaf_olive": 3, "leaf_dark": 4, "tassel": 5, "cord": 6}


class Cards:
    def __init__(self):
        self.V, self.F, self.K, self.S = [], [], [], []
        self.n = 0
    def add(self, V, F, kind, S):
        self.V.append(V); self.F.append(np.asarray(F) + self.n); self.K.append(np.full(len(F), KIND[kind])); self.S.append(S); self.n += len(V)
    def save(self):
        np.savez(os.path.join(WORK, "cards.npz"), V=np.vstack(self.V).astype(np.float32), F=np.vstack(self.F).astype(np.int32),
                 kind=np.concatenate(self.K).astype(np.int32), s=np.concatenate(self.S).astype(np.float32))


def strip(P0, P1, width, bow, normal_dir, nseg=5, taper=0.85, wtop=1.0, sway=0.0):
    """Tapered strip from P0 down/out to P1; bow pushes the middle along normal_dir. returns V (2*(nseg+1) , 3), F, s."""
    P0, P1 = np.asarray(P0, float), np.asarray(P1, float)
    d = P1 - P0; L = np.linalg.norm(d); t_ = d / L
    side = np.cross(t_, normal_dir); side /= max(np.linalg.norm(side), 1e-6)
    V = []; S = []
    for i in range(nseg + 1):
        t = i / nseg
        c = P0 + d * t + normal_dir * bow * np.sin(np.pi * t * 0.9) + side * sway * np.sin(2 * np.pi * t)
        w = width * (wtop * (1 - t) + (1 - taper) * t * 0 + (0.0 if i == nseg else 0.0)) if False else width * (1 - taper * t ** 1.4) * wtop
        if i == nseg:
            V.append(c); S.append(1.0)
        else:
            V += [c - side * w / 2, c + side * w / 2]; S += [t, t]
    F = []
    for i in range(nseg - 1):
        a, b, c_, d_ = 2 * i, 2 * i + 1, 2 * i + 2, 2 * i + 3
        F += [(a, c_, b), (b, c_, d_)]
    a, b, tip = 2 * (nseg - 1), 2 * (nseg - 1) + 1, 2 * nseg
    F.append((a, tip, b))
    return np.array(V), F, np.array(S)


def main():
    import project as P
    vs = P.views(); bv = vs["back"]
    hi = np.load(os.path.join(WORK, "shells_hi.npz"))
    B = np.vstack([hi["V_" + g] for g in ("trunk", "armL", "armR", "legL", "legR")])
    kd = cKDTree(B[:, [0, 2]])

    def back_y(x, z, r=0.035):
        idx = kd.query_ball_point([x, z], r)
        return B[idx, 1].max() if idx else None

    def px2w(u, v):
        return -(u - bv.u0) / bv.ppm, (bv.v0 - v) / bv.ppm
    C = Cards()
    # ---- mantle: polygon in back px, gridded; y = body back surface + offset
    poly = np.array([(262, 372), (320, 352), (400, 362), (455, 420), (474, 500), (468, 575), (430, 548), (372, 520), (315, 480), (272, 432)], float)
    pw = np.array([px2w(u, v) for u, v in poly])
    def inpoly(p, poly):
        x, y = p; c = False
        for i in range(len(poly)):
            x1, y1 = poly[i]; x2, y2 = poly[(i + 1) % len(poly)]
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                c = not c
        return c
    xs = np.arange(pw[:, 0].min(), pw[:, 0].max() + 1e-6, 0.03); zs = np.arange(pw[:, 1].min(), pw[:, 1].max() + 1e-6, 0.03)
    gi = {}; V = []; S = []
    for j, z in enumerate(zs):
        for i, x in enumerate(xs):
            if inpoly((x, z), pw):
                y = back_y(x, z, 0.04)
                if y is None:
                    continue
                gi[(i, j)] = len(V)
                V.append((x, y + 0.035 + 0.05 * (pw[:, 1].max() - z) / 0.4, z)); S.append((pw[:, 1].max() - z) / (pw[:, 1].max() - pw[:, 1].min()))
    F = []
    for (i, j), a in gi.items():
        if (i + 1, j) in gi and (i, j + 1) in gi and (i + 1, j + 1) in gi:
            b, c, d = gi[(i + 1, j)], gi[(i, j + 1)], gi[(i + 1, j + 1)]
            F += [(a, b, c), (b, d, c)]
    C.add(np.array(V), F, "mantle", np.array(S)); print("mantle tris", len(F))
    # ---- fringe strips hanging from the mantle hem along the right arm (back px picks: top u,v -> bottom u,v)
    picks = [((350, 520), (352, 900)), ((385, 530), (402, 1010)), ((420, 545), (440, 1060)), ((448, 560), (480, 1090)),
             ((462, 570), (520, 1100)), ((300, 480), (312, 760)), ((330, 505), (340, 820))]
    for k, (a, b) in enumerate(picks):
        x0, z0 = px2w(*a); x1, z1 = px2w(*b)
        y0 = back_y(x0, z0, 0.05) or 0.2; y1 = back_y(x1, max(z1, 0.7), 0.06) or 0.2
        V_, F_, S_ = strip((x0, y0 + 0.05, z0), (x1, y1 + 0.06, z1), 0.07 + 0.01 * (k % 3), 0.02, np.array([0, 1.0, 0]), nseg=6, taper=0.9)
        C.add(V_, F_, "fringe", S_)
    # ---- waist leaf skirt around the belt (z 1.2): body axis from the hip shell
    Bb_ = np.vstack([hi['V_' + g] for g in ('trunk', 'legL', 'legR')])
    hip = Bb_[(Bb_[:, 2] > 1.1) & (Bb_[:, 2] < 1.3)]
    xc, yc = hip[:, 0].mean(), hip[:, 1].mean()
    rng = np.random.RandomState(3)
    Bb = np.vstack([hi['V_' + g] for g in ('trunk', 'legL', 'legR')])
    xc, yc = np.median(hip[:, 0]), np.median(hip[:, 1])
    RX, RY = 0.235, 0.20
    def rbody(th, z):
        # ellipse radius at angle th, widening slightly down the thighs
        r = RX * RY / np.hypot(RY * np.cos(th), RX * np.sin(th))
        return r * (1.0 + 0.25 * np.clip((1.2 - z) / 0.7, 0, 1))
    nl = 18
    for i in range(nl):
        th = 2 * np.pi * (i + 0.5) / nl                     # angle in xy; front = -y => th = -pi/2
        front = np.cos(th + np.pi / 2) > 0.55 and np.sin(th) < 0
        if front:
            continue
        for layer, kind, off, drop in ((0, "leaf_dark", 0.0, 0.52), (1, "leaf_olive", 0.04, 0.68)):
            L = (drop + 0.12 * rng.rand()) * (0.8 if np.sin(th) < -0.3 else 1.0)
            z0 = 1.2
            r0 = rbody(th, z0) + 0.025 + off
            r1 = rbody(th, z0 - L * 0.55) + 0.05 + off + 0.03
            thj = th + 0.1 * layer
            P0 = np.array([xc + r0 * np.cos(thj), yc + r0 * np.sin(thj), z0])
            P1 = np.array([xc + r1 * np.cos(thj), yc + r1 * np.sin(thj), z0 - L])
            n = np.array([np.cos(thj), np.sin(thj), 0.0])
            V_, F_, S_ = strip(P0, P1, 0.15, 0.04, n, nseg=5, taper=0.8)
            C.add(V_, F_, kind, S_)
    # ---- front cream tassels hanging from the belt at the front centre
    for i, dx in enumerate(np.linspace(-0.13, 0.12, 7)):
        z0 = 1.14; L = 0.38 + 0.12 * np.sin(i * 1.7)
        yb = hip[:, 1].min() if len(hip) else -0.2
        P0 = np.array([xc + dx, yb - 0.02, z0]); P1 = np.array([xc + dx * 1.15, yb - 0.04, z0 - L])
        V_, F_, S_ = strip(P0, P1, 0.05, 0.015, np.array([0, -1.0, 0]), nseg=4, taper=0.5)
        C.add(V_, F_, "tassel", S_)
    C.save(); print("cards tris", sum(len(f) for f in C.F), "verts", C.n)


if __name__ == "__main__":
    main()
