"""Aruun v3 body/gear/horn paint: clean region-based plates (Worley cells = plate shapes, zone = which plate colour),
outlined in dark line work with edge wear and spots, in the sheet palette. Object-space, seam-free."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common.texbake import smooth, mix, hash1, vnoise, worley
from paint_head import DARK, PLUM, RED, REDHI, REDDK, CREAM, TAN, BONE, OLIVE, NAVY, NECK, line

OCHRE = np.array([222, 168, 92.]); CHITIN = np.array([40, 31, 42.]); WINE = np.array([140, 40, 38.]); BROWN = np.array([86, 66, 54.]); NAVYC = np.array([54, 46, 72.]); ORANGEC = np.array([204, 98, 46.])
SH = {"L": np.array([0.235, -0.06, 1.625]), "R": np.array([-0.225, -0.06, 1.665])}


def zones(P, N, kind):
    """(red, bone, orange) probabilities per texel. Sheet balance: ~65% near-black navy chitin, red only on pauldrons/vambraces/back blades,
    tan plates on abdomen/knees/hamstrings/sabatons, orange mottling on the shins."""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]; ax = np.abs(x)
    front = smooth(-0.15, -0.5, N[:, 1]); back = smooth(0.15, 0.5, N[:, 1])
    pr = np.full(len(P), 0.05); pb = np.full(len(P), 0.06); po = np.zeros(len(P))
    if kind == "trunk":
        pr = 0.03 + 0.17 * back * smooth(1.3, 1.5, z)
        pb = 0.05 + 0.34 * front * smooth(1.22, 1.36, z) * smooth(1.72, 1.6, z) + 0.16 * back * smooth(1.2, 1.4, z)
    elif kind in ("armL", "armR"):
        up = smooth(1.3, 1.45, z); fore = smooth(1.28, 1.15, z) * smooth(0.88, 1.0, z); hand = smooth(0.95, 0.88, z)
        pr = 0.05 + 0.18 * up + 0.62 * fore; pb = 0.06 + 0.10 * fore
        pr = pr * (1 - hand) + 0.02 * hand; pb = pb * (1 - hand) + 0.30 * hand
    elif kind in ("legL", "legR"):
        thigh = smooth(0.62, 0.74, z); knee = smooth(0.42, 0.50, z) * smooth(0.70, 0.60, z); shin = smooth(0.50, 0.40, z) * smooth(0.22, 0.30, z); foot = smooth(0.28, 0.18, z)
        pb = 0.05 + 0.12 * thigh + 0.55 * knee + 0.40 * foot + 0.12 * back * (1 - knee) * (1 - foot)
        pr = 0.04 + 0.10 * knee; po = 0.42 * shin + 0.05 * thigh
    return pr, pb, po


def paint_plated(P, N, kind, seed=0):
    """Plate patchwork: elongated Worley cells (plates) coloured by anatomical zone, thick ink outlines, shaded domes,
    big ochre spots on red plates. Large, calm, deliberate shapes (no speckle)."""
    n = len(P); pr, pb, po = zones(P, N, kind)
    L = 0.115 if kind == "trunk" else 0.095
    Pz = P * np.array([1.0, 1.0, 0.62])                       # plates elongated along the limb/trunk axis
    f1, f2, cid, cen = worley(Pz, L * 0.8, seed=seed + 7, jitter=0.9)
    u = hash1(cid, 3 + seed); edge = (f2 - f1) / 0.62 * 0.62
    cls = np.where(u < pr, 0, np.where(u < pr + pb, 1, np.where(u < pr + pb + po, 3, 2)))     # 0 red 1 bone 2 dark 3 orange
    t1 = hash1(cid, 11)[:, None]; t2 = hash1(cid, 13)[:, None]; t3 = hash1(cid, 17)[:, None]
    col = np.where((cls == 0)[:, None], WINE[None] * (1 - t1) + RED[None] * t1, 0.0)
    col = np.where((cls == 1)[:, None], TAN[None] * (1 - t2) + CREAM[None] * t2, col)
    col = np.where((cls == 2)[:, None], CHITIN[None] * (1 - t3) + NAVYC[None] * t3, col)
    col = np.where((cls == 3)[:, None], WINE[None] * (1 - t2) + ORANGEC[None] * t2, col)
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
    GREY = np.array([78, 72, 60.]); OLV = np.array([126, 116, 62.]); NAV = np.array([46, 40, 52.])
    if name == "card_mantle":
        col = mix(GREY, np.array([62, 54, 56.]), vnoise(P, 22, 31)); col = mix(col, OLV * 0.8, smooth(0.62, 0.8, vnoise(P, 28, 32)) * 0.5)
        col = mix(col, CREAM * 0.85, smooth(0.93, 0.985, t)); col = mix(col, DARK * 0.8, line(t - 0.915, 0.010) * 0.85)
        return col, np.full(n, 0.8)
    if name == "card_fringe":      # ragged cloak tails: dark olive-grey, pale drips at the tips
        col = mix(GREY * 1.05, OLV * 0.75, smooth(0.2, 0.7, t) * 0.5); col = mix(col, CREAM * 0.85, smooth(0.68, 0.95, t) * 0.9)
        col = mix(col, DARK * 0.8, line(t - 0.66, 0.012) * 0.6); return col, np.full(n, 0.8)
    if name == "card_leaf_olive":  # olive leaf panels, dark ragged tips, pale mid-vein glow
        col = mix(OLV * 1.05, OLV * 0.8, vnoise(P, 30, 33)); col = mix(col, np.array([170, 156, 92.]), smooth(0.35, 0.0, t) * 0.5)
        col = mix(col, NAV, smooth(0.62, 0.86, t + 0.12 * (vnoise(P, 60, 34) - 0.5)) * 0.95); return col, np.full(n, 0.75)
    if name == "card_leaf_dark":
        col = mix(NAV * 1.1, OLV * 0.7, smooth(0.3, 0.0, t) * 0.7); col = mix(col, DARK, smooth(0.6, 0.9, t) * 0.5); return col, np.full(n, 0.75)
    if name == "card_tassel":
        col = mix(CREAM * 0.95, TAN, t * 0.4 + 0.2 * vnoise(P, 50, 35)); col = mix(col, WINE, smooth(0.82, 0.96, t) * 0.8)
        col = mix(col, DARK * 0.7, (hash1(np.floor(P[:, 0] * 90).astype(np.int64), 6) > 0.93) * 0.6); return col, np.full(n, 0.8)
    return np.tile(TAN, (n, 1)), np.full(n, 0.8)


def paint_mane(sp):
    n = len(sp); var = np.floor(sp / 2.0 + 1e-4); t = sp - 2.0 * var
    base = np.tile(np.array([226, 206, 158.]), (n, 1))
    base = np.where((var == 1)[:, None], np.array([228, 204, 112.]), base)
    base = np.where((var == 2)[:, None], np.array([122, 114, 62.]), base)
    base = base * (0.55 + 0.5 * smooth(0.0, 0.7, t))[:, None]
    base = mix(base, np.array([240, 228, 190.]), smooth(0.8, 1.0, t) * 0.4 * (var != 2))
    return base, np.full(n, 0.6)


def paint_claw(sp, P):
    n = len(P); t = sp
    col = mix(np.array([54, 44, 46.]), np.array([196, 168, 124.]), smooth(0.05, 0.5, t)); col = mix(col, np.array([232, 214, 172.]), smooth(0.7, 1.0, t))
    return col, np.full(n, 0.45)


def paint_trinket(name, sp, P, N):
    n = len(P)
    if name == "buckle_ring": return mix(CREAM * 0.97, TAN, 0.3 * vnoise(P, 50, 8)), np.full(n, 0.55), np.zeros((n, 3))
    if name == "medallion":
        c = P.mean(0); d = np.linalg.norm((P - c) * np.array([1, 3, 1]), axis=1)
        col = mix(np.array([200, 176, 128.]), OCHRE, smooth(0.01, 0.03, d)); col = mix(col, DARK * 0.7, smooth(0.012, 0.006, d) * 0.9)
        return col, np.full(n, 0.35), np.zeros((n, 3))
    if name.startswith("bead"): return np.tile(np.array([176, 40, 38.]), (n, 1)), np.full(n, 0.4), np.zeros((n, 3))
    return np.tile(TAN * 1.05, (n, 1)), np.full(n, 0.5), np.zeros((n, 3))


def paint_morrow(name, P, N):
    n = len(P); nm = name.replace("legacy_morrow_", "")
    if nm == "core":
        return np.tile(np.array([205, 52, 46.]), (n, 1)), np.full(n, 0.25)
    if nm in ("stud", "spike", "rim"):
        return mix(TAN, CREAM, 0.3 + 0.2 * vnoise(P, 40, 3)), np.full(n, 0.6)
    if nm == "head":
        return mix(np.array([52, 40, 50.]), np.array([84, 62, 62.]), vnoise(P, 30, 4)), np.full(n, 0.5)
    return mix(np.array([84, 62, 50.]), np.array([120, 96, 60.]), vnoise(P, 35, 5)), np.full(n, 0.75)
