#!/usr/bin/env python3
"""Fast textured preview (numpy z-buffer + bilinear albedo + lambert): python3 prev_tex.py out.png [full|head] [workdir]"""
import os, sys
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import raster, texbake as TB
out = sys.argv[1]; mode = sys.argv[2] if len(sys.argv) > 2 else "full"
W3 = os.path.join(HERE, "..", "work", "v3")
d = np.load(os.path.join(W3, "game_mesh.npz"), allow_pickle=True); V, T, UV = d["V"], d["T"], d["UV"]
alb = np.asarray(Image.open(os.path.join(W3, "albedo.png")).convert("RGB"), np.float32)
S = alb.shape[0]
N = TB.vertex_normals(V, T)
def sample(uv):
    x = uv[:, 0] * S - 0.5; y = (1 - uv[:, 1]) * S - 0.5
    x0 = np.clip(np.floor(x).astype(int), 0, S - 2); y0 = np.clip(np.floor(y).astype(int), 0, S - 2); fx = (x - x0)[:, None]; fy = (y - y0)[:, None]
    return (alb[y0, x0] * (1 - fx) * (1 - fy) + alb[y0, x0 + 1] * fx * (1 - fy) + alb[y0 + 1, x0] * (1 - fx) * fy + alb[y0 + 1, x0 + 1] * fx * fy)
views = [("side_r", "side_r"), ("front", "front"), ("back", "back")]
tiles = []
if mode == "full":
    ppm, Wp, Hp, org, z0 = 330, 460, 830, (230, 800), 0.0
    cfg = [("front", (230 - 0.085 * 0, 800)), ("side_r", (240, 800)), ("back", (230, 800))]
else:
    ppm, Wp, Hp = 1300, 640, 700
    cfg = [("front", None), ("side_r", None), ("back", None)]
for view, _ in cfg:
    if mode == "full":
        tid, bary, zb, P2 = raster.view_raster(V, T, view, ppm, Wp, Hp, (230, 800))
    else:
        # head crop centred at (0.085, -0.15, 2.07)
        cx = 0.085 if view != "side_r" else 0.15
        sxc = {"front": 0.085, "back": -0.085, "side_r": 0.15}[view]
        tid, bary, zb, P2 = raster.view_raster(V, T, view, ppm, Wp, Hp, (Wp / 2 - sxc * ppm, Hp / 2 + 2.08 * ppm))
    img = np.full((Hp, Wp, 3), (60, 58, 62), np.float32)
    m = tid >= 0
    t = tid[m]; b = bary[m]; tv = T[t]
    uv = np.einsum("nk,nkc->nc", b, UV[tv]); col = sample(uv)
    nn = np.einsum("nk,nkc->nc", b, N[tv]); nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-9)
    cam = {"front": np.array([0, -1, 0.]), "back": np.array([0, 1, 0.]), "side_r": np.array([-1, 0, 0.])}[view]
    L1 = cam * 0.6 + np.array([0.35, 0, 0.7]) * (1 if view != "back" else -1) * np.array([1, 1, 1]); L1 = L1 / np.linalg.norm(L1)
    lam = np.clip(nn @ L1, 0, 1) * 0.65 + 0.42 + 0.12 * np.clip(nn @ cam, 0, 1)
    img[m] = np.clip(col * lam[:, None], 0, 255)
    tiles.append(Image.fromarray(img.astype(np.uint8)))
im = Image.new("RGB", (sum(t.width for t in tiles), tiles[0].height)); x = 0
for t in tiles: im.paste(t, (x, 0)); x += t.width
im.save(out)
