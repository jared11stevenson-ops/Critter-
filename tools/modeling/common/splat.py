"""Fast numpy orthographic preview of dense meshes (vertex splatting + z-buffer + lambert), for sculpt iteration.

views: 'front' (camera at -Y), 'side' (camera at -X; character faces screen-right), 'back' (camera at +Y),
'left' (camera at +X; faces screen-left), or a yaw angle in degrees (0 = front).
"""
import math

import numpy as np
from PIL import Image, ImageDraw


def vertex_normals(V, F):
    n = np.zeros_like(V)
    fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    for k in range(3):
        np.add.at(n, F[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def _view_axes(view):
    yaw = {"front": 0, "side": -90, "back": 180, "left": 90}.get(view, view)
    y = math.radians(yaw)
    cam = np.array([math.sin(y), -math.cos(y), 0.0])      # direction from target to camera
    right = np.array([math.cos(y), math.sin(y), 0.0])
    return cam, right


def render(meshes, view, ppm=300, height=2.5, width=1.4, light=(-0.5, -0.8, 0.9), bg=(236, 228, 214)):
    """meshes: list of (V, F, rgb 0..1). Returns PIL RGBA (transparent bg) with origin at bottom centre."""
    W, H = int(width * ppm), int(height * ppm)
    cam, right = _view_axes(view)
    zb = np.full(H * W, np.inf, dtype=np.float32)
    img = np.zeros((H * W, 3), dtype=np.float32)
    L = np.asarray(light, float)
    L /= np.linalg.norm(L)
    for V, F, col in meshes:
        if len(V) == 0:
            continue
        N = vertex_normals(V.astype(np.float64), F)
        # densify: also splat triangle centroids so coarse meshes still render closed
        C = V[F].mean(1)
        CN = N[F].mean(1)
        P = np.concatenate([V, C])
        PN = np.concatenate([N, CN])
        sx = P @ right
        sz = P[:, 2]
        dep = -(P @ cam)
        px = (W / 2 + sx * ppm).astype(int)
        py = (H - sz * ppm).astype(int)
        shade = np.clip(PN @ L, 0, 1) * 0.75 + 0.25 + 0.15 * np.clip(PN @ cam, 0, 1)
        c = np.clip(np.asarray(col)[None] * shade[:, None], 0, 1)
        for ox in (0, 1):
            for oy in (0, 1):
                x = px + ox
                y = py + oy
                ok = (x >= 0) & (x < W) & (y >= 0) & (y < H)
                idx = y[ok] * W + x[ok]
                d = dep[ok]
                order = np.argsort(-d)            # far first, near overwrite
                idx, d2, cc = idx[order], d[order], c[ok][order]
                closer = d2 < zb[idx]
                zb[idx[closer]] = d2[closer]
                img[idx[closer]] = cc[closer]
    a = np.isfinite(zb).reshape(H, W)
    rgb = (img.reshape(H, W, 3) * 255).astype(np.uint8)
    out = np.dstack([rgb, (a * 255).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def sheet_view(path, ppm, height=2.5, width=1.4, center=None):
    """Load a sheet view cut-out (RGBA), scale to 2.4 m = horn tip..sole at ppm. center: the world origin's
    horizontal position in metres from the image's left edge (None = chest-band midpoint)."""
    s = Image.open(path).convert("RGBA")
    a = np.asarray(s)[..., 3] > 128
    rows = np.where(a.any(1))[0]
    s = s.crop((0, rows[0], s.width, rows[-1] + 1))
    k = 2.4 * ppm / s.height
    s = s.resize((max(1, int(s.width * k)), int(2.4 * ppm)), Image.LANCZOS)
    W, H = int(width * ppm), int(height * ppm)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if center is None:
        aa = np.asarray(s)[..., 3] > 128
        mids = []
        for z in np.linspace(1.3, 1.6, 10):
            c = np.where(aa[int(s.height - 1 - z * ppm)])[0]
            if len(c):
                mids.append(0.5 * (c[0] + c[-1]))
        cx = float(np.median(mids))
    else:
        cx = center * ppm
    out.alpha_composite(s, (int(W / 2 - cx), H - s.height))
    return out


def board(pairs, out_path, ppm, title=""):
    """pairs: list of (label, sheet RGBA, render RGBA). Sheet | render | overlay columns with 0.1 m guides."""
    tiles = []
    for label, s, r in pairs:
        ov = Image.new("RGBA", r.size, (0, 0, 0, 0))
        if s is not None:
            sa = s.copy()
            sa.putalpha(s.getchannel("A").point(lambda v: v // 2))
            ov.alpha_composite(sa)
        rr = r.copy()
        edge = np.asarray(r.getchannel("A")) > 0
        e = edge ^ (np.roll(edge, 1, 0) & np.roll(edge, -1, 0) & np.roll(edge, 1, 1) & np.roll(edge, -1, 1))
        ea = np.zeros(edge.shape + (4,), np.uint8)
        ea[e] = (20, 90, 220, 255)
        ov.alpha_composite(Image.fromarray(ea, "RGBA"))
        tiles.append((label, [x for x in (s, r, ov) if x is not None]))
    W = sum(sum(t.width for t in ts) + 20 for _, ts in tiles)
    H = max(t.height for _, ts in tiles for t in ts) + 30
    img = Image.new("RGBA", (W, H), (236, 228, 214, 255))
    d = ImageDraw.Draw(img)
    x = 0
    for label, ts in tiles:
        x0 = x
        for t in ts:
            img.alpha_composite(t, (x, 30))
            x += t.width
        for k in range(0, 26):
            y = 30 + ts[0].height - k * 0.1 * ppm
            d.line([(x0, y), (x, y)], fill=(150, 120, 110, 255) if k % 5 == 0 else (200, 185, 170, 255), width=1)
        d.text((x0 + 4, 8), label + "  " + title, fill=(40, 30, 30, 255))
        x += 20
    img.convert("RGB").save(out_path)
    return out_path
