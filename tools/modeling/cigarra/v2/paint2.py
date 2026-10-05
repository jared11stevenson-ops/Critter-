#!/usr/bin/env python3
"""Cigarra v2 paint driver: bake game_mesh.npz -> work/v2/{albedo,emissive,orm,normal}.png (2048) + wing.png/wing_emissive.png (512x1024)"""
import os, sys, time
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, HERE)
from common import texbake as TB, raster
import paint_cig as PC
W2 = os.path.join(HERE, "..", "work", "v2")


def main():
    t0 = time.time()
    d = np.load(os.path.join(W2, "game_mesh.npz"), allow_pickle=True)
    V, T, UV = d["V"], d["T"], d["UV"]
    fk = d["facekinds"]; names = np.array([str(k).split("|")[0] for k in fk]); kinds = np.array([str(k).split("|")[1] for k in fk])
    keep = kinds != "wing"
    B = TB.Bake(V, T[keep], UV, 2048, d["sparam"])
    nm_t, kd_t = names[keep][B.tri], kinds[keep][B.tri]
    H = np.load(os.path.join(W2, "head_raw.npz")); O, sc = H["origin"], float(H["scale"])
    n = B.n; col = np.tile(np.array([120., 100, 110]), (n, 1)); emis = np.zeros((n, 3)); rough = np.full(n, 0.6); hgt = np.zeros(n)
    def put(sel, c, r, h=None, e=None):
        col[sel] = c; rough[sel] = r
        if h is not None: hgt[sel] = h
        if e is not None: emis[sel] = e
    s = kd_t == "skull"; c, e, r, h = PC.paint_skull(B.P[s], B.N[s], O, sc); put(s, c, r, h, e)
    s = kd_t == "eye"; c, e, r, h = PC.paint_eye(B.P[s], B.N[s], O, sc); put(s, c, r, h, e)
    for k in ("body", "hand"):
        s = kd_t == k; c, r, h = PC.paint_body(B.P[s], B.N[s], k); put(s, c, r, h)
    for nm in np.unique(nm_t[kd_t == "card"]):
        s = nm_t == nm; P_, N_, sp = B.P[s], B.N[s], B.sp[s]
        if nm.startswith("hair_"): c, r = PC.paint_hair(sp, P_); e = None
        elif nm.startswith("crown"): c, r, e = PC.paint_crown(nm, P_, N_)
        else: c, r, e = PC.paint_cloth(nm, sp, P_, N_)
        put(s, c, r, None, e)
    alb = B.finish(col); em = B.finish(emis)
    orm = B.finish(np.stack([np.full(n, 255.), rough * 255, np.zeros(n)], 1))
    hi = B.image(hgt[:, None], ch=1)[:, :, 0]; hd, _ = raster.dilate(hi, B.mask, 10)
    nrm = TB.height_to_normal(ndi.gaussian_filter(hd, 0.6), 2.0)
    for nme, arr in (("albedo", alb), ("emissive", em), ("orm", orm), ("normal", nrm)):
        Image.fromarray(arr).save(os.path.join(W2, nme + ".png"))
    wa, we = PC.paint_wings(1024)
    H_, Wd_ = wa.shape[:2]; tw = Wd_ // 2; ys, xs = np.mgrid[0:H_, 0:tw]; b = (ys + 0.5) / H_; a = (xs + 0.5) / tw
    al = np.full((H_, Wd_), 255, np.uint8)
    for tile in (0, 1):
        rag = 0.955 - 0.035 * (0.5 + 0.5 * np.sin(a * 37.0 + tile * 2.0) * np.sin(a * 11.0 + 1.0))
        al[:, tile * tw:(tile + 1) * tw] = np.where(b > rag, 0, 255)
    Image.fromarray(np.dstack([wa, al]), "RGBA").save(os.path.join(W2, "wing_rgba.png"))
    Image.fromarray(wa).save(os.path.join(W2, "wing.png")); Image.fromarray(we).save(os.path.join(W2, "wing_emissive.png"))
    print("painted", round(time.time() - t0, 1), "s")


if __name__ == "__main__":
    main()
