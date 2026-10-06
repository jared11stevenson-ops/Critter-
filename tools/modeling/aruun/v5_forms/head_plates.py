"""P1c head details on the lofted skull. Plates are TRACED from the v2 completed side image (colour segmentation of the head crop: red face/muzzle plates, tan brow + cheek plates, olive crown band, yellow eye)
and CONFORMED to the skull surface (analytic ring surface from head_loft), extruded with a bevel (thickness ramps from 0 at the traced outline to T inside). They are mirrored to his left side
(the left side is not visible in any original view: symmetry assumption). Temple tines and cheek spikes are rooted inside the skull. Eyes: socket (dark ring) + eyeball, separate objects."""
import os, sys, numpy as np
import bpy, cv2
from scipy.spatial import Delaunay
import head_loft as HLF
import fid_common as fc
import build_forms as BF
from build_forms import tube, ell, nm, UP, FW, LF, HL

X0, Y0, X1, Y1 = 330, 520, 1000, 860        # head crop in the v2 side frame
def seg():
    import fid_common as f
    im = f.load_ref_alpha('side'); c = im[Y0:Y1, X0:X1]; rgb = c[..., [2, 1, 0]].astype(int); a = c[..., 3] > 128
    R, G, B = rgb[..., 0], rgb[..., 1], rgb[..., 2]; lab = np.zeros(R.shape, np.uint8)
    lab[a & (R < 75) & (G < 75) & (B < 75)] = 1
    lab[a & (R > 100) & (G < 90) & (B < 80) & (R - G > 50)] = 2                 # red plates
    lab[a & (R > 165) & (G > 120) & (B > 60) & (B < 140) & (G < 185) & (R > G)] = 3   # tan
    lab[a & (R > 190) & (G > 140) & (B < 110) & (G > 0.72 * R)] = 4             # yellow eye
    lab[a & (R > 100) & (R <= 165) & (G > 70) & (B < 90) & (lab == 0)] = 5     # olive/brown crown band
    return lab

def px2fu(col, row): return ((X0 + col - fc.view_info('side')['axis_x_px']) / fc.PPM, (fc.GROUND - (Y0 + row)) / fc.PPM)

def components(lab, label, min_area=350):
    n, cc, st, cen = cv2.connectedComponentsWithStats((lab == label).astype(np.uint8), connectivity=8)
    out = []
    for i in range(1, n):
        if st[i, cv2.CC_STAT_AREA] >= min_area: out.append(((cc == i), cen[i], st[i, cv2.CC_STAT_AREA]))
    return out

