"""P1f ticket 3: arm plates (red forearm bracers/vambraces, elbow discs, upper-arm plates) and thigh plates (tan plate + red mark, hamstring plates), sabaton-to-shin cuffs. Flush shells (+4..10 mm) so
arm and leg widths stay within the current compare numbers. Arm centre lines are read from the proxy source (same CR spline) so the plates sit on the arms."""
import ast, os
import numpy as np
import build_forms as BF
from build_forms import P, tube, ell, nm, drop, FW, UP, LF

def _arm(name):
    src = open(os.path.join(P.ROOT, 'tools/modeling/aruun/v4_proxy/build_proxy.py')).read()
    for node in ast.walk(ast.parse(src)):
        if isinstance(node, ast.Call) and getattr(node.func, 'id', '') == 'tube' and node.args and isinstance(node.args[0], ast.Constant) and node.args[0].value == name:
            return np.array(ast.literal_eval(node.args[1])), np.array(ast.literal_eval(node.args[2]))

def at(name, u):
    pts, rad = _arm(name); C = P.cr(pts, 6); R = P.cr(rad, 6)[:len(C)]
    i = int(np.argmin(np.abs(C[:, 1] - u))); return C[i], R[i]

def arms(parts):
    add = []; P.NSEG = 8
    for name, sgn, n in (('armL', 1, 'L'), ('armR', -1, 'R')):
        # red forearm bracer: flat-ended shell from the elbow to above the wrist
        u0, u1 = (1.19, 1.01) if sgn > 0 else (1.20, 1.03)
        pts = []; rad = []
        for u in np.linspace(u0, u1, 4):
            c, r = at(name, u); pts.append(c); rad.append((r[0] + 0.004, r[1] + 0.004))
        add.append(nm(tube('bracer_' + n, pts, rad, hint=FW, sub=2), 'bracer_' + n))
        for k, u in enumerate((u0 - 0.03, u1 + 0.03)):          # bracer rims (raised bands)
            c, r = at(name, u); add.append(nm(tube('bracer_rim%d_%s' % (k, n), [c - [0, 0.008, 0], c + [0, 0.008, 0]], [(r[0] + 0.006, r[1] + 0.006)] * 2, hint=FW, sub=1), 'bracer_rim%d_%s' % (k, n)))
        # elbow disc (red, outward) and upper-arm plate (tan, outward)
        c, r = at(name, 1.30); add.append(nm(ell('elbow_disc_' + n, (c[0] - 0.005, c[1], c[2] + sgn * (r[1] + 0.000)), (0.045, 0.045, 0.010)), 'elbow_disc_' + n))
        c, r = at(name, 1.45); add.append(nm(ell('upper_arm_plate_' + n, (c[0], c[1], c[2] + sgn * (r[1] - 0.002)), (0.035, 0.065, 0.012)), 'upper_arm_plate_' + n))
    P.NSEG = 16
    # thigh plates: tan front plate with a red mark, tan hamstring plate on the back (flush), left leg (L=+) and right leg (L=-)
    for sgn, Lc, n in ((1, 0.17, 'L'), (-1, -0.285, 'R')):
        add.append(nm(ell('thigh_plate_' + n, (0.036, 0.76, Lc + sgn * 0.01), (0.012, 0.085, 0.055)), 'thigh_plate_' + n))
        add.append(nm(ell('thigh_mark_' + n, (0.046, 0.77, Lc + sgn * 0.01), (0.005, 0.030, 0.022)), 'thigh_mark_' + n))
        add.append(nm(ell('hamstring_plate_' + n, (-0.102, 0.70, Lc), (0.012, 0.090, 0.060)), 'hamstring_plate_' + n))
        # shin-to-sabaton join: cuff at the lower shin
        add.append(nm(tube('shin_cuff_' + n, [(-0.162, 0.275, Lc * 1.0 + (0.03 if sgn > 0 else -0.05)), (-0.162, 0.295, Lc * 1.0 + (0.03 if sgn > 0 else -0.05))], [(0.050, 0.064), (0.050, 0.064)], hint=FW, sub=1), 'shin_cuff_' + n))
    parts.extend(add)
