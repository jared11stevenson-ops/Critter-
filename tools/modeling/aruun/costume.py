"""Aruun costume: thick cloth bands and trinkets (SDF), draped sheets (cloak, leaf skirt, strips, loincloth).

Sheet references (hires front/back/side): red waist sash over a cream band with a bone ring medallion at the
front and a long cream talisman below it; cream strips + a dark-red flap hanging in front; olive leaf panels
hanging around the back and sides to the shins; dark cloak draped over his RIGHT shoulder and down the back
(back view) with a bunched hood behind the neck (front view); cream bandage band around the chest, a leather
strap crossing from the left shoulder to the right hip, a cream bow at the throat; cream wraps at the wrists and
ankles/feet; a bead string at the right hip and an olive leaf charm on the chest strap.
"""
import math
import os
import sys

import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from common.sdf2 import (ellipsoid, capsule, tube, torus, union, smooth_union, intersect, subtract, offset,  # noqa
                         shell_cut, halfspace, euler, rot_to, fbm, ridged, T)
from common.cloth import Sheet, torn_edge  # noqa: E402
import sculpt as S  # noqa: E402

V = np.array


def _band(P, n, p0, w):
    """|n.(p-p0)| - w/2 : slab region (negative inside)."""
    n = np.asarray(n, float)
    n = T(n / np.linalg.norm(n))
    return torch.abs((P - T(p0)) @ n) - w * 0.5


def _wrap_folds(amp, freq, axis=(0, 0, 1), seed=0):
    ax = T(np.asarray(axis, float) / np.linalg.norm(axis))

    def fn(P):
        t = P @ ax
        return amp * (0.6 * torch.sin(t * freq + 3 * fbm(P, 8.0, 2, seed)) + 0.5 * fbm(P, 40.0, 2, seed + 1))
    return fn


def disp(f, fn):
    return lambda P: f(P) - fn(P)


