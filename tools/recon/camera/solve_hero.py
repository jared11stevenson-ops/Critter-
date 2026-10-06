#!/usr/bin/env python3
"""R-HERO body camera solve. Landmark pairs (ref px <-> model point), nuisance pose params (hips yaw, torso twist, per-foot yaw), least squares.
usage: solve_hero.py [--fix-f F_PX] [--ortho] -> prints result JSON (used by the lock script)"""
import sys, json, argparse
sys.path.insert(0, __import__('os').path.dirname(__file__))
from camlib import *
from scipy.optimize import least_squares

P = load_parts()
def obj(n): return P[n][0]
def ctr(n):
    v = obj(n); return (v.min(0) + v.max(0)) / 2
def ext(n, axis, sign, band=None):
    v = obj(n); i = np.argmax(sign * v[:, axis]); return v[i]
def lowext(names, axis, sign, ymax=0.12):
    V = np.concatenate([obj(n) for n in names]); V = V[V[:, 1] < ymax]; return V[np.argmax(sign * V[:, axis])]

FOOTL = ['foot_L', 'sole_L', 'toe_claw1_L', 'toe_claw2_L', 'toe_claw3_L']
FOOTR = ['foot_R', 'sole_R', 'toe_claw1_R', 'toe_claw2_R', 'toe_claw3_R']
# (name, group, ref_px (x,y), model xyz, weight)
LM = [
 ('footL_toe_tip',   'footL', (1675, 3985), lowext(FOOTL, 2, +1), 1.0),
 ('footL_side_in',   'footL', (1490, 3800), lowext(FOOTL, 0, -1, 0.17), 0.6),
 ('footL_side_out',  'footL', (1835, 3800), lowext(FOOTL, 0, +1, 0.17), 0.6),
 ('footR_toe_tip',   'footR', (372, 3835),  lowext(FOOTR, 2, +1), 1.0),
 ('footR_heel',      'footR', (862, 3790),  lowext(FOOTR + ['heel_spur_R'], 2, -1, 0.12), 1.0),
 ('ankleL',          'legL',  (1580, 3520), np.array([*ctr('foot_L')[[0]], 0.25, ctr('foot_L')[2]]), 0.7),
 ('ankleR',          'legR',  (705, 3540),  np.array([*ctr('foot_R')[[0]], 0.25, ctr('foot_R')[2]]), 0.7),
 ('kneeL',           'legL',  (1330, 2810), ctr('knee_plate_L'), 0.4),
 ('kneeR',           'legR',  (770, 2990),  ctr('knee_plate_R'), 0.4),
 ('belt_buckle',     'hips', (710, 1955),  ctr('belt_ring_buckle'), 1.0),
 ('belt_medallion',  'hips', (712, 2190),  ctr('belt_medallion'), 1.0),
 ('pauldronL',       'torso', (1520, 1250), ctr('pauldron_disc'), 1.0),
 ('elbowL',          'torso', (1548, 1917), ctr('elbow_disc_L'), 0.2),
]
W_, H_ = 1891, 4096

def Ry(a):
    c, s = np.cos(a), np.sin(a); return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])

def make_cam(p, fixed):
    d, h, phi, f, cx, cy = p[:6]
    C = np.array([0, h, d]); T = C + np.array([0, np.sin(phi), -np.cos(phi)])
    return Cam(C, look_at(C, T), f, cx, cy, W_, H_)

def model_to_world(p, X, grp, pivot_y=1.0):
    yaw, tw, fl, fr = p[6:10]
    X = np.asarray(X, float)
    if grp == 'torso': X = (X - [0, pivot_y, 0]) @ Ry(tw).T + [0, pivot_y, 0]
    if grp == 'footL': c = np.array([ctr('foot_L')[0], 0, ctr('foot_L')[2]]); X = (X - c) @ Ry(fl).T + c
    if grp == 'footR': c = np.array([ctr('foot_R')[0], 0, ctr('foot_R')[2]]); X = (X - c) @ Ry(fr).T + c
    return X @ Ry(yaw).T

def resid(p, fixed):
    cam = make_cam(p, fixed)
    r = []
    for n, g, px, X, w in LM:
        uv, z = cam.project(model_to_world(p, X, g)[None])
        r += list((uv[0] - np.array(px)) * w)
    r += [p[7] * 60.0 * 0.3]      # weak prior: torso twist small (px/rad)
    return np.array(r)

def solve(fix_f=None, start=None, ortho=False):
    best = None
    for yaw0 in np.deg2rad([-60, -40, -20, 0, 20, 40]):
      for phi0 in np.deg2rad([-5, 8, 20]):
        for d0, f0 in [(4.0, 6800), (8.0, 13500), (14.0, 24000)]:
            p0 = np.array([d0, 1.0, phi0, f0, 945, 1900, yaw0, 0, 0, 0])
            lo = [1.5, -0.5, -0.6, 2000, 0, 0, -3.2, -1.0, -2.5, -2.5]; hi = [60, 4, 0.8, 200000, 1891, 4096, 3.2, 1.0, 2.5, 2.5]
            if fix_f:
                lo[3] = fix_f - 1; hi[3] = fix_f + 1; p0[3] = fix_f; p0[0] = fix_f * 2.4 / 3900
            try: s = least_squares(resid, p0, args=(None,), bounds=(lo, hi), x_scale=[1, .5, .1, 1000, 100, 100, .3, .3, .3, .3])
            except Exception as e: continue
            if best is None or s.cost < best.cost: best = s
    return best

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--fix-f', type=float); a = ap.parse_args()
    s = solve(a.fix_f); p = s.x
    cam = make_cam(p, None)
    print('params d,h,phi,f,cx,cy,yaw,twist,footL,footR:', np.round(p, 3), 'deg yaw', np.rad2deg(p[6]), 'phi', np.rad2deg(p[2]))
    rr = resid(p, None)[:-1].reshape(-1, 2)
    for (n, g, px, X, w), e in zip(LM, rr): print(f'{n:16s} err_px=({e[0]/w:7.1f},{e[1]/w:7.1f})')
    rms = np.sqrt(np.mean([(e / w) @ (e / w) for (n, g, px, X, w), e in zip(LM, rr)])); print('rms px', rms, '% of fig height', rms / 3904 * 100)