def patch(name, mask, side, T=0.010, step=5):
    """triangulated, conformed, bevelled plate from a traced component mask (crop px)."""
    m8 = mask.astype(np.uint8)
    cnts, _ = cv2.findContours(m8, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    cnt = max(cnts, key=cv2.contourArea); cnt = cv2.approxPolyDP(cnt, 1.6, True)[:, 0, :]
    if len(cnt) < 4: return None
    dt = cv2.distanceTransform(m8, cv2.DIST_L2, 3)
    ys, xs = np.nonzero(m8); inside = [(x, y) for x, y in zip(xs[::step], ys[::step]) if dt[y, x] > step * 0.8]
    boundary = []
    for i in range(len(cnt)):                                     # densify the outline
        p, q = cnt[i], cnt[(i + 1) % len(cnt)]; k = max(1, int(np.hypot(*(q - p)) // step))
        for j in range(k): boundary.append(p + (q - p) * j / k)
    pts = np.array(boundary + [list(p) for p in inside], float)
    tri = Delaunay(pts); keep = []
    for s in tri.simplices:
        c = pts[s].mean(0)
        if cv2.pointPolygonTest(cnt.astype(np.float32).reshape(-1, 1, 2), (float(c[0]), float(c[1])), False) >= 0: keep.append(s)
    keep = np.array(keep); nb = len(boundary)
    V_top, V_bot, ok = [], [], []
    for (x, y) in pts:
        F, U = px2fu(x, y); xi, yi = int(np.clip(round(x), 0, m8.shape[1] - 1)), int(np.clip(round(y), 0, m8.shape[0] - 1))
        d = dt[yi, xi]; t = T * min(1.0, (d / (step * 1.6)) ** 0.8) + 0.002
        r = HLF.skull_surface(F, U, side)
        if r is None: ok.append(False); V_top.append((0, 0, 0)); V_bot.append((0, 0, 0)); continue
        hw, dLc = r; ok.append(True)
        base = HL + dLc + side * (hw + 0.002)
        V_top.append((base + side * t, -F, U)); V_bot.append((base - side * 0.004, -F, U))
    ok = np.array(ok); keep = np.array([s for s in keep if ok[s].all()])
    if len(keep) < 2: return None
    n = len(pts); V = V_top + V_bot; Fcs = []
    for s in keep: Fcs.append([int(s[0]), int(s[1]), int(s[2])] if side < 0 else [int(s[0]), int(s[2]), int(s[1])])
    for s in keep: Fcs.append([int(s[0]) + n, int(s[2]) + n, int(s[1]) + n] if side < 0 else [int(s[0]) + n, int(s[1]) + n, int(s[2]) + n])
    edges = {}
    for s in keep:
        for a, b in ((s[0], s[1]), (s[1], s[2]), (s[2], s[0])): edges.setdefault((min(a, b), max(a, b)), []).append((a, b))
    for (a, b), l in edges.items():
        if len(l) == 1:
            a, b = l[0]; Fcs.append([int(a), int(b), int(b) + n, int(a) + n] if side < 0 else [int(b), int(a), int(a) + n, int(b) + n])
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], Fcs); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    for p in me.polygons: p.use_smooth = True
    return ob

def build(parts, stage=3):
    lab = seg(); add = []
    # ---- ticket 1: rooted temple tines + cheek spikes (root inside the skull)
    def root(F, U, side, sink=0.012):
        r = HLF.skull_surface(F, U, side) or (0.09, 0.0); return HL + r[1] + side * (r[0] - sink)
    for s, n, tip in ((1, 'L', 0.155), (-1, 'R', 0.168)):
        L0 = root(0.0, 2.098, s); Lt = HL + s * tip
        add.append(nm(tube('temple_tine_' + n, [(0.002, 2.098, L0), (-0.012, 2.102, L0 + s * (Lt - HL - (L0 - HL) * s) * 0.35 * 1.0 if False else L0 + s * 0.04), (-0.028, 2.100, HL + s * (tip - 0.03)), (-0.040, 2.095 if s > 0 else 2.118, HL + s * tip)],
                       [(0.020, 0.014), (0.015, 0.011), (0.010, 0.008), (0.003, 0.003)], hint=UP), 'temple_tine_' + n))

    # ---- ticket 2: plates traced from the reference (red face plate, tan brow, tan cheek, crown band) + eyes
    for lb, T, base in ((2, 0.006, 'red_plate'), (3, 0.008, 'tan_plate')):
        for i, (m, cen, area) in enumerate(components(lab, lb)):
            F, U = px2fu(*cen)
            if not (0.0 < F < 0.17 and 1.975 < U < 2.11 and area < 9000): continue
            for s, side_n in ((-1, 'R'), (1, 'L')):
                ob = patch('%s%d_%s' % (base, i, side_n), m, s, T=T)
                if ob is not None: add.append(ob)
    for (m, cen, area) in components(lab, 4, 60):
        F, U = px2fu(*cen)
        for s, n in ((1, 'L'), (-1, 'R')):
            r = HLF.skull_surface(F, U, s)
            if r is None: continue
            Lc = HL + r[1] + s * r[0]
            add.append(nm(ell('eye_socket_' + n, (F - 0.002, U, Lc - s * 0.016), (0.034, 0.030, 0.014)), 'eye_socket_' + n))
            add.append(nm(ell('eyeball_' + n, (F, U, Lc - s * 0.008), (0.020, 0.017, 0.015)), 'eyeball_' + n))
        break
    for i, (f, u, rf, rl) in enumerate(((0.010, 2.118, 0.080, 0.100), (0.030, 2.126, 0.058, 0.072), (0.045, 2.133, 0.036, 0.048))):
        add.append(nm(ell('crown_plate%d' % (i + 1), (f, u, HL), (rf, 0.007, rl)), 'crown_plate%d' % (i + 1)))
    # nose pad + nostrils at the end of the upper skull
    st = HLF.station_data('skull'); Fe, ube, ute = st[-1]
    add.append(nm(ell('nose_pad', (Fe - 0.004, 0.5 * (ube + ute), HL), (0.020, 0.5 * (ute - ube) * 0.9, 0.024)), 'nose_pad'))
    for s, n in ((1, 'L'), (-1, 'R')): add.append(nm(ell('nostril_' + n, (Fe + 0.008, 0.5 * (ube + ute) + 0.003, HL + s * 0.011), (0.007, 0.006, 0.006)), 'nostril_' + n))
    # horn cups at the horn roots (from the extracted curves)
    import json
    C = json.load(open(os.environ.get('HORN_CURVES', os.path.join(BF.P.ROOT, 'design/model_sheets/aruun/fidelity/forms/horn_curves.json'))))
    for n in ('A', 'B'):
        p = np.array(C[n]['points_FUL']); r = np.array(C[n]['radii_FL'])
        add.append(nm(ell('horn_cup_' + n, tuple(p[2] + [0, 0.004, 0]), (r[2][0] + 0.014, 0.022, r[2][1] + 0.014)), 'horn_cup_' + n))
    skip = [x for x in os.environ.get('PL_SKIP', '').split(',') if x]
    for o in list(add):
        if any(o.name.startswith(k) for k in skip): add.remove(o); bpy.data.objects.remove(o, do_unlink=True)
    parts.extend(add)
