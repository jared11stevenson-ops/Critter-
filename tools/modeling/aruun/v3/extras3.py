#!/usr/bin/env python3
"""Aruun v3.1 extra pieces: flowing mane (cream/olive strands), claws (hand / toes / heel spurs), belt trinkets (bone ring buckle,
medallion, red bead strings), skirt studs.  -> work/v3/extras.npz (V, F, tri_piece, names, kinds, sp)"""
import os, sys, math
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, os.path.join(HERE, "..", "..", "cigarra", "v2"))
import cards as CC            # tube / bez helpers (winding fixed)
WORK = os.path.join(HERE, "..", "work", "v3")
rng = np.random.default_rng(5)
H = np.load(os.path.join(WORK, "head_raw.npz")); O, SC = H["origin"], float(H["scale"])


class Acc:
    def __init__(self): self.V, self.F, self.names, self.kinds, self.sp, self.tp, self.n = [], [], [], [], [], [], 0
    def add(self, name, kind, V, F, sp=None):
        V = np.asarray(V, np.float32); F = np.asarray(F, np.int32)
        self.V.append(V); self.F.append(F + self.n); self.names.append(name); self.kinds.append(kind)
        self.sp.append(np.zeros(len(V), np.float32) if sp is None else np.asarray(sp, np.float32)); self.tp.append(np.full(len(F), len(self.names) - 1, np.int32)); self.n += len(V)


def Wh(p):          # head-local (x, f, z) -> world
    return O + SC * np.array([p[0], -p[1], p[2]])


