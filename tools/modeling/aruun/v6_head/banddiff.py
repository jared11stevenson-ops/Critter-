"""usage: banddiff.py RENDERDIR OUT.png -> side/back head-band diff (white both, red ref-only, blue model-only), rows 1.75-2.2 m (FID_REF=v2)"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
os.environ.setdefault('FID_REF', 'v2')
import numpy as np, cv2, compare as C
from fid_common import *
rd, out = sys.argv[1], sys.argv[2]; tiles = []
for v in ('side', 'back'):
    W = view_info(v)['width_px']; ref = C.load_ref_mask(v)
    mod = cv2.imread(os.path.join(rd, f'sil_{v}.png'), 0) > 0
    rp = np.zeros_like(mod); rp[:, C.PAD:C.PAD + W] = ref
    dx = C.best_shift(rp, mod); ma = C.shift_x(mod, dx)
    r0, r1 = band_rows(1.75, 2.25); cx = C.PAD + int(view_info(v)['axis_x_px']) + (250 if v == 'side' else 0)
    a, b = rp[r0:r1, cx - 450:cx + 450], ma[r0:r1, cx - 450:cx + 450]
    im = np.full(a.shape + (3,), 255, np.uint8); im[a & b] = (170, 170, 170); im[a & ~b] = (40, 40, 230); im[b & ~a] = (230, 120, 30)
    tiles.append(im)
cv2.imwrite(out, np.hstack(tiles)); print(out)
