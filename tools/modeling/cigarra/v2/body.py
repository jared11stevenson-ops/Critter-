#!/usr/bin/env python3
"""Cigarra v2 body shell (everything below the neck, SDF union) + hands. Clothing is PAINTED by position (crop top, jacket sleeves,
baggy pants, bandages, boots), only silhouette-carrying cloth is real geometry (hood/cape, wings, hair, crown, charms: cards.py).
 -> work/v2/body_raw.npz (Vb, Fb) + hands (Vh_L/R)"""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, os.path.join(HERE, "..", "..", ".."))
from common import sdf2 as S
WORK = os.path.join(HERE, "..", "work", "v2"); os.makedirs(WORK, exist_ok=True)

# rig joints (tools/animation/standin.py) with the arms abducted a little so sleeves clear the baggy trousers
J = {"shoulder": (0.165, 0.01, 1.335), "elbow": (0.222, 0.02, 1.085), "wrist": (0.288, -0.012, 0.850), "hand_end": (0.305, -0.02, 0.755),
     "hip": (0.085, 0.0, 0.89), "knee": (0.095, -0.015, 0.485), "ankle": (0.10, 0.02, 0.085), "ball": (0.105, -0.085, 0.02), "toe_end": (0.11, -0.15, 0.015)}


def E(c, r, rot=None):
    return S.ellipsoid(np.asarray(c, float), r, rot)


def cap(a, b, ra, rb=None):
    return S.capsule(np.asarray(a, float), np.asarray(b, float), ra, rb)


def mir(p, s):
    return (s * p[0], p[1], p[2])


def shell():
    P = []
    P.append(E((0, 0.0, 0.935), (0.118, 0.092, 0.10)))                      # pelvis
    P.append(E((0, 0.004, 1.075), (0.100, 0.078, 0.125)))                   # midriff
    P.append(E((0, 0.002, 1.240), (0.112, 0.082, 0.105)))                   # ribcage
    P.append(cap((-0.125, 0.012, 1.318), (0.125, 0.012, 1.318), 0.040))      # shoulder yoke
    P.append(cap((0, -0.005, 1.29), (0, -0.018, 1.40), 0.036))               # neck
    for s in (-1, 1):
        sh, el, wr = mir(J["shoulder"], s), mir(J["elbow"], s), mir(J["wrist"], s)
        P.append(cap(sh, el, 0.044, 0.050))                                  # upper sleeve
        # puffy forearm sleeve gathered at the cuff
        pts = [np.array(el) + (np.array(wr) - np.array(el)) * t for t in (0.0, 0.33, 0.62, 0.86, 1.0)]
        P.append(S.tube(pts, [0.050, 0.064, 0.060, 0.040, 0.033], k=0.02))
        # baggy trousers: hip -> thigh -> knee puff -> cuff
        h, k_, a, b = mir(J["hip"], s), mir(J["knee"], s), mir(J["ankle"], s), mir(J["ball"], s)
        P.append(S.tube([np.array(h) + [0, 0, 0.02], np.array(h) + [s * 0.012, -0.004, -0.22], np.array(k_) + [s * 0.005, -0.004, 0.08], np.array(k_) + [0, 0.0, -0.08], (s * 0.100, 0.005, 0.305)],
                        [0.106, 0.114, 0.108, 0.098, 0.072], k=0.03))
        P.append(cap((s * 0.100, 0.008, 0.31), (s * 0.100, 0.022, 0.13), 0.043, 0.036))   # bandaged shin
        P.append(cap((s * 0.100, 0.022, 0.215), (s * 0.100, 0.022, 0.07), 0.056, 0.052))  # boot shaft
        P.append(cap((s * 0.100, 0.022, 0.07), (s * 0.104, -0.085, 0.035), 0.050, 0.044)) # foot
        P.append(E((s * 0.105, -0.108, 0.036), (0.046, 0.058, 0.034)))                  # toe box
        P.append(E((s * 0.100, 0.052, 0.035), (0.040, 0.034, 0.034)))                   # heel
    return S.smooth_union(P, k=0.022)


def hand_field(s):
    """hand hanging down from the wrist (local frame then placed): palm + 4 fingers slightly curled + thumb"""
    wr = np.array(mir(J["wrist"], s)); d = np.array(mir(J["hand_end"], s)) - wr; L = np.linalg.norm(d); d /= L
    P = [E(wr + d * 0.040, (0.030, 0.013, 0.048))]
    fwd = np.array([0, -1.0, 0]); side = np.array([1.0, 0, 0])
    for k, (off, ln) in enumerate(((-0.0225, 0.062), (-0.0075, 0.072), (0.0075, 0.068), (0.0225, 0.054))):
        a = wr + d * 0.080 + side * off * 1.0
        b = a + d * ln * 0.55 + fwd * 0.010
        c = b + d * ln * 0.45 + fwd * 0.022
        P.append(S.tube([a, b, c], [0.0085, 0.0075, 0.0058], k=0.003))
    # thumb: on the forward/inner side
    ta = wr + d * 0.035 + fwd * 0.016 + side * (-s * 0.026)
    tb = ta + d * 0.032 + fwd * 0.016 + side * (-s * 0.012)
    tc = tb + d * 0.026 + fwd * 0.014
    P.append(S.tube([ta, tb, tc], [0.0105, 0.0090, 0.0068], k=0.003))
    return S.smooth_union(P, k=0.006)


def main():
    V, F = S.mesh(shell(), np.array([-0.42, -0.20, 0.0]), np.array([0.42, 0.17, 1.44]), 0.0042)
    print("body raw", len(F))
    out = {"Vb": V, "Fb": F}
    for s, nm in ((1, "L"), (-1, "R")):
        h = hand_field(s); c = np.array(mir(J["wrist"], s))
        Vh, Fh = S.mesh(h, c + np.array([-0.07, -0.07, -0.20]), c + np.array([0.07, 0.07, 0.06]), 0.0016)
        out["Vh_" + nm] = Vh; out["Fh_" + nm] = Fh; print("hand", nm, len(Fh))
    np.savez(os.path.join(WORK, "body_raw.npz"), **out)


if __name__ == "__main__":
    main()
