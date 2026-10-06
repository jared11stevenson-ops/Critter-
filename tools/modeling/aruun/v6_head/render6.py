"""Close-up Workbench renders of the head (front, side, 3/4, back) and optional shoulder, clay grey (+ a 'parts' debug set coloured by object).
usage: python3 render_closeups.py forms.blend OUTDIR [--target head|shoulder]. Orthographic, same framing for all views."""
import sys, os, math, bpy
from mathutils import Vector
blend, out = sys.argv[1], sys.argv[2]
target = 'head'
ONLY = '--only' in sys.argv; SCALE = float(sys.argv[sys.argv.index('--scale') + 1]) if '--scale' in sys.argv else 0.62
os.makedirs(out, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 24; sc.cycles.use_denoising = False
sc.render.resolution_x = sc.render.resolution_y = 900
sc.world = sc.world or bpy.data.worlds.new('w'); sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.80, 0.80, 0.78, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.8
# (F,U,L) centre and ortho scale (m)
C, SC = (0.05, 2.12, 0.09), SCALE
ctr = Vector((C[2], -C[0], C[1]))                    # blender (L, -F, U)
cam_d = bpy.data.cameras.new('c'); cam_d.type = 'ORTHO'; cam_d.ortho_scale = SC; cam_d.clip_end = 50
cam = bpy.data.objects.new('cam', cam_d); sc.collection.objects.link(cam); sc.camera = cam
tgt = bpy.data.objects.new('t', None); tgt.location = ctr; sc.collection.objects.link(tgt)
tc = cam.constraints.new('TRACK_TO'); tc.target = tgt; tc.track_axis = 'TRACK_NEGATIVE_Z'; tc.up_axis = 'UP_Y'
sun_d = bpy.data.lights.new('sun', 'SUN'); sun_d.energy = 3.0; sun = bpy.data.objects.new('sun', sun_d); sc.collection.objects.link(sun)
dirs = {'front': (0, -1, 0.0), 'side': (-1, 0, 0.0), 'q34': (0.62, -0.78, 0.15), 'back': (0, 1, 0.0)}
import colorsys
KEEP = ('nape','nostril','skull','mandible','eye_','brow_','cheek_','crown_','temple_','nose_','horn_cup','neck')
if ONLY:
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and not o.name.startswith(KEEP): o.hide_render = True
meshes = [o for o in bpy.data.objects if o.type == 'MESH' and not o.hide_render]
def mat(name, col):
    m = bpy.data.materials.new(name); m.diffuse_color = col; m.use_nodes = True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = col; m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.9
    return m
clay = mat('clayview', (0.55, 0.55, 0.55, 1))
for mode in (('clay',) if '--clayonly' in sys.argv else ('clay', 'parts')):
    for i, o in enumerate(meshes):
        o.data.materials.clear(); o.data.materials.append(clay if mode == 'clay' else mat('p%d' % i, (*colorsys.hsv_to_rgb((i * 0.37) % 1, 0.55, 0.9), 1)))
    for k, d in dirs.items():
        v = Vector(d).normalized(); cam.location = ctr + v * 4
        sun.location = ctr + (v + Vector((-0.5, 0.2, 0.9))).normalized() * 6; sun.rotation_euler = (ctr - sun.location).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = os.path.join(out, f'head_{mode}_{k}.png'); bpy.ops.render.render(write_still=True)
print('closeups ->', out)
