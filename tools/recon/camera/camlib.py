#!/usr/bin/env python3
"""Shared camera + CPU rasteriser for the exact-reconstruction camera work (no Blender needed).
World frame = glTF/model frame: +Y up, character faces +Z, his LEFT is +X (same as tools/fidelity/render_model_views.py).
Camera = OpenCV pinhole: x right, y down, z forward. World->cam: Xc = R (X - C).
Blender equivalent (exported by to_blender()): world (x,y,z)_gltf -> Blender (x,-z,y)."""
import os, sys, json, subprocess, tempfile
import numpy as np, cv2

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
FORMS = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/forms/LOCKED_P1f/forms.glb')
HEAD7 = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/head_v7/head_v7.glb')
DROP = ['skull_hull', 'mandible', 'eyeball_L', 'eyeball_R', 'eye_socket_L', 'eye_socket_R', 'crown_plate1', 'crown_plate2', 'crown_plate3', 'crown_tine_A', 'crown_tine_B',
        'horn_cup_A', 'horn_cup_B', 'nose_pad', 'nostril_L', 'nostril_R', 'temple_tine_L', 'temple_tine_R']   # = assemble7.py DROP list
HERO_REF = os.path.join(ROOT, 'design/reference_packs/aruun/ortho/aruun_front_4096.png')
HEAD_REF = os.path.join(ROOT, 'design/reference_packs/aruun/head/aruun_head_front.png')

def _scene_parts(path):
    import trimesh
    s = trimesh.load(path)
    parts = {}
    if isinstance(s, trimesh.Scene):
        for node in s.graph.nodes_geometry:
            T, gname = s.graph[node]
            g = s.geometry[gname].copy(); g.apply_transform(T)
            parts[node] = (np.asarray(g.vertices, float), np.asarray(g.faces, int))
    else:
        parts['mesh'] = (np.asarray(s.vertices, float), np.asarray(s.faces, int))
    return parts

def _blend_to_glb(path):
    tmp = os.path.join(tempfile.mkdtemp(), 'm.glb')
    subprocess.check_call(['blender', '-b', path, '--python-expr', f"import bpy;bpy.ops.export_scene.gltf(filepath=r'{tmp}',export_format='GLB')"])
    return tmp

def load_parts(path=None):
    """dict name -> (verts, faces). Default = LOCKED_P1f forms.glb with the head objects swapped for head_v7 (python port of assemble7.py)."""
    if path is None:
        parts = {k: v for k, v in _scene_parts(FORMS).items() if k.split('.')[0] not in DROP and k not in DROP}
        parts.update({'H7_' + k: v for k, v in _scene_parts(HEAD7).items()})
        return parts
    if path.endswith('.blend'): path = _blend_to_glb(path)
    return _scene_parts(path)

def merge(parts, names=None, drop_prefix=()):
    V, F, o = [], [], 0
    for k, (v, f) in parts.items():
        if names is not None and k not in names: continue
        if any(k.startswith(p) for p in drop_prefix): continue
        V.append(v); F.append(f + o); o += len(v)
    return np.concatenate(V), np.concatenate(F)

# ---------------- camera ----------------
class Cam:
    def __init__(self, C, R, f, cx, cy, W, H, ortho_scale=None, name=''):
        self.C = np.asarray(C, float); self.R = np.asarray(R, float); self.f = float(f); self.cx = float(cx); self.cy = float(cy)
        self.W = int(W); self.H = int(H); self.ortho = ortho_scale; self.name = name   # ortho_scale = px per metre (orthographic) or None
    def cam_coords(self, X):
        return (np.asarray(X, float) - self.C) @ self.R.T
    def project(self, X):
        Xc = self.cam_coords(X)
        if self.ortho: return np.stack([self.cx + Xc[:, 0] * self.ortho, self.cy + Xc[:, 1] * self.ortho], -1), Xc[:, 2]
        z = Xc[:, 2]
        return np.stack([self.cx + self.f * Xc[:, 0] / z, self.cy + self.f * Xc[:, 1] / z], -1), z
    def view_dir(self): return self.R[2]
    def to_dict(self):
        return dict(C=self.C.tolist(), R=self.R.tolist(), f_px=self.f, cx=self.cx, cy=self.cy, W=self.W, H=self.H, ortho_px_per_m=self.ortho)

def look_at(C, T, roll_deg=0.0, up=(0, 1, 0)):
    C = np.asarray(C, float); T = np.asarray(T, float)
    z = T - C; z /= np.linalg.norm(z)
    x = np.cross(z, np.asarray(up, float)); x /= np.linalg.norm(x)     # camera right
    y = np.cross(z, x)                                                 # camera down
    R = np.stack([x, y, z])
    r = np.deg2rad(roll_deg); Rz = np.array([[np.cos(r), -np.sin(r), 0], [np.sin(r), np.cos(r), 0], [0, 0, 1]])
    return Rz @ R

