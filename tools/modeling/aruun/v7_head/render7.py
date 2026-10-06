"""Verification renders of the head from the SAME cameras as the reference crops + overlay.
usage: python3 render7.py BLEND OUTDIR [--only side,front,back]
per view: ref.png (crop), clay.png (Cycles CPU, flat), parts.png (colours), overlay.png (ref + model silhouette (cyan) + plate edges (lime)), compare_<view>.png"""
import sys, os, math, json
import bpy
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
PX = 1626.667; FOFF = 0.055; L0 = 0.09; FA = 712; FS = -25
blend, out = sys.argv[1], sys.argv[2]
ONLY = sys.argv[sys.argv.index('--only') + 1].split(',') if '--only' in sys.argv else ['side', 'front', 'back']
os.makedirs(out, exist_ok=True)
# view = (ref name, crop box, zoom, camera dir (from centre toward camera), world centre builder)
def centre_side():  # px (605,640)
    return Vector((L0, -((605 - 436) / PX - FOFF), (4000 - 640) / PX))
VIEWS = {
 'side':  dict(ref='side_completed', box=(330, 480, 880, 800), zoom=2, cam=(-1, 0, 0), ctr=centre_side(), width_m=550 / PX),
 'front': dict(ref='face_calm', box=(480, 420, 940, 900), zoom=2, cam=(0, -1, 0), ctr=Vector((L0 + (710 - FA) / PX, -(0.5), (4000 - (660 + FS)) / PX)), width_m=460 / PX),
 'back':  dict(ref='back_completed', box=(409, 440, 909, 840), zoom=2, cam=(0, 1, 0), ctr=Vector((L0, 0, (4000 - 640) / PX)), width_m=500 / PX),
}
VIEWS['front']['ctr'].y = 0.0
def setup(sc, v, w, h):
    sc.render.resolution_x, sc.render.resolution_y = w, h; sc.render.resolution_percentage = 100
    cam = bpy.data.objects.get('cam7')
    if cam is None:
        cd = bpy.data.cameras.new('cam7'); cd.type = 'ORTHO'; cam = bpy.data.objects.new('cam7', cd); sc.collection.objects.link(cam)
    cam.data.ortho_scale = v['width_m']; cam.data.clip_end = 20
    d = Vector(v['cam']); cam.location = v['ctr'] + d * 3
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler(); sc.camera = cam
    return cam
def render(path): bpy.context.scene.render.filepath = path; bpy.ops.render.render(write_still=True)
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
HEADMESH = [o for o in meshes if not o.name.startswith('cam')]
if 'sun7' not in bpy.data.objects:
    sd = bpy.data.lights.new('sun7', 'SUN'); sd.energy = 3.2; sun = bpy.data.objects.new('sun7', sd); sc.collection.objects.link(sun)
sun = bpy.data.objects['sun7']
sc.world = sc.world or bpy.data.worlds.new('w'); sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.82, 0.82, 0.80, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.9
clay = bpy.data.materials.new('clay7'); clay.use_nodes = True; clay.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.6, 0.6, 0.6, 1); clay.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.9
for vn in ONLY:
    v = VIEWS[vn]; w = (v['box'][2] - v['box'][0]) * v['zoom']; h = (v['box'][3] - v['box'][1]) * v['zoom']
    cam = setup(sc, v, w, h)
    d = Vector(v['cam']); sun.location = v['ctr'] + (d + Vector((-0.5, 0.2, 0.9))).normalized() * 6
    sun.rotation_euler = (v['ctr'] - sun.location).to_track_quat('-Z', 'Y').to_euler()
    # clay (Cycles)
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 32; sc.cycles.use_denoising = False
    sc.view_layers[0].material_override = clay; sc.render.film_transparent = False
    sc.view_settings.view_transform = 'Standard'
    render(f'{out}/{vn}_clay.png'); sc.view_layers[0].material_override = None
    # parts (Cycles, material colours, quick)
    sc.cycles.samples = 12; render(f'{out}/{vn}_parts.png')
    # id pass: unique emission per object, 1 sample, no AA
    sc.cycles.samples = 1; sc.render.filter_size = 0.01; sc.render.dither_intensity = 0.0
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0, 0, 0, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0
    ids = {}; saved = {}
    for i, o in enumerate(HEADMESH):
        c = ((i * 53) % 255 + 1, (i * 97) % 255 + 1, (i * 29) % 255 + 1); ids[o.name] = c
        m = bpy.data.materials.new('id_' + o.name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
        e = nt.nodes.new('ShaderNodeEmission'); e.inputs[0].default_value = (c[0] / 255, c[1] / 255, c[2] / 255, 1); e.inputs[1].default_value = 1.0
        oo = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(e.outputs[0], oo.inputs[0])
        saved[o.name] = list(o.data.materials); o.data.materials.clear(); o.data.materials.append(m)
    render(f'{out}/{vn}_id.png')
    for o in HEADMESH:
        o.data.materials.clear()
        for mm in saved[o.name]: o.data.materials.append(mm)
    sc.render.filter_size = 1.5
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.82, 0.82, 0.80, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.9
    json.dump(ids, open(f'{out}/ids.json','w'))
    print(vn, 'rendered')

json.dump({k: dict(ref=v['ref'], box=v['box'], zoom=v['zoom']) for k, v in VIEWS.items()}, open(f'{out}/views.json','w'))
