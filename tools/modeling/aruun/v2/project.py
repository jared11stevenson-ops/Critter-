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
SMOOTH_N = 40


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
    """Row-wise affine registration of the sheet's 3/4 front onto the mesh's orthographic front: vertical by the sheet's
    landmark rows (piecewise linear), horizontal by per-row silhouette extents (smoothed, clipped).
    Returns f(x, z) -> (pu, pv) in sheet px, the sheet View, and the front z-buffer."""
    PPM = F.PPM; Wg = 360; Hg = int(2.6 * PPM); v0w = Hg - 6.0; u0w = 0.5 * Wg
    v = View(os.path.join(SHEET, "hires", "front_clean_x4.png"), "front", 2.4)
    v.mask = F.largest(v.mask)
    lm = __import__("json").load(open(os.path.join(SHEET, "landmarks.json")))
    zs = lm["canonical_heights_m"]; rows = lm["view_rows_px"]["front"]
    names = ["horn_tip", "cranium_top", "jaw", "neck_base", "shoulder", "elbow", "waist", "crotch", "knee", "ankle", "sole"]
    zz = np.array([zs[n] for n in names]); rr = np.array([rows[n] for n in names], float)
    rr_h = v.top + rr / rows["sole"] * (v.bot - v.top)          # hires rows
    order = np.argsort(zz); zz, rr_h = zz[order], rr_h[order]
    body = np.array([str(k).split("|")[1] in ("trunk", "armL", "armR", "legL", "legR") for k in fk])
    tid, _, zb, _ = raster.view_raster(V, T[body], "front", PPM, Wg, Hg, (u0w, v0w))
    sil = tid >= 0
    zgrid = (v0w - (np.arange(Hg) + 0.5)) / PPM
    mc = np.full(Hg, np.nan); mw = np.full(Hg, np.nan)
    for i in range(Hg):
        c = np.where(sil[i])[0]
        if len(c) and 0.05 < zgrid[i] < F.ZMAX:
            mc[i] = (c.min() + c.max()) / 2; mw[i] = c.max() - c.min() + 1
    vrow_of_z = np.interp(zgrid, zz, rr_h)
    sc_ = np.full(Hg, np.nan); sw_ = np.full(Hg, np.nan)
    for i in range(Hg):
        r = int(round(vrow_of_z[i]))
        if 0 <= r < v.H:
            c = np.where(v.mask[r])[0]
            if len(c):
                sc_[i] = (c.min() + c.max()) / 2; sw_[i] = c.max() - c.min() + 1
    ok_ = ~np.isnan(mc) & ~np.isnan(sc_)
    idx = np.arange(Hg)
    def fill(a):
        a = a.copy(); m = ~np.isnan(a)
        return np.interp(idx, idx[m], a[m])
    mc, mw, sc_, sw_ = fill(mc), fill(mw), fill(sc_), fill(sw_)
    ks = np.clip((sw_ / v.ppm) / (mw / PPM), 0.6, 1.5)
    from scipy.ndimage import gaussian_filter1d
    mc_s = gaussian_filter1d(mc, 6); sc_s = gaussian_filter1d(sc_, 6); k_s = gaussian_filter1d(ks, 10)
    # horizontal scale: use sheet px per world metre = v.ppm * k
    def f(x, z):
        i = np.clip(np.round((v0w - z * PPM) - 0.5).astype(int), 0, Hg - 1)
        pu = sc_s[i] + (x * PPM + u0w - mc_s[i]) / PPM * v.ppm * k_s[i]
        pv = np.interp(z, zz, rr_h)
        return pu, pv
    return dict(view=v, f=f, zbuf=zb, PPM=PPM, u0w=u0w, v0w=v0w)

def grade(img, gamma=0.78, sat=1.28):
    x = np.clip(img / 255.0, 0, 1) ** gamma
    g = x.mean(2, keepdims=True)
    x = np.clip(g + (x - g) * sat, 0, 1)
    return x * 255.0


def sheet_palette(vs, k=16):
    px = []
    for v in vs.values():
        m = v.mask
        ys, xs = np.where(m)
        sel = np.random.RandomState(1).choice(len(ys), 60000, replace=False)
        px.append(v.rgb[ys[sel], xs[sel]])
    px = np.concatenate(px)
    im = Image.fromarray(px.reshape(-1, 1, 3).astype(np.uint8))
    q = im.quantize(colors=k, method=Image.Quantize.MEDIANCUT)
    pal = np.array(q.getpalette()[:3 * k], np.float32).reshape(-1, 3)
    return pal


