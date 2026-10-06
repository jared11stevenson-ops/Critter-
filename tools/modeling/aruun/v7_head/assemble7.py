"""usage: assemble7.py HEAD7.blend SCENE_OUT.blend -> LOCKED_P1d forms.blend with its head objects replaced by head v7 (horns/neck/body untouched)."""
import sys, bpy
head, out = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath='design/model_sheets/aruun/fidelity/forms/LOCKED_P1d/forms.blend')
DROP = ['skull_hull', 'mandible', 'eyeball_L', 'eyeball_R', 'eye_socket_L', 'eye_socket_R', 'crown_plate1', 'crown_plate2', 'crown_plate3', 'crown_tine_A', 'crown_tine_B',
        'horn_cup_A', 'horn_cup_B', 'nose_pad', 'nostril_L', 'nostril_R', 'temple_tine_L', 'temple_tine_R']
for n in DROP:
    o = bpy.data.objects.get(n)
    if o: bpy.data.objects.remove(o, do_unlink=True)
with bpy.data.libraries.load(head) as (src, dst): dst.objects = list(src.objects)
for o in dst.objects:
    if o is not None: bpy.context.scene.collection.objects.link(o)
bpy.ops.wm.save_as_mainfile(filepath=out); print('assembled', out)
