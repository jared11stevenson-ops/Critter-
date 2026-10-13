"""CIGARRA - The Oracle Hopper (approved sheet: tools/source_art/cigarra_sheet.jpg). Brazilian-treehopper psychic witch: wild pale leaf-strand
hair, big ringed yellow-green eyes, forehead gem, oversized dark hood-jacket, cropped top, baggy cuffed trousers, belt charms (skulls, eggs),
leafy boots, bandaged forearms, a translucent leaf-veined wing cloak, and the black branching crown whose six spheres are the swarm.
Run: python3 tools/blender/build_cigarra.py -> v2/art/models/cigarra.glb + cigarra.json (the swarm spheres stay procedural in Godot)."""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
PURPLE = hexc("3d3150"); PURPLE2 = hexc("2c2340"); PURPLE3 = hexc("54446e"); LIME = hexc("a9c83c"); LIME2 = hexc("c9e04a"); SKIN = hexc("e2b58a")
HAIR = hexc("efe9d8"); HAIR2 = hexc("d9d2b6"); BOOT = hexc("3b3a1f"); OLIVE = hexc("8a9a3a"); ORANGE = hexc("e0873a"); BLACK = hexc("15111a")
GOLD = hexc("e8d04a", 0.6); CREAM = hexc("e2dcc4"); WING = hexc("a8c93e"); WING2 = hexc("7fa02c"); SPOT = hexc("2a2236"); VEIN = hexc("e2f08a", 0.5)
lib.reset()
parts = {}

# ---- legs (baggy cuffed trousers, striped socks, leafy boots); hips at y=1.0
def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.2, z))
    p.tube([(x0, 1.2, z), (x0 + 0.04, 0.92, z), (x0 + 0.06, 0.62, z)], (0.2, 0.17), PURPLE, sides=12)           # baggy trouser leg
    p.blob((x0 + 0.1, 0.98, z), (0.14, 0.16, 0.2), PURPLE2)                                                      # cargo patch
    p.hard().ring((x0 + 0.06, 0.58, z), 0.17, 0.04, PURPLE3, rot=(90, 0, 0), seg=14, tseg=4)                     # cuff
    p.tube([(x0 + 0.05, 0.58, z), (x0 + 0.03, 0.2, z)], (0.085, 0.07), CREAM, sides=8)                          # striped sock
    for k in range(3):
        p.hard().ring((x0 + 0.045, 0.5 - 0.08 * k, z), 0.088, 0.016, OLIVE, rot=(90, 0, 0), seg=10, tseg=4)
    p.blob((x0 + 0.14, 0.1, z), (0.26, 0.11, 0.14), BOOT)                                                       # boot
    p.hard().blob((x0 + 0.33, 0.1, z), (0.08, 0.075, 0.1), hexc("2a2a14"))
    p.hard().tube([(x0 + 0.0, 0.2, z + 0.05 * s), (x0 - 0.12, 0.2, z + 0.1 * s), (x0 - 0.2, 0.14, z + 0.12 * s)], (0.05, 0.02), OLIVE, wide=(0, 0, 1), sides=4)  # leaf trim
    parts[name] = p.finish(voxel=0.045, smooth_passes=2, target_tris=640)

leg("leg_f", 0.2, 0.0)
leg("leg_b", -0.2, -0.04)

# ---- torso: hips, cropped top, belt with charms, oversized hood-collar
t = Part("torso", (0, 1.0, 0), dy=0.2)
t.blob((0.0, 1.06, 0), (0.28, 0.2, 0.3), PURPLE)                                       # trouser waist
t.tube([(0.0, 1.1, 0), (0.03, 1.4, 0), (0.04, 1.66, 0)], (0.18, 0.2), SKIN, sides=12)    # bare midriff
t.blob((0.05, 1.74, 0), (0.2, 0.2, 0.25), CREAM)                                      # cropped top
t.hard().blob((0.02, 1.74, 0), (0.22, 0.2, 0.28), PURPLE2, seg=12, ring=8)              # open jacket body
t.hard().ring((0.0, 1.14, 0), 0.27, 0.045, ORANGE, rot=(90, 0, 0), seg=16, tseg=5)     # belt
for (pos, col, rr, hh) in (((0.26, 1.02, 0.2), CREAM, 0.07, 0.1), ((0.2, 1.0, -0.22), hexc("f2c27a"), 0.065, 0.09), ((0.1, 1.02, 0.28), OLIVE, 0.055, 0.075)):
    t.hard().tube([(pos[0], pos[1] + 0.12, pos[2]), pos], 0.01, ORANGE, sides=3)
    t.hard().blob((pos[0], pos[1] - hh * 0.8, pos[2]), (rr, hh, rr * 0.8), col)          # skull / egg charms
    t.hard().blob((pos[0] + rr * 0.6, pos[1] - hh * 0.6, pos[2] + rr * 0.3), (0.012, 0.018, 0.012), BLACK, seg=5, ring=4)
