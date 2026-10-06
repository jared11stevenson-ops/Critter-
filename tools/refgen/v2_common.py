"""Shared helpers for design/reference_gen/aruun/v2 (non-diffusion). Class maps: 0=empty, 1=GREEN original pixel, 2=YELLOW inferred/completed from other views, 3=RED unknown / nearest-neighbour fill."""
import os, sys, json, numpy as np, cv2
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rast import *
OUT = os.path.join(ROOT, 'design/reference_gen/aruun/v2')
ORTHO = os.path.join(ROOT, 'design/reference_packs/aruun/ortho')
GREEN, YELLOW, RED = (60, 200, 70), (250, 215, 20), (235, 40, 40)
TINT = {1: GREEN, 2: YELLOW, 3: RED}

def load_rgba(path):
    im = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if im.shape[2] == 3: im = np.dstack([im, np.full(im.shape[:2], 255, np.uint8)])
    return im   # BGRA

def save_rgba(path, im): os.makedirs(os.path.dirname(path), exist_ok=True); cv2.imwrite(path, im)

def overlay(rgba, cls, bg=(150, 150, 150), alpha=0.55):
    a = rgba[..., 3:] / 255.0
    base = (rgba[..., :3] * a + np.array(bg[::-1], float) * (1 - a))
    out = base.copy()
    for k, c in TINT.items():
        m = cls == k
        out[m] = base[m] * (1 - alpha) + np.array(c[::-1], float) * alpha
    return out.astype(np.uint8)

def pcts(cls):
    n = (cls > 0).sum()
    return {k: round(float((cls == v).sum() / max(n, 1) * 100), 2) for k, v in (('green', 1), ('yellow', 2), ('red', 3))}

def write_set(name, rgba, cls, meta, outdir=OUT):
    """writes {name}.png, {name}_derivation.png, {name}.json"""
    save_rgba(os.path.join(outdir, name + '.png'), rgba)
    save_rgba(os.path.join(outdir, name + '_derivation.png'), overlay(rgba, cls))
    cv2.imwrite(os.path.join(outdir, name + '_classmap.png'), cls.astype(np.uint8) * 80)
    meta = dict(meta); meta['percent_of_painted_pixels'] = pcts(cls); meta['legend'] = 'GREEN=original sheet pixels, YELLOW=inferred/completed/warped from other views, RED=unknown (nearest-neighbour fill)'
    meta['canvas'] = dict(width_px=int(rgba.shape[1]), height_px=int(rgba.shape[0]), px_per_m=PPM, ground_row=GROUND, note='same scale/ground row as reference_packs/aruun/ortho; x_offset_px = columns added at the left of the original cut (axis_x_px shifts by the same amount)')
    json.dump(meta, open(os.path.join(outdir, name + '.json'), 'w'), indent=1)
    return meta['percent_of_painted_pixels']
