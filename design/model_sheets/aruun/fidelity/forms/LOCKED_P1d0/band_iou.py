"""Band IoU of a render against the reference (same alignment as compare.py: best whole-silhouette x shift per view). Bands (m): horn zone 2.0-2.4, horns only 2.14-2.4,
head 1.75-2.0 (inspector's definition), head+horns 1.75-2.4, plus the whole silhouette. usage: [FID_REF=v2] python3 band_iou.py RENDER_DIR [OUT.json]"""
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
import numpy as np, cv2
import compare as C
from fid_common import *
BANDS = {'horn_zone_2.0-2.4': (2.0, 2.4), 'horns_only_2.14-2.4': (2.14, 2.4), 'head_1.75-2.0': (1.75, 2.0), 'head+horns_1.75-2.4': (1.75, 2.4), 'whole': (0.0, 2.4)}
def main():
    rd = sys.argv[1]; res = {}
    for v in ('side', 'back'):
        W = view_info(v)['width_px']; ref = C.load_ref_mask(v)
        mod = cv2.imread(os.path.join(rd, f'sil_{v}.png'), 0) > 0
        rp = np.zeros_like(mod); rp[:, C.PAD:C.PAD + W] = ref
        dx = C.best_shift(rp, mod); ma = C.shift_x(mod, dx)
        res[v] = {}
        for k, (h0, h1) in BANDS.items():
            r0, r1 = band_rows(h0, h1)
            a, b = rp[r0:r1 + 1], ma[r0:r1 + 1]
            res[v][k] = dict(iou=round(C.iou(a, b), 3), ref_only_px=int((a & ~b).sum()), model_only_px=int((b & ~a).sum()))
    for k in BANDS: print(f"{k:22s} side {res['side'][k]['iou']:.3f} (ref-only {res['side'][k]['ref_only_px']:6d}, model-only {res['side'][k]['model_only_px']:6d})   back {res['back'][k]['iou']:.3f} (ref-only {res['back'][k]['ref_only_px']:6d}, model-only {res['back'][k]['model_only_px']:6d})")
    if len(sys.argv) > 2: json.dump(res, open(sys.argv[2], 'w'), indent=1)
main()
