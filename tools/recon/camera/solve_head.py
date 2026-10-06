#!/usr/bin/env python3
"""R-HEAD / hero-head pose solve: rotate the head+horn assembly (rigid, 3 DOF about the neck-top pivot) + screen shift (+ optional uniform scale) to maximise silhouette IoU
with the reference head. Works for (a) the hero image through the solved hero camera, (b) the head tile through a fitted orthographic/weak-perspective camera.
usage: solve_head.py hero BODY.json OUT.json | solve_head.py tile OUT.json"""
import sys, json
sys.path.insert(0, __import__('os').path.dirname(__file__))
from camlib import *
from scipy.optimize import minimize
from scipy.spatial.transform import Rotation as Rot

P = load_parts()
HEADN = [k for k in P if k.startswith('H7_') or k.startswith('horn') or k.startswith('crown')]
HV, HF = merge(P, HEADN)
nk = obj = P['neck'][0]
PIV = nk[nk[:, 1] > 1.96].mean(0)          # neck top centre = head pivot (model rest frame)
print('head parts', len(HEADN), 'tris', len(HF), 'pivot', PIV.round(3))

def body_T(p, X):  # same as solve_hero.model_to_world for group torso (head rides on the torso)
    from solve_hero import Ry
    yaw, tw = p[6], p[7]
    X = (np.asarray(X) - [0, 1.0, 0]) @ Ry(tw).T + [0, 1.0, 0]
    return X @ Ry(yaw).T

def head_verts(rv, shift_world, s, pivot_w, V0):
    R = Rot.from_rotvec(rv).as_matrix()
    return ((V0 - pivot_w) * s) @ R.T + pivot_w + shift_world

def fit(cam, ref, win, pivot_w, V0, F, n_starts=60, seed=0, scale_free=False, ds=4):
    """cam: Cam (full-res). ref mask (full-res). win=(x0,y0,x1,y1) comparison window. returns best dict."""
    x0, y0, x1, y1 = win
    sub = ref[y0:y1, x0:x1] > 0
    small = cv2.resize(sub.astype(np.uint8) * 255, None, fx=1 / ds, fy=1 / ds, interpolation=cv2.INTER_AREA) > 100
    # small camera
    sc = Cam(cam.C, cam.R, cam.f / ds, (cam.cx - x0) / ds, (cam.cy - y0) / ds, small.shape[1], small.shape[0], ortho_scale=(cam.ortho / ds if cam.ortho else None))
    c_ref = cam.project(pivot_w[None])[0][0]
    def render(q):
        rv, tx, ty, ls = q[:3], q[3], q[4], (q[5] if scale_free else 0.0)
        V = head_verts(rv, 0, np.exp(ls), pivot_w, V0)
        # screen shift (px at full-res) -> world shift in the camera plane at pivot depth
        z = cam.cam_coords(pivot_w[None])[0, 2]
        k = (1.0 / cam.ortho) if cam.ortho else z / cam.f
        shift = cam.R.T @ np.array([tx * k, ty * k, 0.0])
        m, _ = raster(sc, V + shift, F)
        return m > 0
    def cost(q):
        m = render(q); return 1 - (m & small).sum() / max((m | small).sum(), 1)
    rng = np.random.default_rng(seed); best = None
    starts = [Rot.from_euler('y', a, degrees=True).as_rotvec() for a in range(0, 360, 30)]
    starts = [np.concatenate([Rot.from_euler('yxz', [yy, pp, 0], degrees=True).as_rotvec(), [0, 0, 0]]) for yy in range(-180, 180, 30) for pp in (-40, 0, 40)]
    scored = sorted(starts, key=cost)[:6]
    for q0 in scored:
        q0 = np.concatenate([q0, [0, 0, 0]])[:6 if scale_free else 5] if len(q0) == 5 else q0[:6 if scale_free else 5]
        for it in range(2):
            r = minimize(cost, q0, method='Powell', options=dict(xtol=1e-3, ftol=1e-5, maxiter=3000)); q0 = r.x
        if best is None or r.fun < best.fun: best = r
    return best, render

if __name__ == '__main__':
    mode = sys.argv[1]
    if mode == 'hero':
        bj = json.load(open(sys.argv[2])); p = np.array(bj['p'])
        from solve_hero import make_cam
        cam = make_cam(p, None); ref, _ = ref_mask(HERO_REF)
        pivot_w = body_T(p, PIV)
        V0 = body_T(p, HEADN and HV)
        win = (560, 60, 1520, 830)
        # exclude the neck (below y=830 is outside the window); model neck not in head set
        best, render = fit(cam, ref, win, pivot_w, V0, HF, scale_free=False)
        best2, _ = fit(cam, ref, win, pivot_w, V0, HF, scale_free=True)
        out = dict(IoU_fixed_scale=1 - best.fun, q=best.x.tolist(), IoU_free_scale=1 - best2.fun, q_scale=best2.x.tolist(), pivot_w=pivot_w.tolist())
        json.dump(out, open(sys.argv[3], 'w'), indent=1); print(out)
