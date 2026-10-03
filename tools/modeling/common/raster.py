"""Small numpy triangle rasterizers (orthographic view rasterization + UV-space rasterization).

view_raster(): depth / triangle-id buffers for an orthographic view -> silhouettes, visibility tests.
uv_raster():   per-texel barycentrics + triangle id in UV space -> position/normal maps for painting/projection.
"""
import numpy as np


def _raster(P2, tris, W, H, depth=None):
    """P2: (N,2) pixel coords (x right, y down), depth: (N,) smaller = closer (or None).
    Returns tri id buffer (-1 empty), barycentric buffer (H,W,3), z buffer."""
    tid = np.full((H, W), -1, dtype=np.int32)
    bary = np.zeros((H, W, 3), dtype=np.float32)
    zb = np.full((H, W), np.inf, dtype=np.float32)
    A = P2[tris[:, 0]]
    B = P2[tris[:, 1]]
    C = P2[tris[:, 2]]
    xmin = np.clip(np.floor(np.minimum(np.minimum(A[:, 0], B[:, 0]), C[:, 0])).astype(int), 0, W - 1)
    xmax = np.clip(np.ceil(np.maximum(np.maximum(A[:, 0], B[:, 0]), C[:, 0])).astype(int), 0, W - 1)
    ymin = np.clip(np.floor(np.minimum(np.minimum(A[:, 1], B[:, 1]), C[:, 1])).astype(int), 0, H - 1)
    ymax = np.clip(np.ceil(np.maximum(np.maximum(A[:, 1], B[:, 1]), C[:, 1])).astype(int), 0, H - 1)
    for t in range(len(tris)):
        x0, x1, y0, y1 = xmin[t], xmax[t], ymin[t], ymax[t]
        if x1 < x0 or y1 < y0:
            continue
        xs = np.arange(x0, x1 + 1) + 0.5
        ys = np.arange(y0, y1 + 1) + 0.5
        X, Y = np.meshgrid(xs, ys)
        a, b, c = A[t], B[t], C[t]
        d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(d) < 1e-12:
            continue
        l0 = ((b[1] - c[1]) * (X - c[0]) + (c[0] - b[0]) * (Y - c[1])) / d
        l1 = ((c[1] - a[1]) * (X - c[0]) + (a[0] - c[0]) * (Y - c[1])) / d
        l2 = 1 - l0 - l1
        eps = -1e-4
        m = (l0 >= eps) & (l1 >= eps) & (l2 >= eps)
        if not m.any():
            continue
        sub_t = tid[y0:y1 + 1, x0:x1 + 1]
        sub_b = bary[y0:y1 + 1, x0:x1 + 1]
        sub_z = zb[y0:y1 + 1, x0:x1 + 1]
        if depth is not None:
            z = l0 * depth[tris[t, 0]] + l1 * depth[tris[t, 1]] + l2 * depth[tris[t, 2]]
            m = m & (z < sub_z)
            sub_z[m] = z[m]
        sub_t[m] = t
        sub_b[m, 0] = l0[m]
        sub_b[m, 1] = l1[m]
        sub_b[m, 2] = l2[m]
    return tid, bary, zb


def view_raster(V, tris, view, px_per_m, W, H, origin_px, z0=0.0):
    """Orthographic view. view in {'front','back','side_r','side_l'}; model faces -Y, Z up.
    origin_px = (cx, ground_y) pixel position of the world origin (x=0, z=0).
    Conventions (screen x right, y down):
      front : camera at -Y looking +Y. screen_x = +X world, depth = +Y
      back  : camera at +Y looking -Y. screen_x = -X world, depth = -Y
      side_r: character faces screen-right: camera at -X (sees his RIGHT side): screen_x = -Y, depth = +X
      side_l: faces screen-left: camera at +X (sees his LEFT side): screen_x = +Y, depth = -X
    """
    V = np.asarray(V, dtype=np.float64)
    if view == "front":
        sx, d = V[:, 0], V[:, 1]
    elif view == "back":
        sx, d = -V[:, 0], -V[:, 1]
    elif view == "side_r":
        sx, d = -V[:, 1], V[:, 0]
    elif view == "side_l":
        sx, d = V[:, 1], -V[:, 0]
    else:
        raise ValueError(view)
    P2 = np.stack([origin_px[0] + sx * px_per_m, origin_px[1] - (V[:, 2] - z0) * px_per_m], 1)
    return _raster(P2, np.asarray(tris), W, H, d) + (P2,)


def uv_raster(UV, tris_uv, size):
    """UV: (K,2) uv coords per corner-vertex, tris_uv: (M,3) indices into UV. Returns tid, bary."""
    P2 = np.stack([UV[:, 0] * size, (1 - UV[:, 1]) * size], 1)
    tid, bary, _ = _raster(P2, np.asarray(tris_uv), size, size, None)
    return tid, bary


def dilate(img, mask, iters=8):
    """Push colors from mask into empty texels (seam padding)."""
    img = img.copy()
    m = mask.copy()
    for _ in range(iters):
        acc = np.zeros_like(img, dtype=np.float64)
        cnt = np.zeros(m.shape, dtype=np.float64)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            sm = np.roll(np.roll(m, dy, 0), dx, 1)
            si = np.roll(np.roll(img, dy, 0), dx, 1)
            acc += si * sm[..., None] if img.ndim == 3 else si * sm
            cnt += sm
        new = (~m) & (cnt > 0)
        if not new.any():
            break
        if img.ndim == 3:
            img[new] = (acc[new] / cnt[new][:, None]).astype(img.dtype)
        else:
            img[new] = (acc[new] / cnt[new]).astype(img.dtype)
        m = m | new
    return img, m