def cam_from_orbit(target, dist, yaw_deg, pitch_deg, roll_deg, f, cx, cy, W, H, name=''):
    """Orbit camera around `target`. yaw 0 = camera in FRONT of the character (on +Z looking -Z, image-right = his LEFT +X);
    yaw +90 = camera at his LEFT (+X) looking -X (character faces screen-left... see doc), pitch>0 = camera ABOVE target looking down."""
    ya, pa = np.deg2rad(yaw_deg), np.deg2rad(pitch_deg)
    d = np.array([np.sin(ya) * np.cos(pa), np.sin(pa), np.cos(ya) * np.cos(pa)])
    C = np.asarray(target, float) + dist * d
    return Cam(C, look_at(C, target, roll_deg), f, cx, cy, W, H, name=name)

def euler_to_R(yaw, pitch, roll):  # helper not used by solver
    return look_at(cam_from_orbit([0, 0, 0], 1, yaw, pitch, 0, 1, 0, 0, 1, 1).C, [0, 0, 0], roll)

def to_blender(cam):
    """Blender camera: location (Z-up world, x,-z,y), rotation_euler XYZ, lens mm (sensor_width 36, fit AUTO->width), shift_x/shift_y."""
    Mw = np.array([[1, 0, 0], [0, 0, -1], [0, 1, 0]], float)      # gltf -> blender
    Rb = np.diag([1, -1, -1.0])                                    # blender cam axes (x right,y up,-z forward) vs opencv (x right,y down,z fwd)
    Rcw = Rb @ cam.R @ Mw.T                                        # blender world -> blender cam
    Rwc = Rcw.T                                                    # camera-to-world matrix columns
    from math import atan2, asin, degrees
    # XYZ euler from rotation matrix (Blender: R = Rz*Ry*Rx)
    sy = -Rwc[2, 0]; y = np.arcsin(np.clip(sy, -1, 1))
    if abs(sy) < 0.99999: x = atan2(Rwc[2, 1], Rwc[2, 2]); z = atan2(Rwc[1, 0], Rwc[0, 0])
    else: x = atan2(-Rwc[1, 2], Rwc[1, 1]); z = 0
    loc = Mw @ cam.C
    d = dict(location=loc.tolist(), rotation_euler_rad=[float(x), float(y), float(z)], rotation_euler_deg=[degrees(x), degrees(y), degrees(z)])
    if cam.ortho:
        d.update(type='ORTHO', ortho_scale_m=float(cam.W / cam.ortho))
    else:
        d.update(type='PERSP', sensor_width_mm=36.0, lens_mm=float(cam.f * 36.0 / cam.W), shift_x=float((cam.cx - cam.W / 2) / cam.W), shift_y=float((cam.H / 2 - cam.cy) / cam.W))
    d.update(res_x=cam.W, res_y=cam.H)
    return d

# ---------------- rasteriser ----------------
def raster(cam, V, F, SS=2, shade=True, flat=False):
    """Painter's-algorithm raster. returns (mask uint8 0/255 HxW, clay BGR HxW). SS = supersample factor for the polygon fill (shift bits)."""
    uv, z = cam.project(V)
    W, H = cam.W, cam.H
    P = V[F]; n = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]); n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    cen = P.mean(1)
    if cam.ortho: vd = -cam.R[2][None, :].repeat(len(F), 0)
    else:
        vd = cam.C[None, :] - cen; vd /= np.maximum(np.linalg.norm(vd, axis=1, keepdims=True), 1e-12)
    lam = np.abs((n * vd).sum(1))
    light = np.array([0.35, 0.8, 0.5]); light /= np.linalg.norm(light)   # key light from the camera's world up-ish; fixed in world for stability
    lit = 0.55 * lam + 0.30 * np.clip(n @ light, 0, 1) + 0.15
    zt = z[F].mean(1)
    tri = uv[F]
    ok = (z[F] > 1e-4).all(1) if not cam.ortho else np.ones(len(F), bool)
    order = np.argsort(-zt, kind='stable')
    mask = np.zeros((H, W), np.uint8); clay = np.full((H, W, 3), 0, np.uint8)
    col = (np.clip(lit, 0, 1) * 235 + 10).astype(np.uint8)
    t8 = np.round(tri * 8).astype(np.int32)
    for i in order:
        if not ok[i]: continue
        t = t8[i]
        if np.abs(t).max() > 2 ** 28: continue
        cv2.fillConvexPoly(mask, t, 255, lineType=cv2.LINE_8, shift=3)
        c = int(col[i]); cv2.fillConvexPoly(clay, t, (c, c, c), lineType=cv2.LINE_8, shift=3)
    return mask, clay

def ref_mask(path, thr=128):
    from PIL import Image
    im = Image.open(path).convert('RGBA'); a = np.asarray(im)
    alpha = a[..., 3]
    if alpha.min() == 255:   # opaque -> background is near white/cream
        rgb = a[..., :3].astype(int); alpha = (np.abs(rgb - rgb[:2, :2].reshape(-1, 3).mean(0)).sum(-1) > 40).astype(np.uint8) * 255
    return (alpha >= thr).astype(np.uint8) * 255, cv2.cvtColor(a[..., :3], cv2.COLOR_RGB2BGR)

def iou(a, b):
    a = a > 0; b = b > 0; return (a & b).sum() / max((a | b).sum(), 1)
