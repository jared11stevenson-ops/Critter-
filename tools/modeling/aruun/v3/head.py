#!/usr/bin/env python3
"""Aruun v3: DEDICATED head, sculpted with signed-distance fields (common/sdf2) from the sheet's head crops
(design/model_sheets/aruun/detail_head.png): long dragon/horse snout with a downward chin hook, brow ridges over
eye sockets on the sides, cheek plates, red crown plates + horn cups, nostrils, separate mandible (jaw bone) with
fangs/teeth/tongue.   python3 head.py  -> work/v3/head_raw.npz  (pieces: skull, jaw, eyes, teeth_up, teeth_lo, tongue)

Head-local frame (metres): x lateral (+x = his left), f forward (world -Y), z up.  Origin = cranium centre.
"""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import sdf2 as S
WORK = os.path.join(HERE, "..", "work", "v3"); os.makedirs(WORK, exist_ok=True)

# world placement of the head-local origin
ORIGIN = np.array([0.085, -0.050, 2.045])
SCALE = 0.92          # head is exaggerated a touch for phone readability


def W(p):
    """head-local (x, f, z) -> world (x, y, z) in the same units (no scale)"""
    p = np.asarray(p, float)
    return np.array([p[0], -p[1], p[2]])


def E(c, r, rot=None):
    return S.ellipsoid(W(c), r, rot)


def cap(a, b, ra, rb=None):
    return S.capsule(W(a), W(b), ra, rb)


def skull_field():
    parts = []
    # braincase, a bit flattened, pushed back
    parts.append(E((0, -0.012, 0.0), (0.071, 0.082, 0.070)))
    # snout: three overlapping ellipsoids = long tapering muzzle drooping slightly
    parts.append(E((0, 0.110, -0.020), (0.054, 0.085, 0.042)))
    parts.append(E((0, 0.185, -0.032), (0.037, 0.070, 0.031)))
    parts.append(E((0, 0.245, -0.040), (0.029, 0.030, 0.027)))        # nose pad
    # nose bridge ridge
    parts.append(cap((0, 0.02, 0.05), (0, 0.24, -0.010), 0.014, 0.011))
    for s in (-1, 1):
        # brow ridge: heavy bar over the eye socket sweeping up and back
        parts.append(cap((s * 0.030, 0.100, 0.034), (s * 0.072, 0.040, 0.044), 0.017, 0.013))
        parts.append(cap((s * 0.072, 0.040, 0.044), (s * 0.074, -0.020, 0.030), 0.013, 0.010))
        # cheek plate (zygomatic) + lip plate along the upper jaw
        parts.append(E((s * 0.060, 0.020, -0.034), (0.016, 0.052, 0.036), S.euler(0.0, 0.0, s * 0.18)))
        parts.append(E((s * 0.040, 0.150, -0.044), (0.014, 0.075, 0.016), S.euler(0.0, 0.0, s * 0.12)))
        # horn cups / crown plates
        parts.append(cap((s * 0.044, -0.020, 0.035), (s * 0.050, -0.030, 0.092), 0.034, 0.026))
        # temple knob (bone tine root)
        parts.append(E((s * 0.076, -0.030, 0.005), (0.012, 0.016, 0.012)))
    # sagittal crest plates
    for k, (f, h) in enumerate(((0.012, 0.085), (-0.030, 0.095), (-0.065, 0.08))):
        parts.append(cap((0, f, 0.05), (0, f - 0.018, h), 0.017 - 0.002 * k, 0.006))
    body = S.smooth_union(parts, k=0.014)
    # brow flare keeps its edge: re-union a few without smoothing
    # cut the underside flat = palate (mouth line); slopes down toward the nose
    n = np.array([0.0, 0.06, -1.0]); n /= np.linalg.norm(n)
    body = S.intersect(body, S.halfspace(n, W((0, 0.0, -0.034))), 0.0)
    # jaw-hinge muscle block behind/below the palate cut so the back of the head has depth
    blocks = [E((s * 0.048, -0.025, -0.052), (0.024, 0.042, 0.028)) for s in (-1, 1)]
    body = S.smooth_union([body] + blocks, k=0.012)
    # eye sockets (carved) + nostrils
    for s in (-1, 1):
        sock = S.sphere(W((s * 0.060, 0.062, 0.004)), 0.027)
        body = S.subtract(body, sock, 0.008)
        for nf in (0.003,):
            body = S.subtract(body, E((s * 0.012, 0.268, -0.030), (0.0075, 0.012, 0.0075)), 0.004)
    # the neck stub (collar) so the head seats on the neck; joined last, wide and soft
    nx, nf, nz = (0.085 - ORIGIN[0]) / SCALE, -(-0.085 - ORIGIN[1]) / SCALE, (1.872 - ORIGIN[2]) / SCALE
    stub = S.smooth_union([S.capsule(W((0, 0.0, -0.045)), W((nx, nf, nz + 0.02)), 0.055, 0.05),
                           E((nx, nf, nz + 0.005), (0.078 / SCALE, 0.060 / SCALE, 0.03))], k=0.02)
    body = S.smooth_union([body, stub], k=0.03)
    return body


