"""GATE 2 / PASS 1 primary forms for Aruun, built ON the Gate-1 proxy (tools/modeling/aruun/v4_proxy/build_proxy.py, = LOCKED_BASELINE_03, the proxy after
correction round 3). Clay grey, no materials. Coordinates (F, U, L) = (forward, up, his LEFT) metres. Image-right in the BACK view = his RIGHT = L<0.
FORMS_STAGE=0 proxy only | 1 +HEAD | 2 +HORNS | 3 +PAULDRON/shoulder blades (cumulative; default 3).  Output dir: env FORMS_OUT (default design/.../forms).
Run: python3 tools/modeling/aruun/v5_forms/build_forms.py
Every form is a separate named object (eyeball_L, mandible, nose_pad, ...), so materials/rig can address them later."""
import os, sys, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'v4_proxy'))
import bpy
import build_proxy as P
from build_proxy import tube, ell, FW, UP, LF

ROOT = P.ROOT
OUT = os.environ.get('FORMS_OUT', os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/forms'))
STAGE = int(os.environ.get('FORMS_STAGE', '3'))
HL = 0.09            # head centre line (L), as in the proxy
SKULL_L_SCALE = float(os.environ.get('SKULL_L_SCALE', '0.85'))

def to_bl(F, U, L): return (L, -F, U)

def set_pivot(ob, F, U, L):
    """move the object origin to the world point (F,U,L) without moving the geometry"""
    p = np.array(to_bl(F, U, L))
    for v in ob.data.vertices: v.co = v.co - __import__('mathutils').Vector(p)
    ob.location = __import__('mathutils').Vector(p)

def rename(parts, old, new=None):
    for o in parts:
        if o.name == old: return o

def drop(parts, name):
    for o in list(parts):
        if o.name == name:
            parts.remove(o); bpy.data.objects.remove(o, do_unlink=True)

def nm(ob, name):
    ob.name = name; ob.data.name = name; return ob

def build():
    parts = P.build()
    keep = {o.name: o for o in parts}
    if STAGE >= 1: head(parts, keep)
    if STAGE >= 2: horns(parts, keep)
    if STAGE >= 3: shoulders(parts, keep)
    return parts

# ------------------------------------------------------------------------------------------ FORM 1: HEAD
def head(parts, keep):
    nm(keep['cranium'], 'skull')                      # dark navy skull (measured proxy cranium, unchanged)
    # the face features (eyes, cheek plates, brows) now carry part of the measured head width, so the skull core is narrowed by SKULL_L_SCALE below the crown plates
    sk = keep['cranium']
    for v in sk.data.vertices:
        if v.co.z < 2.095: v.co.x = HL + (v.co.x - HL) * SKULL_L_SCALE
    drop(parts, 'snout')                              # replaced by upper muzzle + separate mandible (union ~ the proxy snout)
    add = []
    # upper muzzle (maxilla): thick root, long taper to the nose pad; droops slightly
    add.append(nm(tube('muzzle_upper', [(0.00, 2.062, HL), (0.07, 2.048, HL), (0.13, 2.034, HL), (0.165, 2.022, HL)],
                       [(0.052, 0.075), (0.040, 0.060), (0.027, 0.045), (0.015, 0.034)], hint=UP), 'muzzle_upper'))
    # nose pad + two nostrils at the tip
    add.append(nm(ell('nose_pad', (0.168, 2.024, HL), (0.018, 0.016, 0.034)), 'nose_pad'))
    for s, n in ((1, 'L'), (-1, 'R')):
        add.append(nm(ell('nostril_' + n, (0.180, 2.027, HL + 0.016 * s), (0.008, 0.007, 0.007)), 'nostril_' + n))
    # separate lower jaw with the hooked chin; origin = jaw pivot (condyle) so it can open
    jaw = tube('mandible', [(0.000, 2.012, HL), (0.06, 2.005, HL), (0.12, 2.005, HL), (0.165, 2.004, HL), (0.192, 2.000, HL)],
               [(0.032, 0.062), (0.026, 0.050), (0.022, 0.040), (0.016, 0.030), (0.011, 0.014)], hint=UP)
    set_pivot(jaw, -0.02, 2.02, HL); add.append(nm(jaw, 'mandible'))
    # eyes on the SIDES of the head + brow ridges + cheek plates (symmetric about the head centre line)
    for s, n in ((1, 'L'), (-1, 'R')):
        add.append(nm(ell('eyeball_' + n, (0.058, 2.077, HL + 0.098 * s), (0.020, 0.023, 0.016)), 'eyeball_' + n))
        add.append(nm(tube('brow_' + n, [(-0.01, 2.100, HL + 0.082 * s), (0.04, 2.103, HL + 0.090 * s), (0.065, 2.098, HL + 0.075 * s)],
                           [(0.012, 0.012), (0.014, 0.014), (0.008, 0.008)], hint=UP), 'brow_' + n))
        add.append(nm(ell('cheek_plate_' + n, (0.045, 2.035, HL + 0.088 * s), (0.050, 0.030, 0.014)), 'cheek_plate_' + n))
    # red crown plates (flat, inside the measured crown envelope) + horn cups at the horn roots
    add.append(nm(ell('crown_plate', (0.040, 2.118, HL), (0.050, 0.014, 0.085)), 'crown_plate'))
    add.append(nm(ell('horn_cup_A', (-0.020, 2.128, 0.000), (0.040, 0.026, 0.040)), 'horn_cup_A'))
    add.append(nm(ell('horn_cup_B', (0.070, 2.122, 0.040), (0.040, 0.026, 0.040)), 'horn_cup_B'))
    parts.extend(add)

# ------------------------------------------------------------------------------------------ FORM 2: HORNS
def horns(parts, keep):
    add = []
    # knobbed joints on each shaft (rings slightly thicker than the shaft) -- positions are fractions of the proxy path
    def knob(name, c, r): add.append(nm(ell(name, c, r), name))
    knob('hornA_knob1', (0.000, 2.20, 0.000), (0.030, 0.014, 0.025))
    knob('hornA_knob2', (0.060, 2.335, -0.008), (0.022, 0.014, 0.019))
    knob('hornB_knob1', (0.095, 2.19, 0.100), (0.027, 0.014, 0.023))
    knob('hornB_knob2', (0.185, 2.32, 0.190), (0.022, 0.013, 0.019))
    # cream tines at the knobs (short bone spurs) and the long TEMPLE TINES at the sides of the head (back view: left long, right short)
    add.append(nm(tube('temple_tine_L', [(0.000, 2.095, HL + 0.07), (-0.015, 2.100, HL + 0.115), (-0.035, 2.103, HL + 0.155)],
                       [(0.014, 0.010), (0.011, 0.008), (0.004, 0.004)], hint=UP), 'temple_tine_L'))
    add.append(nm(tube('temple_tine_R', [(0.000, 2.095, HL - 0.07), (0.010, 2.100, HL - 0.12), (0.020, 2.103, HL - 0.168)],
                       [(0.012, 0.009), (0.010, 0.007), (0.004, 0.004)], hint=UP), 'temple_tine_R'))
    parts.extend(add)

# ------------------------------------------------------------------------------------------ FORM 3: PAULDRON + SHOULDER BLADES
def shoulders(parts, keep):
    drop(parts, 'pauldronL')
    add = []
    # red ladybug disc on his LEFT shoulder (same measured envelope as the proxy ellipsoid), domed outward; tan underplate beneath it
    add.append(nm(ell('pauldron_disc', (-0.10, 1.585, 0.235), (0.14, 0.15, 0.095)), 'pauldron_disc'))
    add.append(nm(ell('pauldron_underplate', (-0.10, 1.455, 0.215), (0.105, 0.045, 0.09)), 'pauldron_underplate'))
    # tan shoulder blades (carapace plates, part 14) on the back, a few mm proud of the trunk
    for s, n in ((1, 'L'), (-1, 'R')):
        add.append(nm(ell('shoulder_blade_' + n, (-0.192, 1.50, 0.115 * s), (0.026, 0.115, 0.070)), 'shoulder_blade_' + n))
    parts.extend(add)

def main():
    os.makedirs(OUT, exist_ok=True)
    parts = build()
    mat = bpy.data.materials.new('clay'); mat.diffuse_color = (0.55, 0.55, 0.55, 1)
    for o in bpy.data.objects:
        o.data.materials.clear(); o.data.materials.append(mat)
    bpy.context.preferences.filepaths.save_version = 0       # no .blend1 backups
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'forms.blend'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'forms.glb'), export_format='GLB', use_selection=True)
    print('wrote', OUT, 'stage', STAGE, len(bpy.data.objects), 'objects')

if __name__ == '__main__': main()