def cel_clean(img, mask, vs, k=16, passes=2, win=7):
    """Quantise to the sheet's own palette and majority-filter -> flat cel regions (kills projection marbling)."""
    pal = sheet_palette(vs, k)
    h, w, _ = img.shape
    d = ((img.reshape(-1, 1, 3) - pal[None]) ** 2).sum(2)
    lab = d.argmin(1).reshape(h, w)
    for _ in range(passes):
        best = np.zeros((h, w), np.float32); out = lab.copy()
        for c in range(len(pal)):
            f = ndi.uniform_filter((lab == c).astype(np.float32), win)
            upd = f > best
            out[upd] = c; best[upd] = f[upd]
        lab = out
    res = pal[lab]
    res[~mask] = 0
    return res



def hx(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32)


def lerp(a, b, t):
    return a * (1 - t)[:, None] + b * t[:, None]


def paint_procedural(out, ok, tt, b, T, fk, sp):
    """Paint horns / cards from their arc parameter s (no projection)."""
    names = np.array([str(k).split("|")[0] for k in fk])
    s = np.einsum("nk,nk->n", b, sp[T[tt]])
    nm = names[tt]
    col = out[ok].copy()
    def put(mask, c):
        col[mask] = c[mask] if c.ndim == 2 else c
    red, dred, dark, cream = hx("#913f2e"), hx("#5e2a1e"), hx("#2a1812"), hx("#d3ad68")
    m = nm == "horn_R"
    if m.any():
        ring = (np.cos(2 * np.pi * s[m] * 5.0) ** 2) ** 3
        c = lerp(np.tile(red, (m.sum(), 1)), np.tile(dred, (m.sum(), 1)), 0.55 * ring)
        c = lerp(c, np.tile(dark, (m.sum(), 1)), np.clip((s[m] - 0.88) / 0.1, 0, 1) + np.clip((0.07 - s[m]) / 0.07, 0, 1) * 0.8)
        col[m] = c
    m = nm == "horn_L"
    if m.any():
        base = lerp(np.tile(cream, (m.sum(), 1)), np.tile(red, (m.sum(), 1)), np.clip((s[m] - 0.42) / 0.12, 0, 1))
        ring = (np.cos(2 * np.pi * s[m] * 5.0) ** 2) ** 3
        base = lerp(base, np.tile(dred, (m.sum(), 1)), 0.4 * ring)
        base = lerp(base, np.tile(dark, (m.sum(), 1)), np.clip((s[m] - 0.9) / 0.08, 0, 1) + np.clip((0.06 - s[m]) / 0.06, 0, 1) * 0.8)
        col[m] = base
    for key, c0, c1 in (("hp_eye_liner", "#1c1210", "#1c1210"), ("hp_eye", "#e8c840", "#f4de70"), ("hp_tine", "#d8c096", "#a98b5f"), ("hp_crest", "#9a4632", "#5e2a1e"), ("hp_fringe_head", "#d9c27a", "#8a7a44")):
        m = nm == key
        if m.any():
            col[m] = lerp(np.tile(hx(c0), (m.sum(), 1)), np.tile(hx(c1), (m.sum(), 1)), np.clip(s[m], 0, 1))
    m = nm == "card_mantle"
    if m.any():
        col[m] = lerp(np.tile(hx("#51443a"), (m.sum(), 1)), np.tile(hx("#3a2f28"), (m.sum(), 1)), np.clip(s[m], 0, 1))
    m = nm == "card_fringe"
    if m.any():
        col[m] = lerp(np.tile(hx("#bd996f"), (m.sum(), 1)), np.tile(hx("#8f6b45"), (m.sum(), 1)), np.clip(s[m] * 1.1, 0, 1))
    m = nm == "card_leaf_olive"
    if m.any():
        col[m] = lerp(np.tile(hx("#7a6341"), (m.sum(), 1)), np.tile(hx("#a79063"), (m.sum(), 1)), np.clip(s[m], 0, 1))
    m = nm == "card_leaf_dark"
    if m.any():
        col[m] = lerp(np.tile(hx("#2c2218"), (m.sum(), 1)), np.tile(hx("#4e4235"), (m.sum(), 1)), np.clip(s[m], 0, 1))
    m = nm == "card_tassel"
    if m.any():
        col[m] = lerp(np.tile(hx("#c9a97d"), (m.sum(), 1)), np.tile(hx("#e1cfa6"), (m.sum(), 1)), np.clip(s[m], 0, 1))
    out[ok] = col
    return out

