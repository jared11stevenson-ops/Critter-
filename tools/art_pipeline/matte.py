"""CRITTER art pipeline — shared matting helpers.

Cut-out = isnet-anime (rembg) matte  x  parchment flood-fill  x  connected-component selection,
followed by colour decontamination (removes the beige fringe), colour bleed into transparent pixels
(so mipmaps never pull parchment back in) and trimming.

All boxes / polygons are in SOURCE SHEET pixel coordinates.
"""
import os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "tools", "source_art")

_session = None


def sheet(name):
    return Image.open(os.path.join(SRC, name)).convert("RGB")


def rembg_alpha(img):
    """isnet-anime matte, float32 0..1. Falls back to None if rembg is unavailable."""
    global _session
    try:
        from rembg import remove, new_session
    except Exception:
        return None
    if _session is None:
        _session = new_session("isnet-anime")
    # The model wants context: pad the crop to a square canvas of the border colour so a figure
    # that fills its box is still recognised as a subject.
    arr = np.asarray(img)
    bgc = tuple(int(v) for v in border_bg_color(arr))
    w, h = img.size
    side = int(max(w, h) * 1.3)
    canvas = Image.new("RGB", (side, side), bgc)
    ox, oy = (side - w) // 2, (side - h) // 2
    canvas.paste(img, (ox, oy))
    m = remove(canvas, session=_session, only_mask=True)
    m = np.asarray(m, dtype=np.float32)[oy:oy + h, ox:ox + w] / 255.0
    return m


def border_bg_color(arr):
    b = np.concatenate([arr[0], arr[-1], arr[:, 0], arr[:, -1]])
    return np.median(b, axis=0)


def flood_bg(arr, bg, thr):
    """Parchment-coloured pixels connected to the crop border (bool)."""
    d = np.sqrt(((arr.astype(np.float32) - bg) ** 2).sum(-1))
    near = d < thr
    lab, n = ndi.label(near)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    return np.isin(lab, list(edge)), d


def poly_mask(shape, polys, offset):
    """Rasterise polygons (sheet coords) into a bool mask of the crop."""
    h, w = shape
    im = Image.new("L", (w, h), 0)
    dr = ImageDraw.Draw(im)
    for p in polys:
        if len(p) == 4 and not isinstance(p[0], (list, tuple)):
            x0, y0, x1, y1 = p
            p = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]
        dr.polygon([(x - offset[0], y - offset[1]) for x, y in p], fill=255)
    return np.asarray(im) > 0


def select_components(binary, join_dist=6, min_frac=0.0015, seed_point=None):
    """Keep the main silhouette plus nearby fragments (antenna tips, lantern chains)."""
    lab, n = ndi.label(binary, structure=np.ones((3, 3)))
    if n == 0:
        return binary
    areas = ndi.sum(binary, lab, index=np.arange(1, n + 1))
    if seed_point is not None and lab[seed_point[1], seed_point[0]] > 0:
        main = lab[seed_point[1], seed_point[0]]
    else:
        main = int(np.argmax(areas)) + 1
    keep = lab == main
    total = areas.max()
    changed = True
    while changed:
        changed = False
        grown = ndi.binary_dilation(keep, iterations=join_dist)
        touching = np.unique(lab[grown & binary & ~keep])
        for t in touching:
            if t == 0:
                continue
            if areas[t - 1] >= min_frac * total or areas[t - 1] >= 12:
                keep |= lab == t
                changed = True
    return keep