t.hard().blob((0.0, 2.0, 0), (0.3, 0.18, 0.38), PURPLE2, seg=14, ring=8)                # oversized hood-collar
t.hard().tube([(0.2, 1.87, 0.32), (0.28, 1.74, 0.0), (0.2, 1.87, -0.32)], 0.025, LIME, sides=4)
for dz in (-0.3, -0.15, 0.0, 0.15, 0.3):
    t.hard().tube([(0.25, 1.74, dz), (0.29, 1.64, dz), (0.27, 1.54, dz)], (0.04, 0.02), LIME, wide=(0, 0, 1), sides=4)
t.tube([(0.04, 1.82, 0), (0.07, 2.0, 0)], 0.07, SKIN, sides=8)                          # neck
parts["torso"] = t.finish(voxel=0.04, smooth_passes=2, target_tris=1200)

# ---- head (pivot at the neck top): face, big eyes (face shader on top), hair mass, leaf strands, leaf ears, crown
hp = (0.08, 1.9, 0)
HS = 0.8
h = Part("head", hp, dy=0.34, sc=HS)
h.blob((0.12, 2.07, 0), (0.2, 0.23, 0.19), SKIN)                                         # face/skull
h.hard().blob((0.3, 2.17, 0), (0.03, 0.06, 0.04), GOLD, rot=(0, 0, 20), seg=6, ring=5)   # forehead gem
for pr in ((0.3, 2.12, 0.07), (0.3, 2.12, -0.07), (0.2, 1.92, 0.17), (0.2, 1.92, -0.17)):
    h.hard().blob(pr, (0.02, 0.02, 0.02), BLACK, seg=5, ring=4)
h.blob((0.02, 2.22, 0), (0.24, 0.19, 0.26), HAIR, rot=(0, 0, 14))                        # hair mass
for k in range(11):
    az = -1.2 + 2.4 * k / 10
    base = (0.04, 2.28, 0.2 * math.sin(az))
    drop = 0.25 + 0.15 * abs(math.sin(k * 1.9))
    h.hard().tube([base, (base[0] - 0.12, base[1] + 0.07, base[2] * 1.3), (base[0] - 0.24, base[1] - drop * 0.4, base[2] * 1.5), (base[0] - 0.28, base[1] - drop, base[2] * 1.55)],
                  (0.055, 0.015), HAIR if k % 3 != 1 else LIME2, wide=(0, 0, 1) if k % 2 == 0 else (1, 0, 0), sides=4)
for k in range(5):
    z = (k - 2) * 0.09
    h.hard().tube([(0.2, 2.3, z), (0.28, 2.27, z * 1.2), (0.3, 2.17, z * 1.4)], (0.035, 0.01), HAIR if k % 2 == 0 else LIME, wide=(0, 0, 1), sides=4)   # fringe
for sd in (-1, 1):
    h.hard().tube([(0.1, 2.02, 0.19 * sd), (0.02, 2.1, 0.36 * sd), (-0.1, 2.2, 0.52 * sd)], (0.06, 0.012), LIME, wide=(0, 1, 0), sides=4)           # leaf ears
    h.hard().tube([(0.12, 1.84, 0.2 * sd), (0.06, 1.74, 0.26 * sd), (0.0, 1.66, 0.27 * sd)], (0.04, 0.012), HAIR2, wide=(1, 0, 0), sides=4)            # side locks
# crown: black twig + branches (the six swarm spheres sit on the branch tips)
tw = (0.1, 2.42, 0)
h.hard().tube([tw, (0.1, 2.52, 0), (0.1, 2.6, 0)], (0.04, 0.03), BLACK, sides=6)
branches = [((0.1, 0.5, 0.3), (0.2, 0.62, 0.55)), ((-0.05, 0.55, 0.12), (0.0, 0.8, 0.1)), ((0.1, 0.5, -0.3), (0.2, 0.66, -0.58)),
            ((-0.2, 0.42, 0.28), (-0.36, 0.5, 0.45)), ((-0.2, 0.42, -0.28), (-0.36, 0.54, -0.5)), ((0.3, 0.8, 0.3), (0.35, 0.98, 0.22))]
