#!/usr/bin/env python3
"""Cigarra 3D model: low-poly skinned mesh + palette-atlas / wing WebP textures, rig bone-compatible with the
tools/animation stand-in (so tools/animation/characters/cigarra.py clips bake straight onto it).

  python3 tools/modeling/cigarra/build.py   -> game/art/models/cigarra/{cigarra.glb, cigarra_anim.json, cigarra_model.tscn}
Reference: design/model_sheets/cigarra (turnaround.png, spec.md, palette.json). Budget: <= 6k tris, 2 textures.
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "animation"))
sys.path.insert(0, os.path.join(ROOT, "tools", "modeling"))
import bpy  # noqa: E402
from PIL import Image, ImageChops, ImageDraw, ImageFilter  # noqa: E402
import standin  # noqa: E402

OUT = os.path.join(ROOT, "game", "art", "models", "cigarra")
WORK = os.path.join(HERE, "work")
os.makedirs(OUT, exist_ok=True)
os.makedirs(WORK, exist_ok=True)

COL = {  # v3: sheet colour family (violet-black jacket, white-blonde hair, olive/gold wings, bone+gold charms), lifted
    "skin": (0.88, 0.64, 0.46), "hair": (0.98, 0.94, 0.78), "violet": (0.27, 0.21, 0.35), "violet_d": (0.23, 0.18, 0.31),
    "moss": (0.66, 0.72, 0.12), "crop": (0.93, 0.88, 0.66), "trim": (0.12, 0.09, 0.16), "leather": (0.58, 0.34, 0.16),
    "gold": (1.00, 0.76, 0.18), "cream": (0.92, 0.86, 0.68), "orange": (0.95, 0.48, 0.14), "black": (0.10, 0.08, 0.13),
    "boot": (0.22, 0.17, 0.12), "eye": (1.00, 0.84, 0.16), "gourd": (0.95, 0.90, 0.72), "violet_l": (0.40, 0.30, 0.54),
}
CELLS = list(COL)
GRID = 4  # 4x4 cells of 64 px = 256 px atlas


def cell_uv(name):
    i = CELLS.index(name)
    return ((i % GRID + 0.5) / GRID, 1 - ((i // GRID) + 0.5) / GRID)


class B:
    def __init__(self):
        self.v, self.f, self.cand, self.uv, self.mat = [], [], [], [], []

    def vert(self, p, cand):
        self.v.append(tuple(p))
        self.cand.append(cand)
        return len(self.v) - 1

    def tube(self, path, rx, ry, col, cand, n=8, cap0=True, cap1=True, flare=None):
        path = [np.array(p, float) for p in path]
        k = len(path)
        rx = rx if isinstance(rx, (list, tuple)) else [rx] * k
        ry = ry if isinstance(ry, (list, tuple)) else [ry] * k
        rings = []
        for i, p in enumerate(path):
            t = path[min(i + 1, k - 1)] - path[max(i - 1, 0)]
            t = t / (np.linalg.norm(t) + 1e-9)
            h = np.array([0, -1.0, 0]) if abs(t[1]) < 0.9 else np.array([1.0, 0, 0])
            u = np.cross(t, h)
            u /= np.linalg.norm(u)
            w = np.cross(t, u)
            ring = []
            for s in range(n):
                a = 2 * math.pi * s / n
                ring.append(self.vert(p + u * math.cos(a) * rx[i] + w * math.sin(a) * ry[i], cand))
            rings.append(ring)
        uv = cell_uv(col)
        for i in range(k - 1):
            for s in range(n):
                self.quad((rings[i][s], rings[i][(s + 1) % n], rings[i + 1][(s + 1) % n], rings[i + 1][s]), uv, 0)
        for flag, ring, p in ((cap0, rings[0], path[0]), (cap1, rings[-1], path[-1])):
            if flag:
                c = self.vert(p, cand)
                for s in range(n):
                    self.f.append((ring[s], ring[(s + 1) % n], c))
                    self.uv.append([uv] * 3)
                    self.mat.append(0)
        return rings

    def quad(self, idx, uv, mat):
        self.f.append(tuple(idx))
        self.uv.append(uv if isinstance(uv, list) else [uv] * len(idx))
        self.mat.append(mat)

    def ellipsoid(self, c, r, col, cand, n=8, rings=5):
        c = np.array(c, float)
        r = np.array(r, float)
        path = [c + np.array([0, 0, r[2] * math.cos(math.pi * i / rings)]) for i in range(rings + 1)]
        rad = [max(math.sin(math.pi * i / rings), 0.02) for i in range(rings + 1)]
        self.tube(path, [r[0] * x for x in rad], [r[1] * x for x in rad], col, cand, n=n, cap0=False, cap1=False)

    def cone(self, a, b, r, col, cand, n=5):
        self.tube([a, b], [r, 0.0005], [r, 0.0005], col, cand, n=n, cap0=True, cap1=False)


def build_geometry(J):
    b = B()
    V = lambda k: np.array(J[k], float)  # noqa: E731
    hd, he = V("head"), V("head_end")
    # ---- torso: crop top + midriff + belt + hooded jacket shoulders
    b.tube([V("hips") + [0, 0, 0.02], [0, 0, 1.00], [0, 0, 1.10]], [0.155, 0.135, 0.13], [0.105, 0.09, 0.09], "skin",
           ["hips", "spine1", "spine2"], n=14, cap0=False, cap1=False)
    b.tube([[0, 0, 1.11], [0, 0.005, 1.20], [0, 0, 1.30], [0, -0.005, 1.35]], [0.14, 0.15, 0.17, 0.09],
           [0.095, 0.105, 0.11, 0.07], "crop", ["spine2", "chest"], n=14, cap0=False, cap1=True)
    b.tube([[0, 0, 1.095], [0, 0, 1.125]], [0.142, 0.142], [0.097, 0.097], "trim", ["spine2"], n=14, cap0=False, cap1=False)
    # belt + buckle + charms (hips bone)
    b.tube([[0, 0, 0.905], [0, 0, 0.965]], [0.17, 0.17], [0.125, 0.125], "leather", ["hips"], n=14, cap0=False, cap1=False)
    b.ellipsoid([0, -0.125, 0.935], [0.035, 0.012, 0.03], "gold", ["hips"], n=6, rings=3)
    for sx, (x, z, col, rr) in zip((1, 1, -1), ((0.10, 0.78, "gourd", 0.04), (0.17, 0.80, "orange", 0.035),
                                                 (-0.12, 0.80, "gourd", 0.03))):
        b.ellipsoid([x, -0.11, z], [rr, rr * 0.8, rr * 1.2], col, ["hips", "thigh.L" if x > 0 else "thigh.R"], n=6, rings=4)
    b.tube([[0.07, -0.12, 0.9], [0.075, -0.125, 0.62]], [0.012, 0.01], [0.006, 0.005], "orange", ["hips", "thigh.L"], n=4)
    # jacket: shoulders mantle + collar + hood behind the head
    b.tube([[0, 0.02, 1.31], [0, 0.03, 1.22], [0, 0.07, 1.06]], [0.21, 0.20, 0.17], [0.12, 0.13, 0.12], "violet",
           ["chest", "spine2"], n=14, cap0=False, cap1=False)
    b.tube([[0, 0.0, 1.31], [0, 0.0, 1.38]], [0.15, 0.12], [0.12, 0.10], "violet_d", ["chest", "neck1"], n=14, cap0=False, cap1=False)
    b.tube([[0, 0.0, 1.375], [0, 0.0, 1.395]], [0.125, 0.125], [0.105, 0.105], "moss", ["neck1"], n=14, cap0=False, cap1=False)
    b.ellipsoid([0, 0.125, 1.40], [0.12, 0.07, 0.10], "violet_d", ["neck1", "head"], n=10, rings=5)   # hood
    b.ellipsoid([0, 0.17, 1.30], [0.045, 0.012, 0.06], "gold", ["chest"], n=6, rings=3)               # sigil tab
    # ---- neck + head
    b.tube([V("neck1") + [0, 0, -0.02], hd], 0.045, 0.045, "skin", ["neck1", "head"], n=8, cap0=False, cap1=False)
    n0 = len(b.f)
    v0 = len(b.v)
    b.ellipsoid(hd + [0, -0.01, 0.075], [0.085, 0.09, 0.105], "skin", ["head"], n=18, rings=12)       # face (painted texture)
    for k in range(n0, len(b.f)):                                                                     # planar face UVs, material 2
        b.uv[k] = [(((b.v[i][0] - hd[0]) + 0.095) / 0.19, (b.v[i][2] - (hd[2] - 0.03)) / 0.21) for i in b.f[k]]
        b.mat[k] = 2
    b.ellipsoid(hd + [0, 0.035, 0.125], [0.105, 0.10, 0.085], "hair", ["head"], n=14, rings=7)         # hair mass (behind forehead)
    b.ellipsoid(hd + [0, -0.062, 0.178], [0.092, 0.03, 0.03], "hair", ["head"], n=10, rings=4)         # fringe
    rng = np.random.default_rng(4)
    for i in range(16):                                                                                 # shaggy tufts
        a = rng.uniform(0.35, 2 * math.pi - 0.35) + math.pi / 2 + math.pi * 0.0
        a = rng.uniform(0, 2 * math.pi)
        if math.sin(a) < -0.55:
            a += math.pi * 0.6                                                                          # keep the face clear
        p = hd + [math.cos(a) * 0.095, math.sin(a) * 0.095 + 0.02, 0.13 + rng.uniform(-0.04, 0.07)]
        d = np.array([math.cos(a) * 0.05, math.sin(a) * 0.05 - 0.01, rng.uniform(-0.08, 0.01)])
        b.cone(p, p + d * 1.4, 0.026, "hair", ["head"], n=6)
    for sx in (1, -1):
        b.cone(hd + [sx * 0.085, 0.0, 0.085], hd + [sx * 0.17, 0.01, 0.125], 0.022, "skin", ["head"], n=6)   # pointed ears
        for yy, zz in ((-0.07, 0.17), (-0.03, 0.15)):                                                   # bangs framing the face
            b.cone(hd + [sx * 0.07, yy, zz], hd + [sx * 0.085, yy - 0.02, zz - 0.10], 0.02, "hair", ["head"], n=6)
    HS = 1.3                                                                                            # bigger head = readable face
    piv = hd + np.array([0, 0, 0.0])
    for i in range(v0, len(b.v)):
        b.v[i] = tuple(piv + (np.array(b.v[i]) - piv) * HS)
    # ---- crown (treehopper horn): branching stalks + glossy black spheres
    cr = ["crown"]
    base = he + [0, 0.045, 0.01]
    for stalk, (dx, dy, dz, rr) in enumerate([(0.02, 0.02, 0.14, 0.07), (0.16, 0.04, 0.09, 0.066), (-0.16, 0.04, 0.08, 0.066),
                                              (0.08, 0.16, 0.11, 0.058), (-0.10, 0.16, 0.07, 0.056),
                                              (0.24, -0.01, -0.01, 0.052), (-0.24, 0.0, 0.0, 0.052)]):
        tip = base + [dx, dy, dz]
        mid = base + [dx * 0.4, dy * 0.4 + 0.015, dz * 0.55]
        b.tube([base, mid, tip], [0.011, 0.008, 0.006], [0.011, 0.008, 0.006], "black", cr, n=5, cap0=False, cap1=False)
        b.ellipsoid(tip + [0, 0, rr * 0.7], [rr, rr, rr], "black", cr, n=8, rings=5)
        b.ellipsoid(tip + [rr * 0.35, -rr * 0.7, rr * 1.2], [rr * 0.3, rr * 0.15, rr * 0.3], "gold", cr, n=4, rings=2)
    # ---- limbs (build the left, mirror by sx)
    for sx, s in ((1, ".L"), (-1, ".R")):
        P = lambda k: V(k + s)  # noqa: E731
        sh, el, wr, he_ = P("shoulder"), P("elbow"), P("wrist"), P("hand_end")
        ua, fa, hn = ["upperarm" + s, "clavicle" + s], ["forearm" + s, "upperarm" + s], ["hand" + s, "forearm" + s]
        b.tube([sh + [0, 0, 0.02], (sh + el) / 2 + [sx * 0.012, 0.01, 0], el + [0, 0, 0.0]], [0.062, 0.068, 0.07],
               [0.058, 0.064, 0.066], "violet", ua, n=12, cap0=True, cap1=False)                       # puffy rolled sleeve
        b.tube([el, (el + wr) / 2 + [0, 0, 0.0], wr + [0, 0, 0.1 - 0.1]], [0.05, 0.043, 0.036], [0.05, 0.043, 0.036],
               "cream", fa, n=12, cap0=False, cap1=False)                                               # bandaged forearm
        b.tube([wr, he_], [0.032, 0.012], [0.02, 0.01], "skin", hn, n=12, cap0=True, cap1=True)         # hand
        # ---- legs: baggy harem pants, bandage shins, leaf-trim boots
        hp, kn, an, bl, te = P("hip"), P("knee"), P("ankle"), P("ball"), P("toe_end")
        th, sn, ft = ["thigh" + s, "hips"], ["shin" + s, "thigh" + s], ["foot" + s, "shin" + s]
        pc = "violet_d" if sx > 0 else "violet"
        th_path = [hp + [0, 0, 0.03]] + [hp + (kn - hp) * t + [sx * 0.012 * math.sin(t * 3), -0.012 * math.sin(t * 3.4), 0] for t in (0.18, 0.34, 0.5, 0.66, 0.82)] + [kn]
        th_r = [0.125, 0.138, 0.122, 0.14, 0.12, 0.13, 0.112]                                          # baggy fold ridges
        b.tube(th_path, th_r, [r * 0.97 for r in th_r], pc, th, n=14, cap0=True, cap1=False)
        b.tube([kn, kn * 0.55 + an * 0.45 + [0, -0.01, 0.04], an + [0, -0.01, 0.22]], [0.112, 0.118, 0.07], [0.112, 0.118, 0.07],
               pc, sn, n=14, cap0=False, cap1=True)
        b.tube([kn + [0, 0, 0.01], kn + [0, 0, -0.04]], [0.118, 0.118], [0.118, 0.118], "moss", sn, n=14, cap0=False, cap1=False)   # knee cuff
        b.ellipsoid(hp + (kn - hp) * 0.45 + [sx * 0.07, -0.105, 0], [0.05, 0.016, 0.06], "moss", th, n=8, rings=4)      # patches
        b.ellipsoid(hp + (kn - hp) * 0.75 + [-sx * 0.04, -0.11, 0], [0.04, 0.014, 0.045], "cream", th, n=8, rings=4)
        b.ellipsoid(kn * 0.7 + an * 0.3 + [sx * 0.02, -0.108, 0.02], [0.035, 0.014, 0.05], "violet_l", sn, n=8, rings=4)
        for k in range(7):                                                                                # bandaged shin wraps
            zz = 0.215 - k * 0.026
            b.tube([an + [0, -0.008, zz], an + [0, -0.008, zz - 0.03]], [0.058 - 0.0015 * k] * 2, [0.058 - 0.0015 * k] * 2,
                   "cream" if k % 2 == 0 else "gourd", sn, n=12, cap0=False, cap1=False)
        b.tube([an + [0, 0.02, 0.1], an + [0, 0.0, 0.02], bl + [0, 0, 0.03], te + [0, 0, 0.025]], [0.055, 0.06, 0.056, 0.04],
               [0.05, 0.06, 0.05, 0.03], "boot", ft, n=12, cap0=True, cap1=True)
        b.cone(an + [sx * 0.05, 0.0, 0.06], an + [sx * 0.15, -0.04, 0.1], 0.03, "moss", ft)           # leaf trim
    return b


def wing_mesh(b, J):
    """Veined wing-cloak panels (material 1): leaf-shaped alpha-cut membranes, 2 per side, curved around the back."""
    for sx, s in ((1, ".L"), (-1, ".R")):
        root = np.array(J["wing_root" + s], float)
        # (length, width, y offset, outward splay, z start, uoff)
        for panel, (length, width, dy, splay, dz, uoff) in enumerate([(0.90, 0.50, 0.0, 0.22, 0.0, 0.0), (0.62, 0.36, 0.05, 0.10, -0.05, 0.5)]):
            NU, NV = 6, 12
            ids = []
            for iv in range(NV + 1):
                v = iv / NV
                row = []
                for iu in range(NU + 1):
                    u = iu / NU
                    wv = width * (0.55 + 0.45 * math.sin(min(v * 1.25, 1.0) * math.pi * 0.5 + 0.0))   # fan out down the wing
                    x = root[0] + sx * (0.02 + wv * u + splay * v * v)
                    y = root[1] + dy + 0.02 + 0.06 * math.sin(u * math.pi) * (0.3 + v) + 0.05 * v * v
                    z = root[2] + dz - length * v + 0.03 * u * v
                    cand = [("wing" + s)] + (["chest"] if v < 0.18 else [])
                    row.append(b.vert((x, y, z), cand))
                ids.append(row)
            for iv in range(NV):
                for iu in range(NU):
                    u0, u1 = iu / NU, (iu + 1) / NU
                    v0, v1 = iv / NV, (iv + 1) / NV
                    a_, bb, c, d = ids[iv][iu], ids[iv][iu + 1], ids[iv + 1][iu + 1], ids[iv + 1][iu]
                    uu0, uu1 = (u0, u1) if sx > 0 else (1 - u0, 1 - u1)
                    T = lambda uu, vv: (uoff + uu * 0.5, 1 - vv)  # noqa: E731
                    b.quad((a_, bb, c, d), [T(uu0, v0), T(uu1, v0), T(uu1, v1), T(uu0, v1)], 1)


def paint_wing(img, px, seed):
    """One 256x512 panel: leaf-shaped membrane with white veins, lilac->gold gradient, violet cells, gold rim."""
    rng = np.random.default_rng(seed)
    W, H = 256, 512
    S = 2
    pnl = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(pnl)
    pts = []
    for i in range(41):                      # leaf outline, widest ~40% down, tip at the bottom
        t = i / 40
        wd = 0.5 * math.sin(math.pi * t ** 0.8) ** 0.8
        pts.append((W * S * (0.04 + 0.92 * wd * 1.9 * 0.5 + 0.0), H * S * (0.02 + 0.96 * t)))
    left = [(max(2.0, x0), y0) for x0, y0 in pts]
    outline = [(W * S * 0.04, H * S * 0.02)] + left + [(W * S * 0.04, H * S * 0.98)]
    mask = Image.new("L", (W * S, H * S), 0)
    ImageDraw.Draw(mask).polygon(outline, fill=255)
    # membrane gradient
    yy = np.linspace(0, 1, H * S)[:, None, None]
    top, mid, bot = np.array([140, 168, 30]), np.array([196, 198, 52]), np.array([250, 196, 60])
    g = np.where(yy < 0.5, top + (mid - top) * (yy / 0.5), mid + (bot - mid) * ((yy - 0.5) / 0.5))
    g = np.broadcast_to(g, (H * S, W * S, 3)).astype(np.uint8)
    pnl = Image.fromarray(g).convert("RGBA")
    d = ImageDraw.Draw(pnl)
    # veins: main spine along the left edge-ish, branching to the leaf edge
    for k in range(10):
        t = 0.06 + k * 0.09
        x0, y0 = W * S * 0.05, H * S * t
        x1 = W * S * (0.05 + 0.85 * math.sin(math.pi * min(t + 0.14, 1) ** 0.8) ** 0.8 * 0.95)
        y1 = H * S * min(t + 0.17, 0.98)
        d.line([(x0, y0), ((x0 + x1) / 2, (y0 + y1) / 2 - 12), (x1, y1)], fill=(52, 62, 14, 255), width=7)
        for j in range(1, 3):                # cross veins
            fx = j / 3
            d.line([(x0 + (x1 - x0) * fx, y0 + (y1 - y0) * fx), (x0 + (x1 - x0) * fx + 18, y0 + (y1 - y0) * fx + 46)],
                   fill=(70, 80, 20, 230), width=3)
    d.line([(W * S * 0.05, H * S * 0.02), (W * S * 0.06, H * S * 0.98)], fill=(40, 48, 10, 255), width=13)
    for (cx, cy, rx, ry) in ((0.55, 0.3, 0.12, 0.07), (0.38, 0.5, 0.1, 0.06), (0.52, 0.7, 0.09, 0.05)):   # violet wing spots
        d.ellipse([W * S * (cx - rx), H * S * (cy - ry), W * S * (cx + rx), H * S * (cy + ry)], fill=(40, 28, 62, 255))
    # gold rim: erode mask and tint the border
    inner = mask.filter(ImageFilter.MinFilter(15))
    rim = Image.composite(Image.new("RGBA", pnl.size, (60, 50, 24, 255)), pnl, ImageChops.invert(inner))
    pnl = rim
    pnl.putalpha(mask)
    pnl = pnl.resize((W, H), Image.LANCZOS)
    a = np.array(pnl.getchannel("A"))
    pnl.putalpha(Image.fromarray(np.where(a > 110, 255, 0).astype(np.uint8)))   # clean cutout edge for alpha-scissor
    img.paste(pnl, (px, 0))


def paint_face():
    """512x512 planar face map (u = x across the head, v = height): skin, yellow eyes with liner, third-eye mark."""
    S = 2
    W = 512 * S
    im = Image.new("RGB", (W, W), tuple(int(c * 255) for c in COL["skin"]))
    d = ImageDraw.Draw(im)
    hair = tuple(int(c * 255) for c in COL["hair"])
    d.rectangle([0, 0, W, int(W * 0.17)], fill=hair)                                    # hairline
    for k in range(9):
        x = W * (0.08 + k * 0.105)
        d.polygon([(x - 26, W * 0.15), (x + 30, W * 0.15), (x + 6, W * (0.22 + 0.05 * (k % 3)))], fill=hair)
    d.rectangle([0, 0, int(W * 0.09), W], fill=hair)
    d.rectangle([int(W * 0.91), 0, W, W], fill=hair)
    liner = (28, 16, 34)
    for sx in (-1, 1):
        cx, cy = W * (0.5 + sx * 0.235), W * 0.52
        ex, ey = W * 0.15, W * 0.095
        d.polygon([(cx - ex * 1.25, cy + ey * 0.2), (cx - ex * 0.4, cy - ey * 1.5), (cx + ex * 0.6, cy - ey * 1.45), (cx + ex * 1.3, cy - ey * 0.1 * sx),
                   (cx + ex * 0.4, cy + ey * 1.2), (cx - ex * 0.5, cy + ey * 1.1)], fill=liner)
        d.ellipse([cx - ex, cy - ey, cx + ex, cy + ey], fill=(255, 236, 150))
        d.ellipse([cx - ex * 0.62, cy - ey * 1.05, cx + ex * 0.62, cy + ey * 1.05], fill=(255, 196, 30))
        d.ellipse([cx - ex * 0.3, cy - ey * 0.5, cx + ex * 0.3, cy + ey * 0.5], fill=(40, 20, 12))
        d.ellipse([cx - ex * 0.28, cy - ey * 0.78, cx - ex * 0.02, cy - ey * 0.3], fill=(255, 255, 255))
        d.line([(cx - ex * 1.2, cy - ey * 1.7 - 18), (cx + ex * 1.1, cy - ey * 1.9 - 28 * sx)], fill=liner, width=int(W * 0.018))   # brow
        for k in range(3):                                                                                       # face marks
            d.line([(cx + sx * ex * 0.4, cy + ey * 2.2 + k * 26), (cx + sx * ex * (0.9 + 0.2 * k), cy + ey * 3.0 + k * 30)], fill=(80, 40, 40), width=8)
    r = W * 0.036
    d.ellipse([W * 0.5 - r, W * 0.30 - r, W * 0.5 + r, W * 0.30 + r], fill=(24, 12, 30))                         # third eye
    d.ellipse([W * 0.5 - r * 0.45, W * 0.30 - r * 0.75, W * 0.5 + r * 0.05, W * 0.30 - r * 0.25], fill=(255, 215, 90))
    d.ellipse([W * 0.5 - r * 1.5, W * 0.30 - r * 1.5, W * 0.5 + r * 1.5, W * 0.30 + r * 1.5], outline=(255, 205, 70), width=5)
    d.line([(W * 0.5, W * 0.57), (W * 0.49, W * 0.66)], fill=(190, 120, 90), width=8)                            # nose
    d.ellipse([W * 0.46, W * 0.655, W * 0.54, W * 0.675], fill=(165, 95, 80))
    d.line([(W * 0.43, W * 0.74), (W * 0.5, W * 0.755), (W * 0.57, W * 0.74)], fill=(120, 50, 60), width=9)    # mouth
    d.rectangle([0, int(W * 0.94), W, W], fill=tuple(int(c * 255) for c in COL["skin"]))
    return im.resize((512, 512), Image.LANCZOS)


def make_textures():
    img = Image.new("RGB", (GRID * 64, GRID * 64), (40, 40, 40))
    rng = np.random.default_rng(2)
    for i, nm in enumerate(CELLS):
        c = np.array(COL[nm]) * 255
        x0, y0 = (i % GRID) * 64, (i // GRID) * 64
        a = np.clip(c[None, None, :] + rng.normal(0, 5, (64, 64, 1)), 0, 255).astype(np.uint8)
        img.paste(Image.fromarray(a), (x0, y0))
    img.save(os.path.join(WORK, "cigarra_albedo.webp"), quality=92)
    w = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    paint_wing(w, 0, 1)
    paint_wing(w, 256, 2)
    w.save(os.path.join(WORK, "cigarra_wing.webp"), quality=90)
    paint_face().save(os.path.join(WORK, "cigarra_face.webp"), quality=92)
    return tuple(os.path.join(WORK, f) for f in ("cigarra_albedo.webp", "cigarra_wing.webp", "cigarra_face.webp"))


def material(name, path, alpha=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = 0.75 if not alpha else 0.4
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = bpy.data.images.load(path)
    t.image.alpha_mode = "STRAIGHT"
    nt.links.new(t.outputs["Color"], bs.inputs["Base Color"])
    if alpha:
        nt.links.new(t.outputs["Alpha"], bs.inputs["Alpha"])
        m.surface_render_method = "BLENDED"
        m.use_backface_culling = False
        nt.links.new(t.outputs["Color"], bs.inputs["Emission Color"])      # wings glow a little: read bright in shade
        bs.inputs["Emission Strength"].default_value = 0.12
    return m


def patch_alpha_mask(glb):
    """Blender exports the wing material as alphaMode BLEND; the leaf cut-out wants MASK (no sort artefacts on mobile)."""
    import struct
    data = open(glb, "rb").read()
    n = struct.unpack("<I", data[12:16])[0]
    js = json.loads(data[20:20 + n])
    for m in js.get("materials", []):
        if m.get("alphaMode") == "BLEND":
            m["alphaMode"] = "MASK"
            m["alphaCutoff"] = 0.5
    nj = json.dumps(js, separators=(",", ":")).encode()
    nj += b" " * ((4 - len(nj) % 4) % 4)
    rest = data[20 + n:]
    out = data[:8] + struct.pack("<I", 12 + 8 + len(nj) + len(rest)) + struct.pack("<I", len(nj)) + b"JSON" + nj + rest
    open(glb, "wb").write(out)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cfg = standin.STANDINS["cigarra"]
    J, Bn, S = standin.mirror(cfg)
    rig = standin.build_armature("Cigarra", J, Bn)
    b = build_geometry(J)
    wing_mesh(b, J)
    me = bpy.data.meshes.new("Cigarra")
    me.from_pydata(b.v, [], b.f)
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    uv.data.foreach_set("uv", np.array([u for f in b.uv for u in f], dtype=np.float32).ravel())
    me.polygons.foreach_set("material_index", np.array(b.mat, dtype=np.int32))
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Cigarra", me)
    bpy.context.scene.collection.objects.link(ob)
    alb, wing, face = make_textures()
    ob.data.materials.append(material("cigarra_body", alb))
    ob.data.materials.append(material("cigarra_wings", wing, alpha=True))
    ob.data.materials.append(material("cigarra_face", face))
    # skin: inverse-distance weights over the part's candidate bones
    bones = {bn.name: (np.array(bn.head_local), np.array(bn.tail_local)) for bn in rig.data.bones}

    def sd(p, a, c):
        ab = c - a
        t = np.clip(np.dot(p - a, ab) / (np.dot(ab, ab) + 1e-9), 0, 1)
        return np.linalg.norm(p - (a + ab * t))

    groups = {n: ob.vertex_groups.new(name=n) for n in bones if n != "root"}
    for i, (p, cand) in enumerate(zip(b.v, b.cand)):
        p = np.array(p)
        if len(cand) == 1:
            groups[cand[0]].add([i], 1.0, "REPLACE")
            continue
        d = np.array([sd(p, *bones[c]) for c in cand])
        w = 1.0 / (d + 0.03) ** 3
        w /= w.sum()
        for c, wi in zip(cand, w):
            if wi > 0.03:
                groups[c].add([i], float(wi), "REPLACE")
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    ob.select_set(False)
    from apply import apply_animations
    meta = apply_animations(rig, "cigarra")
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    glb = os.path.join(OUT, "cigarra.glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True, export_image_format="WEBP")
    patch_alpha_mask(glb)
    json.dump({"height_m": 1.65, "tris": tris, "fps": 30, "animations": meta}, open(os.path.join(OUT, "cigarra_anim.json"), "w"), indent=1)
    open(os.path.join(OUT, "cigarra_model.tscn"), "w").write(
        '[gd_scene load_steps=3 format=3]\n\n'
        '[ext_resource type="Script" path="res://game/art/models/character_model.gd" id="1"]\n'
        '[ext_resource type="PackedScene" path="res://game/art/models/cigarra/cigarra.glb" id="2"]\n\n'
        '[node name="CigarraModel" type="Node3D"]\nscript = ExtResource("1")\nmodel_scene = ExtResource("2")\n'
        'anim_json = "res://game/art/models/cigarra/cigarra_anim.json"\nheight_m = 1.65\ncharacter_id = "cigarra"\n'
        + cfg.get("tscn_extra", ""))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "cigarra_final.blend"))
    print("TRIS", tris, glb)


if __name__ == "__main__":
    main()
