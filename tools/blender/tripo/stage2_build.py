"""Stage 2 (Tripo -> rig parts): split the cropped figure by /tmp/cu/tr/mask.bin, weld the shards, decimate each part to its triangle budget, scale into game
units (feet on y=0, body centred), put each part's origin on its joint pivot and export v2/art/models/<id>.glb (+ <id>.json sockets).
Run after stage1.  Usage: python3 tools/blender/tripo/stage2_build.py [-- <id>]"""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector
ID = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "aruun"
SRC = "/tmp/cu/tr/aruun_crop.glb"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "v2", "art", "models")
S = 7.0                                   # tripo units -> game units (horn tip ~ 4.4 tall)
Z0, X0, Y0 = -0.158, 0.06, -0.08          # feet level / body centre in the tripo frame
NAMES = ["torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]
TARGET = {"torso": 5200, "head": 3600, "arm_f": 2100, "arm_b": 2300, "leg_f": 2900, "leg_b": 3100, "weapon": 3200, "extra": 900}
PIVOT = {"torso": (0.06, -0.08, 0.15), "head": (0.08, -0.08, 0.31), "arm_f": (0.06, -0.165, 0.285), "arm_b": (0.06, 0.005, 0.285),
         "leg_f": (0.06, -0.12, 0.135), "leg_b": (0.06, -0.04, 0.135), "weapon": (0.045, -0.175, 0.08), "extra": (0.0, -0.08, 0.28)}
def to_game(p):                            # tripo frame == lib blender frame (x fwd, y across with right = -y, z up)
    return Vector(((p[0] - X0) * S, (p[1] - Y0) * S, (p[2] - Z0) * S))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
src = [x for x in bpy.data.objects if x.type == "MESH"][0]
mask = open("/tmp/cu/tr/mask.bin", "rb").read()
srcmat = src.data.materials[0]
tex = None
for n in srcmat.node_tree.nodes:
    if n.type == "TEX_IMAGE" and "Color" in (n.image.name if n.image else ""):
        tex = n.image
print("colour texture", tex.name if tex else None, tex.size[:] if tex else None)
tex.scale(2048, 2048)
mat = bpy.data.materials.new("aruun_tex"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = tex; nt.links.new(ti.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.9
objs = {}
for i, name in enumerate(NAMES):
    bm = bmesh.new(); bm.from_mesh(src.data); bm.faces.ensure_lookup_table()
    drop = [f for f in bm.faces if not (mask[f.index] >> i) & 1]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0007)
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    for v in bm.verts:
        v.co = to_game(v.co) - to_game(PIVOT[name])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    ob.location = to_game(PIVOT[name])
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.mesh.customdata_custom_splitnormals_clear()
    bpy.ops.object.shade_smooth()
    n0 = len(me.polygons)
    tris0 = sum(len(p.vertices) - 2 for p in me.polygons)
    mod = ob.modifiers.new("d", "DECIMATE"); mod.decimate_type = "COLLAPSE"; mod.ratio = min(1.0, TARGET[name] / max(tris0, 1)); mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="d")
    ob.select_set(False)
    objs[name] = ob
    print(name, "tris", tris0, "->", sum(len(p.vertices) - 2 for p in ob.data.polygons))
bpy.data.objects.remove(src)
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, ID + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=False,
                          export_materials="EXPORT", export_image_format="JPEG", export_jpeg_quality=86, export_cameras=False, export_lights=False)
# sockets in game coordinates relative to their part pivot (rig reads them as [part, x, y, z])
def sock(part, p):
    return [part] + [round(c, 4) for c in (to_game(p) - to_game(PIVOT[part]))]
grip = (0.045, -0.175, 0.08); ball = (0.162, -0.336, -0.081)
meta = {"textured": True, "face_off": True,
        "sockets": {"head": sock("head", (0.12, -0.08, 0.36)), "hand": sock("arm_f", grip), "weapon_base": sock("weapon", grip), "weapon_tip": sock("weapon", ball)}}
json.dump(meta, open(os.path.join(OUT, ID + ".json"), "w"), indent=1)
print("done", os.path.getsize(os.path.join(OUT, ID + ".glb")))