def jaw_field():
    parts = []
    for s in (-1, 1):
        parts.append(cap((s * 0.050, -0.030, -0.048), (s * 0.034, 0.090, -0.058), 0.016, 0.015))
        parts.append(cap((s * 0.034, 0.090, -0.058), (s * 0.014, 0.235, -0.060), 0.015, 0.014))
    parts.append(E((0, 0.238, -0.060), (0.018, 0.020, 0.015)))                        # chin
    parts.append(cap((0, 0.246, -0.062), (0, 0.268, -0.120), 0.014, 0.005))             # chin hook
    parts.append(E((0, 0.040, -0.058), (0.040, 0.075, 0.015)))                          # throat/jaw base
    body = S.smooth_union(parts, k=0.012)
    # flat top (tongue bed / lip line) slightly below the palate so the closed mouth leaves a thin dark seam
    n = np.array([0.0, 0.06, -1.0]); n /= np.linalg.norm(n)
    body = S.intersect(body, S.halfspace(-n, W((0, 0.0, -0.0355))), 0.0)
    return body


def mesh(f, lo, hi, step=0.0022):
    V, F = S.mesh(f, np.array(lo), np.array(hi), step)
    return V, F


def cone_mesh(base, tip, r, sides=5):
    base = np.asarray(base, float); tip = np.asarray(tip, float)
    ax = tip - base; l = np.linalg.norm(ax); ax /= l
    a = np.cross(ax, [0, 0, 1.0]); a = a / np.linalg.norm(a) if np.linalg.norm(a) > 1e-3 else np.array([1, 0, 0.0]); b = np.cross(ax, a)
    V = []; F = []
    for j in range(sides):
        t = 2 * np.pi * j / sides
        V.append(base + r * (np.cos(t) * a + np.sin(t) * b))
    V.append(tip); V.append(base)
    for j in range(sides):
        F.append((j, (j + 1) % sides, sides)); F.append((j, sides + 1, (j + 1) % sides))
    return np.array(V), np.array(F)


def zp(f):
    return -0.034 - 0.06 * f


def teeth():
    up = []; lo = []
    def add(lst, base, tip, r):
        lst.append(cone_mesh(W(base), W(tip), r))
    for s in (-1, 1):
        # upper: big fang at the mouth corner + small row along the lip
        f = 0.125; add(up, (s * 0.036, f, zp(f) + 0.004), (s * 0.038, f + 0.004, zp(f) - 0.040), 0.0095)
        for f in (0.04, 0.08, 0.17, 0.21):
            x = 0.048 - 0.014 * (f > 0.12)
            add(up, (s * x, f, zp(f) + 0.003), (s * x, f + 0.002, zp(f) - 0.015), 0.0055)
        f = 0.180; add(lo, (s * 0.027, f, zp(f) - 0.0015), (s * 0.028, f + 0.002, zp(f) + 0.034), 0.0070)
        for f in (0.04, 0.08, 0.12, 0.15):
            x = 0.038 - 0.010 * (f > 0.1)
            add(lo, (s * x, f, zp(f) - 0.0015), (s * x, f, zp(f) + 0.016), 0.0052)
    return up, lo


def merge(pieces):
    V = []; F = []; off = 0
    for v, f in pieces:
        V.append(v); F.append(f + off); off += len(v)
    return np.vstack(V), np.vstack(F)


def main():
    out = {}
    sk = skull_field()
    Vs, Fs = mesh(sk, (-0.13, -0.32, -0.25), (0.13, 0.12, 0.14))   # world-space bounds of skull (head-local f -> -y)
    print("skull raw", len(Fs))
    jw = jaw_field()
    Vj, Fj = mesh(jw, (-0.09, -0.30, -0.16), (0.09, 0.08, -0.02))
    print("jaw raw", len(Fj))
    up, lo = teeth()
    Vu, Fu = merge(up); Vl, Fl = merge(lo)
    # eyes
    eyes = []
    for s in (-1, 1):
        c = W((s * 0.058, 0.064, 0.005))
        ey = S.mesh(S.ellipsoid(c, (0.016, 0.024, 0.020), S.euler(0.0, 0.0, s * 0.5)), c - 0.03, c + 0.03, 0.0015)
        eyes.append(ey)
    Ve, Fe = merge(eyes)
    tg = S.mesh(S.ellipsoid(W((0, 0.11, zp(0.11) - 0.008)), (0.018, 0.085, 0.008)), W((0, 0.11, zp(0.11))) - [0.05, 0.1, 0.04], W((0, 0.11, zp(0.11))) + [0.05, 0.1, 0.04], 0.002)
    Vt, Ft = tg
    # world: add origin and scale about the origin; keep rotation none
    def place(V):
        loc = V.copy().astype(np.float64)
        # input coords are already 'world-oriented' relative to head-local origin (x, -f, z): place and scale
        return (loc * SCALE + ORIGIN * np.array([1, 1, 1]) * 1.0).astype(np.float32)
    np.savez(os.path.join(WORK, "head_raw.npz"),
             Vs=place(Vs), Fs=Fs, Vj=place(Vj), Fj=Fj, Vu=place(Vu), Fu=Fu, Vl=place(Vl), Fl=Fl, Ve=place(Ve), Fe=Fe, Vt=place(Vt), Ft=Ft,
             origin=ORIGIN, scale=SCALE)


if __name__ == "__main__":
    main()
