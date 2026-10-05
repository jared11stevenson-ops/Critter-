import numpy as np, bpy
def make_object(path, name="Aruun"):
    d = np.load(path, allow_pickle=True)
    V, T, UVc = d["V"], d["T"], d["UVc"]
    me = bpy.data.meshes.new(name); me.from_pydata(V.tolist(), [], T.tolist()); me.update()
    uv = me.uv_layers.new(name="UVMap")
    uv.data.foreach_set("uv", UVc.reshape(-1, 2).ravel().astype(np.float32))
    for p in me.polygons: p.use_smooth = True
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    return ob
