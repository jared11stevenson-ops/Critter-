"""bpy: load legacy final blend, move vertices to the fitted positions (work/v2/fit.npz), dump arrays for projection."""
import os, sys
import numpy as np
import bpy
HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(HERE, "..", "work", "v2")
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "..", "work", "aruun_final.blend"))
ob = bpy.data.objects["Aruun"]; me = ob.data
V = np.load(os.path.join(WORK, "fit.npz"))["V"]
me.vertices.foreach_set("co", V.astype(np.float32).ravel()); me.update()
me.calc_loop_triangles()
n = len(me.vertices)
tri = np.array([t.vertices[:] for t in me.loop_triangles], np.int32)
loops = np.array([t.loops[:] for t in me.loop_triangles], np.int32)
uv = np.zeros(len(me.loops) * 2, np.float32); me.uv_layers["UVMap"].data.foreach_get("uv", uv); uv = uv.reshape(-1, 2)
vn = np.zeros(n * 3, np.float32); me.vertices.foreach_get("normal", vn); vn = vn.reshape(-1, 3)
tp = np.array([t.polygon_index for t in me.loop_triangles], np.int32)
pa = np.zeros(len(me.polygons), np.int32); me.attributes["part"].data.foreach_get("value", pa)
np.savez(os.path.join(WORK, "mesh_fit.npz"), V=V, Vn=vn, T=tri, UVc=uv[loops], part_of_tri=pa[tp], parts=np.array(list(ob["parts"])))
print("ok", n, len(tri))
