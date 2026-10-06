#!/usr/bin/env python3
"""Compare rendered model views (render_model_views.py output) against the reference silhouettes. Deterministic, CPU, ~5 s.
usage: python3 tools/fidelity/compare.py --render-dir DIR --out DIR [--views side back] [--align best|axis]
Quantitative views = side, back (front reference is a 3/4 pose: add --views front only for the qualitative overlay; its numbers are marked non-ortho).
Alignment: vertical = shared ground row 4000 and px/m (landmark rows identical by construction, NO height rescale); horizontal = the model origin is arbitrary, so
align='best' shifts the render by the dx (px, searched +-PAD) maximising silhouette IoU (nominal IoU at dx=0 also reported); width/height numbers are shift-invariant.
Sign convention: error = MODEL - REFERENCE (positive = model larger / further screen-right / higher). Output: metrics.json, REPORT.md, overlay_{v}.png (RED = model only,
BLUE = reference only, light grey = both), sidebyside_{v}.png (reference | model clay | overlay), width_error_{v}.csv."""
import sys, os, json, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fid_common as fc
from fid_common import *
import extract_ref_silhouettes as ex

PAD = 1200
EDGE_ERR_M = 2 * HALO_PX / PPM  # each of two edges +-3 px

def load_ref_mask(v):
    return clean_mask(load_ref_alpha(v)[..., 3])

def iou(a, b):
    u = np.logical_or(a, b).sum(); return float(np.logical_and(a, b).sum() / u) if u else 0.0

def shift_x(m, dx):
    out = np.zeros_like(m)
    if dx >= 0: out[:, dx:] = m[:, :m.shape[1] - dx] if dx else m
    else: out[:, :dx] = m[:, -dx:]
    return out

