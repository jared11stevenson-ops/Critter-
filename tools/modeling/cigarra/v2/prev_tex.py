#!/usr/bin/env python3
"""python3 prev_tex.py out.png [full|head]  fast textured preview of work/v2 (body atlas + wing texture)"""
import os, sys
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import raster, texbake as TB
out = sys.argv[1]; mode = sys.argv[2] if len(sys.argv) > 2 else "full"
W2 = os.path.join(HERE, "..", "work", "v2")
d = np.load(os.path.join(W2, "game_mesh.npz"), allow_pickle=True); V, T, UV = d["V"], d["T"], d["UV"]
kinds = np.array([str(k).split("|")[1] for k in d["facekinds"]])
albs = {"body": np.asarray(Image.open(os.path.join(W2, "albedo.png")).convert("RGB"), np.float32), "wing": np.asarray(Image.open(os.path.join(W2, "wing.png")).convert("RGB"), np.float32)}
N = TB.vertex_normals(V, T)
def sample(img, uv):
    H_, W_ = img.shape[:2]
    x = np.clip(uv[:, 0] * W_ - 0.5, 0, W_ - 1.001); y = np.clip((1 - uv[:, 1]) * H_ - 0.5, 0, H_ - 1.001)
    x0 = x.astype(int); y0 = y.astype(int); fx = (x - x0)[:, None]; fy = (y - y0)[:, None]
    return img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy
tiles = []
if mode == "full": ppm, Wp, Hp = 400, 520, 780
else: ppm, Wp, Hp = 2200, 640, 700
for view in (sys.argv[3].split(",") if len(sys.argv) > 3 else ["front", "side_r", "back"]):
    if mode == "full": org = (Wp / 2, 740)
    else:
        sxc = {"front": 0.0, "back": 0.0, "side_r": 0.0, "side_l": 0.0}[view]; org = (Wp / 2 - sxc * ppm, Hp / 2 + 1.56 * ppm)
    tid, bary, zb, P2 = raster.view_raster(V, T, view, ppm, Wp, Hp, org)
    img = np.full((Hp, Wp, 3), (88, 96, 108), np.float32); m = tid >= 0
    t = tid[m]; b = bary[m]; tv = T[t]; uv = np.einsum("nk,nkc->nc", b, UV[tv])
    iswing = kinds[t] == "wing"; col = np.zeros((len(t), 3), np.float32)
    col[~iswing] = sample(albs["body"], uv[~iswing]); col[iswing] = sample(albs["wing"], uv[iswing])
    nn = np.einsum("nk,nkc->nc", b, N[tv]); nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    cam = {"front": np.array([0, -1, 0.]), "back": np.array([0, 1, 0.]), "side_r": np.array([-1, 0, 0.]), "side_l": np.array([1, 0, 0.])}[view]
    L1 = cam * 0.6 + np.array([0.35, 0, 0.7]); L1 = L1 / np.linalg.norm(L1)
    lam = np.abs(nn @ L1) * 0.6 + 0.45 + 0.1 * np.abs(nn @ cam)
    img[m] = np.clip(col * lam[:, None], 0, 255); tiles.append(Image.fromarray(img.astype(np.uint8)))
im = Image.new("RGB", (sum(t.width for t in tiles), tiles[0].height)); x = 0
for t in tiles: im.paste(t, (x, 0)); x += t.width
im.save(out)
