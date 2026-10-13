"""Generic Tripo -> rig parts builder (used for Cigarra; Aruun's two-stage scripts predate it).
Usage: python3 tools/blender/tripo/tripo_build.py <critter> [debug]
  <critter> selects a config in CONFIGS below (source glb, orientation, scale, pivots, partition rules).
  "debug" only writes colour-coded partition renders to /tmp/cu/ci/dbg_*.png and stops (no export).
Frames: the source model is rotated into the lib frame (x = forward, y = across with the RIGHT hand at -y, z = up), then scaled so feet = 0."""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector, Matrix
CID = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else (sys.argv[1] if len(sys.argv) > 1 else "cigarra")
DEBUG = "debug" in sys.argv
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "v2", "art", "models")
NAMES = ["torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]

RIGHT_ARM = [(-0.03, -0.16, 0.65), (0.01, -0.18, 0.57), (0.07, -0.12, 0.52), (0.08, -0.12, 0.44)]

def _seg_dist(p, poly):
    best = 9.0
    for a, b in zip(poly, poly[1:]):
        ab = [b[i] - a[i] for i in range(3)]
        ap = [p[i] - a[i] for i in range(3)]
        t = max(0.0, min(1.0, sum(ab[i] * ap[i] for i in range(3)) / max(sum(v * v for v in ab), 1e-9)))
        d = math.sqrt(sum((ap[i] - ab[i] * t) ** 2 for i in range(3)))
        best = min(best, d)
    return best

def cigarra_part(c, el):
    """c = island centroid in the LIB frame BEFORE scaling (x fwd, y across [right = -y], z up, feet z=0, height 0.98)."""
    x, y, z = c
    if z >= 0.80 or (z >= 0.665 and abs(y) < 0.13 and x > -0.12):
        return "head"                                   # head, hair, crown spheres, hood collar
    if x < -0.035 and 0.07 < z < 0.70:
        return "extra"                                  # the wing-cloak behind her back
    if _seg_dist((x, y, z), RIGHT_ARM) < 0.075:
        return "arm_f"                                  # her right arm hangs forward with the hand at the belt: capsule around its measured path
    if abs(y) > 0.125 and z > 0.20:
        return "arm_f" if y < 0 else "arm_b"            # sleeves, hands, belt charms hanging at the sides (right hand = -y)
    if z < 0.50:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

CONFIGS = {
    "cigarra": dict(src="/tmp/cu/ci/cig_plain.glb", rot_z=90.0, scale=3.3, x0=0.0, y0=0.0,
                    part=cigarra_part, min_faces=0,
                    pivots={"torso": (0.0, 0.0, 0.50), "head": (0.0, 0.0, 0.68), "arm_f": (0.0, -0.15, 0.66), "arm_b": (0.0, 0.15, 0.66),
                            "leg_f": (0.0, -0.07, 0.50), "leg_b": (0.0, 0.07, 0.50), "weapon": (0.0, -0.2, 0.3), "extra": (-0.06, 0.0, 0.68)},
                    targets={"torso": 4200, "head": 5200, "arm_f": 2400, "arm_b": 2400, "leg_f": 3000, "leg_b": 3000, "weapon": 0, "extra": 3200},
                    sockets={"head": ("head", (0.08, 0.0, 0.1)), "hand": ("arm_f", (0.0, 0.0, 0.25)), "weapon_base": ("arm_f", (0.0, 0.0, 0.25)), "weapon_tip": ("arm_f", (0.3, 0.0, 0.2)),
                             "crown": ("head", (0.0, 0.0, 0.22))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.15}),
}
C = CONFIGS[CID]
S = C["scale"]
rotm = Matrix.Rotation(math.radians(C["rot_z"]), 4, "Z")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=C["src"])
src = [x for x in bpy.data.objects if x.type == "MESH"][0]
me = src.data
for v in me.vertices:
    v.co = (rotm @ (src.matrix_world @ v.co))
src.matrix_world = Matrix.Identity(4)
zmin = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= zmin
bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
seen = bytearray(len(bm.faces)); isl = []
for f in bm.faces:
    if seen[f.index]:
        continue
    st = [f]; seen[f.index] = 1; comp = []
    while st:
        cc = st.pop(); comp.append(cc)
        for e in cc.edges:
            for n in e.link_faces:
                if not seen[n.index]:
                    seen[n.index] = 1; st.append(n)
    isl.append(comp)
cents = []
for comp in isl:
    cs = Vector((0, 0, 0))
    for f in comp:
        cs += f.calc_center_median()
    cents.append(cs / len(comp))
mi = {n: i for i, n in enumerate(NAMES)}
prim = [mi[C["part"]((cs.x, cs.y, cs.z), len(comp))] for comp, cs in zip(isl, cents)]
# arms are mirror images in this A-pose: islands near the mirrored LEFT-arm islands (y > 0) that were swallowed by the trousers/torso become the RIGHT arm
if CID == "cigarra":
    left = [cents[k] for k in range(len(cents)) if prim[k] == mi["arm_b"]]
    for k, cs in enumerate(cents):
        if cs.y < -0.05 and cs.z > 0.20 and prim[k] in (mi["torso"], mi["leg_f"], mi["leg_b"]):
            m = Vector((cs.x, -cs.y, cs.z))
            if min((m - l).length for l in left) < 0.035:
                prim[k] = mi["arm_f"]