def main(size=2048):
    t0 = time.time()
    global EXTRA
    MOR = np.zeros((size, size), bool)
    EXTRA = {"emissive": np.zeros((size, size, 3), np.float32), "orm": np.tile(np.array([255, 175, 0], np.float32), (size, size, 1))}
    m = np.load(os.path.join(WORK, "game_mesh.npz"), allow_pickle=True)
    V, T, UVc = m["V"].astype(np.float64), m["T"], m["UVc"]
    from common.splat import vertex_normals
    Vn = vertex_normals(V, T)
    # large-scale normals: Laplacian-smooth over the welded mesh so view selection is spatially coherent
    import scipy.sparse as sp
    vm = m["vmap"]; Tw = vm[T]; nw = vm.max() + 1
    Vw = np.zeros((nw, 3)); Vw[vm] = V
    Nw = np.zeros((nw, 3)); np.add.at(Nw, vm, Vn); Nw /= np.maximum(np.linalg.norm(Nw, axis=1, keepdims=True), 1e-9)
    E = np.concatenate([Tw[:, [0, 1]], Tw[:, [1, 2]], Tw[:, [2, 0]]]); E = np.concatenate([E, E[:, ::-1]])
    A = sp.coo_matrix((np.ones(len(E)), (E[:, 0], E[:, 1])), shape=(nw, nw)).tocsr(); A.data[:] = 1
    A = sp.diags(1 / np.maximum(A.sum(1).A1, 1)) @ A
    for _ in range(SMOOTH_N):
        Nw = 0.5 * Nw + 0.5 * (A @ Nw)
    Nw /= np.maximum(np.linalg.norm(Nw, axis=1, keepdims=True), 1e-9)
    Vn_s = Nw[vm]
    fk = m["facekinds"]
    nT = len(T)
    tid, bary = raster.uv_raster(UVc.reshape(-1, 2), np.arange(nT * 3).reshape(-1, 3), size)
    ok = tid >= 0
    tt = tid[ok]; b = bary[ok]
    P = np.einsum("nk,nkc->nc", b, V[T[tt]])
    N = np.einsum("nk,nkc->nc", b, Vn[T[tt]]); N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    Ns = np.einsum("nk,nkc->nc", b, Vn_s[T[tt]]); Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-9)
    print("texels", ok.sum(), "raster %.1fs" % (time.time() - t0))
    vs = views()
    acc = np.zeros((len(P), 3)); wsum = np.zeros(len(P)); cmax = np.zeros(len(P))
    srcs = [("side", "side_r", np.array([-1.0, 0, 0])), ("side", "side_l", np.array([1.0, 0, 0])),
            ("back", "back", np.array([0, 1.0, 0]))]
    for kind, vk, d in srcs:
        v = vs[kind]
        cos = Ns @ d
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
        tc = N @ d
        cq = np.minimum(cos, tc)
        w = np.where(vis & valid, np.clip((cq - 0.35) / 0.3, 0, 1) ** 1.0, 0.0) ** 2
        # sample
        from scipy.ndimage import map_coordinates
        col = np.stack([map_coordinates(v.rgb[:, :, c].astype(np.float32), [vf - 0.5, uu - 0.5], order=1, mode="nearest") for c in range(3)], 1)
        acc += col * w[:, None]; wsum += w; cmax = np.maximum(cmax, np.where(vis & valid, cq, 0.0))
        print(vk, "vis %.2f valid %.2f cos %.2f" % (vis.mean(), valid.mean(), (cos>0.25).mean()), "valid frac %.2f" % ((w > 0).mean()), "%.1fs" % (time.time() - t0))

    # ---- front (registered by silhouette flow)
    fr = front_register(V, T, fk)
    from scipy.ndimage import map_coordinates
    v = fr["view"]
    pu, pv = fr["f"](P[:, 0], P[:, 2])
    uw = fr["u0w"] + P[:, 0] * fr["PPM"]; vw = fr["v0w"] - P[:, 2] * fr["PPM"]
    cos = Ns @ np.array([0, -1.0, 0])
    zbf = fr["zbuf"]
    ui = np.clip(np.round(uw - 0.5).astype(int), 0, zbf.shape[1] - 1); vi = np.clip(np.round(vw - 0.5).astype(int), 0, zbf.shape[0] - 1)
    zmin = ndi.minimum_filter(zbf, 5)
    vis = P[:, 1] <= zmin[vi, ui] + 0.03
    er = ndi.binary_erosion(v.mask, iterations=4)
    pui = np.clip(np.round(pu - 0.5).astype(int), 0, v.W - 1); pvi = np.clip(np.round(pv - 0.5).astype(int), 0, v.H - 1)
    valid = er[pvi, pui]
    tcf = N @ np.array([0, -1.0, 0]); cq = np.minimum(cos, tcf)
    w = np.where(vis & valid, np.clip((cq - 0.45) / 0.3, 0, 1), 0.0) ** 2 * 0.8
    col = np.stack([map_coordinates(v.rgb[:, :, c].astype(np.float32), [pv - 0.5, pu - 0.5], order=1, mode="nearest") for c in range(3)], 1)
    acc += col * w[:, None]; wsum += w; cmax = np.maximum(cmax, np.where(vis & valid, cq, 0.0))
    print("front used frac %.3f" % (w > 0).mean())
    col = acc / np.maximum(wsum, 1e-6)[:, None]
    NAVY = np.array([40, 31, 34], np.float32)
    conf = np.clip((cmax - 0.28) / 0.25, 0, 1)[:, None]
    col = col * conf + NAVY * (1 - conf)
    cmax = np.maximum(cmax, 0.5)
    img = np.zeros((size, size, 3), np.float32); W = np.zeros((size, size), np.float32)
    img[ok] = col; W[ok] = cmax
    Image.fromarray(np.clip(W * 255, 0, 255).astype(np.uint8)).save(os.path.join(WORK, "proj_weight.png"))
    have = W > 0.1
    # fill: dilate colours into unseen texels
    filled, mask = raster.dilate(img.astype(np.float32), have, iters=24)
    out = np.where(mask[..., None], filled, 0.0)
    # legacy Morrow: copy the old procedural paint through the old UVs (same triangles)
    old = np.load(os.path.join(WORK, "mesh_fit.npz"), allow_pickle=True)
    oparts = list(old["parts"]); opot = old["part_of_tri"]; oUV = old["UVc"]
    sel = [i for i, p in enumerate(oparts) if p.startswith(("cloak_hood", "cloak_back", "cloak_tail", "leaf_dark", "leaf_olive", "strip_cord", "strip_cream", "strip_olive", "band_cream", "talisman", "beads", "cloth_sash", "pommel")) and False or p.startswith("morrow")]
    otri = np.concatenate([np.where(opot == pi)[0] for pi in sel if (opot == pi).any()])
    kind_of_tri = np.array([str(k).split("|")[1] for k in fk])
    leg = np.where(np.isin(kind_of_tri, ["morrow"]))[0]
    assert len(leg) == len(otri), (len(leg), len(otri))
    oalb = np.asarray(Image.open(os.path.join(WORK, "legacy", "albedo.webp")).convert("RGB")).astype(np.float32)
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
        MOR[ii[:, 0], ii[:, 1]] = True
        mask[ii[:, 0], ii[:, 1]] = True
        for nm in ("emissive", "orm"):
            la = np.asarray(Image.open(os.path.join(WORK, "legacy", nm + ".webp")).convert("RGB")).astype(np.float32)
            side_img = EXTRA[nm]
            side_img[ii[:, 0], ii[:, 1]] = la[py, px]
    out = cel_clean(out, mask, vs, k=28, passes=1, win=3)
    out = np.where(MOR[..., None], out, grade(out))
    out = paint_procedural(out, ok, tt, b, T, fk, m['sparam'])
    # eyes: yellow texels on the head glow a little
    yel = (out[..., 0] > 170) & (out[..., 1] > 140) & (out[..., 2] < 130) & (out[..., 0] - out[..., 2] > 70)
    EXTRA["emissive"][yel & (EXTRA["emissive"].sum(2) == 0)] = out[yel & (EXTRA["emissive"].sum(2) == 0)] * 0.35
    for nm in ("emissive", "orm"):
        Image.fromarray(np.clip(EXTRA[nm], 0, 255).astype(np.uint8)).save(os.path.join(WORK, nm + ".png"))
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(os.path.join(WORK, "albedo_proj.png"))
    print("coverage seen %.3f of covered %.3f" % (have.sum() / ok.sum() if ok.sum() else 0, 0), "done %.1fs" % (time.time() - t0))


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 2048)
