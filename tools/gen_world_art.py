#!/usr/bin/env python3
"""Generate game/world/red_reaches/world_art.json (landmark / skyline / dressing placements for ReachesLandmarks).
Coordinates: x east, z south (camera side), metres. y is snapped to the terrain unless given."""
import json, math, random, os

rng = random.Random(2026)
G = []

def grp(id, items, shadow=True, vis_end=0.0, vis_begin=0.0):
    G.append({"id": id, "shadow": shadow, "vis_end": vis_end, "vis_begin": vis_begin, "items": items})

# ---- skyline: merged low-poly mesas/buttes ringing the level (chunked in x for frustum culling) ----
sky = []
def sky_item(piece, x, z, s, r):
    sky.append({"p": piece, "x": round(x, 1), "z": round(z, 1), "s": round(s, 2), "r": round(r, 0), "dy": -3.0, "bd": True})
pieces_far = ["mesa_a_lo", "mesa_b_lo", "mesa_c_lo", "butte_a_lo", "butte_b_lo"]
for row, (z0, sc) in enumerate([(-96, (1.8, 2.8)), (-142, (2.6, 3.8)), (-200, (3.4, 4.8))]):
    x = -160 + rng.uniform(0, 30)
    while x < 520:
        piece = rng.choice(pieces_far)
        s = rng.uniform(*sc) * (0.75 if "butte" in piece else 1.0)
        sky_item(piece, x, z0 + rng.uniform(-14, 14), s, rng.uniform(0, 360))
        x += rng.uniform(46, 78) * (s / 2.5 + 0.4)
# west / east caps and a few southern ones (hero cameras look back south)
for x, z, p, s in [(-110, -30, "mesa_b_lo", 2.4), (-130, 10, "butte_a_lo", 2.0), (-100, 60, "mesa_c_lo", 2.6),
                   (420, -20, "mesa_a_lo", 3.0), (440, 40, "butte_b_lo", 2.6), (470, -60, "mesa_b_lo", 3.4),
                   (30, 120, "mesa_c_lo", 3.0), (130, 135, "butte_a_lo", 2.4), (230, 125, "mesa_b_lo", 2.8), (330, 118, "mesa_c_lo", 3.0)]:
    sky_item(p, x, z, s, rng.uniform(0, 360))
