"""usage: build_head6.py OUT.blend  (env STEP).  Opens LOCKED_P1b forms.blend as CONTEXT (body/neck/horns kept untouched), removes P1b head objects, builds v6 head."""
import os, sys, json, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
import head6 as H
ROOT = os.path.abspath(os.path.join(HERE, '../../../..'))
P1B = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/forms/LOCKED_P1b/forms.blend')
STEP = int(os.environ.get('STEP', '4'))
DROP = ('brow', 'cheek_plate', 'crown_plate', 'eye_socket', 'eyeball', 'horn_cup', 'mandible', 'nose_pad', 'nostril', 'skull_hull', 'temple_tine')
def main(out):
    bpy.ops.wm.open_mainfile(filepath=P1B)
    for o in list(bpy.data.objects):
        if o.name.startswith(DROP): bpy.data.objects.remove(o, do_unlink=True)
    import features6 as FE
    FE.build(STEP)
    clay = bpy.data.materials.new('clay'); clay.diffuse_color = (0.55, 0.55, 0.55, 1)
    for o in bpy.data.objects: o.data.materials.clear(); o.data.materials.append(clay)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=out); print('saved', out, [o.name for o in bpy.data.objects if o.name in FE.NAMES])
main(sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else sys.argv[1])
