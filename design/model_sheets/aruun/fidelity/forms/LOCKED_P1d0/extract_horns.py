"""Reference-driven HORN construction data. For each horn: medial-axis path (skeleton, routed between measured endpoints) and per-point radius (distance transform) in the v2 COMPLETED
side and back masks, combined into ONE 3D curve (F, U, L) with radii (rF from the side view, rL from the back view).
Matching: the ascending part of both paths (up to the highest point) is matched by vertical coordinate U; the descending tail (hook) is paired by arclength fraction.
Coordinates: F forward (side view x), U up, L his LEFT (= -x in the back view).  Output: horn_curves.json next to this file's output dir.
usage: python3 extract_horns.py OUT.json [--debug DIR]"""
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
os.environ['FID_REF'] = 'v2'
import numpy as np, cv2
from scipy import ndimage as ndi
from skimage.morphology import skeletonize
from skimage.graph import route_through_array
from fid_common import *

U0 = 2.12   # horn paths start here (the base is continued into the head below this)
# endpoints in metres: (x_image_m, U) with x as in the view image (side: +x = forward; back: +x = image right = his RIGHT)
PATHS = {
    'side': {'A': ((-0.047, 2.122), (0.191, 2.394)), 'B': ((0.120, 2.122), (0.274, 2.383))},
    'back': {'A': ((0.015, 2.125), (-0.093, 2.366)), 'B': ((-0.152, 2.122), (-0.364, 2.352))},
}
NEEDLE = ((0.331, 2.31),)    # side view: horn B hook needle (clipped in the original; v2 completed it)

def view_data(v):
    m = clean_mask(load_ref_alpha(v)[..., 3]); r0, r1 = band_rows(U0, 2.42)
    sub = ndi.binary_closing(m[r0:r1 + 1], iterations=2)
    sk = skeletonize(sub); dt = ndi.distance_transform_edt(sub)
    return sub, sk, dt, r0, view_info(v)['axis_x_px']

def snap(sk, pt, r0, ax):
    x, u = pt; col = ax + x * PPM; row = (GROUND - u * PPM) - r0
    ys, xs = np.nonzero(sk); d = (ys - row) ** 2 + (xs - col) ** 2; i = int(np.argmin(d)); return (ys[i], xs[i])

def route(sk, a, b):
    cost = np.where(sk, 1.0, 1e5)
    path, _ = route_through_array(cost, a, b, fully_connected=True, geometric=True)
    return np.array(path)

def smooth(a, s=6):
    return ndi.gaussian_filter1d(a, s, axis=0, mode='nearest')

def extract(v, name):
    sub, sk, dt, r0, ax = view_data(v)
    a, b = PATHS[v][name]
    p = route(sk, snap(sk, a, r0, ax), snap(sk, b, r0, ax))
    rad = dt[p[:, 0], p[:, 1]] / PPM
    X = (p[:, 1] - ax) / PPM; Uu = (GROUND - (p[:, 0] + r0)) / PPM
    Xs, Us, Rs = smooth(X), smooth(Uu), smooth(rad)
    return Xs, Us, Rs

def combine(name):
    Fs, Us_s, Rs = extract('side', name); Xb, Us_b, Rb = extract('back', name); Lb = -Xb
    def split(U):          # index of the highest point
        return int(np.argmax(U))
    ts, tb = split(Us_s), split(Us_b)
    top = min(Us_s[ts], Us_b[tb])
    # ascent: monotone cumulative max in U, then match by U
    def asc(Fv, Uv, Rv, t):
        U = np.maximum.accumulate(Uv[:t + 1]); k = np.concatenate([[True], np.diff(U) > 1e-5]); return Fv[:t + 1][k], U[k], Rv[:t + 1][k]
    f, us, rs = asc(Fs, Us_s, Rs, ts); l, ub, rb = asc(Lb, Us_b, Rb, tb)
    grid = np.linspace(max(us[0], ub[0]), top, 40)
    F = np.interp(grid, us, f); L = np.interp(grid, ub, l); rF = np.interp(grid, us, rs); rL = np.interp(grid, ub, rb)
    pts = list(zip(F, grid, L)); rad = list(zip(rF, rL))
    # descending tails (hook): pair by arclength fraction, other coordinate held at its last ascent value if the tail is absent
    ts_tail = np.stack([Fs[ts:], Us_s[ts:], Rs[ts:]], 1); tb_tail = np.stack([Lb[tb:], Us_b[tb:], Rb[tb:]], 1)
    n = 12
    def rs_(t):
        if len(t) < 3: return np.repeat(t[-1:], n, 0)
        s = np.linspace(0, 1, len(t)); return np.stack([np.interp(np.linspace(0, 1, n), s, t[:, i]) for i in range(3)], 1)
    a, bb = rs_(ts_tail), rs_(tb_tail)
    for i in range(1, n):
        pts.append((a[i, 0], 0.5 * (a[i, 1] + bb[i, 1]), bb[i, 0])); rad.append((a[i, 2], bb[i, 2]))
    return np.array(pts), np.array(rad)

def main():
    out = {}
    for nm in ('A', 'B'):
        pts, rad = combine(nm)
        # extend the base 0.035 m down into the head along the first tangent
        t = pts[1] - pts[0]; t = t / np.linalg.norm(t)
        base = pts[0] - t * 0.035
        pts = np.vstack([base, pts]); rad = np.vstack([rad[0], rad])
        keep = [0]                                            # drop (near-)duplicate points: zero-length tangents make NaN frames in the sweep
        for i in range(1, len(pts)):
            if np.linalg.norm(pts[i] - pts[keep[-1]]) > 0.004: keep.append(i)
        pts, rad = pts[keep], rad[keep]
        out[nm] = dict(points_FUL=[[round(float(x), 4) for x in p] for p in pts], radii_FL=[[round(float(x), 4) for x in r] for r in rad])
    out['needle_B_FUL'] = [list(NEEDLE[0]) and [NEEDLE[0][0], NEEDLE[0][1]]]
    json.dump(out, open(sys.argv[1], 'w'), indent=1)
    for nm in ('A', 'B'):
        p = np.array(out[nm]['points_FUL']); r = np.array(out[nm]['radii_FL'])
        print(nm, 'pts', len(p), 'F', p[:, 0].min().round(3), p[:, 0].max().round(3), 'U', p[:, 1].min().round(3), p[:, 1].max().round(3), 'L', p[:, 2].min().round(3), p[:, 2].max().round(3),
              'radius mean F/L', r[:, 0].mean().round(4), r[:, 1].mean().round(4), 'max', r.max().round(3))
main()
