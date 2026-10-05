#!/usr/bin/env python3
"""Cigarra v2: DEDICATED head sculpted with SDFs (common/sdf2) from design/model_sheets/cigarra (head_x4, side_x4):
big readable face (anime-stylised, ~7 heads tall body), almond eyes under a heavy brow, small nose, soft lips, pointed
elf ears, third-eye dome on the forehead, neck.  -> work/v2/head_raw.npz  (skin skull, eyes, ears folded into the skull)

Head-local frame: x lateral (+x = her left), y = world Y (forward is -y), z up; origin = cranium centre, placed at ORIGIN.
"""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import sdf2 as S
WORK = os.path.join(HERE, "..", "work", "v2"); os.makedirs(WORK, exist_ok=True)
ORIGIN = np.array([0.0, -0.012, 1.545])        # head joint is at z=1.44; cranium centre ~10 cm above
SCALE = 1.12


def W(p):
    p = np.asarray(p, float)
    return p      # offsets are already world-oriented (forward = -y)


def E(c, r, rot=None):
    return S.ellipsoid(W(c), r, rot)


def cap(a, b, ra, rb=None):
    return S.capsule(W(a), W(b), ra, rb)


def skull_field():
    P = []
    P.append(E((0, 0.004, 0.030), (0.077, 0.088, 0.088)))                   # cranium
    P.append(E((0, -0.030, -0.026), (0.059, 0.064, 0.072)))                  # lower face
    P.append(E((0, -0.046, -0.078), (0.031, 0.034, 0.028)))                  # chin (tapered)
    for s in (-1, 1):
        P.append(E((s * 0.050, -0.018, -0.040), (0.018, 0.034, 0.030)))      # cheeks / jaw angle
        P.append(cap((s * 0.030, -0.066, 0.034), (s * 0.066, -0.040, 0.044), 0.009, 0.008))   # brow ridge (heavy-lidded look)
    P.append(E((0, -0.088, -0.016), (0.014, 0.018, 0.021)))                  # nose bridge+tip
    P.append(E((0, -0.099, -0.031), (0.012, 0.012, 0.011)))                  # nose tip
    for s in (-1, 1):
        P.append(E((s * 0.009, -0.092, -0.034), (0.008, 0.009, 0.007)))      # nostril wings
    P.append(E((0, -0.080, -0.060), (0.018, 0.012, 0.0045)))                 # upper lip
    P.append(E((0, -0.081, -0.068), (0.020, 0.013, 0.0055)))                 # lower lip
    P.append(E((0, -0.077, 0.052), (0.014, 0.008, 0.010)))                   # third-eye dome
    body = S.smooth_union(P, k=0.016)
    # eye sockets: soft carve, then eyeballs sit in them
    for s in (-1, 1):
        body = S.subtract(body, E((s * 0.036, -0.068, 0.008), (0.028, 0.015, 0.020), S.euler(0, 0, s * 0.25)), 0.008)
    # mouth line (thin groove) and nostrils
    body = S.subtract(body, E((0, -0.088, -0.0645), (0.020, 0.004, 0.0016)), 0.0015)
    for s in (-1, 1):
        body = S.subtract(body, E((s * 0.0075, -0.104, -0.034), (0.0045, 0.006, 0.0045)), 0.002)
    # ears: pointed blades swept out and up through the hair
    ears = []
    for s in (-1, 1):
        ears.append(S.capsule(W((s * 0.072, 0.005, -0.004)), W((s * 0.124, 0.022, 0.042)), 0.013, 0.0035))
        ears.append(E((s * 0.078, 0.004, -0.004), (0.010, 0.020, 0.026)))
    body = S.smooth_union([body] + ears, k=0.008)
    # neck + collar seat
    neck = S.capsule(W((0, 0.004, -0.060)), W((0, 0.020, -0.185)), 0.036, 0.040)
    body = S.smooth_union([body, neck], k=0.03)
    return body


def main():
    sk = skull_field()
    V, F = S.mesh(sk, np.array([-0.17, -0.17, -0.26]), np.array([0.17, 0.13, 0.16]), 0.0022)
    print("skull raw", len(F))
    eyes = []
    for s in (-1, 1):
        c = W((s * 0.036, -0.062, 0.008))
        eyes.append(S.mesh(S.ellipsoid(c, (0.0185, 0.0125, 0.0120), S.euler(0, 0, s * 0.25)), c - 0.03, c + 0.03, 0.0012))
    Ve = np.vstack([e[0] for e in eyes]); Fe = np.vstack([eyes[0][1], eyes[1][1] + len(eyes[0][0])])
    pl = lambda v: (v * SCALE + ORIGIN).astype(np.float32)
    np.savez(os.path.join(WORK, "head_raw.npz"), Vs=pl(V), Fs=F, Ve=pl(Ve), Fe=Fe, origin=ORIGIN, scale=SCALE)


if __name__ == "__main__":
    main()
