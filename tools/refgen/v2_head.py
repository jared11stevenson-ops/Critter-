#!/usr/bin/env python3
"""v2 head layer for the front ortho + straight-on FACE views (non-diffusion).
Face tiles = design/reference_gen/aruun/head/aruun_head_{front,rage}_straighton.png (Real-ESRGAN x4 of the sheet's CALM / RAGE expression tiles, 4000 px/m, rows_px landmarks).
Long horns are NOT on the tiles (cut by the tile top): they are projected from the side and back sheet cuts onto the proxy horn tubes (3D projection with visibility test),
shifted in x so that each horn base meets the matching tile horn stub top (landmark registration), YELLOW."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
HEAD = os.path.join(ROOT, 'design/reference_gen/aruun/head')
TILE_PPM = 4000.0; EYE_ROW = 1499; EYE_H = 2.0752; NECK_ROW = 2712     # derivation json rows_px
X_HEAD = 0.08                                                          # world x of the tile's eye midline (proxy cranium centre 0.09, neck 0.07)
SIDE_AX = META['views']['side']['axis_x_px'] - 10; BACK_AX = META['views']['back']['axis_x_px']   # -10: best-IoU shift of the proxy to the side cut

def tile_mask(im, name):
    bg = im[5, 5].astype(int); d = np.abs(im.astype(int) - bg).sum(2)
    m = (d > 45).astype(np.uint8)
    if name == 'front_straighton': m[:696] = 0                       # black clip line of the CALM tile (rows ~686-692)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
    keep = np.zeros(n, bool); keep[1:] = st[1:, 4] > 3000; m = keep[lab].astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    return m.astype(bool)

def place_tile(name, canvas_w, ax, x_world=X_HEAD, h_cut=None):
    im = cv2.imread(os.path.join(HEAD, f'aruun_head_{name}.png')); m = tile_mask(im, name)
    s = PPM / TILE_PPM
    rgba = np.dstack([im, m.astype(np.uint8) * 255])
    rs = cv2.resize(rgba, None, fx=s, fy=s, interpolation=cv2.INTER_AREA); ms = cv2.resize(m.astype(np.uint8) * 255, None, fx=s, fy=s, interpolation=cv2.INTER_AREA)
    rs[..., 3] = np.where(ms > 160, 255, 0)
    row0 = GROUND - EYE_H * PPM - EYE_ROW * s                                         # canvas row of tile row 0
    col0 = ax + x_world * PPM - 765 * s                                               # tile col 765 = eye midline
    out = np.zeros((4096, canvas_w, 4), np.uint8); r0 = int(round(row0)); c0 = int(round(col0))
    h, w = rs.shape[:2]
    out[r0:r0 + h, c0:c0 + w] = rs[:min(h, 4096 - r0), :min(w, canvas_w - c0)] if r0 >= 0 else out[r0:r0 + h, c0:c0 + w]
    if h_cut is not None: out[int(round(GROUND - h_cut * PPM)):] = 0               # drop tile rows below h_cut (neck row)
    return out, dict(scale=s, row0=r0, col0=c0, tile=f'aruun_head_{name}.png')

def view_sampler(view):
    """returns function (P world pts Nx3) -> (bgr, ok)"""
    if view == 'side': a = load_rgba(os.path.join(ORTHO, 'aruun_side_4096.png')); yaw, ax = -90, SIDE_AX
    else: a = load_rgba(os.path.join(ORTHO, 'aruun_back_4096.png')); yaw, ax = 180, BACK_AX
    alpha = a[..., 3] > 128
    dist, lab = cv2.distanceTransformWithLabels((~alpha).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
    zy, zx = np.where(dist == 0); l2 = np.zeros((lab.max() + 1, 2), np.int32); l2[lab[zy, zx]] = np.c_[zx, zy]
    def f(P, maxd=45):
        sx, sy, _ = project(P, yaw, ax)
        xi = np.clip(np.round(sx).astype(int), 0, a.shape[1] - 1); yi = np.clip(np.round(sy).astype(int), 0, a.shape[0] - 1)
        d = dist[yi, xi]; nn = l2[lab[yi, xi]]
        col = a[nn[:, 1], nn[:, 0], :3]; return col, d <= maxd, d
    return f

def horn_layer(canvas_w, ax, stubA_x, stubB_x, h_min=2.14, taper_h=2.34, base_h=2.26, xh=None):
    """Front-view horns = the BACK ortho silhouette mirrored (an orthographic front view is the mirror image of the back view for any thin solid), painted with the
    back cut's own pixels (horn paint is a flat cel colour on all faces; the opposite face is a mild assumption -> YELLOW). The back head midline is registered to the
    tile eye midline; then each horn is nudged in x so its base meets the matching tile horn-stub top, the nudge tapering to zero at taper_h."""
    xh = X_HEAD if xh is None else xh
    a = load_rgba(os.path.join(ORTHO, 'aruun_back_4096.png')); H, Wb = a.shape[:2]
    hh = (GROUND - np.arange(H)) / PPM
    # back head midline: the cranium column centre at h=2.05..2.10 (dark navy head), measured from the opaque span
    r = int(GROUND - 2.07 * PPM); c = np.where(a[r, :, 3] > 128)[0]
    mid_back = (c[0] + c[-1]) / 2.0
    out = np.zeros((4096, canvas_w, 4), np.uint8); cls = np.zeros((4096, canvas_w), np.uint8)
    rows = np.where(hh >= h_min)[0]; info = dict(back_head_mid_col=float(mid_back), head_span_row=int(r))
    # which back-image side is A: A = thick red horn at his RIGHT = back image-right (x > mid) -> mirrored image-left
    # base nudges measured at base_h on the mirrored layer
    rb = int(GROUND - base_h * PPM); cb = np.where(a[rb, :, 3] > 128)[0]
    runs_ = np.split(cb, np.where(np.diff(cb) > 1)[0] + 1); runs_ = [rr for rr in runs_ if len(rr) > 4]
    cen = [(rr.mean() - mid_back) for rr in runs_]                                    # back-image offsets of the horn bases (px)
    info['horn_runs_at_base_row_px_from_mid'] = [float(x) for x in cen]
    # mirrored world x of a run = X_HEAD - off/PPM ; A is the run with off>0 (back image-right), B off<0
    tgtA, tgtB = stubA_x, stubB_x
    dxs = {}
    for rr, off in zip(runs_, cen):
        wx = xh - off / PPM; tgt = tgtA if off > 0 else tgtB; dxs['A' if off > 0 else 'B'] = tgt - wx
    info['nudge_m'] = {k: float(v) for k, v in dxs.items()}
    for r_ in rows:
        h = hh[r_]; w = float(np.clip((taper_h - h) / (taper_h - base_h), 0, 1)) if h > base_h else 1.0
        cols = np.where(a[r_, :, 3] > 128)[0]
        if not len(cols): continue
        # horn side assignment per column: image-right of the back midline = A, left = B
        for cx in cols:
            off = cx - mid_back; k = 'A' if off > 0 else 'B'
            if k not in dxs: continue
            xw = xh - off / PPM + dxs[k] * w
            xo = int(round(ax + xw * PPM))
            if 0 <= xo < canvas_w:
                out[r_, xo, :3] = a[r_, cx, :3]; out[r_, xo, 3] = 255; cls[r_, xo] = 2
    k = np.ones((3, 3), np.uint8); al = (out[..., 3] > 0).astype(np.uint8); cl = cv2.morphologyEx(al, cv2.MORPH_CLOSE, k)
    add = (cl > 0) & (al == 0)
    dil = cv2.dilate(out[..., :3], k); out[add, :3] = dil[add]; out[add, 3] = 255; cls[add] = 2
    return out, cls, info
