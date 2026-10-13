"""ARUUN - the Reacher (v2 design, built from what we have; the old sheet is inspiration only). A towering, friendly-fierce giraffe-beetle brute:
glossy red wing-case shell on his back (black-spotted, split like a ladybug), a long strong neck with a cream fur ruff, a small broad beetle head
with big warm orange eyes, a heavy forked rhino-beetle horn and two short brow horns, thick charcoal arms and legs with chunky red armour, a
belt with a bone charm, a tattered cloth kilt and Morrow, the spiked psionic mace with a glowing red core.
Pivots/sockets match the rig. Run: python3 tools/blender/build_aruun.py -> v2/art/models/aruun.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur, brow, mouth, pauldron, bracer, rivets

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
CHAR = hexc("34303c"); CHAR2 = hexc("45414f"); CHAR3 = hexc("26232d"); RED = hexc("b8302a"); RED2 = hexc("e24a30"); DRED = hexc("8c1c1c"); CREAM = hexc("e8d6ad"); CREAM2 = hexc("cdb78a")
OLIVE = hexc("707a42"); BROWN = hexc("5e3e2c"); GOLD = hexc("c99a3e"); BLACK = hexc("17141a"); GLOWC = hexc("ff4a28", 1.0); ORANGE = hexc("ffa030", 0.6); BONE = hexc("efe4c8")
lib.reset()
parts = {}
rnd = random.Random(21)

# ------------------------------------------------------------------------------------------------ legs (hips y = 1.3)
def leg(name, z, x0):
    s = 1.0 if z > 0 else -1.0
    p = Part(name, (x0, 1.3, z))
    hip = (x0, 1.3, z); knee = (x0 + 0.26, 0.76, z + 0.02 * s); ank = (x0 - 0.04, 0.26, z + 0.03 * s); toe = (x0 + 0.42, 0.06, z + 0.03 * s)
    p.tube([hip, (x0 + 0.14, 1.02, z), knee], (0.25, 0.18), CHAR, sides=14)
    p.tube([knee, (x0 + 0.1, 0.5, z), ank], (0.17, 0.095), CHAR2, sides=12)
    p.tube([ank, (x0 + 0.2, 0.1, z + 0.03 * s), toe], (0.11, 0.07), CHAR3, sides=10)
    p.blob(knee, (0.2, 0.2, 0.2), CHAR)
    p.hard().blob((knee[0] + 0.12, knee[1] + 0.02, knee[2] + 0.04 * s), (0.2, 0.22, 0.19), RED, e=0.8, seg=12, ring=9)         # knee cop
    p.hard().blob((x0 + 0.2, 0.98, z + 0.1 * s), (0.14, 0.34, 0.2), RED, rot=(0, 0, -14), e=0.8, seg=12, ring=9)             # thigh guard
    p.hard().blob((x0 + 0.12, 0.5, z + 0.07 * s), (0.1, 0.3, 0.14), RED2, rot=(0, 0, 8), e=0.8, seg=10, ring=8)               # greave
    p.hard().ring((x0 + 0.04, 0.36, z), 0.12, 0.03, BONE, rot=(90, 0, 0), seg=10, tseg=4)
    for dz in (-0.07, 0.0, 0.07):
        p.hard().tube([(toe[0], 0.06, toe[2] + dz), (toe[0] + 0.2, 0.02, toe[2] + dz * 1.7)], (0.045, 0.0), CREAM, sides=4)
    p.hard().tube([(ank[0] - 0.03, 0.22, ank[2]), (ank[0] - 0.22, 0.13, ank[2])], (0.05, 0.0), CREAM, sides=4)
    parts[name] = p.finish(voxel=0.04, smooth_passes=3, target_tris=900)

leg("leg_f", 0.27, 0.06)
leg("leg_b", -0.27, -0.10)

# ------------------------------------------------------------------------------------------------ torso: pelvis, waist, chest, neck (+ fur ruff, belt, kilt)
t = Part("torso", (0, 1.12, 0), dy=0.18)
t.blob((0.0, 1.22, 0), (0.38, 0.27, 0.36), CHAR)                                           # pelvis
t.tube([(0.0, 1.25, 0), (0.04, 1.62, 0), (0.1, 1.9, 0)], (0.3, 0.34), CHAR, sides=14)       # waist
t.blob((0.1, 2.02, 0), (0.46, 0.4, 0.52), CHAR2)                                           # chest
t.tube([(0.1, 2.15, 0), (0.17, 2.45, 0), (0.26, 2.78, 0), (0.38, 3.05, 0), (0.5, 3.25, 0)], (0.19, 0.11), CHAR, sides=12)   # long strong neck
t.hard().blob((0.34, 2.0, 0), (0.3, 0.34, 0.42), CHAR3, e=0.8)                              # chest plate base
t.hard().blob((0.5, 2.02, 0), (0.12, 0.27, 0.22), RED, e=0.8, seg=12, ring=9)               # red sternum plate
for k, y in enumerate((2.3, 2.52, 2.74, 2.96)):                                             # bone truss rings on the neck
    f = (y - 2.15) / 1.1
    t.hard().ring((0.1 + 0.4 * f, y, 0), 0.14 - 0.05 * f, 0.03, BONE if k % 2 == 0 else CREAM2, rot=(90, 0, 0), seg=12, tseg=4)
fur(t, (0.2, 2.2, 0), (0.34, 0.2, 0.46), CREAM, n=110, ln=0.2, flow=(-0.3, -0.8, 0), seed=3, width=0.07, skip_below=-0.2)    # fur ruff at the shoulders
t.hard().tube([(0.0, 1.38, 0.38), (0.12, 1.34, 0.0), (0.0, 1.38, -0.38)], 0.075, DRED, sides=7)  # belt
t.hard().ring((0.05, 1.36, 0), 0.38, 0.06, BROWN, rot=(90, 0, 0), seg=18, tseg=5)
t.hard().blob((0.26, 1.34, 0.0), (0.07, 0.1, 0.1), GOLD, e=0.8)                             # buckle
t.hard().blob((0.2, 1.16, 0.34), (0.1, 0.18, 0.08), BONE)                                  # bone charm
for k, dz in enumerate((-0.3, -0.16, 0.0, 0.16, 0.3)):                                     # kilt tatters
    t.hard().mat(0, 1).tube([(0.24, 1.3, dz), (0.34, 0.95, dz * 1.2), (0.3, 0.68 - 0.06 * (k % 2), dz * 1.3)], ((0.1, 0.012), (0.1, 0.012), (0.01, 0.01)), OLIVE if k % 2 == 0 else hexc("8a8a4e"), wide=(0, 0, 1), sides=4)
parts["torso"] = t.finish(voxel=0.04, smooth_passes=3, target_tris=2300)

# ------------------------------------------------------------------------------------------------ head: broad beetle head, big warm eyes, forked rhino horn
hp = (0.5, 2.86, 0)
HS = 1.3
h = Part("head", hp, dy=0.54, sc=HS)
h.blob((0.54, 2.92, 0), (0.3, 0.23, 0.26), CHAR2)                                           # skull
h.blob((0.8, 2.84, 0), (0.28, 0.17, 0.2), CHAR)                                              # broad snout
h.hard().blob((0.92, 2.78, 0), (0.2, 0.1, 0.17), CHAR3, e=0.8)                               # muzzle plate
h.hard().blob((0.62, 3.1, 0), (0.28, 0.1, 0.24), RED, e=0.8, seg=12, ring=8)                 # red brow shield
eye(h, (0.72, 2.97, 0.17), 0.1, "ffb83a", look=(1.0, 0.0, 0.45), glow=0.7)
eye(h, (0.72, 2.97, -0.17), 0.1, "ffb83a", look=(1.0, 0.0, -0.45), glow=0.7)
for sg in (-1, 1):
    brow(h, (0.78, 3.12, 0.17 * sg), 0.2, 0.07, "17141a", th=0.05, look=(1, 0, 0.45 * sg))
mouth(h, (1.0, 2.66, 0), 0.26, -0.03, "17141a", teeth=0)
for s in (-1, 1):
    h.hard().tube([(0.98, 2.74, 0.09 * s), (1.18, 2.62, 0.13 * s)], (0.055, 0.0), CREAM, sides=5)       # tusks
    h.hard().tube([(0.56, 3.12, 0.16 * s), (0.5, 3.3, 0.26 * s), (0.58, 3.42, 0.32 * s)], (0.06, 0.012), RED2, sides=6)   # short brow horns
# the forked rhino horn rising from the forehead, curving forward
h.hard().tube([(0.66, 3.08, 0), (0.62, 3.4, 0), (0.8, 3.72, 0), (1.1, 3.88, 0)], (0.12, 0.03), RED, sides=9)
h.hard().tube([(0.8, 3.72, 0), (0.94, 3.96, 0.1)], (0.05, 0.012), RED2, sides=6)
h.hard().tube([(0.8, 3.72, 0), (0.94, 3.96, -0.1)], (0.05, 0.012), RED2, sides=6)
fur(h, (0.46, 3.0, 0), (0.26, 0.14, 0.24), CREAM, n=40, ln=0.14, flow=(-0.6, -0.2, 0), seed=7, width=0.05, skip_below=0.0)   # mane
parts["head"] = h.finish(voxel=0.03, smooth_passes=3, target_tris=1300)

# ------------------------------------------------------------------------------------------------ arms: thick charcoal arms, chunky red armour
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.1, 2.14, z)
    p = Part(name, sh, dy=0.2)
    el = (0.12, 1.6, z + 0.12 * s); hand = (0.3, 1.14, z + 0.08 * s)
    p.tube([sh, (0.08, 1.85, z + 0.1 * s), el], (0.21, 0.16), CHAR, sides=12)
    p.tube([el, (0.2, 1.4, z + 0.11 * s), hand], (0.16, 0.12), CHAR2, sides=12)
    p.blob(sh, (0.22, 0.22, 0.22), CHAR)
    p.blob(el, (0.17, 0.17, 0.17), CHAR)
    p.hard().blob((0.06, 2.28, z + 0.12 * s), (0.32, 0.2, 0.3), RED, e=0.8, seg=14, ring=10)         # pauldron (a piece of the wing-case)
    p.hard().blob((0.14, 1.66, z + 0.15 * s), (0.19, 0.2, 0.18), RED, e=0.8, seg=10, ring=8)         # elbow
    p.hard().blob((0.24, 1.34, z + 0.11 * s), (0.15, 0.2, 0.17), RED2, rot=(0, 0, 12), e=0.8, seg=12, ring=9)   # bracer
    p.hard().ring((0.17, 1.52, z + 0.12 * s), 0.14, 0.03, BONE, rot=(90, 0, 10), seg=10, tseg=4)
    p.blob(hand, (0.17, 0.17, 0.16), CHAR2)                                                         # fist
    for dz in (-0.07, 0.0, 0.07):
        p.hard().tube([(0.4, 1.1, z + 0.08 * s + dz), (0.52, 1.0, z + 0.08 * s + dz * 1.5)], (0.045, 0.0), CREAM, sides=4)
    bracer(p, (el[0] + 0.02, el[1] - 0.08, el[2]), (hand[0] - 0.02, hand[1] + 0.26, hand[2]), 0.15, DRED, GOLD)
    pauldron(p, (sh[0] + 0.02, sh[1] + 0.02, z + 0.04 * s), 0.27, RED2, GOLD, spikes=3, sd=s)
    parts[name] = p.finish(voxel=0.038, smooth_passes=3, target_tris=1200)

arm("arm_f", 0.58)
arm("arm_b", -0.58)

# ------------------------------------------------------------------------------------------------ Morrow, the psionic mace
wp = (0.2, 1.18, 0.62)
w = Part("weapon", wp, dy=0.2)
d = (0.78, -0.3, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
def at(f, off=(0, 0, 0)):
    return (wp[0] + d[0] * f + off[0], wp[1] + d[1] * f + off[1], wp[2] + off[2])
w.hard().tube([at(-0.35), at(0.6), at(1.4)], (0.075, 0.06), BROWN, sides=8)
for k in range(4):
    w.hard().ring(at(0.25 + k * 0.3), 0.085, 0.02, GOLD, rot=(0, 73, 0), seg=8, tseg=3)
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
parts["weapon"] = w.finish(voxel=0.04, smooth_passes=1, target_tris=900)

# ------------------------------------------------------------------------------------------------ the wing-case shell on his back (the "extra" part: lags like a cape)
ep = (-0.1, 2.5, 0)
e = Part("extra", ep, dy=0.4)
for sd in (-1, 1):   # two glossy elytra, split down the spine
    e.blob((-0.3, 2.28, 0.26 * sd), (0.24, 0.72, 0.28), RED, rot=(0, 0, 8), e=0.85, seg=14, ring=10)
    for k, (yy, zz, rr_) in enumerate(((2.55, 0.16, 0.1), (2.2, 0.38, 0.12), (1.9, 0.2, 0.1), (1.7, 0.42, 0.08))):
        e.hard().blob((-0.58, yy, zz * sd + 0.05 * sd), (0.03, rr_, rr_), BLACK, seg=8, ring=6)   # ladybug spots
    e.hard().blob((-0.3, 1.5, 0.3 * sd), (0.22, 0.2, 0.28), DRED, e=0.85, seg=10, ring=7)
e.hard().tube([(-0.5, 3.0, 0), (-0.5, 1.4, 0)], 0.02, BLACK, sides=4)                          # seam
e.blob((-0.18, 2.85, 0), (0.2, 0.2, 0.46), CHAR3)                                             # shell base / hood
for k in range(7):
    z = -0.4 + k * 0.133
    e.hard().mat(0, 1).tube([(-0.24, 1.6, z), (-0.3, 1.3, z), (-0.34, 1.0 + 0.07 * (k % 2), z)], ((0.09, 0.012), (0.09, 0.012), (0.01, 0.01)), OLIVE if k % 2 == 0 else hexc("8a8a4e"), wide=(0, 0, 1), sides=4)
parts["extra"] = e.finish(voxel=0.04, smooth_passes=3, target_tris=1400)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "aruun.glb"))
mtip = [round(mc[0] - wp[0] + 0.42, 4), round(mc[1] - wp[1], 4), round(mc[2] - wp[2], 4)]
meta = {"sockets": {"head": ["head", 0.02 * HS, 0.09 * HS, 0.0], "hand": ["arm_f", 0.2, -1.0, 0.08], "weapon_tip": ["weapon"] + mtip, "weapon_base": ["weapon", round(d[0] * 0.3, 4), round(d[1] * 0.3, 4), 0.0]},
        "face_off": True}
json.dump(meta, open(os.path.join(OUT, "aruun.json"), "w"), indent=1)
