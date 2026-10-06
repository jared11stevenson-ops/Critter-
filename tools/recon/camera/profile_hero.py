#!/usr/bin/env python3
"""Profile of the hero landmark fit cost over camera distance d and camera height h (everything else free), f/d (px per m at the target) bounded to [1400,2100]."""
import sys, json
sys.path.insert(0, __import__('os').path.dirname(__file__))
from solve_hero import *
def fit(d, h):
    best = None
    for yaw0 in np.deg2rad([-60, -40, -20, 0]):
        for phi0 in np.deg2rad([0, 10, 25]):
            p0 = np.array([d, h, phi0, 1700 * d, 945, 1900, yaw0, 0, 0, 0])
            lo = [d - 1e-6, h - 1e-6, -0.2, 1400 * d, 0, 0, -3.2, -1.0, -2.5, -2.5]; hi = [d + 1e-6, h + 1e-6, 0.9, 2100 * d, 1891, 4096, 3.2, 1.0, 2.5, 2.5]
            s = least_squares(resid, p0, args=(None,), bounds=(lo, hi), x_scale=[1, .5, .1, 1000, 100, 100, .3, .3, .3, .3])
            if best is None or s.cost < best.cost: best = s
    return best
if __name__ == '__main__':
    out = {}
    print('rows h (m); cols d (m); rms px   [yaw deg / pitch deg]')
    ds = [2.5, 3.5, 5, 8, 14, 30]; hs = [0.3, 0.7, 1.1, 1.5]
    for h in hs:
        row = []
        for d in ds:
            s = fit(d, h); p = s.x; rr = resid(p, None)[:-1].reshape(-1, 2)
            rms = np.sqrt(np.mean([(e / w) @ (e / w) for (n, g, px, X, w), e in zip(LM, rr)]))
            row.append(f'{rms:6.0f} [{np.rad2deg(p[6]):4.0f}/{np.rad2deg(p[2]):3.0f}]'); out[f'{h}_{d}'] = dict(rms=rms, p=p.tolist())
        print(f'h={h:3.1f}', ' | '.join(row), flush=True)
    json.dump(out, open('/tmp/claude-0/-home-user/93e78eb3-d0a6-51a5-a1e6-85186b0b3df8/scratchpad/prof.json', 'w'))
