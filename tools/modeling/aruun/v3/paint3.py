#!/usr/bin/env python3
"""Aruun v3 paint: bake game_mesh.npz positions into 2048 UV space, paint albedo/emissive/ORM/normal. -> work/v3/{albedo,emissive,orm,normal}.png"""
import os, sys, time
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", "..")); sys.path.insert(0, HERE)
from common import texbake as TB
import paint_head as PH, paint_body as PB, paint_body2 as PB2
from paint_head import smooth, mix
W3 = os.path.join(HERE, "..", "work", "v3")


def main():
    t0 = time.time()
    d = np.load(os.path.join(W3, "game_mesh.npz"), allow_pickle=True)
    V, T, UV = d["V"], d["T"], d["UV"]
    # smooth/shared UV: UV per vertex (vertex-split) already
    fk = d["facekinds"]; names = np.array([str(k).split("|")[0] for k in fk]); kinds = np.array([str(k).split("|")[1] for k in fk])
    B = TB.Bake(V, T, UV, 2048, d["sparam"])
    print("bake", B.n, "texels", round(time.time() - t0, 1), "s")
    nm_t, kd_t = names[B.tri], kinds[B.tri]
    H = np.load(os.path.join(W3, "head_raw.npz")); O, sc = H["origin"], float(H["scale"])
    n = B.n
    kv = np.full(len(V), "", object)
    for t_, kk in enumerate(kinds): kv[T[t_]] = kk
    PB2.set_anchors(V, kv)
    col = np.tile(np.array([60, 50, 55.]), (n, 1)); emis = np.zeros((n, 3)); rough = np.full(n, 0.6); hgt = np.zeros(n)
    def put(sel, c, r, h, e=None):
        col[sel] = c; rough[sel] = r; hgt[sel] = h
        if e is not None: emis[sel] = e
    for k in ("trunk", "armL", "armR", "legL", "legR"):
        s = kd_t == k
        if not s.any(): continue
        P, Nn = B.P[s], B.N[s]
        c, r, h, cls = PB.paint_plated(P, Nn, k, seed={"trunk": 0, "armL": 1, "armR": 2, "legL": 3, "legR": 4}[k])
        c, h, r = PB2.overlays(P, Nn, k, c, h, r)
        c, h = PB.neck_belt(P, Nn, c, h, k)
        put(s, c, r, h)
    s = kd_t == "horn"
    if s.any():
        c, r, h = PB.paint_horn(B.sp[s], B.P[s], B.N[s]); put(s, c, r, h)
    for nm in np.unique(nm_t[kd_t == "card"]):
        s = nm_t == nm; c, r = PB.paint_card(nm, B.sp[s], B.P[s], B.N[s]); put(s, c, r, np.zeros(s.sum()))
    for nm in np.unique(nm_t[kd_t == "morrow"]):
        s = nm_t == nm; c, r = PB.paint_morrow(nm, B.P[s], B.N[s]); put(s, c, r, np.zeros(s.sum()))
    s = kd_t == "skull"; c, e, r, h = PH.paint_skull(B.P[s], B.N[s], O, sc, None); put(s, c, r, h, e)
    s = kd_t == "jaw"; c, e, r, h = PH.paint_jaw(B.P[s], B.N[s], O, sc); put(s, c, r, h, e)
    for k, up in (("tooth_up", True), ("tooth_lo", False)):
        s = kd_t == k; c, e, r, h = PH.paint_tooth(B.P[s], up); put(s, c, r, h, e)
    s = kd_t == "fringe_head"; c, e, r, h = PH.paint_fringe(B.sp[s]); put(s, c, r, h, e)
    s = kd_t == "tine"; c, e, r, h = PH.paint_tine(B.P[s]); put(s, c, r, h, e)
    s = kd_t == "tongue"; c, e, r, h = PH.paint_tongue(B.P[s], B.N[s], O, sc); put(s, c, r, h, e)
    s = kd_t == "eye"; c, e, r, h = PH.paint_eye(B.P[s], B.N[s], O, sc); put(s, c, r, h, e)
    alb = B.finish(col)
    em = B.finish(emis)
    orm = B.finish(np.stack([np.full(n, 255.), rough * 255, np.zeros(n)], 1))
    hi = B.image(hgt[:, None], ch=1)[:, :, 0]
    from common import raster
    hd, _ = raster.dilate(hi, B.mask, 10)
    from scipy import ndimage as ndi
    nrm = TB.height_to_normal(ndi.gaussian_filter(hd, 0.6), 2.2)
    for nme, arr in (("albedo", alb), ("emissive", em), ("orm", orm), ("normal", nrm)):
        Image.fromarray(arr).save(os.path.join(W3, nme + ".png"))
    print("painted", round(time.time() - t0, 1), "s")


if __name__ == "__main__":
    main()
