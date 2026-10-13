"""CIGARRA - the Oracle Hopper (v2 design: the sheet is inspiration only). A bright, clever treehopper witch: big glossy yellow eyes, wild white
leaf-tipped hair, a black branching crown whose six spheres are the swarm (stay procedural), an oversized hooded purple jacket with a lime lining,
puffy baggy trousers with cuffs, leafy green boots, bandaged forearms, belt charms and a pair of big translucent leaf wings.
Pivots/sockets match the rig. Run: python3 tools/blender/build_cigarra.py -> v2/art/models/cigarra.glb + .json"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur, brow, mouth, pauldron, bracer, rivets

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
PURPLE = hexc("4a3a68"); PURPLE2 = hexc("362a50"); PURPLE3 = hexc("66548a"); LIME = hexc("b4d640"); LIME2 = hexc("d4ec62"); SKIN = hexc("eebb92")
HAIR = hexc("f4efdf"); HAIR2 = hexc("dcd5bc"); BOOT = hexc("3e4a22"); OLIVE = hexc("8a9e3c"); ORANGE = hexc("f09040"); BLACK = hexc("1a1520")
GOLD = hexc("ffd84a", 0.7); CREAM = hexc("eee6cc"); WING = hexc("b8d84c"); WING2 = hexc("8cb030"); VEIN = hexc("eaf8a0", 0.4); BLUSH = hexc("f08a7a")
lib.reset()
parts = {}

def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.2, z))
    p.tube([(x0, 1.2, z), (x0 + 0.04, 0.92, z), (x0 + 0.06, 0.62, z)], (0.24, 0.2), PURPLE, sides=14)          # puffy trouser
    p.blob((x0 + 0.1, 0.98, z), (0.17, 0.2, 0.24), PURPLE2, seg=12, ring=8)                                      # cargo pocket
    p.hard().ring((x0 + 0.06, 0.6, z), 0.2, 0.05, PURPLE3, rot=(90, 0, 0), seg=14, tseg=4)                                       # cuff
    p.tube([(x0 + 0.05, 0.58, z), (x0 + 0.03, 0.22, z)], (0.1, 0.085), CREAM, sides=10)                          # sock
    for k in range(3):
        p.hard().ring((x0 + 0.045, 0.5 - 0.09 * k, z), 0.095, 0.02, OLIVE, rot=(90, 0, 0), seg=10, tseg=3)
    p.blob((x0 + 0.14, 0.12, z), (0.36, 0.16, 0.21), BOOT, e=0.8, seg=12, ring=8)                                 # boot
    p.hard().blob((x0 + 0.38, 0.1, z), (0.1, 0.09, 0.12), hexc("2c3818"), e=0.8, seg=8, ring=6)
    p.hard().tube([(x0 + 0.02, 0.24, z + 0.07 * s), (x0 - 0.1, 0.24, z + 0.11 * s), (x0 - 0.2, 0.18, z + 0.13 * s)], ((0.06, 0.012), (0.06, 0.012), (0.0, 0.01)), OLIVE, wide=(0, 0, 1), sides=4)
    parts[name] = p.finish(voxel=0.04, smooth_passes=3, target_tris=800)

leg("leg_f", 0.2, 0.0)
leg("leg_b", -0.2, -0.04)

t = Part("torso", (0, 1.0, 0), dy=0.2)
t.blob((0.0, 1.06, 0), (0.3, 0.22, 0.32), PURPLE)
t.tube([(0.0, 1.1, 0), (0.03, 1.4, 0), (0.04, 1.66, 0)], (0.2, 0.22), SKIN, sides=14)
t.blob((0.05, 1.76, 0), (0.24, 0.22, 0.28), CREAM)
t.hard().blob((0.0, 1.76, 0), (0.28, 0.24, 0.34), PURPLE2, e=0.85, seg=14, ring=9)                              # open jacket
t.hard().ring((0.0, 1.14, 0), 0.29, 0.05, ORANGE, rot=(90, 0, 0), seg=18, tseg=5)                                              # belt
for (pos, col, rr, hh) in (((0.28, 1.02, 0.22), CREAM, 0.08, 0.11), ((0.22, 1.0, -0.24), hexc("f6c880"), 0.07, 0.1), ((0.1, 1.02, 0.3), OLIVE, 0.06, 0.08)):
    t.hard().tube([(pos[0], pos[1] + 0.12, pos[2]), pos], 0.012, ORANGE, sides=3)
    t.hard().blob((pos[0], pos[1] - hh * 0.8, pos[2]), (rr, hh, rr * 0.85), col, seg=9, ring=7)                 # skull / egg charms
    eye(t, (pos[0] + rr * 0.55, pos[1] - hh * 0.6, pos[2]), rr * 0.3, "1a1520", white="1a1520", look=(1, 0, 0))
for sg in (-1, 1):
    t.hard().blob((0.02, 1.9, 0.36 * sg), (0.14, 0.09, 0.14), PURPLE3, e=0.8, seg=10, ring=7)               # shoulder cap
    t.hard().ring((0.02, 1.84, 0.36 * sg), 0.13, 0.02, GOLD, rot=(90, 0, 0), seg=12, tseg=4)
t.hard().blob((0.3, 1.5, 0), (0.05, 0.1, 0.1), LIME, e=0.8, seg=8, ring=6)                              # leaf brooch
t.hard().ring((0.33, 1.5, 0), 0.08, 0.016, GOLD, rot=(0, 90, 0), seg=10, tseg=3)
t.hard().blob((0.0, 1.06, -0.3), (0.12, 0.14, 0.09), ORANGE, e=0.8, seg=8, ring=6)                      # belt pouch
t.hard().tube([(0.3, 1.9, -0.25), (0.36, 1.45, 0.0), (0.28, 1.1, 0.26)], 0.04, ORANGE, sides=5)         # strap
t.hard().blob((0.0, 2.0, 0), (0.34, 0.2, 0.44), PURPLE2, e=0.85, seg=14, ring=9)                                # oversized hood collar
t.hard().ring((0.08, 2.1, 0), 0.34, 0.035, LIME, rot=(90, 0, 0), seg=16, tseg=4)                                                # lime lining
t.tube([(0.04, 1.82, 0), (0.07, 2.0, 0)], 0.08, SKIN, sides=10)
parts["torso"] = t.finish(voxel=0.035, smooth_passes=3, target_tris=1500)

hp = (0.08, 1.9, 0)
HS = 1.55
h = Part("head", hp, dy=0.34, sc=HS)
h.blob((0.12, 2.1, 0), (0.24, 0.26, 0.23), SKIN)                                                              # big head
eye(h, (0.28, 2.12, 0.11), 0.125, "e8e060", white="fffbe8", look=(1, 0, 0.35), glow=0.4, ps=1.3, lid="eebb92", ring_c="3a2a5a")
eye(h, (0.28, 2.12, -0.11), 0.11, "e8e060", white="fffbe8", look=(1, 0, -0.35), glow=0.4, ps=0.65, lid="eebb92", ring_c="3a2a5a")   # mismatched pupils
h.hard().blob((0.35, 2.05, 0.0), (0.045, 0.04, 0.04), hexc("e0a080"), seg=6, ring=5)                      # little nose
for sg in (-1, 1):
    h.hard().blob((0.2, 1.96, 0.2 * sg), (0.07, 0.04, 0.05), hexc("f0a090"), seg=6, ring=5)               # cheeks
for sg in (-1, 1):
    brow(h, (0.3, 2.26, 0.1 * sg), 0.14, 0.04, "3a2a5a", th=0.028, look=(1, 0, 0.35 * sg))
mouth(h, (0.33, 1.95, 0), 0.17, 0.05, "5a2030", look=(1, 0, 0), th=0.022, teeth=3, tooth="fffbe8", tongue="e06a7a")
h.hard().blob((0.34, 2.0, 0.0), (0.03, 0.025, 0.05), hexc("c8705a"), seg=6, ring=4)                           # tiny nose/mouth
h.hard().blob((0.28, 2.02, 0.17), (0.04, 0.03, 0.05), BLUSH, seg=6, ring=4)
h.hard().blob((0.28, 2.02, -0.17), (0.04, 0.03, 0.05), BLUSH, seg=6, ring=4)
h.hard().blob((0.3, 2.28, 0), (0.035, 0.07, 0.04), GOLD, rot=(0, 0, 20), seg=6, ring=5)                       # forehead gem
h.blob((0.04, 2.24, 0), (0.28, 0.22, 0.3), HAIR, rot=(0, 0, 14))                                              # hair mass
fur(h, (0.0, 2.24, 0), (0.27, 0.22, 0.29), HAIR, n=100, ln=0.2, flow=(-0.7, -0.5, 0), seed=5, width=0.06, skip_below=0.25)
fur(h, (-0.06, 2.1, 0), (0.22, 0.25, 0.3), HAIR2, n=60, ln=0.2, flow=(-0.4, -0.9, 0), seed=9, width=0.06, skip_below=-0.9, spread=(0.4, 1.0, 1.0))
for k in range(8):    # lime-tipped leaf strands (sides and back only)
    az = (-2.6 + 5.2 * k / 7) * 0.5 + (0.9 if k >= 4 else -0.9) * 0
    base = (0.02, 2.3, 0.22 * math.sin(az))
    h.hard().mat(0, 1).tube([base, (base[0] - 0.14, base[1] + 0.06, base[2] * 1.4), (base[0] - 0.3, base[1] - 0.18, base[2] * 1.6), (base[0] - 0.34, base[1] - 0.34, base[2] * 1.7)], ((0.0, 0.01), (0.07, 0.012), (0.06, 0.012), (0.0, 0.01)), LIME if k % 2 else HAIR2, wide=(0, 0, 1) if k % 2 == 0 else (1, 0, 0), sides=4)
for sd in (-1, 1):
    h.hard().tube([(0.1, 2.06, 0.22 * sd), (0.0, 2.14, 0.4 * sd), (-0.12, 2.24, 0.56 * sd)], ((0.07, 0.014), (0.06, 0.014), (0.0, 0.01)), LIME, wide=(0, 1, 0), sides=4)   # leaf ears
tw = (0.1, 2.5, 0)
h.hard().tube([tw, (0.1, 2.62, 0), (0.1, 2.72, 0)], (0.05, 0.035), BLACK, sides=7)
branches = [((0.1, 0.5, 0.3), (0.2, 0.62, 0.55)), ((-0.05, 0.55, 0.12), (0.0, 0.8, 0.1)), ((0.1, 0.5, -0.3), (0.2, 0.66, -0.58)),
            ((-0.2, 0.42, 0.28), (-0.36, 0.5, 0.45)), ((-0.2, 0.42, -0.28), (-0.36, 0.54, -0.5)), ((0.3, 0.8, 0.3), (0.35, 0.98, 0.22))]
rest = []
base = (tw[0], tw[1] + 0.2, tw[2])
for (a, b) in branches:
    pa = (tw[0] + a[0] * 0.55, tw[1] + a[1] * 0.55, tw[2] + a[2] * 0.55)
    pb = (tw[0] + b[0] * 0.55, tw[1] + b[1] * 0.55, tw[2] + b[2] * 0.55)
    h.hard().tube([base, pa, pb], (0.03, 0.016), BLACK, sides=5)
    rest.append(pb)
parts["head"] = h.finish(voxel=0.028, smooth_passes=3, target_tris=1900)

def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (0.0, 1.72, z), dy=0.26)
    p.blob((0.0, 1.62, z + 0.02 * s), (0.2, 0.22, 0.2), PURPLE3)
    p.tube([(0.02, 1.5, z + 0.03 * s), (0.08, 1.3, z + 0.05 * s)], (0.1, 0.085), CREAM, sides=10)
    p.hard().ring((0.05, 1.44, z + 0.04 * s), 0.1, 0.028, PURPLE3, rot=(90, 0, 12), seg=10, tseg=4)
    p.blob((0.14, 1.2, z + 0.06 * s), (0.14, 0.16, 0.12), SKIN)
    for dz in (-0.04, 0.0, 0.04):
        p.hard().tube([(0.2, 1.14, z + 0.06 * s + dz * 1.3), (0.31, 1.03, z + 0.07 * s + dz * 1.9)], (0.04, 0.008), SKIN, sides=5)
    parts[name] = p.finish(voxel=0.032, smooth_passes=3, target_tris=650)

arm("arm_f", 0.4)
arm("arm_b", -0.4)

# big translucent leaf wings (glass material in Godot): two layers each side
e = Part("extra", (-0.05, 1.8, 0), dy=0.3)
for sd in (-1, 1):
    for layer, (ln, wd, y0, col) in enumerate(((1.15, 0.34, 1.75, WING), (0.95, 0.3, 1.55, WING2))):
        for k in range(3):
            ang = -18 + 22 * k
            ctr = (-0.2 - 0.1 * layer, y0 - ln * 0.45 + 0.06 * k, (0.2 + 0.32 * k + 0.1 * layer) * sd)
            e.hard().blob(ctr, (0.012, ln * 0.5 - 0.06 * k, wd * 0.5), col, rot=(sd * (10 + 8 * k), 0, ang), seg=10, ring=8)
            e.hard().tube([(ctr[0] + 0.015, ctr[1] + ln * 0.3, ctr[2]), (ctr[0] + 0.015, ctr[1] - ln * 0.3, ctr[2])], 0.01, VEIN, sides=3, caps=False)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=900)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "cigarra.glb"))
tw_local = [(tw[0] - hp[0]) * HS, (tw[1] - hp[1]) * HS, tw[2] * HS]
meta = {"sockets": {"head": ["head", 0.04 * HS, 0.2 * HS, 0.0], "crown": ["head", tw_local[0], tw_local[1], 0.0], "hand": ["arm_f", 0.16, -0.58, 0.06], "weapon_base": ["arm_f", 0.16, -0.58, 0.06], "weapon_tip": ["arm_f", 0.3, -0.76, 0.07]},
        "face_off": True,
        "swarm_pos": [hp[0] + tw_local[0], hp[1] + 0.34 + tw_local[1], 0.0],
        "swarm_rest": [[round((r[0] - tw[0]) * HS, 4), round((r[1] - tw[1]) * HS, 4), round((r[2] - tw[2]) * HS, 4)] for r in rest]}
json.dump(meta, open(os.path.join(OUT, "cigarra.json"), "w"), indent=1)
