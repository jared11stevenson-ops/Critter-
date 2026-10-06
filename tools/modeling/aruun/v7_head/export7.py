"""usage: export7.py HEAD.blend OUTDIR -> head_v7.blend + head_v7.glb + stats"""
import sys, bpy, os
src, out = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=src)
tris = 0; xs = []; ys = []; zs = []
for o in bpy.data.objects:
    if o.type != 'MESH': continue
    tris += sum(len(p.vertices) - 2 for p in o.data.polygons)
    for v in o.data.vertices:
        w = o.matrix_world @ v.co; xs.append(w.x); ys.append(w.y); zs.append(w.z)
m = bpy.data.objects['mandible']
print('STATS tris', tris, 'objects', len(bpy.data.objects), 'F range', round(-max(ys), 3), round(-min(ys), 3), 'U', round(min(zs), 3), round(max(zs), 3), 'L', round(min(xs), 3), round(max(xs), 3), 'mandible pivot (L,F,U)', tuple(round(c, 3) for c in (m.location.x, -m.location.y, m.location.z)))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'head_v7.blend'))
bpy.ops.object.select_all(action='SELECT'); bpy.ops.export_scene.gltf(filepath=os.path.join(out, 'head_v7.glb'), export_format='GLB', use_selection=True)
