#!/usr/bin/env python3
"""Real-ESRGAN x4 (anime_6B) of only the sheet regions the pipeline uses -> full-size x4 canvas.

Upscales the union of every box in sprite_boxes.json + portrait_boxes.json (+ --extra boxes) for each sheet,
padded with context, and pastes the results into a black canvas of exactly 4x the sheet size, so all x4
consumers (hd_sprites.py, cut_portraits.py --x4, reference packs) can use plain box*4 coordinates.
3-10x faster than upscaling the whole sheet (most of a sheet is lore panels we never cut).

Usage: esrgan_regions.py <weights.pth> <out_dir> [sheet ...] [--extra sheet:x0,y0,x1,y1 ...]
Weights: RealESRGAN_x4plus_anime_6B.pth (github.com/xinntao/Real-ESRGAN releases v0.2.2.4).
"""
import json
import os
import sys

import numpy as np
import torch
from PIL import Image
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(__file__))
from esrgan_upscale import Net  # noqa: E402

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PAD = 16


def regions():
    sp = json.load(open(os.path.join(HERE, "sprite_boxes.json")))
    pb = json.load(open(os.path.join(HERE, "portrait_boxes.json")))
    reg = {}
    for k, v in sp.items():
        if not k.startswith("_"):
            for vv in v["views"].values():
                reg.setdefault(v["sheet"], []).append(vv["box"])
    for v in pb["portraits"].values():
        reg.setdefault(v["sheet"], []).extend(v["boxes"].values())
    for v in pb["icons"].values():
        reg.setdefault(v["sheet"], []).append(v["box"])
    return reg


def run(net, img, tile=192, pad=12):
    t = torch.from_numpy(np.asarray(img, np.float32) / 255.0).permute(2, 0, 1)[None]
    H, W = img.height, img.width
    out = np.zeros((H * 4, W * 4, 3), np.float32)
    with torch.no_grad():
        for y in range(0, H, tile):
            for x in range(0, W, tile):
                y0, x0 = max(y - pad, 0), max(x - pad, 0)
                y1, x1 = min(y + tile + pad, H), min(x + tile + pad, W)
                o = net(t[:, :, y0:y1, x0:x1])[0].permute(1, 2, 0).numpy()
                ty, tx = min(tile, H - y), min(tile, W - x)
                out[y * 4:(y + ty) * 4, x * 4:(x + tx) * 4] = \
                    o[(y - y0) * 4:(y - y0 + ty) * 4, (x - x0) * 4:(x - x0 + tx) * 4]
    return Image.fromarray((out.clip(0, 1) * 255 + 0.5).astype(np.uint8))


def main():
    a = sys.argv[1:]
    extra = {}
    if "--extra" in a:
        i = a.index("--extra")
        for e in a[i + 1:]:
            s, b = e.split(":")
            extra.setdefault(s, []).append([int(v) for v in b.split(",")])
        a = a[:i]
    weights, out = a[0], a[1]
    reg = regions()
    for s, bs in extra.items():
        reg.setdefault(s, []).extend(bs)
    sheets = a[2:] or sorted(reg)
    os.makedirs(out, exist_ok=True)
    net = Net()
    sd = torch.load(weights, map_location="cpu")
    net.load_state_dict(sd.get("params_ema", sd))
    net.eval()
    for s in sheets:
        dst = os.path.join(out, os.path.splitext(s)[0] + ".png")
        src = Image.open(os.path.join(ROOT, "tools", "source_art", s)).convert("RGB")
        W, H = src.size
        need = np.zeros((H, W), bool)
        for b in reg.get(s, []):
            need[max(0, b[1] - PAD):min(H, b[3] + PAD), max(0, b[0] - PAD):min(W, b[2] + PAD)] = True
        done = np.zeros((H, W), bool)
        canvas = None
        if os.path.exists(dst):   # incremental: keep what an earlier run already upscaled
            canvas = Image.open(dst).convert("RGB")
            if canvas.size != (4 * W, 4 * H):
                canvas = None
            else:
                done = np.asarray(canvas.resize((W, H), Image.NEAREST)).max(-1) > 0
                done = ndi.binary_erosion(done, iterations=2)
        if canvas is None:
            canvas = Image.new("RGB", (4 * W, 4 * H), (0, 0, 0))
        todo = need & ~done
        lab, n = ndi.label(todo)
        for sl in ndi.find_objects(lab):
            y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
            cy0, cx0, cy1, cx1 = max(0, y0 - 8), max(0, x0 - 8), min(H, y1 + 8), min(W, x1 + 8)
            up = run(net, src.crop((cx0, cy0, cx1, cy1)))
            # paste only the requested rect (the 8 px context ring avoids border artifacts)
            canvas.paste(up.crop((4 * (x0 - cx0), 4 * (y0 - cy0), 4 * (x1 - cx0), 4 * (y1 - cy0))), (4 * x0, 4 * y0))
            print(s, "region", (x0, y0, x1, y1), flush=True)
        canvas.save(dst)
        print("x4", s, "%.0f%% of sheet" % (100 * need.mean()), flush=True)


if __name__ == "__main__":
    main()
