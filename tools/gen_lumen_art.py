#!/usr/bin/env python3
"""Generate game/world/lumen/lumen_art.json (Lumen Depths vault-layer placements for ReachesLandmarks)."""
import json, random, os
rng = random.Random(77)
G = []
def grp(id, items, shadow=True, vis_end=0.0):
    G.append({"id": id, "shadow": shadow, "vis_end": vis_end, "vis_begin": 0.0, "items": items})
def L(piece, x, z, s=1.0, r=0.0, **kw):
    d = {"p": piece, "x": x, "z": z, "s": s, "r": r}
    d.update(kw)
    return d
AVOID = [[8,0,8],[20,1,5],[32,2,5],[44,4,5],[52,4,5],[62,5,6],[70,5,5],[78,5,5],[90,4,5],[100,2,6],[66,-12,4],[65,-20,4],[64,-27,4],[105,2,8],[134,2,8],[145,4,6]]
def scat(c, r, n, seed, pieces, s=(1, 1), **kw):
    d = {"c": c, "r": r, "n": n, "seed": seed, "pieces": pieces, "s": list(s), "avoid": AVOID}
    d.update(kw)
    return {"scatter": d}

# far crystal spires ringing the vault (the skyline), chunked in x
sky = []
for row, (z0, sc) in enumerate([(-80, (1.2, 2.0)), (-120, (1.8, 3.0)), (-170, (2.6, 4.2))]):
    x = -80 + rng.uniform(0, 20)
    while x < 280:
        sky.append({"p": "lumen_spire_big", "x": round(x, 1), "z": round(z0 + rng.uniform(-12, 12), 1), "s": round(rng.uniform(*sc), 2),
                    "r": round(rng.uniform(0, 360)), "dy": -2.0, "bd": True})
        x += rng.uniform(26, 52) * (0.7 + sc[0] * 0.2)
for x, z in [(-70, 20), (-60, -10), (250, 10), (260, -20), (80, 100), (160, 110), (30, 105)]:
    sky.append({"p": "lumen_spire_big", "x": x, "z": z, "s": round(rng.uniform(1.6, 3.0), 2), "r": round(rng.uniform(0, 360)), "dy": -2.0, "bd": True})
