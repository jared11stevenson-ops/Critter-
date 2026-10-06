#!/usr/bin/env python3
"""Orthographic CPU renders of a model at EXACTLY the reference framing (4096 px tall, ground row 4000, 1626.667 px/m = 2.40 m scale, same axis column
per view; canvas padded by PAD=1200 px left/right, reference window = columns PAD..PAD+width). Writes sil_{view}.png (flat white-on-black silhouette) and clay_{view}.png (clay-shaded, depth-sorted) for side/back/front.
usage: python3 tools/fidelity/render_model_views.py [model.glb|.gltf|.obj|.ply|.stl|.blend] --out DIR [--views side back front] [--forward +z] [--scale 1.0]
Conventions (checked against the references): model +Y up, character faces +Z (glTF) and his LEFT is +X. side = camera at his right looking +X, he faces screen-right;
back = camera behind him (image-right = his RIGHT); front = camera in front (image-right = his LEFT).
NO height normalisation is applied (a 2.38 m model stays 2.38 m): --normalize-height rescales to 2.40 m about the ground. Pose caveat: the model is rendered in
its rest pose (A-pose arms) while the reference arms hang differently, so arm/hand rows are not like-for-like. The reference front is a 3/4 pose: front is for qualitative use only."""
import sys, os, json, argparse, subprocess, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fid_common import *

PAD = 1200   # horizontal padding (px) each side; reference window = columns PAD..PAD+width_px
DEFAULT_MODEL = os.path.join(ROOT, 'game/art/models/aruun/aruun.glb')

def load_mesh(path):
    import trimesh
    if path.endswith('.blend'):
        tmp = os.path.join(tempfile.mkdtemp(), 'm.glb')
        subprocess.check_call(['blender', '-b', path, '--python-expr', f"import bpy;bpy.ops.export_scene.gltf(filepath=r'{tmp}',export_format='GLB')"])
        path = tmp
    m = trimesh.load(path, force='mesh')
    return np.asarray(m.vertices, float), np.asarray(m.faces, int)

def drop_mace(verts, faces, forward='+z', right_limit=0.46):
    """Reference has no Morrow (mace erased): drop mesh islands that reach further than right_limit m to his RIGHT of the model origin (the mace head+haft)."""
    import trimesh
    fwd, up, left = axes(verts, forward)
    m = trimesh.Trimesh(verts, faces, process=False)
    cc = trimesh.graph.connected_components(m.face_adjacency, nodes=np.arange(len(faces)), min_len=1)
    keep = np.ones(len(faces), bool)
    for c in cc:
        if left[faces[c].ravel()].min() < -right_limit: keep[c] = False
    return faces[keep], int((~keep).sum())

def axes(vertices, forward):
    sgn = -1 if forward[0] == '-' else 1; ax = 'xyz'.index(forward[1].lower())
    f = np.zeros(3); f[ax] = sgn
    up = np.array([0, 1., 0]); l = np.cross(up, f)
    return vertices @ f, vertices[:, 1], vertices @ l      # fwd, up, left coordinates

def project(view, fwd, up, left):
    ax = view_info(view)['axis_x_px']
    if view == 'side':  sx, depth = ax + fwd * PPM, -left        # camera on his right (-left side): near = larger -left... see below
    elif view == 'back': sx, depth = ax - left * PPM, fwd        # camera behind: near = smaller fwd
    else:               sx, depth = ax + left * PPM, -fwd       # camera in front: near = larger fwd
    sy = GROUND - up * PPM
    return sx, sy, depth

