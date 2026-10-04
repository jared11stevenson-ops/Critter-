#!/usr/bin/env python3
"""Build NPC models.   python3 tools/modeling/npcs/build.py [ids...] [--preview] [--noanim]

Per id: specs/<id>.py -> Builder (one skinned mesh, palette-atlas material) -> rig -> mocap-retargeted clips
(tools/animation/characters/npc.py, or the procedural creature gaits in creature_rig.py) -> glb (WebP textures)
-> game/art/models/<id>/{<id>.glb, <id>_anim.json, <id>_model.tscn}.  --preview renders 4 views to work/<id>_prev.png.
"""
import importlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import numpy as np  # noqa: E402

import bpy  # noqa: E402
import npc_lib as L  # noqa: E402

ROOT = L.ROOT
WORK = os.path.join(HERE, "work")
ALL = ["mara", "dexter", "mollusk", "bramvex", "nerit", "zephyr", "nyxaris", "pharilux", "solmara", "scarlith", "oda_keth", "tavik_roon", "hobb_sarrane", "imre_dahl", "ilsa_brandt", "pel_narr", "vesk_dunmore", "nuru_tamsin", "odalys_penhallow", "bede_alcott", "idris_voll", "dessa_harl", "rival_dominion", "rival_undermarket", "rival_free_scale", "rival_helix"]


def preview(cid, out):
    from common import render as R
    from PIL import Image
    ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
    H = ob.dimensions.z
    R.setup_cycles((420, 620), samples=16)
    R.add_lights()
    ext = max(ob.dimensions.x, ob.dimensions.y, ob.dimensions.z)
    cam = R.camera(ortho_scale=max(H * 1.15, ext * 1.1), target=(0, 0, H / 2))
    tiles = []
    for name, yaw in (("front", 0), ("q34", 40), ("side", -90), ("back", 180)):
        R.place_camera(cam, (0, 0, H * 0.5), yaw, 5, 12)
        p = os.path.join(WORK, "_p_%s.png" % name)
        R.render(p)
        tiles.append(Image.open(p).convert("RGBA"))
    img = Image.new("RGBA", (sum(t.width for t in tiles), tiles[0].height), (226, 220, 210, 255))
    x = 0
    for t in tiles:
        img.alpha_composite(t, (x, 0))
        x += t.width
    img.convert("RGB").save(out)


def build(cid, do_preview=False, do_anim=True):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    spec = importlib.import_module("specs." + cid)
    importlib.reload(spec)
    b = spec.build()
    os.makedirs(WORK, exist_ok=True)
    pa, pe = L.write_atlas(b, WORK)
    rig = L.build_armature(cid, b.J, b.bones)
    ob = L.finish_mesh(b)
    ob.data.materials.append(L.make_material(b, pa, pe, emit=getattr(spec, "EMIT", 1.6)))
    tris = L.tri_count(ob)
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    print("[%s] tris=%d verts=%d bones=%d" % (cid, tris, len(ob.data.vertices), len(rig.data.bones)))
    if do_preview:
        preview(cid, os.path.join(WORK, cid + "_prev.png"))
    meta = {}
    if do_anim:
        meta = animate(spec, rig, cid)
    if not do_anim:          # preview-only run: never overwrite the shipped glb with an animation-less one
        return tris
    out = os.path.join(ROOT, "game", "art", "creatures", "models", cid) if getattr(spec, "TSCN", "") == "creature" else os.path.join(ROOT, "game", "art", "models", "npcs", cid)
    os.makedirs(out, exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(o in (ob, rig))
    bpy.context.view_layer.objects.active = rig
    glb = os.path.join(out, cid + ".glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=do_anim,
                              export_animation_mode="ACTIONS", export_skins=True, export_apply=False,
                              export_yup=True, export_force_sampling=True, export_image_format="WEBP")
    json.dump({"height_m": spec.HEIGHT, "tris": tris, "texture_px": 128, "fps": 30, "animations": meta},
              open(os.path.join(out, cid + "_anim.json"), "w"), indent=1)
    if getattr(spec, "TSCN", "") == "creature":
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, cid + ".blend"))
        print("[%s] wrote %s" % (cid, glb))
        return tris
    extra = getattr(spec, "TSCN_EXTRA", "")
    open(os.path.join(out, cid + "_model.tscn"), "w").write(
        '[gd_scene load_steps=3 format=3]\n\n'
        '[ext_resource type="Script" path="res://game/art/models/character_model.gd" id="1"]\n'
        '[ext_resource type="PackedScene" path="res://game/art/models/npcs/%s/%s.glb" id="2"]\n\n'
        '[node name="%sModel" type="Node3D"]\nscript = ExtResource("1")\nmodel_scene = ExtResource("2")\n'
        'anim_json = "res://game/art/models/npcs/%s/%s_anim.json"\nheight_m = %.3f\ncharacter_id = "%s"\n%s'
        % (cid, cid, cid.capitalize(), cid, cid, spec.HEIGHT, cid, extra))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(WORK, cid + ".blend"))
    print("[%s] wrote %s" % (cid, glb))
    return tris


def animate(spec, rig, cid):
    from retarget import FPS, Skeleton
    from apply import bake
    sc = bpy.context.scene
    sc.render.fps = FPS
    sc.render.fps_base = 1.0
    sc.frame_start = 0
    sk = Skeleton.from_blender(rig)
    meta = {}
    if getattr(spec, "RIG", "humanoid") == "humanoid":
        from characters import npc
        npc.STYLE = dict(getattr(spec, "STYLE", {}))
        npc.SECONDARY = list(getattr(spec, "SECONDARY", []))
        npc.TALK_WINDOW = getattr(spec, "TALK_WINDOW", (1.7, 3.6667))
        for name in npc.CLIPS + (npc.COMBAT_CLIPS if getattr(spec, 'COMBAT', False) else []):
            tr, m = npc.build(name, sk)
            bake(rig, name, tr)
            meta[name] = m
            print("[anim] %-10s %5.2fs" % (name, m["duration"]))
    else:
        import creature_rig
        for name, (tr, m) in creature_rig.clips(spec, sk).items():
            bake(rig, name, tr)
            meta[name] = m
            print("[anim] %-10s %5.2fs" % (name, m["duration"]))
    rig.animation_data.action = None
    return meta


def write_registry():
    """game/art/models/npcs/npc_registry.json: id -> scene path / height / tris (read by RrNpcs and VisualFactory users)."""
    base = os.path.join(ROOT, "game", "art", "models", "npcs")
    reg = {}
    for cid in sorted(os.listdir(base)):
        j = os.path.join(base, cid, cid + "_anim.json")
        if os.path.exists(j):
            m = json.load(open(j))
            reg[cid] = {"scene": "res://game/art/models/npcs/%s/%s_model.tscn" % (cid, cid), "height_m": m["height_m"], "tris": m["tris"],
                        "clips": sorted(m["animations"].keys())}
    json.dump(reg, open(os.path.join(base, "npc_registry.json"), "w"), indent=1)
    print("registry:", len(reg), "models")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ids = args or ALL
    t = {}
    for i in ids:
        t[i] = build(i, "--preview" in sys.argv, "--noanim" not in sys.argv)
    print("TRIS", t)
    # npc_registry.json is hand/NpcLife-owned (merged format); write_registry() is kept for reference only.
