#!/usr/bin/env python3
"""Stage 1: master cuts. For each view of a character: (re)cut from the original sheet (ESRGAN x4 -> rembg isnet-anime -> cleanup)
or take the audited hires cut. Result cached in $REFSHEET_CACHE/<id>/cut_<view>.png (RGBA, ~4x sheet res). Sheet panels (details,
expressions) are ESRGAN x4 (+ rembg when marked) and cached as panel_<name>.png.  usage: stage1_cuts.py <id> [views|panels ...]"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST


def main(cid, only=None):
    c = CAST[cid]; d = os.path.join(CACHE, cid); os.makedirs(d, exist_ok=True)
    sheet = Image.open(os.path.join(ROOT, c["sheet"])).convert("RGB")
    for v, s in c["views"].items():
        if only and v not in only: continue
        out = os.path.join(d, f"cut_{v}.png")
        if os.path.exists(out): continue
        if "hires" in s:
            im = Image.open(os.path.join(ROOT, s["hires"])).convert("RGBA")
        else:
            x4 = esrgan_rgb(sheet.crop(s["box"]))
            im = largest(cut_bg(x4), keep_near=int(s.get("near", 6)))
            im = trim(im)
            if "erase" in s:      # re-apply an audited erase mask (e.g. Aruun's Morrow) by registering the old cut onto the new one
                from skimage.registration import phase_cross_correlation
                ref = Image.open(os.path.join(ROOT, s["erase"]["ref"])).convert("RGBA"); mk = Image.open(os.path.join(ROOT, s["erase"]["mask"])).convert("L")
                full = esrgan_rgb_cut_full = None
                # canvas big enough for both, compare at 1/4 scale on alpha
                def pad(a, W, H):
                    o = np.zeros((H, W), np.float32); o[:a.shape[0], :a.shape[1]] = a; return o
                A = np.asarray(ref.getchannel("A"), np.float32) / 255; B = np.asarray(im.getchannel("A"), np.float32) / 255
                W, H = max(A.shape[1], B.shape[1]), max(A.shape[0], B.shape[0])
                A4 = pad(A, W, H)[::4, ::4]; B4 = pad(B, W, H)[::4, ::4]
                sh, _, _ = phase_cross_correlation(B4, A4, upsample_factor=4)   # shift to move ref onto new
                dy, dx = int(round(sh[0] * 4)), int(round(sh[1] * 4)); print("erase-mask registration shift", dx, dy)
                m = Image.new("L", im.size, 0); m.paste(mk, (dx, dy))
                a = np.asarray(im).copy(); a[np.asarray(m) > 0, 3] = 0; im = trim(largest(Image.fromarray(a), keep_near=0))
        trim(im).save(out); print("cut", cid, v, im.size, flush=True)
    for p, (box, bg) in c.get("sheet_panels", {}).items():
        if only and p not in only: continue
        out = os.path.join(d, f"panel_{p}.png")
        if os.path.exists(out): continue
        x4 = esrgan_rgb(sheet.crop(box))
        if bg == "center":      # keep the connected component under the panel centre (isolates one head from touching neighbours)
            cut = cut_bg(x4); a = np.asarray(cut).copy(); lab, n = ndimage.label(a[..., 3] > 20)
            if n > 1:
                H, W = lab.shape; core = lab[H // 4:3 * H // 4, W // 3:2 * W // 3]; ids = core[core > 0]
                keep = int(np.bincount(ids).argmax()) if len(ids) else 1
                a[lab != keep, 3] = 0
            x4 = trim(Image.fromarray(a))
        elif bg: x4 = trim(largest(cut_bg(x4), keep_near=8))
        x4.save(out); print("panel", cid, p, x4.size, flush=True)


def upgrade(cid):
    """Second Real-ESRGAN x4 pass (slow on CPU, ~5-10 min per view) so the 4096-px export is downsampled, not stretched. Writes cut_<view>_up.png;
    ortho.py prefers it when present."""
    for v in CAST[cid]["views"]:
        src = os.path.join(CACHE, cid, f"cut_{v}.png"); dst = os.path.join(CACHE, cid, f"cut_{v}_up.png")
        if os.path.exists(dst) or not os.path.exists(src): continue
        im = Image.open(src).convert("RGBA")
        if im.height >= 1800: continue
        trim(largest(upscale_rgba(im), keep_near=0)).save(dst); print("up", cid, v, flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "up":
        for cid in sys.argv[2:]: upgrade(cid)
        sys.exit()
    main(sys.argv[1], sys.argv[2:] or None)
