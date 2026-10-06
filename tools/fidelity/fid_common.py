"""Shared constants/helpers for the Aruun fidelity tools. Frame: 4096 px tall, ground row 4000, 1626.667 px/m (2.40 m = rows 96..4000)."""
import json, os
import numpy as np, cv2

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PACK = os.path.join(ROOT, 'design/reference_packs/aruun')
META = json.load(open(os.path.join(PACK, 'metadata.json')))
PPM = META['px_per_m']            # 1626.667
GROUND = META['ground_y']         # 4000
H_M = META['height_m']            # 2.40
LM = META['landmarks_m']          # canonical heights (m)
VIEWS = ['front', 'side', 'back']
QUANT_VIEWS = ['side', 'back']    # front is a 3/4 pose: qualitative only
HALO_PX = 3                       # +-px edge uncertainty from the jagged black halo of the upscaled side/back cuts

def view_info(v):
    return META['views'][v]

def row_of(h_m):  # height in metres -> pixel row (float)
    return GROUND - h_m * PPM

def h_of(row):
    return (GROUND - row) / PPM

def load_ref_alpha(v):
    im = cv2.imread(os.path.join(PACK, view_info(v)['file']), cv2.IMREAD_UNCHANGED)
    return im

def clean_mask(alpha, min_area=300):
    """alpha(uint8) -> boolean mask: threshold 128, drop specks, close 1-px pinholes of the upscaler. Outline halo is NOT removed (error bar HALO_PX)."""
    m = (alpha >= 128).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
    keep = np.zeros(n, bool); keep[1:] = st[1:, cv2.CC_STAT_AREA] >= min_area
    m = keep[lab].astype(np.uint8)
    return m.astype(bool)

def band_rows(h0, h1):
    """rows (int) covering heights h0..h1 metres, clipped"""
    r0 = int(round(row_of(h1))); r1 = int(round(row_of(h0)))
    return max(r0, 0), min(r1, 4095)

def band_stats(mask, h0, h1, col_lo=None, col_hi=None):
    """Statistics of mask inside the height band (and optional column window). All px; callers convert."""
    r0, r1 = band_rows(h0, h1)
    sub = mask[r0:r1 + 1]
    if col_lo is not None or col_hi is not None:
        lo = 0 if col_lo is None else int(col_lo); hi = sub.shape[1] if col_hi is None else int(col_hi)
        sub = sub[:, lo:hi]; off = lo
    else:
        off = 0
    cols = np.where(sub.any(0))[0]
    if len(cols) == 0:
        return dict(empty=True, xmin=None, xmax=None, outer_w=0.0, solid_w=0.0, rows=(r0, r1))
    rs = np.where(sub.any(1))[0]
    per = sub.sum(1).astype(float)
    outer = []
    for row in sub:
        c = np.where(row)[0]
        outer.append(c[-1] - c[0] + 1 if len(c) else 0)
    return dict(empty=False, xmin=float(cols[0] + off), xmax=float(cols[-1] + off), outer_w=float(np.mean(outer)),
                outer_w_max=float(np.max(outer)), solid_w=float(per.mean()), solid_w_max=float(per.max()),
                top_row=float(rs[0] + r0), bottom_row=float(rs[-1] + r0), rows=(r0, r1))

def width_profile(mask, nslice=100):
    """100 equal slices of the 2.40 m height (slice 0 = top). Returns list of dict (heights in normalized 0..1 where 1=top of horn)."""
    out = []
    for i in range(nslice):
        hh1 = H_M * (1 - i / nslice); hh0 = H_M * (1 - (i + 1) / nslice)
        s = band_stats(mask, hh0, hh1)
        out.append(dict(slice=i, h_norm_top=1 - i / nslice, h_norm_bot=1 - (i + 1) / nslice, h_m_top=hh1, h_m_bot=hh0,
                        xmin=s['xmin'], xmax=s['xmax'], outer_w_px=s['outer_w'], solid_w_px=s['solid_w']))
    return out

# Row bands (metres of height) used by BOTH the spec and compare.py. Derived from metadata landmarks.
BANDS = {
    'horns':     (LM['crown'] + 0.013, LM['top']),
    'head':      (LM['chin'], LM['crown']),
    'snout':     (LM['chin'], LM['eyes'] + 0.01),
    'neck':      (LM['neck'], LM['chin']),
    'neck_top':  (LM['chin'] - 0.05, LM['chin']),
    'neck_mid':  ((LM['chin'] + LM['neck']) / 2 - 0.025, (LM['chin'] + LM['neck']) / 2 + 0.025),
    'neck_base': (LM['neck'], LM['neck'] + 0.05),
    'shoulders': (LM['shoulder'] - 0.04, LM['shoulder'] + 0.04),
    'torso':     (LM['crotch'], LM['neck']),
    'waist':     (LM['waist'] - 0.04, LM['waist'] + 0.04),
    'pelvis':    (LM['crotch'], LM['crotch'] + 0.10),
    'arm':       (LM['wrist'] - 0.25, LM['shoulder']),
    'hand':      (0.70, LM['wrist'] + 0.05),
    'thigh':     (LM['knee'], LM['crotch']),
    'shin':      (LM['ankle'], LM['knee']),
    'foot':      (0.0, LM['ankle']),
}
