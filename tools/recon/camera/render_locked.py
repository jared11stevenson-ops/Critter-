#!/usr/bin/env python3
"""Render a model (.glb/.gltf/.obj/.blend ; default = LOCKED_P1f forms + head_v7 composite) from the LOCKED reference cameras (and optional DIAGNOSTIC cameras).
No Blender needed for .glb (pure numpy/OpenCV rasteriser; .blend is exported to glb via `blender -b` when available).
usage: render_locked.py [MODEL] --out DIR [--cams HERO HEAD SIDE BACK FRONT_ORTHO] [--diag HERO|HEAD|SIDE|BACK ...] [--no-ref]
Per camera it writes, at the reference resolution (same pixel grid as the reference image):
  clay_<cam>.png      gray clay (white-ish bg removed -> mid-dark gray bg)
  sil_<cam>.png       PURE BLACK model on a flat white background (silhouette-first test)
  overlay_<cam>.png   RGBA: clay at 55% alpha + red 3px silhouette outline + landmark crosses, transparent elsewhere (drop on top of the reference)
  vsref_<cam>.png     reference with model silhouette outline (red) and ref silhouette outline (green) + IoU text   (unless --no-ref)
  <cam>_info.json     camera + IoU vs reference mask
Diagnostic cameras (yaw/pitch +-30 deg about the locked camera's target, same intrinsics) are written as diag_<cam>_yaw+30.png etc. They are NEVER used to judge the match."""
import sys, os, json, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from camlib import *

LOCK = os.path.join(ROOT, 'design/model_sheets/aruun/recon/camera/LOCKED_CAMERAS.json')
REFS = {'HERO': HERO_REF, 'HEAD': HEAD_REF,
        'SIDE': os.path.join(ROOT, 'design/reference_packs/aruun/ortho/aruun_side_4096.png'),
        'BACK': os.path.join(ROOT, 'design/reference_packs/aruun/ortho/aruun_back_4096.png')}

def cam_from_lock(d, model_T=None):
    """LOCKED entry -> Cam in the MODEL frame. Entries may carry a rigid transform `model_T` (R, pivot, t) that the camera was solved with
    (root yaw / head rotation): folded into the camera so the rest-pose model is rendered as-is."""
    C = np.array(d['C']); R = np.array(d['R'])
    cam = Cam(C, R, d['f_px'], d['cx'], d['cy'], d['W'], d['H'], ortho_scale=d.get('ortho_px_per_m'), name=d.get('name', ''))
    if 'model_T' in d:
        Rm = np.array(d['model_T']['R']); piv = np.array(d['model_T']['pivot']); t = np.array(d['model_T']['t'])
        cam.R = R @ Rm; cam.C = piv - Rm.T @ (piv + t - C)
    return cam

def diag_cams(cam, tgt, yaw, pitch):
    """re-orbit the locked camera about target `tgt` by yaw (about world Y) / pitch (about camera right axis)."""
    c = cv2.Rodrigues(np.array([0, np.deg2rad(yaw), 0.0]))[0]
    C = tgt + c @ (cam.C - tgt); R = cam.R @ c.T
    right = R[0]
    p = cv2.Rodrigues(right * np.deg2rad(-pitch))[0]
    C = tgt + p @ (C - tgt); R = R @ p.T
    return Cam(C, R, cam.f, cam.cx, cam.cy, cam.W, cam.H, ortho_scale=cam.ortho)

def outline(mask, col, img, th=3):
    cnts = cv2.findContours((mask > 0).astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)[0]
    cv2.drawContours(img, cnts, -1, col, th)

