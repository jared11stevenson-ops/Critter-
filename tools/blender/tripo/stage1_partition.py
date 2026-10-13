"""Stage 1 (Tripo -> rig parts): load the cropped Tripo figure, drop tiny fragments, assign each whole island (armour plate, strip, stud...) to a rig part,
and save /tmp/cu/tr/stage1.blend (objects named torso/head/arm_f/arm_b/leg_f/leg_b/weapon/extra) + a colour-coded debug render.
Blender frame here = the Tripo file's own frame: +x = the way the figure faces, y = across (right hand is -y), z = up."""
import bpy, bmesh, math, sys, json
from mathutils import Vector
SRC = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/cu/tr/aruun_crop.glb"
P = dict(yc=-0.08, min_faces=0, head_z=0.312, hip_z=0.135, arm_dy=0.075, weapon_y=-0.205, back_x=0.005, arm_z0=0.035)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
o = [x for x in bpy.data.objects if x.type == "MESH"][0]
bm = bmesh.new(); bm.from_mesh(o.data); bm.faces.ensure_lookup_table()
seen = bytearray(len(bm.faces)); isl = []
for f in bm.faces:
    if seen[f.index]:
        continue
    st = [f]; seen[f.index] = 1; comp = []
    while st:
        c = st.pop(); comp.append(c)
        for e in c.edges:
            for n in e.link_faces:
                if not seen[n.index]:
                    seen[n.index] = 1; st.append(n)
    isl.append(comp)
print("islands", len(isl))
NAMES = ["torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]
LINE = {}
def part_of(cx, cy, cz, elong=0.0):
    dy = cy - P["yc"]
    if elong > 2.8:
        return "weapon"
    if LINE:
        a, d = LINE["a"], LINE["d"]
        v = Vector((cx, cy, cz)) - a
        t = v.dot(d)
        if -0.02 < t < LINE["len"] + 0.03 and (v - d * t).length < 0.03:
            return "weapon"
    if cy < P["weapon_y"]:
        return "weapon"
    if cz >= P["head_z"] and abs(dy) < 0.13:
        return "head"
    if (cz > 0.15 and cx < 0.005) or (0.0 < cz <= 0.15 and cx < 0.025):
        return "extra"
    if abs(dy) > 0.07 and cz > P["arm_z0"]:
        return "arm_f" if dy < 0 else "arm_b"
    if cz < P["hip_z"]:
        return "leg_f" if dy < 0 else "leg_b"
    return "torso"
# pass 0: find the mace axis (ball centre C -> grip H) so the pole that continues behind the shoulder also belongs to the weapon
cents = []
for c in isl:
    cs = Vector((0, 0, 0)); lo = Vector((9, 9, 9)); hi = Vector((-9, -9, -9))
    for f in c:
        cs += f.calc_center_median()
        for v in f.verts:
            for i in range(3):
                lo[i] = min(lo[i], v.co[i]); hi[i] = max(hi[i], v.co[i])
    dd = sorted([hi[i] - lo[i] for i in range(3)], reverse=True)
    cents.append((cs / len(c), len(c), dd[0] / max(dd[1], 1e-4) if dd[0] > 0.04 else 0.0))
ball = [(p, n) for p, n, _e in cents if p.y < -0.28 and p.z < 0.12]
C = sum((p * n for p, n in ball), Vector((0, 0, 0))) / sum(n for p, n in ball)
shaft = [p for p, n, _e in cents if -0.28 <= p.y < -0.2 and (p - C).length > 0.1]
H = sum(shaft, Vector((0, 0, 0))) / len(shaft)
LINE["a"] = Vector((0.045, -0.175, 0.08)); LINE["d"] = (Vector((-0.12, 0.005, 0.235)) - LINE["a"]).normalized(); LINE["len"] = (Vector((-0.12, 0.005, 0.235)) - LINE["a"]).length   # pole measured off the back/side views
print("mace C", tuple(round(x, 3) for x in C), "H", tuple(round(x, 3) for x in H), "d", tuple(round(x, 3) for x in LINE["d"]))
kill = []
counts = {n: 0 for n in NAMES}
mi = {n: i for i, n in enumerate(NAMES)}
prim = []
for c, (cs, _n, el) in zip(isl, cents):
    nm = part_of(cs.x, cs.y, cs.z, el)
    prim.append(mi[nm])
# bridging: an island also joins every neighbouring part whose island centroid is within 0.03, so a rotating joint never opens a gap
grid = {}
for k, (cs, _n, _e) in enumerate(cents):
    grid.setdefault((int(cs.x // 0.03), int(cs.y // 0.03), int(cs.z // 0.03)), []).append(k)
mask_isl = [1 << p for p in prim]
for k, (cs, _n, _e) in enumerate(cents):
    gx, gy, gz = int(cs.x // 0.03), int(cs.y // 0.03), int(cs.z // 0.03)
    for dx in (-1, 0, 1):
        for dy_ in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for j in grid.get((gx + dx, gy + dy_, gz + dz), ()):
                    if prim[j] != prim[k] and (cents[j][0] - cs).length < 0.03:
                        mask_isl[j] |= 1 << prim[k]
mask = bytearray(len(bm.faces))
for c, m, p in zip(isl, mask_isl, prim):
    for f in c:
        mask[f.index] = m
        f.material_index = 1 + p
counts = {n: sum(len(c) for c, m in zip(isl, mask_isl) if m >> mi[n] & 1) for n in NAMES}
print("faces per part (with bridging)", counts)
open("/tmp/cu/tr/mask.bin", "wb").write(bytes(mask))
bmesh.ops.delete(bm, geom=kill, context="FACES_ONLY")
bm.to_mesh(o.data); bm.free()
# debug materials (kept for the debug render; stage 2 replaces them)
cols = [(0.8, 0.8, 0.8), (1, 0.2, 0.2), (0.2, 0.9, 0.2), (0.2, 0.4, 1), (1, 0.9, 0.1), (0.9, 0.2, 0.9), (0.1, 0.9, 0.9), (1, 0.5, 0.1)]
for n, c in zip(NAMES, cols):
    m = bpy.data.materials.new(n); m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*c, 1); m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    o.data.materials.append(m)
bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.mesh.separate(type="MATERIAL") if False else None
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 6; sc.cycles.device = "CPU"
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.6, 0.65, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.3
sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 3; sun.rotation_euler = (math.radians(50), 0, math.radians(30))
sc.render.resolution_x = 700; sc.render.resolution_y = 800
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 0.8
cy, cz = -0.175, 0.15
for name, (loc, rot) in {"front": ((3, cy, cz), (90, 0, 90)), "back": ((-3, cy, cz), (90, 0, -90)), "left": ((0, 3, cz), (90, 0, 180))}.items():
    cam.location = loc; cam.rotation_euler = [math.radians(a) for a in rot]
    sc.render.filepath = f"/tmp/cu/tr/p_{name}.png"; bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath="/tmp/cu/tr/stage1.blend")
json.dump(P, open("/tmp/cu/tr/stage1_params.json", "w"))
