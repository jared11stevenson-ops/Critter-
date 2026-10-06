#!/usr/bin/env python3
"""v2 (4): 3/4 ortho-style views by re-rendering the measured proxy at yaw +-35 / +-145 and projecting the v2 front, completed side and completed back paint onto it
(per-pixel: world point + smooth normal from the proxy; source visible = proxy z-buffer test in the source camera; best source = largest normal.d_source).
Surfaces no source sees (e.g. his LEFT flank from the side/back, which only the front sees at a grazing angle) are RED nearest-neighbour fill."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v2_common import *
import trimesh

def smooth_normals(V, F):
    fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]]); vn = np.zeros_like(V)
    for k in range(3): np.add.at(vn, F[:, k], fn)
    return vn / np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)

class Source:
    def __init__(self, name, rgba, cls, yaw, ax, V, F, snap=45):
        self.name, self.rgba, self.cls, self.yaw, self.ax = name, rgba, cls, yaw, ax
        self.alpha = rgba[..., 3] > 128; self.snap = snap
        self.d = cam_vec(yaw); H, W = rgba.shape[:2]
        fid, zb, _, _ = rasterise(V, F, yaw, ax, W); self.zb = zb
        dist, lab = cv2.distanceTransformWithLabels((~self.alpha).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
        zy, zx = np.where(dist == 0); self.l2 = np.zeros((lab.max() + 1, 2), np.int32); self.l2[lab[zy, zx]] = np.c_[zx, zy]; self.dist, self.lab = dist, lab
    def sample(self, P, tol=0.035):
        sx, sy, dep = project(P, self.yaw, self.ax); H, W = self.rgba.shape[:2]
        xi = np.clip(np.round(sx).astype(int), 0, W - 1); yi = np.clip(np.round(sy).astype(int), 0, H - 1)
        vis = dep >= self.zb[yi, xi] - tol
        d = self.dist[yi, xi]; nn = self.l2[self.lab[yi, xi]]
        return self.rgba[nn[:, 1], nn[:, 0], :3], self.cls[nn[:, 1], nn[:, 0]], vis & (d <= self.snap), d

def render_view(name, yaw, sources, V, F, W=2200, ax=1100):
    sn = smooth_normals(V, F)
    fid, zb, bu, bv = rasterise(V, F, yaw, ax, W)
    m = fid >= 0; f = np.where(m, fid, 0)
    u = bu[..., None].astype(np.float64); v = bv[..., None].astype(np.float64)
    P = u * V[F[f, 0]] + v * V[F[f, 1]] + (1 - u - v) * V[F[f, 2]]
    N = u * sn[F[f, 0]] + v * sn[F[f, 1]] + (1 - u - v) * sn[F[f, 2]]; N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
    ys, xs = np.where(m); Pm = P[ys, xs]; Nm = N[ys, xs]; dt = cam_vec(yaw)
    Nm = Nm * np.where((Nm @ dt) < 0, -1.0, 1.0)[:, None]      # visible surface faces the camera (guards against inward winding)
    out = np.zeros((4096, W, 4), np.uint8); cls = np.zeros((4096, W), np.uint8)
    best = np.full(len(ys), -1.0); col = np.zeros((len(ys), 3), np.uint8); cl = np.full(len(ys), 3, np.uint8); who = np.full(len(ys), -1, np.int8)
    for si, s in enumerate(sources):
        c, c_cls, ok, d = s.sample(Pm); w = Nm @ s.d; w = np.where(ok & (w > 0.15), w, -1)
        # bias to the source nearest the target camera when scores are close (keeps seams low)
        w = w + 0.15 * np.clip(s.d @ dt, 0, 1) * (w > 0)
        take = w > best; best[take] = w[take]; col[take] = c[take]; who[take] = si
        # class: the source's own class; side/back originals become GREEN only when the surface faces both cameras squarely
        isorig = s.name in ('side', 'back')
        k = np.where(isorig, np.where(((Nm @ s.d) > 0.8) & ((Nm @ dt) > 0.8) & (d < 15), 1, 2), c_cls)
        cl[take] = np.asarray(k)[take]
    unk = who < 0
    cl[unk] = 3
    out[ys, xs, :3] = col; out[ys, xs, 3] = 255; cls[ys, xs] = cl
    # unknown: nearest-neighbour colour from known pixels (inside the silhouette only)
    known = np.zeros((4096, W), bool); known[ys[~unk], xs[~unk]] = True
    if unk.any() and known.any():
        dist, lab = cv2.distanceTransformWithLabels((~known).astype(np.uint8), cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
        zy, zx = np.where(dist == 0); l2 = np.zeros((lab.max() + 1, 2), np.int32); l2[lab[zy, zx]] = np.c_[zx, zy]
        uy, ux = ys[unk], xs[unk]; nn = l2[lab[uy, ux]]; out[uy, ux, :3] = out[nn[:, 1], nn[:, 0], :3]
    # 2 px ink silhouette
    a = out[..., 3] > 0; er = cv2.erode(a.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0; out[a & ~er, :3] = np.array([22, 16, 20], np.uint8)
    contrib = {s.name: float((who == i).mean() * 100) for i, s in enumerate(sources)}; contrib['none(red)'] = float(unk.mean() * 100)
    return out, cls, contrib

def load_sources(V, F):
    D = OUT
    fr = load_rgba(os.path.join(D, 'aruun_v2_front_ortho_4096.png')); frc = cv2.imread(os.path.join(D, 'aruun_v2_front_ortho_4096_classmap.png'), 0) // 80
    sd = load_rgba(os.path.join(D, 'aruun_v2_side_completed_4096.png')); sdc = cv2.imread(os.path.join(D, 'aruun_v2_side_completed_4096_classmap.png'), 0) // 80
    bk = load_rgba(os.path.join(D, 'aruun_v2_back_completed_4096.png')); bkc = cv2.imread(os.path.join(D, 'aruun_v2_back_completed_4096_classmap.png'), 0) // 80
    return [Source('front', fr, frc, 0, 900, V, F), Source('side', sd, sdc, -90, META['views']['side']['axis_x_px'] + 100 - 10, V, F),
            Source('back', bk, bkc, 180, META['views']['back']['axis_x_px'] + 100, V, F)]

if __name__ == '__main__':
    V, F = load_proxy(); srcs = load_sources(V, F)
    for nm, yaw in (('front_left', 35), ('front_right', -35), ('back_left', 145), ('back_right', -145)):
        img, cls, contrib = render_view(nm, yaw, srcs, V, F)
        meta = dict(view=f'3/4 {nm.replace("_", "-")}', camera=f'orthographic yaw {yaw} deg about +Y (0=front, +90 sees his LEFT side, -90 sees his RIGHT side, 180=back); axis_x_px=1100 = world x 0', axis_x_px=1100,
                    x_offset_px=0, sources=['proxy.glb geometry', 'aruun_v2_front_ortho_4096.png', 'aruun_v2_side_completed_4096.png', 'aruun_v2_back_completed_4096.png'],
                    source_contribution_percent=contrib, silhouette='proxy silhouette (geometry-only, ~1-3 cm vs the side/back cuts); horn tips, fringe, strips and tines are proxy-simplified')
        print(nm, write_set(f'aruun_v2_34_{nm}_4096', img, cls, meta), contrib)
