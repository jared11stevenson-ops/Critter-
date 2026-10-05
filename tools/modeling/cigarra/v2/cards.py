#!/usr/bin/env python3
"""Cigarra v2 hand-authored pieces (low-poly tubes / cards / blobs read off the sheet):
wing-cloak panels (4), cape + hood roll + collar, hair clumps, treehopper crown (branches + 7 glossy spheres), belt + cords + charms,
boot leaf-trim.   -> work/v2/pieces.npz  (V, F, tri_piece[int], piece names, per-vertex param sp, per-vertex uv2 for wings)
World frame: x = her left, forward = -y, z up. Everything here is placed relative to the rig joints in tools/animation/standin.py."""
import os, sys, math
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
WORK = os.path.join(HERE, "..", "work", "v2"); os.makedirs(WORK, exist_ok=True)
rng = np.random.default_rng(11)


class Pieces:
    def __init__(self):
        self.V, self.F, self.names, self.sp, self.uv, self.tri_piece, self.n = [], [], [], [], [], [], 0
    def add(self, name, V, F, sp=None, uv=None):
        V = np.asarray(V, np.float32); F = np.asarray(F, np.int32)
        self.V.append(V); self.F.append(F + self.n); self.sp.append(np.zeros(len(V), np.float32) if sp is None else np.asarray(sp, np.float32))
        self.uv.append(np.zeros((len(V), 2), np.float32) if uv is None else np.asarray(uv, np.float32))
        self.names.append(name); self.tri_piece.append(np.full(len(F), len(self.names) - 1, np.int32)); self.n += len(V)
    def save(self):
        np.savez(os.path.join(WORK, "pieces.npz"), V=np.vstack(self.V), F=np.vstack(self.F), tri_piece=np.concatenate(self.tri_piece),
                 names=np.array(self.names), sp=np.concatenate(self.sp), uv=np.vstack(self.uv))
        print("pieces", len(self.names), "tris", sum(len(f) for f in self.F))


def frame(T):
    T = T / np.linalg.norm(T, axis=1, keepdims=True)
    up = np.array([0, 0, 1.0]); N = np.cross(T, up); bad = np.linalg.norm(N, axis=1) < 1e-3
    N[bad] = np.cross(T[bad], [1.0, 0, 0]); N /= np.linalg.norm(N, axis=1, keepdims=True)
    return T, N, np.cross(T, N)


def tube(C, radii, sides=6, cap_end=True, cap_start=False, ry=None):
    C = np.asarray(C, float); n = len(C); T, N, B = frame(np.gradient(C, axis=0))
    ang = np.linspace(0, 2 * np.pi, sides, endpoint=False); V = []; S = []
    ry = radii if ry is None else ry
    for i in range(n):
        V.append(C[i] + radii[i] * np.cos(ang)[:, None] * N[i] + ry[i] * np.sin(ang)[:, None] * B[i]); S += [i / (n - 1)] * sides
    V = np.vstack(V); F = []
    for i in range(n - 1):
        for j in range(sides):
            a = i * sides + j; b = i * sides + (j + 1) % sides; c = (i + 1) * sides + j; d = (i + 1) * sides + (j + 1) % sides
            F += [(a, b, c), (b, d, c)]
    S = list(S)
    if cap_end:
        k = len(V); V = np.vstack([V, C[-1]]); S.append(1.0)
        for j in range(sides): F.append((k, (n - 1) * sides + (j + 1) % sides, (n - 1) * sides + j))
    if cap_start:
        k = len(V); V = np.vstack([V, C[0]]); S.append(0.0)
        for j in range(sides): F.append((k, j, (j + 1) % sides))
    return V, np.array(F), np.array(S)


def bez(P, n):
    P = np.asarray(P, float); t = np.linspace(0, 1, n)[:, None]
    if len(P) == 3: return (1 - t) ** 2 * P[0] + 2 * (1 - t) * t * P[1] + t ** 2 * P[2]
    return (1 - t) ** 3 * P[0] + 3 * (1 - t) ** 2 * t * P[1] + 3 * (1 - t) * t ** 2 * P[2] + t ** 3 * P[3]


def sphere(c, r, n=10, m=6):
    V = []; F = []
    for i in range(m + 1):
        th = np.pi * i / m
        for j in range(n):
            ph = 2 * np.pi * j / n
            V.append(np.asarray(c) + r * np.array([np.sin(th) * np.cos(ph), np.sin(th) * np.sin(ph), np.cos(th)]))
    for i in range(m):
        for j in range(n):
            a = i * n + j; b = i * n + (j + 1) % n
            F += [(a, a + n, b), (b, a + n, b + n)]
    return np.array(V), np.array(F)


