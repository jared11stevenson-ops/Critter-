#!/usr/bin/env python3
"""Quality gate for generated Aruun references. usage: review_gen.py <generated.png> <kind> [out.png]
kind: front|side|back|head_front|head_side|head_back|hands|feet. Builds a side-by-side (original | generated | difference) with silhouette IoU after
height-normalising both, plus a colour-drift table (palette of the original vs generated). Judgement stays human: see REVIEW_GEN.md."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from common import *
gen, kind = sys.argv[1], sys.argv[2]; out = sys.argv[3] if len(sys.argv) > 3 else gen.rsplit(".", 1)[0] + "_review.png"
base = kind.split("_")[-1] if kind.startswith("head") else kind
src = {"front": "front", "side": "side", "back": "back", "hands": "front", "feet": "front"}.get(base, "side")
orig = Image.open(f"{PACKS}/aruun/ortho/aruun_{src}_4096.png").convert("RGBA")
g = Image.open(gen).convert("RGBA")
if g.getchannel("A").getextrema()[0] == 255:                      # opaque: key out the border colour
    g = key_bg(g.convert("RGB"))
def norm(im, h=1200):
    bb = im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox(); im = im.crop(bb); return im.resize((max(1, int(im.width * h / im.height)), h), Image.LANCZOS)
o, n = norm(orig), norm(g); W = max(o.width, n.width)
def mask(im): m = np.zeros((1200, W), bool); m[:, :im.width] = np.asarray(im.getchannel("A")) > 40; return m
mo, mn = mask(o), mask(n); iou = (mo & mn).sum() / max((mo | mn).sum(), 1)
diff = np.zeros((1200, W, 3), np.uint8); diff[mo & ~mn] = (220, 40, 40); diff[mn & ~mo] = (40, 80, 220); diff[mo & mn] = (200, 200, 200)
cv = Image.new("RGB", (W * 3 + 40, 1260), BG); d = ImageDraw.Draw(cv)
for i, (im, t) in enumerate(((o, "ORIGINAL"), (n, "GENERATED"))):
    bg = Image.new("RGB", (W, 1200), BG); bg.paste(im, (0, 0), im); cv.paste(bg, (i * (W + 20), 50)); d.text((i * (W + 20) + 10, 10), t, font=font(28), fill=INK)
cv.paste(Image.fromarray(diff), (2 * (W + 20), 50)); d.text((2 * (W + 20) + 10, 10), f"DIFF red=orig only blue=gen only  IoU {iou:.2f}", font=font(24), fill=INK)
cv.save(out); print(f"silhouette IoU (height-normalised, left-aligned) = {iou:.3f}; wrote {out}")
def pal(im):
    a = np.asarray(im.convert("RGBA")).reshape(-1, 4); a = a[a[:, 3] > 200][:, :3]; q = (a // 32).astype(int); k, c = np.unique(q, axis=0, return_counts=True); o = np.argsort(-c)[:6]
    return [("#%02x%02x%02x" % tuple(k[i] * 32 + 16), round(c[i] / c.sum(), 2)) for i in o]
print("orig palette", pal(o)); print("gen  palette", pal(n))
