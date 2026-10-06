"""usage: export_head6.py WORK.blend OUTDIR -> OUTDIR/head_v6.blend + head_v6.glb with ONLY the head objects (context body/horns removed)"""
import sys, bpy
bpy.ops.wm.open_mainfile(filepath=sys.argv[1]); out = sys.argv[2]
KEEP = ('skull', 'mandible', 'eye_', 'brow_', 'cheek', 'crown_plates', 'temple_tine', 'nose_pad', 'nostril', 'horn_cup', 'nape_fringe')
for o in list(bpy.data.objects):
    if not o.name.startswith(KEEP): bpy.data.objects.remove(o, do_unlink=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=out + '/head_v6.blend')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.export_scene.gltf(filepath=out + '/head_v6.glb', export_format='GLB', use_selection=True)
print('exported', sorted(o.name for o in bpy.data.objects), {o.name: len(o.data.polygons) for o in bpy.data.objects})
