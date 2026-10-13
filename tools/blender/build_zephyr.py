"""ZEPHYR - The Nectar Seeker (approved sheet: tools/source_art/zephyr_sheet.png). Tall lanky hummingbird-hawk-moth fairy: bird-skull head with a long
curved proboscis beak, dark red-lit eyes, leaf-feather crest and flower crown, feathered antennae hung with nectar drops, a tattered burgundy/olive
feather cloak, bird legs with talons, nectar vials and satchel, a long proboscis spear, two pairs of big pink/olive translucent wings.
Run: python3 tools/blender/build_zephyr.py -> v2/art/models/zephyr.glb + zephyr.json"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
OLV = hexc("7a6a3e"); OLV2 = hexc("5e6a34"); BURG = hexc("7a2a3a"); BURG2 = hexc("a03a4a"); PINK = hexc("e86a9a"); MAG = hexc("d63a9c"); CREAM = hexc("ecd9b0")
GOLD = hexc("ffd24a", 0.6); LEAF = hexc("6a7a3a"); DARKB = hexc("2a1a1c"); BEAK = hexc("a8845a"); WOOD = hexc("5a3e26"); VIAL = hexc("ff5aa8", 1.0)
WING = hexc("c86a7a"); WING2 = hexc("8a8a4a"); SPOT = hexc("f0d8c0")
lib.reset()
parts = {}
rr = random.Random(5)

# ---- legs: bird legs (feathered thigh, long swept tarsus, three toes + hind talon), hips at y = 1.2
def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.2, z))
    knee = (x0 + 0.2, 0.8, z); hock = (x0 - 0.06, 0.4, z); toe = (x0 + 0.3, 0.04, z)
    p.tube([(x0, 1.2, z), (x0 + 0.1, 1.0, z), knee], (0.13, 0.09), BURG, sides=9)
    p.tube([knee, (x0 + 0.08, 0.6, z), hock], (0.07, 0.05), OLV, sides=7)
    p.tube([hock, (x0 + 0.1, 0.18, z), (x0 + 0.08, 0.06, z)], (0.045, 0.04), DARKB, sides=6)
    for dz in (-0.07, 0.0, 0.07):
        p.hard().tube([(x0 + 0.08, 0.06, z + dz * 0.4), (x0 + 0.3, 0.04, z + dz * 1.6)], (0.025, 0.0), DARKB, sides=4)
    p.hard().tube([(x0 + 0.06, 0.07, z), (x0 - 0.12, 0.03, z)], (0.025, 0.0), DARKB, sides=4)
    for k in range(5):   # leg feathers
        p.hard().tube([(x0 + 0.05, 1.12 - 0.07 * k, z + 0.05 * s), (x0 - 0.1, 0.95 - 0.12 * k, z + 0.1 * s)], (0.04, 0.0), BURG2 if k % 2 == 0 else OLV2, sides=4)
    parts[name] = p.finish(voxel=0.035, smooth_passes=2, target_tris=520)

leg("leg_f", 0.14, 0.1)
leg("leg_b", -0.14, -0.08)

# ---- torso: slim hunched thorax, tattered feather cloak, satchel strap, flower garland
t = Part("torso", (0, 1.2, 0))
t.blob((0.0, 1.25, 0), (0.22, 0.2, 0.22), OLV)
t.tube([(0.0, 1.3, 0), (0.06, 1.65, 0), (0.12, 1.95, 0)], (0.2, 0.23), OLV, sides=10)
t.blob((0.15, 1.8, 0), (0.12, 0.22, 0.22), CREAM)                                              # pale chest
t.hard().blob((0.0, 1.92, 0), (0.3, 0.16, 0.38), BURG)                                         # shoulder mantle
for k in range(12):   # tattered feather cloak
    a = -1.2 + 2.4 * k / 11
    z = 0.34 * math.sin(a); x = -0.05 - 0.2 * math.cos(a)
    ln = 0.7 + 0.25 * ((k * 5) % 3)
    t.hard().tube([(x + 0.1, 1.95, z), (x - 0.04, 1.95 - ln * 0.5, z * 1.2), (x - 0.1, 1.95 - ln, z * 1.3)], ((0.0, 0.01), (0.07, 0.01), (0.0, 0.01)), BURG if k % 3 == 0 else (OLV2 if k % 3 == 1 else BURG2), wide=(0, 0, 1), sides=4)
t.hard().tube([(0.16, 2.0, 0.22), (0.3, 1.7, 0.0), (0.16, 1.35, -0.22)], 0.03, WOOD, sides=4)    # strap
t.hard().blob((0.14, 1.28, -0.28), (0.12, 0.14, 0.08), WOOD)                                  # satchel
for k, c in enumerate((VIAL, GOLD, MAG)):                                                     # nectar vials
    t.hard().blob((0.28, 1.5 - 0.12 * k, 0.12 * (k - 1)), (0.04, 0.07, 0.04), c, seg=6, ring=5)
for k in range(5):    # flower garland
    a = k * 1.26
    t.hard().blob((0.1 + 0.12 * math.cos(a), 2.0, 0.3 * math.sin(a)), (0.05, 0.03, 0.05), PINK if k % 2 == 0 else MAG, seg=6, ring=4)
t.tube([(0.1, 2.0, 0), (0.14, 2.14, 0)], 0.07, OLV, sides=7)                                  # neck
parts["torso"] = t.finish(voxel=0.04, smooth_passes=2, target_tris=1200)

# ---- head: bird skull with a long curved proboscis, crest of leaf feathers, flower crown, feathered antennae with nectar drops
hp = (0.14, 2.2, 0)
h = Part("head", hp)
h.blob((0.24, 2.34, 0), (0.26, 0.24, 0.22), OLV)                                                # skull
h.tube([(0.36, 2.3, 0), (0.7, 2.22, 0), (1.05, 2.1, 0), (1.25, 1.95, 0)], (0.1, 0.01), BEAK, sides=7)    # proboscis
h.hard().tube([(0.4, 2.36, 0), (0.75, 2.3, 0), (1.0, 2.18, 0)], (0.05, 0.01), BURG, sides=5)
for s in (-1, 1):
    eye(h, (0.36, 2.4, 0.15 * s), 0.115, "d83a8a", white="fff4e8", look=(1, 0, 0.3 * s), glow=0.5)
    ant = [(0.2, 2.5, 0.08 * s), (0.1, 2.85, 0.2 * s), (0.18, 3.1, 0.34 * s), (0.3, 3.0, 0.42 * s)]
    h.hard().tube(ant, (0.02, 0.01), WOOD, sides=4)
    h.hard().tube([ant[3], (0.3, 2.82, 0.43 * s)], (0.012, 0.0), WOOD, sides=3)
    h.hard().blob((0.3, 2.74, 0.43 * s), (0.04, 0.07, 0.04), VIAL, seg=6, ring=5)               # nectar drop
for k in range(7):    # leaf-feather crest sweeping back
    a = -0.9 + 1.8 * k / 6
    base = (0.15, 2.5, 0.16 * math.sin(a))
    h.hard().tube([base, (base[0] - 0.12, base[1] + 0.22, base[2] * 1.6), (base[0] - 0.3, base[1] + 0.3, base[2] * 2.0)], ((0.0, 0.01), (0.07, 0.01), (0.0, 0.01)), BURG if k % 2 == 0 else OLV2, wide=(0, 0, 1), sides=4)
for k in range(4):
    h.hard().blob((0.18, 2.52, 0.12 * (k - 1.5)), (0.05, 0.03, 0.05), PINK if k % 2 else MAG, seg=6, ring=4)
parts["head"] = h.finish(voxel=0.03, smooth_passes=2, target_tris=800)

# ---- arms: thin clawed arms; the front hand carries the long proboscis spear
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.05, 1.95, z)
    p = Part(name, sh)
    el = (0.0, 1.5, z + 0.05 * s); hand = (0.2, 1.1, z + 0.08 * s)
    p.tube([sh, el, hand], (0.065, 0.045), OLV, sides=7)
    p.blob(sh, (0.1, 0.1, 0.1), BURG)
    p.blob(hand, (0.07, 0.08, 0.06), DARKB)
    for dz in (-0.03, 0.0, 0.03):
        p.hard().tube([(hand[0] + 0.04, hand[1] - 0.04, hand[2] + dz), (hand[0] + 0.14, hand[1] - 0.16, hand[2] + dz * 1.5)], (0.016, 0.0), DARKB, sides=4)
    for k in range(4):
        p.hard().tube([(0.0 - 0.02 * k, 1.85 - 0.1 * k, z), (-0.14 - 0.02 * k, 1.8 - 0.14 * k, z + 0.04 * s)], (0.04, 0.0), BURG2, sides=4)
    if s > 0:
        d = (0.5, 0.86, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
        a0 = (hand[0] - d[0] * 0.4, hand[1] - d[1] * 0.4, hand[2]); a1 = (hand[0] + d[0] * 1.3, hand[1] + d[1] * 1.3, hand[2]); a2 = (hand[0] + d[0] * 1.9, hand[1] + d[1] * 1.9, hand[2])
        p.hard().tube([a0, a1, a2], ((0.03, 0.03), (0.03, 0.03), (0.0, 0.0)), WOOD, sides=5)
        p.hard().blob(a2, (0.04, 0.04, 0.04), PINK)
        sock["weapon_tip"] = ["arm_f", round(a2[0] - sh[0], 4), round(a2[1] - sh[1], 4), round(a2[2] - sh[2], 4)]
        sock["weapon_base"] = ["arm_f", round(hand[0] - sh[0], 4), round(hand[1] - sh[1], 4), round(hand[2] - sh[2], 4)]
        sock["hand"] = ["arm_f", round(hand[0] - sh[0], 4), round(hand[1] - sh[1], 4), round(hand[2] - sh[2], 4)]
    parts[name] = p.finish(voxel=0.03, smooth_passes=2, target_tris=520)

sock = {}
arm("arm_f", 0.3)
arm("arm_b", -0.3)

# ---- hanging vials and charms (lag)
w = Part("weapon", (-0.1, 1.5, 0.34))
w.hard().tube([(-0.1, 1.5, 0.34), (-0.1, 1.2, 0.34)], 0.012, WOOD, sides=3)
w.hard().blob((-0.1, 1.1, 0.34), (0.05, 0.09, 0.05), VIAL, seg=7, ring=5)
w.hard().blob((-0.04, 1.2, 0.3), (0.04, 0.07, 0.04), GOLD, seg=6, ring=5)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=200)

# ---- wings: two big pink/olive translucent forewings + two smaller hindwings with spots (glass material in Godot)
e = Part("extra", (-0.2, 1.4, 0))
def wing(side, root, ln, wid, tilt, col, up):
    z0 = 0.12 * side
    pts = [(root[0], root[1], z0), (root[0] - 0.1, root[1] + up * ln * 0.5, z0 + 0.5 * side * tilt), (root[0] - 0.18, root[1] + up * ln, z0 + 1.0 * side * tilt)]
    e.hard().tube(pts, ((0.04, 0.008), (wid, 0.008), (wid * 0.4, 0.008)), col, wide=(1, 0, 0), sides=4, caps=False)
    e.hard().tube(pts, (0.015, 0.01), WOOD, sides=4, caps=False)
    for q in range(3):
        f = 0.35 + 0.2 * q
        e.hard().blob((pts[1][0] - 0.06 * q, pts[1][1] + up * ln * (f - 0.5) * 0.6, pts[1][2] + 0.25 * side * q), (0.03, 0.03, 0.012), SPOT, seg=6, ring=4)
for sd in (-1, 1):
    wing(sd, (-0.2, 2.15, 0), 1.1, 0.32, 0.9, WING, 1)
    wing(sd, (-0.2, 2.0, 0), 0.8, 0.24, 0.8, WING2, -1)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=600)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "zephyr.glb"))
meta = {"sockets": dict(sock, head=["head", 0.08, 0.15, 0.0]), "face_off": True}
json.dump(meta, open(os.path.join(OUT, "zephyr.json"), "w"), indent=1)