ch = {}
for it in sky:
    ch.setdefault(int((it["x"] + 100) // 130), []).append(it)
for k in sorted(ch):
    grp("sky_%d" % k, ch[k], shadow=False)

# spawn ledge + the path
grp("ledge", [
    L("lumen_spire_b", -6, -8, 1.2, 20, col={"cyl": [0.9, 3.0]}), L("lumen_spire_a", 10, -11, 1.1, 120, col={"cyl": [1.2, 4.0]}),
    L("lumen_spire_c", -9, 7, 1.3, 40), L("lumen_spire_c", 6, 11, 1.1, 200),
    L("glow_colony", -3, -10, 1.3, 0), L("glow_colony", 9, 9, 1.1, 90), L("glow_colony", -10, 2, 1.0, 40),
    L("bell_moss", -7, 10, 1.2, 0), L("bell_moss", 4, -9, 1.3, 70), L("bell_moss", 12, 6, 1.0, 20),
    L("mineral_shelf", -4, -4, 1.0, 30), L("glass_bloom", 8, -6, 1.2, 0), L("glass_bloom", -8, -5, 1.0, 100),
    L("sleeping_den", -16, -18, 1.4, 0, dy=-0.5),
], vis_end=160)
grp("path", [
    scat([27, 2], 18, 16, 3, ["lumen_spire_c", "lumen_spire_c", "bell_moss", "glow_colony"], (0.9, 1.4), off_floor=True, floor_margin=1.5, min_gap=3.0, clear=3.0),
    scat([27, 2], 16, 6, 4, ["glass_bloom"], (1.0, 1.4), off_floor=True, floor_margin=0.8, min_gap=3.0),
], vis_end=140)

# the crystal forest: tall spires on the shelves, basalt column fields, glass bloom meadows, colonies
fo = [
    L("lumen_spire_a", 50, -8, 1.8, 10, col={"cyl": [1.6, 6.0]}), L("lumen_spire_a", 76, -4, 1.6, 150, col={"cyl": [1.6, 6.0]}),
    L("lumen_spire_b", 44, 18, 1.5, 200, col={"cyl": [1.2, 4.0]}), L("lumen_spire_b", 78, 20, 1.6, 60, col={"cyl": [1.2, 4.0]}),
    L("lumen_spire_a", 62, 26, 1.7, 90, col={"cyl": [1.6, 6.0]}), L("lumen_spire_b", 54, -6.5, 1.2, 300),
    L("basalt_cols", 52, 14, 1.6, 20), L("basalt_cols", 72, 10, 1.4, 130), L("basalt_cols", 60, -4, 1.3, 70),
    L("mineral_shelf", 62, 6, 1.4, 50, dy=-0.15),
]
fo.append(scat([62, 6], 21, 30, 11, ["lumen_spire_c", "lumen_spire_b", "lumen_spire_c", "lumen_spire_a"], (0.9, 1.5), off_floor=True, floor_margin=-8.0, min_gap=3.4, clear=3.0))
fo.append(scat([62, 6], 20, 22, 12, ["glass_bloom", "bell_moss", "glow_colony"], (0.9, 1.5), min_gap=2.4, clear=2.5))
grp("forest", fo, vis_end=170)

# dark pool: kelp shallows, colonies, shelf stepping stones, spires on the rim
po = [
    scat([64, -36], 11, 18, 21, ["lantern_kelp"], (0.9, 1.5), on_floor=True, floor_margin=2.0, min_gap=2.2),
    scat([64, -36], 14, 10, 22, ["glow_colony", "bell_moss"], (0.9, 1.3), min_gap=3.0, on_floor=True, floor_margin=0.5),
    L("mineral_shelf", 58, -30, 0.9, 20, dy=-0.6), L("mineral_shelf", 70, -42, 0.8, 120, dy=-0.6),
    L("lumen_spire_a", 50, -42, 1.5, 40, col={"cyl": [1.6, 6.0]}), L("lumen_spire_b", 78, -30, 1.4, 200),
    L("lumen_spire_c", 56, -48, 1.2, 0), L("lumen_spire_c", 74, -26, 1.2, 100),
]
grp("pool", po, vis_end=150)

# warm pulse colonies along the whole route (the rhythm is language: gold = calm, pink = warning)
grp("pulse_line", [
    scat([30, 2], 16, 10, 41, ["glow_colony"], (1.1, 1.7), off_floor=True, floor_margin=2.0, min_gap=4.0),
    scat([90, 4], 14, 8, 42, ["glow_colony"], (1.1, 1.6), off_floor=True, floor_margin=2.0, min_gap=4.0),
    L("glow_colony", 100, -2, 1.5, 0), L("glow_colony", 138, 6, 1.5, 100), L("glow_colony", 99, 8, 1.3, 40), L("bell_moss", 133, -2, 1.5, 0),
], vis_end=150)

# the shaft crossing: hanging walkway, anchor spires, lantern posts
wk = []
for i in range(4):
    wk.append(L("hanging_walkway", 107.0 + i * 6.0, 2.0, 1.0, 0, y=-2.02))
wk += [L("lumen_spire_b", 103, -5, 1.6, 40, col={"cyl": [1.2, 4.0]}), L("lumen_spire_b", 135, 8, 1.6, 200, col={"cyl": [1.2, 4.0]}),
       L("glow_colony", 101, 8, 1.2, 0), L("glow_colony", 137, -3, 1.2, 100)]
grp("shaft", wk, vis_end=170)

# far ledge: the sleeping den and a sealed vault door; crystals thin out to quiet
fl = [
    L("sleeping_den", 148, -17, 1.6, 0, y=-2.0, col=[9.0, 6.0, 3.0, 0, 0, -0.8]),
    L("vault_door", 166, -16.2, 1.1, 0, y=-2.0, col=[10.0, 8.0, 3.0, 0, 0, -1.0]),
    L("lumen_spire_a", 142, 16, 1.5, 100, col={"cyl": [1.6, 6.0]}), L("lumen_spire_b", 170, 12, 1.4, 20),
    L("glow_colony", 154, -8, 1.0, 20), L("bell_moss", 146, -9, 1.2, 0), L("bell_moss", 162, -9, 1.1, 90),
    L("glass_bloom", 158, 2, 1.2, 10), L("mineral_shelf", 154, 6, 1.5, 60, dy=-0.15),
]
fl.append(scat([154, 4], 20, 10, 31, ["lumen_spire_c", "glass_bloom", "bell_moss"], (0.9, 1.4), off_floor=True, floor_margin=-6.0, min_gap=3.4, clear=3.0))
grp("far_ledge", fl, vis_end=170)

path = os.path.join(os.path.dirname(__file__), "..", "game", "world", "lumen", "lumen_art.json")
json.dump({"_doc": "Generated by tools/gen_lumen_art.py", "groups": G}, open(path, "w"), indent=0, separators=(",", ":"))
print("groups", len(G), "items", sum(len(g["items"]) for g in G))
