"""Aruun v3 head paint (object-space). Called by paint3.py with the Bake and the arrays; head-local coordinates from head_raw.npz."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common.texbake import smooth, mix, hash1, vnoise

DARK = np.array([36, 27, 38.]); PLUM = np.array([62, 48, 70.]); RED = np.array([156, 50, 40.]); REDHI = np.array([206, 82, 46.])
REDDK = np.array([104, 30, 30.]); CREAM = np.array([216, 194, 152.]); TAN = np.array([178, 140, 104.]); BONE = np.array([232, 218, 182.])
PALATE = np.array([172, 62, 72.]); OLIVE = np.array([118, 104, 60.]); NAVY = np.array([40, 38, 56.]); NECK = np.array([196, 88, 50.])
EYE_Y = np.array([240, 214, 62.])


def zp(f):
    return -0.034 - 0.06 * f


def seg_d(P, a, b):
    a = np.asarray(a); b = np.asarray(b); ab = b - a
    t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def line(d, w, soft=0.0007):
    """1 on a line of half-width w around d==0"""
    return 1 - smooth(w - soft, w + soft, np.abs(d))


def local(P, O, sc):
    q = (P - O) / sc
    return np.stack([q[:, 0], -q[:, 1], q[:, 2]], 1)


def paint_skull(P, Nr, O, sc, out):
    """returns dict of arrays: col, emis, rough, metal, height"""
    L = local(P, O, sc); nl = np.stack([Nr[:, 0], -Nr[:, 1], Nr[:, 2]], 1)
    lx, lf, lz = L[:, 0], L[:, 1], L[:, 2]; ax = np.abs(lx); s = np.where(lx >= 0, 1.0, -1.0)
    n = len(P); col = np.tile(DARK, (n, 1)); hgt = np.zeros(n); rough = np.full(n, 0.55); emis = np.zeros((n, 3))
    # base chitin: plum rim toward the top/back with soft gradient
    col = mix(col, PLUM, smooth(-0.02, 0.07, lz) * 0.6 + 0.15 * vnoise(P, 40, 1))
    lip = lz - zp(lf)            # >0 above the mouth line
    # --- snout cream plate (above lip line, in front of a diagonal border)
    g_front = 0.060 + (lz + 0.040) * 0.55 - lf          # <0 in the plate
    plate = smooth(0.0007, -0.0007, g_front) * smooth(0.004, 0.012, lip) * smooth(0.005, -0.004, lf - 0.262)
    plate_rim = line(g_front, 0.0022) * smooth(0.004, 0.010, lip) * (lf < 0.265)
    cream = mix(CREAM, TAN, smooth(0.10, 0.27, lf) * 0.55 + 0.12 * vnoise(P, 60, 2))
    cream = mix(cream, TAN, smooth(0.012, -0.03, lz) * 0.45)          # shaded lower snout sides
    col = mix(col, cream, plate)
    col = mix(col, DARK * 0.7, plate_rim)
    hgt += 0.8 * plate
    # scale lines across the upper lip plates
    for k, f0 in enumerate((0.09, 0.13, 0.175, 0.22)):
        ln = line(lf - f0 - 0.012 * (lz < -0.01), 0.0016) * smooth(0.004, 0.010, lip) * smooth(0.032, 0.020, lip) * plate
        col = mix(col, TAN * 0.55, ln * 0.9); hgt -= 0.5 * ln
    # nose bridge ridge: bone strip
    ridge = (1 - smooth(0.007, 0.011, ax)) * smooth(0.075, 0.095, lf) * smooth(0.268, 0.25, lf) * smooth(-0.005, 0.01, lz)
    col = mix(col, mix(CREAM, BONE, 0.4), ridge * 0.6); hgt += 0.5 * ridge
    # --- crown: red plates over the brow/skull, segmented by cream-edged arcs
    top = smooth(0.022, 0.034, lz + 0.0 * lf) * smooth(0.11, 0.085, lf) * smooth(-0.075, -0.045, lf)
    col = mix(col, RED, top * 0.96)
    seg = np.zeros(n)
    for f0 in (0.06, 0.012, -0.03):
        d = lf - f0 - 0.25 * (ax - 0.03) ** 2 * 6
        seg = np.maximum(seg, line(d, 0.0018))
    col = mix(col, CREAM, seg * top * 0.85); hgt -= 0.5 * seg * top
    col = mix(col, REDHI, top * smooth(0.032, 0.0, ax) * smooth(0.02, 0.05, lf) * smooth(0.10, 0.07, lf) * 0.9)   # orange brow patch
    col = mix(col, REDDK, top * smooth(0.10, 0.03, lz) * 0.0 + top * (1 - smooth(0.02, 0.065, lz)) * 0.35)
    # horn cups: red with cream rings
    cup = smooth(0.050, 0.068, lz) * smooth(0.075, 0.04, np.hypot(ax - 0.048, lf + 0.025))
    col = mix(col, RED, cup)
    for z0 in (0.078, 0.098, 0.116):
        col = mix(col, CREAM, line(lz - z0, 0.0035) * cup * 0.9)
    # sagittal crest spikes (red, cream tips)
    crest = smooth(0.013, 0.007, ax) * smooth(0.04, 0.062, lz) * smooth(0.04, 0.0, lf + 0.065)
    col = mix(col, REDHI, crest * 0.9); col = mix(col, CREAM, crest * smooth(0.085, 0.098, lz))
    # --- brow ridge (bone) over the eye
    for sg in (-1, 1):
        sm = s == sg
        a = np.array([sg * 0.030, 0.100, 0.034]); b = np.array([sg * 0.072, 0.040, 0.044]); c = np.array([sg * 0.074, -0.020, 0.030])
        d = np.minimum(seg_d(L, a, b), seg_d(L, b, c))
        br = smooth(0.0195, 0.0160, d) * sm * smooth(0.0, 0.012, lz - 0.02)
        col = mix(col, mix(CREAM, TAN, 0.35), br * 0.95)
        ed = line(d - 0.0172, 0.0016) * sm * smooth(0.0, 0.01, lz - 0.015)
        col = mix(col, DARK, ed * 0.9); hgt += 0.6 * br
        # eye socket liner: big dark almond + red sclera glow ring
        ce = np.array([sg * 0.060, 0.062, 0.004])
        de = np.linalg.norm((L - ce) * np.array([1.0, 0.8, 1.15]), axis=1)
        sock = smooth(0.046, 0.030, de) * sm
        col = mix(col, DARK * 0.55, sock)
        col = mix(col, REDDK, line(de - 0.049, 0.0024) * sm * 0.8)
        # eye-streak: dark tear line running down the snout from the eye (sheet detail)
        tear = line(seg_d(L, ce + np.array([0, 0.02, -0.02]), ce + np.array([sg * 0.0, 0.07, -0.040])) - 0.0, 0.0028) * sm
        col = mix(col, DARK * 0.6, tear * 0.85)
        # cheek plate: tan with red spot and dark outline
        cc = np.array([sg * 0.062, 0.022, -0.030])
        dc = np.linalg.norm((L - cc) / np.array([0.030, 0.050, 0.034]), axis=1)
        chk = smooth(1.0, 0.92, dc) * sm
        col = mix(col, mix(TAN, CREAM, 0.3), chk * 0.95)
        col = mix(col, DARK * 0.8, line(dc - 1.0, 0.07) * sm)
        col = mix(col, RED, smooth(0.36, 0.28, dc) * sm * 0.95); col = mix(col, CREAM, smooth(0.14, 0.08, dc) * sm)
        hgt += 0.5 * chk
        # temple knob (bone tine root)
        tk = np.linalg.norm((L - np.array([sg * 0.076, -0.030, 0.005])) / 0.016, axis=1)
        col = mix(col, BONE, smooth(1.2, 0.9, tk) * sm)
    # --- nostrils + mouth line + palate
    for sg in (-1, 1):
        nd = np.linalg.norm((L - np.array([sg * 0.012, 0.268, -0.030])) / np.array([0.011, 0.015, 0.011]), axis=1)
        col = mix(col, DARK * 0.25, smooth(1.15, 0.85, nd)); hgt -= 0.8 * smooth(1.2, 0.8, nd)
    mouth = line(lip, 0.0032) * smooth(-0.02, 0.03, lf)
    col = mix(col, DARK * 0.45, mouth * 0.95); hgt -= 0.8 * mouth
    pal = smooth(-0.8, -0.95, nl[:, 2]) * (1 - smooth(0.0, 0.006, lip)) * smooth(-0.002, 0.003, lip + 0.003)
    palcol = mix(PALATE, DARK, smooth(0.0, 0.06, -lf + 0.0) * 0.7 + 0.15 * smooth(0.02, 0.0, ax) * 0)
    palcol = mix(palcol, PALATE * 1.25, line(ax, 0.003) * 0.7)
    col = mix(col, palcol, np.clip(pal * 1.5, 0, 1))
    # --- nape: dark cap fading into olive fringe line, neck stub fades to the neck's orange-red
    nape = smooth(-0.02, -0.06, lf) * smooth(0.06, 0.02, lz)
    col = mix(col, mix(NAVY, PLUM, 0.3), nape * 0.8)
    col = mix(col, OLIVE, line(lz - 0.033 + 0.15 * (lf + 0.07), 0.004) * smooth(-0.01, -0.05, lf) * 0.8)
    col = mix(col, DARK * 0.9, smooth(-0.045, -0.085, lz) * smooth(-0.14, -0.06, lz) * 0.0)
    neck = smooth(-0.095, -0.150, lz)
    neck_c = mix(NECK, REDDK, smooth(0.0, -0.06, lf) * 0.85)
    col = mix(col, neck_c, neck)
    col = mix(col, DARK * 0.7, line(lz + 0.095, 0.0035) * 0.9)           # collar line
    # general edge darkening by curvature proxy: darker with downward normals
    col = col * (0.82 + 0.18 * smooth(-1, 0.6, nl[:, 2]))[:, None]
    # shadowed under-chin
    rough = np.where(plate > 0.5, 0.42, 0.6) - 0.1 * smooth(0.01, 0.05, lz)
    return col, emis, rough, hgt


def paint_jaw(P, Nr, O, sc):
    L = local(P, O, sc); nl = np.stack([Nr[:, 0], -Nr[:, 1], Nr[:, 2]], 1)
    lx, lf, lz = L[:, 0], L[:, 1], L[:, 2]; ax = np.abs(lx); n = len(P)
    col = np.tile(NAVY, (n, 1)); hgt = np.zeros(n)
    col = mix(col, PLUM, smooth(-0.1, -0.04, lz) * 0.5 + 0.12 * vnoise(P, 50, 3))
    # cream chin plate and hook (bone), segmented by lines
    chin = smooth(0.150, 0.185, lf)
    col = mix(col, mix(RED, REDDK, smooth(0.20, 0.27, lf)), chin * 0.95)
    for f0 in (0.19, 0.225):
        col = mix(col, CREAM, line(lf - f0, 0.0016) * chin * 0.8)
    col = mix(col, TAN, smooth(0.0, 0.5, ax * 40 - 0.0) * 0 + smooth(0.255, 0.275, lf) * 0.5 * chin)
    # lower lip plates: tan stripe along the top edge of the jaw outside
    lip = lz - (zp(lf) - 0.0015)
    col = mix(col, TAN * 0.9, smooth(-0.018, -0.008, lip) * smooth(0.004, -0.004, lip) * smooth(0.0, 0.05, lf) * (1 - chin))
    col = mix(col, DARK * 0.4, line(lip + 0.001, 0.0025) * smooth(0.0, 0.03, lf))
    # inside of the mouth: flat top face -> tongue bed (dark pink)
    top = smooth(0.5, 0.85, nl[:, 2])
    col = mix(col, mix(PALATE * 0.75, DARK, smooth(0.0, 0.07, -lf) * 0.8), top)
    # jaw hinge plate
    hinge = smooth(0.03, 0.01, np.hypot(lf + 0.025, lz + 0.05))
    col = mix(col, TAN, hinge * 0.7)
    col = col * (0.85 + 0.15 * smooth(-1, 0.6, nl[:, 2]))[:, None]
    return col, np.zeros((n, 3)), np.full(n, 0.55), hgt


def paint_tooth(P, up):
    n = len(P)
    col = np.tile(BONE, (n, 1)) * 0.97
    return col, np.zeros((n, 3)), np.full(n, 0.35), np.zeros(n)


def paint_tongue(P, Nr, O, sc):
    L = local(P, O, sc); n = len(P)
    col = np.tile(np.array([205, 92, 108.]), (n, 1)); col = mix(col, np.array([140, 52, 70.]), smooth(0.0, 0.12, -L[:, 1]) * 0.7)
    col = mix(col, np.array([236, 150, 150.]), line(np.abs(L[:, 0]), 0.0035) * 0.7)
    return col, np.zeros((n, 3)), np.full(n, 0.3), np.zeros(n)


def paint_eye(P, Nr, O, sc):
    L = local(P, O, sc); n = len(P)
    col = np.zeros((n, 3)); emis = np.zeros((n, 3)); rough = np.full(n, 0.06)
    for sg in (-1, 1):
        sel = np.sign(L[:, 0] + 1e-9) == sg
        ce = np.array([sg * 0.058, 0.064, 0.005]); v = L - ce; r = np.linalg.norm(v, axis=1, keepdims=True) + 1e-9; u = v / r
        gaze = np.array([sg * 0.62, 0.78, -0.08]); gaze /= np.linalg.norm(gaze)
        # tangent frame around gaze
        up = np.array([0, 0, 1.0]); tx = np.cross(gaze, up); tx /= np.linalg.norm(tx); ty = np.cross(tx, gaze)
        a = u @ gaze; ang = np.arccos(np.clip(a, -1, 1))
        px = (u @ tx); py = (u @ ty)
        # vertical slit pupil: ellipse in (px,py) with ang as radius scale
        er = np.sqrt((px / 0.55) ** 2 + (py / 1.0) ** 2) * ang
        c = np.tile(EYE_Y, (n, 1))
        c = mix(c, np.array([232, 150, 40.]), smooth(0.55, 1.0, ang / 1.0) * 0.5)          # warm limb
        c = mix(c, np.array([150, 90, 20.]), smooth(0.50, 0.40, er) * 0.8)
        c = mix(c, np.array([8, 4, 8.]), smooth(0.34, 0.27, er))                          # pupil
        c = mix(c, np.array([30, 20, 20.]), line(ang - 1.12, 0.07) * 0.8)                  # rim
        gl = np.exp(-(((px + 0.42) / 0.12) ** 2 + ((py - 0.42) / 0.12) ** 2)) * smooth(0.0, 0.4, a)
        c = mix(c, np.array([255, 255, 240.]), np.clip(gl * 2.0, 0, 1))
        e = np.where((er < 0.30)[:, None], 0, c * 0.8)
        col[sel] = c[sel]; emis[sel] = e[sel]
    return col, emis, rough, np.zeros(n)


def paint_fringe(sp):
    n = len(sp); k = np.floor(sp / 2.0 + 1e-4).astype(int) % 3; t = sp - 2.0 * np.floor(sp / 2.0 + 1e-4)
    cols = np.array([[228, 200, 112.], [216, 198, 156.], [120, 106, 62.]])
    c = cols[k]; c = c * (0.62 + 0.55 * smooth(0.0, 0.8, t))[:, None]
    return c, np.zeros((n, 3)), np.full(n, 0.7), np.zeros(n)


def paint_tine(P):
    n = len(P); return np.tile(BONE * 0.95, (n, 1)), np.zeros((n, 3)), np.full(n, 0.5), np.zeros(n)
