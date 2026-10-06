#!/usr/bin/env python3
"""Final hero BODY camera fit with the chosen perspective strength (level camera, lens-shift pp). Writes scratch json used by later steps.
usage: lock_body_hero.py D H OUT.json   (D camera distance m, H camera height m; pitch fixed 0, f/d in [1400,2100])"""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from solve_hero import *
d, h, out = float(sys.argv[1]), float(sys.argv[2]), sys.argv[3]
best = None
for yaw0 in np.deg2rad([-60, -40, -20, 0]):
    p0 = np.array([d, h, 0, 1700 * d, 945, 1900, yaw0, 0, 0, 0])
    lo = [d - 1e-6, h - 1e-6, -1e-6, 1400 * d, 0, 0, -3.2, -1.0, -2.5, -2.5]; hi = [d + 1e-6, h + 1e-6, 1e-6, 2100 * d, 1891, 4096, 3.2, 1.0, 2.5, 2.5]
    s = least_squares(resid, p0, args=(None,), bounds=(lo, hi), x_scale=[1, .5, .1, 1000, 100, 100, .3, .3, .3, .3])
    if best is None or s.cost < best.cost: best = s
p = best.x; rr = resid(p, None)[:-1].reshape(-1, 2)
res = {n: [float(e[0] / w), float(e[1] / w)] for (n, g, px, X, w), e in zip(LM, rr)}
rms = float(np.sqrt(np.mean([(e / w) @ (e / w) for (n, g, px, X, w), e in zip(LM, rr)])))
json.dump(dict(p=p.tolist(), rms_px=rms, residuals=res), open(out, 'w'), indent=1)
print('p', np.round(p, 3), 'yaw deg', np.rad2deg(p[6]), 'twist deg', np.rad2deg(p[7]), 'footL/R deg', np.rad2deg(p[8:10]), 'f/d', p[3] / p[0], 'rms', rms, rms / 3904 * 100, '%')
for k, v in res.items(): print(k, np.round(v, 0))
