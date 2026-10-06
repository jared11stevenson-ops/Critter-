#!/usr/bin/env python3
"""Assemble the v2 FRONT ortho: body (v2_front) + face tile head (v2_head) + projected horns, then palette-quantise + outline."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
import v2_front, v2_head
from scipy.ndimage import binary_dilation

def palette_bgr():
    p = json.load(open(os.path.join(ROOT, 'design/model_sheets/aruun/palette.json'))); cols = []
    for k, v in p.items():
        if isinstance(v, dict) and 'median' in v:
            cols.append(v['median']); cols += [c[0] for c in v['clusters']]
        elif isinstance(v, list): cols += v
    cols = sorted(set(c.lower() for c in cols if isinstance(c, str) and c.startswith('#')))
    return np.array([[int(c[5:7], 16), int(c[3:5], 16), int(c[1:3], 16)] for c in cols], np.uint8), cols

def quantise(rgba, tol=14.0):
    """snap each pixel to the nearest sheet-palette colour when within dE(Lab)<tol; otherwise keep the (original) colour"""
    pal, _ = palette_bgr(); lab_p = cv2.cvtColor(pal[None], cv2.COLOR_BGR2LAB)[0].astype(np.float32)
    m = rgba[..., 3] > 0; px = rgba[m][:, :3]; lab = cv2.cvtColor(px[None], cv2.COLOR_BGR2LAB)[0].astype(np.float32)
    # lab uint8 scale: L*255/100 ; approximate dE by scaling L back
    sc = np.array([100 / 255., 1, 1], np.float32)
    best = np.zeros(len(lab), np.int32); bd = np.full(len(lab), 1e9, np.float32)
    for i, pl in enumerate(lab_p):
        d = np.linalg.norm((lab - pl) * sc, axis=1); u = d < bd; bd[u] = d[u]; best[u] = i
    px2 = np.where((bd < tol)[:, None], pal[best], px); out = rgba.copy(); out[m, :3] = px2
    return out, float((bd < tol).mean())

def outline(rgba, cls, px=4):
    a = rgba[..., 3] > 0; er = cv2.erode(a.astype(np.uint8), np.ones((2 * px + 1, 2 * px + 1), np.uint8)) > 0
    ring = a & ~er; out = rgba.copy(); out[ring, :3] = v2_complete_INK; return out

v2_complete_INK = np.array([22, 16, 20], np.uint8)

def build_front():
    sheet = load_rgba(os.path.join(ORTHO, 'aruun_front_4096.png'))
    body, cls, grp, P, hid, stats, names = v2_front.build(sheet)
    W = v2_front.W; AX = v2_front.AX
    tile, tinfo = v2_head.place_tile('front_straighton', W, AX, h_cut=None)
    # tile horn stub tops (tile px) -> world x
    s = 1.0; sa = v2_head.X_HEAD + (390 - 765) / 4000.0; sb = v2_head.X_HEAD + (1100 - 765) / 4000.0
    horn, hcls, hinfo = v2_head.horn_layer(W, AX, sa, sb)
    out = body.copy(); ccls = cls.copy()
    # drop body pixels of head groups (they are empty anyway). horns first, tile on top
    hm = horn[..., 3] > 0; out[hm] = horn[hm]; ccls[hm] = hcls[hm]
    names = info_names = v2_front.GROUPS; gl = list(v2_front.GROUPS)
    allow = np.isin(grp, [-1, gl.index('neck'), gl.index('neckbase')])            # the face tile goes UNDER trunk/limbs, over neck/hood-hump/empty
    tm = (tile[..., 3] > 0) & allow; out[tm] = tile[tm]; ccls[tm] = 1
    out[tm & (grp == gl.index('neckbase'))] = tile[tm & (grp == gl.index('neckbase'))]
    return out, ccls, dict(stats=stats, tile=tinfo, horns=hinfo, stub_targets_world_x=[sa, sb])

def finish_front():
    raw, cls, info = build_front()
    q, frac = quantise(raw); q = outline(q, cls, 3)
    meta = dict(view='front', camera='orthographic, camera in front looking -Z (yaw 0); image-right = his LEFT (red pauldron side); arms hanging (reference pose); head facing forward',
                axis_x_px=v2_front.AX, x_offset_px=0,
                sources=['proxy: design/model_sheets/aruun/fidelity/proxy/proxy.glb (geometry only: part ids, visibility, row extents)',
                         'silhouette below the neck: design/reference_packs/aruun/ortho/aruun_back_4096.png mirrored (an ortho front silhouette is the mirror of the back one)',
                         'body paint: design/reference_packs/aruun/ortho/aruun_front_4096.png (3/4 front cut, perspective pose) through hand-registered per-part row warps (v2_front.py GROUPS)',
                         'head/neck: design/reference_gen/aruun/head/aruun_head_front_straighton.png (x4 upscale of the CALM tile, original pixels), registered by eye/chin landmark rows',
                         'horns: back cut mirrored (aruun_back_4096.png), bases nudged to the tile horn-stub tops'],
                regions_by_source=info['stats'], head=dict(tile=info['tile'], horns=info['horns'], stub_targets_world_x=info['stub_targets_world_x']),
                palette_quantisation=dict(palette='design/model_sheets/aruun/palette.json (medians+clusters+dots)', dE_tol=14, fraction_snapped=frac),
                outline='4 px ink ring (#14101a) on the silhouette only; interior lines are the sheet\'s own',
                unknown_policy='RED = pixels where the sheet has no paint at the mapped place (gap between sheet parts) and the nearest opaque sheet pixel (>10 px away) was copied; no new features drawn',
                notes=['green criterion: sheet pixel mapped with local x and y scale both within 0.8..1.25 (mild warp of original paint) - not a claim that the 3/4 pose equals a true front',
                       'every body group is warped from a 3/4 perspective pose: treat as LAYOUT reference, not as measured front art',
                       'pauldron: proxy+back silhouette give only a narrow outer slice; the sheet shows a large round red disc facing the viewer: the disc size in a true front is UNKNOWN',
                       'open creator question: pauldrons on both shoulders? his right shoulder carries the mantle here (front+back agree)'])
    pc = write_set('aruun_v2_front_ortho_4096', q, cls, meta)
    return q, cls, pc

if __name__ == '__main__':
    q, cls, pc = finish_front(); print('front', pc)
