"""Gate 2 pass 1b: REBUILD of head and horns by reference-driven construction on top of the Gate-1 proxy (v4_proxy, LOCKED_BASELINE_03) + the pass-1 pauldron/shoulder blades.
FORMS2_STAGE: 0 = rollback (proxy + pauldron/blades only) | 1 = + HORNS swept along the medial-axis curves extracted from the v2 completed side/back masks (extract_horns.py) |
2 = + HEAD visual hull (head_hull.py) | 3 = + head features.   Output dir env FORMS_OUT.  Clay grey, separate named objects."""
import os, sys, json, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
import build_forms as BF
from build_forms import P, tube, ell, FW, UP, LF, nm, drop, HL
STAGE = int(os.environ.get('FORMS2_STAGE', '3'))
OUT = os.environ.get('FORMS_OUT', os.path.join(P.ROOT, 'design/model_sheets/aruun/fidelity/forms/p1b'))
CURVES = os.environ.get('HORN_CURVES', os.path.join(P.ROOT, 'design/model_sheets/aruun/fidelity/forms/horn_curves.json'))

def build():
    parts = P.build(); keep = {o.name: o for o in parts}
    BF.shoulders(parts, keep)                                  # pass-1 pauldron + underplate + shoulder blades (kept)
    if STAGE >= 1: horns(parts)
    if STAGE >= 2:
        import head_hull; head_hull.build_hull(parts)
    if STAGE >= 3:
        import head_features; head_features.build(parts)
    return parts

def horns(parts):
    for n in ('hornA', 'hornB', 'hornB_tooth'): drop(parts, n)
    C = json.load(open(CURVES))
    for n, hint, order in (('A', LF, (1, 0)), ('B', FW, (0, 1))):
        pts = np.array(C[n]['points_FUL']); rad = np.array(C[n]['radii_FL'])
        r = rad[:, list(order)] * float(os.environ.get('HORN_R_SCALE', '1.15'))
        r[-3:] *= np.array([[0.7], [0.5], [0.3]])             # taper the last points to a point
        parts.append(nm(tube('horn' + n, pts, r, hint=hint, sub=2), 'horn' + n))
        if n == 'B':        # the dark hooked needle at the tip of B (v2 completed side view: tip at F 0.331, U 2.31)
            e = pts[-1]; parts.append(nm(tube('hornB_needle', [e, (e[0] + 0.035, e[1] - 0.035, e[2]), (0.331, 2.31, e[2])], [(0.012, 0.012), (0.007, 0.007), (0.002, 0.002)], hint=FW, sub=3), 'hornB_needle'))

def main():
    os.makedirs(OUT, exist_ok=True)
    parts = build()
    mat = bpy.data.materials.new('clay'); mat.diffuse_color = (0.55, 0.55, 0.55, 1)
    for o in bpy.data.objects: o.data.materials.clear(); o.data.materials.append(mat)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'forms.blend'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'forms.glb'), export_format='GLB', use_selection=True)
    print('wrote', OUT, 'stage', STAGE, len(bpy.data.objects), 'objects')
if __name__ == '__main__': main()
