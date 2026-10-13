"""SCARLITH - The Fermented Kingpin (approved sheet: tools/source_art/scarlith_sheet.jpg). Round plush red-velvet-mite pirate cartel lord:
eight fuzzy legs, big fuzzy head with gold-ringed eyes, eyepatch and a gold tooth, black tricorn with a gold wheel, wine coat with gold buttons,
belt and coin purse, a huge aged-cheese carapace on his back (holes, rind) with a barrel/bottle cache, lantern at the hat, boarding-hook polearm.
Layout matches the procedural design pivots. Run: python3 tools/blender/build_scarlith.py -> v2/art/models/scarlith.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur, brow, mouth, pauldron, bracer, rivets

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
RED = hexc("b01c2c"); RED2 = hexc("c42a3a"); DRED = hexc("7e1522"); GOLD = hexc("e3b04a"); WINE = hexc("4f1a36"); BLACK = hexc("171012"); WOOD = hexc("7a4a2a")
RIND = hexc("d98a3a"); CHEESE = hexc("e8c25a"); CHEESE2 = hexc("f2d98a"); HOLE = hexc("a8782a"); IRON = hexc("4a4852"); GLOWC = hexc("ffc24a", 1.0); GREEN = hexc("4a7a3a")
lib.reset()
lib.CHUNK = 1.3; lib.EYE_SCALE = 1.2; lib.MISMATCH = True
parts = {}
rnd = random.Random(11)


def fuzz(p, c, r, n, ln, color, seed=0):
    rr = random.Random(seed)
    for i in range(n):
        a = rr.uniform(0, math.tau); y = rr.uniform(-0.6, 1.0)
        s = math.sqrt(max(0.0, 1 - y * y))
        d = (math.cos(a) * s, y, math.sin(a) * s)
        base = (c[0] + d[0] * r[0], c[1] + d[1] * r[1], c[2] + d[2] * r[2])
        tip = (base[0] + d[0] * ln, base[1] + d[1] * ln, base[2] + d[2] * ln)
        p.hard().tube([base, tip], (0.045, 0.0), color, sides=4)


# ---- legs: eight short fuzzy legs (4 per group), pivots at the body midline
def legs(name, dx):
    p = Part(name, (dx, 0.55, 0.0))
    for z in (0.5, -0.5):
        for k in range(2):
            xo = (k - 0.5) * 0.5 * (1 if dx > 0 else -1)
            col = RED if z > 0 else DRED
            a = (xo, 0.65, z * 0.5); b = (xo + dx * 0.4, 0.65, z * 1.1); c = (xo + dx * 0.55, 0.0, z * 1.5)
            p.tube([a, b, c], (0.15, 0.085), col, sides=8)
            p.blob(b, (0.13, 0.13, 0.13), col)
            p.hard().blob((c[0] + 0.02, 0.03, c[2]), (0.15, 0.05, 0.11), GOLD)
            fuzz(p, b, (0.1, 0.1, 0.1), 1, 0.1, col, seed=k + int(abs(z) * 10))
    parts[name] = p.finish(voxel=0.05, smooth_passes=2, target_tris=700)

legs("leg_f", 0.35)
legs("leg_b", -0.4)

# ---- torso: round plush body, wine coat, gold buttons, belt + coin purse
t = Part("torso", (0, 0.55, 0))
t.blob((0, 1.0, 0), (0.85, 0.7, 0.8), RED)
t.hard().blob((0.38, 0.9, 0), (0.5, 0.58, 0.62), WINE)
for z in (-0.4, -0.2, 0.2, 0.4):
    t.hard().blob((0.82, 0.8, z), (0.05, 0.45, 0.07), WINE)
for k in range(3):
    t.hard().blob((0.86, 1.1 - k * 0.22, 0.0), (0.04, 0.06, 0.06), GOLD)
t.hard().ring((0.0, 0.73, 0), 0.8, 0.05, BLACK, rot=(90, 0, 0), seg=18, tseg=4)
t.hard().blob((0.8, 0.73, 0.0), (0.03, 0.1, 0.1), GOLD)
t.hard().blob((0.55, 0.6, 0.6), (0.14, 0.17, 0.12), WOOD)
t.hard().blob((0.55, 0.77, 0.6), (0.1, 0.06, 0.09), GOLD)
for k in range(6):
    z = -0.45 + k * 0.18
    t.hard().blob((0.74, 0.22 - 0.05 * (k % 2), z), (0.05, 0.28, 0.07), RIND if k % 2 == 0 else GOLD)
fuzz(t, (0, 1.0, 0), (0.85, 0.7, 0.8), 18, 0.12, RED, seed=3)
t.hard().tube([(0.55, 1.62, -0.55), (0.9, 1.1, 0.0), (0.55, 0.62, 0.55)], 0.05, BLACK, sides=5)   # bandolier
t.hard().blob((0.9, 1.1, 0.0), (0.04, 0.09, 0.09), GOLD)
t.hard().ring((0.93, 1.1, 0.0), 0.08, 0.016, GOLD, rot=(0, 90, 0), seg=10, tseg=3)
parts["torso"] = t.finish(voxel=0.05, smooth_passes=2, target_tris=1100)

# ---- head: big fuzzy red head, gold-ringed eyes (face shader), eyepatch, gold tooth, black tricorn with a gold wheel
hp = (0.75, 1.55, 0)
h = Part("head", hp, sc=1.2)
h.blob((0.8, 1.65, 0), (0.55, 0.45, 0.52), RED2)
h.blob((1.25, 1.4, 0), (0.14, 0.1, 0.2), DRED, rot=(0, 0, -10))
eye(h, (1.16, 1.78, -0.25), 0.15, "e3b04a", white="fff4d8", look=(1, 0, -0.2), glow=0.3)
eye(h, (1.16, 1.78, 0.25), 0.15, "e3b04a", white="fff4d8", look=(1, 0, 0.2), glow=0.3)
for sg in (-1, 1):
    brow(h, (1.2, 1.99, 0.25 * sg), 0.3, 0.09, "171012", th=0.06, look=(1, 0, 0.2 * sg))
mouth(h, (1.3, 1.5, 0), 0.5, 0.12, "171012", teeth=4, tooth="fff0c0")
h.hard().ring((1.2, 1.78, -0.25), 0.17, 0.03, GOLD, rot=(0, 90, 0), seg=14, tseg=4)
h.hard().blob((1.35, 1.35, 0.06), (0.025, 0.04, 0.02), GOLD)                                  # gold tooth
fuzz(h, (0.8, 1.65, 0), (0.55, 0.45, 0.52), 22, 0.1, RED2, seed=5)
h.hard().blob((0.75, 2.05, 0), (0.42, 0.28, 0.42), BLACK)                                      # tricorn crown
h.hard().blob((0.75, 1.95, 0), (0.7, 0.05, 0.66), BLACK, rot=(0, 0, 3))                       # brim
for s in (-1, 1):
    h.hard().blob((0.75, 2.08, 0.5 * s), (0.16, 0.05, 0.13), BLACK, rot=(0, 0, 25 * s))
h.hard().ring((0.75, 2.05, 0.0), 0.44, 0.04, WINE, rot=(90, 0, 0), seg=16, tseg=4)
h.hard().ring((0.75, 2.07, 0.45), 0.11, 0.025, GOLD, seg=12, tseg=4)
h.hard().tube([(1.05, 1.75, 0.3), (1.15, 1.6, 0.0), (1.05, 1.75, -0.3)], 0.02, BLACK, sides=4)  # eyepatch strap
h.hard().blob((1.22, 1.62, 0.2), (0.05, 0.12, 0.12), BLACK, rot=(0, 20, 0))                  # eyepatch
parts["head"] = h.finish(voxel=0.04, smooth_passes=2, target_tris=950)

# ---- arms: fuzzy red forelegs; front one holds a boarding-hook polearm
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    col = RED if s > 0 else DRED
    sh = (0.4, 1.0, z)
    p = Part(name, sh)
    el = (0.52, 0.6, z + 0.1 * s); hand = (0.82, 0.45, z + 0.14 * s)
    p.tube([sh, el, hand], (0.14, 0.09), col, sides=8)
    p.blob(el, (0.12, 0.12, 0.12), col)
    p.hard().blob((el[0] + 0.04, el[1] - 0.05, el[2]), (0.12, 0.17, 0.14), RIND, rot=(0, 0, 20))     # cuff
    p.blob(hand, (0.1, 0.09, 0.09), RED2)
    fuzz(p, el, (0.12, 0.12, 0.12), 6, 0.1, col, seed=int(z * 7))
    if s > 0:
        d = (0.5, 0.86, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
        def at(f, o=(0, 0, 0)):
            return (hand[0] + d[0] * f + o[0], hand[1] + d[1] * f + o[1], hand[2] + o[2])
        p.hard().tube([at(-0.6), at(1.2), at(2.4)], (0.05, 0.06), IRON, sides=6)
        for k in (0.0, 0.9):
            p.hard().ring(at(k), 0.08, 0.025, GOLD, rot=(0, 0, 25), seg=8, tseg=4)
        tip = at(2.4)
        p.hard().tube([tip, (tip[0] + 0.2, tip[1] + 0.25, tip[2]), (tip[0] + 0.45, tip[1] + 0.2, tip[2]), (tip[0] + 0.5, tip[1] - 0.05, tip[2])], ((0.14, 0.03), (0.16, 0.03), (0.12, 0.03), (0.0, 0.01)), IRON, wide=(-0.5, 0.5, 0), sides=4)
    pauldron(p, (sh[0] + 0.02, sh[1] + 0.04, z), 0.2, hexc("4f1a36"), hexc("e3b04a"), spikes=3, sd=s)
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=700 if s > 0 else 480)

arm("arm_f", 0.82)
arm("arm_b", -0.82)

# ---- lantern at the hat (lag)
w = Part("weapon", (0.75, 2.2, 0.62))
w.hard().tube([(0.75, 2.2, 0.62), (0.75, 1.9, 0.62)], 0.015, GOLD, sides=4)
w.hard().blob((0.75, 1.7, 0.62), (0.11, 0.17, 0.11), GLOWC, seg=10, ring=8)
w.hard().ring((0.75, 1.86, 0.62), 0.08, 0.025, BLACK, rot=(90, 0, 0), seg=8, tseg=4)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=240)

# ---- back: aged-cheese carapace (dome with holes + rind) over a barrel cache with gold hoops and a bottle rack
e = Part("extra", (-0.65, 1.1, 0))
e.blob((-0.7, 1.55, 0), (0.7, 0.7, 0.75), CHEESE)                                              # big cheese carapace
e.hard().blob((-0.7, 1.35, 0), (0.78, 0.2, 0.82), RIND)                                         # rind band
rr = random.Random(2)
for i in range(8):
    a = rr.uniform(-2.2, 2.2); b = rr.uniform(0.1, 1.2)
    pos = (-0.7 + math.cos(b) * 0.55 * -1 * 0 + -0.35 * math.cos(a) * math.sin(b), 1.55 + 0.7 * math.cos(b), 0.75 * math.sin(a) * math.sin(b))
    e.hard().blob(pos, (rr.uniform(0.06, 0.13), rr.uniform(0.06, 0.12), 0.05), HOLE)             # holes
e.hard().tube([(-0.65, 0.98, 0), (-0.65, 1.1, 0), (-0.65, 1.7, 0)], ((0.4, 0.4), (0.5, 0.5), (0.42, 0.42)), WOOD, sides=10)   # barrel
for hy in (1.1, 1.45, 1.8):
    e.hard().ring((-0.65, hy, 0), 0.5 - 0.05 * abs(hy - 1.45) * 2.0, 0.035, GOLD, rot=(90, 0, 0), seg=14, tseg=4)
for z in (-0.3, 0.0, 0.3):
    e.hard().tube([(-1.1, 1.2, z), (-1.1, 1.6, z)], 0.1, GREEN, sides=6)
    e.hard().tube([(-1.1, 1.6, z), (-1.1, 1.9, z)], 0.045, GREEN, sides=5)
    e.hard().blob((-1.1, 1.95, z), (0.055, 0.04, 0.055), RIND)
parts["extra"] = e.finish(voxel=0.05, smooth_passes=2, target_tris=800)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "scarlith.glb"))
json.dump({"face_off": True}, open(os.path.join(OUT, "scarlith.json"), "w"))
