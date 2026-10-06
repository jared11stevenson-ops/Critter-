"""P1f cloth forms (clay). Coordinates (F,U,L); his RIGHT = -L. Reference: detail_costume.png (back: cloak/mantle over the RIGHT shoulder with ragged tails; hood/collar behind the neck; chest: cream
bandage straps crossing L-shoulder -> R-hip with knot and gold ring; belt: red sash, bone ring buckle, medallion, bead strings).
mantle(): hood pad at the nape + draped mantle (the proxy mantle volume cut at 1.44 m) + ragged tails (flat tongues hanging from the lower rim, varied lengths) kept inside the side silhouette."""
import numpy as np
import build_forms as BF
from build_forms import P, tube, ell, nm, drop, FW, UP, LF

def unit(v): return v / np.linalg.norm(v)

def mantle(parts):
    drop(parts, 'mantleR'); add = []
    # draped upper mantle: same volume as the proxy mantle from the shoulder down to 1.46 m (rim), rounded cap at the rim
    add.append(nm(tube('mantleR', [(-0.07, 1.46, -0.20), (-0.08, 1.50, -0.20), (-0.09, 1.60, -0.19), (-0.08, 1.69, -0.16), (-0.07, 1.76, -0.13)],
                       [(0.095, 0.115), (0.100, 0.12), (0.13, 0.12), (0.10, 0.10), (0.05, 0.07)]), 'mantleR'))
    # hood: rolled pad behind the neck base, drooping toward the right shoulder (his right = -L)
    add.append(nm(ell('hood_pad', (-0.085, 1.78, -0.075), (0.065, 0.055, 0.135)), 'hood_pad'))
    add.append(nm(ell('hood_rim', (-0.095, 1.75, -0.170), (0.060, 0.040, 0.095)), 'hood_rim'))
    # ragged tails: flat tongues around the lower rim (back -> right side), varied lengths; rim ellipse centre/radii at U 1.47
    Fc, Lc, rF, rL = -0.075, -0.20, 0.100, 0.118
    ph = np.radians([-40, -10, 20, 50, 80, 105, 125]); ln = [0.11, 0.17, 0.13, 0.20, 0.12, 0.16, 0.09]
    for k, (a, l) in enumerate(zip(ph, ln)):
        rim = np.array([Fc - rF * np.cos(a), 1.47, Lc - rL * np.sin(a)])
        tan = unit(np.array([np.sin(a) * rF, 0.0, -np.cos(a) * rL]))               # tangent along the rim
        out = unit(np.array([-np.cos(a), 0.0, -np.sin(a)]))                        # outward normal
        pts = [rim + [0, 0.010, 0] - out * 0.004, rim + out * 0.004 - [0, l * 0.5, 0], rim + out * 0.008 - [0, l, 0]]
        add.append(nm(tube('mantle_tail%d' % k, pts, [(0.030, 0.011), (0.027, 0.010), (0.014, 0.006)], hint=tan, sub=3), 'mantle_tail%d' % k))
    parts.extend(add)

# ------------------------------------------------------------------------------------------ P1f ticket 2: chest wrap, straps, belt
import ast, os
def _trunk():
    src = open(os.path.join(P.ROOT, 'tools/modeling/aruun/v4_proxy/build_proxy.py')).read()
    for node in ast.walk(ast.parse(src)):
        if isinstance(node, ast.Call) and getattr(node.func, 'id', '') == 'tube' and node.args and isinstance(node.args[0], ast.Constant) and node.args[0].value == 'trunk':
            return np.array(ast.literal_eval(node.args[1])), np.array(ast.literal_eval(node.args[2]))
TP, TR = _trunk()
def surf(u, phi, off=0.0):
    """point on the trunk surface at height u, angle phi (0 = front (+F), + toward his LEFT), pushed `off` m outward"""
    Fc = np.interp(u, TP[:, 1], TP[:, 0]); rf = np.interp(u, TP[:, 1], TR[:, 0]); rl = np.interp(u, TP[:, 1], TR[:, 1])
    return np.array([Fc + (rf + off) * np.cos(phi), u, (rl + off) * np.sin(phi)])

def band(name, uv, width, thick, off=0.007, sub=3, hint=UP):
    pts = [surf(u, np.radians(p), off) for (u, p) in uv]
    return nm(tube(name, pts, [(width, thick)] * len(pts), hint=hint, sub=sub), name)

