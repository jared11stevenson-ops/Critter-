"""Shared Pillow helpers for the 3D reference packs (design/model_sheets/<id>/).

Everything here only crops, scales and annotates the approved sheet art -- no invention.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
BG = (238, 230, 214, 255)
INK = (40, 30, 28, 255)


def font(size, bold=False):
    try:
        return ImageFont.truetype(FONT_BOLD if bold else FONT_PATH, size)
    except OSError:
        return ImageFont.load_default()


def rpath(*p):
    return os.path.join(ROOT, *p)


def load(path):
    return Image.open(rpath(path) if not os.path.isabs(path) else path).convert("RGBA")


def sheet_crop(path, box, scale_from=None, k=4):
    """Crop a box (given in `scale_from` sheet-width coordinates) from a sheet and upscale by k."""
    im = load(path)
    if scale_from:
        f = im.width / float(scale_from)
        box = tuple(int(round(v * f)) for v in box)
    c = im.crop(box)
    return c.resize((max(1, int(c.width * k)), max(1, int(c.height * k))), Image.LANCZOS)


def alpha_bbox(im):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 20)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def title_bar(img, text, sub=""):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, img.width, 70], fill=(52, 36, 32, 255))
    d.text((24, 12), text, font=font(34, True), fill=(240, 220, 190, 255))
    if sub:
        d.text((24 + d.textlength(text, font=font(34, True)) + 24, 24), sub, font=font(18), fill=(220, 200, 170, 255))


def label(d, xy, text, size=16, fill=INK, bold=False, anchor="la"):
    d.text(xy, text, font=font(size, bold), fill=fill, anchor=anchor)


def kmeans_colors(pixels, k=3, seed=1):
    from scipy.cluster.vq import kmeans2
    P = pixels.astype(float)
    if len(P) < k:
        return [(tuple(P.mean(0).astype(int)), len(P))]
    c, l = kmeans2(P, k, minit="++", seed=seed)
    cnt = np.bincount(l, minlength=k)
    order = np.argsort(-cnt)
    return [(tuple(np.clip(c[i], 0, 255).astype(int)), int(cnt[i])) for i in order if cnt[i] > 0]


def hexc(c):
    return "#%02x%02x%02x" % tuple(int(v) for v in c[:3])


def region_pixels(im, box):
    a = np.asarray(im.crop(box))
    p = a.reshape(-1, 4)
    return p[p[:, 3] > 230][:, :3]


def paste_fit(dst, im, box, bg=None):
    """Paste im scaled to fit inside box (x0,y0,x1,y1), centered horizontally, bottom-aligned."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    s = min(w / im.width, h / im.height)
    r = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    px = x0 + (w - r.width) // 2
    py = y1 - r.height
    if bg is not None:
        ImageDraw.Draw(dst).rectangle([x0, y0, x1, y1], fill=bg)
    dst.alpha_composite(r, (px, py))
    return px, py, s