def cut(img_full, box, exclude=(), include=None, flood_thr=34.0, join_dist=6, min_frac=0.0015,
        use_flood=True, alpha_lo=0.18, alpha_hi=0.82, seed=None, erode=0, bg=None, fill_holes_max=0, flood_regions=(), hole_regions=(), method="auto", pocket_k=0.8, pocket_min=30,
        dark_regions=(), dark_color=(22, 22, 26), dark_thr=(22, 48)):
    """Return an RGBA PIL image (same size as the box crop) with a clean matte."""
    x0, y0, x1, y1 = box
    img = img_full.crop(box)
    arr = np.asarray(img).astype(np.float32)
    h, w = arr.shape[:2]
    a = rembg_alpha(img)
    bgc = np.array(bg, np.float32) if bg is not None else border_bg_color(arr)
    fb, dist = flood_bg(arr, bgc, flood_thr)
    method_used = "rembg"
    fg_cov = float((~fb).mean())
    if a is None or (method == "auto" and float((a > 0.5).mean()) < 0.6 * fg_cov) or method == "flood":
        # model failed (non-humanoid creature on parchment): pure parchment flood matte
        method_used = "flood"
        hard = ~fb
        # enclosed parchment pockets (between legs, under arms)
        pockets = hard & (dist < flood_thr * pocket_k)
        pockets = ndi.binary_opening(pockets, iterations=1)
        lab, n = ndi.label(pockets)
        if n:
            sizes = ndi.sum(pockets, lab, index=np.arange(1, n + 1))
            big = np.isin(lab, np.nonzero(sizes >= pocket_min)[0] + 1)
            hard = hard & ~ndi.binary_dilation(big, iterations=1)
        soft = ndi.gaussian_filter(hard.astype(np.float32), 0.6)
        a = np.where(hard, np.maximum(soft, 0.55), soft * 0.8)
    if use_flood and method_used == "rembg":
        # parchment connected to the outside is background, unless the model is very sure
        a = np.where(fb & (a < 0.97), a * 0.15, a)
    # figure painted over a dark sheet panel: key against the panel colour inside these polys
    if dark_regions:
        dr_m = poly_mask((h, w), dark_regions, (x0, y0))
        dc = np.array(dark_color, np.float32)
        dd = np.sqrt(((arr - dc) ** 2).sum(-1))
        ka = np.clip((dd - dark_thr[0]) / (dark_thr[1] - dark_thr[0]), 0, 1)
        ka = ndi.median_filter(ka, size=3)
        a = np.where(dr_m, ka, a)
    # thin details the model misses (crown stalks, antennae): trust the flood-fill inside these polys
    if flood_regions:
        fr = poly_mask((h, w), flood_regions, (x0, y0))
        ff = ndi.binary_erosion(~fb, iterations=1)
        ff = ndi.binary_opening(ff, iterations=1) | (ff & (dist > flood_thr * 2.5))
        a = np.where(fr, np.maximum(a * ~fb, ff.astype(np.float32)), a)
    # enclosed parchment pockets (between horns, under arms): remove bg-coloured pixels in these polys
    if hole_regions:
        hr = poly_mask((h, w), hole_regions, (x0, y0))
        pocket = hr & (dist < flood_thr * 1.2)
        pocket = ndi.binary_opening(pocket, iterations=1)
        a = np.where(ndi.binary_dilation(pocket, iterations=1) & hr, a * 0.0, a)
    # explicit exclusions / inclusion window
    if exclude:
        a[poly_mask((h, w), exclude, (x0, y0))] = 0
    if include is not None:
        a[~poly_mask((h, w), include, (x0, y0))] = 0
    # remap soft alpha (kills faint shadow haze)
    a = np.clip((a - alpha_lo) / (alpha_hi - alpha_lo), 0, 1)
    binary = a > 0.5
    sp = None if seed is None else (seed[0] - x0, seed[1] - y0)
    keep = select_components(binary, join_dist, min_frac, sp)
    if fill_holes_max:
        holes = ndi.binary_fill_holes(keep) & ~keep
        lab, n = ndi.label(holes)
        if n:
            sizes = ndi.sum(holes, lab, index=np.arange(1, n + 1))
            for i, s in enumerate(sizes):
                if s <= fill_holes_max:
                    keep |= lab == (i + 1)
                    a[lab == (i + 1)] = 1.0
    keep_soft = ndi.binary_dilation(keep, iterations=1)
    a = a * keep_soft
    if erode:
        core = ndi.binary_erosion(a > 0.5, iterations=erode)
        a = np.where(core, a, np.minimum(a, ndi.binary_dilation(core, iterations=1) * 0.5))
    rgb = decontaminate(arr, a, bgc)
    rgb = bleed(rgb, a)
    out = np.dstack([rgb, a * 255.0]).clip(0, 255).astype(np.uint8)
    im = Image.fromarray(out, "RGBA")
    im.info["method"] = method_used
    return im