rest = []
base = (tw[0], tw[1] + 0.18, tw[2])
for (a, b) in branches:
    pa = (tw[0] + a[0] * 0.55, tw[1] + a[1] * 0.55, tw[2] + a[2] * 0.55)
    pb = (tw[0] + b[0] * 0.55, tw[1] + b[1] * 0.55, tw[2] + b[2] * 0.55)
    h.hard().tube([base, pa, pb], (0.024, 0.014), BLACK, sides=5, caps=True)
    rest.append(pb)
parts["head"] = h.finish(voxel=0.03, smooth_passes=2, target_tris=1100)

# ---- arms: puffy sleeves, bandaged forearms, long pale hands; shoulders at y=1.72
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (0.0, 1.72, z), dy=0.26)
    p.blob((0.0, 1.62, z + 0.02 * s), (0.17, 0.2, 0.17), PURPLE3)                                         # puffy sleeve
    p.tube([(0.02, 1.5, z + 0.03 * s), (0.08, 1.3, z + 0.05 * s)], (0.085, 0.07), CREAM, sides=8)          # bandaged forearm
    p.hard().ring((0.05, 1.44, z + 0.04 * s), 0.09, 0.022, PURPLE3, rot=(80, 0, 12), seg=10, tseg=4)
    p.blob((0.14, 1.2, z + 0.06 * s), (0.08, 0.1, 0.065), SKIN)                                            # hand
    for dz in (-0.035, 0.0, 0.035):
        p.hard().tube([(0.19, 1.15, z + 0.06 * s + dz), (0.26, 1.06, z + 0.07 * s + dz * 1.4)], (0.02, 0.0), SKIN, sides=4)
    parts[name] = p.finish(voxel=0.035, smooth_passes=2, target_tris=480)

arm("arm_f", 0.4)
arm("arm_b", -0.4)

# ---- wing cloak: two layers of long scalloped translucent petals around the back (glass material in Godot)
e = Part("extra", (-0.05, 1.8, 0), dy=0.3)
def petal(phi, top_y, ln, wid, flare, col):
    ph = math.radians(phi)
    R = 0.4
    cx = -0.12 - math.cos(ph) * R
    cz = math.sin(ph) * R
    y0 = top_y
    # a long thin leaf plane hanging from the shoulder, flaring outward
    pts = [(cx, y0, cz), (cx - 0.06 * math.cos(ph) - 0.02, y0 - ln * 0.5, cz + 0.08 * math.sin(ph) * (1 + flare / 20)), (cx - 0.12 * math.cos(ph) - 0.05, y0 - ln, cz + 0.16 * math.sin(ph) * (1 + flare / 20))]
    wd = (0, 0, 1) if abs(math.sin(ph)) < 0.7 else (1, 0, 0)
    e.hard().tube(pts, ((wid * 0.55, 0.006), (wid, 0.006), (wid * 0.25, 0.006)), col, wide=wd, sides=4, caps=False)
    e.hard().tube(pts, (0.01, 0.006), VEIN, sides=3, caps=False)
for k in range(7):
    phi = -105 + 210 * k / 6
    petal(phi, 1.78, 0.95 + 0.25 * math.cos(math.radians(phi)) - 0.18 * (k % 2), 0.2, 10 + 6 * abs(phi) / 105, WING)
for k in range(5):
    phi = -95 + 190 * k / 4
    petal(phi, 1.66, 1.0 + 0.3 * math.cos(math.radians(phi)) - 0.2 * (k % 2), 0.22, 18 + 8 * abs(phi) / 95, WING2)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=900)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.export(os.path.join(OUT, "cigarra.glb"))
tw_local = [(tw[0] - hp[0]) * HS, (tw[1] - hp[1]) * HS, tw[2] * HS]
meta = {"sockets": {"head": ["head", 0.04 * HS, 0.17 * HS, 0.0], "crown": ["head", tw_local[0], tw_local[1], 0.0],
                    "hand": ["arm_f", 0.16, -0.58, 0.06], "weapon_base": ["arm_f", 0.16, -0.58, 0.06], "weapon_tip": ["arm_f", 0.3, -0.76, 0.07]},
        "face": {"center": [0.04 * HS, 0.17 * HS, 0.0], "radii": [0.21 * HS, 0.24 * HS, 0.2 * HS], "half_lon": 0.95, "half_lat": 0.75, "lat_center": -0.12, "e": 0.92},
        "swarm_pos": [hp[0] + tw_local[0], hp[1] + 0.34 + tw_local[1], 0.0],
        "swarm_rest": [[round((r[0] - tw[0]) * HS, 4), round((r[1] - tw[1]) * HS, 4), round((r[2] - tw[2]) * HS, 4)] for r in rest]}
json.dump(meta, open(os.path.join(OUT, "cigarra.json"), "w"), indent=1)
