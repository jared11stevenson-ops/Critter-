#!/usr/bin/env python3
"""Overview sheet: originals (row 1), new v2 views clean (row 2) and derivation overlays (row 3) + legend. <= 2400 px wide."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
from PIL import Image, ImageDraw, ImageFont
TH = 640; BG = (214, 208, 196)
def flat(path, bgc=BG):
    a = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if a.shape[2] == 3: return a
    al = a[..., 3:] / 255.0; return (a[..., :3] * al + np.array(bgc[::-1]) * (1 - al)).astype(np.uint8)
def tile(img, crop=None, h=TH):
    if crop: img = img[crop[1]:crop[3], crop[0]:crop[2]]
    s = h / img.shape[0]; return cv2.resize(img, None, fx=s, fy=s, interpolation=cv2.INTER_AREA)
def row(tiles, gap=10):
    W = sum(t.shape[1] for t in tiles) + gap * (len(tiles) + 1); out = np.full((TH + 30, W, 3), BG[::-1], np.uint8) if False else np.full((TH + 30, W, 3), BG, np.uint8)
    x = gap
    for t, cap in tiles_caps(tiles):
        pass
    return out
def compose(cols, gap=8):
    """cols: list of (img, caption)"""
    W = sum(c[0].shape[1] for c in cols) + gap * (len(cols) + 1); H = TH + 26
    im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im); f = ImageFont.load_default(); x = gap
    for t, cap in cols:
        im.paste(Image.fromarray(cv2.cvtColor(t, cv2.COLOR_BGR2RGB)), (x, 22)); d.text((x + 2, 6), cap, fill=(20, 16, 18), font=f); x += t.shape[1] + gap
    return np.array(im)[..., ::-1]
if __name__ == '__main__':
    P = ORTHO; V = OUT
    o = [(flat(P + '/aruun_front_4096.png'), None, 'ORIGINAL front (3/4, perspective)'), (flat(P + '/aruun_side_4096.png'), None, 'ORIGINAL side'), (flat(P + '/aruun_back_4096.png'), None, 'ORIGINAL back'),
         (flat(ROOT + '/design/reference_packs/aruun/head/aruun_head_turnaround.jpg'), None, 'ORIGINAL head turnaround')]
    n = [('aruun_v2_front_ortho_4096', None, 'NEW front ortho'), ('aruun_v2_side_completed_4096', None, 'NEW side (completed)'), ('aruun_v2_back_completed_4096', None, 'NEW back (completed)'),
         ('aruun_v2_34_front_left_4096', (350, 0, 1850, 4096), 'NEW 3/4 front-left'), ('aruun_v2_34_front_right_4096', (350, 0, 1850, 4096), 'NEW 3/4 front-right'),
         ('aruun_v2_34_back_left_4096', (350, 0, 1850, 4096), 'NEW 3/4 back-left'), ('aruun_v2_34_back_right_4096', (350, 0, 1850, 4096), 'NEW 3/4 back-right'),
         ('aruun_v2_face_calm_zoom', None, 'NEW face CALM'), ('aruun_v2_face_rage_zoom', None, 'NEW face RAGE')]
    r1 = compose([(tile(a, crop), c) for a, crop, c in o])
    def newtile(name, crop, suf=''):
        a = flat(os.path.join(V, name + suf + '.png'), BG); return tile(a, crop)
    r2 = compose([(newtile(a, crop), c) for a, crop, c in n]); r3 = compose([(newtile(a, crop, '' if 'zoom' in a and False else ('_derivation')), c + ' - derivation') for a, crop, c in n])
    W = max(r1.shape[1], r2.shape[1], r3.shape[1]); rows = [r1, r2, r3]
    # scale every row to the same total width (<=2400)
    rows = [cv2.resize(r, None, fx=2400 / r.shape[1], fy=2400 / r.shape[1], interpolation=cv2.INTER_AREA) if r.shape[1] > 2400 else r for r in rows]
    W = max(r.shape[1] for r in rows); pad = lambda r: np.pad(r, ((0, 0), (0, W - r.shape[1]), (0, 0)), constant_values=214)
    leg = Image.new('RGB', (W, 56), BG); d = ImageDraw.Draw(leg); f = ImageFont.load_default(); x = 12
    for col, txt in ((GREEN, 'GREEN = original sheet pixels (head tiles; side/back paint where the surface faces both cameras)'), (YELLOW, 'YELLOW = inferred / completed / warped from another view'), (RED, 'RED = unknown, nearest-neighbour fill')):
        d.rectangle([x, 8, x + 22, 30], fill=col); d.text((x + 28, 14), txt, fill=(20, 16, 18), font=f); x += 28 + int(d.textlength(txt, font=f)) + 30
    d.text((12, 38), 'Nothing here is approved: creator approval only. Rows: originals / new clean / new derivation overlay. See FIDELITY_NOTES.md for the risk ranking.', fill=(20, 16, 18), font=f)
    out = np.vstack([pad(r) for r in rows] + [np.array(leg)[..., ::-1]])
    os.makedirs(os.path.join(V, 'review'), exist_ok=True); cv2.imwrite(os.path.join(V, 'review/aruun_v2_overview.png'), out); print(out.shape)