# bridging: neighbours within 0.012 (model units) share the island so rotating joints never open gaps
grid = {}
G = 0.012
for k, cs in enumerate(cents):
    grid.setdefault((int(cs.x // G), int(cs.y // G), int(cs.z // G)), []).append(k)
mask_isl = [1 << p for p in prim]
for k, cs in enumerate(cents):
    gx, gy, gz = int(cs.x // G), int(cs.y // G), int(cs.z // G)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for j in grid.get((gx + dx, gy + dy, gz + dz), ()):
                    if prim[j] != prim[k] and (cents[j] - cs).length < G:
                        mask_isl[j] |= 1 << prim[k]
mask = bytearray(len(bm.faces))
for comp, m, p in zip(isl, mask_isl, prim):
    for f in comp:
        mask[f.index] = m
        f.material_index = 1 + p
print("faces per part", {n: sum(len(c) for c, m in zip(isl, mask_isl) if m >> mi[n] & 1) for n in NAMES}, "islands", len(isl))
if DEBUG:
    bm.to_mesh(me)
    cols = [(0.8, 0.8, 0.8), (1, 0.2, 0.2), (0.2, 0.9, 0.2), (0.2, 0.4, 1), (1, 0.9, 0.1), (0.9, 0.2, 0.9), (0.1, 0.9, 0.9), (1, 0.5, 0.1)]
    orig = me.materials[0]
    for n, c in zip(NAMES, cols):
        m = bpy.data.materials.new(n); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*c, 1); me.materials.append(m)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 8; sc.cycles.device = "CPU"
    sc.render.resolution_x = 600; sc.render.resolution_y = 800
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.6, 0.65, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
    sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 3; sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 1.15
    for name, (loc, rot) in {"front": ((3, 0, 0.5), (90, 0, 90)), "side": ((0, 3, 0.5), (90, 0, 180)), "back": ((-3, 0, 0.5), (90, 0, -90)), "rside": ((0, -3, 0.5), (90, 0, 0))}.items():
        cam.location = loc; cam.rotation_euler = [math.radians(a) for a in rot]
        sc.render.filepath = f"/tmp/cu/ci/dbg_{name}.png"; bpy.ops.render.render(write_still=True)
    sys.exit(0)
srcmat = me.materials[0]
tex = None
for n in srcmat.node_tree.nodes:
    if n.type == "TEX_IMAGE" and n.image and "BaseColor" in n.image.name:
        tex = n.image
print("colour texture", tex.name if tex else None, tex.size[:] if tex else None)
tex.scale(2048, 2048)
mat = bpy.data.materials.new(CID + "_tex"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = tex; nt.links.new(ti.outputs["Color"], bsdf.inputs["Base Color"]); bsdf.inputs["Roughness"].default_value = 0.9
def to_game(p):
    return Vector(((p[0] - C["x0"]) * S, (p[1] - C["y0"]) * S, p[2] * S))
objs = []
for i, name in enumerate(NAMES):
    if C["targets"].get(name, 0) <= 0:
        continue
    b2 = bmesh.new(); b2.from_mesh(me); b2.faces.ensure_lookup_table()
    drop = [f for f in b2.faces if not (mask[f.index] >> i) & 1]
    bmesh.ops.delete(b2, geom=drop, context="FACES")
    bmesh.ops.remove_doubles(b2, verts=b2.verts, dist=0.0004)
    bmesh.ops.delete(b2, geom=[v for v in b2.verts if not v.link_faces], context="VERTS")
    pv = to_game(C["pivots"][name])
    for v in b2.verts:
        v.co = to_game(v.co) - pv
    m2 = bpy.data.meshes.new(name); b2.to_mesh(m2); b2.free()
    m2.materials.append(mat)
    ob = bpy.data.objects.new(name, m2); bpy.context.scene.collection.objects.link(ob)
    ob.location = pv
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    bpy.ops.mesh.customdata_custom_splitnormals_clear(); bpy.ops.object.shade_smooth()
    t0 = sum(len(p.vertices) - 2 for p in m2.polygons)
    mod = ob.modifiers.new("d", "DECIMATE"); mod.decimate_type = "COLLAPSE"; mod.ratio = min(1.0, C["targets"][name] / max(t0, 1)); mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="d"); ob.select_set(False)
    objs.append(ob)
    print(name, "tris", t0, "->", sum(len(p.vertices) - 2 for p in ob.data.polygons))
bpy.data.objects.remove(src)
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, CID + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=False,
                          export_materials="EXPORT", export_image_format="JPEG", export_jpeg_quality=86, export_cameras=False, export_lights=False)
meta = dict(C["meta"])
meta["sockets"] = {k: [part] + [round(c, 4) for c in off] for k, (part, off) in C["sockets"].items()}
json.dump(meta, open(os.path.join(OUT, CID + ".json"), "w"), indent=1)
print("done", os.path.getsize(os.path.join(OUT, CID + ".glb")))
