#!/usr/bin/env python3
"""Landmark-based head orientation (scaled orthographic, rigid 3 DOF + scale + shift), all assignment hypotheses, ranked by silhouette IoU after polishing.
Used for the hero head (px of aruun_front_4096) and for the head tile (px of aruun_head_front.png): same drawing region, two pixel grids."""
import sys, json, itertools
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))) if 'os' in dir() else None
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from camlib import *
from scipy.optimize import least_squares
from scipy.spatial.transform import Rotation as Rot
P = load_parts()
def ctr(n): v = P[n][0]; return (v.min(0) + v.max(0)) / 2
HEADN = [k for k in P if k.startswith('H7_') or k.startswith('horn')]
HV, HF = merge(P, HEADN)
mand = P['H7_mandible'][0]; MAND_TIP = mand[np.argmax(mand[:, 2])]
hA, hB = P['hornA'][0], P['hornB'][0]
TIP_A = hA[np.argmax(np.linalg.norm(hA - hA[np.argmin(hA[:, 1])], axis=1))]; TIP_B = hB[np.argmax(np.linalg.norm(hB - hB[np.argmin(hB[:, 1])], axis=1))]
BASE_A, BASE_B = ctr('H7_horn_cup_A'), ctr('H7_horn_cup_B')
PIV = np.array([0.063, 1.977, 0.036])
# hero-image landmarks (orig px):
HERO = dict(eye=(1017, 636), snout=(815, 782), bigtip=(1390, 185), smalltip=(780, 270), bigbase=(920, 580), smallbase=(880, 640))
def hyps():
    for eye in ('eye_L', 'eye_R'):
        for big, small in (('A', 'B'), ('B', 'A')):
            yield eye, big, small
def model_pts(eye, big, small):
    t = dict(A=TIP_A, B=TIP_B); b = dict(A=BASE_A, B=BASE_B)
    return np.array([ctr('H7_' + eye), MAND_TIP, t[big], t[small], b[big], b[small]])
def solve(lmpx, eye, big, small, n=400, seed=1):
    X = model_pts(eye, big, small) - PIV
    ref = np.array([lmpx['eye'], lmpx['snout'], lmpx['bigtip'], lmpx['smalltip'], lmpx['bigbase'], lmpx['smallbase']], float)
    ref0 = ref - ref.mean(0)
    def res(q):
        R = Rot.from_rotvec(q[:3]).as_matrix(); s = np.exp(q[3])
        uv = (X @ R.T)[:, :2] * s * np.array([1, -1]) + q[4:6]
        return (uv - ref).ravel()
    best = None; rng = np.random.default_rng(seed)
    for _ in range(n):
        q0 = np.concatenate([Rot.random(random_state=int(rng.integers(1 << 30))).as_rotvec(), [np.log(1800), *ref.mean(0)]])
        r = least_squares(res, q0)
        if best is None or r.cost < best.cost: best = r
    return best, res
if __name__ == '__main__':
    out = []
    for eye, big, small in hyps():
        b, res = solve(HERO, eye, big, small)
        out.append((np.sqrt(b.cost * 2 / 6), eye, big, small, b.x))
        e = Rot.from_rotvec(b.x[:3]).as_euler('yxz', degrees=True)
        print(f'{eye} big={big} small={small} rms={np.sqrt(b.cost*2/6):6.1f}px scale={np.exp(b.x[3]):7.0f}px/m euler(yxz)={e.round(0)}')
