#!/usr/bin/env python3
"""v2 (3): TRUE ORTHOGRAPHIC FRONT body. Non-diffusion: the measured proxy is rendered at the orthographic front camera (silhouette + visible part ids);
each visible part group takes its paint from the original 3/4 front sheet cut (ortho/aruun_front_4096.png, a perspective low-camera 3/4 pose) through a
hand-registered row-wise horizontal warp (keyframes below = sheet landmarks read on the 100-px grid overlays), vertical mapping per keyframe.
Output of this module: body RGBA + class map (head groups are left empty here; v2_head.py fills them)."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
from scipy.ndimage import median_filter, uniform_filter1d
AX, W = 900, 1891
W_S = 1891
GROUPS = {   # group -> (proxy parts, keyframes [(h_m, sheet_y, sheet_xl, sheet_xr)])  sheet = ortho/aruun_front_4096.png px; h top->bottom
 'neck':   (['neck'], [(2.00, 800, 1040, 1260), (1.85, 1000, 1050, 1270), (1.72, 1300, 1000, 1290)]),
 'neckbase': (['neckbase'], [(1.85, 1300, 700, 1000), (1.72, 1400, 700, 1000)]),
 'trunk':  (['trunk'], [(1.75, 1300, 840, 1420), (1.60, 1450, 780, 1400), (1.45, 1650, 700, 1330), (1.25, 1950, 640, 1290), (1.05, 2290, 480, 1340), (0.88, 2569, 440, 1400)]),
 'mantle': (['mantleR'], [(1.80, 1250, 850, 980), (1.60, 1420, 600, 800), (1.45, 1560, 500, 700), (1.30, 1700, 530, 650)]),
 'pauldron': (['pauldronL'], [(1.73, 1080, 1480, 1640), (1.58, 1250, 1400, 1710), (1.44, 1480, 1500, 1700)]),
 'armL':   (['armL', 'fistL'], [(1.45, 1750, 1450, 1720), (1.30, 1900, 1440, 1790), (1.15, 2150, 1440, 1730), (1.00, 2370, 1480, 1700), (0.92, 2470, 1400, 1690), (0.75, 2580, 1400, 1690)]),
 'armR':   (['armR', 'fistR'], [(1.45, 1850, 360, 640), (1.30, 1980, 280, 560), (1.15, 2150, 180, 470), (1.00, 2330, 70, 340), (0.93, 2420, 40, 330), (0.85, 2520, 20, 400)]),
 'legL':   (['legL', 'footL', 'soleL'], [(0.93, 2520, 1180, 1560), (0.75, 2640, 1200, 1520), (0.60, 2760, 1240, 1520), (0.45, 3000, 1330, 1550), (0.30, 3300, 1420, 1620),
                                          (0.25, 3480, 1430, 1620), (0.18, 3600, 1380, 1700), (0.0, 4000, 1350, 1750)]),
 'legR':   (['legR', 'footR', 'soleR'], [(0.94, 2569, 400, 880), (0.75, 2800, 430, 880), (0.60, 3000, 540, 860), (0.45, 3250, 620, 800), (0.30, 3430, 640, 780), (0.18, 3600, 520, 800), (0.0, 3880, 330, 790)]),
 'strips': (['stripmassR'], [(0.89, 2600, 900, 1180), (0.65, 2950, 880, 1200), (0.40, 3250, 850, 1150)]),
}
HEAD_PARTS = ['cranium', 'snout', 'hornA', 'hornB', 'hornB_tooth']

def target_raster():
    V, F, pid, names = load_parts()
    fid, zb, bu, bv = rasterise(V, F, 0, AX, W)
    P = np.where(fid >= 0, pid[np.maximum(fid, 0)], -1)
    return V, F, pid, names, fid, zb, P

def mirrored_back_mask():
    """orthographic FRONT silhouette of everything below the neck = the BACK cut's alpha mirrored about the shared world axis (front col = AX + back_axis - back col)."""
    b = load_rgba(os.path.join(ORTHO, 'aruun_back_4096.png')); m = (b[..., 3] > 128).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8); keep = np.zeros(n, bool); keep[1:] = st[1:, 4] > 400; m = keep[lab]
    bx = META['views']['back']['axis_x_px']; out = np.zeros((4096, W), bool)
    cols = np.arange(m.shape[1]); cf = np.round(AX + bx - cols).astype(int); ok = (cf >= 0) & (cf < W)
    out[:, cf[ok]] = m[:, cols[ok]]; return out

