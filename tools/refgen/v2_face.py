#!/usr/bin/env python3
"""v2 (5): straight-on FACE views on the 4096-px canvas (same scale / ground row / landmark rows as ortho/). Head = the original CALM and RAGE expression tiles (Real-ESRGAN x4 of
the sheet pixels, no diffusion), placed on the eye/chin landmark rows. CALM gets the long horns from the mirrored back cut (YELLOW); RAGE is left as the tile (its horn stubs are cut by the tile top)."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
import v2_head
W, AX = 1400, 700
def feature_table(kind):
    base = {'eyes on the SIDES of the head (yellow, dark ring, cream/white glint)': 'original tile pixels (both expression tiles)',
            'red/orange crown plate between the horn bases': 'original tile pixels',
            'brow ridges / cream temple tines': 'original tile pixels',
            'nape/side fringe strands (olive-cream)': 'original tile pixels; the tile clips the right-hand strands with a hard vertical edge at tile col ~1300 (cut by the sheet crop, NOT design)',
            'horn bases in red crown plates': 'original tile stubs (cut flat by the tile top, rows < ~690-700 at 4000 px/m)'}
    if kind == 'calm':
        base.update({'snout / nostrils at the tip': 'PARTLY: the calm tile foreshortens the snout toward the camera (tan plates + dark slit); nostrils are not separately readable',
                     'white fang at mouth corner': 'NOT VISIBLE in the calm tile (mouth closed, hidden by the foreshortened snout); see the RAGE face for fangs',
                     'long lyre horns above the stubs': 'INFERRED (YELLOW): back cut mirrored, bases nudged to the stub tops; the front-facing surface of the horns is not drawn anywhere'})
    else:
        base.update({'snout / nostrils at the tip': 'original RAGE tile: dark nose triangle + upper lip; mouth open',
                     'white fang at mouth corner': 'original RAGE tile: cream fangs inside the open jaw (expression state, not the calm design)',
                     'long lyre horns above the stubs': 'NOT ADDED (tile only)'})
    return base
if __name__ == '__main__':
    for kind, tile in (('calm', 'front_straighton'), ('rage', 'rage_straighton')):
        t, tinfo = v2_head.place_tile(tile, W, AX, x_world=0.0)
        out = np.zeros_like(t); cls = np.zeros((4096, W), np.uint8)
        if kind == 'calm':
            sa = (390 - 765) / 4000.0; sb = (1100 - 765) / 4000.0
            horn, hc, hinfo = v2_head.horn_layer(W, AX, sa, sb, xh=0.0); hm = horn[..., 3] > 0; out[hm] = horn[hm]; cls[hm] = hc[hm]
        else: hinfo = None
        tm = t[..., 3] > 0; out[tm] = t[tm]; cls[tm] = 1
        # tile bottom is cut square by the tile bottom edge (row 2799 at 4000 px/m): that edge is a crop, not design
        ys = np.where(tm.any(1))[0]; cls[ys.max() - 6:ys.max() + 1][tm[ys.max() - 6:ys.max() + 1]] = 3
        o = out.copy(); a = o[..., 3] > 0; er = cv2.erode(a.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0; o[a & ~er, :3] = np.array([22, 16, 20], np.uint8)
        meta = dict(view=f'straight-on face ({kind})', camera='orthographic front; head facing forward as the tile shows (tile itself is a slightly down-looking bust, snout foreshortened)', axis_x_px=AX, x_offset_px=0,
                    sources=[f'design/reference_gen/aruun/head/aruun_head_{tile}.png (x4 upscale of the sheet {kind.upper()} expression tile, 4000 px/m, landmark rows eyes=1499 chin=1920 crown=1292)'] + (['design/reference_packs/aruun/ortho/aruun_back_4096.png (horns)'] if hinfo else []),
                    horns=hinfo, tile=tinfo, features=feature_table(kind), notes=['the face is a head-only canvas: body rows are empty by design', 'last 6 rows of the tile are RED = the tile crop edge'])
        print(kind, write_set(f'aruun_v2_face_{kind}_4096', o, cls, meta))
        # convenience zoom crop (not a separate design)
        y0, y1 = int(GROUND - 2.42 * PPM), int(GROUND - 1.66 * PPM)
        for suf, im in (('', o), ('_derivation', cv2.imread(os.path.join(OUT, f'aruun_v2_face_{kind}_4096_derivation.png')))):
            cv2.imwrite(os.path.join(OUT, f'aruun_v2_face_{kind}_zoom{suf}.png'), im[y0:y1, 150:1250])
