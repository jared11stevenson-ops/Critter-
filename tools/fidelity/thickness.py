#!/usr/bin/env python3
"""Limb/horn thickness = 2 x distance-transform value on the skeleton (perpendicular thickness, curvature independent), median over skeleton points
inside a region, for ref (alpha thresholds) and model sil. usage: import thickness; thickness.skel_thickness(mask, region_mask)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fid_common import *
from skimage.morphology import skeletonize

def skel_thickness(mask, region, trim_frac=0.15):
    m = mask & region
    dt = cv2.distanceTransform(m.astype(np.uint8), cv2.DIST_L2, 5)
    sk = skeletonize(m)
    v = 2 * dt[sk]
    if len(v) < 10: return None
    v = np.sort(v); n = len(v); lo, hi = int(n * trim_frac), int(n * (1 - trim_frac))
    core = v[lo:hi]    # trimmed: drops tips/joins
    return dict(median_px=float(np.median(v)), core_median_px=float(np.median(core)), p25_px=float(np.percentile(v, 25)), p75_px=float(np.percentile(v, 75)), n=int(n))