chunks = {}
for it in sky:
    chunks.setdefault(int((it["x"] + 200) // 150), []).append(it)
for k in sorted(chunks):
    grp("sky_%d" % k, chunks[k], shadow=False)

# ---- mid landmarks: wayfinding silhouettes just behind the rim (hi-poly, culled beyond range) ----
def L(piece, x, z, s=1.0, r=0.0, **kw):
    d = {"p": piece, "x": x, "z": z, "s": s, "r": r}
    d.update(kw)
    return d

mid = [
    L("rock_arch", 62, -58, 2.4, 0, dy=-2),                      # the Window: seen from the valley
    L("butte_a", 118, -72, 1.7, 20, dy=-3),                      # the Anvil, north of the Waystation
    L("butte_b", 150, -66, 1.5, 70, dy=-3),                      # twin sentinels over the Boulder Pass
    L("butte_b", 166, -74, 1.2, 10, dy=-3),
    L("mesa_b", 196, -58, 2.1, 0, dy=-3),                        # the drill-basin wall
    L("hoodoo_a", 232, -62, 3.2, 0, dy=-2),                      # the Needle over the Span approach
    L("mesa_a", 280, -66, 2.6, 30, dy=-3),
    L("mesa_c", 330, -64, 2.2, 150, dy=-3),
    L("butte_a", 14, -78, 1.5, 200, dy=-3),
    L("mesa_a", -44, -40, 1.8, 90, dy=-3),
    L("hoodoo_b", 38, -46, 2.2, 0, dy=-2),
    L("hoodoo_a", 86, -50, 2.0, 0, dy=-2),
    L("mesa_c", 128, 70, 1.8, 0, dy=-3),
    L("butte_b", 210, 74, 1.6, 40, dy=-3),
    L("butte_a", 300, 70, 1.4, 300, dy=-3),
]
grp("mid_landmarks", mid, shadow=False, vis_end=260)

# ---- the Window (rock arch) over the Fracture Valley: collision legs are on the rim ----
# ---- Valley dressing ----
grp("valley", [
    L("boulder_a", 46, -9.5, 1.5, 20), L("boulder_b", 52, 9, 1.4, 120), L("boulder_c", 78, 9.5, 1.8, 40),
    L("scree", 40, -9, 1.6, 0), L("scree", 70, 9, 1.4, 90), L("scree", 58, -10, 1.3, 40),
    L("flat_tree_a", 36, -12, 1.0, 0), L("flat_tree_b", 66, -11, 1.1, 90), L("flat_tree_b", 22, 9, 1.0, 40),
    L("marker_stone", 28, 8.2, 0.9, 200, col=[1.6, 4.4, 1.1]),
], vis_end=150)

# ---- Red Span remnant (the bridge that failed) on the Gap's west lip ----
grp("red_span_remnant", [
    L("span_stump", 85.0, -8.5, 1.0, 0, col=[3.6, 7.0, 5.4, 0, 0, 0]),
    L("cairn_names", 82.0, -6.0, 1.0, 20, col={"cyl": [1.2, 2.0]}),
    L("pillar_broken", 89, 9, 1.0, 130),
], vis_end=140)

# ---- Echo Hollow glyph wall ----
grp("echo_hollow", [
    L("glyph_wall", 64.0, -39.6, 1.0, 0, col=[9.0, 6.0, 1.6, 0, 0, 0]),
    L("boulder_b", 58, -36, 1.2, 40), L("boulder_a", 70, -37, 1.0, 100),
    L("thoughtstone_b", 61.5, -37.2, 1.0, 0), L("thoughtstone_b", 67.2, -36.8, 0.8, 90),
], vis_end=120)

# ---- Boulder Pass / Thoughtstone vault ----
grp("pass_vault", [
    L("vault_door", 160.0, -34.4, 1.0, 0, col=[9.4, 8.0, 3.0, 0, 0, -0.9]),
    L("thoughtstone_b", 154.6, -32.8, 1.0, 20), L("thoughtstone_b", 165.2, -32.6, 1.1, 70),
    L("thoughtstone_a", 146, 10.5, 1.0, 0, col={"cyl": [1.0, 2.0]}), L("thoughtstone_b", 158.5, 9.5, 1.0, 100),
    L("boulder_c", 141.5, -6.5, 1.8, 20), L("boulder_a", 147, -7.5, 1.7, 70), L("boulder_b", 138.5, 8, 1.6, 200),
    L("scree", 156, 11, 1.7, 30), L("scree", 143, 9.5, 1.3, 200),
    L("marker_stone", 170, 3.5, 0.9, 160, col=[1.6, 4.4, 1.1]),
], vis_end=150)

# ---- Salt pans / grazer flats ----
grp("salt_pans", [
    {"scatter": {"c": [110, 34], "r": 9.5, "n": 16, "seed": 7, "pieces": ["salt_crust"], "s": [1.3, 2.1], "on_floor": True, "clear": 2.6, "min_gap": 4.5}},
    {"scatter": {"c": [110, 35], "r": 9, "n": 10, "seed": 9, "pieces": ["salt_crystals"], "s": [1.0, 1.6], "on_floor": True, "clear": 3.0, "min_gap": 3}},
    L("pillar_broken", 100.5, 31.5, 1.0, 30),
], vis_end=120, shadow=False)
grp("grazer_flats", [
    {"scatter": {"c": [130, 6], "r": 11, "n": 22, "seed": 3, "pieces": ["lichen_mat", "lichen_mat", "lichen_terrace"], "s": [0.9, 1.5], "on_floor": True, "clear": 4.0, "min_gap": 3.2, "floor_margin": 1.0}},
    L("bone_ribs", 138.5, 9.5, 1.4, 20), L("bone_ribs", 108.5, 12.0, 1.1, 150),
], vis_end=110, shadow=False)

# ---- Overlook: load posts, rail runs and crew cairns facing the Span ----
ov = []
for i in range(6):
    x = 229.0 + i * 3.2
    ov.append(L("load_post", x, -38.6, 1.0, 0, col=[0.6, 1.5, 0.6]))
for i in range(5):
    ov.append(L("rail_run", 230.6 + i * 3.2, -38.6, 0.8, 0))
for x, z, s, p in [(231, -34.5, 1.0, "cairn"), (234, -35.3, 0.8, "cairn_small"), (243.2, -36.5, 1.1, "cairn"), (226.5, -33, 0.9, "cairn_small"), (245.5, -33, 0.8, "cairn_small")]:
    ov.append(L(p, x, z, s, rng.uniform(0, 360), col={"cyl": [0.6, 1.2]}))
grp("overlook", ov, vis_end=120)

# ---- Dominion drill basin: AUGUR derrick, bore collar, floodlights, spoil, survey flags ----
dr = [
    L("bore_collar", 202, -17, 1.0, 0),
    L("augur_derrick", 202, -17, 1.0, 0, col=[10.5, 6.0, 10.5, 0, 0, 0]),
    L("floodlight", 188.5, -10, 1.0, 20, col={"cyl": [0.25, 7]}), L("floodlight", 216.5, -12, 1.0, 200, col={"cyl": [0.25, 7]}),
    L("floodlight", 210, 2.5, 1.0, 120, col={"cyl": [0.25, 7]}),
    L("spoil_heap", 189, -17.5, 1.4, 20), L("spoil_heap", 219, -19, 1.7, 100), L("spoil_heap", 224, -6, 1.2, 200),
    L("spoil_heap", 176, 19, 1.3, 60), L("spoil_heap", 183, 25, 1.1, 150),
    L("dom_stack", 190.8, -4.2, 1.0, 30, col=[3.8, 2.0, 2.2, 0.4, 0, 0]), L("dom_stack", 214, 16, 1.0, 200, col=[3.8, 2.0, 2.2, 0.4, 0, 0]),
    L("scree", 193, 21, 1.2, 40), L("scree", 218, 9, 1.5, 100),
]
for i, (x, z) in enumerate([(174.5, -1.2), (176.5, 6.2), (181.2, 13.0), (186.5, 18.5), (192.5, 22.5), (178.5, -6.8), (184.0, -12.2)]):
    dr.append(L("survey_flag", x, z, 1.05, rng.uniform(0, 360)))
grp("drill_basin", dr, vis_end=170)

# ---- Spanwright approach: marker stones, cairn trail terminus, pillars ----
grp("span_approach", [
    L("marker_stone", 224.0, 7.2, 1.0, 190, col=[1.6, 4.4, 1.1]),
    L("pillar_broken", 226.5, -8.5, 1.0, 40, col=[1.2, 3.6, 1.2]),
    L("pillar_broken", 244.5, 8.4, 1.0, 100, col=[1.2, 3.6, 1.2]),
    L("cairn", 236, 8.8, 1.0, 40, col={"cyl": [0.8, 1.6]}),
], vis_end=140)

# ---- Gate pad ----
grp("gate_pad", [
    L("flat_tree_a", -16, -13, 1.1, 30), L("flat_tree_b", 12, -14, 1.0, 210),
    L("boulder_c", -14, 9, 1.8, 60), L("scree", 9, 11.5, 1.5, 120), L("bone_ribs", 14, 6.5, 1.0, 90),
    L("cairn_small", -9.2, -9, 1.0, 0), L("cairn", 15.5, -3, 0.9, 0),
], vis_end=120)

out = {"_doc": "Generated by tools/gen_world_art.py: ReachesLandmarks placements (kit pieces from game/art/world/kit).", "groups": G}
path = os.path.join(os.path.dirname(__file__), "..", "game", "world", "red_reaches", "world_art.json")
json.dump(out, open(path, "w"), indent=0, separators=(",", ":"))
print("groups", len(G), "items", sum(len(g["items"]) for g in G))
