#!/usr/bin/env python3
"""Build design/model_sheets/aruun/fidelity/character_spec.json + CHARACTER_SPEC.md from the reference silhouettes (run extract_ref_silhouettes.py first).
usage: python3 tools/fidelity/make_spec.py"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fid_common import *
import compare as C

FID = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity'); EXT = os.path.join(FID, 'ref_extract')
R = json.load(open(os.path.join(EXT, 'ref_measurements.json')))
MS = {v: cv2.imread(os.path.join(EXT, f'mask_{v}.png'), 0) > 0 for v in VIEWS}
parts = json.load(open(os.path.join(PACK, 'parts.json')))
HEAD_H = LM['chin'] and (LM['crown'] - LM['chin'])   # 0.157
E1 = 3 / PPM          # one edge (halo) +- m
E2 = 2 * E1           # width = two edges
POSE = 0.02           # extra +- m for landmark-row definitions (rows are artist-read)

meas = {}
def M(key, val, view, err, note='', source='silhouette'):
    meas[key] = dict(m=round(float(val), 4), rel_height=round(float(val) / H_M, 4), rel_head=round(float(val) / HEAD_H, 3), err_m=round(float(err), 4), view=view, source=source, note=note)

b = {v: R[v]['bands'] for v in VIEWS}
# --- canonical (landmarks.json/proportions.json: artist rows, +-0.02)
M('total_height', 2.400, 'canon', 0.0, 'horn tip to sole; side/back silhouettes give 2.400 (rows 96..3999)', 'proportions.json')
M('body_height_to_crown', LM['crown'], 'canon', POSE, 'sole to crown', 'landmarks')
M('head_height_crown_to_chin', HEAD_H, 'canon', POSE, '13.5 heads tall to crown', 'landmarks')
M('neck_vertical_chin_to_base', LM['chin'] - LM['neck'], 'canon', POSE, 'vertical chin -> neck base. The 0.45 m in spec.md/ARTLOG is NOT supported (see centreline arc)', 'landmarks')
M('torso_length_neckbase_to_crotch', LM['neck'] - LM['crotch'], 'canon', POSE, '', 'landmarks')
M('upper_arm_shoulder_to_elbow_vertical', LM['shoulder'] - LM['elbow'], 'canon', POSE, 'vertical drop, arm hangs ~vertical in side/back', 'landmarks')
M('forearm_elbow_to_wrist_vertical', LM['elbow'] - LM['wrist'], 'canon', POSE + 0.02, 'wrist row is READ not measured', 'landmarks')
M('arm_shoulder_to_wrist_vertical', LM['shoulder'] - LM['wrist'], 'canon', POSE + 0.02, '', 'landmarks')
M('thigh_crotch_to_knee', LM['crotch'] - LM['knee'], 'canon', POSE, '', 'landmarks')
M('shin_knee_to_ankle', LM['knee'] - LM['ankle'], 'canon', POSE, '', 'landmarks')
M('ankle_height', LM['ankle'], 'canon', POSE, '', 'landmarks')
M('leg_crotch_to_ground', LM['crotch'], 'canon', POSE, '', 'landmarks')
# --- head
hd = R['side']['head_detail']
M('head_length_side_nape_to_snout_tip', hd['head_length_m'], 'side', E2 + 0.01, 'includes nape fringe + temple tines at back; snout tip is the far end; head carried forward, faces screen-right')
M('head_width_back_mean_outer', b['back']['head']['outer_w_m'], 'back', E2, 'mean width over crown..chin rows (back view; horns excluded)')
M('head_width_back_max_with_tines', b['back']['head']['outer_w_max_m'], 'back', E2, 'temple tines / nape fringe at widest row')
M('snout_length_from_eye', hd['snout_len_from_eye_m'], 'side', 0.02, 'eye marker x = parts.json 0.57*width (approx) to snout tip')
M('snout_tip_thickness_vertical_mid', [p for p in hd['snout_thickness_profile']][2]['thickness_m'], 'side', E2, 'vertical thickness of the muzzle at 40% from eye to tip; tapers to ~0.03 at 85% (hooked tip)')
M('snout_width_front', 0.12, 'generated front head', 0.03, 'NO original front view: from reference_gen head_front_straighton (upscaled/generated; low confidence)', 'generated')
M('head_width_front_with_tines', 0.28, 'generated front head', 0.03, 'generated; includes temple tines', 'generated')
# --- neck
def runw(v, bn):
    h0, h1 = BANDS[bn]; rr = band_rows(h0, h1); col = float(np.median(np.where(MS[v][rr[0]:rr[1] + 1])[1])); return C.run_width(MS[v], h0, h1, col)
for bn in ('neck_top', 'neck_mid', 'neck_base'):
    M(f'{bn}_width_back', runw('back', bn), 'back', E2, 'central run of the silhouette (contaminated by shoulder slope at neck_base)')
    M(f'{bn}_depth_side', runw('side', bn), 'side', E2, 'front-back depth of neck')
M('neck_centreline_arc_side', 0.245, 'side', 0.04, 'polyline of central-run centres chin->base; ~0.06 m forward lean over 0.198 m vertical', 'derived')
# --- trunk
M('shoulder_width_back_outer', b['back']['shoulders']['outer_w_m'], 'back', E2 + 0.01, 'pauldron + mantle to far shoulder edge; includes armour and cloak; arm outer edge touches the canvas edge (clipped?)')
M('shoulder_width_back_extent_max', b['back']['shoulders']['extent_m'], 'back', E2, 'extreme left..right over band 1.59-1.67 m')
M('chest_depth_side_shoulders', b['side']['shoulders']['outer_w_m'], 'side', E2 + 0.01, 'includes pauldron (rear) and chest wrap (front)')
M('torso_depth_side_chest_to_back', (R['side']['special_points']['chest_front_extreme']['x_px'] - R['side']['special_points']['back_extreme']['x_px'] + 1) / PPM, 'side', E2 + 0.02, 'max front minus min back over waist..neck-0.1; the back extreme is the pauldron/arm')
M('waist_width_back', b['back']['waist']['outer_w_m'], 'back', E2, 'incl. arms and cloak/skirt strips at band 1.20-1.28 m (arms hang beside the waist)')
M('waist_depth_side', b['side']['waist']['outer_w_m'], 'side', E2, '')
M('pelvis_width_back', b['back']['pelvis']['outer_w_m'], 'back', E2 + 0.01, 'crotch..+0.10 m; includes hanging strips on his side')
M('pelvis_depth_side', b['side']['pelvis']['outer_w_m'], 'side', E2, '')
# --- limbs
ap = R['back']['arm_points']['hand_bottom']
M('hand_bottom_height_back', ap['h_m'], 'back', E1 + 0.01, 'lowest silhouette row of the image-left arm (fist)')
M('arm_shoulder_to_hand_bottom', LM['shoulder'] - ap['h_m'], 'back', POSE + 0.01, 'vertical')
M('hand_length_wrist_to_fingertip_vertical', LM['wrist'] - ap['h_m'], 'back', POSE + 0.02, 'wrist row is READ; fist hangs closed')
M('hand_width_back_fist', 0.165, 'back', 0.01, 'image-left fist at 0.85-0.95 m, window col<300 (some arm included)', 'derived')
M('arm_outer_extent_back_left', abs(R['back']['arm_points']['arm_outer_left']['x_m']), 'back', 0.05, 'LOWER BOUND: silhouette touches canvas edge x=0 (clipped)')
M('thigh_width_back_outer', b['back']['thigh']['outer_w_m'], 'back', E2 + 0.02, 'mean over knee..crotch rows both thighs + gap + strips (outer span)')
M('thigh_depth_side', b['side']['thigh']['outer_w_m'], 'side', E2, 'front-back thickness of the near thigh (no skirt in the side view)')
M('shin_depth_side', b['side']['shin']['outer_w_m'], 'side', E2, '')
M('shin_outer_span_back', b['back']['shin']['outer_w_m'], 'back', E2, 'outer span of both shins')
M('foot_length_side_heel_to_toe', (R['side']['special_points']['toe_extreme']['x_px'] - R['side']['special_points']['heel_extreme']['x_px'] + 1) / PPM, 'side', E2 + 0.01, 'includes heel spur and toe claw')
M('foot_width_back_each', 0.23, 'back', 0.02, 'image-left foot ~0.23-0.25, image-right ~0.20 at rows 0.03-0.08 m', 'derived')
M('foot_height_ankle', LM['ankle'], 'canon', POSE, '')
# --- horns
hb, hs = R['back']['horns'], R['side']['horns']
if len(hb) == 2:
    M('hornB_height_above_crown_back', hb[0]['top_h_m'] - LM['crown'], 'back', E1 + 0.02, 'image-left horn (thin/long, cream shaft)')
    M('hornB_span_back', hb[0]['span_m'], 'back', E2, 'horizontal extent at heights above crown+0.14')
    M('hornA_height_above_crown_back', hb[1]['top_h_m'] - LM['crown'], 'back', E1 + 0.02, 'image-right horn (thick/short, red)')
    M('hornA_span_back', hb[1]['span_m'], 'back', E2, '')
    M('horns_total_spread_back', (hb[1]['x_px'][1] - hb[0]['x_px'][0] + 1) / PPM, 'back', E2, 'outer tip to outer tip')
if len(hs) == 2:
    M('hornA_height_above_crown_side', hs[0]['top_h_m'] - LM['crown'], 'side', E1 + 0.02, 'rear/thick horn')
    M('hornA_span_side_depth', hs[0]['span_m'], 'side', E2, '')
    M('hornB_height_above_crown_side', hs[1]['top_h_m'] - LM['crown'], 'side', E1 + 0.02, 'front/long horn; CLIPPED by the right canvas edge (x=946) -> true reach >= shown')
    M('hornB_span_side_depth', hs[1]['span_m'], 'side', E2, 'lower bound (clipped at canvas edge)')

# ---- landmarks table (px in the 4096 frames + metres at 2.40 m)
lm_tab = {}
for v in VIEWS:
    lm_tab[v] = dict(axis_x_px=R[v]['axis_x_px'], rows={k: {kk: (round(vv, 3) if isinstance(vv, float) else vv) for kk, vv in d.items()} for k, d in R[v]['landmark_rows'].items()},
                     special_points={k: {kk: round(vv, 3) for kk, vv in d.items()} for k, d in R[v]['special_points'].items()})
# ---- negative spaces
neg = {v: [dict(name=g['name'], area_m2=round(g['area_m2'], 4), bbox_px=g['bbox_px'], h_top_m=round(g['h_top_m'], 3), h_bot_m=round(g['h_bot_m'], 3), x_range_m=[round(x, 3) for x in g['x_range_m']], polygon_px=g['polygon_px']) for g in R[v]['gaps'][:10]] for v in VIEWS}
# ---- asymmetry (back view, axis-relative)
asym = {}
for bn in ('shoulders', 'waist', 'pelvis', 'thigh', 'shin', 'foot'):
    bb = b['back'][bn]; asym[bn] = dict(left_edge_m=round(bb['xmin_m'], 3), right_edge_m=round(bb['xmax_m'], 3), centre_offset_m=round((bb['xmin_m'] + bb['xmax_m']) / 2, 3), note='back view, screen-left/right (image-right = his RIGHT by true geometry)')
# ---- part polygons: flood-fill colour regions at parts.json markers (approximate)
def part_polys():
    out = {}
    for v in VIEWS:
        im = load_ref_alpha(v); al = im[..., 3:4] / 255.; rgb = (im[..., :3] * al + 255 * (1 - al)).astype(np.uint8)
        H, W = rgb.shape[:2]; sil = MS[v]
        for p in parts:
            if v not in p['pos']: continue
            fx, fy = p['pos'][v]; x, y = int(fx * W), int(fy * H)
            if not (0 <= x < W and 0 <= y < H) or not sil[y, x]: continue
            patch = rgb[max(y - 3, 0):y + 4, max(x - 3, 0):x + 4].reshape(-1, 3); c = tuple(int(t) for t in np.median(patch, 0))
            mk = np.zeros((H + 2, W + 2), np.uint8); fl = cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE | (255 << 8) | 4
            area, _, _, rect = cv2.floodFill(rgb.copy(), mk, (x, y), 0, (16,) * 3, (16,) * 3, fl)
            reg = mk[1:-1, 1:-1].astype(np.uint8)
            if area < 300: continue
            cn = cv2.findContours(reg, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[0]
            if not cn: continue
            poly = cv2.approxPolyDP(max(cn, key=cv2.contourArea), 5, True)[:, 0, :]
            out.setdefault(str(p['id']), {})[v] = dict(marker_px=[x, y], marker_h_m=round(h_of(y), 3), colour_rgb=list(c)[::-1], area_m2=round(area / PPM**2, 4), bbox_px=list(rect), polygon_px=poly.tolist(), note='colour-region at marker (approximate)')
    return out
pp = part_polys()
# ---- classification
CLS = {
 'IMMUTABLE': ['Total height 2.40 m (horn tip to sole) and head 0.157 m (13.5 heads)', 'Two ASYMMETRIC jointed stag-beetle horns: A thick/short, B thin/long, tips ~2.40 m, hooked forward (side) / arching over (back); never symmetrise (parts 1,2,3)',
               'Long snouted dragon/horse head with side-set yellow eyes, white fang visible, cream face plate, red crown plates (parts 4-8)', 'Very long orange-red neck leaning forward; head carried ahead of the shoulders; hunched trunk (10)',
               'Big round red ladybug pauldron + elbow disc (11, 19), on the side set by the ruling (see Q1)', 'Dark aubergine under-armour (23) with tan plates (14, 24)', 'Hooded dark mantle with cream fringe over one shoulder (12)',
               'Chest wrap with knot (13), red waist sash (15), brass ring + boss (16), cream tassels (17)', 'Ragged leaf-strip skirt panel (25-27): hangs from belt over the front and his left side, NOT a full circle skirt',
               'Long pointed clawed hands (21, 22) and large clawed feet with armoured ankle wraps (30, 31, 32)', 'Morrow (spiked sphere, red core, telescoping haft)', 'Palette and the flat cel / heavy ink style'],
 'STRUCTURAL': ['Silhouette-carrying proportions: landmark rows of proportions.json (neck base 1.772, shoulder 1.631, elbow 1.311, waist 1.239, crotch 0.894, knee 0.596, ankle 0.251)', 'Neck length/lean, head-forward offset, torso hunch, spine curve (side)',
                'Shoulder mass: pauldron disc + mantle hem silhouette (back view, 0.625 m wide at the shoulder row)', 'Leg masses: thigh/knee guard/shin/calf plates and foot length', 'Skirt/strip hem line and extent', 'Horn curves (arc radius, hook), snout length and drooping hooked tip',
                'Stance: feet planted at different widths in the back view (contrapposto), knees bent in the side view', 'Negative spaces: arm-torso gaps, leg gap (0.21 m2 in back view), horn gap'],
 'SECONDARY': ['Tan plates 14/24 edges, forearm guards 20, knee guard 28, shin plate 29, ankle wraps 30', 'Nape fringe 9, temple tines 5, horn knob rings and side tines 3', 'Tassels 17, leaf pendant 18, shoulder fringe tail 33, belt strips', 'Eye socket/brow ridge, fang 8, finger/claw count', 'Hood bulge behind the neck, mantle fringe teeth'],
 'SURFACE': ['Cream star specks, gloss ovals, yellow spots on red discs, black pits (shallow recesses)', 'Orange/cream gloss streaks on the neck', 'Colour block edges, ink outline (heavy black silhouette), cream edge highlights', 'Wrap texture, cloth weave, leaf vein marks'],
}
PART_CLASS = {1: 'IMMUTABLE', 2: 'IMMUTABLE', 3: 'SECONDARY', 4: 'IMMUTABLE', 5: 'SECONDARY', 6: 'IMMUTABLE', 7: 'IMMUTABLE', 8: 'SECONDARY', 9: 'SECONDARY', 10: 'IMMUTABLE', 11: 'IMMUTABLE', 12: 'IMMUTABLE', 13: 'IMMUTABLE',
              14: 'STRUCTURAL', 15: 'IMMUTABLE', 16: 'IMMUTABLE', 17: 'SECONDARY', 18: 'SECONDARY', 19: 'IMMUTABLE', 20: 'STRUCTURAL', 21: 'IMMUTABLE', 22: 'IMMUTABLE', 23: 'STRUCTURAL', 24: 'STRUCTURAL', 25: 'IMMUTABLE',
              26: 'STRUCTURAL', 27: 'SECONDARY', 28: 'STRUCTURAL', 29: 'STRUCTURAL', 30: 'SECONDARY', 31: 'IMMUTABLE', 32: 'IMMUTABLE', 33: 'SECONDARY'}
ASYM = [
 dict(item='Horns', detail='A (thick, red, hooked, jointed) is short: tip 2.36-2.40 m, span 0.10 m (back) / 0.22 m (side). B (thin, longer arch, cream shaft in back view) tip 2.39-2.40 m, span 0.29 m (back) / 0.18+ m (side, clipped at the canvas edge). In the back view B is image-left, A is image-right.'),
 dict(item='Pauldron / mantle', detail='IMAGE terms (unambiguous): BACK view: red pauldron at image-left, big dark mantle at image-right (hem to ~0.37 of image height, cream fringe below). SIDE view (faces screen-right): red pauldron visible, no mantle. FRONT 3/4: hood behind viewer-left shoulder, red pauldron at viewer-right. Handedness ruling: see Q1.'),
 dict(item='Hands', detail='One hand = three long pointed claws (open, front viewer-left), the other = gloved fist gripping the Morrow haft (viewer-right in front; image-left fist in back view hangs at 0.77 m). Spec C5 proposes anatomy-identical, posed differently.'),
 dict(item='Feet', detail='Back view: image-left foot 0.23-0.25 m wide, image-right 0.20 m; legs planted at different widths; side foot has heel spur + long toe claw.'),
 dict(item='Skirt / strips', detail='Back view: ragged strips only along image-right leg (parts 26, 27, hem to ~0.83 of height); bare tan thigh plate on image-left. Front: full leaf skirt (25) across both thighs. Side: none. Brief proposes belt-hung strips over the front and his left side.'),
 dict(item='Stance', detail='Contrapposto: head/neck centre offset from hip axis; shoulders higher on one side; asym table below (back view).'),
]
spec = dict(meta=dict(character='aruun', frame='4096 px tall, ground row 4000, 1626.667 px/m; x relative to each view axis_x_px (side 436, back 659, front 896.5); +x screen-right', height_m=2.40, head_height_m=round(HEAD_H, 4),
                      views=dict(front='3/4 pose, head in profile, Morrow erased: NOT orthographic -> qualitative only', side='orthographic, faces screen-right, we see his RIGHT side', back='orthographic; true geometry: image-right = his RIGHT'),
                      edge_error_m=round(E1, 4), caveats=['side/back ortho PNGs carry a 2-5 px jagged black halo (error bar +-3 px per edge = +-0.0018 m)', 'side canvas clips horn B (x=946) and the rear arm/pauldron (x=0); back canvas clips the left arm (x=0) and right strips (x=1458)',
                                                         'landmark rows are artist-read (+-0.02 m); wrist is READ', 'front head is a profile: snout/head width and horn spread front come from the GENERATED head set only']),
            measurements=meas, silhouette_landmarks=lm_tab, negative_spaces=neg, asymmetry_list=ASYM, asymmetry_measured_back_view=asym, classification=CLS,
            part_class={str(k): v for k, v in PART_CLASS.items()}, part_regions=pp, width_profile_files='design/model_sheets/aruun/fidelity/ref_extract/width_profiles.csv')
json.dump(spec, open(os.path.join(FID, 'character_spec.json'), 'w'), indent=1)

# ---- debug image of part regions
for v in ('side', 'back'):
    im = load_ref_alpha(v); al = im[..., 3:4] / 255.; rgb = (im[..., :3] * al + 255 * (1 - al)).astype(np.uint8).copy()
    for pid, d in pp.items():
        if v in d:
            cv2.polylines(rgb, [np.array(d[v]['polygon_px'], np.int32)], True, (0, 255, 0), 4); cv2.putText(rgb, pid, tuple(d[v]['marker_px']), cv2.FONT_HERSHEY_SIMPLEX, 2.2, (255, 0, 255), 5)
    cv2.imwrite(os.path.join(FID, f'parts_regions_{v}.jpg'), cv2.resize(rgb, None, fx=.3, fy=.3, interpolation=cv2.INTER_AREA))

# ---- markdown
L = ['# ARUUN CHARACTER SPECIFICATION (Reference Forensics, source of truth for fidelity work)', '',
     'Generated by `tools/fidelity/make_spec.py` from `ref_extract/` (cleaned original ortho cuts). Machine-readable twin: `character_spec.json`. All numbers are the reference, not opinion.', '',
     '## 0. Frames, units, error bars', '- Reference frames: 4096 px tall, ground row 4000, 1626.667 px/m, 2.40 m = rows 96..4000. x relative to each view axis (side 436, back 659, front 896.5 px). Metres below assume 2.40 m total.',
     f'- Edge error: alpha cut + black halo = +-3 px per edge (+-{E1:.4f} m); a width has two edges (+-{E2:.4f} m). Landmark rows (artist-read) +-0.02 m. Quoted per measurement.',
     '- VIEW RULES: side and back are orthographic (quantitative). FRONT is a 3/4 pose with the head in profile: qualitative only, never a width source. Head front/top-down widths exist only in the GENERATED head set (low confidence).',
     '- Handedness: stated in IMAGE terms where it matters. Geometrically, in the BACK view image-right is his RIGHT (see Q1). In the SIDE view (faces screen-right) we see his RIGHT side.', '',
     '## 1. Normalised measurements', '', 'rel_H = value / 2.40 m; rel_head = value / 0.157 m. `err` = +- m. view = where it comes from.', '', '| measurement | m | rel_H | rel_head | err +-m | view | note |', '|---|---|---|---|---|---|---|']
for k, d in meas.items(): L.append(f"| {k} | {d['m']:.3f} | {d['rel_height']:.3f} | {d['rel_head']:.2f} | {d['err_m']:.3f} | {d['view']} | {d['note']} |")
L += ['', 'Width profile per 100 height slices: `ref_extract/width_profiles.csv` (slice 0 = top of horns; columns outer/solid width, xmin/xmax, centre offset, metres), per view.', '',
      '## 2. Silhouette landmarks (px in the 4096 frames; metres = height above sole and x from the view axis, at 2.40 m)', '']
for v in ('side', 'back', 'front'):
    L += [f"### {v}{'' if R[v]['quantitative'] else ' (3/4, qualitative)'}", '', '| landmark | height m | row px | left px | right px | left m | right m |', '|---|---|---|---|---|---|---|']
    for k, d in lm_tab[v]['rows'].items():
        L.append(f"| {k} | {d['h_m']:.3f} | {d['row_px']:.0f} | {d['left_px']} | {d['right_px']} | {'' if d['left_m'] is None else '%.3f' % d['left_m']} | {'' if d['right_m'] is None else '%.3f' % d['right_m']} |")
    L += ['', '| special point | x px | y px | x m | height m |', '|---|---|---|---|---|']
    for k, d in lm_tab[v]['special_points'].items(): L.append(f"| {k} | {d['x_px']:.0f} | {d['y_px']:.0f} | {d['x_m']:.3f} | {d['h_m']:.3f} |")
    L.append('')
L += ['## 3. Negative spaces (enclosed background regions; polygons in character_spec.json)', '']
for v in ('side', 'back', 'front'):
    L += [f'### {v}', '', '| name | area m2 | height range m | x range m | bbox px (x,y,w,h) |', '|---|---|---|---|---|']
    for g in neg[v][:8]: L.append(f"| {g['name']} | {g['area_m2']:.3f} | {g['h_bot_m']:.2f}..{g['h_top_m']:.2f} | {g['x_range_m'][0]:.2f}..{g['x_range_m'][1]:.2f} | {g['bbox_px']} |")
    L.append('')
L += ['## 4. Asymmetry', ''] + [f"- **{a['item']}**: {a['detail']}" for a in ASYM] + ['', 'Measured left/right edge of the silhouette (back view, m from axis, screen-left negative):', '', '| band | screen-left edge | screen-right edge | centre offset |', '|---|---|---|---|']
for k, d in asym.items(): L.append(f"| {k} | {d['left_edge_m']} | {d['right_edge_m']} | {d['centre_offset_m']} |")
L += ['', '## 5. Armour / clothing boundaries', '', 'Part numbers = `parts.json` / ARUUN_BRIEF section 1 (33 parts). Polygons (colour regions flood-filled at the parts.json marker, approximate) are in `character_spec.json` -> `part_regions[part_id][view]`; debug overlays `parts_regions_side.jpg`, `parts_regions_back.jpg`. Layer order inner->outer: 1 bone/skin, 2 under-armour (23), 3 neck (10), 4 hands/feet (21,22,31,32), 5 tan plates (14,24), 6 wrap/guards (13,20,28,29,30), 7 red discs+sash (11,15,19), 8 belt/tassels/skirt/head plates, 9 horns/outer strips/tail (1-3,26,33), 10 mantle (12).', '',
      '| id | part | class | regions found (views) | layer |', '|---|---|---|---|---|']
for p in parts: L.append(f"| {p['id']} | {p['name']} | {PART_CLASS[p['id']]} | {','.join(pp.get(str(p['id']), {}).keys()) or '-'} | {p['layer']} |")
L += ['', '## 6. Feature classification', '']
for k, v in CLS.items(): L += [f'**{k}**'] + [f'- {x}' for x in v] + ['']
L += ['## 7. Known ambiguity in the reference (see report questions)', '- Handedness of mantle/pauldron (Q1). Side vs back/front disagree.', '- Canvas clipping of horn B (side) and arms (side/back).', '- No true-front head. Generated head only.',
      '- Wrist row READ; hand length is vertical only (fist hangs closed). The neck arc measured here (~0.25 m) contradicts the 0.45 m in spec.md.', '- Horn tip heights disagree between views by up to 0.04 m (A: 2.36 back / 2.40 side; B: 2.40 back / 2.39 side).', '']
open(os.path.join(FID, 'CHARACTER_SPEC.md'), 'w').write('\n'.join(L))
print('spec written', len(meas), 'measurements', len(pp), 'parts with regions')
