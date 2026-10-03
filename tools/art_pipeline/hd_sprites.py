#!/usr/bin/env python3
"""HD character billboards: re-cut every view from Real-ESRGAN x4 (anime_6B) upscales of the model sheets.

Topology + framing come from the tuned x1 matte (matte.cut with the sprite_boxes.json table, exactly as
cut_sprites.py), so exclusions/holes/anchors and the in-game framing (feet on bottom edge, centred, side faces
screen-right, same aspect ratio) are unchanged. The x4 sheet supplies the colour (JPEG noise gone, crisp ink)
and a sub-pixel edge: inside a narrow band around the x1 contour, alpha is re-keyed against the sheet
background at x4 resolution. Edge colour is decontaminated + bled (no parchment halo, mip-safe), then the
view is downsampled (premultiplied Lanczos + light unsharp) to the per-character target height and written as
an optimized (palettized when lossless enough) PNG.

Usage:
  python3 tools/art_pipeline/esrgan_upscale.py <weights.pth> tools/source_art/<sheet> <x4dir>/<sheet stem>.png
  python3 tools/art_pipeline/hd_sprites.py --x4 <x4dir> [id ...] [--preview out.png] [--dry] [--refs]
  --refs also writes design/model_sheets/<id>/hires/<view>_hd.png (<= 1200 px tall, same cut, original paint).
Requires: pillow numpy scipy rembg onnxruntime; optional pngquant + pyoxipng (pip install pngquant-cli pyoxipng).
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageFilter, ImageOps
from scipy import ndimage as ndi

sys.path.insert(0, os.path.dirname(__file__))
import matte  # noqa: E402

ROOT = matte.ROOT
OUT = os.path.join(ROOT, "game", "art", "characters")
CACHE = os.path.join(tempfile.gettempdir(), "critter_hd_cache")
REF_H = 1200

# Target texture height per character (px). Chosen by on-screen size (canon height x camera use) and a
# total pixel budget of <= 1.5x the previous set (3.40 Mpx -> <= 5.1 Mpx). Every view of a character
# shares one height, so the outline/rim (texel based) is consistent when the view switches.
HEIGHTS = {
    "solmara": 768,   # 5.5 m, largest on screen (was 176-186 px: badly magnified)
    "aruun": 576, "cigarra": 576,           # playable, closest to camera, cutscenes
    "pharilux": 512, "bramvex": 512, "mollusk": 512, "nyxaris": 512,
    "dexter": 512, "mara": 512, "nerit": 512, "zephyr": 512,
    "scarlith": 384,  # 12 cm canon; never large on screen
}


def trim_rect(a, pad, anchor_x):
    """Same rectangle matte.trim_pad would produce (crop coords): x0, y0, x1, y1 (may exceed the crop)."""
    ys, xs = np.nonzero(a > 8)
    bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    if anchor_x is None:
        w = a.astype(np.float64)
        anchor_x = (w.sum(0) * np.arange(a.shape[1])).sum() / max(1.0, w.sum())
    half = max(anchor_x - bx0, bx1 - anchor_x) + pad
    return int(round(anchor_x - half)), by0 - pad, int(round(anchor_x + half)), by1


def x1_cut(cid, view, spec, v, sh, bgc):
    os.makedirs(CACHE, exist_ok=True)
    key = os.path.join(CACHE, "%s_%s.png" % (cid, view))
    sig = json.dumps(v, sort_keys=True) + json.dumps(bgc)
    if os.path.exists(key) and open(key + ".sig").read() == sig:
        return Image.open(key)
    kw = {k: v[k] for k in ("exclude", "include", "flood_thr", "join_dist", "min_frac", "use_flood",
                             "alpha_lo", "alpha_hi", "seed", "erode", "fill_holes_max", "flood_regions",
                             "hole_regions", "method", "pocket_k", "pocket_min", "bg", "dark_regions",
                             "dark_color", "dark_thr") if k in v}
    if bgc is not None and "bg" not in kw:
        kw["bg"] = bgc
    im = matte.cut(sh, v["box"], **kw)
    im.save(key)
    open(key + ".sig", "w").write(sig)
    return im


def refine_x4(a1, rgb4, bgc, v, box, k=4):
    """x4 alpha: x1 matte upsampled, edge band re-keyed against the background colour at x4."""
    h4, w4 = rgb4.shape[:2]
    m = np.asarray(Image.fromarray((a1 * 255).astype(np.uint8)).resize((w4, h4), Image.BICUBIC),
                   np.float32) / 255.0
    core = m > 0.5
    inner = ndi.binary_erosion(core, iterations=6)
    near = ndi.maximum_filter(m, size=2 * k + 1) > 0.25        # within ~1 x1 px of the original matte
    d = np.sqrt(((rgb4 - bgc) ** 2).sum(-1))
    lo, hi = float(v.get("flood_thr", 34.0)) * 0.55, float(v.get("flood_thr", 34.0)) * 1.6
    key = np.clip((d - lo) / (hi - lo), 0, 1)
    key = ndi.median_filter(key, size=3)
    if v.get("dark_regions"):
        dr = matte.poly_mask((h4, w4), [[(4 * x, 4 * y) for x, y in p] if isinstance(p[0], (list, tuple))
                                        else [4 * c for c in p] for p in v["dark_regions"]],
                             (4 * box[0], 4 * box[1]))
        key = np.where(dr, m, key)
    a = np.where(inner, 1.0, np.maximum(key * near, np.clip((m - 0.5) * 2.0, 0, 1) * (m > 0.75)))
    a = np.where(near, a, 0.0)
    # never resurrect regions the x1 cut excluded on purpose: limit growth to the dilated x1 matte
    a = np.minimum(a, ndi.binary_dilation(core, iterations=k).astype(np.float32))
    # parchment connected to the crop border (pockets between legs the x1 model kept): background
    if v.get("x4_flood", True):
        bgm = ndi.binary_opening(d < lo * 0.8, iterations=2)
        lab, n = ndi.label(bgm)
        if n:
            edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
            edge = edge[edge > 0]
            outside = ndi.binary_dilation(np.isin(lab, edge), iterations=2)
            a = np.where(outside & ~inner, np.minimum(a, key), a)
    # sheet ground lines / shadow strokes under the feet: thin horizontal structures in the bottom band
    yb = int(h4 * 0.93)
    sol = a[yb:] > 0.35
    keep = ndi.binary_opening(sol, structure=np.ones((11, 1), bool))
    keep = ndi.binary_dilation(keep, iterations=2) & sol
    a[yb:][sol & ~keep] = 0.0
    return a.astype(np.float32)


def downsample(im, size):
    """Premultiplied Lanczos + gentle unsharp on colour; alpha left soft (shader uses scissor 0.5)."""
    arr = np.asarray(im).astype(np.float32) / 255.0
    a = arr[..., 3:4]
    pre = np.dstack([arr[..., :3] * a, a])
    chans = [np.asarray(Image.fromarray(np.ascontiguousarray(pre[..., i], np.float32), "F")
                        .resize(size, Image.LANCZOS), np.float32) for i in range(4)]
    out = np.dstack(chans).clip(0, 1)
    al = out[..., 3]
    rgb = out[..., :3] / np.maximum(al[..., None], 1e-4)
    rgb_im = Image.fromarray((rgb.clip(0, 1) * 255 + 0.5).astype(np.uint8), "RGB")
    rgb_im = rgb_im.filter(ImageFilter.UnsharpMask(radius=1.0, percent=45, threshold=2))
    rgb = np.asarray(rgb_im).astype(np.float32)
    rgb = matte.bleed(rgb, al)
    return Image.fromarray(np.dstack([rgb, al * 255.0 + 0.5]).clip(0, 255).astype(np.uint8), "RGBA")


def save_optimized(im, path, quality="88-100"):
    """Palettize with pngquant when it stays near-lossless, then oxipng; falls back to plain optimize."""
    tmp = path + ".tmp.png"
    im.save(tmp, optimize=True)
    pq = shutil.which("pngquant")
    if pq:
        r = subprocess.run([pq, "--quality", quality, "--speed", "1", "--strip", "--force",
                            "--output", tmp + ".q.png", tmp], capture_output=True)
        if r.returncode == 0 and os.path.getsize(tmp + ".q.png") < os.path.getsize(tmp):
            os.replace(tmp + ".q.png", tmp)
        elif os.path.exists(tmp + ".q.png"):
            os.remove(tmp + ".q.png")
    try:
        import oxipng
        oxipng.optimize(tmp, level=4)
    except Exception:
        pass
    os.replace(tmp, path)


def main():
    argv = sys.argv[1:]
    x4dir = argv[argv.index("--x4") + 1] if "--x4" in argv else os.path.join(CACHE, "x4")
    preview = argv[argv.index("--preview") + 1] if "--preview" in argv else None
    dry = "--dry" in argv
    refs = "--refs" in argv
    skip = {x4dir, preview}
    ids = [a for a in argv if not a.startswith("--") and a not in skip]
    with open(os.path.join(os.path.dirname(__file__), "sprite_boxes.json")) as f:
        table = json.load(f)
    with open(os.path.join(ROOT, "game", "canon", "canon.json")) as f:
        cn = json.load(f)["characters"]
    ids = ids or [k for k in table if not k.startswith("_")]
    previews, labels = [], []
    total = 0
    for cid in ids:
        spec = table[cid]
        sh = matte.sheet(spec["sheet"])
        sh4 = Image.open(os.path.join(x4dir, os.path.splitext(spec["sheet"])[0] + ".png")).convert("RGB")
        assert sh4.size == (sh.width * 4, sh.height * 4), (cid, sh4.size)
        bgc = None
        if "bg_sample" in spec:
            bx, by = spec["bg_sample"]
            bgc = np.median(np.asarray(sh.crop((bx - 3, by - 3, bx + 4, by + 4))).reshape(-1, 3), axis=0).tolist()
        H = HEIGHTS.get(cid, 512)
        odir = os.path.join(OUT, cid)
        views, sizes = [], {}
        for view in ("front", "side", "back"):
            v = spec["views"].get(view)
            if not v:
                continue
            box = v["box"]
            c1 = x1_cut(cid, view, spec, v, sh, bgc)
            a1u8 = np.asarray(c1)[..., 3]
            ax = v.get("anchor_x")
            r = trim_rect(a1u8, 4, None if ax is None else ax - box[0])
            W1, H1 = r[2] - r[0], r[3] - r[1]
            # x4 crop of the box, refined alpha, decontaminated colour
            crop4 = sh4.crop(tuple(4 * c for c in box))
            rgb4 = np.asarray(crop4).astype(np.float32)
            bg = np.array(v.get("bg", bgc if bgc is not None else matte.border_bg_color(np.asarray(sh.crop(box)))),
                          np.float32)
            a4 = refine_x4(a1u8.astype(np.float32) / 255.0, rgb4, bg, v, box)
            rgb4 = matte.decontaminate(rgb4, a4, bg)
            rgb4 = matte.bleed(rgb4, a4)
            im4 = Image.fromarray(np.dstack([rgb4, a4 * 255.0]).clip(0, 255).astype(np.uint8), "RGBA")
            # identical framing to the x1 trim (same rect x4, transparent outside the crop)
            canvas = Image.new("RGBA", (4 * W1, 4 * H1), (0, 0, 0, 0))
            canvas.paste(im4, (-4 * r[0], -4 * r[1]))
            canvas = matte.rebleed(canvas)
            if refs:   # hi-res reference view for 3D work (design/model_sheets/<id>/hires/), <= REF_H tall
                rd = os.path.join(ROOT, "design", "model_sheets", cid, "hires")
                os.makedirs(rd, exist_ok=True)
                rh = min(REF_H, canvas.height)
                ref = downsample(canvas, (max(1, round(canvas.width * rh / canvas.height)), rh))
                save_optimized(ImageOps.mirror(ref) if v.get("flip") else ref, os.path.join(rd, view + "_hd.png"))
            Ht = min(H, 1024, 4 * H1)
            Wt = max(1, int(round(W1 * Ht / H1)))
            out = downsample(canvas, (Wt, Ht))
            if v.get("flip"):
                out = ImageOps.mirror(out)
            total += Wt * Ht
            if dry:   # preview copies only, game files untouched
                os.makedirs(os.path.join(CACHE, "dry", cid), exist_ok=True)
                save_optimized(out, os.path.join(CACHE, "dry", cid, view + ".png"))
            else:
                save_optimized(out, os.path.join(odir, view + ".png"))
            views.append(view)
            sizes[view] = [Wt, Ht]
            previews.append(out)
            labels.append("%s/%s %dx%d (x1 %dx%d)" % (cid, view, Wt, Ht, W1, H1))
            print("hd", cid, view, (Wt, Ht), "x1", (W1, H1), "aspect d=%.4f" % (Wt / Ht - W1 / H1), flush=True)
        if not dry:
            meta = {"height_m": cn.get(cid, {}).get("height_m", 1.8), "views": views, "px": sizes,
                    "feet_y_px": sizes["front"][1] if "front" in sizes else None,
                    "source": {k: spec["views"][k].get("source", "") for k in views}, "sheet": spec["sheet"],
                    "hd": "Real-ESRGAN x4 anime_6B re-cut (tools/art_pipeline/hd_sprites.py)"}
            mp = os.path.join(odir, "meta.json")
            if os.path.exists(mp):
                old = json.load(open(mp))
                meta["height_m"] = old.get("height_m", meta["height_m"])
            with open(mp, "w") as f:
                json.dump(meta, f, indent=1)
    print("total px %.2f M" % (total / 1e6))
    if preview:
        matte.composite_preview(previews, labels, cell_h=360).save(preview)
        print("preview", preview)


if __name__ == "__main__":
    main()