def render(view, verts, faces, forward='+z', scale=1.0, normalize=False):
    fwd, up, left = axes(verts, forward)
    if normalize: s = H_M / up.max(); fwd, up, left = fwd * s, up * s, left * s
    fwd, up, left = fwd * scale, up * scale, left * scale
    sx, sy, depth_far = project(view, fwd, up, left)
    W = view_info(view)['width_px'] + 2 * PAD; H = 4096
    sx = sx + PAD                                                 # canvas is padded by PAD px each side so a mis-centred model is never clipped
    tri = np.stack([sx[faces], sy[faces]], -1)                    # (N,3,2)
    sil = np.zeros((H, W), np.uint8)
    tri8 = (tri * 8).round().astype(np.int32)
    for t in tri8:                                                # per-triangle fill (cv2.fillPoly on a list is even-odd and punches holes)
        cv2.fillConvexPoly(sil, t, 255, lineType=cv2.LINE_8, shift=3)
    # clay: painter's order, flat Lambert. depth_far: larger = farther from camera (we sort descending).
    P = [verts[faces][:, k] for k in range(3)]
    n = np.cross(P[1] - P[0], P[2] - P[0]); nl = np.linalg.norm(n, axis=1, keepdims=True); n = n / np.maximum(nl, 1e-12)
    # view-space shading: headlight from camera with slight top light
    fwd_v, _, left_v = None, None, None
    f = np.zeros(3); sgn = -1 if forward[0] == '-' else 1; f['xyz'.index(forward[1].lower())] = sgn
    l = np.cross([0, 1., 0], f)
    cam_dir = {'side': -l, 'back': -f, 'front': f}[view]         # direction from the object toward the camera... for side camera is on his right (-left)
    lit = np.abs(n @ cam_dir) * 0.62 + np.clip(n[:, 1], 0, 1) * 0.25 + 0.13
    key = depth_far[faces].mean(1)
    order = np.argsort(-key, kind='stable')
    clay = np.full((H, W, 3), 214, np.uint8)
    col = (np.clip(lit, 0, 1) * 235).astype(np.uint8)
    for i in order:
        t = tri[i]
        cv2.fillConvexPoly(clay, (t * 8).round().astype(np.int32), (int(col[i]),) * 3, lineType=cv2.LINE_8, shift=3)
    # outline from the silhouette so thin parts read
    cnts = cv2.findContours((sil > 0).astype(np.uint8), cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)[0]
    cv2.drawContours(clay, cnts, -1, (30, 30, 30), 3)
    return sil, clay, dict(height_m=float(up.max() - up.min()), top_m=float(up.max()), bottom_m=float(up.min()))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('model', nargs='?', default=DEFAULT_MODEL); ap.add_argument('--out', required=True)
    ap.add_argument('--views', nargs='+', default=VIEWS); ap.add_argument('--forward', default='+z', choices=['+z', '-z', '+x', '-x'])
    ap.add_argument('--scale', type=float, default=1.0); ap.add_argument('--normalize-height', action='store_true')
    ap.add_argument('--keep-mace', action='store_true', help='do not drop the Morrow mace islands (reference has none)'); ap.add_argument('--no-clay', action='store_true')
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    verts, faces = load_mesh(a.model); info = {}
    dropped = 0
    if not a.keep_mace: faces, dropped = drop_mace(verts, faces, a.forward)
    for v in a.views:
        sil, clay, meta = render(v, verts, faces, a.forward, a.scale, a.normalize_height)
        cv2.imwrite(os.path.join(a.out, f'sil_{v}.png'), sil)
        if not a.no_clay: cv2.imwrite(os.path.join(a.out, f'clay_{v}.png'), clay)
        info[v] = meta
    json.dump(dict(model=os.path.relpath(a.model, ROOT) if a.model.startswith(ROOT) else a.model, forward=a.forward, px_per_m=PPM, ground_row=GROUND, pad_px=PAD,
                   views=info, mace_faces_dropped=dropped, note='rest/A-pose render; mace islands dropped unless --keep-mace; front reference is 3/4 so front compare is qualitative'), open(os.path.join(a.out, 'render_info.json'), 'w'), indent=1)
    print('rendered', list(info), info[a.views[0]])
if __name__ == '__main__': main()