def wing_panels(P):
    """4 leaf-shaped cloak panels (2 per side), curved around the back. Explicit uv2 into the 4-tile wing texture."""
    specs = [  # name, root, end, max width, flare out, wrap, tile
        ("wing_0", (0.085, 0.085, 1.32), (0.200, 0.155, 0.78), 0.27, 0.05, 0.05, 0),
        ("wing_1", (0.100, 0.110, 1.24), (0.235, 0.190, 0.44), 0.32, 0.07, 0.06, 1)]
    for s in (1, -1):
        for name, root, end, Wd, flare, wrap, tile in specs:
            nu, nv = 12, 6
            root = np.array(root); end = np.array(end); root[0] *= s; end[0] *= s
            V = []; UV = []; SP = []
            for i in range(nu + 1):
                u = i / nu
                c = root + (end - root) * u
                c = c + np.array([s * flare * math.sin(np.pi * u * 0.8), 0.04 * math.sin(np.pi * u), 0])
                # leaf width: narrow at the shoulder, widest ~55%, pointed tip
                w = Wd * (np.sin(np.pi * min(u * 0.92 + 0.08, 1.0) ** 0.9)) ** 0.85 * (1.0 - 0.15 * u)
                for j in range(nv + 1):
                    v = j / nv * 2 - 1
                    off = np.array([s * v * w * 0.5, -(v * v) * w * 0.07, 0.0])
                    V.append(c + off)
                    vv = (v * 0.5 + 0.5) if s > 0 else (0.5 - v * 0.5)
                    UV.append(((tile + vv) / 2.0, 1 - u))
                    SP.append(u)
            F = []
            for i in range(nu):
                for j in range(nv):
                    a = i * (nv + 1) + j; b = a + 1; c = a + nv + 1; d = c + 1
                    F += [(a, c, b), (b, c, d)] if s > 0 else [(a, b, c), (b, d, c)]
            P.add(f"{name}_{'L' if s > 0 else 'R'}", V, F, SP, UV)


def cape(P):
    """violet back-cloth under the wings with the gold-sigil tab: rounded trapezoid from the nape to mid-back"""
    nu, nv = 9, 6; V = []; F = []; SP = []
    for i in range(nu + 1):
        u = i / nu; z = 1.40 - 0.50 * u
        w = 0.085 + 0.095 * np.sin(np.pi * 0.5 * min(u * 1.6, 1.0)) - 0.02 * u
        for j in range(nv + 1):
            v = j / nv * 2 - 1
            V.append((v * w, 0.092 + 0.032 * u - 0.028 * (v * v), z)); SP.append(u)
    for i in range(nu):
        for j in range(nv):
            a = i * (nv + 1) + j; b = a + 1; c = a + nv + 1; d = c + 1
            F += [(a, b, c), (b, d, c)]
    P.add("cape", V, F, SP)


def jacket_panels(P):
    """open violet jacket front panels hanging from the shoulders to the hips (moss hem), one per side"""
    for sd in (1, -1):
        nu, nv = 8, 2; V = []; SP = []
        for i in range(nu + 1):
            u = i / nu; z = 1.335 - 0.40 * u
            cx = sd * (0.080 + 0.085 * u ** 1.3); cy = -0.092 - 0.016 * u
            w = 0.052 + 0.030 * u
            for j in range(nv + 1):
                v = j / nv * 2 - 1
                V.append((cx + sd * v * w * 0.5, cy - 0.014 * (1 - v * v) * 0.0 + (0.03 * abs(v) * (0.4 + u)), z - 0.01 * v * v)); SP.append(u)
        F = []
        for i in range(nu):
            for j in range(nv):
                a = i * (nv + 1) + j; b = a + 1; c = a + nv + 1; d = c + 1
                F += [(a, b, c), (b, d, c)]
        V = np.array(V); F = np.array(F)
        n = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]).mean(0)
        if n[1] > 0: F = F[:, ::-1]
        P.add(f"jacket_{'L' if sd > 0 else 'R'}", V, F, SP)


