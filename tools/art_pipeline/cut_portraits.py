#!/usr/bin/env python3
"""Cut dialogue portraits and ability icons from the model sheets.

Usage: python3 tools/art_pipeline/cut_portraits.py [--x4 <dir of Real-ESRGAN x4 sheets>] [--preview out.png]
Writes game/art/portraits/<id>/<expression>.png (+ default.png) and game/art/icons/<ability>.png.
With --x4, every crop is taken from the x4 upscale of the sheet (box coords x4) and DOWN-sampled to 256
(crisp lines, no JPEG blocks) instead of up-sampling a 60-140 px crop; output is palettized (pngquant).
"""
import json
import os
import sys
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import matte  # noqa: E402
from hd_sprites import save_optimized  # noqa: E402

ROOT = matte.ROOT
SIZE = 256


def border_color(im):
    a = np.asarray(im.convert("RGB")).reshape(-1, 3) if False else np.asarray(im.convert("RGB"))
    b = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    return tuple(int(v) for v in np.median(b, axis=0))


def square(im, fill):
    w, h = im.size
    if max(w, h) / min(w, h) <= 1.42:
        if w > h:
            x = (w - h) // 2
            return im.crop((x, 0, x + h, h))
        y = int((h - w) * 0.3)
        return im.crop((0, y, w, y + w))
    s = max(w, h)
    out = Image.new("RGB", (s, s), fill)
    # bottom-aligned (busts sit on the panel floor)
    out.paste(im, ((s - w) // 2, s - h))
    if w < s:
        # soften the pad seam with a short horizontal blend
        arr = np.asarray(out).astype(np.float32)
        x0 = (s - w) // 2
        x1 = x0 + w
        for i in range(6):
            t = (i + 1) / 7.0
            if x0 + i < s:
                arr[:, x0 + i] = arr[:, x0 + i] * t + np.array(fill) * (1 - t)
            if x1 - 1 - i >= 0:
                arr[:, x1 - 1 - i] = arr[:, x1 - 1 - i] * t + np.array(fill) * (1 - t)
        out = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
    return out


def upscale(im, size=SIZE):
    up = im.width < size
    im = im.resize((size, size), Image.LANCZOS)
    if up:
        return im.filter(ImageFilter.UnsharpMask(radius=1.6, percent=70, threshold=2))
    return im.filter(ImageFilter.UnsharpMask(radius=0.9, percent=45, threshold=2))


X4 = sys.argv[sys.argv.index("--x4") + 1] if "--x4" in sys.argv else None
_sheets = {}


def get_sheet(name):
    """(image, scale): the x4 upscale when available, else the original sheet."""
    if name not in _sheets:
        p = X4 and os.path.join(X4, os.path.splitext(name)[0] + ".png")
        if p and os.path.exists(p):
            _sheets[name] = (Image.open(p).convert("RGB"), 4)
        else:
            if X4:
                print("WARNING: no x4 sheet for", name, "- using original")
            _sheets[name] = (matte.sheet(name), 1)
    return _sheets[name]


def save(im, path):
    save_optimized(im, path, quality="80-100")


def main():
    with open(os.path.join(os.path.dirname(__file__), "portrait_boxes.json")) as f:
        table = json.load(f)
    previews = []
    for cid, spec in table["portraits"].items():
        sh, k = get_sheet(spec["sheet"])
        odir = os.path.join(ROOT, "game", "art", "portraits", cid)
        os.makedirs(odir, exist_ok=True)
        ins = spec.get("inset", 0)
        for name, box in spec["boxes"].items():
            x0, y0, x1, y1 = box
            crop = sh.crop((k * (x0 + ins), k * (y0 + ins), k * (x1 - ins), k * (y1 - ins)))
            out = upscale(square(crop, border_color(crop)))
            save(out, os.path.join(odir, name + ".png"))
            if name == spec["default"]:
                save(out, os.path.join(odir, "default.png"))
            previews.append((cid + "/" + name, out))
        print("portraits", cid, list(spec["boxes"].keys()))
    idir = os.path.join(ROOT, "game", "art", "icons")
    os.makedirs(idir, exist_ok=True)
    for aid, spec in table["icons"].items():
        sh, k = get_sheet(spec["sheet"])
        crop = sh.crop(tuple(k * c for c in spec["box"]))
        out = upscale(square(crop, border_color(crop)))
        save(out, os.path.join(idir, aid + ".png"))
        previews.append(("icon/" + aid, out))
    print("icons", list(table["icons"].keys()))
    if "--preview" in sys.argv:
        p = sys.argv[sys.argv.index("--preview") + 1]
        cols = 10
        rows = (len(previews) + cols - 1) // cols
        cs = 160
        sheet_im = Image.new("RGB", (cols * (cs + 4), rows * (cs + 16)), (40, 40, 40))
        d = ImageDraw.Draw(sheet_im)
        for i, (lab, im) in enumerate(previews):
            x, y = (i % cols) * (cs + 4), (i // cols) * (cs + 16)
            sheet_im.paste(im.resize((cs, cs)), (x, y))
            d.text((x + 2, y + cs + 2), lab, fill=(255, 255, 255))
        sheet_im.save(p)


if __name__ == "__main__":
    main()
