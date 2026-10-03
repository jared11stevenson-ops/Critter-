#!/usr/bin/env python3
"""Reference pack boards for 3D work: design/model_sheets/<id>/{turnaround.png, palette.json, palette.png,
expressions.png}. Inputs: hires/<view>_hd.png (hd_sprites.py --refs) and game/art/portraits/<id>/*.png.
spec.md is hand-written (read off the sheet + lore bible); this script never touches it.

Usage: python3 tools/art_pipeline/make_refpack.py <id> [<id> ...]
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.cluster.vq import kmeans2

sys.path.insert(0, os.path.dirname(__file__))
from hd_sprites import save_optimized  # noqa: E402

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BG = (232, 223, 204)
INK = (40, 30, 28)


def font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              os.path.join(ROOT, "game/art/fonts/barlow_condensed_bold.ttf")):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def palette(im, k=6):
    a = np.asarray(im.convert("RGBA"))
    px = a[a[..., 3] > 200][:, :3].astype(np.float32)
    if len(px) > 60000:
        px = px[np.random.default_rng(1).choice(len(px), 60000, replace=False)]
    cent, lab = kmeans2(px, k, minit="++", seed=1)
    share = np.bincount(lab, minlength=k) / len(lab)
    order = np.argsort(-share)
    return [{"hex": "#%02x%02x%02x" % tuple(int(v) for v in cent[i].clip(0, 255)), "share": round(float(share[i]), 3)}
            for i in order if share[i] > 0]


def main():
    canon = json.load(open(os.path.join(ROOT, "game/canon/canon.json")))["characters"]
    for cid in sys.argv[1:]:
        d = os.path.join(ROOT, "design", "model_sheets", cid)
        views = [(v, Image.open(os.path.join(d, "hires", v + "_hd.png")).convert("RGBA"))
                 for v in ("front", "side", "back") if os.path.exists(os.path.join(d, "hires", v + "_hd.png"))]
        H = 900
        h_m = canon.get(cid, {}).get("height_m", 1.8)
        scaled = [(v, im.resize((max(1, round(im.width * H / im.height)), H), Image.LANCZOS)) for v, im in views]
        W = sum(im.width for _, im in scaled) + 40 * (len(scaled) + 1) + 140
        board = Image.new("RGB", (W, H + 150), BG)
        dr = ImageDraw.Draw(board)
        dr.text((30, 18), "%s - turnaround (game cut, original paint)  height %s" %
                (canon.get(cid, {}).get("name", cid), ("%g cm" % (h_m * 100)) if h_m < 3 else "%g m" % h_m),
                fill=INK, font=font(30))
        x = 40
        top = 80
        for v, im in scaled:
            board.paste(im, (x, top), im)
            dr.text((x + im.width // 2 - 30, top + H + 12), v.upper(), fill=INK, font=font(26))
            x += im.width + 40
        # height bar (art top -> feet = canon height)
        bx = x + 30
        dr.line((bx, top, bx, top + H), fill=INK, width=4)
        for t in (0, 0.25, 0.5, 0.75, 1.0):
            y = top + H - t * H
            dr.line((bx - 10, y, bx + 10, y), fill=INK, width=3)
            lab = ("%.0f cm" % (t * h_m * 100)) if h_m < 3 else ("%.2g m" % (t * h_m))
            dr.text((bx + 16, y - 12), lab, fill=INK, font=font(20))
        save_optimized(board, os.path.join(d, "turnaround.png"), quality="75-100")
        # palette
        pal = {v: palette(im) for v, im in views}
        json.dump(pal, open(os.path.join(d, "palette.json"), "w"), indent=1)
        sw = Image.new("RGB", (6 * 90 + 20, len(pal) * 110 + 10), BG)
        sd = ImageDraw.Draw(sw)
        for r, (v, cols) in enumerate(pal.items()):
            sd.text((10, r * 110 + 4), v, fill=INK, font=font(18))
            for i, c in enumerate(cols):
                sd.rectangle((10 + i * 90, r * 110 + 28, 90 + i * 90, r * 110 + 88), fill=c["hex"])
                sd.text((12 + i * 90, r * 110 + 90), c["hex"], fill=INK, font=font(13))
        sw.save(os.path.join(d, "palette.png"), optimize=True)
        # expressions board from the in-game portraits
        pd = os.path.join(ROOT, "game/art/portraits", cid)
        if os.path.isdir(pd):
            names = [n[:-4] for n in sorted(os.listdir(pd)) if n.endswith(".png") and n != "default.png"]
            if names:
                cs = 256
                ex = Image.new("RGB", (len(names) * (cs + 10) + 10, cs + 50), BG)
                ed = ImageDraw.Draw(ex)
                for i, n in enumerate(names):
                    ex.paste(Image.open(os.path.join(pd, n + ".png")).convert("RGB").resize((cs, cs)), (10 + i * (cs + 10), 10))
                    ed.text((14 + i * (cs + 10), cs + 16), n, fill=INK, font=font(20))
                save_optimized(ex, os.path.join(d, "expressions.png"), quality="75-100")
        print("refpack", cid, [v for v, _ in views])


if __name__ == "__main__":
    main()
