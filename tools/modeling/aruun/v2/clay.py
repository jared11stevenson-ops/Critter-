"""bpy clay-render board of (V,F) shells: clay(shells: dict name->(V,F), out.png, yaws)."""
import sys, os
import numpy as np
import bpy
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import render as R

def clay(shells, out, yaws=(0, 45, 90, 180), res=(420, 760), samples=16, cols=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for i, (n, (V, F)) in enumerate(shells.items()):
        me = bpy.data.meshes.new(n); me.from_pydata(V.tolist(), [], F.tolist()); me.update()
        ob = bpy.data.objects.new(n, me); bpy.context.scene.collection.objects.link(ob)
        m = bpy.data.materials.new(n); m.use_nodes = True
        c = (cols or {}).get(n, (0.8, 0.75, 0.68, 1))
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = c
        m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
        ob.data.materials.append(m)
        for p in me.polygons: p.use_smooth = True
    R.setup_cycles(res=res, samples=samples); R.add_lights()
    cam = R.camera(ortho_scale=2.7)
    tiles = []
    for i, y in enumerate(yaws):
        R.place_camera(cam, (0, 0, 1.2), y, 5, 10)
        p = "/tmp/claude-0/s/_cl_%d.png" % i
        R.render(p); tiles.append(Image.open(p).convert("RGBA"))
    W = sum(t.width for t in tiles); im = Image.new("RGBA", (W, tiles[0].height), (200, 190, 175, 255)); x = 0
    for t in tiles: im.alpha_composite(t, (x, 0)); x += t.width
    im.convert("RGB").save(out); print("wrote", out)

if __name__ == "__main__":
    d = np.load(os.path.join(HERE, "..", "work", "v2", sys.argv[1]))
    names = sorted({k[2:] for k in d.files if k.startswith("V_")})
    clay({n: (d["V_" + n], d["F_" + n]) for n in names}, sys.argv[2])
