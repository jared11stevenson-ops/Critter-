"""Shared helpers for the reference-pack tools (Pillow/numpy/scipy/torch CPU/rembg only; see design/ART_TOOLING.md)."""
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
WEIGHTS = next((p for p in ("/tmp/RealESRGAN_x4plus_anime_6B.pth", "/tmp/claude-0/up/RealESRGAN_x4plus_anime_6B.pth") if os.path.exists(p)), None)
CACHE = os.environ.get("REFSHEET_CACHE", "/home/user/critter/.claude/refsheet_cache")
os.makedirs(CACHE, exist_ok=True)
PACKS = os.path.join(ROOT, "design", "reference_packs")
BG = (232, 223, 204)
INK = (40, 30, 28)


def font(sz, bold=True):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def esrgan_rgb(img, tile=256):
    """Real-ESRGAN anime_6B x4 on an RGB PIL image (cached by content hash)."""
    import hashlib, esrgan_upscale as E
    h = hashlib.md5(img.tobytes() + str(img.size).encode()).hexdigest()
    cp = os.path.join(CACHE, f"x4_{h}.png")
    if os.path.exists(cp):
        return Image.open(cp).convert("RGB")
    tmp = os.path.join(CACHE, f"in_{h}.png"); img.convert("RGB").save(tmp)
    E.upscale(WEIGHTS, tmp, cp, tile=tile)
    os.remove(tmp)
    return Image.open(cp).convert("RGB")


def flood_bg(rgba):
    """Fill fully transparent pixels with the nearest opaque colour so ESRGAN sees no halo."""
    a = np.asarray(rgba).copy()
    m = a[..., 3] < 8
    if not m.any():
        return Image.fromarray(a[..., :3])
    idx = ndimage.distance_transform_edt(m, return_distances=False, return_indices=True)
    rgb = a[..., :3][tuple(idx)]
    return Image.fromarray(rgb)


def upscale_rgba(rgba, factor=4):
    """x4 ESRGAN on colour (background-filled), alpha resampled + re-sharpened."""
    rgb = esrgan_rgb(flood_bg(rgba))
    al = rgba.getchannel("A").resize(rgb.size, Image.LANCZOS)
    a = np.asarray(al).astype(np.float32) / 255
    a = np.clip((a - 0.5) * 2.2 + 0.5, 0, 1)          # keep edges crisp after resample
    a = ndimage.gaussian_filter(a, 0.8)
    a = np.clip((a - 0.5) * 2.0 + 0.5, 0, 1)
    out = rgb.convert("RGBA"); out.putalpha(Image.fromarray((a * 255).astype(np.uint8)))
    return out


def largest(rgba, min_frac=0.0, keep_near=0):
    a = np.asarray(rgba).copy()
    lab, n = ndimage.label(a[..., 3] > 20)
    if n > 1:
        s = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1)); keep = 1 + int(np.argmax(s))
        km = lab == keep
        if keep_near:
            km = ndimage.binary_dilation(km, iterations=keep_near)
            labs = np.unique(lab[km & (lab > 0)])
            km = np.isin(lab, labs)
        a[~km, 3] = 0
    return Image.fromarray(a)


_sess = None


def cut_bg(rgb):
    """rembg isnet-anime background removal."""
    global _sess
    from rembg import remove, new_session
    if _sess is None:
        _sess = new_session("isnet-anime")
    return remove(rgb, session=_sess, post_process_mask=True)


def trim(rgba, pad=0):
    bb = rgba.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
    return rgba.crop((max(bb[0] - pad, 0), max(bb[1] - pad, 0), bb[2] + pad, bb[3] + pad)) if bb else rgba


def save_png(img, path, colors=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def label(draw, xy, text, sz=28, fill=INK):
    draw.text(xy, text, font=font(sz), fill=fill)


def save_art(im, path):
    """Flat-colour sheet art: 256-colour RGBA PNG (octree). ~5x smaller than 32-bit with no visible change on cel art (keeps packs < 25 MB)."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im = im.convert("RGBA")
    if im.getchannel("A").getextrema()[0] == 255:
        im.convert("RGB").quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)
    else:
        im.quantize(256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(path, optimize=True)
