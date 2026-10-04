#!/usr/bin/env python3
"""Cigarra 3D model: low-poly skinned mesh + palette-atlas / wing WebP textures, rig bone-compatible with the
tools/animation stand-in (so tools/animation/characters/cigarra.py clips bake straight onto it).

  python3 tools/modeling/cigarra/build.py   -> game/art/models/cigarra/{cigarra.glb, cigarra_anim.json, cigarra_model.tscn}
Reference: design/model_sheets/cigarra (turnaround.png, spec.md, palette.json). Budget: <= 6k tris, 2 textures.
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "animation"))
sys.path.insert(0, os.path.join(ROOT, "tools", "modeling"))
import bpy  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402
import standin  # noqa: E402

OUT = os.path.join(ROOT, "game", "art", "models", "cigarra")
WORK = os.path.join(HERE, "work")
os.makedirs(OUT, exist_ok=True)
os.makedirs(WORK, exist_ok=True)

COL = {  # name -> rgb (sampled by eye from design/model_sheets/cigarra/palette.png)
    "skin": (0.72, 0.54, 0.38), "hair": (0.86, 0.82, 0.70), "violet": (0.24, 0.18, 0.30), "violet_d": (0.12, 0.09, 0.15),
    "moss": (0.50, 0.55, 0.16), "crop": (0.72, 0.70, 0.48), "trim": (0.11, 0.09, 0.09), "leather": (0.32, 0.19, 0.10),
    "gold": (0.85, 0.66, 0.18), "cream": (0.82, 0.76, 0.60), "orange": (0.78, 0.36, 0.12), "black": (0.035, 0.035, 0.045),
    "boot": (0.17, 0.11, 0.08), "eye": (0.97, 0.80, 0.12), "gourd": (0.80, 0.74, 0.55), "mark": (0.08, 0.06, 0.06),
}
CELLS = list(COL)
GRID = 4  # 4x4 cells of 64 px = 256 px atlas


def cell_uv(name):
    i = CELLS.index(name)
    return ((i % GRID + 0.5) / GRID, 1 - ((i // GRID) + 0.5) / GRID)


class B:
    def __init__(self):
        self.v, self.f, self.cand, self.uv, self.mat = [], [], [], [], []

    def vert(self, p, cand):
        self.v.append(tuple(p))
        self.cand.append(cand)
        return len(self.v) - 1

    def tube(self, path, rx, ry, col, cand, n=8, cap0=True, cap1=True, flare=None):
        path = [np.array(p, float) for p in path]
        k = len(path)
        rx = rx if isinstance(rx, (list, tuple)) else [rx] * k
        ry = ry if isinstance(ry, (list, tuple)) else [ry] * k
        rings = []
        for i, p in enumerate(path):
            t = path[min(i + 1, k - 1)] - path[max(i - 1, 0)]
            t = t / (np.linalg.norm(t) + 1e-9)
            h = np.array([0, -1.0, 0]) if abs(t[1]) < 0.9 else np.array([1.0, 0, 0])
            u = np.cross(t, h)
            u /= np.linalg.norm(u)
            w = np.cross(t, u)
            ring = []
            for s in range(n):
                a = 2 * math.pi * s / n
                ring.append(self.vert(p + u * math.cos(a) * rx[i] + w * math.sin(a) * ry[i], cand))
            rings.append(ring)
        uv = cell_uv(col)
        for i in range(k - 1):
            for s in range(n):
                self.quad((rings[i][s], rings[i][(s + 1) % n], rings[i + 1][(s + 1) % n], rings[i + 1][s]), uv, 0)
        for flag, ring, p in ((cap0, rings[0], path[0]), (cap1, rings[-1], path[-1])):
            if flag:
                c = self.vert(p, cand)
                for s in range(n):
                    self.f.append((ring[s], ring[(s + 1) % n], c))
                    self.uv.append([uv] * 3)
                    self.mat.append(0)
        return rings

    def quad(self, idx, uv, mat):
        self.f.append(tuple(idx))
        self.uv.append(uv if isinstance(uv, list) else [uv] * len(idx))
        self.mat.append(mat)

    def ellipsoid(self, c, r, col, cand, n=8, rings=5):
        c = np.array(c, float)
        r = np.array(r, float)
        path = [c + np.array([0, 0, r[2] * math.cos(math.pi * i / rings)]) for i in range(rings + 1)]
        rad = [max(math.sin(math.pi * i / rings), 0.02) for i in range(rings + 1)]
        self.tube(path, [r[0] * x for x in rad], [r[1] * x for x in rad], col, cand, n=n, cap0=False, cap1=False)

    def cone(self, a, b, r, col, cand, n=5):
        self.tube([a, b], [r, 0.0005], [r, 0.0005], col, cand, n=n, cap0=True, cap1=False)


def build_geometry(J):
    b = B()
    V = lambda k: np.array(J[k], float)  # noqa: E731
    hd, he = V("head"), V("head_end")
    # ---- torso: crop top + midriff + belt + hooded jacket shoulders
    b.tube([V("hips") + [0, 0, 0.02], [0, 0, 1.00], [0, 0, 1.10]], [0.155, 0.135, 0.13], [0.105, 0.09, 0.09], "skin",
           ["hips", "spine1", "spine2"], n=10, cap0=False, cap1=False)
    b.tube([[0, 0, 1.11], [0, 0.005, 1.20], [0, 0, 1.30], [0, -0.005, 1.35]], [0.14, 0.15, 0.17, 0.09],
           [0.095, 0.105, 0.11, 0.07], "crop", ["spine2", "chest"], n=10, cap0=False, cap1=True)
    b.tube([[0, 0, 1.095], [0, 0, 1.125]], [0.142, 0.142], [0.097, 0.097], "trim", ["spine2"], n=10, cap0=False, cap1=False)
    # belt + buckle + charms (hips bone)
    b.tube([[0, 0, 0.905], [0, 0, 0.965]], [0.17, 0.17], [0.125, 0.125], "leather", ["hips"], n=10, cap0=False, cap1=False)
    b.ellipsoid([0, -0.125, 0.935], [0.035, 0.012, 0.03], "gold", ["hips"], n=6, rings=3)
    for sx, (x, z, col, rr) in zip((1, 1, -1), ((0.10, 0.78, "gourd", 0.04), (0.17, 0.80, "orange", 0.035),
                                                 (-0.12, 0.80, "gourd", 0.03))):
        b.ellipsoid([x, -0.11, z], [rr, rr * 0.8, rr * 1.2], col, ["hips", "thigh.L" if x > 0 else "thigh.R"], n=6, rings=4)
    b.tube([[0.07, -0.12, 0.9], [0.075, -0.125, 0.62]], [0.012, 0.01], [0.006, 0.005], "orange", ["hips", "thigh.L"], n=4)
    # jacket: shoulders mantle + collar + hood behind the head
    b.tube([[0, 0.02, 1.31], [0, 0.03, 1.22], [0, 0.07, 1.06]], [0.21, 0.20, 0.17], [0.12, 0.13, 0.12], "violet",
           ["chest", "spine2"], n=10, cap0=False, cap1=False)
    b.tube([[0, 0.0, 1.31], [0, 0.0, 1.38]], [0.15, 0.12], [0.12, 0.10], "violet_d", ["chest", "neck1"], n=10, cap0=False, cap1=False)
    b.tube([[0, 0.0, 1.375], [0, 0.0, 1.395]], [0.125, 0.125], [0.105, 0.105], "moss", ["neck1"], n=10, cap0=False, cap1=False)
    b.ellipsoid([0, 0.125, 1.40], [0.12, 0.07, 0.10], "violet_d", ["neck1", "head"], n=10, rings=5)   # hood
    b.ellipsoid([0, 0.17, 1.30], [0.045, 0.012, 0.06], "gold", ["chest"], n=6, rings=3)               # sigil tab
    # ---- neck + head
    b.tube([V("neck1") + [0, 0, -0.02], hd], 0.045, 0.045, "skin", ["neck1", "head"], n=8, cap0=False, cap1=False)
    b.ellipsoid(hd + [0, -0.01, 0.075], [0.085, 0.09, 0.105], "skin", ["head"], n=10, rings=6)
    b.ellipsoid(hd + [0, 0.012, 0.115], [0.105, 0.105, 0.085], "hair", ["head"], n=10, rings=5)         # hair mass
    b.ellipsoid(hd + [0, -0.075, 0.13], [0.09, 0.03, 0.04], "hair", ["head"], n=8, rings=3)             # fringe
    rng = np.random.default_rng(4)
    for i in range(14):                                                                                   # shaggy tufts
        a = rng.uniform(0, 2 * math.pi)
        p = hd + [math.cos(a) * 0.09, math.sin(a) * 0.09 + 0.01, 0.12 + rng.uniform(-0.04, 0.06)]
        d = np.array([math.cos(a) * 0.05, math.sin(a) * 0.05 - 0.01, rng.uniform(-0.07, 0.01)])
        b.cone(p, p + d * 1.4, 0.026, "hair", ["head"])
    for sx in (1, -1):
        e = hd + [sx * 0.04, -0.082, 0.075]
        b.ellipsoid(e, [0.022, 0.008, 0.012], "eye", ["head"], n=6, rings=3)
        b.ellipsoid(e + [0, -0.006, 0.014], [0.026, 0.006, 0.006], "mark", ["head"], n=6, rings=2)
        b.cone(hd + [sx * 0.085, 0.0, 0.085], hd + [sx * 0.17, 0.01, 0.12], 0.02, "skin", ["head"])      # pointed ears
    b.ellipsoid(hd + [0, -0.09, 0.115], [0.012, 0.006, 0.012], "mark", ["head"], n=6, rings=3)           # third eye
    # ---- crown (treehopper horn): branching stalks + glossy black spheres
    cr = ["crown"]
    base = he + [0, 0.045, 0.01]
    for stalk, (dx, dy, dz, rr) in enumerate([(0.02, 0.02, 0.13, 0.05), (0.15, 0.04, 0.08, 0.046), (-0.15, 0.04, 0.07, 0.046),
                                              (0.07, 0.15, 0.10, 0.04), (-0.09, 0.15, 0.06, 0.038),
                                              (0.22, -0.01, -0.01, 0.036), (-0.22, 0.0, 0.0, 0.036)]):
        tip = base + [dx, dy, dz]
        mid = base + [dx * 0.4, dy * 0.4 + 0.015, dz * 0.55]
        b.tube([base, mid, tip], [0.011, 0.008, 0.006], [0.011, 0.008, 0.006], "black", cr, n=5, cap0=False, cap1=False)
        b.ellipsoid(tip + [0, 0, rr * 0.7], [rr, rr, rr], "black", cr, n=8, rings=5)
        b.ellipsoid(tip + [rr * 0.35, -rr * 0.7, rr * 1.2], [rr * 0.3, rr * 0.15, rr * 0.3], "gold", cr, n=4, rings=2)
    # ---- limbs (build the left, mirror by sx)
    for sx, s in ((1, ".L"), (-1, ".R")):
        P = lambda k: V(k + s)  # noqa: E731
        sh, el, wr, he_ = P("shoulder"), P("elbow"), P("wrist"), P("hand_end")
        ua, fa, hn = ["upperarm" + s, "clavicle" + s], ["forearm" + s, "upperarm" + s], ["hand" + s, "forearm" + s]
        b.tube([sh + [0, 0, 0.02], (sh + el) / 2 + [sx * 0.012, 0.01, 0], el + [0, 0, 0.0]], [0.062, 0.068, 0.07],
               [0.058, 0.064, 0.066], "violet", ua, n=8, cap0=True, cap1=False)                       # puffy rolled sleeve
        b.tube([el, (el + wr) / 2 + [0, 0, 0.0], wr + [0, 0, 0.1 - 0.1]], [0.05, 0.043, 0.036], [0.05, 0.043, 0.036],
               "cream", fa, n=8, cap0=False, cap1=False)                                               # bandaged forearm
        b.tube([wr, he_], [0.032, 0.012], [0.02, 0.01], "skin", hn, n=6, cap0=True, cap1=True)         # hand
        # ---- legs: baggy harem pants, bandage shins, leaf-trim boots
        hp, kn, an, bl, te = P("hip"), P("knee"), P("ankle"), P("ball"), P("toe_end")
        th, sn, ft = ["thigh" + s, "hips"], ["shin" + s, "thigh" + s], ["foot" + s, "shin" + s]
        b.tube([hp + [0, 0, 0.03], (hp + kn) / 2 + [sx * 0.01, -0.01, 0], kn + [0, 0, 0.0]], [0.125, 0.125, 0.115],
               [0.12, 0.125, 0.115], "violet_d", th, n=9, cap0=True, cap1=False)
        b.tube([kn, kn * 0.55 + an * 0.45 + [0, -0.01, 0.04], an + [0, -0.01, 0.2]], [0.115, 0.115, 0.08], [0.115, 0.115, 0.08],
               "violet_d", sn, n=9, cap0=False, cap1=True)
        b.tube([an + [0, -0.005, 0.2], an + [0, 0, 0.1]], [0.042, 0.04], [0.042, 0.04], "cream", sn, n=7, cap0=False, cap1=False)
        b.tube([an + [0, 0.02, 0.1], an + [0, 0.0, 0.02], bl + [0, 0, 0.03], te + [0, 0, 0.025]], [0.055, 0.06, 0.056, 0.04],
               [0.05, 0.06, 0.05, 0.03], "boot", ft, n=7, cap0=True, cap1=True)
        b.cone(an + [sx * 0.05, 0.0, 0.06], an + [sx * 0.15, -0.04, 0.1], 0.03, "moss", ft)           # leaf trim
    return b


def wing_mesh(b, J):
    """Translucent wing-cloak panels, material 1. Returns nothing; faces appended with uv into wing texture."""
    for sx, s in ((1, ".L"), (-1, ".R")):
        root = np.array(J["wing_root" + s], float)
        for panel, (length, width, dy, tilt, uoff) in enumerate([(0.74, 0.30, 0.0, 0.18, 0.0), (0.52, 0.22, 0.045, -0.05, 0.5)]):
            NU, NV = 3, 5
            ids = []
            for iv in range(NV + 1):
                v = iv / NV
                row = []
                for iu in range(NU + 1):
                    u = iu / NU
                    x = root[0] + sx * (width * u * (0.55 + 0.45 * v) + tilt * v * 0.3 + 0.01)
                    y = root[1] + dy + 0.03 * v + 0.05 * math.sin(u * math.pi) * v
                    z = root[2] - length * v + 0.02 * u
                    cand = [("wing" + s)] + (["chest"] if v < 0.2 else [])
                    row.append(b.vert((x, y, z), cand))
                ids.append(row)
            for iv in range(NV):
                for iu in range(NU):
                    u0, u1 = iu / NU, (iu + 1) / NU
                    v0, v1 = iv / NV, (iv + 1) / NV
                    a, bb, c, d = ids[iv][iu], ids[iv][iu + 1], ids[iv + 1][iu + 1], ids[iv + 1][iu]
                    # panel textures side by side: left half = panel 0, right half = panel 1; mirror u for the R wing
                    uu0, uu1 = (u0, u1) if sx > 0 else (1 - u0, 1 - u1)
                    T = lambda uu, vv: (uoff + uu * 0.5, 1 - vv)  # noqa: E731
                    quad = (a, bb, c, d)
                    b.quad(quad, [T(uu0, v0), T(uu1, v0), T(uu1, v1), T(uu0, v1)], 1)


def make_textures():
    img = Image.new("RGB", (GRID * 64, GRID * 64), (40, 40, 40))
    rng = np.random.default_rng(2)
    for i, nm in enumerate(CELLS):
        c = np.array(COL[nm]) * 255
        x0, y0 = (i % GRID) * 64, (i // GRID) * 64
        a = np.clip(c[None, None, :] + rng.normal(0, 5, (64, 64, 1)), 0, 255).astype(np.uint8)
        img.paste(Image.fromarray(a), (x0, y0))
    img.save(os.path.join(WORK, "cigarra_albedo.webp"), quality=90)
    # wing: two 128x512 panels, lime membrane + dark violet cells, veins, black spots (sheet back view)
    W, H = 256, 512
    w = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(w)
    for px in (0, 128):
        d.rectangle([px, 0, px + 127, H], fill=(150, 168, 45, 150))
        for k in range(5):
            x = px + 20 + k * 20
            d.polygon([(x, 20 + k * 10), (x + 24, 110 + k * 40), (x + 8, 330 + k * 20), (x - 12, 120 + k * 40)],
                      fill=(54, 38, 74, 215))
        d.line([(px + 4, 0), (px + 120, H)], fill=(40, 52, 20, 255), width=3)
        for k in range(8):
            d.line([(px + 64, k * 64), (px + (10 if k % 2 else 118), 60 + k * 64)], fill=(70, 85, 25, 230), width=2)
        for (cx, cy) in ((px + 90, 160), (px + 40, 300), (px + 80, 420)):
            d.ellipse([cx - 14, cy - 20, cx + 14, cy + 20], fill=(18, 14, 24, 230))
        d.rectangle([px, 0, px + 127, 6], fill=(30, 30, 40, 255))
    w.save(os.path.join(WORK, "cigarra_wing.webp"), quality=88)
    return os.path.join(WORK, "cigarra_albedo.webp"), os.path.join(WORK, "cigarra_wing.webp")


def material(name, path, alpha=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = 0.75 if not alpha else 0.4
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = bpy.data.images.load(path)
    t.image.alpha_mode = "STRAIGHT"
    nt.links.new(t.outputs["Color"], bs.inputs["Base Color"])
    if alpha:
        nt.links.new(t.outputs["Alpha"], bs.inputs["Alpha"])
        m.surface_render_method = "BLENDED"
        m.use_backface_culling = False
    return m


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cfg = standin.STANDINS["cigarra"]
    J, Bn, S = standin.mirror(cfg)
    rig = standin.build_armature("Cigarra", J, Bn)
    b = build_geometry(J)
    wing_mesh(b, J)
    me = bpy.data.meshes.new("Cigarra")
    me.from_pydata(b.v, [], b.f)
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    uv.data.foreach_set("uv", np.array([u for f in b.uv for u in f], dtype=np.float32).ravel())
    me.polygons.foreach_set("material_index", np.array(b.mat, dtype=np.int32))
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Cigarra", me)
    bpy.context.scene.collection.objects.link(ob)
    alb, wing = make_textures()
    ob.data.materials.append(material("cigarra_body", alb))
    ob.data.materials.append(material("cigarra_wings", wing, alpha=True))
    # skin: inverse-distance weights over the part's candidate bones
    bones = {bn.name: (np.array(bn.head_local), np.array(bn.tail_local)) for bn in rig.data.bones}

    def sd(p, a, c):
        ab = c - a
        t = np.clip(np.dot(p - a, ab) / (np.dot(ab, ab) + 1e-9), 0, 1)
        return np.linalg.norm(p - (a + ab * t))

    groups = {n: ob.vertex_groups.new(name=n) for n in bones if n != "root"}
    for i, (p, cand) in enumerate(zip(b.v, b.cand)):
        p = np.array(p)
        if len(cand) == 1:
            groups[cand[0]].add([i], 1.0, "REPLACE")
            continue
        d = np.array([sd(p, *bones[c]) for c in cand])
        w = 1.0 / (d + 0.03) ** 3
        w /= w.sum()
        for c, wi in zip(cand, w):
            if wi > 0.03:
                groups[c].add([i], float(wi), "REPLACE")
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    ob.select_set(False)
    from apply import apply_animations
    meta = apply_animations(rig, "cigarra")
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    glb = os.path.join(OUT, "cigarra.glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True, export_image_format="WEBP")
    json.dump({"height_m": 1.65, "tris": tris, "fps": 30, "animations": meta}, open(os.path.join(OUT, "cigarra_anim.json"), "w"), indent=1)
    open(os.path.join(OUT, "cigarra_model.tscn"), "w").write(
        '[gd_scene load_steps=3 format=3]\n\n'
        '[ext_resource type="Script" path="res://game/art/models/character_model.gd" id="1"]\n'
        '[ext_resource type="PackedScene" path="res://game/art/models/cigarra/cigarra.glb" id="2"]\n\n'
        '[node name="CigarraModel" type="Node3D"]\nscript = ExtResource("1")\nmodel_scene = ExtResource("2")\n'
        'anim_json = "res://game/art/models/cigarra/cigarra_anim.json"\nheight_m = 1.65\ncharacter_id = "cigarra"\n'
        + cfg.get("tscn_extra", ""))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "cigarra_final.blend"))
    print("TRIS", tris, glb)


if __name__ == "__main__":
    main()
