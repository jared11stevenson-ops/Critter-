"""P1d horns: the swept measured centerlines (unchanged) rebuilt as FACETED flat bone blades (8-sided oval sections, radii from the measured distance transform), with flat PLATE STEPS (collars) at the joints
instead of balls, sharp forked/notched TINES, forked tips, A with a SADDLE at its base (A = near/thick, B = slimmer/longer, different part counts and tine layouts) and a BRIDGE between A's top and B's
shaft (the inward arch seen in the back view)."""
import os
import numpy as np
import build_forms as BF
from build_forms import P, tube, ell, nm, FW, UP, LF

def at(pts, f):
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]; s = f * seg[-1]
    i = int(np.clip(np.searchsorted(seg, s) - 1, 0, len(pts) - 2)); u = (s - seg[i]) / max(seg[i + 1] - seg[i], 1e-6)
    p = pts[i] * (1 - u) + pts[i + 1] * u; t = pts[i + 1] - pts[i]; return p, t / np.linalg.norm(t), i

def unit(v): return v / np.linalg.norm(v)

def build(parts, C, rscale=1.07):
    old = P.NSEG; P.NSEG = 8; add = []
    for n, hint, order, plates, tines in (('A', LF, (1, 0), (0.22, 0.50, 0.78), (0.35, 0.62)), ('B', FW, (0, 1), (0.30, 0.62, 0.86), (0.42, 0.74, 0.90))):
        pts = np.array(C[n]['points_FUL']); rad = np.array(C[n]['radii_FL'])
        r = rad[:, list(order)] * rscale * 1.04
        r[-3:] *= np.array([[0.7], [0.5], [0.3]])
        add.append(nm(tube('horn' + n, pts, r, hint=hint, sub=2), 'horn' + n))
        # flat plate steps (collars) at the joints: short wider 6-sided tubes with flat ends
        P.NSEG = 6
        for k, f in enumerate(plates):
            p, t, i = at(pts, f); rr = r[min(i, len(r) - 1)]
            add.append(nm(tube('horn%s_plate%d' % (n, k), [p - t * 0.008, p + t * 0.008], [tuple(rr * 1.10), tuple(rr * 1.10)], hint=hint, sub=1), 'horn%s_plate%d' % (n, k)))
        # forked tines on the rear/outer edge: each = long prong + short second prong
        P.NSEG = 5
        for k, f in enumerate(tines):
            p, t, i = at(pts, f); rr = r[min(i, len(r) - 1)]
            nrm = unit(np.cross(t, [0, 0, 1.0]))                     # perpendicular in the F-U plane
            if (nrm[0] > 0) == (n == 'A'): nrm = -nrm                  # A: rearward (away from B); B: forward (away from A)
            nrm = unit(nrm - t * 0.35)                                # swept back toward the base
            base = p + nrm * rr.max() * 0.6; L1 = 0.028 if n == 'A' else 0.024
            add.append(nm(tube('horn%s_tine%d' % (n, k), [base, base + nrm * L1 * 0.5, base + nrm * L1 + t * 0.01], [(0.010, 0.009), (0.007, 0.006), (0.0015, 0.0015)], hint=hint, sub=2), 'horn%s_tine%d' % (n, k)))
            alt = unit(nrm * 0.7 - t * 0.5)
            add.append(nm(tube('horn%s_tine%db' % (n, k), [base + nrm * L1 * 0.45, base + nrm * L1 * 0.45 + alt * 0.022], [(0.006, 0.005), (0.0012, 0.0012)], hint=hint, sub=1), 'horn%s_tine%db' % (n, k)))
        # forked tip
        e, t, _ = at(pts, 1.0); side = unit(np.cross(t, [0, 1.0, 0]))
        for s_, nn in ((1, 'a'), (-1, 'b')):
            d = unit(t + side * 0.45 * s_)
            add.append(nm(tube('horn%s_fork%s' % (n, nn), [e - t * 0.01, e + d * 0.014, e + d * 0.028], [(0.008, 0.008), (0.005, 0.005), (0.0012, 0.0012)], hint=hint, sub=2), 'horn%s_fork%s' % (n, nn)))
        if n == 'A':      # saddle at the base of the near/thick horn
            p, t, i = at(pts, 0.06)
            add.append(nm(ell('hornA_saddle', tuple(p + [0, 0.004, 0]), (r[2][1] + 0.028, 0.016, r[2][0] + 0.030)), 'hornA_saddle'))
        P.NSEG = 8
        if n == 'B':      # the dark hooked needle (v2 side view)
            e = pts[-1]; add.append(nm(tube('hornB_needle', [e, (e[0] + 0.035, e[1] - 0.035, e[2]), (0.331, 2.31, e[2])], [(0.012, 0.012), (0.007, 0.007), (0.002, 0.002)], hint=FW, sub=3), 'hornB_needle'))
    # crown tines between the bases (inward spurs of the back-view arch: A's inner side points toward B and B's toward A, rising from the crown)
    A = np.array(C['A']['points_FUL']); B = np.array(C['B']['points_FUL'])
    pa, ta, _ = at(A, 0.10); pb, tb, _ = at(B, 0.10)
    P.NSEG = 5
    add.append(nm(tube('crown_tine_A', [pa + [0, 0, 0.012], pa + [0.0, 0.02, 0.040], pa + [-0.01, 0.045, 0.062]], [(0.010, 0.012), (0.007, 0.008), (0.0015, 0.0015)], hint=UP, sub=2), 'crown_tine_A'))
    add.append(nm(tube('crown_tine_B', [pb - [0, 0, 0.012], pb + [0.0, 0.02, -0.036], pb + [0.01, 0.040, -0.056]], [(0.010, 0.011), (0.007, 0.008), (0.0015, 0.0015)], hint=UP, sub=2), 'crown_tine_B'))
    P.NSEG = old
    parts.extend(add)
