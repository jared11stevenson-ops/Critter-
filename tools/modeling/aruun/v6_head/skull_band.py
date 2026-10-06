"""usage: skull_band.py RENDERDIR -> IoU for the skull-only band 1.96-2.14 m (excludes neck & horns), v2 masks"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
os.environ.setdefault('FID_REF', 'v2')
import numpy as np, cv2, compare as C
from fid_common import *
rd = sys.argv[1]
for v in ('side', 'back'):
    W = view_info(v)['width_px']; ref = C.load_ref_mask(v); mod = cv2.imread(os.path.join(rd, f'sil_{v}.png'), 0) > 0
    rp = np.zeros_like(mod); rp[:, C.PAD:C.PAD + W] = ref; dx = C.best_shift(rp, mod); ma = C.shift_x(mod, dx)
    for h0, h1 in ((1.96, 2.14), (2.0, 2.14)):
        r0, r1 = band_rows(h0, h1); print(v, f'{h0}-{h1}', round(C.iou(rp[r0:r1 + 1], ma[r0:r1 + 1]), 3))
