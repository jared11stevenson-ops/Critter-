#!/usr/bin/env python3
"""Extract clean reference silhouette masks, 100-slice width profiles, landmarks, gaps (negative spaces), horn/head/neck dims.
usage: python3 tools/fidelity/extract_ref_silhouettes.py [--out DIR]
Front (3/4 pose, NOT orthographic) is extracted for qualitative use only; quantitative checks use side + back.
All px are in the 4096-tall reference frames; metres = px/1626.667, heights from ground row 4000, x relative to the view's axis_x_px."""
import sys, os, json, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fid_common import *

def m_x(v, px): return (px - view_info(v)['axis_x_px']) / PPM   # +x = screen right
def m_h(row): return h_of(row)

def edge_at(mask, h, side):
    r = int(round(row_of(h))); c = np.where(mask[r])[0]
    if len(c) == 0: return None
    return float(c[0] if side == 'L' else c[-1])

def gaps(mask, v):
    """Negative spaces: background enclosed between silhouette runs of the same row (arm/torso, legs, horns, cloak) as labelled regions."""
    H, W = mask.shape
    filled = np.zeros_like(mask)
    for r in range(H):
        c = np.where(mask[r])[0]
        if len(c): filled[r, c[0]:c[-1] + 1] = True
    g = (filled & ~mask).astype(np.uint8)
    g = cv2.morphologyEx(g, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, cen = cv2.connectedComponentsWithStats(g, connectivity=4)
    out = []
    for i in range(1, n):
        a = st[i, cv2.CC_STAT_AREA]
        if a < 1500: continue
        x, y, w, h = [int(st[i, k]) for k in (cv2.CC_STAT_LEFT, cv2.CC_STAT_TOP, cv2.CC_STAT_WIDTH, cv2.CC_STAT_HEIGHT)]
        top_h, bot_h = m_h(y), m_h(y + h)
        enclosed = not (x == 0 or y == 0)
        ys, xs = np.where(lab[y:y + h, x:x + w] == i)
        cnt = cv2.findContours((lab[y:y + h, x:x + w] == i).astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[0]
        poly = cv2.approxPolyDP(max(cnt, key=cv2.contourArea), 6, True)[:, 0, :] + [x, y]
        mid = (top_h + bot_h) / 2
        name = ('above_crown_horn_gap' if bot_h > LM['crown'] - .02 else
                'neck_head_notch' if mid > LM['neck'] else
                'arm_torso_gap' if mid > LM['crotch'] + .1 and mid > LM['wrist'] - .3 else
                'leg_gap' if mid < LM['crotch'] + .12 else 'torso_side_gap')
        out.append(dict(name=name, area_px=int(a), area_m2=float(a / PPM**2), bbox_px=[x, y, w, h],
                        h_top_m=top_h, h_bot_m=bot_h, x_range_m=[m_x(v, x), m_x(v, x + w)], centroid_px=[float(cen[i][0]), float(cen[i][1])],
                        polygon_px=poly.tolist()))
    return sorted(out, key=lambda d: -d['area_px'])

def horn_components(mask, v, cut=0.14, split_x=None):
    """Horns = silhouette above crown+cut. Side/front: connected components. Back: horns join at the crown plate and arch over, so split at split_x
    (head centre column; default = centre of the head band). Returns dicts sorted by image-x (A/B naming is done in the spec: back image-right = A, image-left = B)."""
    r0, r1 = band_rows(LM['crown'] + cut, LM['top'])
    sub = mask[r0:r1 + 1].copy()
    parts = []
    if v == 'back':
        if split_x is None:
            hs = band_stats(mask, LM['chin'], LM['crown']); split_x = (hs['xmin'] + hs['xmax']) / 2
        for lo, hi in ((0, int(split_x)), (int(split_x), sub.shape[1])):
            q = np.zeros_like(sub); q[:, lo:hi] = sub[:, lo:hi]; parts.append(q)
    else:
        n, lab, st, _ = cv2.connectedComponentsWithStats(sub.astype(np.uint8), connectivity=8)
        parts = [lab == i for i in range(1, n) if st[i, cv2.CC_STAT_AREA] >= 400]
    comps = []
    for q in parts:
        ys, xs = np.where(q)
        if len(xs) < 400: continue
        tip = int(np.argmin(ys)); x0, x1 = int(xs.min()), int(xs.max())
        comps.append(dict(x_px=[x0, x1], top_row=float(ys.min() + r0), top_h_m=m_h(ys.min() + r0), tip_x_px=float(xs[tip]),
                          span_m=float((x1 - x0 + 1) / PPM), x_range_m=[m_x(v, x0), m_x(v, x1)], area_px=int(len(xs)),
                          tip_x_m=m_x(v, float(xs[tip])), outer_extreme_x_px=float(x0 if v == 'back' and q[:, :int(split_x)].any() and x0 < split_x - 1 and False else x0)))
    comps.sort(key=lambda c: c['x_px'][0])
    return comps

def analyse(v, mask):
    I = view_info(v); ax = I['axis_x_px']
    d = dict(view=v, orthographic=I['orthographic'], axis_x_px=ax, width_px=mask.shape[1],
             edge_err_px=HALO_PX, edge_err_m=HALO_PX / PPM)
    d['top_row'] = float(np.where(mask.any(1))[0][0]); d['bottom_row'] = float(np.where(mask.any(1))[0][-1])
    d['touches_canvas_edge'] = dict(left=bool(mask[:, 0].any()), right=bool(mask[:, -1].any()),
                                    left_rows_h_m=[m_h(r) for r in (np.where(mask[:, 0])[0][[0, -1]] if mask[:, 0].any() else [])],
                                    right_rows_h_m=[m_h(r) for r in (np.where(mask[:, -1])[0][[0, -1]] if mask[:, -1].any() else [])])
    bands = {}
    for k, (h0, h1) in BANDS.items():
        s = band_stats(mask, h0, h1)
        if s['empty']: continue
        bands[k] = dict(h_m=[h0, h1], xmin_px=s['xmin'], xmax_px=s['xmax'], xmin_m=m_x(v, s['xmin']), xmax_m=m_x(v, s['xmax']),
                        outer_w_m=s['outer_w'] / PPM, outer_w_max_m=s['outer_w_max'] / PPM, solid_w_m=s['solid_w'] / PPM,
                        extent_m=(s['xmax'] - s['xmin'] + 1) / PPM, top_h_m=m_h(s['top_row']), bottom_h_m=m_h(s['bottom_row']))
    d['bands'] = bands
    # per-landmark rows: left/right edge px + m
    lms = {}
    for k, h in LM.items():
        if k in ('ground',): continue
        L, R = edge_at(mask, min(h, 2.3995) if k != 'top' else 2.39, 'L'), edge_at(mask, min(h, 2.3995) if k != 'top' else 2.39, 'R')
        lms[k] = dict(h_m=h, row_px=row_of(h), left_px=L, right_px=R, left_m=None if L is None else m_x(v, L), right_m=None if R is None else m_x(v, R))
    d['landmark_rows'] = lms
    d['width_profile'] = [dict(p, xmin_m=None if p['xmin'] is None else m_x(v, p['xmin']), xmax_m=None if p['xmax'] is None else m_x(v, p['xmax']),
                               outer_w_m=p['outer_w_px'] / PPM, solid_w_m=p['solid_w_px'] / PPM,
                               centre_offset_m=None if p['xmin'] is None else m_x(v, (p['xmin'] + p['xmax']) / 2)) for p in width_profile(mask)]
    d['horns'] = horn_components(mask, v)
    d['gaps'] = gaps(mask, v)
    return d

def special_points(v, mask):
    """Extremal silhouette points (px) used as landmarks."""
    pts = {}
    def ext(name, h0, h1, kind, cols=None):
        r0, r1 = band_rows(h0, h1); sub = mask[r0:r1 + 1]
        if cols: sub = sub.copy(); sub[:, :cols[0]] = False; sub[:, cols[1]:] = False
        ys, xs = np.where(sub)
        if len(xs) == 0: return
        i = {'maxx': np.argmax(xs), 'minx': np.argmin(xs), 'miny': np.argmin(ys), 'maxy': np.argmax(ys)}[kind]
        pts[name] = dict(x_px=float(xs[i]), y_px=float(ys[i] + r0), x_m=m_x(v, xs[i]), h_m=m_h(ys[i] + r0))
    ext('highest_point', LM['top'] - .01, LM['top'], 'miny') if False else None
    ys, xs = np.where(mask); i = np.argmin(ys); pts['highest_point'] = dict(x_px=float(xs[i]), y_px=float(ys[i]), x_m=m_x(v, xs[i]), h_m=m_h(ys[i]))
    ext('head_front_extreme', LM['chin'], LM['crown'], 'maxx'); ext('head_back_extreme', LM['chin'], LM['crown'], 'minx')
    ext('chest_front_extreme', LM['waist'], LM['neck'] - .1, 'maxx'); ext('back_extreme', LM['waist'], LM['neck'] - .1, 'minx')
    ext('toe_extreme', 0, LM['ankle'], 'maxx'); ext('heel_extreme', 0, LM['ankle'], 'minx')
    ext('knee_front', LM['knee'] - .1, LM['knee'] + .1, 'maxx'); ext('knee_back', LM['knee'] - .1, LM['knee'] + .1, 'minx')
    return pts

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--out', default=os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/ref_extract'))
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    allv = {}
    for v in VIEWS:
        im = load_ref_alpha(v); mask = clean_mask(im[..., 3])
        cv2.imwrite(os.path.join(a.out, f'mask_{v}.png'), mask.astype(np.uint8) * 255)
        d = analyse(v, mask); d['special_points'] = special_points(v, mask)
        d['quantitative'] = v in QUANT_VIEWS
        allv[v] = d
    # side-view head details
    s = cv2.imread(os.path.join(a.out, 'mask_side.png'), 0) > 0
    eye_x = 0.57 * s.shape[1]            # parts.json eye marker (fraction of width) - approximate
    sp = allv['side']['special_points']
    hd = dict(eye_x_px=eye_x, snout_tip_px=sp['head_front_extreme']['x_px'], snout_len_from_eye_m=(sp['head_front_extreme']['x_px'] - eye_x) / PPM,
              head_length_m=(sp['head_front_extreme']['x_px'] - sp['head_back_extreme']['x_px'] + 1) / PPM)
    prof = []
    for t in np.linspace(0, 1, 6):
        c = int(eye_x + t * (sp['head_front_extreme']['x_px'] - eye_x - 2)); r0, r1 = band_rows(LM['chin'] - .02, LM['crown'])
        rr = np.where(s[r0:r1 + 1, c])[0]
        prof.append(dict(col_px=c, thickness_m=0 if len(rr) == 0 else float((rr[-1] - rr[0] + 1) / PPM), top_h_m=None if len(rr) == 0 else m_h(rr[0] + r0), bot_h_m=None if len(rr) == 0 else m_h(rr[-1] + r0)))
    hd['snout_thickness_profile'] = prof
    allv['side']['head_detail'] = hd
    json.dump(allv, open(os.path.join(a.out, 'ref_measurements.json'), 'w'), indent=1)
    with open(os.path.join(a.out, 'width_profiles.csv'), 'w') as f:
        f.write('view,slice,h_norm_top,h_norm_bot,h_m_top,h_m_bot,xmin_m,xmax_m,outer_w_m,solid_w_m,centre_offset_m\n')
        for v in VIEWS:
            for p in allv[v]['width_profile']:
                f.write(','.join(str(x) if x is not None else '' for x in [v, p['slice'], p['h_norm_top'], p['h_norm_bot'], p['h_m_top'], p['h_m_bot'], p['xmin_m'], p['xmax_m'], p['outer_w_m'], p['solid_w_m'], p['centre_offset_m']]) + '\n')
    print('wrote', a.out)
    for v in VIEWS: print(v, 'horns', [(round(h['top_h_m'], 3), round(h['span_m'], 3)) for h in allv[v]['horns']], 'gaps', [(g['name'], round(g['area_m2'], 3)) for g in allv[v]['gaps'][:6]], 'edge', allv[v]['touches_canvas_edge']['left'], allv[v]['touches_canvas_edge']['right'])
if __name__ == '__main__': main()