def build(sheet, use_back_silhouette=True):
    V, F, pid, names, fid, zb, P = target_raster()
    if use_back_silhouette:
        S = mirrored_back_mask(); hrow = (GROUND - np.arange(4096)) / PPM
        S[hrow >= 1.80] = False
        cov = (P >= 0) & (np.isin(P, [names.index(p) for p in HEAD_PARTS]) == False)
        dist, lab = cv2.distanceTransformWithLabels((~cov).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
        zy, zx = np.where(dist == 0); l2 = np.full(lab.max() + 1, -1, np.int32); l2[lab[zy, zx]] = P[zy, zx]
        Pn = l2[lab]
        P2 = np.where(hrow[:, None] >= 1.80, P, np.where(S, Pn, -1)).astype(P.dtype)
        P = P2
    H = 4096
    out = np.zeros((H, W, 4), np.uint8); cls = np.zeros((H, W), np.uint8); grp = np.full((H, W), -1, np.int8)
    ys_all, xs_all = np.mgrid[0:H, 0:W]
    alpha = sheet[..., 3] > 128
    # nearest opaque sheet pixel for transparent samples
    dist, lab = cv2.distanceTransformWithLabels((~alpha).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    ys_o, xs_o = np.where(alpha); lab2xy = np.zeros((lab.max() + 1, 2), np.int32)
    zy, zx = np.where(dist == 0); lab2xy[lab[zy, zx]] = np.c_[zx, zy]
    stats = {}
    for gi, (g, (parts, kf)) in enumerate(GROUPS.items()):
        ids = [names.index(p) for p in parts]; m = np.isin(P, ids); grp[m] = gi
        rows = np.where(m.any(1))[0]
        xl_t = np.full(H, np.nan); xr_t = np.full(H, np.nan)
        for r in rows:
            c = np.where(m[r])[0]; xl_t[r] = c[0]; xr_t[r] = c[-1] + 1
        # fill + smooth extents
        okr = ~np.isnan(xl_t); xl_t = np.interp(np.arange(H), np.where(okr)[0], xl_t[okr]); xr_t = np.interp(np.arange(H), np.where(okr)[0], xr_t[okr])
        xl_t = uniform_filter1d(median_filter(xl_t, 81), 61); xr_t = uniform_filter1d(median_filter(xr_t, 81), 61)
        kh = np.array([k[0] for k in kf])[::-1]; ky = np.array([k[1] for k in kf], float)[::-1]; kl = np.array([k[2] for k in kf], float)[::-1]; kr = np.array([k[3] for k in kf], float)[::-1]
        hh = (GROUND - np.arange(H)) / PPM
        ysr = np.interp(hh, kh, ky); xlr = np.interp(hh, kh, kl); xrr = np.interp(hh, kh, kr)
        if g not in ('trunk', 'strips'):     # snap the sheet span to the real sheet silhouette edges inside +-70 px of the hand-picked keyframe span
            for r in rows:
                yi = int(np.clip(round(ysr[r]), 0, sheet.shape[0] - 1)); row = alpha[yi]
                lo, hi = int(max(xlr[r] - 70, 0)), int(min(xrr[r] + 70, W_S - 1)); c = np.where(row[lo:hi + 1])[0]
                if len(c) > 20:
                    cl, cr = lo + c[0], lo + c[-1]
                    if abs(cl - xlr[r]) < 70: xlr[r] = cl + 6
                    if abs(cr - xrr[r]) < 70: xrr[r] = cr - 6
            xlr = uniform_filter1d(xlr, 25); xrr = uniform_filter1d(xrr, 25)
        sx_ = (xrr - xlr) / np.maximum(xr_t - xl_t, 1); dy = np.gradient(ysr)
        yy, xx = np.where(m)
        u = (xx - xl_t[yy]) / np.maximum(xr_t[yy] - xl_t[yy], 1)
        sxm = xlr[yy] + u * (xrr[yy] - xlr[yy]); sym = ysr[yy]
        sxi = np.clip(np.round(sxm).astype(int), 0, sheet.shape[1] - 1); syi = np.clip(np.round(sym).astype(int), 0, sheet.shape[0] - 1)
        op = alpha[syi, sxi]; fx, fy = sxi.copy(), syi.copy()
        l = lab[syi, sxi]; nn = lab2xy[l]; d = dist[syi, sxi]
        fx[~op] = nn[~op, 0]; fy[~op] = nn[~op, 1]
        out[yy, xx, :3] = sheet[fy, fx, :3]; out[yy, xx, 3] = 255
        stretch = np.maximum(sx_[yy], np.abs(dy[yy])); smin = np.minimum(sx_[yy], np.abs(dy[yy]))
        c = np.full(len(yy), 2, np.uint8)
        c[(~op) & (d > 10)] = 3                     # RED: no sheet paint at that place (gap in the sheet) -> nearest neighbour
        good = op & (sx_[yy] > 0.8) & (sx_[yy] < 1.25) & (np.abs(dy[yy]) > 0.8) & (np.abs(dy[yy]) < 1.25)
        cls[yy, xx] = c
        stats[g] = dict(parts=parts, rows=[int(rows.min()), int(rows.max())], mean_x_scale=float(np.mean(sx_[yy])), mean_y_scale=float(np.mean(np.abs(dy[yy]))), px=int(m.sum()),
                        green=float((c == 1).mean() * 100), yellow=float((c == 2).mean() * 100), red=float((c == 3).mean() * 100))
    hid = np.isin(P, [names.index(p) for p in HEAD_PARTS])
    return out, cls, grp, P, hid, stats, names

if __name__ == '__main__':
    sheet = load_rgba(os.path.join(ORTHO, 'aruun_front_4096.png'))
    out, cls, grp, P, hid, stats, names = build(sheet)
    np.save('/tmp/front_body.npy', out)
    cv2.imwrite('/tmp/front_body_dbg.png', overlay(out, cls))
    save_rgba('/tmp/front_body.png', out)
    for g, s in stats.items(): print(g, {k: (round(v, 2) if isinstance(v, float) else v) for k, v in s.items() if k != 'parts'})
