"""ARUUN - The Reacher. Giraffe-beetle barbarian (approved sheet: tools/source_art/aruun_nerit_sheet.jpg).
Tall dark-bodied warrior, truss-braced long neck, small beetle head with red mask plates and swept branching antlers,
red-and-black spotted wing-case pauldrons and greaves, bone-cream wrappings, tattered olive cloak, psionic spiked mace Morrow.
Run: python3 tools/blender/build_aruun.py   ->   v2/art/models/aruun.glb + aruun.json"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
CHAR = hexc("2c262b"); CHAR2 = hexc("3a3238"); RED = hexc("b02a22"); RED2 = hexc("d4402a"); CREAM = hexc("d8bf94"); OLIVE = hexc("6f7240")
OLIVE2 = hexc("8a8a50"); BROWN = hexc("5a3a2a"); GOLD = hexc("c9a24a"); GLOW = hexc("e03018", 0.75); TAN = hexc("a88a5a"); DEEP = hexc("1c181c")
EYE = hexc("e8502a", 0.8)

lib.reset()
parts = {}
sockets = {}


def spots(p, center, r, n, color, rad, hard=True, seed=1):
    """Dark/red spots on a dome (ladybug markings): small blobs just proud of the surface."""
    import random
    rnd = random.Random(seed)
    for _ in range(n):
        a = rnd.uniform(0, math.tau); b = rnd.uniform(0.2, 1.2)
        d = (math.cos(a) * math.sin(b), math.cos(b), math.sin(a) * math.sin(b))
        pos = (center[0] + d[0] * r[0], center[1] + d[1] * r[1], center[2] + d[2] * r[2])
        p.hard().blob(pos, (rad, rad, rad * 0.5), color, rot=(0, 0, 0), seg=8, ring=6)


# ---------------------------------------------------------------------------------------------- legs
def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.3, z))
    hip = (x0, 1.3, z)
    knee = (x0 + 0.26, 0.74, z + 0.02 * s)
    ankle = (x0 - 0.04, 0.24, z + 0.03 * s)
    toe = (x0 + 0.40, 0.04, z + 0.03 * s)
    p.hard(False).tube([hip, (x0 + 0.14, 1.02, z), knee], (0.19, 0.14), CHAR, sides=10)          # thigh
    p.tube([knee, (x0 + 0.1, 0.5, z + 0.02 * s), ankle], (0.125, 0.075), CHAR, sides=9)          # shin (digitigrade, swept back)
    p.tube([ankle, (x0 + 0.2, 0.08, z + 0.03 * s), toe], (0.085, 0.05), CHAR2, sides=8)           # foot
    p.blob(knee, (0.17, 0.17, 0.17), CHAR, seg=12, ring=8)
    # armour: red knee cap, shin plate, thigh plate
    p.hard().blob((knee[0] + 0.09, knee[1] + 0.02, knee[2] + 0.04 * s), (0.17, 0.2, 0.15), RED, seg=12, ring=8)
    p.hard().blob((x0 + 0.19, 0.92, z + 0.07 * s), (0.1, 0.26, 0.14), RED, rot=(0, 0, -14), seg=10, ring=8)
    p.hard().blob((x0 + 0.1, 0.48, z + 0.05 * s), (0.07, 0.24, 0.1), RED2, rot=(0, 0, 8), seg=10, ring=8)
    for k in range(3):  # cream wraps
        p.hard().ring((x0 + 0.08 + 0.02 * k, 0.58 - 0.11 * k, z + 0.02 * s), 0.095, 0.022, CREAM, rot=(90, 0, 8), seg=10, tseg=4)
    for dz in (-0.05, 0.0, 0.05):   # claws
        p.hard().cone((toe[0], 0.05, toe[2] + dz), (toe[0] + 0.2, 0.01, toe[2] + dz * 1.8), 0.04, 0.0, CREAM, sides=5)
    p.hard().cone((ankle[0] - 0.03, 0.2, ankle[2]), (ankle[0] - 0.22, 0.12, ankle[2]), 0.04, 0.0, CREAM, sides=5)
    spots(p, (x0 + 0.19, 0.92, z + 0.07 * s), (0.1, 0.26, 0.14), 4, DEEP, 0.04, seed=3 if s > 0 else 5)
    o = p.finish(voxel=0.045, smooth_passes=2, target_tris=580)
    parts[name] = o


leg("leg_f", 0.27, 0.06)
leg("leg_b", -0.27, -0.10)

# ---------------------------------------------------------------------------------------------- torso (pelvis, waist, chest, neck)
t = Part("torso", (0, 1.12, 0), dy=0.18)
t.blob((0.0, 1.22, 0), (0.34, 0.24, 0.32), CHAR)                                   # pelvis
t.tube([(0.0, 1.25, 0), (0.04, 1.6, 0), (0.1, 1.85, 0)], (0.27, 0.3), CHAR, sides=12)  # waist
t.blob((0.1, 2.0, 0), (0.38, 0.35, 0.44), CHAR2)                                    # chest
t.tube([(0.1, 2.12, 0), (0.17, 2.4, 0), (0.26, 2.72, 0), (0.38, 3.0, 0), (0.5, 3.22, 0)], (0.15, 0.08), CHAR, sides=10)   # long neck
t.hard().blob((0.3, 2.0, 0), (0.24, 0.3, 0.34), RED, seg=12, ring=8)                 # carapace breastplate
t.hard().blob((0.5, 1.96, 0), (0.1, 0.3, 0.16), CREAM, seg=10, ring=8)              # sternum
for k in range(4):
    t.hard().tube([(0.38, 2.2 - 0.14 * k, -0.34), (0.5, 2.2 - 0.14 * k, 0.0), (0.38, 2.2 - 0.14 * k, 0.34)], 0.028, BROWN, sides=5)   # rib bands
for k, y in enumerate((2.3, 2.5, 2.7, 2.9, 3.08)):     # truss rings along the neck
    f = (y - 2.12) / 1.0
    cx = 0.1 + 0.4 * f
    t.hard().ring((cx + 0.02 * k, y, 0), 0.115 - 0.045 * f, 0.026, CREAM if k % 2 == 0 else TAN, rot=(0, 0, 18 + 12 * f), seg=10, tseg=4)
t.hard().tube([(0.0, 1.32, 0.34), (0.1, 1.3, 0.0), (0.0, 1.32, -0.34)], 0.07, RED, sides=8)          # belt
t.hard().ring((0.05, 1.3, 0), 0.34, 0.05, GOLD, rot=(90, 0, 0), seg=18, tseg=5)
t.hard().blob((0.12, 1.12, 0.3), (0.1, 0.14, 0.08), BROWN)                                          # pouch
t.hard().blob((0.12, 1.1, -0.3), (0.08, 0.16, 0.07), TAN)
for dz in (-0.2, -0.08, 0.08, 0.2):   # loincloth tatters
    t.hard().tube([(0.2, 1.2, dz), (0.3, 0.9, dz * 1.2), (0.28, 0.62, dz * 1.3)], (0.07, 0.03), OLIVE if dz > 0 else OLIVE2, sides=4)
spots(t, (0.3, 2.0, 0), (0.24, 0.3, 0.34), 6, DEEP, 0.045, seed=9)
parts["torso"] = t.finish(voxel=0.05, smooth_passes=2, target_tris=1450)

# ---------------------------------------------------------------------------------------------- head
hp = (0.5, 2.86, 0)
h = Part("head", hp, dy=0.52)
h.blob((0.52, 2.95, 0), (0.25, 0.19, 0.2), CHAR)                                    # skull
h.tube([(0.58, 2.93, 0), (0.78, 2.88, 0), (1.0, 2.8, 0)], (0.15, 0.085), CHAR2, sides=10)   # long snout
h.hard().tube([(0.62, 3.0, 0), (0.86, 2.94, 0), (1.04, 2.85, 0)], (0.11, 0.07), RED, sides=8)   # mask plate (top of snout)
h.hard().blob((0.67, 2.98, 0.14), (0.07, 0.035, 0.05), EYE, rot=(0, 0, 0), seg=8, ring=6)          # glowing eye marks
h.hard().blob((0.67, 2.98, -0.14), (0.07, 0.035, 0.05), EYE, seg=8, ring=6)
h.hard().cone((0.92, 2.78, 0.07), (1.12, 2.66, 0.1), 0.045, 0.0, CREAM, sides=5)  # mandible hooks
h.hard().cone((0.92, 2.78, -0.07), (1.12, 2.66, -0.1), 0.045, 0.0, CREAM, sides=5)
for s in (1, -1):   # antlers: swept back, branching, red
    main = [(0.5, 3.06, 0.09 * s), (0.42, 3.38, 0.2 * s), (0.18, 3.72, 0.3 * s), (-0.14, 3.92, 0.34 * s)]
    h.hard().tube(main, (0.05, 0.016), RED, sides=6)
    for (a, b, c) in ((1, (0.34, 3.52, 0.34 * s), (0.5, 3.74, 0.4 * s)), (2, (0.06, 3.82, 0.4 * s), (0.2, 4.02, 0.44 * s)), (2, (0.0, 3.8, 0.2 * s), (-0.12, 4.12, 0.22 * s))):
        h.hard().tube([main[a], b, c], (0.026, 0.01), RED2, sides=5)
h.hard().tube([(0.44, 3.0, 0.0), (0.2, 3.14, 0.0), (-0.06, 3.1, 0.0)], (0.06, 0.02), OLIVE, sides=5)       # mane
for dz in (-0.12, 0.12):
    h.hard().tube([(0.42, 2.98, dz), (0.2, 3.02, dz * 1.5), (-0.02, 2.92, dz * 1.7)], (0.045, 0.012), OLIVE2, sides=4)
parts["head"] = h.finish(voxel=0.032, smooth_passes=2, target_tris=800)

# ---------------------------------------------------------------------------------------------- arms
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.1, 2.14, z)
    p = Part(name, sh, dy=0.2)
    p.tube([sh, (0.08, 1.85, z + 0.1 * s), (0.12, 1.6, z + 0.12 * s)], (0.155, 0.12), CHAR, sides=10)             # upper arm
    p.tube([(0.12, 1.6, z + 0.12 * s), (0.2, 1.4, z + 0.11 * s), (0.28, 1.2, z + 0.08 * s)], (0.125, 0.09), CHAR2, sides=10)     # forearm
    p.blob((0.3, 1.14, z + 0.08 * s), (0.13, 0.12, 0.12), CHAR2)                                                  # hand
    p.hard().blob((0.06, 2.26, z + 0.1 * s), (0.3, 0.17, 0.27), RED, rot=(0, 0, 0), seg=14, ring=10)
    p.hard().blob((0.0, 2.16, z + 0.16 * s), (0.2, 0.16, 0.2), RED2, seg=10, ring=8)                              # wing-case pauldron
    spots(p, (0.06, 2.26, z + 0.1 * s), (0.3, 0.17, 0.27), 5, DEEP, 0.06, seed=21 if s > 0 else 22)
    p.hard().blob((0.14, 1.66, z + 0.13 * s), (0.15, 0.17, 0.14), RED, seg=10, ring=8)                            # elbow plate
    p.hard().blob((0.24, 1.32, z + 0.1 * s), (0.13, 0.22, 0.14), RED2, rot=(0, 0, 12), seg=10, ring=8)           # bracer
    for k in range(3):
        p.hard().ring((0.15 + 0.02 * k, 1.5 - 0.1 * k, z + 0.12 * s), 0.12, 0.026, CREAM, rot=(90, 0, 10), seg=10, tseg=4)
    for dz in (-0.06, 0.0, 0.06):
        p.hard().cone((0.36, 1.12, z + 0.08 * s + dz), (0.5, 1.02, z + 0.08 * s + dz * 1.5), 0.034, 0.0, CREAM, sides=5)
    parts[name] = p.finish(voxel=0.045, smooth_passes=2, target_tris=600)


arm("arm_f", 0.56)
arm("arm_b", -0.56)

# ---------------------------------------------------------------------------------------------- Morrow, the psionic mace (detachable)
wp = (0.2, 1.18, 0.62)
w = Part("weapon", wp, dy=0.2)
d = (0.78, -0.3, 0.0)
dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
def at(f, off=(0, 0, 0)):
    return (wp[0] + d[0] * f + off[0], wp[1] + d[1] * f + off[1], wp[2] + off[2])
w.hard().tube([at(-0.35), at(0.6), at(1.35)], (0.07, 0.055), BROWN, sides=7)
for k in range(4):
    f = 0.3 + k * 0.28
    w.hard().tube([at(f, (0.0, 0.04, 0.0)), at(f, (0.08, 0.15, 0.06))], (0.03, 0.0), hexc("3a2418"), sides=4)
mc = at(1.65)
w.blob(mc, (0.4, 0.4, 0.4), CHAR)
import itertools
dirs = [(0, 1, 0), (0, -1, 0), (1, 0.2, 0.5), (-1, 0.4, 0.5), (0.3, 0.2, -1), (-0.4, -0.2, -1), (0.9, -0.5, -0.4), (-0.9, -0.5, 0.2), (0.4, 0.9, 0.5), (-0.4, 0.9, -0.5), (0.5, -0.9, 0.4), (-0.6, 0.5, -0.8), (0.9, 0.5, -0.3), (0.1, 0.2, 1)]
for dd in dirs:
    n = math.sqrt(sum(x * x for x in dd)); dd = tuple(x / n for x in dd)
    base = tuple(mc[i] + dd[i] * 0.38 for i in range(3)); tip = tuple(base[i] + dd[i] * 0.22 for i in range(3))
    w.hard().tube([base, tip], (0.08, 0.0), TAN, sides=5)
w.hard().blob((mc[0], mc[1], mc[2] + 0.37), (0.2, 0.2, 0.08), GLOW, seg=10, ring=6)
w.hard().blob((mc[0], mc[1], mc[2] - 0.37), (0.2, 0.2, 0.08), GLOW, seg=10, ring=6)
w.hard().blob((mc[0] + 0.04, mc[1] + 0.04, mc[2] + 0.43), (0.06, 0.06, 0.03), hexc("ffd9c8", 1.0), seg=6, ring=4)
parts["weapon"] = w.finish(voxel=0.04, smooth_passes=1, target_tris=800)

# ---------------------------------------------------------------------------------------------- cloak + hood (lags)
ep = (-0.1, 2.5, 0)
e = Part("extra", ep, dy=0.4)
e.blob((-0.12, 2.6, 0), (0.34, 0.3, 0.52), CHAR, rot=(0, 0, 10))
e.blob((-0.2, 2.2, 0), (0.22, 0.6, 0.55), hexc("45462a"), rot=(0, 0, 8))
for k in range(9):
    z = -0.48 + k * 0.12
    ln = 1.15 - abs(z) * 0.5 + 0.2 * (k % 2)
    e.hard().tube([(-0.2, 2.3, z), (-0.3, 2.3 - ln * 0.5, z), (-0.38, 2.3 - ln, z)], (0.075, 0.03), OLIVE if k % 2 == 0 else OLIVE2, sides=4)
for k in range(3):
    e.hard().tube([(-0.3, 2.4, -0.2 + 0.2 * k), (-0.5, 1.95 - 0.1 * k, -0.2 + 0.2 * k), (-0.55, 1.4, -0.2 + 0.2 * k)], (0.05, 0.02), CREAM, sides=4)
parts["extra"] = e.finish(voxel=0.05, smooth_passes=2, target_tris=380)

# ---------------------------------------------------------------------------------------------- export
def local(part, p):
    pv = parts[part].location
    return [round(p[0] - pv.x, 4), round(p[1] - pv.z, 4), round(p[2] + pv.y, 4)]   # blender->game inverse of V()

sock = {
    "head": ["head", 0.02, 0.09, 0.0],
    "hand": ["arm_f", 0.2, -1.0, 0.08],
    "weapon_tip": ["weapon", round(mc[0] - wp[0] + 0.4, 4), round(mc[1] - wp[1], 4), round(mc[2] - wp[2], 4)],
    "weapon_base": ["weapon", round(d[0] * 0.3, 4), round(d[1] * 0.3, 4), 0.0],
}
meta = {"sockets": sock, "face": {"center": [0.02, 0.09, 0.0], "radii": [0.27, 0.2, 0.21], "half_lon": 1.0, "half_lat": 0.7, "lat_center": 0.1, "e": 0.9}}
total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.export(os.path.join(OUT, "aruun.glb"))
json.dump(meta, open(os.path.join(OUT, "aruun.json"), "w"), indent=1)
