#!/usr/bin/env python3
"""Overlay the model's orthographic silhouette on the sheet's front/side/back cut-outs (same 2.4 m scale).
Usage: python3 tools/modeling/aruun/qa_silhouette.py [out.png]   (reads work/aruun_geo.npz written by build.py)
Cyan outline = model silhouette. Front view: model is shown without Morrow (sheet front holds it in a pose).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from common import raster, refboard as rb  # noqa: E402

H_M = 2.4


def main(out):
    d = np.load(os.path.join(HERE, "work", "aruun_geo.npz"), allow_pickle=True)
    V, T = d["V"], d["T"]
    views = [("side", "side_r"), ("back", "back"), ("front", "front")]
    tiles = []
    for name, vk in views:
        im = rb.load("game/art/characters/aruun/%s.png" % name)
        k = 3
        im = im.resize((im.width * k, im.height * k), Image.LANCZOS)
        ppm = im.height / H_M
        a = np.asarray(im)[:, :, 3] > 128
        # horizontal anchor: centre of the feet columns (bottom 4%)
        rows = a[int(a.shape[0] * 0.96):]
        cols = np.where(rows.any(0))[0]
        if name == "side":
            # side: feet span heel..toe; model ankle is at y=+0.03, toe tip -0.30, heel +0.17 -> centre -0.065
            cx = (cols.min() + cols.max()) / 2 - 0.065 * ppm
        else:
            cx = (cols.min() + cols.max()) / 2
        if name == "front":
            # front: anchor at his left foot (screen right) since Morrow lies to the left
            right_cols = cols[cols > a.shape[1] * 0.5]
            cx = (right_cols.min() + right_cols.max()) / 2 - 0.15 * ppm
        W, Hh = im.width, im.height
        tid, bary, zb, P2 = raster.view_raster(V, T, vk, ppm, W, Hh, (cx, Hh))
        sil = (tid >= 0)
        edge = Image.fromarray((sil * 255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES)
        bg = Image.new("RGBA", (W, Hh), (235, 228, 214, 255))
        bg.alpha_composite(im)
        ov = np.asarray(bg).copy()
        e = np.asarray(edge) > 0
        e = e | np.roll(e, 1, 0) | np.roll(e, 1, 1)
        ov[e] = (0, 200, 255, 255)
        # translucent fill
        fill = sil & ~e
        ov[fill] = (ov[fill] * 0.75 + np.array([0, 160, 255, 255]) * 0.25).astype(np.uint8)
        tiles.append(Image.fromarray(ov))
    Wt = sum(t.width for t in tiles) + 20 * (len(tiles) + 1)
    Ht = max(t.height for t in tiles) + 40
    img = Image.new("RGBA", (Wt, Ht), (255, 255, 255, 255))
    x = 20
    for t in tiles:
        img.alpha_composite(t, (x, Ht - t.height - 20))
        x += t.width + 20
    img.convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/aruun_sil.png")