def chest_belt(parts):
    add = []
    # bandage wrap around the chest (two stacked bands) + two crossing straps (L shoulder -> R hip, and a second thinner one) + knot with tails + gold ring
    add.append(band('chest_wrap_band1', [(1.50, -62), (1.50, -30), (1.50, 0), (1.50, 30), (1.50, 62)], 0.026, 0.008, off=0.004))
    add.append(band('chest_wrap_band2', [(1.43, -62), (1.43, -30), (1.43, 0), (1.43, 30), (1.43, 62)], 0.024, 0.008, off=0.004))
    add.append(band('chest_strap_A', [(1.68, 70), (1.58, 45), (1.46, 18), (1.34, -12), (1.22, -42)], 0.022, 0.006, off=0.004))
    add.append(band('chest_strap_B', [(1.66, -70), (1.56, -50), (1.46, -28)], 0.016, 0.005, off=0.004))
    k = surf(1.465, -8, 0.006); add.append(nm(ell('chest_knot', tuple(k), (0.016, 0.020, 0.024)), 'chest_knot'))
    for i, (du, dp) in enumerate(((-0.07, -14), (-0.09, 6))):
        a = surf(1.465, -8, 0.008); b = surf(1.465 + du, dp, 0.006)
        add.append(nm(tube('chest_knot_tail%d' % i, [a, (a + b) / 2 + [0.004, 0, 0], b], [(0.010, 0.005), (0.009, 0.005), (0.004, 0.003)], hint=LF, sub=2), 'chest_knot_tail%d' % i))
    ring = []; c = surf(1.36, 4, 0.008)
    for t in np.linspace(0, 2 * np.pi, 13): ring.append(c + [0.0, 0.012 * np.sin(t), 0.012 * np.cos(t)])
    add.append(nm(tube('gold_ring_pendant', ring, [(0.0035, 0.0035)] * len(ring), hint=FW, sub=1), 'gold_ring_pendant'))
    # red sash belt: thick band around the waist (+ knot at his right hip)
    u0, u1 = 1.165, 1.255; um = 0.5 * (u0 + u1)
    Fc = np.interp(um, TP[:, 1], TP[:, 0]); rf = np.interp(um, TP[:, 1], TR[:, 0]); rl = np.interp(um, TP[:, 1], TR[:, 1])
    P.NSEG = 28
    add.append(nm(tube('belt_sash', [(Fc, u0, 0.0), (Fc, u1, 0.0)], [(rf + 0.003, rl + 0.005), (rf + 0.003, rl + 0.005)], hint=FW, sub=1), 'belt_sash'))
    P.NSEG = 16
    add.append(nm(ell('sash_knot', tuple(surf(1.17, -78, 0.022)), (0.030, 0.030, 0.030)), 'sash_knot'))
    # buckle ring, medallion, bead strings, studs
    ring = []; c = surf(1.21, 0, 0.008)
    for t in np.linspace(0, 2 * np.pi, 15): ring.append(c + [0.0, 0.036 * np.sin(t), 0.036 * np.cos(t)])
    add.append(nm(tube('belt_ring_buckle', ring, [(0.007, 0.007)] * len(ring), hint=FW, sub=1), 'belt_ring_buckle'))
    add.append(nm(ell('belt_medallion', tuple(surf(1.09, 0, 0.004)), (0.010, 0.036, 0.028)), 'belt_medallion'))
    for i, ph in enumerate((-16, -8, 8, 16)):
        us = [1.16, 1.10, 1.04 - 0.03 * (i % 2)]; pts = [surf(u, ph, 0.006) for u in us]
        add.append(nm(tube('belt_bead_string%d' % i, pts, [(0.004, 0.004)] * 3, hint=FW, sub=2), 'belt_bead_string%d' % i))
        for j in range(3): add.append(nm(ell('belt_bead%d_%d' % (i, j), tuple(surf(1.145 - 0.045 * j, ph, 0.008)), (0.006, 0.008, 0.006)), 'belt_bead%d_%d' % (i, j)))
    for i, ph in enumerate(np.linspace(-70, 70, 7)):
        if abs(ph) < 12: continue
        add.append(nm(ell('belt_stud%d' % i, tuple(surf(1.21, ph, 0.006)), (0.007, 0.007, 0.007)), 'belt_stud%d' % i))
    parts.extend(add)
