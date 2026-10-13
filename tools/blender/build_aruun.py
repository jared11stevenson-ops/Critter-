"""ARUUN - the Reacher (v3, built from the sheet tools/source_art/aruun_nerit_sheet.jpg).
A towering giraffe-beetle barbarian: a long, noble horse/giraffe muzzle on a long strong neck, a big hooked rhino-beetle horn plus two swept brow horns,
a cream mane down the back of the neck, a dark muscular body wearing red-orange chitin armour (round black-spotted shoulder shells, segmented breastplate,
bracers, greaves), an olive tattered cloth skirt and cape, and Morrow, the psionic spiked mace with a glowing red core.
Pivots/sockets match the rig. Run: python3 tools/blender/build_aruun.py -> v2/art/models/aruun.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur, brow, mouth, rivets

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
CHAR = hexc("2c2733"); CHAR2 = hexc("3d3643"); CHAR3 = hexc("1d1a22")
RED = hexc("b02c1c"); RED2 = hexc("d44a1c"); DRED = hexc("45120e"); ORANGE = hexc("f08a2a"); CREAM = hexc("efe1ba"); CREAM2 = hexc("cfb98c")
OLIVE = hexc("6f7b3b"); OLIVE2 = hexc("8d8c4a"); BROWN = hexc("5e3b28"); GOLD = hexc("dcae45"); BLACK = hexc("14111a"); GLOWC = hexc("ff4a28", 1.0)
BONE = hexc("efe4c8"); AMBER = "ffb02e"
lib.reset()
parts = {}


def spot(p, c, r, axis, color=BLACK):
    """Round shell spot: a thin disc on the surface; axis = 'x' (faces front/back), 'z' (faces the sides), 'y' (faces up)."""
    rad = {"x": (0.03, r, r), "z": (r, r, 0.03), "y": (r, 0.03, r)}[axis]
    p.hard().blob(c, rad, color, seg=10, ring=6)


def plate(p, c, rad, color, trim=None, rot=(0, 0, 0), spots=()):
    """A chunky armour plate with an optional gold trim rim."""
    p.hard().blob(c, rad, color, rot=rot, e=0.75, seg=12, ring=8)


# ------------------------------------------------------------------------------------------------ legs (digitigrade; hips y = 1.3)
def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.3, z))
    hip = (x0, 1.3, z); knee = (x0 + 0.28, 0.78, z + 0.02 * s); ank = (x0 - 0.06, 0.26, z + 0.03 * s); toe = (x0 + 0.44, 0.06, z + 0.03 * s)
    p.tube([hip, (x0 + 0.15, 1.04, z), knee], (0.27, 0.19), CHAR, sides=14)
    p.tube([knee, (x0 + 0.1, 0.5, z), ank], (0.18, 0.1), CHAR2, sides=12)
    p.tube([ank, (x0 + 0.2, 0.1, z + 0.03 * s), toe], (0.12, 0.08), CHAR3, sides=10)
    p.blob(knee, (0.22, 0.22, 0.22), CHAR)
    p.hard().blob((knee[0] + 0.13, knee[1] + 0.02, knee[2] + 0.04 * s), (0.22, 0.24, 0.2), RED, e=0.8, seg=12, ring=9)          # knee cop
    spot(p, (knee[0] + 0.15, knee[1] + 0.05, knee[2] + 0.24 * s), 0.07, "z")
    p.hard().blob((x0 + 0.22, 1.0, z + 0.1 * s), (0.15, 0.36, 0.21), CHAR2, rot=(0, 0, -14), e=0.8, seg=12, ring=9)             # thigh guard
    spot(p, (x0 + 0.2, 1.05, z + 0.3 * s), 0.08, "z")
    p.hard().blob((x0 + 0.1, 0.5, z + 0.07 * s), (0.11, 0.32, 0.15), CHAR2, rot=(0, 0, 8), e=0.8, seg=10, ring=8)                 # greave
    p.hard().ring((x0 + 0.03, 0.34, z), 0.13, 0.035, BONE, rot=(90, 0, 0), seg=10, tseg=4)
    p.blob((x0 + 0.2, 0.1, z + 0.03 * s), (0.34, 0.12, 0.23), CHAR3)                                                         # fat foot pad
    for dz in (-0.09, 0.0, 0.09):
        p.hard().tube([(toe[0], 0.07, toe[2] + dz * 1.3), (toe[0] + 0.26, 0.03, toe[2] + dz * 2.0)], (0.075, 0.01), CREAM, sides=5)  # toe claws
    p.hard().tube([(ank[0] - 0.03, 0.22, ank[2]), (ank[0] - 0.24, 0.13, ank[2])], (0.06, 0.0), CREAM, sides=4)                  # heel spur
    parts[name] = p.finish(voxel=0.04, smooth_passes=3, target_tris=1000)

leg("leg_f", 0.27, 0.06)
leg("leg_b", -0.27, -0.10)

# ------------------------------------------------------------------------------------------------ torso: pelvis, ribbed waist, big chest, long neck (+ mane, breastplate, belt, kilt)
t = Part("torso", (0, 1.12, 0), dy=0.18)
t.blob((0.0, 1.22, 0), (0.4, 0.28, 0.38), CHAR)                                            # pelvis
t.tube([(0.0, 1.25, 0), (0.04, 1.62, 0), (0.1, 1.9, 0)], (0.3, 0.36), CHAR, sides=14)       # waist
t.blob((0.1, 2.02, 0), (0.5, 0.42, 0.56), CHAR2)                                           # chest
t.tube([(0.1, 2.15, 0), (0.2, 2.5, 0), (0.32, 2.85, 0), (0.46, 3.12, 0), (0.56, 3.3, 0)], (0.23, 0.14), CHAR, sides=14)   # long strong neck
# segmented red-orange breastplate: centre keel + pec plates + three abdominal bands
t.hard().blob((0.36, 2.0, 0), (0.28, 0.34, 0.44), CHAR3, e=0.8)                             # dark under-plate
for sg in (-1, 1):
    t.hard().blob((0.5, 2.1, 0.23 * sg), (0.14, 0.22, 0.22), DRED, rot=(0, 0, -6), e=0.8, seg=12, ring=9)   # pec plates
    t.hard().ring((0.62, 2.1, 0.23 * sg), 0.18, 0.026, GOLD, rot=(0, 90, 0), seg=14, tseg=4)
for k in range(3):
    t.hard().blob((0.44 - 0.01 * k, 1.78 - 0.17 * k, 0), (0.1, 0.07, 0.3 - 0.03 * k), DRED if k % 2 == 0 else RED, e=0.8, seg=10, ring=7)   # abs bands
t.hard().blob((0.62, 2.04, 0), (0.05, 0.12, 0.1), GOLD, e=0.8)                              # beetle emblem keel
t.hard().ring((0.68, 2.04, 0), 0.08, 0.018, BLACK, rot=(0, 90, 0), seg=10, tseg=3)
# neck armour collars (red-orange chitin bands, widest at the base) + cream mane running up the back of the neck
for k, y in enumerate((2.3, 2.52, 2.74, 2.96, 3.16)):
    f = (y - 2.15) / 1.15
    cx = 0.1 + 0.46 * f + 0.0
    t.hard().ring((cx, y, 0), 0.22 - 0.07 * f, 0.034, ORANGE if k % 2 == 0 else DRED, rot=(90, 0, 0), seg=14, tseg=4)
for k, y in enumerate((2.3, 2.55, 2.8, 3.05, 3.25)):
    f = (y - 2.15) / 1.15
    fur(t, (0.1 + 0.46 * f - 0.14, y, 0), (0.12, 0.2, 0.2), CREAM if k % 2 == 0 else CREAM2, n=5, ln=0.2, flow=(-0.8, -0.6, 0), seed=11 + k, width=0.08, skip_below=-0.1)   # mane
fur(t, (0.2, 2.25, 0), (0.36, 0.2, 0.5), CREAM, n=60, ln=0.2, flow=(-0.3, -0.8, 0), seed=3, width=0.07, skip_below=-0.2)    # fur ruff at the shoulders
# belt, buckle, skull charm, pouch
t.hard().tube([(0.0, 1.38, 0.4), (0.12, 1.34, 0.0), (0.0, 1.38, -0.4)], 0.08, DRED, sides=7)
t.hard().ring((0.05, 1.36, 0), 0.4, 0.065, BROWN, rot=(90, 0, 0), seg=18, tseg=5)
t.hard().blob((0.28, 1.34, 0.0), (0.08, 0.11, 0.11), GOLD, e=0.8)
t.hard().blob((0.2, 1.16, 0.36), (0.1, 0.18, 0.08), BONE)
t.hard().blob((0.0, 1.2, -0.38), (0.14, 0.18, 0.1), BROWN, e=0.8, seg=8, ring=6)
t.hard().tube([(0.36, 2.55, -0.32), (0.52, 1.95, 0.0), (0.3, 1.45, 0.3)], 0.055, BROWN, sides=6)   # bandolier
t.hard().blob((0.5, 1.95, 0.0), (0.05, 0.08, 0.08), GOLD)
for k, dz in enumerate((-0.32, -0.17, 0.0, 0.17, 0.32)):                                          # kilt tatters
    t.hard().mat(0, 1).tube([(0.25, 1.3, dz), (0.35, 0.95, dz * 1.2), (0.31, 0.66 - 0.06 * (k % 2), dz * 1.3)], ((0.11, 0.012), (0.11, 0.012), (0.01, 0.01)), OLIVE if k % 2 == 0 else OLIVE2, wide=(0, 0, 1), sides=4)
parts["torso"] = t.finish(voxel=0.04, smooth_passes=3, target_tris=2800)

# ------------------------------------------------------------------------------------------------ head: long noble muzzle, stern amber eyes, hooked horn, mane
hp = (0.5, 2.86, 0)
HS = 1.45
h = Part("head", hp, dy=0.54, sc=HS)
h.blob((0.54, 2.95, 0), (0.3, 0.27, 0.28), CHAR2)                                           # cranium
h.tube([(0.62, 2.9, 0), (0.88, 2.8, 0), (1.12, 2.7, 0)], (0.26, 0.18), CHAR, sides=12)       # long tapering muzzle
h.hard().blob((0.9, 2.88, 0), (0.3, 0.06, 0.17), DRED, rot=(0, 0, -11), e=0.8, seg=12, ring=7)    # armoured upper muzzle plate
h.hard().blob((1.2, 2.72, 0), (0.1, 0.1, 0.14), BLACK, seg=10, ring=7)                    # nose pad
h.hard().blob((0.88, 2.6, 0), (0.28, 0.07, 0.15), CHAR3, rot=(0, 0, -9), e=0.8, seg=10, ring=6)  # lower jaw
for sg in (-1, 1):
    h.hard().blob((1.28, 2.74, 0.06 * sg), (0.03, 0.03, 0.025), CHAR3, seg=6, ring=4)         # nostrils
    # eyes: big, amber, set toward the sides of the skull, heavy red brow plate above each
    eye(h, (0.66, 3.0, 0.2 * sg), 0.145, AMBER, look=(0.55, 0.0, 0.85 * sg), glow=0.8, ps=0.85, lid="3d3643", ring_c="14111a")
    h.hard().blob((0.68, 3.14, 0.19 * sg), (0.17, 0.06, 0.1), DRED, rot=(sg * 14, 0, -8), e=0.8, seg=10, ring=7)   # brow plate
    h.hard().blob((0.6, 2.8, 0.27 * sg), (0.17, 0.12, 0.05), RED2, rot=(0, 15 * sg, 0), e=0.8, seg=10, ring=7)     # cheek plate
    spot(h, (0.58, 2.82, 0.31 * sg), 0.045, "z")
    h.hard().tube([(0.5, 3.14, 0.15 * sg), (0.28, 3.42, 0.22 * sg), (0.06, 3.56, 0.26 * sg)], (0.055, 0.008), DRED, sides=5)    # swept brow horns
    h.hard().tube([(0.94, 2.64, 0.1 * sg), (1.1, 2.46, 0.14 * sg)], (0.07, 0.0), CREAM, sides=5)                  # small tusks
mouth(h, (0.9, 2.64, 0), 0.4, 0.02, "14111a", th=0.022, look=(1, 0, 0))                     # closed stern mouth (a line along the jaw)
# the big hooked rhino-beetle horn rising from the forehead and curling forward, with a short fork
h.hard().tube([(0.66, 3.1, 0), (0.62, 3.42, 0), (0.78, 3.78, 0), (1.1, 3.96, 0), (1.3, 3.84, 0)], (0.1, 0.022), RED, sides=9)
h.hard().tube([(0.78, 3.78, 0), (0.98, 4.02, 0.0)], (0.05, 0.01), RED2, sides=6)
for k, (px, py) in enumerate(((0.63, 3.2), (0.64, 3.36), (0.7, 3.56))):
    h.hard().ring((px, py, 0), 0.115 - 0.02 * k, 0.018, ORANGE, rot=(90, 0, 0), seg=10, tseg=3)   # growth rings on the horn
fur(h, (0.4, 3.0, 0), (0.24, 0.2, 0.26), CREAM, n=30, ln=0.18, flow=(-0.7, -0.4, 0), seed=7, width=0.06, skip_below=-0.1)   # mane at the back of the head
parts["head"] = h.finish(voxel=0.03, smooth_passes=3, target_tris=2000)

# ------------------------------------------------------------------------------------------------ arms: thick dark arms, round spotted shoulder shells, bracers, big claw hands
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.1, 2.14, z)
    p = Part(name, sh, dy=0.2)
    el = (0.12, 1.6, z + 0.12 * s); hand = (0.3, 1.14, z + 0.08 * s)
    p.tube([sh, (0.08, 1.85, z + 0.1 * s), el], (0.22, 0.17), CHAR, sides=12)
    p.tube([el, (0.2, 1.4, z + 0.11 * s), hand], (0.17, 0.12), CHAR2, sides=12)
    p.blob(sh, (0.23, 0.23, 0.23), CHAR)
    p.blob(el, (0.18, 0.18, 0.18), CHAR)
    # round shoulder shell (a wing-case piece) with black spots, gold rim, a short spike
    p.hard().blob((0.06, 2.3, z + 0.14 * s), (0.28, 0.22, 0.27), RED, e=0.9, seg=14, ring=10)
    p.hard().ring((0.06, 2.14, z + 0.14 * s), 0.25, 0.03, GOLD, rot=(90, 0, 0), seg=14, tseg=4)
    for (dx, dy, dz, r) in ((0.0, 0.18, 0.28, 0.07), (0.16, 0.08, 0.26, 0.055), (-0.14, 0.04, 0.27, 0.06)):
        spot(p, (0.06 + dx, 2.3 + dy, z + 0.14 * s + dz * s), r, "z")
    p.hard().tube([(0.06, 2.46, z + 0.14 * s), (0.04, 2.62, z + 0.16 * s)], (0.07, 0.0), CREAM, sides=5)
    p.hard().blob((0.14, 1.66, z + 0.16 * s), (0.2, 0.2, 0.19), RED, e=0.8, seg=10, ring=8)           # elbow guard
    p.hard().blob((0.24, 1.34, z + 0.12 * s), (0.17, 0.25, 0.19), CHAR2, rot=(0, 0, 12), e=0.8, seg=12, ring=9)   # bracer
    p.hard().ring((0.17, 1.52, z + 0.12 * s), 0.15, 0.032, BONE, rot=(90, 0, 10), seg=10, tseg=4)
    p.blob(hand, (0.25, 0.24, 0.23), CHAR2)                                                         # fist
    for dz in (-0.08, 0.0, 0.08):
        p.hard().tube([(0.42, 1.1, z + 0.08 * s + dz * 1.3), (0.58, 0.98, z + 0.08 * s + dz * 1.9)], (0.07, 0.01), CREAM, sides=5)   # claws
    parts[name] = p.finish(voxel=0.038, smooth_passes=3, target_tris=1500)

arm("arm_f", 0.58)
arm("arm_b", -0.58)

# ------------------------------------------------------------------------------------------------ Morrow, the psionic mace
wp = (0.2, 1.18, 0.62)
w = Part("weapon", wp, dy=0.2)
d = (0.78, -0.3, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
def at(f, off=(0, 0, 0)):
    return (wp[0] + d[0] * f + off[0], wp[1] + d[1] * f + off[1], wp[2] + off[2])
w.hard().tube([at(-0.35), at(0.6), at(1.4)], (0.1, 0.085), BROWN, sides=8)
w.hard().blob(at(-0.4), (0.13, 0.13, 0.13), GOLD)
w.hard().blob(at(1.35), (0.16, 0.16, 0.16), GOLD)
for k in range(4):
    w.hard().ring(at(0.25 + k * 0.3), 0.105, 0.02, GOLD, rot=(0, 73, 0), seg=8, tseg=3)
mc = at(1.7)
w.blob(mc, (0.42, 0.42, 0.42), CHAR)
for k in range(14):   # spikes on a fibonacci sphere
    yy = 1 - 2 * (k + 0.5) / 14; rr_ = math.sqrt(1 - yy * yy); a = k * 2.399
    dd = (math.cos(a) * rr_, yy, math.sin(a) * rr_)
    base = tuple(mc[i] + dd[i] * 0.4 for i in range(3)); tip = tuple(base[i] + dd[i] * 0.24 for i in range(3))
    w.hard().tube([base, tip], (0.085, 0.0), CREAM2, sides=5)
w.hard().blob((mc[0], mc[1], mc[2] + 0.39), (0.22, 0.22, 0.09), GLOWC, seg=10, ring=7)
w.hard().blob((mc[0], mc[1], mc[2] - 0.39), (0.22, 0.22, 0.09), GLOWC, seg=10, ring=7)
w.hard().ring((mc[0], mc[1], mc[2] + 0.4), 0.27, 0.025, GOLD, seg=14, tseg=3)
parts["weapon"] = w.finish(voxel=0.04, smooth_passes=1, target_tris=950)

# ------------------------------------------------------------------------------------------------ back: tucked wing-case shell + olive tattered cape (the "extra" part lags like a cape)
ep = (-0.1, 2.5, 0)
e = Part("extra", ep, dy=0.4)
for sd in (-1, 1):
    e.blob((-0.32, 2.3, 0.27 * sd), (0.22, 0.7, 0.27), RED, rot=(0, 0, 8), e=0.85, seg=14, ring=10)
    for (yy, zz, rr_) in ((2.6, 0.17, 0.09), (2.25, 0.36, 0.11), (1.95, 0.2, 0.09), (1.72, 0.4, 0.07)):
        e.hard().blob((-0.54, yy, (zz + 0.03) * sd), (0.03, rr_, rr_), BLACK, seg=8, ring=6)
    e.hard().blob((-0.3, 1.55, 0.3 * sd), (0.2, 0.2, 0.26), DRED, e=0.85, seg=10, ring=7)
e.hard().tube([(-0.5, 3.0, 0), (-0.5, 1.45, 0)], 0.02, BLACK, sides=4)
e.blob((-0.18, 2.85, 0), (0.2, 0.2, 0.46), CHAR3)
for k in range(8):
    z = -0.46 + k * 0.132
    e.hard().mat(0, 1).tube([(-0.24, 1.7, z), (-0.3, 1.3, z), (-0.34, 0.8 + 0.08 * (k % 2), z)], ((0.1, 0.012), (0.1, 0.012), (0.01, 0.01)), OLIVE if k % 2 == 0 else OLIVE2, wide=(0, 0, 1), sides=4)
parts["extra"] = e.finish(voxel=0.04, smooth_passes=3, target_tris=1500)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "aruun.glb"))
mtip = [round(mc[0] - wp[0] + 0.42, 4), round(mc[1] - wp[1], 4), round(mc[2] - wp[2], 4)]
meta = {"sockets": {"head": ["head", 0.02 * HS, 0.09 * HS, 0.0], "hand": ["arm_f", 0.2, -1.0, 0.08], "weapon_tip": ["weapon"] + mtip, "weapon_base": ["weapon", round(d[0] * 0.3, 4), round(d[1] * 0.3, 4), 0.0]},
        "face_off": True}
json.dump(meta, open(os.path.join(OUT, "aruun.json"), "w"), indent=1)