def render_set(V, F, cam, name, out, refpath=None, landmarks=None, tag=''):
    mask, clay = raster(cam, V, F)
    if tag:   # diagnostic: half-resolution clay only (never used to judge the match)
        clay_d = np.where(mask[..., None] > 0, clay, 70).astype(np.uint8); cv2.imwrite(os.path.join(out, f'diag_{name}{tag}.png'), cv2.resize(clay_d, None, fx=.5, fy=.5, interpolation=cv2.INTER_AREA)); return mask
    bg = np.full_like(clay, 70); clay_o = np.where(mask[..., None] > 0, clay, bg)
    cv2.imwrite(os.path.join(out, f'clay_{name}{tag}.png'), clay_o)
    sil = np.full((cam.H, cam.W, 3), 255, np.uint8); sil[mask > 0] = 0
    cv2.imwrite(os.path.join(out, f'sil_{name}{tag}.png'), sil)
    ov = np.zeros((cam.H, cam.W, 4), np.uint8); ov[..., :3] = clay; ov[..., 3] = (mask > 0) * 140
    ocol = np.zeros((cam.H, cam.W, 3), np.uint8); outline(mask, (0, 0, 255), ocol, 3); line = ocol.any(-1)
    ov[line, :3] = (0, 0, 255); ov[line, 3] = 255
    cv2.imwrite(os.path.join(out, f'overlay_{name}{tag}.png'), ov)
    info = dict(camera=cam.to_dict())
    if refpath and os.path.exists(refpath) and not tag:
        rm, rbgr = ref_mask(refpath)
        if rm.shape != mask.shape: rm = cv2.resize(rm, (cam.W, cam.H), interpolation=cv2.INTER_NEAREST); rbgr = cv2.resize(rbgr, (cam.W, cam.H))
        v = (rbgr.astype(float) * (rm[..., None] > 0) + 40 * (rm[..., None] == 0)).astype(np.uint8)
        outline(rm, (0, 255, 0), v, 3); outline(mask, (0, 0, 255), v, 3)
        if landmarks:
            for n, (x, y) in landmarks.items():
                cv2.drawMarker(v, (int(x), int(y)), (255, 255, 0), cv2.MARKER_CROSS, 40, 3)
        i = iou(mask, rm); info['iou'] = float(i)
        cv2.putText(v, f'IoU {i:.3f}  green=ref red=model', (20, 60), 0, 1.6, (255, 255, 255), 3)
        cv2.imwrite(os.path.join(out, f'vsref_{name}.png'), v)
        comp = rbgr.astype(float) * 0.55; mk = mask > 0
        comp[mk] = comp[mk] * 0.3 + clay[mk].astype(float) * 0.7 * np.array([0.8, 0.9, 1.0])
        comp = comp.astype(np.uint8); outline(mask, (0, 0, 255), comp, 3)
        cv2.imwrite(os.path.join(out, f'composite_{name}.png'), comp)
    json.dump(info, open(os.path.join(out, f'{name}{tag}_info.json'), 'w'), indent=1)
    return mask

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('model', nargs='?'); ap.add_argument('--out', required=True)
    ap.add_argument('--cams', nargs='+', default=['HERO', 'HEAD', 'SIDE', 'BACK']); ap.add_argument('--diag', nargs='*', default=[])
    ap.add_argument('--no-ref', action='store_true'); ap.add_argument('--head-pose', action='store_true', help='rotate head+horn parts by the solved head orientation (LOCKED head_pose) so the pose target can be checked'); ap.add_argument('--lock', default=LOCK)
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    L = json.load(open(a.lock)); parts = load_parts(a.model)
    parts0 = dict(parts)
    if a.head_pose:
        hp = L['head_pose']; Rh = np.array(hp['R_rel_torso']); piv = np.array(hp['pivot_model']); hero_cam = cam_from_lock(L['cameras']['HERO'])
        px = np.array(hp['pivot_px_target_hero'])
        for k in list(parts):
            if k.startswith('H7_') or k.startswith('horn'):
                v, f = parts[k]; parts[k] = (piv + (v - piv) @ Rh.T, f)
        # translate so that the posed pivot lands on the fitted image position (neck lean is pose, not camera)
        uv, z = hero_cam.project(piv[None]); dx, dy = px - uv[0]; sh = hero_cam.R.T @ np.array([dx * z[0] / hero_cam.f, dy * z[0] / hero_cam.f, 0])
        for k in list(parts):
            if k.startswith('H7_') or k.startswith('horn'): parts[k] = (parts[k][0] + sh, parts[k][1])
    V, F = merge(parts); V0, F0 = merge(parts0)
    HEADN = [k for k in parts if k.startswith('H7_') or k.startswith('horn')] if a.model is None else None
    for name in a.cams:
        d = L['cameras'][name]; cam = cam_from_lock(d)
        Vn, Fn = (V, F) if name in ('HERO', 'HEAD') else (V0, F0)   # head pose only applies to the hero drawing
        if name == 'HEAD' and HEADN:      # head tile: head + horns (+ neck) only
            Vn, Fn = merge(parts, HEADN + ['neck'])
        lm = {k: v for k, v in d.get('landmarks_ref_px', {}).items()}
        render_set(Vn, Fn, cam, name, a.out, None if a.no_ref else REFS.get(name), lm)
        if name in a.diag:
            tgt = np.array(d.get('target_model', [0, 1.2, 0]))
            for yaw, pit in [(30, 0), (-30, 0), (0, 30), (0, -30)]:
                render_set(Vn, Fn, diag_cams(cam, tgt, yaw, pit), name, a.out, tag=f'_diag_yaw{yaw:+d}_pitch{pit:+d}')
    print('done ->', a.out)
if __name__ == '__main__': main()
