"""Gate 2 pass 1b: REBUILD of head and horns by reference-driven construction on top of the Gate-1 proxy (v4_proxy, LOCKED_BASELINE_03) + the pass-1 pauldron/shoulder blades.
FORMS2_STAGE: 0 = rollback (proxy + pauldron/blades only) | 1 = + HORNS swept along the medial-axis curves extracted from the v2 completed side/back masks (extract_horns.py) |
2 = + HEAD visual hull (head_hull.py) | 3 = + head features.   Output dir env FORMS_OUT.  Clay grey, separate named objects."""
import os, sys, json, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
os.environ['FID_REF'] = 'v2'          # head hull + horn curves are extracted from the v2 completed masks
import bpy
import build_forms as BF
from build_forms import P, tube, ell, FW, UP, LF, nm, drop, HL
STAGE = int(os.environ.get('FORMS2_STAGE', '3'))
OUT = os.environ.get('FORMS_OUT', os.path.join(P.ROOT, 'design/model_sheets/aruun/fidelity/forms/p1b'))
CURVES = os.environ.get('HORN_CURVES', os.path.join(P.ROOT, 'design/model_sheets/aruun/fidelity/forms/horn_curves.json'))

def build():
    parts = P.build(); keep = {o.name: o for o in parts}
    if os.environ.get('NECK_D', '1') == '1': neck_d(parts)
    BF.shoulders(parts, keep)
    if os.environ.get('CHEST_D', '1') == '1':          # P1d ticket 3
        # the side reference's front extreme (F 0.268 at 1.45 m) is NOT chest mass but the red hanging fringe tail (part 33) hooking out of the shoulder strap: traced from the ref skeleton (F,U,r)
        parts.append(nm(tube('fringe_tail', [(0.190, 1.545, -0.10), (0.215, 1.520, -0.10), (0.243, 1.495, -0.10), (0.256, 1.463, -0.10), (0.257, 1.445, -0.10), (0.245, 1.427, -0.10), (0.225, 1.420, -0.10)],
                             [(0.006, 0.006), (0.007, 0.007), (0.0075, 0.0075), (0.0075, 0.0075), (0.010, 0.010), (0.011, 0.011), (0.004, 0.004)]), 'fringe_tail'))
        # chest plate: flush with the trunk front (side silhouette unchanged), gives the front chest line / sternum plate in the 3D forms
        parts.append(nm(ell('chest_plate', (0.168, 1.50, 0.0), (0.034, 0.075, 0.14)), 'chest_plate'))                                  # pass-1 pauldron + underplate + shoulder blades (kept)
    if os.environ.get('LEGS_E', '1') == '1': legs_e(parts)
    if STAGE >= 1: horns(parts)
    if STAGE >= 2:
        if os.environ.get('P1C', '0') == '1':
            import head_loft; head_loft.build_loft(parts)                       # P1c: subdivision skull + mandible lofted from measured sections
        else:
            import head_hull; head_hull.build_hull(parts, split_jaw=(STAGE >= 3))
    if STAGE >= 3:
        if os.environ.get('P1C', '0') == '1':
            import head_plates; head_plates.build(parts)
        else:
            import head_features; head_features.build(parts)
    return parts

def legs_e(parts):
    """P1e ticket 1: knee/calf/shin shaping (calf bow at 0.50-0.60 m, shin taper at 0.30-0.40 m, flush knee plate) from the width-error CSVs; blades attached to the trapezius."""
    for n in ('legL', 'legR', 'shoulder_blade_L', 'shoulder_blade_R'): drop(parts, n)
    parts.append(nm(tube('legL', [(0.0, 0.92, 0.17), (-0.03, 0.74, 0.18), (-0.115, 0.60, 0.15), (-0.150, 0.50, 0.12), (-0.158, 0.42, 0.115), (-0.162, 0.34, 0.13), (-0.162, 0.28, 0.145), (-0.162, 0.22, 0.17), (-0.162, 0.15, 0.175)],
                     [(0.09, 0.10), (0.075, 0.105), (0.088, 0.115), (0.078, 0.112), (0.055, 0.085), (0.044, 0.058), (0.046, 0.062), (0.075, 0.075), (0.075, 0.085)]), 'legL'))
    parts.append(nm(tube('legR', [(0.0, 0.92, -0.26), (-0.03, 0.74, -0.29), (-0.068, 0.67, -0.30), (-0.115, 0.60, -0.30), (-0.150, 0.50, -0.30), (-0.158, 0.42, -0.325), (-0.162, 0.34, -0.332), (-0.162, 0.28, -0.335), (-0.162, 0.22, -0.335), (-0.162, 0.15, -0.34)],
                     [(0.09, 0.13), (0.075, 0.16), (0.075, 0.17), (0.088, 0.115), (0.078, 0.11), (0.055, 0.075), (0.044, 0.052), (0.046, 0.055), (0.075, 0.065), (0.075, 0.075)]), 'legR'))
    for sgn, L, n in ((1, 0.15, 'L'), (-1, -0.30, 'R')):
        parts.append(nm(ell('knee_plate_' + n, (-0.045, 0.615, L), (0.020, 0.045, 0.060)), 'knee_plate_' + n))
    # shoulder blades attached: plates sunk into the back, joined to the neck base by trapezius ridges
    for sgn, n in ((1, 'L'), (-1, 'R')):
        parts.append(nm(ell('shoulder_blade_' + n, (-0.188, 1.50, 0.115 * sgn), (0.022, 0.115, 0.070)), 'shoulder_blade_' + n))
        parts.append(nm(tube('trapezius_' + n, [(-0.185, 1.58, 0.115 * sgn), (-0.150, 1.68, 0.075 * sgn), (-0.100, 1.76, 0.035 * sgn)], [(0.030, 0.035), (0.032, 0.030), (0.030, 0.025)]), 'trapezius_' + n))

def neck_d(parts):
    """P1d ticket 2: neck re-pathed 0.02-0.025 m forward at 1.84-1.90 m (side error was -0.02..-0.03 at the throat), top radii matched to the head hull's neck blend (F 0.058 / L 0.07) so the collar ring at the skull junction disappears."""
    drop(parts, 'neck')
    parts.append(nm(tube('neck', [(-0.05, 1.70, 0.0), (-0.035, 1.78, 0.03), (0.000, 1.84, 0.055), (0.022, 1.90, 0.068), (0.018, 1.945, 0.075), (0.008, 1.975, 0.080)],
                         [(0.15, 0.22), (0.085, 0.105), (0.062, 0.062), (0.056, 0.056), (0.056, 0.060), (0.058, 0.066)]), 'neck'))

def horns(parts):
    for n in ('hornA', 'hornB', 'hornB_tooth'): drop(parts, n)
    C = json.load(open(CURVES))
    if os.environ.get('HORNS_D', '1') == '1':
        import horns_blade; horns_blade.build(parts, C); return
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
