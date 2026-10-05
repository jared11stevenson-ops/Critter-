#!/usr/bin/env python3
"""Aruun v2 stage 1: silhouette-driven non-rigid fit of the legacy body mesh to the sheet's side + back views.

For each view: SDF(old silhouette) -> SDF(sheet silhouette) TV-L1 optical flow (skimage), sampled at every vertex's
projection; side gives (dy,dz), back gives (dx,dz); iterate. Rig weights stay valid (same vertices).
  python3 tools/modeling/aruun/v2/fit.py   -> work/v2/fit.npz + qa/v2_fit_overlay.png
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from skimage.registration import optical_flow_tvl1

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import raster
from common.sheetfit import View

WORK = os.path.join(HERE, "..", "work", "v2")
SHEET = os.path.join(ROOT, "design", "model_sheets", "aruun")
PPM = 160.0      # working resolution (px/m)
ZMAX = 2.08      # fit below this height only (horns are hand-built)


def largest(mask):
    lab, n = ndi.label(mask)
    if n <= 1:
        return mask
    sz = ndi.sum(mask, lab, range(1, n + 1))
    return lab == (1 + int(np.argmax(sz)))


def sheet_mask(view, kind):
    m = largest(view.mask)
    ys, xs = np.where(m)
    return m


def to_work(view, m, W, H, u0w, v0w):
    """sheet mask (own ppm) -> working grid with origin (u0w, v0w) px, PPM."""
    s = PPM / view.ppm
    im = Image.fromarray((m * 255).astype(np.uint8)).resize((int(view.W * s), int(view.H * s)), Image.BILINEAR)
    a = np.asarray(im) > 127
    out = np.zeros((H, W), bool)
    # place so that view.u0,v0 -> u0w,v0w
    ou = int(round(u0w - view.u0 * s)); ov = int(round(v0w - view.v0 * s))
    h, w = a.shape
    y0, x0 = max(ov, 0), max(ou, 0)
    y1, x1 = min(ov + h, H), min(ou + w, W)
    out[y0:y1, x0:x1] = a[y0 - ov:y1 - ov, x0 - ou:x1 - ou]
    return out


def sdf(m):
    d = ndi.distance_transform_edt(m) - ndi.distance_transform_edt(~m)
    return np.clip(d, -25, 25).astype(np.float32)


def proj(V, kind, u0w, v0w):
    if kind == "side":
        u = u0w - V[:, 1] * PPM
    else:
        u = u0w - V[:, 0] * PPM
    return u, v0w - V[:, 2] * PPM


def render_sil(V, T, kind, W, H, u0w, v0w):
    vk = "side_r" if kind == "side" else "back"
    tid, _, _, _ = raster.view_raster(V, T, vk, PPM, W, H, (u0w, v0w))
    return tid >= 0


def main():
    old = np.load(os.path.join(WORK, "old.npz"), allow_pickle=True)
    V0 = old["V"].astype(np.float64); T = old["T"]; parts = list(old["parts"]); pot = old["part_of_tri"]
    excl = [i for i, p in enumerate(parts) if p.startswith("morrow") or p.split(".")[0] in ("horn", "tine")]
    body_tri = ~np.isin(pot, excl)
    Tb = T[body_tri]
    W_, H_ = 340, int(2.6 * PPM)
    v0w = H_ - 6.0
    views = {}
    for kind, f in (("side", "side_x4.png"), ("back", "back_x4.png")):
        v = View(os.path.join(SHEET, "hires", f), kind, 2.4)
        views[kind] = v
    # sheet masks cut at ZMAX; back view: drop mace remnants by keeping largest component
    tgt = {}
    u0 = {"side": 0.46 * W_, "back": 0.5 * W_}
    for kind, v in views.items():
        m = sheet_mask(v, kind)
        tgt[kind] = to_work(v, m, W_, H_, u0[kind], v0w)
        tgt[kind][: int(v0w - ZMAX * PPM)] = False
    V = V0.copy()
    # initial alignment: shift old model so IoU max (u0 search per view)
    off = {}
    for kind in ("side", "back"):
        best = (-1, 0)
        for du in range(-30, 31, 2):
            s = render_sil(V, Tb, kind, W_, H_, u0[kind] + du, v0w)
            s[: int(v0w - ZMAX * PPM)] = False
            iou = (s & tgt[kind]).sum() / (s | tgt[kind]).sum()
            if iou > best[0]:
                best = (iou, du)
        off[kind] = best[1]
        print(kind, "initial IoU %.3f shift %d px" % best)
    # world frame: keep old model's frame; the target masks are shifted to match
    for kind in ("side", "back"):
        u0[kind] += off[kind]
    hist = []
    for it in range(4):
        disp = np.zeros_like(V); cnt = np.zeros(len(V)); ious = []
        for kind in ("side", "back"):
            s = render_sil(V, Tb, kind, W_, H_, u0[kind], v0w)
            cut = int(v0w - ZMAX * PPM)
            s[:cut] = False
            ious.append((s & tgt[kind]).sum() / (s | tgt[kind]).sum())
            a, b = sdf(s), sdf(tgt[kind])
            vf, uf = optical_flow_tvl1(a, b, attachment=10, tightness=0.3, num_warp=6, num_iter=20, tol=1e-4, prefilter=True)
            uu, vv = proj(V, kind, u0[kind], v0w)
            fu = ndi.map_coordinates(uf, [vv, uu], order=1, mode="nearest")
            fv = ndi.map_coordinates(vf, [vv, uu], order=1, mode="nearest")
            lim = 0.9
            fu = np.clip(fu, -30, 30) * lim; fv = np.clip(fv, -30, 30) * lim
            sel = V[:, 2] < ZMAX + 0.05
            if kind == "side":
                disp[:, 1] += -fu / PPM * sel; 
            else:
                disp[:, 0] += -fu / PPM * sel
            disp[:, 2] += -fv / PPM * sel
            cnt += 0.5 * sel
        disp[:, 2] *= 1.0   # both views contributed 1x each; average z
        disp[:, 2] *= 0.5
        V = V + disp
        hist.append(ious)
        print("iter", it, "IoU side %.3f back %.3f" % tuple(ious), "max move %.3f" % np.abs(disp).max())
    # Morrow rides the right hand: rigid shift by the mean displacement of the right hand, not the warp
    hand = [i for i, p in enumerate(parts) if p in ("hand.R",)]
    vh = np.unique(T[np.isin(pot, hand)])
    shift = (V[vh] - V0[vh]).mean(0)
    mv = np.unique(T[np.isin(pot, [i for i, p in enumerate(parts) if p.startswith("morrow")])])
    V[mv] = V0[mv] + shift
    # final iou
    fin = []
    for kind in ("side", "back"):
        s = render_sil(V, Tb, kind, W_, H_, u0[kind], v0w); s[: int(v0w - ZMAX * PPM)] = False
        fin.append((s & tgt[kind]).sum() / (s | tgt[kind]).sum())
    print("final IoU side %.3f back %.3f" % tuple(fin))
    np.savez(os.path.join(WORK, "fit.npz"), V=V, V0=V0, u0side=u0["side"], u0back=u0["back"])
    # overlay board: sheet mask (grey) + old (blue) / fitted (red) outlines
    tiles = []
    for kind in ("side", "back"):
        for lab, VV in (("old", V0), ("fit", V)):
            s = render_sil(VV, Tb, kind, W_, H_, u0[kind], v0w); s[: int(v0w - ZMAX * PPM)] = False
            img = np.full((H_, W_, 3), 235, np.uint8)
            img[tgt[kind]] = (150, 150, 150)
            edge = s & ~ndi.binary_erosion(s)
            img[edge] = (230, 30, 30)
            tiles.append(Image.fromarray(img))
    out = Image.new("RGB", (W_ * 4 + 30, H_), (255, 255, 255))
    for i, t in enumerate(tiles):
        out.paste(t, (i * (W_ + 10), 0))
    p = os.path.join(SHEET, "qa", "v2_fit_overlay.png")
    out.save(p); print("wrote", p)


if __name__ == "__main__":
    main()
