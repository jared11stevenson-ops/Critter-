#!/usr/bin/env python3
"""Cigarra v2: xatlas per group composed into the 2048 body atlas (head densest) + explicit wing UVs (separate 512x1024 material).
   body(shell+hands) 1152 @(0,0) | head 768 @(1152,0) (+128px strip for 2 eyes) | gear(hair, crown, cloth, charms) 896 @(0,1152)"""
import os, sys
import numpy as np
import xatlas
HERE = os.path.dirname(os.path.abspath(__file__)); W2 = os.path.join(HERE, "..", "work", "v2")
d = np.load(os.path.join(W2, "raw_mesh.npz"), allow_pickle=True)
V, T, fk, sp, uv2 = d["V"].astype(np.float32), d["T"].astype(np.int64), d["facekinds"], d["sparam"], d["uv2"]
kind = np.array([str(k).split("|")[1] for k in fk])
GROUPS = {"body": (("body", "hand"), 1152, (0, 0)), "head": (("skull",), 768, (1152, 0)), "gear": (("card",), 896, (0, 1152))}
S = 2048.0
outV, outT, outUV, outK, outSP, outG, outW = [], [], [], [], [], [], []; off = 0
for g, (kinds, res, (ox, oy)) in GROUPS.items():
    ti = np.where(np.isin(kind, kinds))[0]
    at = xatlas.Atlas(); at.add_mesh(V, T[ti].astype(np.uint32))
    co = xatlas.ChartOptions(); co.max_iterations = 4; co.normal_deviation_weight = 2.0; co.max_cost = 8.0; co.roundness_weight = 0.2
    po = xatlas.PackOptions(); po.resolution = res; po.padding = 5; po.texels_per_unit = 0.0; po.create_image = False
    at.generate(co, po)
    vmap, idx, uv = at[0]; idx = idx.reshape(-1, 3)
    px = uv if uv.max() > 1.5 else uv * np.array([at.width, at.height])
    px = px / float(max(at.width, at.height)) * res
    uvf = (np.array([ox, oy]) + px) / S; uvf[:, 1] = 1.0 - uvf[:, 1]
    print(g, "atlas", at.width, at.height, "charts", at.chart_count, "tris", len(idx))
    outV.append(V[vmap]); outT.append(idx + off); outUV.append(uvf.astype(np.float32)); off += len(vmap)
    outK.append(fk[ti]); outSP.append(sp[vmap]); outG += [g] * len(idx); outW.append(np.zeros((len(vmap), 2), np.float32))
# eyes: planar disc UVs in reserved squares
H = np.load(os.path.join(W2, "head_raw.npz")); O, sc = H["origin"], float(H["scale"])
ti = np.where(kind == "eye")[0]
for sg, (ox, oy) in ((1, (1152 + 768, 0)), (-1, (1152 + 768, 128))):
    tsel = [t for t in ti if (V[T[t]].mean(0)[0] - O[0]) * sg > 0]
    verts = np.unique(T[tsel]); remap = {v: i for i, v in enumerate(verts)}
    c = O + sc * np.array([sg * 0.036, -0.062, 0.008]); gz = np.array([sg * 0.12, -1.0, 0.0]); gz /= np.linalg.norm(gz)
    tx = np.cross(gz, [0, 0, 1.0]); tx /= np.linalg.norm(tx); ty = np.cross(tx, gz)
    dd = V[verts] - c; R = np.linalg.norm(dd, axis=1).max()
    u = dd @ tx / R; v = dd @ ty / R; front = (dd @ gz) > 0
    r2 = np.hypot(u, v); k = np.where((~front) & (r2 < 0.985), 0.985 / np.maximum(r2, 1e-6), 1.0); u, v = u * k, v * k
    px = np.stack([(u * 0.5 + 0.5) * 120 + 4 + ox, (1 - (v * 0.5 + 0.5)) * 120 + 4 + oy], 1)
    uvf = px / S; uvf[:, 1] = 1.0 - uvf[:, 1]
    tt = np.array([[remap[a] for a in T[t]] for t in tsel], np.int64)
    outV.append(V[verts]); outT.append(tt + off); outUV.append(uvf.astype(np.float32)); off += len(verts)
    outK.append(fk[tsel]); outSP.append(sp[verts]); outG += ["eye"] * len(tsel); outW.append(np.zeros((len(verts), 2), np.float32))
# wings: explicit uv2 (texture 2 tiles) kept as is, separate material
ti = np.where(kind == "wing")[0]
verts = np.unique(T[ti]); remap = -np.ones(len(V), int); remap[verts] = np.arange(len(verts))
outV.append(V[verts]); outT.append(remap[T[ti]] + off); outUV.append(uv2[verts].astype(np.float32)); off += len(verts)
outK.append(fk[ti]); outSP.append(sp[verts]); outG += ["wing"] * len(ti)
Vn = np.vstack(outV); Tn = np.vstack(outT); UV = np.vstack(outUV)
np.savez(os.path.join(W2, "game_mesh.npz"), V=Vn, T=Tn.astype(np.int32), UV=UV, facekinds=np.concatenate(outK), sparam=np.concatenate(outSP),
         UVc=UV[Tn].astype(np.float32), group=np.array(outG))
print("total verts", len(Vn), "tris", len(Tn))
