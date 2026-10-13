"""Stage 0: the Tripo upload contained the whole model SHEET as one 1.8M-triangle mesh. This crops the central front figure (with its mace) out of it.
Input: the meshopt-decoded glb (npx @gltf-transform/cli copy tools/source_art/aruun_tripo.glb /tmp/cu/tr/aruun_plain.glb). Output: /tmp/cu/tr/aruun_crop.glb"""
import bpy, bmesh
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="/tmp/cu/tr/aruun_plain.glb")
o = [x for x in bpy.data.objects if x.type == "MESH"][0]
bm = bmesh.new(); bm.from_mesh(o.data); mw = o.matrix_world
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not (-0.43 <= (mw @ v.co).y <= 0.08 and -0.2 <= (mw @ v.co).z <= 0.5)], context="VERTS")
bm.to_mesh(o.data); bm.free()
bpy.ops.export_scene.gltf(filepath="/tmp/cu/tr/aruun_crop.glb", export_format="GLB")