def sdf_parts(body):
    """name -> (field, kind, bind, step)."""
    out = {}
    torso = S.SUB["torso"]
    hips = smooth_union([torso, S.SUB["leg.L"], S.SUB["leg.R"]], 0.03)
    # --- waist: red sash (thick wrapped cloth, slanting down to the front) over a cream band
    sash_reg = lambda P: _band(P, (0, -0.25, 1), (0, -0.02, 1.115), 0.1)
    sash = shell_cut(hips, 0.022, sash_reg, 0.008, 0.004)
    out["sash"] = (disp(sash, _wrap_folds(0.004, 140, (0, -0.25, 1), 3)), "cloth_red", "hips", 0.0025)
    band_reg = lambda P: _band(P, (0, -0.25, 1), (0, -0.02, 1.045), 0.035)
    out["waistband"] = (disp(shell_cut(hips, 0.01, band_reg, 0.004, 0.003), _wrap_folds(0.0015, 300, (0, -0.25, 1), 5)),
                        "cloth", "hips", 0.0022)
    # knot of the sash at his left hip
    kc = V([0.15, -0.07, 1.1])
    knot = smooth_union([ellipsoid(kc, (0.035, 0.03, 0.03)), ellipsoid(kc + V([0.02, -0.02, -0.03]), (0.02, 0.022, 0.035)),
                         ellipsoid(kc + V([-0.01, -0.025, -0.035]), (0.02, 0.02, 0.03))], 0.012)
    out["sashknot"] = (disp(knot, _wrap_folds(0.002, 200, (1, 0, 1), 9)), "cloth_red", "hips", 0.002)
    # --- medallion: bone ring at the front of the sash with a dark boss + talisman below
    mc = V([0, -0.165, 1.10])
    ring = torus(mc, 0.042, 0.011, rot_to((0, 0, 1), (0, -1, 0.1)))
    boss = ellipsoid(mc + V([0, 0.005, 0]), (0.03, 0.012, 0.03))
    out["medallion"] = (smooth_union([ring, union([boss, ellipsoid(mc + V([0, -0.008, 0]), (0.012, 0.008, 0.016))])], 0.004),
                        "bone", "hips", 0.0012)
    tal = tube([mc + V([0, 0.002, -0.05]), mc + V([0, -0.004, -0.11]), mc + V([0, -0.0, -0.19]), mc + V([0, 0.004, -0.25])],
               [0.012, 0.02, 0.016, 0.004], 0.01)
    tal = intersect(tal, lambda P: torch.abs(P[:, 1] - (mc[1] + 0.0)) - 0.011, 0.004)       # flattened pendant
    out["talisman"] = (smooth_union([tal, torus(mc + V([0, 0, -0.045]), 0.008, 0.003, rot_to((0, 0, 1), (1, 0, 0)))], 0.002),
                       "bone", "hips", 0.0012)
    # --- chest: cream bandage band below the pecs + leather strap L shoulder -> R hip (front and back)
    chest_reg = lambda P: _band(P, (0, -0.35, 1), (0, -0.04, 1.39), 0.06)
    out["chestwrap"] = (disp(shell_cut(torso, 0.008, chest_reg, 0.004, 0.006), _wrap_folds(0.0018, 260, (0, -0.35, 1), 11)),
                        "cloth", "chest", 0.0022)
    n = np.cross(V([-0.27, -0.0, -0.5]), V([0, 1, 0]))      # plane containing the diagonal and the depth axis
    strap_reg = lambda P: _band(P, n, (0.0, -0.03, 1.40), 0.035)
    strap = intersect(shell_cut(torso, 0.007, strap_reg, 0.003, 0.012), lambda P: P[:, 2] - 1.66)
    out["strap"] = (strap, "leather", "chest", 0.002)
    bk = V([-0.075, -0.17, 1.30])
    out["buckle"] = (subtract(ellipsoid(bk, (0.022, 0.008, 0.026), euler(0, 0.5, 0)),
                              ellipsoid(bk + V([0, -0.004, 0]), (0.012, 0.02, 0.015), euler(0, 0.5, 0)), 0.002),
                     "gold", "chest", 0.001)
    # --- throat bow (cream) with two tails
    tc = V([0, -0.155, 1.645])
    bow = [ellipsoid(tc, (0.02, 0.016, 0.018))]
    for s in (1, -1):
        bow.append(ellipsoid(tc + V([s * 0.03, 0.004, 0.006]), (0.028, 0.012, 0.018), euler(0, s * 0.3, 0)))
        bow.append(tube([tc + V([s * 0.008, -0.004, -0.01]), tc + V([s * 0.02, -0.012, -0.07]), tc + V([s * 0.026, -0.008, -0.13])],
                        [0.01, 0.009, 0.007], 0.004))
    out["bow"] = (disp(smooth_union(bow, 0.006), _wrap_folds(0.001, 400, (1, 0, 0), 13)), "cloth", "chest", 0.0015)
    # --- hood: bunched cloak hood lying behind the neck base (front view), dark cloth
    hc = V([0, 0.06, 1.66])
    hood = smooth_union([torus(hc + V([0, -0.04, 0.0]), 0.105, 0.035, euler(0.25, 0, 0)),
                         ellipsoid(hc + V([0.0, 0.07, -0.03]), (0.12, 0.06, 0.08), euler(0.3, 0, 0)),
                         ellipsoid(hc + V([-0.1, 0.0, -0.02]), (0.08, 0.08, 0.07))], 0.03)
    hood = intersect(hood, lambda P: -(P[:, 1] - (-0.06)), 0.02)                    # nothing in front of the throat
    hood = subtract(hood, S.SUB["neck"], 0.01)
    out["hood"] = (disp(hood, lambda P: 0.008 * fbm(P, 14.0, 3, 21) + 0.002 * ridged(P, 60.0, 2, 22)), "cloak", "chest", 0.0025)
    # --- wrist wraps + ankle/foot wraps (cream bandage)
    for side in ("L", "R"):
        s = 1 if side == "L" else -1
        el, wr = S.jm("elbow." + side), S.jm("wrist." + side)
        ax = (wr - el) / np.linalg.norm(wr - el)
        arm = S.SUB["arm." + side]
        wreg = lambda P, ax=ax, el=el, wr=wr: _band(P, ax, el + (wr - el) * 0.8, 0.06)
        out["wristwrap." + side] = (disp(shell_cut(arm, 0.007, wreg, 0.003, 0.004), _wrap_folds(0.0015, 420, ax, 30 + s)),
                                    "cloth", "forearm." + side, 0.0018)
        an, toe = S.jm("ankle." + side), S.jm("toe." + side)
        legfoot = smooth_union([S.SUB["leg." + side], S.SUB["foot." + side]], 0.02)
        regs = [lambda P, an=an: _band(P, (0, 0.2, 1), an + V([0, 0, -0.02]), 0.07),
                lambda P, an=an, toe=toe: _band(P, (s * 0.3, -0.6, 0.75), (an + toe) / 2 + V([0, 0, -0.02]), 0.035),
                lambda P, an=an, toe=toe: _band(P, (-s * 0.3, -0.6, 0.75), (an + toe) / 2 + V([0, 0.05, -0.05]), 0.03)]
        wraps = union([shell_cut(legfoot, 0.008, r, 0.003, 0.004 + 0.003 * k) for k, r in enumerate(regs)])
        out["footwrap." + side] = (disp(intersect(wraps, lambda P: 0.004 - P[:, 2]),
                                        _wrap_folds(0.0015, 380, (0, 0, 1), 40 + s)), "cloth", "foot." + side, 0.002)
    # --- bead string at the right hip and a leaf charm on the chest strap
    beads = []
    b0 = V([-0.15, -0.09, 1.08])
    for k in range(9):
        t = k / 8
        p = b0 + V([-0.012 * math.sin(t * 3), -0.01 * t, -0.17 * t + 0.03 * t * t])
        beads.append(ellipsoid(p, (0.011, 0.011, 0.011)) if k % 3 else ellipsoid(p, (0.014, 0.014, 0.016)))
    beads.append(tube([b0 + V([0, -0.01, -0.17]), b0 + V([-0.005, -0.012, -0.24])], [0.012, 0.002]))     # claw pendant
    out["beads"] = (union(beads), "bone", "hips", 0.0012)
    lc = V([0.095, -0.155, 1.48])
    out["leafcharm"] = (union([ellipsoid(lc + V([0, 0, -0.06]), (0.026, 0.006, 0.07), euler(0.15, 0, 0.15)),
                               tube([lc + V([0, 0, 0.03]), lc + V([0, 0, -0.005])], [0.002, 0.002])]), "leaf", "chest", 0.0012)
    return out


