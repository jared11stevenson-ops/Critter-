"""MOLLUSK - The Weight of Tomorrow (approved sheet: tools/source_art/mollusk_sheet.png). Huge calm giant-African-snail warrior: soft heavy
body leaning forward on stout legs with a long foot trailing behind, a thick banded amber/brown spiral shell overgrown with moss and a
hibiscus, long stalk eyes with tired lids, tattered red/olive wraps with hanging charms and hourglass relics, a mossy rock mace in the fist.
Layout matches the procedural design. Run: python3 tools/blender/build_mollusk.py -> v2/art/models/mollusk.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
BODY = hexc("d7b48a"); BODY2 = hexc("c39a6e"); PALE = hexc("e9d3a6"); AMBER = hexc("94623a"); BROWN = hexc("4a2616"); CREAM = hexc("e8d3a2"); DARK = hexc("3a2a22")
ORANGE = hexc("e0702a"); RED = hexc("a8342a"); OLIVE = hexc("6f7a3a"); MOSS = hexc("56743a"); LEAF = hexc("3f7a3a"); FLOWER = hexc("e2503a"); ROCK = hexc("6a645a")
STEEL = hexc("8b929b"); GLOWC = hexc("d8e060", 1.0); EYEW = hexc("f6efe0"); EYEB = hexc("140c0a")
lib.reset()
parts = {}
rr = random.Random(4)

def leg(name, z, x0):
    p = Part(name, (x0, 0.5, z))
    p.tube([(x0, 0.55, z), (x0 + 0.05, 0.3, z), (x0 + 0.08, 0.1, z)], (0.3, 0.24), BODY2, sides=10)
    p.blob((x0 + 0.3, 0.1, z), (0.2, 0.1, 0.22), BODY2)
    p.hard().ring((x0 + 0.06, 0.34, z), 0.26, 0.035, RED, rot=(90, 0, 0), seg=12, tseg=4)        # wrap
    parts[name] = p.finish(voxel=0.05, smooth_passes=2, target_tris=520)

leg("leg_f", 0.3, 0.25)
leg("leg_b", -0.3, -0.05)

# torso: heavy soft body leaning forward, the foot slab trailing behind, tattered wraps, charms
t = Part("torso", (0, 0.5, 0))
t.blob((0.05, 1.0, 0), (0.6, 0.66, 0.54), BODY)
t.blob((0.28, 1.05, 0), (0.34, 0.5, 0.42), PALE)
t.blob((-0.8, 0.5, 0), (1.0, 0.26, 0.5), BODY2)                                               # the foot slab
t.tube([(-1.4, 0.5, 0), (-2.1, 0.48, 0), (-2.7, 0.44, 0)], (0.38, 0.0), BODY2, sides=10)       # tapering tail
t.hard().blob((0.15, 1.12, 0), (0.54, 0.4, 0.58), RED, rot=(0, 0, 4))                          # woven wrap
t.hard().blob((0.2, 1.5, 0), (0.36, 0.12, 0.5), OLIVE)
for k in range(2):
    t.hard().ring((0.12, 0.95 + k * 0.28, 0), 0.58, 0.035, CREAM, rot=(90, 0, 0), seg=14, tseg=3)
t.hard().tube([(0.1, 1.6, 0.35), (0.45, 1.15, 0.0), (0.2, 0.7, -0.4)], 0.045, DARK, sides=4)  # straps
t.hard().tube([(0.1, 1.6, -0.35), (0.45, 1.1, 0.0), (0.2, 0.7, 0.4)], 0.045, DARK, sides=4)
t.hard().blob((0.5, 1.15, 0.0), (0.03, 0.1, 0.1), STEEL)
t.hard().blob((0.55, 0.95, 0.25), (0.07, 0.1, 0.06), GLOWC)
for k in range(7):    # hanging tatters / beads
    z = -0.4 + k * 0.13
    t.hard().blob((0.55, 0.62 - 0.04 * (k % 2), z), (0.05, 0.24, 0.06), RED if k % 2 == 0 else OLIVE)
parts["torso"] = t.finish(voxel=0.05, smooth_passes=2, target_tris=1500)

# head: gentle peaked head, long stalk eyes with tired lids; plants growing on the crown
hp = (0.4, 1.75, 0)
h = Part("head", hp)
h.blob((0.5, 1.85, 0), (0.36, 0.34, 0.32), BODY)
h.blob((0.64, 1.55, 0), (0.16, 0.09, 0.18), PALE, rot=(0, 0, -10))
for s in (-1, 1):
    st = [(0.45, 2.05, 0.1 * s), (0.5, 2.45, 0.16 * s), (0.58, 2.85, 0.2 * s), (0.64, 3.15, 0.22 * s)]
    h.tube(st, (0.075, 0.055), BODY, sides=7)
    eye(h, (0.68, 3.2, 0.22 * s), 0.17, "5a3a1a", white="fff6e0", look=(1, 0, 0.1 * s), glow=0.0)
    h.hard().blob((0.67, 3.28, 0.22 * s), (0.16, 0.07, 0.16), BODY2, rot=(0, 0, -12))          # tired lid
for k in range(6):   # leaves + hibiscus on the crown
    a = k / 6 * math.tau
    h.hard().tube([(0.4, 2.12, 0), (0.4 + 0.12 * math.cos(a), 2.3, 0.12 * math.sin(a)), (0.4 + 0.3 * math.cos(a), 2.4, 0.3 * math.sin(a))], ((0.05, 0.01), (0.08, 0.01), (0.0, 0.01)), LEAF, wide=(0, 1, 0), sides=4)
h.hard().blob((0.42, 2.22, 0.08), (0.12, 0.05, 0.12), FLOWER, seg=7, ring=4)
parts["head"] = h.finish(voxel=0.04, smooth_passes=2, target_tris=900)

# arms: big stout arms in woven wraps; the front fist holds a mossy rock mace
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.15, 1.5, z)
    p = Part(name, sh)
    el = (0.22, 1.0, z + 0.07 * s); hand = (0.5, 0.55, z + 0.1 * s)
    p.tube([sh, el, hand], (0.22, 0.17), BODY2, sides=10)
    p.hard().blob((0.14, 1.52, z + 0.04 * s), (0.28, 0.24, 0.27), RED)                          # shoulder wrap
    p.hard().ring((0.26, 1.05, z + 0.06 * s), 0.2, 0.04, STEEL, rot=(90, 0, 14), seg=10, tseg=3)
    p.blob(hand, (0.22, 0.19, 0.2), BODY2)
    if s > 0:   # rock mace
        mc = (0.9, 0.2, z + 0.12)
        p.hard().tube([(hand[0], hand[1] - 0.05, hand[2]), (0.75, 0.3, z + 0.12)], 0.06, DARK, sides=5)
        p.blob(mc, (0.4, 0.38, 0.38), ROCK)
        p.hard().blob((mc[0], mc[1] + 0.3, mc[2]), (0.3, 0.14, 0.3), MOSS)
        for q in range(4):
            a = q * 1.57
            p.hard().tube([(mc[0] + 0.3 * math.cos(a), mc[1] + 0.1, mc[2] + 0.3 * math.sin(a)), (mc[0] + 0.5 * math.cos(a), mc[1] + 0.2, mc[2] + 0.5 * math.sin(a))], (0.09, 0.0), hexc("55504a"), sides=5)
    parts[name] = p.finish(voxel=0.05, smooth_passes=2, target_tris=800 if s > 0 else 520)

arm("arm_f", 0.62)
arm("arm_b", -0.62)

# hanging relics (lag): hourglass + charms
w = Part("weapon", (0.35, 1.05, 0.5))
w.hard().tube([(0.35, 1.05, 0.5), (0.35, 0.8, 0.5)], 0.02, DARK, sides=4)
w.hard().blob((0.35, 0.7, 0.5), (0.1, 0.14, 0.1), GLOWC)
w.hard().ring((0.35, 0.82, 0.5), 0.08, 0.025, STEEL, rot=(90, 0, 0), seg=8, tseg=3)
w.hard().blob((0.5, 0.85, 0.45), (0.05, 0.08, 0.04), ORANGE)
w.hard().blob((0.5, 0.65, 0.45), (0.05, 0.08, 0.04), RED)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=240)

# the giant banded spiral shell with moss, a hibiscus and tick marks
e = Part("extra", (-0.6, 1.25, 0))
e.blob((-0.6, 1.45, 0), (1.05, 1.0, 0.76), AMBER, rot=(0, 0, -10))
for sdz in (-1, 1):
    for r_ in (0.3, 0.52, 0.74, 0.92):
        zz = 0.76 * math.sqrt(max(0.0, 1 - (r_ / 1.05) ** 2)) * 0.97 * sdz
        e.hard().ring((-0.6, 1.45, zz), r_, 0.05, BROWN if int(r_ * 10) % 2 == 0 else CREAM, seg=16, tseg=3)
    e.hard().blob((-0.6, 1.45, 0.78 * sdz), (0.13, 0.13, 0.08), BROWN)
    for k in range(5):
        a = 0.5 + k * 0.5
        e.hard().tube([(-0.6 + math.cos(a) * 0.55, 1.45 + math.sin(a) * 0.55, 0.79 * sdz), (-0.6 + math.cos(a) * 0.72, 1.45 + math.sin(a) * 0.72, 0.77 * sdz)], 0.022, DARK, sides=3)
for k in range(9):    # moss + ferns on the shell crown
    a = rr.uniform(0, math.tau); d = rr.uniform(0.0, 0.5)
    base = (-0.6 + 0.45 * math.cos(a) * d, 2.35, 0.4 * math.sin(a) * d)
    e.hard().tube([base, (base[0] - 0.1, base[1] + 0.25, base[2]), (base[0] - 0.2 + 0.1 * math.cos(a), base[1] + 0.35, base[2] + 0.15 * math.sin(a))], ((0.05, 0.01), (0.08, 0.01), (0.0, 0.01)), LEAF, wide=(0, 0, 1), sides=4)
e.hard().blob((-0.55, 2.45, 0.1), (0.14, 0.06, 0.14), FLOWER)
e.hard().blob((-0.55, 2.0, 0.0), (0.7, 0.22, 0.6), MOSS)
parts["extra"] = e.finish(voxel=0.05, smooth_passes=2, target_tris=1500)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "mollusk.glb"))
json.dump({"face_off": True}, open(os.path.join(OUT, "mollusk.json"), "w"))
