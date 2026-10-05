"""Aruun v3 body/gear/horn paint: clean region-based plates (Worley cells = plate shapes, zone = which plate colour),
outlined in dark line work with edge wear and spots, in the sheet palette. Object-space, seam-free."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common.texbake import smooth, mix, hash1, vnoise, worley
from paint_head import DARK, PLUM, RED, REDHI, REDDK, CREAM, TAN, BONE, OLIVE, NAVY, NECK, line

OCHRE = np.array([222, 168, 92.]); CHITIN = np.array([40, 31, 42.]); WINE = np.array([140, 40, 38.]); BROWN = np.array([86, 66, 54.])
SH = {"L": np.array([0.235, -0.06, 1.625]), "R": np.array([-0.225, -0.06, 1.665])}


def zones(P, N, kind):
    """(red, bone) probabilities per texel + cell size choice"""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]; ax = np.abs(x)
    front = smooth(-0.15, -0.5, N[:, 1]); back = smooth(0.15, 0.5, N[:, 1])
    pr = np.full(len(P), 0.12); pb = np.full(len(P), 0.10)
    if kind == "trunk":
        pr = 0.10 + 0.35 * back * smooth(1.28, 1.45, z) + 0.12 * front * smooth(1.55, 1.7, z)
        pb = 0.12 + 0.5 * front * smooth(1.25, 1.4, z) * smooth(1.72, 1.6, z) + 0.28 * back * smooth(1.15, 1.35, z)
    elif kind in ("armL", "armR"):
        up = smooth(1.25, 1.4, z); fore = smooth(1.28, 1.15, z) * smooth(0.88, 1.0, z)
        pr = 0.15 + 0.45 * up + 0.65 * fore; pb = 0.08 + 0.12 * fore + 0.1 * up
        hand = smooth(0.95, 0.88, z); pr = pr * (1 - hand) + 0.05 * hand; pb = pb * (1 - hand) + 0.35 * hand
    elif kind in ("legL", "legR"):
        thigh = smooth(0.58, 0.72, z); knee = smooth(0.42, 0.52, z) * smooth(0.72, 0.62, z); foot = smooth(0.28, 0.18, z)
        pb = 0.12 + 0.52 * thigh * (1 - knee) + 0.25 * foot; pr = 0.12 + 0.8 * knee + 0.15 * thigh + 0.2 * (1 - foot) * (1 - thigh) * (1 - knee)
    return pr, pb


def paint_plated(P, N, kind, seed=0):
    """Plate patchwork: elongated Worley cells (plates) coloured by anatomical zone, thick ink outlines, shaded domes,
    big ochre spots on red plates. Large, calm, deliberate shapes (no speckle)."""
    n = len(P); pr, pb = zones(P, N, kind)
    L = 0.115 if kind == "trunk" else 0.095
    Pz = P * np.array([1.0, 1.0, 0.62])                       # plates elongated along the limb/trunk axis
    f1, f2, cid, cen = worley(Pz, L * 0.8, seed=seed + 7, jitter=0.9)
    u = hash1(cid, 3 + seed); edge = (f2 - f1) / 0.62 * 0.62
    cls = np.where(u < pr, 0, np.where(u < pr + pb, 1, 2))     # 0 red 1 bone 2 dark
    t1 = hash1(cid, 11)[:, None]; t2 = hash1(cid, 13)[:, None]; t3 = hash1(cid, 17)[:, None]
    col = np.where((cls == 0)[:, None], WINE[None] * (1 - t1) + RED[None] * t1, 0.0)
    col = np.where((cls == 1)[:, None], TAN[None] * (1 - t2) + CREAM[None] * t2, col)
    col = np.where((cls == 2)[:, None], CHITIN[None] * (1 - t3) + PLUM[None] * t3 * 0.9, col)
    rr = np.clip(f1 / (0.7 * L * 0.8), 0, 1)
    shade = 1.14 - 0.38 * rr ** 1.5 + 0.10 * N[:, 2]
    col = col * shade[:, None]
    ln = 1 - smooth(0.0022, 0.0050, edge)
    rim = (1 - smooth(0.0050, 0.0105, edge)) * smooth(0.0022, 0.0050, edge)
    col = mix(col, np.where((cls == 0)[:, None], CREAM[None] * 0.9, col * 1.22), rim * np.where(cls == 2, 0.25, 0.6))
    col = mix(col, DARK * 0.7, ln * 0.95)
    d = np.linalg.norm(P - cen, axis=1); R0 = 0.020 + 0.012 * hash1(cid, 23)
    sp = (cls == 0) & (hash1(cid, 19) < 0.55)
    col = mix(col, DARK * 0.8, sp * line(d - R0 * 1.15, 0.0028) * 0.95)
    col = mix(col, mix(OCHRE, CREAM, hash1(cid, 29)[:, None] * 0.5), sp * smooth(R0, R0 * 0.85, d))
    col = mix(col, DARK * 0.6, sp * smooth(R0 * 0.35, R0 * 0.2, d) * 0.8)
    hgt = 0.9 * smooth(0.0, 0.012, edge) - 0.8 * ln + 0.6 * sp * smooth(R0, R0 * 0.8, d)
    rough = np.where(cls == 1, 0.62, np.where(cls == 0, 0.38, 0.32))
    return col, rough, hgt, cls


def pauldron(P, N, col, hgt, rough):
    """big red ladybug pauldron domes with cream rim and ochre spot on the outer pole"""
    for k, c in SH.items():
        sg = 1 if k == "L" else -1
        v = P - c; d = np.linalg.norm(v, axis=1)
        pole = np.array([sg * 0.80, -0.35, 0.45]); pole /= np.linalg.norm(pole)
        ang = np.arccos(np.clip((v / np.maximum(d[:, None], 1e-9)) @ pole, -1, 1)) * 0.17          # arc length on R~0.17
        inside = smooth(0.150, 0.136, d) * smooth(0.135, 0.120, ang * 1.0 + 0.0) * 0 + smooth(0.145, 0.13, d) * (ang < 0.115)
        plate = (ang < 0.108) * (d < 0.16) * (d > 0.095)
        t = smooth(0.108, 0.104, ang) * (d > 0.10) * (d < 0.17)
        base = mix(RED, REDHI, smooth(0.09, 0.0, ang) * 0.55 + 0.1 * vnoise(P, 40, 4))
        base = mix(base, WINE, smooth(0.04, 0.108, ang) * 0.5)
        col = mix(col, base * (0.95 + 0.1 * N[:, 2:3] * 0 + 0), t)
        col = mix(col, CREAM, line(ang - 0.108, 0.0042) * t * 1.0 + 0)
        col = mix(col, DARK * 0.8, line(ang - 0.116, 0.0022) * (d > 0.10) * (d < 0.17) * 0.9)
        # ochre spot with dark ring (the sheet's yellow/black spots)
        col = mix(col, DARK * 0.8, line(ang - 0.050, 0.0042) * t)
        col = mix(col, mix(OCHRE, CREAM, 0.35), smooth(0.047, 0.040, ang) * t)
        col = mix(col, DARK * 0.6, smooth(0.016, 0.010, ang) * t * 0.9)
        hgt += 1.2 * t
        rough = np.where(t > 0.5, 0.30, rough)
    return col, hgt, rough


def neck_belt(P, N, col, hgt, kind):
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    if kind == "trunk":
        nk = smooth(1.66, 1.74, z) * smooth(0.25, 0.16, np.abs(x))
        c = mix(NECK, REDHI, 0.25 * vnoise(P, 30, 12)) * (0.88 + 0.2 * smooth(-1, -0.2, N[:, 1]))[:, None] if False else mix(NECK, REDHI, 0.25 * vnoise(P, 30, 12))
        c = mix(c, REDDK, smooth(0.1, 0.5, N[:, 1]) * 0.8)                # back of neck darker
        g1, g2, gid, gc = worley(P, 0.04, seed=77)
        dash = (g1 < 0.0045) & (hash1(gid, 5) < 0.35)
        c = mix(c, CREAM, dash * 0.85)
        col = mix(col, c, nk)
        # belt: tan wrap band + dark stitch lines
        bnd = smooth(1.135, 1.150, z) * smooth(1.235, 1.220, z)
        bc = mix(TAN, CREAM, 0.25 * vnoise(P, 50, 14))
        bc = mix(bc, DARK * 0.8, line(z - 1.19, 0.0045) * 0.6 + line(z - 1.14, 0.0025) * 0.9 + line(z - 1.23, 0.0025) * 0.9)
        col = mix(col, bc, bnd)
        ring = np.hypot(x - 0.0, (z - 1.19) * 1.0)
        hgt += 0.8 * bnd
    return col, hgt


def paint_horn(sp, P, N):
    n = len(P); t = sp
    col = mix(RED, REDHI, 0.25 * vnoise(P, 45, 21)); col = mix(col, WINE, smooth(0.0, 0.25, 0.25 - t))
    knob = (np.cos(2 * np.pi * t * 3.0) ** 2) ** 2.5
    col = mix(col, CREAM, smooth(0.80, 0.97, knob) * 0.95)
    col = mix(col, DARK * 0.8, line(np.abs(np.sin(2 * np.pi * t * 3.0)) - 0.12, 0.012) * 0.0)
    # lighter spine highlight along the top, dark underside
    col = col * (0.82 + 0.28 * smooth(-0.6, 0.8, N[:, 2]))[:, None]
    col = mix(col, TAN, smooth(0.86, 0.98, t) * 0.8)
    stripe = line(np.sin(vnoise(P, 18, 22) * 40), 0.08) * 0.0
    return col, np.full(n, 0.4), 0.8 * (smooth(0.55, 0.9, knob)) - 0.3 * line(np.abs(np.sin(2 * np.pi * t * 3.0)) - 0.0, 0.05) * 0


def paint_card(name, sp, P, N):
    n = len(P); t = sp
    if name == "card_mantle":
        col = mix(BROWN * 0.75, np.array([62, 52, 50.]), vnoise(P, 22, 31)); col = mix(col, CREAM * 0.8, smooth(0.93, 0.99, t))
        col = mix(col, DARK * 0.8, line(t - 0.9, 0.012) * 0.8)
        return col, np.full(n, 0.8)
    if name == "card_fringe":
        col = mix(CREAM, TAN, t * 0.6); col = mix(col, OLIVE, smooth(0.7, 1.0, t) * 0.5); return col, np.full(n, 0.8)
    if name == "card_leaf_olive":
        col = mix(OLIVE * 1.1, OLIVE * 0.7, t) ; col = mix(col, np.array([150, 130, 80.]), smooth(0.2, 0.0, t) * 0.4); return col, np.full(n, 0.75)
    if name == "card_leaf_dark":
        return mix(np.array([76, 66, 44.]), np.array([46, 40, 36.]), t), np.full(n, 0.75)
    if name == "card_tassel":
        col = mix(CREAM, TAN, t * 0.5); col = mix(col, OCHRE, smooth(0.78, 0.95, t)); return col, np.full(n, 0.8)
    return np.tile(TAN, (n, 1)), np.full(n, 0.8)


def paint_morrow(name, P, N):
    n = len(P); nm = name.replace("legacy_morrow_", "")
    if nm == "core":
        return np.tile(np.array([205, 52, 46.]), (n, 1)), np.full(n, 0.25)
    if nm in ("stud", "spike", "rim"):
        return mix(TAN, CREAM, 0.3 + 0.2 * vnoise(P, 40, 3)), np.full(n, 0.6)
    if nm == "head":
        return mix(np.array([52, 40, 50.]), np.array([84, 62, 62.]), vnoise(P, 30, 4)), np.full(n, 0.5)
    return mix(np.array([84, 62, 50.]), np.array([120, 96, 60.]), vnoise(P, 35, 5)), np.full(n, 0.75)