def best_shift(ref_pad, mod_pad, rng=PAD):
    sc = 4; r = ref_pad[::sc, ::sc]; m = mod_pad[::sc, ::sc]
    best = max(range(-rng // sc, rng // sc + 1), key=lambda k: (iou(r, shift_x(m, k)), -abs(k)))
    cands = range(best * sc - sc, best * sc + sc + 1)
    return max(cands, key=lambda d: (iou(ref_pad, shift_x(mod_pad, d)), -abs(d)))

def analyse_pad(v, mask_pad):
    ex.PAD_X = PAD
    d = ex.analyse(v, mask_pad); d['special_points'] = ex.special_points(v, mask_pad); d['arm_points'] = ex.arm_points(v, mask_pad)
    ex.PAD_X = 0
    return d

def run_width(mask, h0, h1, col):
    """mean width (m) of the contiguous run containing (else nearest to) column `col`, over the rows of the band: isolates a neck/limb from fringes, skirt strips, horns."""
    r0, r1 = band_rows(h0, h1); ws = []
    for r in range(r0, r1 + 1, 2):
        c = np.where(mask[r])[0]
        if len(c) == 0: continue
        br = np.where(np.diff(c) > 1)[0]; starts = np.r_[c[0], c[br + 1]]; ends = np.r_[c[br], c[-1]]
        k = [i for i in range(len(starts)) if starts[i] <= col <= ends[i]]
        i = k[0] if k else int(np.argmin(np.minimum(abs(starts - col), abs(ends - col))))
        ws.append(ends[i] - starts[i] + 1)
    return float(np.mean(ws) / PPM) if ws else None

def region_table(v, R, M, refm=None, modm=None):
    """list of dict(name, ref, model, err, view, unit m, rankable)"""
    rows = []
    def add(name, r, m, rankable=True, note=''):
        if r is None or m is None: return
        rows.append(dict(view=v, name=name, ref_m=float(r), model_m=float(m), err_m=float(m - r), err_pct=float((m - r) / r * 100) if abs(r) > 1e-6 else None,
                         rankable=rankable, note=note))
    for b in BANDS:
        if b not in R['bands'] or b not in M['bands']: continue
        rb, mb = R['bands'][b], M['bands'][b]
        add(f'{b}.outer_width', rb['outer_w_m'], mb['outer_w_m'], rankable=b not in ('arm', 'hand', 'horns', 'head', 'snout') and not b.startswith('neck') and not (v == 'side' and b in ('thigh', 'pelvis', 'torso')))
        if b.startswith('neck') or b in ('head', 'snout'):
            h0, h1 = BANDS[b]; rr = band_rows(h0, h1); col = float(np.median(np.where(refm[rr[0]:rr[1] + 1])[1])) if b != 'snout' else None
            if col is not None:
                add(f'{b}.run_width (central run, fringe/skirt-free)', run_width(refm, h0, h1, col), run_width(modm, h0, h1, col), rankable=b.startswith('neck'))
        add(f'{b}.solid_width', rb['solid_w_m'], mb['solid_w_m'], rankable=False)
        add(f'{b}.extent', rb['extent_m'], mb['extent_m'], rankable=False)
    # head / snout / horns (named regions)
    rs, ms = R['special_points'], M['special_points']
    if v == 'side':
        eye = R['head_detail']['eye_x_px'] if 'head_detail' in R else 0.57 * 947
        # ref eye column in padded+aligned frame: eye_x + PAD
        tip_r = rs['head_front_extreme']['x_px']; tip_m = ms['head_front_extreme']['x_px']
        add('snout.length_from_eye (tip - ref eye col; model eye col assumed = ref eye col after alignment)', (tip_r - (eye + PAD)) / PPM, (tip_m - (eye + PAD)) / PPM,
            note='eye column is the reference marker; model eye not located')
        add('head.length (nape..snout tip)', (rs['head_front_extreme']['x_px'] - rs['head_back_extreme']['x_px'] + 1) / PPM,
            (ms['head_front_extreme']['x_px'] - ms['head_back_extreme']['x_px'] + 1) / PPM)
        add('foot.length (heel..toe)', (rs['toe_extreme']['x_px'] - rs['heel_extreme']['x_px'] + 1) / PPM, (ms['toe_extreme']['x_px'] - ms['heel_extreme']['x_px'] + 1) / PPM)
        add('torso.chest_to_back_depth', (rs['chest_front_extreme']['x_px'] - rs['back_extreme']['x_px'] + 1) / PPM, (ms['chest_front_extreme']['x_px'] - ms['back_extreme']['x_px'] + 1) / PPM)
        add('head.snout_tip_height', rs['head_front_extreme']['h_m'], ms['head_front_extreme']['h_m'], rankable=False)
    add('total_height (highest point)', rs['highest_point']['h_m'], ms['highest_point']['h_m'])
    for i, nm in enumerate(['hornX', 'hornY']):
        pass
    rh, mh = R['horns'], M['horns']
    if v == 'back' and len(rh) == 2 and len(mh) >= 1:
        # image-left horn = Horn B (thin/long), image-right = Horn A (thick/short)
        names = ['horn_B(image-left)', 'horn_A(image-right)']
        for k in range(min(2, len(mh))):
            add(names[k] + '.tip_height', rh[k]['top_h_m'], mh[k]['top_h_m']); add(names[k] + '.span', rh[k]['span_m'], mh[k]['span_m'])
        add('horns.total_spread (back, outer tip to outer tip)', (rh[-1]['x_px'][1] - rh[0]['x_px'][0] + 1) / PPM, (mh[-1]['x_px'][1] - mh[0]['x_px'][0] + 1) / PPM)
    if v == 'side' and len(rh) >= 1 and len(mh) >= 1:
        names = ['horn_A(rear/thick)', 'horn_B(front/long)']
        for k in range(min(len(rh), len(mh), 2)):
            add(names[k] + '.tip_height', rh[k]['top_h_m'], mh[k]['top_h_m']); add(names[k] + '.span', rh[k]['span_m'], mh[k]['span_m'])
        add('horns.total_depth_spread (side)', (max(h['x_px'][1] for h in rh) - min(h['x_px'][0] for h in rh) + 1) / PPM, (max(h['x_px'][1] for h in mh) - min(h['x_px'][0] for h in mh) + 1) / PPM)
    if v == 'back':
        ra, ma = R['arm_points'], M['arm_points']
        if ra and ma:
            add('hand.bottom_height (arm length proxy)', ra['hand_bottom']['h_m'], ma['hand_bottom']['h_m'], rankable=False, note='A-pose vs hanging arm: not like-for-like')
            add('arm.arm_length_shoulder_to_hand (vertical)', LM['shoulder'] - ra['hand_bottom']['h_m'], LM['shoulder'] - ma['hand_bottom']['h_m'], rankable=False)
    # silhouette landmarks vertical positions not measurable on model without a skeleton -> skip
    return rows

def width_err(v, R, M):
    out = []
    for r, m in zip(R['width_profile'], M['width_profile']):
        d = dict(slice=r['slice'], h_norm_top=r['h_norm_top'], h_m_top=r['h_m_top'], h_m_bot=r['h_m_bot'], ref_outer_w_m=r['outer_w_m'], model_outer_w_m=m['outer_w_m'],
                 err_outer_m=m['outer_w_m'] - r['outer_w_m'], ref_solid_w_m=r['solid_w_m'], model_solid_w_m=m['solid_w_m'], err_solid_m=m['solid_w_m'] - r['solid_w_m'],
                 err_xmin_m=None if (r['xmin_m'] is None or m['xmin_m'] is None) else m['xmin_m'] - r['xmin_m'],
                 err_xmax_m=None if (r['xmax_m'] is None or m['xmax_m'] is None) else m['xmax_m'] - r['xmax_m'])
        out.append(d)
    return out

def overlay(ref, mod, dx_note=''):
    """BGR image: both = light grey, model-only = RED, reference-only = BLUE, white background."""
    img = np.full(ref.shape + (3,), 255, np.uint8)
    both = ref & mod; img[both] = (200, 200, 200); img[mod & ~ref] = (40, 40, 230); img[ref & ~mod] = (230, 110, 30)
    return img

def crop_window(ref, mod, margin=60):
    cols = np.where((ref | mod).any(0))[0]; x0, x1 = max(cols[0] - margin, 0), min(cols[-1] + margin, ref.shape[1] - 1)
    return x0, x1 + 1

def label(img, text, scale=1.0):
    cv2.putText(img, text, (10, int(34 * scale)), cv2.FONT_HERSHEY_SIMPLEX, 0.9 * scale, (20, 20, 20), 2, cv2.LINE_AA); return img

def hguides(img, x0, scale):
    for k, h in LM.items():
        y = int(row_of(h) * scale)
        if 0 <= y < img.shape[0]:
            cv2.line(img, (0, y), (img.shape[1] - 1, y), (150, 150, 150), 1)
            cv2.putText(img, f'{k} {h:.2f}', (4, y - 3), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (90, 90, 90), 1, cv2.LINE_AA)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--render-dir', required=True); ap.add_argument('--out', required=True)
    ap.add_argument('--views', nargs='+', default=['side', 'back']); ap.add_argument('--align', default='best', choices=['best', 'axis'])
    ap.add_argument('--ref-extract-dir', default=None)
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    info = json.load(open(os.path.join(a.render_dir, 'render_info.json')))
    res = {'render_info': info, 'views': {}, 'conventions': 'err = model - reference; masks alpha>=128; edge uncertainty +-%d px (%.4f m) per edge' % (HALO_PX, HALO_PX / PPM)}
    all_rows = []
    for v in a.views:
        W = view_info(v)['width_px']
        ref = load_ref_mask(v)
        mod_pad = cv2.imread(os.path.join(a.render_dir, f'sil_{v}.png'), 0) > 0          # (4096, W+2*PAD)
        ref_pad = np.zeros_like(mod_pad); ref_pad[:, PAD:PAD + W] = ref
        dx = 0 if a.align == 'axis' else best_shift(ref_pad, mod_pad)
        mod_al = shift_x(mod_pad, dx)
        R = analyse_pad(v, ref_pad); M = analyse_pad(v, mod_al)
        if v == 'side':
            R['head_detail'] = json.load(open(os.path.join(a.ref_extract_dir or os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/ref_extract'), 'ref_measurements.json')))['side']['head_detail']
        rows = region_table(v, R, M, ref_pad, mod_al); werr = width_err(v, R, M)
        in_win = mod_al[:, PAD:PAD + W]
        v_iou = iou(ref_pad, mod_al); nominal = iou(ref_pad, mod_pad)
        sw = [abs(w['err_outer_m']) / max(w['ref_outer_w_m'], 0.02) for w in werr if w['ref_outer_w_m'] > 0]
        res['views'][v] = dict(orthographic=view_info(v)['orthographic'], quantitative=v in QUANT_VIEWS, iou=v_iou, iou_nominal_dx0=nominal, align_dx_px=int(dx), align_dx_m=dx / PPM,
                               model_area_over_ref_area=float(mod_al.sum() / ref_pad.sum()), mean_abs_rel_width_err=float(np.mean(sw)),
                               mean_signed_outer_width_err_m=float(np.mean([w['err_outer_m'] for w in werr])), regions=rows, width_error_profile=werr,
                               model_horns=M['horns'], ref_horns=R['horns'], model_gaps=[{k: g[k] for k in ('name', 'area_m2', 'h_top_m', 'h_bot_m', 'x_range_m')} for g in M['gaps'][:8]],
                               ref_gaps=[{k: g[k] for k in ('name', 'area_m2', 'h_top_m', 'h_bot_m', 'x_range_m')} for g in R['gaps'][:8]])
        all_rows += rows
        # images
        x0, x1 = crop_window(ref_pad, mod_al); ov = overlay(ref_pad, mod_al)[:, x0:x1]
        sc = 0.34; ovs = cv2.resize(ov, None, fx=sc, fy=sc, interpolation=cv2.INTER_AREA); hguides(ovs, x0, sc)
        label(ovs, f'{v} overlay: RED=model only  BLUE=reference only  IoU {v_iou:.3f}' + ('' if v in QUANT_VIEWS else '  (3/4 ref: qualitative)'), 0.6)
        cv2.imwrite(os.path.join(a.out, f'overlay_{v}.png'), ovs)
        full = cv2.resize(overlay(ref_pad, mod_al)[:, x0:x1], None, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA)
        cv2.imwrite(os.path.join(a.out, f'overlay_{v}_large.png'), full)
        refrgb = cv2.imread(os.path.join(PACK, view_info(v)['file']), cv2.IMREAD_UNCHANGED)
        al = refrgb[..., 3:4] / 255.; refv = (refrgb[..., :3] * al + 255 * (1 - al)).astype(np.uint8)
        refp = np.full((4096, ref_pad.shape[1], 3), 255, np.uint8); refp[:, PAD:PAD + W] = refv
        clay_p = cv2.imread(os.path.join(a.render_dir, f'clay_{v}.png'))
        if clay_p is not None:
            clay_al = shift_x(clay_p.transpose(2, 0, 1).copy().reshape(3, 4096, -1)[0] > -1, 0) if False else None
            M3 = np.float32([[1, 0, dx], [0, 1, 0]]); clay_al = cv2.warpAffine(clay_p, M3, (clay_p.shape[1], 4096), flags=cv2.INTER_NEAREST, borderValue=(214, 214, 214))
            panels = [refp[:, x0:x1], clay_al[:, x0:x1], overlay(ref_pad, mod_al)[:, x0:x1]]
        else:
            panels = [refp[:, x0:x1], overlay(ref_pad, mod_al)[:, x0:x1]]
        panels = [cv2.resize(p, None, fx=0.3, fy=0.3, interpolation=cv2.INTER_AREA) for p in panels]
        titles = ['REFERENCE', 'MODEL (clay, aligned dx=%d px)' % dx, 'DIFF red=model only / blue=ref only'][:len(panels)] if clay_p is not None else ['REFERENCE', 'DIFF']
        for p, t in zip(panels, titles): label(p, t, 0.55)
        cv2.imwrite(os.path.join(a.out, f'sidebyside_{v}.png'), np.hstack(panels))
        with open(os.path.join(a.out, f'width_error_{v}.csv'), 'w') as f:
            ks = list(werr[0].keys()); f.write(','.join(ks) + '\n')
            for w in werr: f.write(','.join('' if w[k] is None else (f'{w[k]:.5f}' if isinstance(w[k], float) else str(w[k])) for k in ks) + '\n')
    rank = sorted([r for r in all_rows if r['rankable'] and r['view'] in QUANT_VIEWS], key=lambda r: -abs(r['err_m']))
    res['top_deviations_by_abs_m'] = rank[:12]
    json.dump(res, open(os.path.join(a.out, 'metrics.json'), 'w'), indent=1)
    md = ['# Fidelity comparison (model - reference)', '', f"model: `{info['model']}`  forward {info['forward']}  render height {info['views'][a.views[0]]['height_m']:.3f} m (top {info['views'][a.views[0]]['top_m']:.3f}); mace islands dropped: {info.get('mace_faces_dropped')} faces", '',
          '| view | IoU (aligned) | IoU (dx=0) | align dx (m) | model/ref area | mean abs rel width err | mean signed width err (m) |', '|---|---|---|---|---|---|---|']
    for v, r in res['views'].items():
        md.append(f"| {v}{'' if r['quantitative'] else ' (3/4 ref, qualitative)'} | {r['iou']:.3f} | {r['iou_nominal_dx0']:.3f} | {r['align_dx_m']:+.3f} | {r['model_area_over_ref_area']:.2f} | {r['mean_abs_rel_width_err']:.3f} | {r['mean_signed_outer_width_err_m']:+.3f} |")
    for v, r in res['views'].items():
        md += ['', f'## {v} region errors (m; err = model - ref; edge uncertainty about +-{EDGE_ERR_M:.4f} m)', '', '| region | ref m | model m | err m | err % | rank? |', '|---|---|---|---|---|---|']
        for g in r['regions']:
            md.append(f"| {g['name']} | {g['ref_m']:.3f} | {g['model_m']:.3f} | {g['err_m']:+.3f} | {'' if g['err_pct'] is None else '%+.0f' % g['err_pct']} | {'y' if g['rankable'] else ''} |")
    md += ['', '## Largest deviations (rankable regions, side+back, by |err| in m)', '']
    for i, r in enumerate(rank[:8]): md.append(f"{i+1}. {r['view']} {r['name']}: ref {r['ref_m']:.3f} m, model {r['model_m']:.3f} m, err {r['err_m']:+.3f} m ({r['err_pct']:+.0f}%)" if r['err_pct'] is not None else f"{i+1}. {r['view']} {r['name']}: err {r['err_m']:+.3f}")
    open(os.path.join(a.out, 'REPORT.md'), 'w').write('\n'.join(md) + '\n')
    print('\n'.join(md[:12]))
if __name__ == '__main__': main()
