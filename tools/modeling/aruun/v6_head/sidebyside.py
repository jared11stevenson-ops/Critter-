"""usage: sidebyside.py STEPDIR -> STEPDIR/compare.png : ref crop (top) vs model close-up (bottom) for side, back (v2 completed ortho, same framing as closeups), front (calm face tile), 3/4 (focused_34 head ref)"""
import sys, os
from PIL import Image, ImageDraw
D = sys.argv[1]; ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')); R = ROOT + '/design/reference_gen/aruun/'
PPM = 1626.667; S = 450
def comp(p):
    im = Image.open(p).convert('RGBA'); bg = Image.new('RGBA', im.size, (204, 204, 199, 255)); bg.alpha_composite(im); return bg.convert('RGB')
def crop(im, cx, cy, half): return im.crop((int(cx - half), int(cy - half), int(cx + half), int(cy + half))).resize((S, S), Image.LANCZOS)
half = 0.31 * PPM
side = crop(comp(R + 'v2/aruun_v2_side_completed_4096.png'), 536 + 0.05 * PPM, 4000 - 2.12 * PPM, half)
back = crop(comp(R + 'v2/aruun_v2_back_completed_4096.png'), 759 - 0.09 * PPM, 4000 - 2.12 * PPM, half)
calm = Image.open(R + 'v2/aruun_v2_face_calm_4096.png'); calm = comp(R + 'v2/aruun_v2_face_calm_4096.png').crop((250, 250, 1000, 1000)).resize((S, S), Image.LANCZOS)
q34 = Image.open(R + 'head/aruun_head_focused_34.png').convert('RGB').crop((100, 600, 1400, 1900)).resize((S, S), Image.LANCZOS)
refs = [calm, side, q34, back]; names = ['front', 'side', 'q34', 'back']
out = Image.new('RGB', (S * 4, S * 2))
for i, n in enumerate(names):
    out.paste(refs[i], (S * i, 0)); out.paste(Image.open(f'{D}/head_clay_{n}.png').convert('RGB').resize((S, S), Image.LANCZOS), (S * i, S))
ImageDraw.Draw(out).text((6, 4), 'REF: front(calm tile) | side(v2) | 3/4 (focused_34) | back(v2)    MODEL below', fill=(0, 0, 0))
out.save(D + '/compare.png')
