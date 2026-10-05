#!/usr/bin/env python3
"""Aruun v2 stage 2: project the sheet's side/back/front paint onto the fitted mesh's UV atlas (numpy only).
  python3 tools/modeling/aruun/v2/project.py [size]  -> work/v2/albedo_proj.png, work/v2/proj_weight.png
Visibility via z-buffer per view, weight = cos^2 (grazing < 0.25 rejected), sheet alpha edge eroded; unseen texels
are filled from neighbours (dilate) and a palette blur."""
import os, sys, time
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import raster
from common.sheetfit import View
import fit as F

WORK = os.path.join(HERE, "..", "work", "v2")
SHEET = os.path.join(ROOT, "design", "model_sheets", "aruun")
POW = 8


def views():
    fz = np.load(os.path.join(WORK, "fit.npz"))
    out = {}
    for kind, f, u0o in (("side", "side_x4.png", 0.46 * F.W_ if hasattr(F, "W_") else 156.4), ("back", "back_x4.png", 170.0)):
        v = View(os.path.join(SHEET, "hires", f), kind, 2.4)
        s = F.PPM / v.ppm
        u0f = float(fz["u0side" if kind == "side" else "u0back"])
        v.mask = F.largest(v.mask)
        v.u0 = v.u0 + (u0f - u0o) / s
        out[kind] = v
    return out


def zbuf(V, T, vk, view, scale=0.5):
    ppm = view.ppm * scale
    W, H = int(view.W * scale), int(view.H * scale)
    tid, _, zb, _ = raster.view_raster(V, T, vk, ppm, W, H, (view.u0 * scale, view.v0 * scale))
    return zb, scale



def front_register(V, T, fk):
    """SDF-flow registration of the sheet's 3/4 front view onto the mesh's orthographic front silhouette.
    returns dict with flow arrays + mapping params."""
    from skimage.registration import optical_flow_tvl1
    PPM = F.PPM; Wg, Hg = 360, int(2.6 * PPM); v0w = Hg - 6.0; u0w = 0.5 * Wg
    v = View(os.path.join(SHEET, "hires", "front_clean_x4.png"), "front", 2.4)
    mk = F.largest(v.mask)
    s = PPM / v.ppm
    # mesh body silhouette (no cards/morrow)
    body = np.array([str(k).split("|")[1] in ("trunk", "armL", "armR", "legL", "legR") for k in fk])
    tid, _, _, _ = raster.view_raster(V, T[body], "front", PPM, Wg, Hg, (u0w, v0w))
    sil = tid >= 0
    zc = int(v0w - F.ZMAX * PPM); sil[:zc] = False
    # sheet mask in work grid (initial: centroid-aligned in the torso band)
    im = Image.fromarray((mk * 255).astype(np.uint8)).resize((int(v.W * s), int(v.H * s)), Image.BILINEAR)
    a = np.asarray(im) > 127
    ys, xs = np.where(a)
    band = slice(int(a.shape[0] - 1.7 * PPM), int(a.shape[0] - 0.9 * PPM))
    cx_sheet = np.where(a[band].any(0))[0].mean() if a[band].any() else a.shape[1] / 2
    ys2, xs2 = np.where(sil[int(v0w - 1.7 * PPM):int(v0w - 0.9 * PPM)])
    cx_mesh = xs2.mean()
    ou = int(round(cx_mesh - cx_sheet)); ov = int(round(v0w - a.shape[0]))
    tgt = np.zeros((Hg, Wg), bool)
    y0, x0 = max(ov, 0), max(ou, 0); y1, x1 = min(ov + a.shape[0], Hg), min(ou + a.shape[1], Wg)
    tgt[y0:y1, x0:x1] = a[y0 - ov:y1 - ov, x0 - ou:x1 - ou]
    tgt[:zc] = False
    A, B = F.sdf(sil), F.sdf(tgt)
    vf, uf = optical_flow_tvl1(A, B, attachment=4, tightness=0.3, num_warp=6, num_iter=25, tol=1e-4, prefilter=True)
    iou0 = (sil & tgt).sum() / (sil | tgt).sum()
    from scipy.ndimage import map_coordinates
    yy, xx = np.mgrid[0:Hg, 0:Wg].astype(np.float32)
    warped = map_coordinates(tgt.astype(np.float32), [yy + vf, xx + uf], order=1) > 0.5
    print("front reg IoU %.3f -> %.3f" % (iou0, (sil & warped).sum() / (sil | warped).sum()))
    return dict(view=v, s=s, ou=ou, ov=ov, uf=uf, vf=vf, u0w=u0w, v0w=v0w, PPM=PPM, Wg=Wg, Hg=Hg, zbuf=raster.view_raster(V, T[body], "front", PPM, Wg, Hg, (u0w, v0w))[2])

