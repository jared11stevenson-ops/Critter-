#!/usr/bin/env python3
"""v2 (1)+(2): complete the clipped extents of the ORTHO side / back cuts by continuing the visible curves (no diffusion).
For every run of opaque pixels touching the left/right image edge: pad the canvas, fit the centre-line and width trend of the last columns, extend along the
trend for L px with a width taper, colour = the edge column's own colour profile (flat cel art), and add a 5 px ink outline. Extended pixels = YELLOW."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
PAD = 100
INK = np.array([22, 16, 20], np.uint8)   # BGR sheet outline ink (sampled: ~#14101a-#1b1215)

def runs(mask):
    idx = np.where(mask)[0]
    if not len(idx): return []
    br = np.where(np.diff(idx) > 1)[0]; st = np.r_[idx[0], idx[br + 1]]; en = np.r_[idx[br], idx[-1]]
    return list(zip(st, en))

def extend_edge(img, cls, side, r0, r1, L, taper, kfit=30):
    """Extends the opaque run rows r0..r1 touching the left/right edge outward by up to L px. Long runs (>=60 rows): rounded elliptical bulge (the contour is
    continued smoothly, row colours are extruded from the edge, 5 px ink outline). Short runs (thin tips): centre line trend extrapolated with a width taper."""
    H, W = img.shape[:2]
    e = PAD if side == 'L' else W - PAD - 1; sgn = -1 if side == 'L' else 1
    n = r1 - r0 + 1
    if n >= 60:
        yc = (r0 + r1) / 2; hr = n / 2 + 6
        for y in range(r0 - 6, r1 + 7):
            if y < 0 or y >= H: continue
            ext = int(round(L * np.sqrt(max(1 - ((y - yc) / hr) ** 2, 0))))
            ys = int(np.clip(y, r0, r1))
            if img[y, e, 3] < 128: continue
            ext = min(ext, 4 + 0 if False else ext)
            for d in range(1, ext + 1):
                x = e + sgn * d
                if img[y, x, 3] > 128: continue
                img[y, x, :3] = INK if (ext - d < 5 or abs(y - yc) > hr - 5) else img[y, e - sgn * 1, :3]
                img[y, x, 3] = 255; cls[y, x] = 2
        return img, cls
    cs, ws, xs = [], [], []
    for k in range(kfit):
        x = e - sgn * k; col = img[:, x, 3] > 128
        off = max(r0 - 40, 0); rr = [(a + off, b + off) for a, b in runs(col[off:r1 + 41]) if b + off >= r0 and a + off <= r1]
        if not rr: continue
        a, b = min(rr)[0], max(rr, key=lambda t: t[1])[1]; cs.append((a + b) / 2); ws.append(b - a + 1); xs.append(k)
    xs = np.array(xs, float); cs = np.array(cs); ws = np.array(ws); pc = np.polyfit(xs, cs, 1)
    a0, b0 = int(cs[0] - ws[0] / 2), int(cs[0] + ws[0] / 2)
    for d in range(1, L + 1):
        x = e + sgn * d
        if x < 0 or x >= W: break
        t = d / L; wd = max(ws[0] * (1 - (1 - taper) * t), 3); c = cs[0] - pc[0] * d
        top, bot = c - wd / 2, c + wd / 2
        for y in range(int(np.floor(top)), int(np.ceil(bot)) + 1):
            if y < 0 or y >= H or y < top - 0.5 or y > bot + 0.5: continue
            u = (y - top) / max(bot - top, 1); ys = int(np.clip(a0 + u * (b0 - a0), 0, H - 1))
            edge = (y - top < 4) or (bot - y < 4) or d > L - 4
            img[y, x, :3] = INK if edge else img[ys, e - sgn * 1, :3]; img[y, x, 3] = 255; cls[y, x] = 2
    return img, cls

def process(view, specs):
    s = load_rgba(os.path.join(ORTHO, f'aruun_{view}_4096.png')); H, W = s.shape[:2]
    img = np.zeros((H, W + 2 * PAD, 4), np.uint8); img[:, PAD:PAD + W] = s
    cls = np.zeros(img.shape[:2], np.uint8); cls[:, PAD:PAD + W][s[..., 3] > 128] = 1
    done = []
    for side, r0, r1, L, taper, what in specs:
        img, cls = extend_edge(img, cls, side, r0, r1, L, taper); done.append(dict(edge=side, rows=[r0, r1], extend_px=L, taper=taper, what=what))
    # leftover half-transparent halo pixels belong to the original: class 1 where alpha>0 and not yellow
    cls[(img[..., 3] > 0) & (cls == 0)] = 1
    return img, cls, done

if __name__ == '__main__':
    vi = META['views']
    sd, scls, d1 = process('side', [('L', 2274, 2493, 14, 0.9, 'rear (his back-side) forearm / hand cuff clipped at the left cut edge'),
                                     ('R', 216, 225, 28, 0.35, 'horn B tip (dark hooked knob) clipped at the right cut edge')])
    m = dict(view='side', camera='orthographic, camera at his right looking +X (yaw -90), he faces screen-right', x_offset_px=PAD, axis_x_px=vi['side']['axis_x_px'] + PAD,
             sources=['design/reference_packs/aruun/ortho/aruun_side_4096.png (original cut of tools/source_art/aruun_nerit_sheet.jpg SIDE figure)'], completions=d1,
             regions='all green pixels = original side figure; yellow = only the extensions listed in completions (continued trend, ink outline added). Pauldron on his RIGHT is as drawn; creator question open: red pauldron on both shoulders?')
    print('side', write_set('aruun_v2_side_completed_4096', sd, scls, m))
    bk, bcls, d2 = process('back', [('L', 2394, 2427, 12, 0.85, 'his-left arm forearm/guard clipped at the left cut edge'),
                                     ('R', 2953, 2976, 40, 0.5, 'right-edge strips / cream tassel tip clipped')])
    m = dict(view='back', camera='orthographic, camera behind him looking +Z (yaw 180); image-right = his RIGHT (mantle side)', x_offset_px=PAD, axis_x_px=vi['back']['axis_x_px'] + PAD,
             sources=['design/reference_packs/aruun/ortho/aruun_back_4096.png'], completions=d2, regions='green = original; yellow = edge extensions only')
    print('back', write_set('aruun_v2_back_completed_4096', bk, bcls, m))