def hood_collar(P):
    # hood roll bunched behind the neck: a tube loop from ear to ear passing behind the nape + a drooping bag
    path = np.array([(0.075 * math.sin(a), 0.020 + 0.075 * math.cos(a) * 0.9, 1.385 - 0.03 * math.cos(a * 0.5) * 0) for a in np.linspace(-2.3, 2.3, 16)])
    path = np.array([(0.085 * math.sin(a), -0.006 + 0.085 * math.cos(a), 1.385 + 0.012 * (1 - math.cos(a))) for a in np.linspace(-2.5, 2.5, 18)])
    V, F, S = tube(path, np.full(18, 0.026), 6, cap_end=True, cap_start=True); P.add("hood_roll", V, F, S)
    # hood bag hanging behind (open-front bunched cloth): lofted tube
    pts = bez([(0, 0.060, 1.40), (0, 0.120, 1.36), (0, 0.140, 1.22)], 7)
    r = np.array([0.075, 0.095, 0.100, 0.100, 0.085, 0.05, 0.02]); V, F, S = tube(pts, r, 8, cap_end=True, ry=r * 0.55); P.add("hood_bag", V, F, S)
    # collar ring at the neck base (hides the head/body seam)
    path = np.array([(0.052 * math.cos(a), -0.012 + 0.052 * math.sin(a), 1.345) for a in np.linspace(0, 2 * np.pi, 18, endpoint=False)])
    path = np.vstack([path, path[:1]])
    V, F, S = tube(path, np.full(len(path), 0.019), 6, cap_end=False); P.add("collar", V, F, S)


def hair(P):
    """shaggy layered hair: ~70 tapered clumps swept back/out + bangs, ears left free. sp = param along clump (0 root .. 1 tip) + 2*variant (0 cream, 1 warm, 2 lime tip)"""
    O = np.array([0.0, -0.012, 1.545]) ; R = np.array([0.083, 0.095, 0.098]) * 1.12
    k = 0; tries = 0
    while k < 70 and tries < 600:
        tries += 1
        th = rng.uniform(0.10, 2.05); ph = rng.uniform(0, 2 * np.pi)
        d = np.array([math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)])
        if d[1] < -0.25 and th > 0.95: continue                    # face window
        if abs(d[0]) > 0.80 and 1.15 < th < 1.95 and -0.35 < d[1] < 0.55: continue      # ears
        root = O + d * R * 0.96
        out = d / np.linalg.norm(d)
        back = d[1] > 0.15
        if d[1] < -0.05: sweep = np.array([np.sign(d[0] + 1e-6) * 0.75, 0.15, -0.6])        # bangs / side locks framing the face
        else: sweep = np.array([np.sign(d[0] + 1e-6) * 0.35, 0.8, -0.45 - 0.3 * (th > 1.3)])
        L = rng.uniform(0.060, 0.105) if th < 0.8 else rng.uniform(0.085, 0.160 if back else 0.12)
        sweep = sweep / np.linalg.norm(sweep)
        tip = root + out * 0.035 + sweep * L
        mid = (root + tip) / 2 + out * 0.030 + np.array([0, 0, 0.012])
        C = bez([root, mid, tip], 5)
        rad = np.array([0.032, 0.030, 0.021, 0.011, 0.002])
        V, F, S = tube(C, rad, 4, cap_end=False)
        var = 2 if rng.random() < 0.20 else (1 if rng.random() < 0.35 else 0)
        P.add(f"hair_{k}", V, F, S + 2.0 * var); k += 1


def crown(P):
    """treehopper crown: dark branching stalks from the back of the head with glossy black spheres (sheet crown_x4)."""
    base = np.array([0.0, 0.055, 1.62])
    # main trunk rises and leans back then forks
    trunk = bez([base, (0.0, 0.075, 1.68), (0.0, 0.07, 1.74)], 6)
    V, F, S = tube(trunk, np.linspace(0.021, 0.015, 6), 6); P.add("crown_trunk", V, F, S)
    # branch table: (side, points..., sphere radius) ; sx=+1 left, -1 right, 0 centre
    br = [
        (+1, [(0.012, 0.062, 1.665), (0.09, 0.05, 1.70), (0.18, 0.03, 1.75)], 0.052),
        (+1, [(0.18, 0.03, 1.75), (0.215, 0.02, 1.80), (0.235, 0.00, 1.84)], 0.040),
        (+1, [(0.09, 0.05, 1.70), (0.13, 0.10, 1.75), (0.15, 0.15, 1.79)], 0.036),
        (-1, [(-0.012, 0.062, 1.665), (-0.09, 0.05, 1.71), (-0.19, 0.025, 1.77)], 0.049),
        (-1, [(-0.09, 0.05, 1.71), (-0.13, 0.10, 1.76), (-0.15, 0.16, 1.80)], 0.034),
        (0, [(0.0, 0.07, 1.74), (-0.005, 0.045, 1.83), (-0.02, 0.01, 1.885)], 0.058),
        (0, [(0.0, 0.07, 1.70), (0.0, 0.12, 1.69), (0.0, 0.18, 1.68)], 0.030),
    ]
    for i, (sd, pts, rs) in enumerate(br):
        C = bez(pts, 5); rad = np.linspace(0.015, 0.008, 5)
        V, F, S = tube(C, rad, 5); P.add(f"crownb_{'L' if sd > 0 else 'R' if sd < 0 else 'C'}{i}", V, F, S)
        c = np.array(pts[-1]) + np.array([0, 0, rs * 0.55]) * 0 + (np.array(pts[-1]) - np.array(pts[-2])) / np.linalg.norm(np.array(pts[-1]) - np.array(pts[-2])) * rs * 0.8
        V, F = sphere(c, rs, 10, 6); P.add(f"crowns_{'L' if sd > 0 else 'R' if sd < 0 else 'C'}{i}", V, F, np.full(len(V), rs))