# ------------------------------------------------------------------------------------------------ sheets
def _waist_point(phi, z=1.085, rx=0.175, ry=0.14, cy=-0.02):
    return np.stack([rx * np.cos(phi), cy + ry * np.sin(phi), np.full_like(phi, z)], -1)


def sheets():
    out = []
    # LEAF SKIRT: olive leaf panels around the back and sides (angles: +X = 0, back +Y = 90 deg)
    rng = np.random.default_rng(8)
    angles = [-20, 5, 30, 55, 80, 100, 125, 150, 175, 200]
    for k, a in enumerate(angles):
        phi0 = math.radians(a)
        L = rng.uniform(0.55, 0.72) * (0.85 if a in (-20, 200) else 1.0)
        w = 0.13

        def shape(U, Vv, phi0=phi0, L=L, w=w):
            phi = phi0 + (U - 0.5) * w / 0.16
            top = _waist_point(phi, z=1.09)
            rad = np.stack([np.cos(phi), np.sin(phi), np.zeros_like(phi)], -1)
            return top + rad * (0.035 + 0.13 * Vv ** 1.2)[..., None] + np.array([0, 0, -1.0]) * (L * Vv)[..., None]

        def alpha(u, v, seed=k):
            r = np.random.default_rng(seed)
            tipv = 1.0 - r.uniform(0, 0.08)
            width = np.clip(np.sin(np.pi * np.clip(v * 0.92 + 0.08, 0, 1) ** 0.85), 0, 1) ** 0.6
            jag = 0.04 * np.sin(v * 41 + seed) + 0.03 * np.sin(v * 97 + seed * 2)
            return ((np.abs(u - 0.5) < 0.5 * width + jag) & (v < tipv)).astype(np.float32)

        out.append(Sheet("leaf%d" % k, shape, kind="leaf", bind="skirt", nu=3, nv=10, thick=0.004, gap=0.02,
                         folds=lambda U, Vv: 0.012 * (1 - np.abs(2 * U - 1)) * np.sin(np.pi * Vv) ** 0.5,
                         wrinkle=0.001, alpha=alpha, smooth=0.25))
    # FRONT: cream strips + a dark-red flap under them
    for k, (a, L, wd) in enumerate(((-78, 0.30, 0.045), (-86, 0.36, 0.05), (-94, 0.33, 0.05), (-102, 0.28, 0.045),
                                    (-70, 0.24, 0.04), (-110, 0.26, 0.04))):
        phi0 = math.radians(a)

        def shape(U, Vv, phi0=phi0, L=L, wd=wd):
            phi = phi0 + (U - 0.5) * wd / 0.15
            top = _waist_point(phi, z=1.075, ry=0.15)
            rad = np.stack([np.cos(phi), np.sin(phi), np.zeros_like(phi)], -1)
            return top + rad * (0.03 + 0.03 * Vv)[..., None] + np.array([0, 0, -1.0]) * (L * Vv)[..., None]
        out.append(Sheet("strip%d" % k, shape, kind="cloth", bind="skirt", nu=2, nv=6, thick=0.004, gap=0.025,
                         wrinkle=0.0012, alpha=torn_edge(50 + k, 0.12, 3.0), smooth=0.2))

    def flap(U, Vv):
        phi = math.radians(-90) + (U - 0.5) * 0.17 / 0.15
        top = _waist_point(phi, z=1.07, ry=0.145)
        rad = np.stack([np.cos(phi), np.sin(phi), np.zeros_like(phi)], -1)
        return top + rad * (0.015 + 0.02 * Vv)[..., None] + np.array([0, 0, -1.0]) * (0.42 * Vv)[..., None]
    out.append(Sheet("flap", flap, kind="cloth_red", bind="skirt", nu=5, nv=8, thick=0.005, gap=0.015,
                     folds=lambda U, Vv: 0.008 * np.sin(U * 9.4) * Vv, wrinkle=0.0015, alpha=torn_edge(77, 0.1, 4.0)))

    # CLOAK over his right shoulder: top edge around the neck base from front-right over the right shoulder to the
    # back-left; short in front, long down the back.
    c = np.array([0.0, -0.04, 1.665])

    def cloak(U, Vv):
        phi = np.radians(250 - U * 150)               # 250 (front-right) -> 100 (just past the back centre)
        rad = np.stack([np.cos(phi), np.sin(phi), np.zeros_like(phi)], -1)
        # length by angle: front 0.25, right side 0.5, back 1.15
        back = np.clip(np.sin(phi), 0, 1)
        side = np.clip(-np.cos(phi), 0, 1)
        L = 0.25 + 0.3 * side + 0.85 * back ** 0.7
        top = c + rad * np.where(back > 0, 0.11, 0.1)[..., None] + np.array([0, 0, 0.0])
        over = np.where(Vv < 0.25, Vv / 0.25, 1.0)
        out_r = (0.1 + 0.14 * side + 0.06 * back) * over
        drop = np.clip(Vv - 0.12, 0, None) / 0.88 * L
        return top + rad * out_r[..., None] + np.array([0, 0, -1.0]) * drop[..., None] + np.array([0, 0, 0.05]) * \
            (1 - over)[..., None]

    def cloak_alpha(u, v):
        a = torn_edge(91, 0.14, 5.0)(u, v)
        # long ragged strips at the back: deep vertical tears in the lower half
        tears = (np.abs(np.sin(u * 37.0 + 1.3)) < 0.18) & (v > 0.55 + 0.2 * np.abs(np.sin(u * 13)))
        return (a * (~tears)).astype(np.float32)
    out.append(Sheet("cloak", cloak, kind="cloak", bind="cloak", nu=12, nv=16, thick=0.006, gap=0.02,
                     folds=lambda U, Vv: 0.02 * np.sin(U * 31.0 + 1.0) * np.clip(Vv - 0.2, 0, 1) +
                     0.008 * np.sin(U * 71.0) * Vv, wrinkle=0.002, alpha=cloak_alpha, iters=10, smooth=0.3))
    return out