def decontaminate(arr, a, bgc):
    """Un-mix the parchment from semi-transparent edge pixels; darken the rim slightly toward ink."""
    rgb = arr.copy()
    edge = (a > 0.02) & (a < 0.98)
    aa = np.maximum(a[..., None], 0.35)
    f = (arr - (1.0 - aa) * bgc) / aa
    rgb[edge] = np.clip(f[edge], 0, 255)
    # pull rim pixels toward the nearest solid pixel colour if they are still parchment-ish
    solid = a >= 0.98
    if solid.any():
        _, (iy, ix) = ndi.distance_transform_edt(~solid, return_indices=True)
        nearest = arr[iy, ix]
        d = np.sqrt(((rgb - bgc) ** 2).sum(-1))
        beige = edge & (d < 60)
        rgb[beige] = nearest[beige] * 0.7 + rgb[beige] * 0.3
    return rgb


def bleed(rgb, a):
    """Extend opaque colours into transparent area so mip/bilinear sampling never shows a halo."""
    solid = a > 0.5
    if not solid.any():
        return rgb
    _, (iy, ix) = ndi.distance_transform_edt(~solid, return_indices=True)
    out = rgb.copy()
    t = a <= 0.5
    out[t] = rgb[iy[t], ix[t]]
    # keep decontaminated edge colours where partially opaque
    part = (a > 0.02) & (a <= 0.5)
    out[part] = rgb[part] * 0.5 + rgb[iy[part], ix[part]] * 0.5
    return out


def trim_pad(im, pad=4, bottom_pad=0, anchor_x=None, max_h=1024):
    """Trim to alpha bbox, pad, centre horizontally on anchor_x (crop coords) or alpha centroid."""
    arr = np.asarray(im)
    al = arr[..., 3] > 8
    ys, xs = np.nonzero(al)
    bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    if anchor_x is None:
        w = arr[..., 3].astype(np.float64)
        anchor_x = (w.sum(0) * np.arange(arr.shape[1])).sum() / max(1.0, w.sum())
    half = max(anchor_x - bx0, bx1 - anchor_x) + pad
    cx0 = int(round(anchor_x - half))
    cx1 = int(round(anchor_x + half))
    W = cx1 - cx0
    H = (by1 - by0) + pad + bottom_pad
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    src = im.crop((bx0, by0, bx1, by1))
    out.paste(src, (bx0 - cx0, pad))
    out = rebleed(out)
    if out.height > max_h:
        s = max_h / out.height
        out = out.resize((max(1, int(out.width * s)), max_h), Image.LANCZOS)
    return out


def rebleed(im):
    arr = np.asarray(im).astype(np.float32)
    a = arr[..., 3] / 255.0
    rgb = bleed(arr[..., :3], a)
    return Image.fromarray(np.dstack([rgb, arr[..., 3]]).clip(0, 255).astype(np.uint8), "RGBA")


def composite_preview(images, labels=None, cell_h=320, bgs=((128, 128, 128), (24, 22, 30), (196, 120, 80))):
    """Contact sheet: each image on each background colour."""
    from PIL import ImageFont
    cells = []
    for im in images:
        s = cell_h / im.height
        r = im.resize((max(1, int(im.width * s)), cell_h), Image.LANCZOS)
        cells.append(r)
    W = sum(c.width * len(bgs) + 12 for c in cells)
    rows = [[]]
    rw = 0
    for c in cells:
        cw = c.width * len(bgs) + 12
        if rw + cw > 2400 and rows[-1]:
            rows.append([])
            rw = 0
        rows[-1].append(c)
        rw += cw
    H = len(rows) * (cell_h + 22)
    Wm = max(sum(c.width * len(bgs) + 12 for c in r) for r in rows)
    sheet_im = Image.new("RGB", (Wm, H), (60, 60, 60))
    dr = ImageDraw.Draw(sheet_im)
    k = 0
    for ri, r in enumerate(rows):
        x = 0
        for c in r:
            for bi, bg in enumerate(bgs):
                tile = Image.new("RGBA", c.size, bg + (255,))
                tile.alpha_composite(c)
                sheet_im.paste(tile.convert("RGB"), (x + bi * c.width, ri * (cell_h + 22)))
            if labels:
                dr.text((x + 2, ri * (cell_h + 22) + cell_h + 4), labels[k], fill=(255, 255, 255))
            x += c.width * len(bgs) + 12
            k += 1
    return sheet_im