def mane(A):
    """flowing mane: 24 broad flat locks from the crown/back of the skull sweeping back, then drooping, in cream / pale yellow / olive"""
    k = 0
    for i in range(24):
        side = 1 if i % 2 == 0 else -1
        f = (i // 2) / 11.0                                  # 0 front/top .. 1 nape
        root_l = np.array([side * (0.035 + 0.035 * f) * rng.uniform(0.6, 1.1), 0.02 - 0.085 * f, 0.075 - 0.07 * f])
        root = Wh(root_l)
        L = rng.uniform(0.20, 0.34) * (1.0 - 0.25 * f)
        out = np.array([side * rng.uniform(0.02, 0.09), 0.0, 0.0])
        p1 = root + np.array([0, 0.40 * L, 0.05 * L]) + out * 0.5
        p2 = root + np.array([0, 0.78 * L, -0.12 * L]) + out
        p3 = root + np.array([0, 0.95 * L, -0.55 * L]) + out * 1.4
        C = CC.bez([root, p1, p2, p3], 5)
        w = np.array([0.034, 0.036, 0.030, 0.019, 0.004]) * rng.uniform(0.85, 1.2)
        V, F, S = CC.tube(C, w, 4, cap_end=False, ry=np.full(5, 0.006))
        var = 2 if rng.random() < 0.22 else (1 if rng.random() < 0.45 else 0)
        A.add(f"mane_{k}", "mane", V, F, S + 2.0 * var); k += 1


def cone(A, name, kind, base, tip, r, sides=5, sp=0.0):
    base = np.asarray(base, float); tip = np.asarray(tip, float)
    C = np.array([base, tip]); V, F, S = CC.tube(C, np.array([r, 0.0015]), 4, cap_end=False, cap_start=True)
    A.add(name, kind, V, F, np.full(len(V), sp))


def claws(A):
    # left hand: three long pointed claws + thumb claw
    for k, x in enumerate((0.300, 0.332, 0.364)):
        cone(A, f"claw_hand_L{k}", "claw", (x, -0.092, 0.835), (x + 0.004, -0.115 - 0.01 * k, 0.70 - 0.012 * (k == 1)), 0.0135, 5)
    cone(A, "claw_thumb_L", "claw", (0.392, -0.07, 0.90), (0.43, -0.10, 0.82), 0.012, 5)
    # right hand gripping Morrow: small knuckle claws on the fist
    for k, z in enumerate((0.93, 0.89)):
        cone(A, f"claw_hand_R{k}", "claw", (-0.34 + 0.0, -0.08, z), (-0.37, -0.115, z - 0.02), 0.010, 5)
    # feet: 3 forward toe claws + heel spur
    for nm, fx, hx in (("L", 0.172, 0.173), ("R", -0.365, -0.352)):
        for k, dx in enumerate((-0.05, 0.0, 0.05)):
            cone(A, f"claw_toe_{nm}{k}", "claw", (fx + dx, -0.178, 0.04), (fx + dx * 1.15, -0.30 - 0.015 * (k == 1), 0.012), 0.020, 5)
        cone(A, f"claw_heel_{nm}", "claw", (hx, 0.150, 0.075), (hx, 0.232, 0.135), 0.020, 5)


def skirt(A):
    """olive leaf-panel skirt: two staggered rows of long pointed leaves around the waist (front centre left open for the cream loincloth strips)"""
    xc, yc = 0.0, 0.0
    RX, RY = 0.235, 0.20
    for row, (n_l, z0, dr, Lr) in enumerate(((14, 1.205, 0.045, (0.34, 0.50)), (14, 1.20, 0.0, (0.28, 0.44)))):
        for i in range(n_l):
            th = 2 * np.pi * (i + 0.5 * row + 0.25) / n_l
            if np.sin(th) < -0.55 and abs(np.cos(th)) < 0.5: continue            # front centre
            L = rng.uniform(*Lr); wtop = 0.13
            nrm = np.array([np.cos(th), np.sin(th), 0.0]); tan = np.array([-np.sin(th), np.cos(th), 0.0])
            rr = lambda zz: (RX * RY / np.hypot(RY * np.cos(th), RX * np.sin(th))) * (1.0 + 0.30 * np.clip((1.2 - zz) / 0.7, 0, 1)) + dr + 0.02
            V = []
            for j, (u, w) in enumerate(((0.0, 1.0), (0.30, 1.12), (0.65, 0.78), (1.0, 0.0))):
                zz = z0 - L * u; r = rr(zz) + 0.04 * u
                c = np.array([xc, yc, zz]) + nrm * r
                if w > 0: V += [c - tan * wtop * w / 2, c + tan * wtop * w / 2]
                else: V += [c - nrm * 0.0 + np.array([0, 0, -0.0])]
            F = [(0, 2, 1), (1, 2, 3), (2, 4, 3), (3, 4, 5), (4, 6, 5)]
            F = [(0, 1, 2), (1, 3, 2), (2, 3, 4), (3, 5, 4), (4, 5, 6)]
            V = np.array(V); Fn = np.array(F)
            nn = np.cross(V[Fn[:, 1]] - V[Fn[:, 0]], V[Fn[:, 2]] - V[Fn[:, 0]]).mean(0)
            if nn @ nrm < 0: Fn = Fn[:, ::-1]
            sp = np.array([0, 0, 0.30, 0.30, 0.65, 0.65, 1.0])
            A.add(f"leaf_{row}_{i}", "leaf", V, Fn, sp)


def trinkets(A):
    # bone ring buckle (dark centre) at the belt front + hanging medallion + red bead strings
    c = np.array([0.0, -0.250, 1.17])
    ring = np.array([(c[0] + 0.055 * math.cos(a), c[1] - 0.012 * math.sin(a) * 0 , c[2] + 0.055 * math.sin(a)) for a in np.linspace(0, 2 * np.pi, 10, endpoint=False)])
    ring = np.vstack([ring, ring[:1]])
    V, F, S = CC.tube(ring, np.full(len(ring), 0.012), 4, cap_end=False); A.add("buckle_ring", "trinket", V, F, S)
    # medallion: flattened sphere with gold rim
    V, F = CC.sphere(c + np.array([0.0, -0.01, -0.17]), 0.032, 6, 4); V = V.copy(); V[:, 1] = c[1] - 0.01 + (V[:, 1] - (c[1] - 0.01)) * 0.35
    A.add("medallion", "trinket", V, F, np.full(len(V), 1.0))
    for k, dx in enumerate((-0.07, -0.035, 0.05, 0.085)):
        Cc = CC.bez([c + np.array([dx, 0.0, -0.04]), c + np.array([dx * 1.1, -0.01, -0.16]), c + np.array([dx * 1.2, -0.005, -0.30 - 0.03 * k])], 5)
        V, F, S = CC.tube(Cc, np.full(5, 0.0055), 3, cap_end=True); A.add(f"bead_{k}", "trinket", V, F, S + 2.0)
    # skirt studs around the waistband
    for k in range(8):
        a = np.pi + (k + 0.5) / 10 * np.pi + 0.0
        a = 2 * np.pi * (k + 0.5) / 8
        pos = np.array([0.0 + 0.215 * math.cos(a), 0.0 + 0.175 * math.sin(a), 1.205])
        if pos[1] < -0.10: continue
        cone(A, f"stud_{k}", "trinket", pos, pos + np.array([0.02 * math.cos(a), 0.017 * math.sin(a), 0.004]), 0.012, 4, sp=3.0)


def main():
    A = Acc(); mane(A); claws(A); trinkets(A); skirt(A)
    np.savez(os.path.join(WORK, "extras.npz"), V=np.vstack(A.V), F=np.vstack(A.F), tri_piece=np.concatenate(A.tp), names=np.array(A.names), kinds=np.array(A.kinds), sp=np.concatenate(A.sp))
    print("extras tris", sum(len(f) for f in A.F), "pieces", len(A.names))


if __name__ == "__main__":
    main()