def belt_charms(P):
    # belt: leather loop at the pants waist
    path = np.array([(0.134 * math.cos(a), 0.004 + 0.106 * math.sin(a), 1.0) for a in np.linspace(0, 2 * np.pi, 20, endpoint=False)])
    path = np.vstack([path, path[:1]])
    V, F, S = tube(path, np.full(len(path), 0.016), 6, cap_end=False, ry=np.full(len(path), 0.020)); P.add("belt", V, F, S)
    # buckle: gold ring at the front
    a = np.linspace(0, 2 * np.pi, 10, endpoint=False)
    ring = np.array([(0.0 + 0.026 * np.cos(t), -0.116, 1.0 + 0.026 * np.sin(t)) for t in a]); ring = np.vstack([ring, ring[:1]])
    # ring in the xz plane: tube() frames assume path tangent; fine
    V, F, S = tube(ring, np.full(len(ring), 0.0065), 4, cap_end=False); P.add("buckle", V, F, S)
    # orange cords + knot hanging at the left front
    for k, (x0, ln) in enumerate(((0.045, 0.40), (0.062, 0.30), (0.150, 0.26))):
        C = bez([(x0, -0.112, 0.995), (x0 + 0.005, -0.122, 0.995 - ln * 0.5), (x0 + 0.01, -0.118, 0.995 - ln)], 4)
        V, F, S = tube(C, np.full(4, 0.0055), 4); P.add(f"cord_{k}", V, F, S)
    # charms: two pale skull-gourds + an egg pod (orange) hanging on cords at her left hip (sheet front/side)
    for k, (c, r) in enumerate((((0.058, -0.125, 0.69), (0.030, 0.026, 0.040)), ((0.100, -0.122, 0.755), (0.026, 0.024, 0.036)), ((0.150, -0.105, 0.70), (0.025, 0.022, 0.034)))):
        n = 10; m = 6; Vv = []; Ff = []
        for i in range(m + 1):
            th = np.pi * i / m
            for j in range(n):
                ph = 2 * np.pi * j / n
                Vv.append((c[0] + r[0] * math.sin(th) * math.cos(ph), c[1] + r[1] * math.sin(th) * math.sin(ph), c[2] + r[2] * math.cos(th)))
        for i in range(m):
            for j in range(n):
                a_ = i * n + j; b_ = i * n + (j + 1) % n; Ff += [(a_, a_ + n, b_), (b_, a_ + n, b_ + n)]
        P.add(f"charm_{k}", Vv, Ff, np.full(len(Vv), k))
    # leaf tuft at the belt knot
    for k in range(3):
        a0 = np.array([0.03 + 0.03 * k, -0.118, 0.99]); a1 = a0 + np.array([0.02 * (k - 1), -0.03, -0.09 - 0.02 * k])
        V, F, S = tube(np.array([a0, (a0 + a1) / 2 + [0, -0.01, 0], a1]), np.array([0.012, 0.014, 0.001]), 4, ry=np.array([0.003, 0.003, 0.0005])); P.add(f"leafb_{k}", V, F, S)


def boot_leaves(P):
    for s in (1, -1):
        for k, (dx, dy, ln, ang) in enumerate(((0.05, 0.035, 0.085, 0.2), (0.058, -0.02, 0.07, -0.25), (-0.05, 0.03, 0.06, 0.1))):
            a0 = np.array([s * (0.10 + dx), 0.022 + dy, 0.115]); dirn = np.array([s * (0.7 if dx > 0 else -0.7), 0.25 + ang, 0.6]); dirn /= np.linalg.norm(dirn)
            a1 = a0 + dirn * ln; mid = (a0 + a1) / 2 + np.array([0, 0, 0.012])
            V, F, S = tube(np.array([a0, mid, a1]), np.array([0.010, 0.016, 0.001]), 4, ry=np.array([0.004, 0.005, 0.001])); P.add(f"leafboot_{'L' if s > 0 else 'R'}{k}", V, F, S)


def main():
    P = Pieces()
    wing_panels(P); cape(P); jacket_panels(P); hood_collar(P); hair(P); crown(P); belt_charms(P); boot_leaves(P)
    P.save()


if __name__ == "__main__":
    main()
