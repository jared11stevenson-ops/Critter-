#!/usr/bin/env python3
"""Aruun stage 2: UVs, painted textures (albedo / normal / ORM), rig, weights, animations, glTF export.

  python3 tools/modeling/aruun/build.py geo     # stage 1 -> work/aruun_geo.blend
  python3 tools/modeling/aruun/finish.py        # stage 2 -> game/art/models/aruun/{aruun.glb, textures, aruun_anim.json}

Deterministic: all noise is seeded, all poses are data (anims.py).
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402
from PIL import Image  # noqa: E402
from common import bpy_util as bu  # noqa: E402
from common.raster import uv_raster, dilate  # noqa: E402
import body  # noqa: E402
import anims  # noqa: E402
from preview import PART_COL, hex2  # noqa: E402

OUT = os.path.join(ROOT, "game", "art", "models", "aruun")
WORK = os.path.join(HERE, "work")
TEX = 2048

# ----------------------------------------------------------------------------------------- materials
CARAPACE = {"head", "brow", "crest", "horn", "pauldron", "armplate", "bracer", "neck"}
DARK_CHITIN = {"torso", "upperarm", "forearm", "hand", "thigh", "shin"}
BONE = {"tine", "claw", "toeclaw", "kneeplate", "fang", "foot", "buckle", "medallion"}
ROUGH = {"gold": 0.35, "eye": 0.2, "morrow_core": 0.15, "fang": 0.4}
METAL = {"gold": 0.85}


def noise3(P, freq, seed):
    """Cheap deterministic smooth 3D noise in [-1,1] (sum of random-direction sines)."""
    rng = np.random.default_rng(seed)
    acc = np.zeros(len(P))
    amp = 1.0
    tot = 0.0
    for octave in range(4):
        for _ in range(3):
            d = rng.normal(size=3)
            d /= np.linalg.norm(d)
            acc += amp * np.sin(P @ d * freq * (2 ** octave) * 6.283 + rng.uniform(0, 6.283))
            tot += amp
        amp *= 0.55
    return acc / tot * 1.6


def paint(ob):
    """Bake albedo / height via UV rasterisation; colour by part + mottling matched to the sheet palette."""
    me = ob.data
    names = ob["parts"]
    n_loops = len(me.loops)
    uv = np.zeros(n_loops * 2, dtype=np.float32)
    me.uv_layers["UVMap"].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    lv = np.zeros(n_loops, dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    co = np.zeros(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    me.calc_loop_triangles()
    nt = len(me.loop_triangles)
    tl = np.zeros(nt * 3, dtype=np.int32)
    me.loop_triangles.foreach_get("loops", tl)
    tl = tl.reshape(-1, 3)
    tp = np.zeros(nt, dtype=np.int32)
    me.loop_triangles.foreach_get("polygon_index", tp)
    pa = np.zeros(len(me.polygons), dtype=np.int32)
    me.attributes["part"].data.foreach_get("value", pa)
    tid, bary = uv_raster(uv, tl, TEX)
    mask = tid >= 0
    t = tid[mask]
    b = bary[mask]
    P = (co[lv[tl[t, 0]]] * b[:, :1] + co[lv[tl[t, 1]]] * b[:, 1:2] + co[lv[tl[t, 2]]] * b[:, 2:3]).astype(np.float64)
    part = np.array([names[i].split(".")[0] for i in range(len(names))])[pa[tp[t]]]
    base = np.array([hex2(PART_COL.get(p, "#808080")) for p in part])
    col = base.copy()
    h = np.zeros(len(P))
    n1 = noise3(P, 2.2, 11)
    n2 = noise3(P, 4.0, 23)
    n3 = noise3(P, 9.0, 37)
    is_car = np.isin(part, list(CARAPACE))
    is_dark = np.isin(part, list(DARK_CHITIN))
    is_bone = np.isin(part, list(BONE))
    # sheet: red carapace with cream/ochre blotches and black specks; dark chitin with cream+red plates
    cream = np.array(hex2("#c69b70"))
    ochre = np.array(hex2("#d8a15c"))
    deep = np.array(hex2("#6d2a1b"))
    black = np.array(hex2("#2a2224"))
    red = np.array(hex2("#953d32"))
    m = is_car & (n1 > 0.3)
    col[m] = cream
    m2 = is_car & (n2 > 0.5)
    col[m2] = ochre
    col[is_car & (n3 > 0.7)] = black
    col[is_car & (n1 < -0.7)] = deep
    h[is_car] = np.clip(n1[is_car], -1, 1) * 0.5 + 0.3
    # dark chitin: cream plates and red bands
    col[is_dark & (n1 > 0.4)] = cream
    col[is_dark & (n2 < -0.55)] = red
    col[is_dark & (n3 > 1.05)] = ochre * 0.9
    h[is_dark] = (n1[is_dark] > 0.65) * 0.6 + n3[is_dark] * 0.1
    # bone: subtle grain
    col[is_bone] *= (0.92 + 0.08 * n3[is_bone])[:, None]
    h[is_bone] = n3[is_bone] * 0.2
    # cloth: weave / grime
    cloth = np.array([x.startswith(("cloak", "leaf", "strip", "band", "cloth", "belt", "fringe")) for x in part])
    col[cloth] *= (0.85 + 0.15 * n2[cloth] + 0.04 * np.sin(P[cloth, 2] * 900))[:, None]
    h[cloth] = 0.08 * np.sin(P[cloth, 2] * 900) + 0.1 * n2[cloth]
    # morrow head: black ball with cream specks
    mh = part == "morrow_head"
    col[mh & (n3 > 1.0)] = cream * 0.8
    # tiny star specks over the whole dark body (sheet "starry" dots)
    col[is_dark & (n3 > 1.2) & (n2 > 0.3)] = np.array(hex2("#e7d6a8"))
    # cavity darkening from noise → fake AO into albedo slightly
    col *= (0.93 + 0.07 * np.clip(n2, -1, 1))[:, None]
    col = np.clip(col, 0, 1)

    img = np.zeros((TEX, TEX, 3), dtype=np.float32)
    img[mask] = col
    himg = np.zeros((TEX, TEX), dtype=np.float32)
    himg[mask] = h
    rough = np.full(len(P), 0.6)
    metal = np.zeros(len(P))
    for k, v in ROUGH.items():
        rough[part == k] = v
    for k, v in METAL.items():
        metal[part == k] = v
    rough[is_car] = 0.45 - 0.1 * np.clip(n1[is_car], 0, 1)
    rough[cloth] = 0.85
    orm = np.zeros((TEX, TEX, 3), dtype=np.float32)
    orm[mask] = np.stack([np.ones(len(P)), rough, metal], 1)
    img, _ = dilate(img, mask, 6)
    himg, _ = dilate(himg, mask, 6)
    orm, _ = dilate(orm, mask, 6)
    # normal from height (tangent space approx; UV-space gradient)
    gy, gx = np.gradient(himg)
    k = 6.0
    nrm = np.stack([-gx * k, gy * k, np.ones_like(himg)], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    os.makedirs(OUT, exist_ok=True)
    paths = {}
    for nm, arr in (("albedo", img), ("normal", nrm * 0.5 + 0.5), ("orm", orm)):
        p = os.path.join(WORK, "aruun_%s.png" % nm)
        Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(p)
        paths[nm] = p
    return paths


def make_material(paths):
    m = bpy.data.materials.new("aruun")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")

    def tex(p, non_color):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(p)
        if non_color:
            n.image.colorspace_settings.name = "Non-Color"
        return n
    a = tex(paths["albedo"], False)
    nt.links.new(a.outputs["Color"], bsdf.inputs["Base Color"])
    o = tex(paths["orm"], True)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(o.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    n = tex(paths["normal"], True)
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(n.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    # eyes / morrow core glow
    return m


# ----------------------------------------------------------------------------------------- rig
BONES = [
    # name, head joint, tail joint, parent
    ("root", None, None, None),
    ("hips", "hips", "spine1", "root"),
    ("spine1", "spine1", "spine2", "hips"),
    ("spine2", "spine2", "chest", "spine1"),
    ("chest", "chest", "neck1", "spine2"),
    ("neck1", "neck1", "neck2", "chest"),
    ("neck2", "neck2", "neck3", "neck1"),
    ("neck3", "neck3", "head", "neck2"),
    ("head", "head", "head_end", "neck3"),
    ("jaw", "jaw", "jaw_end", "head"),
]
for s in ("L", "R"):
    BONES += [
        ("clavicle." + s, "clavicle." + s, "shoulder." + s, "chest"),
        ("upperarm." + s, "shoulder." + s, "elbow." + s, "clavicle." + s),
        ("forearm." + s, "elbow." + s, "wrist." + s, "upperarm." + s),
        ("hand." + s, "wrist." + s, "hand_end." + s, "forearm." + s),
        ("thigh." + s, "hip." + s, "knee." + s, "hips"),
        ("shin." + s, "knee." + s, "ankle." + s, "thigh." + s),
        ("foot." + s, "ankle." + s, "toe." + s, "shin." + s),
        ("toe." + s, "toe." + s, "toe_end." + s, "foot." + s),
    ]
BONES += [("weapon", "wrist.R", None, "hand.R"), ("cloak", "neck1", None, "chest")]

HEAD_PARTS = {"head", "eye", "brow", "crest", "horn", "tine", "fringe_cream", "fringe_olive"}
JAW_PARTS = {"jaw", "fang"}
TORSO_ONLY = ("cloak", "belt", "buckle", "medallion", "gold", "beads", "talisman", "cloth_sash", "band_cream",
              "strip")
SKIRT = ("leaf",)
MORROW_GRIP = None


def build_armature():
    arm = bpy.data.armatures.new("AruunRig")
    ob = bpy.data.objects.new("Aruun_Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bu.set_active(ob)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones
    for name, h, t, par in BONES:
        b = eb.new(name)
        if name == "root":
            b.head, b.tail = Vector((0, 0, 0)), Vector((0, 0.3, 0))
        elif name == "weapon":
            hp = body.jm("wrist.R") + Vector((-0.02, -0.02, -0.06))
            b.head, b.tail = hp, hp + Vector((0, 0, -0.3))
        elif name == "cloak":
            b.head, b.tail = body.jm("neck1") + Vector((0, 0.12, 0)), body.jm("neck1") + Vector((0, 0.15, -0.5))
        else:
            b.head, b.tail = body.jm(h), body.jm(t)
        if par:
            b.parent = eb[par]
            if name not in ("root", "weapon", "cloak", "thigh.L", "thigh.R", "clavicle.L", "clavicle.R", "jaw") and \
                    (b.head - eb[par].tail).length < 1e-4:
                b.use_connect = True
        # roll so local X points to world +X for everything (consistent signs in anims.py)
        b.align_roll(Vector((0, -1, 0)) if abs(b.vector.normalized().y) < 0.9 else Vector((0, 0, 1)))
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def skin(mesh_ob, rig):
    me = mesh_ob.data
    names = mesh_ob["parts"]
    co = np.zeros(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    pa = np.zeros(len(me.polygons), dtype=np.int32)
    me.attributes["part"].data.foreach_get("value", pa)
    vpart = [None] * len(me.vertices)
    for p in me.polygons:
        for v in p.vertices:
            vpart[v] = names[pa[p.index]]
    bones = {b.name: (np.array(b.head_local), np.array(b.tail_local)) for b in rig.data.bones}
    deform = [n for n in bones if n not in ("root", "cloak")]
    D = np.stack([seg_dist(co, *bones[n]) for n in deform], 1)
    groups = {n: mesh_ob.vertex_groups.new(name=n) for n in bones if n != "root"}
    torso = ["hips", "spine1", "spine2", "chest", "clavicle.L", "clavicle.R"]
    for vi in range(len(co)):
        nm = vpart[vi] or "torso"
        base = nm.split(".")[0]
        side = nm[-2:] if nm[-2:] in (".L", ".R") else None
        if base.startswith("morrow"):
            groups["weapon"].add([vi], 1.0, "REPLACE")
            continue
        if base in HEAD_PARTS:
            groups["head"].add([vi], 1.0, "REPLACE")
            continue
        if base in JAW_PARTS:
            groups["jaw"].add([vi], 1.0, "REPLACE")
            continue
        allowed = []
        for j, n in enumerate(deform):
            if n in ("weapon", "head", "jaw"):
                continue
            if base.startswith(TORSO_ONLY) and n not in torso:
                continue
            if base.startswith(SKIRT) and n not in torso + ["thigh.L", "thigh.R"]:
                continue
            if side and n.endswith(".L" if side == ".R" else ".R"):
                continue
            if base in ("neck",) and not n.startswith(("neck", "chest")):
                continue
            allowed.append(j)
        d = D[vi, allowed]
        order = np.argsort(d)[:3]
        w = 1.0 / (d[order] + 0.02) ** 4
        if base.startswith(SKIRT):
            w = 1.0 / (d[order] + 0.08) ** 2   # soft: skirt follows legs loosely
        w /= w.sum()
        for k, j in enumerate(order):
            if w[k] > 0.02:
                groups[deform[allowed[j]]].add([vi], float(w[k]), "REPLACE")
        # cloak tail also swings a little with the cloak bone
        if base == "cloak_tail" or base == "cloak_back":
            groups["cloak"].add([vi], 0.6, "ADD")
    mod = mesh_ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    mesh_ob.parent = rig
    # normalise
    bu.set_active(mesh_ob)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)


# ----------------------------------------------------------------------------------------- main
def main():
    bpy.ops.wm.open_mainfile(filepath=os.path.join(WORK, "aruun_geo.blend"))
    ob = bpy.data.objects["Aruun"]
    mor = bpy.data.objects["Morrow"]
    wr = body.jm("wrist.R")
    mor.matrix_world = Matrix.Translation(wr + Vector((-0.02, -0.02, -0.06))) @ Matrix.Rotation(0.5, 4, "Y") @ \
        Matrix.Rotation(-0.25, 4, "X")
    bu.set_active(mor)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # merge part tables, then join
    parts = list(ob["parts"])
    mparts = list(mor["parts"])
    pa = np.zeros(len(mor.data.polygons), dtype=np.int32)
    mor.data.attributes["part"].data.foreach_get("value", pa)
    remap = []
    for p in mparts:
        if p not in parts:
            parts.append(p)
        remap.append(parts.index(p))
    mor.data.attributes["part"].data.foreach_set("value", np.array(remap, dtype=np.int32)[pa])
    for o in bpy.data.objects:
        o.select_set(o.name in ("Aruun", "Morrow"))
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.join()
    ob["parts"] = parts
    bu.pack_uvs(ob, density={"head": 1.8, "eye": 1.5, "brow": 1.5, "jaw": 1.4, "horn": 1.2, "morrow_head": 0.8,
                             "cloak": 0.7, "torso": 1.2})
    paths = paint(ob)
    mat = make_material(paths)
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    for p in ob.data.polygons:
        p.material_index = 0
    tris = bu.tri_count(ob)
    rig = build_armature()
    skin(ob, rig)
    impacts = anims.build_all(rig)
    # export
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    glb = os.path.join(OUT, "aruun.glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True, export_image_format="AUTO")
    meta = {"height_m": 2.4, "tris": tris, "texture_px": TEX, "fps": anims.FPS, "animations": impacts}
    with open(os.path.join(OUT, "aruun_anim.json"), "w") as f:
        json.dump(meta, f, indent=1)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, "aruun_final.blend"))
    print("TRIS", tris, "-> ", glb)


if __name__ == "__main__":
    main()
