"""Cigarra v2 painting (object space): face (hand-painted look: liner, third eye, markings), body regions, hair, crown, charms, wings."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common.texbake import smooth, mix, hash1, vnoise, worley

SKIN = np.array([208, 154, 114.]); SKIN_D = np.array([168, 112, 80.]); SKIN_L = np.array([232, 182, 138.]); LIP = np.array([188, 102, 98.])
INK = np.array([22, 16, 26.]); VIOLET = np.array([70, 54, 98.]); VIOLET_D = np.array([46, 36, 68.]); MOSS = np.array([160, 172, 48.]); OLIVE = np.array([112, 120, 52.])
CREAM = np.array([230, 218, 172.]); HAIR = np.array([236, 230, 206.]); LEATHER = np.array([136, 84, 48.]); BOOT = np.array([76, 56, 46.])
GOLD = np.array([240, 188, 58.]); ORANGE = np.array([236, 112, 42.]); LIME = np.array([184, 214, 62.]); EYE_Y = np.array([246, 204, 52.])


def line(d, w, soft=0.0007):
    return 1 - smooth(w - soft, w + soft, np.abs(d))


def seg_d2(x, z, a, b):
    ab = np.array(b) - np.array(a); t = np.clip(((x - a[0]) * ab[0] + (z - a[1]) * ab[1]) / (ab @ ab), 0, 1)
    return np.hypot(x - (a[0] + t * ab[0]), z - (a[1] + t * ab[1]))


def local(P, O, sc):
    return (P - O) / sc


def paint_skull(P, N, O, sc):
    L = local(P, O, sc); lx, ly, lz = L[:, 0], L[:, 1], L[:, 2]; s = np.where(lx >= 0, 1.0, -1.0); ax = np.abs(lx)
    n = len(P); col = np.tile(SKIN, (n, 1)); hgt = np.zeros(n); rough = np.full(n, 0.55); emis = np.zeros((n, 3))
    front = smooth(0.05, -0.35, N[:, 1])              # facing forward (-y)
    # soft skin modelling: warmer cheeks/nose, cooler under chin & neck, ears pinker
    col = mix(col, SKIN_L, smooth(0.02, -0.06, ly) * smooth(-0.03, 0.03, lz) * 0.25)
    col = mix(col, SKIN_D, smooth(-0.07, -0.13, lz) * 0.5)
    col = mix(col, np.array([226, 120, 104.]), smooth(0.03, 0.0, np.hypot(ax - 0.044, lz + 0.032)) * front * 0.25)      # cheek blush
    col = mix(col, np.array([226, 120, 104.]), smooth(0.016, 0.006, np.hypot(lx, (lz + 0.018) * 0.9)) * smooth(-0.07, -0.095, ly) * 0.22)   # nose tip
    # scalp / hair-cap colour behind the hairline (never bald under the clumps)
    scalp = np.clip(smooth(0.040, 0.050, lz) + smooth(0.005, 0.03, ly) * smooth(-0.07, -0.02, lz) * (1 - smooth(0.055, 0.075, ax) * smooth(-0.04, -0.01, lz) * 0.0), 0, 1)
    scalp = scalp * (1 - front * smooth(0.040, 0.030, lz) * 0)
    streak = np.sin(np.arctan2(lx, ly + 0.02) * 26.0 + lz * 20) * 0.5 + 0.5
    hc = HAIR * (0.80 + 0.17 * streak + 0.06 * vnoise(P, 40, 4))[:, None]
    hc = mix(hc, HAIR * 0.62, smooth(0.075, 0.042, lz) * 0.5)
    col = mix(col, hc, scalp)
    # eyes: liner (thick, upper heavier, wing flick), lids, brows
    for sg in (-1, 1):
        m = (s == sg)
        cx, cz = 0.036 * sg, 0.008
        dx = (lx - cx) * sg; dz = lz - cz        # dx>0 toward the outer corner
        # almond: slanted ellipse (outer corner up)
        ca, sa = np.cos(0.24), np.sin(0.24)
        u = dx * ca + dz * sa; v = -dx * sa + dz * ca
        e = (u / 0.0235) ** 2 + (v / 0.0125) ** 2
        up = smooth(-0.002, 0.006, v)
        ring = smooth(1.75 + 0.9 * up, 1.1, e) * front * m                  # liner band, thicker on the top lid
        col = mix(col, INK, ring * (1 - smooth(1.0, 0.92, e)) * 0.95)
        col = mix(col, INK, line(e - 1.0, 0.12) * front * m)
        # wing flick at the outer corner and lower lash line
        d1 = seg_d2(dx, dz, (0.020, 0.012), (0.046, 0.026)); col = mix(col, INK, line(d1 - 0.0014, 0.0022) * front * m * smooth(-0.03, 0.01, ly * -1 - 0.0 + 0.0))
        d2 = seg_d2(dx, dz, (-0.018, -0.005), (-0.030, -0.014)); col = mix(col, INK, line(d2 - 0.0008, 0.0012) * front * m)
        # upper lid crease + brow
        crease = np.abs(v - 0.0185 * (1 - 0.0 * u)) - 0.0
        col = mix(col, SKIN_D * 0.8, line(v - 0.021 + 0.03 * (u / 0.0235) ** 2 * 0.0, 0.0012) * smooth(1.8, 1.0, (u / 0.032) ** 2) * front * m * 0.6)
        brow = seg_d2(dx, dz, (-0.012, 0.024), (0.044, 0.036))
        col = mix(col, INK * 1.6, smooth(0.0042, 0.0020, brow) * front * m * 0.9)
        # cheek smears (the sheet's dark brown face marks): three slashes and dots under the eye
        for (a0, a1) in (((-0.004, -0.018), (-0.012, -0.040)), ((0.008, -0.020), (0.004, -0.045)), ((0.022, -0.012), (0.034, -0.028))):
            dd = seg_d2(dx, dz, a0, a1); col = mix(col, np.array([90, 56, 44.]), smooth(0.0030, 0.0012, dd) * front * m * 0.9)
    # third eye: black disc on the forehead with tiny highlight
    d3 = np.hypot(lx, (lz - 0.052) * 1.0)
    col = mix(col, INK, smooth(0.0135, 0.0105, d3) * front)
    col = mix(col, np.array([90, 80, 120.]), smooth(0.0035, 0.0015, np.hypot(lx + 0.004, lz - 0.0575)) * front * 0.9)
    hgt += 0.7 * smooth(0.0135, 0.0105, d3) * front
    # forehead pale scar line (sheet) + nose bridge shadow
    col = mix(col, SKIN_L, line(seg_d2(lx, lz, (-0.03, 0.036), (-0.012, 0.062)) - 0.0, 0.0016) * front * 0.6)
    # nose: nostril dark, tip highlight
    for sg in (-1, 1):
        dn = np.hypot((lx - sg * 0.0075) / 0.0042, (lz + 0.040) / 0.0032)
        col = mix(col, INK * 1.4, smooth(1.2, 0.8, dn) * front)
    col = mix(col, SKIN_L, smooth(0.008, 0.002, np.hypot(lx, lz + 0.034)) * front * 0.35)
    # lips: pink upper/lower, dark mouth line, tiny gloss; chin line (black)
    lipz = (lz + 0.067) / 0.0095; lipx = lx / 0.021
    lipm = smooth(1.0, 0.8, np.hypot(lipx, lipz * 1.0)) * front
    col = mix(col, LIP, lipm); col = mix(col, LIP * 1.15, smooth(0.5, 0.2, np.hypot(lipx, (lz + 0.0765) / 0.004)) * front * 0.5)
    col = mix(col, INK * 1.5, line(lz + 0.0705 + 0.003 * (lx / 0.02) ** 2 * 0 - 0.0012 * (lx / 0.02) ** 2, 0.0011) * smooth(0.024, 0.018, ax) * front * 0.95)
    col = mix(col, INK, line(lx, 0.0015) * smooth(-0.082, -0.092, lz) * smooth(-0.118, -0.100, lz) * front * 0.9)      # black chin line
    # ears: inner pink
    ear = smooth(0.045, 0.03, np.hypot(ax - 0.092, lz - 0.01)) * smooth(0.05, 0.075, ax)
    col = mix(col, np.array([226, 140, 118.]), ear * 0.5)
    # neck: darker skin with collar shadow near the bottom
    col = mix(col, SKIN_D * 0.9, smooth(-0.115, -0.17, lz) * 0.6)
    col = col * (0.88 + 0.12 * smooth(-1, 0.6, N[:, 2]))[:, None]
    rough = np.full(n, 0.5)
    return col, emis, rough, hgt


def paint_eye(P, N, O, sc):
    L = local(P, O, sc); n = len(P)
    col = np.zeros((n, 3)); emis = np.zeros((n, 3))
    for sg in (-1, 1):
        sel = np.sign(L[:, 0] + 1e-9) == sg
        ce = np.array([sg * 0.036, -0.062, 0.008]); v = L - ce; r = np.linalg.norm(v, axis=1, keepdims=True) + 1e-9; u = v / r
        gaze = np.array([sg * 0.12, -1.0, 0.0]); gaze /= np.linalg.norm(gaze)
        tx = np.cross(gaze, [0, 0, 1.0]); tx /= np.linalg.norm(tx); ty = np.cross(tx, gaze)
        a = u @ gaze; ang = np.arccos(np.clip(a, -1, 1)); px = u @ tx; py = u @ ty
        rr = ang / 1.15
        c = np.tile(EYE_Y, (n, 1))
        c = mix(c, np.array([252, 232, 120.]), smooth(0.55, 0.0, rr) * 0.4)
        c = mix(c, np.array([214, 128, 28.]), smooth(0.42, 0.62, rr) * 0.8)                # amber limbal ring
        c = mix(c, INK, smooth(0.20, 0.17, rr))                                                # round pupil
        c = mix(c, np.array([60, 30, 10.]), smooth(0.82, 0.95, rr) * 0.8)
        gl = np.exp(-(((px + 0.30) / 0.13) ** 2 + ((py - 0.30) / 0.13) ** 2)) * smooth(0.0, 0.3, a)
        c = mix(c, np.array([255, 255, 245.]), np.clip(gl * 2.2, 0, 1))
        e = np.where((rr < 0.18)[:, None], 0.0, c * 0.55)
        col[sel] = c[sel]; emis[sel] = e[sel]
    return col, emis, np.full(n, 0.08), np.zeros(n)


def paint_body(P, N, kind, seed=0):
    """body shell + hands: skin (midriff, hands), crop top, violet jacket sleeves, baggy violet trousers with leather knee patches,
    bandaged wrists / shins, leaf-trimmed boots, belt line."""
    n = len(P); x, y, z = P[:, 0], P[:, 1], P[:, 2]; ax = np.abs(x); nx, ny, nz = N[:, 0], N[:, 1], N[:, 2]
    front = smooth(0.0, -0.4, ny)
    col = np.tile(SKIN, (n, 1)); rough = np.full(n, 0.55); hgt = np.zeros(n)
    fab = vnoise(P, 18, seed + 3)
    if kind == "hand":
        col = mix(SKIN, SKIN_D, smooth(0.35, 0.8, vnoise(P, 40, 5)) * 0.35)
        col = mix(col, SKIN_D * 0.85, line(((z * 90) % 1.0) - 0.5, 0.04) * 0.2)
        # bandage cuff at the wrist
        bnd = smooth(0.86, 0.845, z)
        col = mix(col, CREAM, bnd * 0.0)
        return col, np.full(n, 0.55), hgt
    # ---- trousers (z < 1.0): violet, folds, moss hem, knee patches, pocket
    pants = smooth(1.012, 0.995, z) * smooth(0.215, 0.20, z + 0.0 * ax) * 0 + smooth(1.012, 0.995, z)
    fold = np.sin((np.arctan2(y - 0.0, x) * 9.0) + z * 14.0) * 0.5 + 0.5
    pc = mix(VIOLET, VIOLET_D, 0.35 + 0.35 * fold) * (0.9 + 0.2 * fab)[:, None]
    # side/inner shade
    pc = pc * (0.82 + 0.18 * smooth(-1, 0.7, nz))[:, None]
    # moss patches near the hem and thigh sides (sheet olive moss)
    mossm = smooth(0.62, 0.78, vnoise(P, 11, seed + 7)) * smooth(0.52, 0.30, z) + smooth(0.74, 0.86, vnoise(P, 9, seed + 8)) * 0.4 * smooth(0.95, 0.7, z)
    pc = mix(pc, OLIVE, np.clip(mossm, 0, 1) * 0.65)
    # knee patches: brown leather rectangles with stitches, front of both knees
    for sg in (-1, 1):
        cx = sg * 0.097
        sd = np.maximum(np.abs(x - cx) - 0.052, np.abs(z - 0.47) - 0.05)
        pm = smooth(0.0008, -0.0008, sd) * front
        pc = mix(pc, LEATHER * (0.9 + 0.2 * vnoise(P, 60, seed + 11))[:, None], pm)
        pc = mix(pc, INK, line(sd + 0.004, 0.0009) * front * 0.7)      # stitch row
        pc = mix(pc, INK, line(sd, 0.0018) * front * 0.8)
        hgt += 0.7 * pm
    # brown hip pocket (left thigh side) and torn patch
    sd = np.maximum(np.abs(y + 0.0) - 0.06, np.maximum(np.abs(z - 0.72) - 0.07, np.abs(x - 0.215) - 0.05))
    pm = smooth(0.0008, -0.0008, sd) * smooth(0.3, 0.8, nx) * 0
    # cuff band + moss trim at z ~0.30-0.33
    cuff = smooth(0.285, 0.30, z) * smooth(0.345, 0.33, z)
    pc = mix(pc, VIOLET_D * 0.8, cuff); pc = mix(pc, MOSS * 0.9, line(z - 0.335, 0.003) * 0.9)
    col = mix(col, pc, pants)
    # ---- shin bandages (z 0.14..0.30): cream spiral wrap with olive diamonds
    shin = smooth(0.285, 0.272, z) * smooth(0.13, 0.145, z)
    ang = np.arctan2(y - 0.02, x - np.sign(x) * 0.10)
    spiral = np.sin(ang * 3.0 + z * 38.0) * 0.5 + 0.5
    bc = mix(CREAM * 0.97, OLIVE * 1.15, smooth(0.62, 0.72, spiral) * 0.8)
    bc = mix(bc, INK, line(((z * 38.0 + ang * 3.0) / (2 * np.pi)) % 1.0 - 0.5, 0.03) * 0.5)
    col = mix(col, bc, shin); rough = np.where(shin > 0.5, 0.75, rough)
    # ---- boots (z < 0.14): dark brown leather, olive/lime leaf trim along the top, gold eyelets, toe cap + sole
    boot = smooth(0.145, 0.13, z)
    bcol = mix(BOOT, BOOT * 1.45, smooth(0.25, 0.7, vnoise(P, 30, seed + 13)) * 0.5)
    bcol = mix(bcol, np.array([40, 30, 28.]), smooth(0.03, 0.012, z))                            # sole
    bcol = mix(bcol, MOSS, line(z - 0.136, 0.004) * 0.9)
    bcol = mix(bcol, np.array([112, 86, 66.]), smooth(0.040, 0.075, z) * smooth(-0.07, -0.12, y) * 0.55)          # toe cap
    for k in range(3):
        d = np.hypot(z - (0.1 - 0.0 * k), np.where(front > 0.2, (np.mod(y * 100 + 3 * k, 5.0) - 2.5) * 0.002, 1.0))
    col = mix(col, bcol, boot); rough = np.where(boot > 0.5, 0.5, rough)
    # ---- torso zones
    torso_top = 1.33
    # waistband / belt line z 0.99..1.03 handled by belt geometry; pants top edge dark band
    col = mix(col, VIOLET_D * 0.7, line(z - 1.0, 0.012) * (z > 0.95) * (1 - boot) * 0.0)
    skin_mid = smooth(1.005, 1.02, z) * smooth(1.2, 1.185, z)
    sm = mix(SKIN, SKIN_L, smooth(0.0, 1.0, front) * 0.2) * (0.92 + 0.12 * smooth(-1, 0.5, nz))[:, None]
    sm = mix(sm, SKIN_D, smooth(0.0, 0.4, ny) * 0.5)
    col = mix(col, sm, skin_mid)
    # navel
    col = mix(col, SKIN_D * 0.55, smooth(0.0075, 0.004, np.hypot(x, (z - 1.095) * 1.0)) * front)
    # crop top: cream with olive/dark blotches, black hem band, v-neckline
    crop = smooth(1.185, 1.2, z) * smooth(1.345, 1.33, z) * (smooth(0.145, 0.12, ax) + (1 - front) * 0 + 0.0)
    cc = mix(CREAM, OLIVE * 1.2, smooth(0.62, 0.8, vnoise(P, 26, seed + 17)) * 0.8)
    cc = mix(cc, VIOLET_D, smooth(0.8, 0.9, vnoise(P, 33, seed + 18)) * 0.8)
    cc = mix(cc, INK * 1.3, smooth(1.215, 1.19, z))                                          # black hem band
    cc = mix(cc, INK * 1.3, line(z - 1.2, 0.0) * 0)
    col = mix(col, cc, crop * (1 - (1 - front) * 0.0))
    # ---- sleeves: upper arm violet jacket with moss edge at the shoulder; puffy forearm; bandaged wrist; skin hand beyond
    arm = smooth(0.19, 0.205, ax) * smooth(1.40, 1.37, z) * 0 + smooth(0.158, 0.17, ax) * smooth(1.40, 1.38, z)
    arm_sleeve = arm * smooth(0.835, 0.865, z)
    jac = mix(VIOLET, VIOLET_D, 0.3 + 0.4 * (np.sin(z * 30 + ax * 8) * 0.5 + 0.5)) * (0.9 + 0.2 * fab)[:, None]
    jac = mix(jac, MOSS, line(z - 1.30, 0.012) * 0.5 * smooth(0.3, 0.8, vnoise(P, 40, seed + 19)))
    jac = mix(jac, VIOLET_D * 0.6, smooth(0.9, 0.84, z) * smooth(0.0, 0.00001, z - 0.8))
    col = mix(col, jac, arm_sleeve)
    # cuff + wrist bandage between z 0.76..0.865
    wr = smooth(0.87, 0.855, z) * smooth(0.74, 0.76, z) * arm
    ang2 = np.arctan2(y, x - np.sign(x) * 0.28)
    bc2 = mix(CREAM, OLIVE * 1.1, smooth(0.6, 0.75, np.sin(ang2 * 2.0 + z * 60.0) * 0.5 + 0.5) * 0.7)
    col = mix(col, bc2, wr)
    col = mix(col, VIOLET_D * 0.6, line(z - 0.872, 0.004) * arm * 0.9)
    # shoulders / back: violet jacket yoke over the top + back panel (under the cape)
    yoke = smooth(1.28, 1.30, z) * smooth(0.19, 0.17, ax) * 0 + smooth(1.285, 1.3, z) * smooth(1.40, 1.385, z) * smooth(0.20, 0.16, ax)
    col = mix(col, VIOLET * 0.9, yoke * smooth(-0.1, 0.35, ny))
    col = mix(col, VIOLET, smooth(0.15, 0.55, ny) * smooth(1.34, 1.2, z) * smooth(1.0, 1.1, z) * 0.9)       # jacket back
    # seams: dark thin lines at joint regions
    hgt += 0.3 * fab
    # neck base skin
    col = mix(col, SKIN_D, smooth(1.33, 1.37, z) * smooth(0.06, 0.04, ax))
    rough = np.where(pants > 0.5, 0.78, rough)
    return col * (0.9 + 0.1 * smooth(-1, 0.6, nz))[:, None], rough, hgt


def paint_hair(sp, P):
    n = len(P); var = np.floor(sp / 2.0 + 1e-4); t = sp - 2.0 * var
    base = np.tile(HAIR, (n, 1)); base = np.where((var == 1)[:, None], np.array([230, 214, 168.]), base)
    base = np.where((var == 2)[:, None], mix(HAIR, LIME, smooth(0.2, 0.8, t)), base)
    base = base * (0.62 + 0.45 * smooth(0.0, 0.5, t))[:, None]
    base = mix(base, np.array([250, 244, 224.]), smooth(0.7, 1.0, t) * 0.5 * (var != 2))
    return base, np.full(n, 0.6)


def paint_crown(name, P, N):
    n = len(P)
    if name.startswith("crowns_"):
        c = P.mean(0); r = np.linalg.norm(P - c, axis=1).max(); d = (P - c) / np.maximum(np.linalg.norm(P - c, axis=1, keepdims=True), 1e-9)
        col = np.tile(np.array([26, 20, 34.]), (n, 1))
        # glossy highlights: warm yellow crescent on the upper-left, pale glint
        h = np.array([-0.55, -0.45, 0.70]); h /= np.linalg.norm(h)
        dh = d @ h
        cres = smooth(0.62, 0.70, dh) * smooth(0.97, 0.90, dh)
        col = mix(col, np.array([226, 196, 70.]), cres)
        col = mix(col, np.array([255, 250, 220.]), smooth(0.93, 0.97, dh))
        col = mix(col, np.array([58, 40, 84.]), smooth(0.0, -0.8, d @ np.array([0.4, 0.5, -0.7])) * 0.0 + smooth(0.55, 0.95, -(d @ h)) * 0.35)   # violet rim light opposite the glint
        emis = np.tile(np.array([34., 12, 54]), (n, 1)) * smooth(0.0, 0.8, -(d @ h))[:, None] + np.tile(np.array([90., 70, 12]), (n, 1)) * cres[:, None]
        return col, np.full(n, 0.12), emis
    col = np.tile(np.array([52, 40, 46.]), (n, 1)); col = mix(col, np.array([96, 80, 70.]), smooth(0.4, 0.8, vnoise(P, 50, 3)) * 0.4)
    # olive/yellow patches on the branches (sheet crown_x4)
    patch = smooth(0.55, 0.7, np.sin(P[:, 2] * 70 + P[:, 0] * 40) * 0.5 + 0.5) * smooth(0.5, 0.7, vnoise(P, 24, 9))
    col = mix(col, np.array([170, 160, 56.]), patch)
    return col, np.full(n, 0.5), np.zeros((n, 3))


def paint_cloth(name, sp, P, N):
    n = len(P)
    if name == "cape":
        col = mix(VIOLET, VIOLET_D, 0.35 + 0.4 * vnoise(P, 14, 2)); col = mix(col, MOSS, smooth(0.9, 1.0, sp) * 0.4 * smooth(0.5, 0.8, vnoise(P, 30, 3)))
        # gold sigil tab: shield plate with a trident-like glyph
        x, z = P[:, 0], P[:, 2]
        sd = np.maximum(np.abs(x) - 0.052 * (1 + 0.5 * smooth(1.18, 1.08, z)), np.maximum(z - 1.30, 1.08 - z)) + 0.0
        pm = smooth(0.0008, -0.0008, sd)
        col = mix(col, np.array([108, 76, 52.]), pm); col = mix(col, GOLD, line(sd + 0.007, 0.0016) * 0.9)
        glyph = np.maximum(line(x, 0.0035) * smooth(1.27, 1.26, z) * smooth(1.10, 1.12, z), np.maximum(line(z - 1.21, 0.0035) * smooth(0.032, 0.03, np.abs(x)), line(np.abs(x) - 0.026, 0.0035) * smooth(1.255, 1.25, z) * smooth(1.19, 1.20, z)))
        col = mix(col, GOLD, glyph * pm)
        em = np.tile(GOLD, (n, 1)) * (np.maximum(glyph, line(sd + 0.007, 0.0016) * 0.8) * pm * 0.5)[:, None]
        return col, np.full(n, 0.8), em
    if name in ("hood_roll", "hood_bag", "collar"):
        col = mix(VIOLET, VIOLET_D, 0.3 + 0.4 * vnoise(P, 20, 4))
        col = mix(col, MOSS, smooth(0.6, 0.8, vnoise(P, 28, 5)) * 0.7 * (1 if name != "hood_bag" else smooth(0.5, 1.0, sp)))
        if name == "collar": col = mix(INK * 1.4, MOSS, smooth(0.55, 0.75, vnoise(P, 40, 6)) * 0.8)
        return col, np.full(n, 0.8), np.zeros((n, 3))
    if name == "belt":
        col = mix(LEATHER, LEATHER * 0.7, vnoise(P, 40, 7)); col = mix(col, INK, line(((P[:, 0] * 60) % 1.0) - 0.5, 0.05) * 0.3)
        return col, np.full(n, 0.55), np.zeros((n, 3))
    if name == "buckle":
        return np.tile(GOLD, (n, 1)), np.full(n, 0.25), np.tile(GOLD, (n, 1)) * 0.25
    if name.startswith("cord_"):
        return np.tile(ORANGE * 0.95, (n, 1)), np.full(n, 0.7), np.zeros((n, 3))
    if name.startswith("leaf"):
        col = mix(OLIVE * 1.1, LIME * 0.9, smooth(0.2, 0.9, sp) * 0.8); return col, np.full(n, 0.7), np.zeros((n, 3))
    if name.startswith("charm_"):
        k = int(round(float(sp.mean())))
        c = P.mean(0); d = P - c
        base = np.array([[236, 228, 190.], [226, 218, 176.], [244, 150, 56.]])[k]
        col = np.tile(base, (n, 1)) * (0.85 + 0.2 * vnoise(P, 60, 8 + k))[:, None]
        # painted face: two dark eye holes + mouth, facing front (-y), little cheeks
        front = d[:, 1] < -0.012
        for sx in (-1, 1):
            de = np.hypot((P[:, 0] - c[0] - sx * 0.0105) / 0.0070, (P[:, 2] - c[2] - 0.0045) / 0.0085)
            col = mix(col, INK * 1.2, smooth(1.1, 0.8, de) * front)
        dm = np.hypot((P[:, 0] - c[0]) / 0.0095, (P[:, 2] - c[2] + 0.014) / (0.0045 + 0.004 * (k == 2)))
        col = mix(col, INK * 1.2, smooth(1.1, 0.8, dm) * front)
        col = mix(col, np.array([150, 120, 60.]), smooth(0.2, 0.9, (P[:, 2] - c[2]) / 0.04) * 0.3)
        return col, np.full(n, 0.45), np.zeros((n, 3))
    return np.tile(VIOLET, (n, 1)), np.full(n, 0.8), np.zeros((n, 3))


def paint_wings(S=1024):
    """two tiles (variant 0: upper panel, 1: lower panel), 512x1024 image: lime membrane with a gold-lime vein network and dark violet cells"""
    from PIL import Image
    H = S; Wd = S // 2
    img = np.zeros((H, Wd, 3), np.float32); emis = np.zeros((H, Wd, 3), np.float32)
    for tile in (0, 1):
        tw = Wd // 2
        ys, xs = np.mgrid[0:H, 0:tw]
        a = (xs + 0.5) / tw; b = (ys + 0.5) / H          # a across 0..1, b along top->bottom
        P = np.stack([a * 0.28, b * 0.9, np.zeros_like(a) + tile * 3.1], -1).reshape(-1, 3)
        f1, f2, cid, cen = worley(P, 0.095, seed=21 + tile, jitter=0.85)
        edge = (f2 - f1).reshape(H, tw)
        cidr = cid.reshape(H, tw); d_c = f1.reshape(H, tw)
        base = mix(OLIVE * 0.95, LIME * 1.05, smooth(0.0, 0.5, b)[..., None] if False else (smooth(0.0, 0.45, b))[..., None])
        base = mix(base, np.array([212, 228, 90.]), smooth(0.35, 0.0, np.abs(a - 0.5) * 2 - 0.35)[..., None] * 0.25)
        # dark violet cells in the central region, bigger toward the middle
        pick = hash1(cidr.astype(np.int64), 3 + tile) < (0.75 - 0.9 * np.abs(a - 0.5)) * smooth(0.04, 0.2, b) * smooth(0.97, 0.8, b)
        cell = pick * smooth(0.012, 0.004, edge - 0.012 * 0 - 0.0)
        cellm = pick * smooth(0.0035, 0.0075, edge)
        base = mix(base, VIOLET_D * 0.95, cellm[..., None] * 0.9)
        base = mix(base, VIOLET * 1.15, cellm[..., None] * smooth(0.04, 0.0, d_c)[..., None] * 0.5)
        # veins: network on cell borders (gold-lime) + chevron side veins + central rib
        vein = (1 - smooth(0.0016, 0.0040, edge))
        rib = line(a - 0.5, 0.012)
        chev = line(((b * 9.0 + np.abs(a - 0.5) * 3.2) % 1.0) - 0.5, 0.02) * smooth(0.0, 0.1, b)
        vm = np.clip(vein * 0.9 + rib * 0.9 + chev * 0.45, 0, 1)
        vc = mix(LIME * 1.1, np.array([240, 226, 110.]), 0.5)
        base = mix(base, vc, vm[..., None])
        # black spots
        spot = (hash1(cidr.astype(np.int64), 9 + tile) > 0.86) * (1 - pick) * smooth(0.012, 0.007, d_c)
        base = mix(base, INK * 1.3, spot[..., None] * 0.85)
        # edge darkening (leaf outline)
        eg = smooth(0.0, 0.05, a) * smooth(1.0, 0.95, a)
        base = base * (0.7 + 0.3 * eg)[..., None]
        img[:, tile * tw:(tile + 1) * tw] = base
        emis[:, tile * tw:(tile + 1) * tw] = (np.array([120., 140, 30]) * (vm * 0.25)[..., None])
    return np.clip(img, 0, 255).astype(np.uint8), np.clip(emis, 0, 255).astype(np.uint8)