def main(size=2048):
    t0 = time.time()
    m = np.load(os.path.join(WORK, "game_mesh.npz"), allow_pickle=True)
    V, T, UVc = m["V"].astype(np.float64), m["T"], m["UVc"]
    from common.splat import vertex_normals
    Vn = vertex_normals(V, T)
    fk = m["facekinds"]
    nT = len(T)
    tid, bary = raster.uv_raster(UVc.reshape(-1, 2), np.arange(nT * 3).reshape(-1, 3), size)
    ok = tid >= 0
    tt = tid[ok]; b = bary[ok]
    P = np.einsum("nk,nkc->nc", b, V[T[tt]])
    N = np.einsum("nk,nkc->nc", b, Vn[T[tt]]); N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    print("texels", ok.sum(), "raster %.1fs" % (time.time() - t0))
    vs = views()
    acc = np.zeros((len(P), 3)); wsum = np.zeros(len(P)); cmax = np.zeros(len(P))
    srcs = [("side", "side_r", np.array([-1.0, 0, 0])), ("side", "side_l", np.array([1.0, 0, 0])),
            ("back", "back", np.array([0, 1.0, 0]))]
    for kind, vk, d in srcs:
        v = vs[kind]
        cos = N @ d
        # visibility: depth of the texel along view vs z-buffer
        zb, sc = zbuf(V, T, vk if vk != "side_l" else "side_l", v)
        if vk == "side_l":
            # mirrored: the left-side camera looks from +X; screen x = +Y, we sample the sheet at the mirrored y
            sx, dep = P[:, 1], -P[:, 0]
            u = v.u0 * sc + sx * v.ppm * sc * -1.0 * -1.0
            # sheet faces screen-right => y forward negative => u = u0 - y*ppm (same as right side)
            u = (v.u0 - P[:, 1] * v.ppm) * sc
            # zbuffer from side_l: u_buf = u0 + y*ppm
            ub = (v.u0 + P[:, 1] * v.ppm) * sc
        else:
            sx = -P[:, 1] if vk == "side_r" else -P[:, 0]
            dep = P[:, 0] if vk == "side_r" else -P[:, 1]
            u = (v.u0 + sx * v.ppm) * sc; ub = u
        vv = (v.v0 - P[:, 2] * v.ppm) * sc
        ui = np.clip(np.round(ub - 0.5).astype(int), 0, zb.shape[1] - 1)
        vi = np.clip(np.round(vv - 0.5).astype(int), 0, zb.shape[0] - 1)
        # 3x3 min-neighbourhood tolerance
        zmin = ndi.minimum_filter(zb, 3)
        vis = dep <= zmin[vi, ui] + 0.02
        # sheet validity (eroded alpha)
        er = ndi.binary_erosion(v.mask, iterations=3)
        uu = (u / sc); vf = vv / sc
        ui2 = np.clip(np.round(uu - 0.5).astype(int), 0, v.W - 1); vi2 = np.clip(np.round(vf - 0.5).astype(int), 0, v.H - 1)
        valid = er[vi2, ui2]
        w = np.where(vis & valid & (cos > 0.25), cos ** POW, 0.0)
        # sample
        from scipy.ndimage import map_coordinates
        col = np.stack([map_coordinates(v.rgb[:, :, c].astype(np.float32), [vf - 0.5, uu - 0.5], order=1, mode="nearest") for c in range(3)], 1)
        acc += col * w[:, None]; wsum += w; cmax = np.maximum(cmax, np.where(w > 0, cos, 0))
        print(vk, "vis %.2f valid %.2f cos %.2f" % (vis.mean(), valid.mean(), (cos>0.25).mean()), "valid frac %.2f" % ((w > 0).mean()), "%.1fs" % (time.time() - t0))

    # ---- front (registered by silhouette flow)
    fr = front_register(V, T, fk)
    from scipy.ndimage import map_coordinates
    uw = fr["u0w"] + P[:, 0] * fr["PPM"]; vw = fr["v0w"] - P[:, 2] * fr["PPM"]
    fu = map_coordinates(fr["uf"], [vw, uw], order=1, mode="nearest"); fv = map_coordinates(fr["vf"], [vw, uw], order=1, mode="nearest")
    su = uw + fu; sv = vw + fv                       # position in the (scaled, shifted) sheet grid
    v = fr["view"]
    # grid -> sheet px: grid = sheet*s + (ou, ov)
    pu = (su - fr["ou"]) / fr["s"]; pv = (sv - fr["ov"]) / fr["s"]
    cos = N @ np.array([0, -1.0, 0])
    zbf = fr["zbuf"]
    ui = np.clip(np.round(uw - 0.5).astype(int), 0, zbf.shape[1] - 1); vi = np.clip(np.round(vw - 0.5).astype(int), 0, zbf.shape[0] - 1)
    zmin = ndi.minimum_filter(zbf, 5)
    vis = P[:, 1] <= zmin[vi, ui] + 0.03
    er = ndi.binary_erosion(F.largest(v.mask), iterations=4)
    pui = np.clip(np.round(pu - 0.5).astype(int), 0, v.W - 1); pvi = np.clip(np.round(pv - 0.5).astype(int), 0, v.H - 1)
    valid = er[pvi, pui]
    conf = np.exp(-np.hypot(fu, fv) / 14.0)
    w = np.where(vis & valid & (cos > 0.25), (cos * conf) ** POW * 1.5, 0.0)
    col = np.stack([map_coordinates(v.rgb[:, :, c].astype(np.float32), [pv - 0.5, pu - 0.5], order=1, mode="nearest") for c in range(3)], 1)
    acc += col * w[:, None]; wsum += w; cmax = np.maximum(cmax, np.where(w > 0, cos, 0))
    print("front used frac %.3f" % (w > 0).mean())
    img = np.zeros((size, size, 3), np.float32); W = np.zeros((size, size), np.float32)
    col = acc / np.maximum(wsum, 1e-6)[:, None]
    img[ok] = col; W[ok] = cmax
    Image.fromarray(np.clip(W * 255, 0, 255).astype(np.uint8)).save(os.path.join(WORK, "proj_weight.png"))
    have = W > 0.2
    # fill: dilate colours into unseen texels
    filled, mask = raster.dilate(img.astype(np.float32), have, iters=24)
    out = np.where(mask[..., None], filled, 0.0)
    # legacy Morrow: copy the old procedural paint through the old UVs (same triangles)
    old = np.load(os.path.join(WORK, "mesh_fit.npz"), allow_pickle=True)
    oparts = list(old["parts"]); opot = old["part_of_tri"]; oUV = old["UVc"]
    sel = [i for i, p in enumerate(oparts) if p.startswith(("cloak_hood", "cloak_back", "cloak_tail", "leaf_dark", "leaf_olive", "strip_cord", "strip_cream", "strip_olive", "band_cream", "talisman", "beads", "cloth_sash", "pommel")) or p.startswith("morrow")]
    otri = np.concatenate([np.where(opot == pi)[0] for pi in sel if (opot == pi).any()])
    kind_of_tri = np.array([str(k).split("|")[1] for k in fk])
    leg = np.where(np.isin(kind_of_tri, ["morrow", "card"]))[0]
    assert len(leg) == len(otri), (len(leg), len(otri))
    oalb = np.asarray(Image.open(os.path.join(ROOT, "game/art/models/aruun/aruun_aruun_albedo.webp")).convert("RGB")).astype(np.float32)
    osz = oalb.shape[0]
    tid_m = tid[ok]
    is_mor = np.isin(kind_of_tri[tt], ["morrow"])
    if is_mor.any():
        ot = otri[np.searchsorted(leg, tt[is_mor])]
        buv = np.einsum("nk,nkc->nc", b[is_mor], oUV[ot])
        px = np.clip((buv[:, 0] * osz).astype(int), 0, osz - 1); py = np.clip(((1 - buv[:, 1]) * osz).astype(int), 0, osz - 1)
        mc = oalb[py, px]
        ii = np.argwhere(ok)[is_mor]
        out[ii[:, 0], ii[:, 1]] = mc
        mask[ii[:, 0], ii[:, 1]] = True
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(WORK, "albedo_proj.png"))
    print("coverage seen %.3f of covered %.3f" % (have.sum() / ok.sum() if ok.sum() else 0, 0), "done %.1fs" % (time.time() - t0))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 2048)
