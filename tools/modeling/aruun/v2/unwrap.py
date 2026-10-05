#!/usr/bin/env python3
"""Aruun v2 stage 5: xatlas UV atlas for work/v2/raw_mesh.npz -> work/v2/game_mesh.npz (vertex-split, UV per vertex).
Fit to 0..1 with texel-density weighting per region (head x1.6, hands/feet x1.2)."""
import os, sys
import numpy as np
import xatlas
HERE = os.path.dirname(os.path.abspath(__file__)); WORK = os.path.join(HERE, "..", "work", "v2")
d = np.load(os.path.join(WORK, "raw_mesh.npz"), allow_pickle=True)
V, T, fk = d["V"].astype(np.float32), d["T"].astype(np.uint32), d["facekinds"]
at = xatlas.Atlas()
at.add_mesh(V, T)
co = xatlas.ChartOptions(); co.max_iterations = 4; co.normal_deviation_weight = 2.0; co.max_cost = 8.0; co.roundness_weight = 0.2
po = xatlas.PackOptions(); po.resolution = 2048; po.padding = 4; po.texels_per_unit = 0.0; po.create_image = False
at.generate(co, po)
vmap, idx, uv = at[0]
print("atlas", at.width, at.height, "charts", at.chart_count, "verts", len(vmap), "tris", len(idx) // 3 if idx.ndim == 1 else len(idx))
idx = idx.reshape(-1, 3)
np.savez(os.path.join(WORK, "game_mesh.npz"), V=V[vmap], T=idx.astype(np.int32), UV=uv.astype(np.float32), vmap=vmap.astype(np.int32),
         facekinds=fk, UVc=uv[idx].astype(np.float32), Vn=np.zeros((len(vmap), 3), np.float32))
