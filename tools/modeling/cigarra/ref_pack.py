#!/usr/bin/env python3
"""Cigarra reference pack from the hi-res x4 views (design/model_sheets/cigarra/hires). Crops/annotations only.
Outputs turnaround.png (views at equal height 1.65 m, 0.1 m guides), palette.json/png (k-means of each view)."""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
D = os.path.join(ROOT, "design", "model_sheets", "cigarra")
H_M, H = 1.65, 1400
views = [("front", "FRONT (3/4, wing cloak spread)"), ("side", "SIDE (faces screen-right)"), ("back", "BACK (wing cloak folded)")]
ims = []
for v, lab in views:
    im = Image.open(os.path.join(D, "hires", v + "_x4.png")).convert("RGBA")
    im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 128 else 0).getbbox())
    ims.append((v, lab, im.resize((int(im.width * H / im.height), H), Image.LANCZOS)))
W = sum(i.width for _, _, i in ims) + 60 * (len(ims) + 1)
board = Image.new("RGBA", (W, H + 140), (236, 228, 214, 255)); d = ImageDraw.Draw(board)
d.text((20, 15), "CIGARRA - turnaround from Real-ESRGAN x4 sheet views (height 165 cm incl. crown; guides every 10 cm)", fill=(30, 25, 25))
for k in range(0, 17):
    y = 100 + H - k / H_M * 0.1 * H
    d.line([(0, y), (W, y)], fill=(170, 150, 140, 255))
x = 60
pal = {}
for v, lab, im in ims:
    board.alpha_composite(im, (x, 100)); d.text((x, 75), lab, fill=(30, 25, 25)); x += im.width + 60
    a = np.asarray(im); px = a[a[..., 3] > 200][:, :3].astype(float)
    rng = np.random.default_rng(1); c = px[rng.choice(len(px), 6, replace=False)]
    for _ in range(15):
        lab_ = np.argmin(((px[:, None] - c[None]) ** 2).sum(-1), 1)
        c = np.array([px[lab_ == j].mean(0) if (lab_ == j).any() else c[j] for j in range(6)])
    cnt = np.bincount(lab_, minlength=6); o = np.argsort(-cnt)
    pal[v] = [{"hex": "#%02x%02x%02x" % tuple(int(t) for t in c[j]), "share": round(cnt[j] / len(px), 3)} for j in o]
board.convert("RGB").save(os.path.join(D, "turnaround.png"))
json.dump(pal, open(os.path.join(D, "palette.json"), "w"), indent=1)
sw = Image.new("RGB", (6 * 80, 3 * 80), (236, 228, 214)); sd = ImageDraw.Draw(sw)
for r, v in enumerate(pal):
    for i, e in enumerate(pal[v]):
        sd.rectangle((i * 80, r * 80, i * 80 + 78, r * 80 + 78), fill=e["hex"]); sd.text((i * 80 + 4, r * 80 + 4), e["hex"], fill=(255, 255, 255))
sw.save(os.path.join(D, "palette.png"))
print("ok")
