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
