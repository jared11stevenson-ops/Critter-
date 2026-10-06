"""Orthographic z-buffer rasteriser + camera helpers for the Aruun v2 reference generator (numba, CPU).
World: +Y up, character faces +Z, his LEFT is +X (tools/fidelity convention). Canvas: 4096 px tall, ground row 4000, PPM px per metre.
Camera = unit vector d (XZ plane, object->camera, yaw) ; screen-right r=(d_z,0,-d_x). front d=(0,0,1) side d=(-1,0,0) back d=(0,0,-1)."""
import numpy as np, numba as nb, json, os, trimesh
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
META = json.load(open(os.path.join(ROOT, 'design/reference_packs/aruun/metadata.json')))
PPM = META['px_per_m']; GROUND = META['ground_y']
PROXY = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/proxy/proxy.glb')

def load_proxy(path=PROXY):
    m = trimesh.load(path, force='mesh')
    return np.asarray(m.vertices, np.float64), np.asarray(m.faces, np.int64)

def cam_vec(yaw_deg):
    a = np.radians(yaw_deg); return np.array([np.sin(a), 0, np.cos(a)])   # yaw 0=front, +90 = his left side faces camera, -90 side view (right), 180 back

def project(P, yaw_deg, ax, W=None):
    """world pts (N,3) -> sx, sy, depth(larger=nearer)"""
    d = cam_vec(yaw_deg); r = np.array([d[2], 0, -d[0]])
    return ax + P @ r * PPM, GROUND - P[:, 1] * PPM, P @ d

@nb.njit(cache=True)
def _raster(sx, sy, dep, faces, W, H):
    fid = -np.ones((H, W), np.int32); zb = np.full((H, W), -1e9); bu = np.zeros((H, W), np.float32); bv = np.zeros((H, W), np.float32)
    for f in range(faces.shape[0]):
        a, b, c = faces[f, 0], faces[f, 1], faces[f, 2]
        x0, y0, x1, y1, x2, y2 = sx[a], sy[a], sx[b], sy[b], sx[c], sy[c]
        den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(den) < 1e-9: continue
        xmin = max(int(np.floor(min(x0, x1, x2))), 0); xmax = min(int(np.ceil(max(x0, x1, x2))), W - 1)
        ymin = max(int(np.floor(min(y0, y1, y2))), 0); ymax = min(int(np.ceil(max(y0, y1, y2))), H - 1)
        for y in range(ymin, ymax + 1):
            for x in range(xmin, xmax + 1):
                px = x + 0.5; py = y + 0.5
                u = ((y1 - y2) * (px - x2) + (x2 - x1) * (py - y2)) / den
                v = ((y2 - y0) * (px - x2) + (x0 - x2) * (py - y2)) / den
                w = 1 - u - v
                if u < -1e-6 or v < -1e-6 or w < -1e-6: continue
                z = u * dep[a] + v * dep[b] + w * dep[c]
                if z > zb[y, x]:
                    zb[y, x] = z; fid[y, x] = f; bu[y, x] = u; bv[y, x] = v
    return fid, zb, bu, bv

def rasterise(V, F, yaw_deg, ax, W, H=4096, vmask_extra=None):
    sx, sy, dep = project(V, yaw_deg, ax)
    fid, zb, bu, bv = _raster(sx, sy, dep, F, W, H)
    return fid, zb, bu, bv

def surf_points(V, F, fid, bu, bv):
    """world position + smooth-ish (face) normal per pixel; invalid -> nan"""
    m = fid >= 0; f = np.where(m, fid, 0)
    a, b, c = V[F[f, 0]], V[F[f, 1]], V[F[f, 2]]
    u = bu[..., None].astype(np.float64); v = bv[..., None].astype(np.float64)
    P = u * a + v * b + (1 - u - v) * c
    N = np.cross(b - a, c - a); N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-12)
    P[~m] = np.nan; N[~m] = np.nan
    return P, N

def load_parts(path=PROXY):
    """per-part meshes (scene nodes with transforms applied): returns V, F, part_id_per_face, names"""
    sc = trimesh.load(path)
    Vs, Fs, pid, names = [], [], [], []; off = 0
    for node in sc.graph.nodes_geometry:
        T, gname = sc.graph[node]; g = sc.geometry[gname]
        v = np.asarray(g.vertices, float); v = (np.c_[v, np.ones(len(v))] @ T.T)[:, :3]
        Vs.append(v); Fs.append(np.asarray(g.faces) + off); pid.append(np.full(len(g.faces), len(names))); names.append(gname); off += len(v)
    return np.vstack(Vs), np.vstack(Fs).astype(np.int64), np.concatenate(pid), names
