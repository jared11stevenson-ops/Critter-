#!/usr/bin/env python3
"""Aruun v3: xatlas per group, composed into one 2048 atlas (head gets the densest texels):
   body (trunk/arms/legs) 1152 @(0,0) | head 896 @(1152,0) | horns 768 @(1152,896) | gear (morrow+cards) 896 @(0,1152)"""
import os, sys
import numpy as np
import xatlas
HERE = os.path.dirname(os.path.abspath(__file__)); W3 = os.path.join(HERE, "..", "work", "v3")
d = np.load(os.path.join(W3, "raw_mesh.npz"), allow_pickle=True)
V, T, fk, sp = d["V"].astype(np.float32), d["T"].astype(np.int64), d["facekinds"], d["sparam"]
kind = np.array([str(k).split("|")[1] for k in fk])
GROUPS = {"body": (("trunk", "armL", "armR", "legL", "legR"), 1152, (0, 0)),
          "head": (("skull", "jaw", "eye", "tooth_up", "tooth_lo", "tongue", "tine", "fringe_head"), 896, (1152, 0)),
          "horn": (("horn",), 768, (1152, 896)),
          "gear": (("morrow", "card"), 896, (0, 1152))}
S = 2048.0
outV, outT, outUV, outK, outSP, outG = [], [], [], [], [], []; off = 0
for g, (kinds, res, (ox, oy)) in GROUPS.items():
    ti = np.where(np.isin(kind, kinds))[0]
    at = xatlas.Atlas(); at.add_mesh(V, T[ti].astype(np.uint32))
    co = xatlas.ChartOptions(); co.max_iterations = 4; co.normal_deviation_weight = 2.0; co.max_cost = 8.0; co.roundness_weight = 0.2
    po = xatlas.PackOptions(); po.resolution = res; po.padding = 5; po.texels_per_unit = 0.0; po.create_image = False
    at.generate(co, po)
    vmap, idx, uv = at[0]; idx = idx.reshape(-1, 3)
    print(g, "atlas", at.width, at.height, "charts", at.chart_count, "verts", len(vmap), "tris", len(idx))
    px = uv if uv.max() > 1.5 else uv * np.array([at.width, at.height])      # pixels in atlas space
    px = px / float(max(at.width, at.height)) * res * (1.0 if max(at.width, at.height) > 0 else 1)
    uvf = (np.array([ox, oy]) + px) / S; uvf[:, 1] = 1.0 - uvf[:, 1]          # image row 0 = top = v 1
    print('  uv range', px.min(0), px.max(0))
    # map tri order back: xatlas keeps input triangle order
    outV.append(V[vmap]); outT.append(idx + off); outUV.append(uvf.astype(np.float32)); off += len(vmap)
    outK.append(fk[ti]); outSP.append(sp[vmap]); outG += [g] * len(idx)
Vn = np.vstack(outV); Tn = np.vstack(outT); UV = np.vstack(outUV)
np.savez(os.path.join(W3, "game_mesh.npz"), V=Vn, T=Tn.astype(np.int32), UV=UV, facekinds=np.concatenate(outK), sparam=np.concatenate(outSP),
         UVc=UV[Tn].astype(np.float32), group=np.array(outG))
print("total verts", len(Vn), "tris", len(Tn))
