"""BRAMVEX - The Quiet Command (approved sheet: tools/source_art/bramvex_sheet.png). Tall gaunt stick-insect sergeant: very long jointed thorny limbs,
three slender thorax segments, olive patched field harness with pouches, ONE red accent (armband), insect head with long thorned antennae,
torn translucent bat wings folded like a cloak, an amber lantern, and Diplomacy: a huge thorned club taller than he is.
Layout matches the procedural design (same pivots/sockets) so animation and effects carry over.
Run: python3 tools/blender/build_bramvex.py -> v2/art/models/bramvex.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
BARK = hexc("6a5238"); BARK2 = hexc("7a6044"); TAN = hexc("cbb98c"); OLIVE = hexc("6b7240"); OLIVE2 = hexc("55602f"); WOOD = hexc("5a4128"); THORN = hexc("8a6a3a")
BRASS = hexc("c9a24a"); RED = hexc("b0322a"); AMBER = hexc("ffa845", 1.0); WING = hexc("a9b07a"); WING2 = hexc("8f9660"); DARK = hexc("241a14"); EYE = hexc("1a0e0c")
lib.reset()
parts = {}
rnd = random.Random(7)


def thorns(p, pts, n, ln, color, rad=0.03, side=(0, 0, 1)):
    """Hard thorn cones sprouting along a polyline."""
    for i in range(n):
        f = (i + 0.5) / n
        k = min(int(f * (len(pts) - 1)), len(pts) - 2)
        t = f * (len(pts) - 1) - k
        a, b = pts[k], pts[k + 1]
        c = tuple(a[j] + (b[j] - a[j]) * t for j in range(3))
        sgn = 1 if i % 2 == 0 else -1
        tip = (c[0] + side[0] * ln * sgn, c[1] + side[1] * ln * sgn + 0.02, c[2] + side[2] * ln * sgn)
        p.hard().tube([c, tip], (rad, 0.0), color, sides=4)


# ---- legs: very long thin jointed stick legs with big boots (hip y = 1.5)
def leg(name, z, x0):
    p = Part(name, (x0, 1.5, z))
    hip = (x0, 1.5, z); knee = (x0 + 0.24, 0.8, z); ank = (x0 - 0.02, 0.1, z)
    p.tube([hip, (x0 + 0.14, 1.15, z), knee], (0.085, 0.06), BARK, sides=8)
    p.tube([knee, (x0 + 0.12, 0.45, z), ank], (0.06, 0.045), BARK2, sides=8)
    p.blob(knee, (0.09, 0.09, 0.09), BARK)
    p.hard().blob((x0 + 0.18, 0.78, z), (0.06, 0.14, 0.07), TAN, rot=(0, 0, -20))                  # knee guard
    p.blob((x0 + 0.12, 0.08, z), (0.32, 0.1, 0.15), WOOD)                                          # boot
    p.hard().blob((x0 + 0.38, 0.07, z), (0.09, 0.07, 0.1), DARK)
    p.hard().blob((x0 + 0.0, 0.42, z), (0.1, 0.2, 0.1), OLIVE2)                                     # gaiter
    thorns(p, [hip, (x0 + 0.14, 1.15, z), knee, (x0 + 0.12, 0.45, z), ank], 9, 0.13, THORN, 0.028, side=(0, 0, 1))
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=620)

leg("leg_f", 0.2, 0.1)
leg("leg_b", -0.2, -0.12)

# ---- torso: slender thorax segments, harness, pouches, abdomen stub
t = Part("torso", (0, 1.5, 0))
t.blob((0, 1.55, 0), (0.24, 0.17, 0.2), BARK2)
t.blob((0.02, 1.9, 0), (0.26, 0.3, 0.22), BARK)
t.blob((0.05, 2.35, 0), (0.3, 0.3, 0.24), BARK2)
t.blob((-0.35, 1.55, 0), (0.4, 0.2, 0.22), BARK2)                                              # abdomen stub
for k in range(3):
    t.hard().ring((0.02 + 0.015 * k, 1.78 + k * 0.32, 0), 0.24 + 0.02 * k, 0.03, THORN, rot=(90, 0, 0), seg=12, tseg=4)
thorns(t, [(-0.2, 1.7, 0), (-0.2, 2.1, 0), (-0.15, 2.5, 0)], 8, 0.22, THORN, 0.04, side=(-1, 0.6, 0))
t.hard().blob((0.18, 2.1, 0), (0.1, 0.3, 0.3), OLIVE, rot=(0, 0, 8))                           # vest panel
t.hard().tube([(0.15, 2.55, 0.22), (0.3, 2.1, 0.0), (0.15, 1.7, -0.22)], 0.04, WOOD, sides=5)  # straps
t.hard().tube([(0.15, 2.55, -0.22), (0.3, 2.05, 0.0), (0.15, 1.7, 0.22)], 0.04, WOOD, sides=5)
t.hard().ring((0.0, 1.65, 0), 0.26, 0.05, WOOD, rot=(90, 0, 0), seg=14, tseg=4)               # belt
for z in (-0.2, 0.0, 0.2):
    t.hard().blob((0.22, 1.62, z), (0.1, 0.12, 0.08), OLIVE2)                                   # pouches
    t.hard().blob((0.28, 1.66, z), (0.025, 0.04, 0.05), BRASS)
t.hard().tube([(0.12, 2.7, 0.2), (0.05, 2.6, 0.0), (0.12, 2.7, -0.2)], 0.035, OLIVE, sides=5)  # collar scrap
# red sash scrap on the hip (the single accent besides the armband)
t.hard().tube([(0.2, 1.85, -0.2), (0.28, 1.5, -0.24), (0.24, 1.1, -0.26)], (0.07, 0.015), RED, wide=(0, 0, 1), sides=4)
parts["torso"] = t.finish(voxel=0.045, smooth_passes=2, target_tris=1300)

# ---- head: long narrow insect head, big dark eyes (face shader), mandibles, long thorned antennae
hp = (0.12, 2.65, 0)
h = Part("head", hp)
h.blob((0.24, 2.7, 0), (0.3, 0.26, 0.24), BARK2)
h.blob((0.5, 2.57, 0), (0.24, 0.13, 0.15), hexc("a8966a"), rot=(0, 0, -15))                   # muzzle
for s in (-1, 1):
    h.hard().tube([(0.62, 2.48, 0.08 * s), (0.74, 2.33, 0.06 * s)], (0.045, 0.0), THORN, sides=5)   # mandibles
    ant = [(0.22, 2.9, 0.1 * s), (0.12, 3.45, 0.22 * s), (0.02, 4.05, 0.3 * s), (0.12, 4.55, 0.34 * s)]
    h.hard().tube(ant, (0.03, 0.012), BARK, sides=5)
    thorns(h, ant, 8, 0.1, THORN, 0.022, side=(-1, 0.2, 0))
    h.hard().blob((0.34, 2.78, 0.19 * s), (0.08, 0.11, 0.07), EYE, seg=8, ring=6)               # compound eye bulge
h.hard().tube([(0.02, 2.9, 0), (-0.23, 3.0, 0), (-0.38, 2.85, 0)], (0.04, 0.02), WOOD, sides=5)  # head spine
parts["head"] = h.finish(voxel=0.035, smooth_passes=2, target_tris=860)

# ---- arms: long thin, pale bark, sharp elbows, red armband on the left arm; both hands on Diplomacy. Front arm carries the club.
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.05, 2.3, z)
    p = Part(name, sh)
    el = (-0.05, 1.7, z + 0.04 * s); hand = (0.19, 1.02, z + 0.07 * s)
    p.hard().blob(sh, (0.14, 0.12, 0.14), OLIVE)
    p.tube([sh, (-0.02, 2.0, z + 0.03 * s), el], (0.06, 0.05), BARK2, sides=8)
    p.tube([el, (0.08, 1.35, z + 0.06 * s), hand], (0.05, 0.045), BARK2, sides=8)
    p.blob(el, (0.07, 0.07, 0.07), BARK)
    p.hard().blob((el[0] + 0.05, el[1], el[2]), (0.06, 0.1, 0.07), TAN)
    p.blob(hand, (0.1, 0.12, 0.09), TAN)
    for dz in (-0.04, 0.0, 0.04):
        p.hard().tube([(hand[0] + 0.05, hand[1] - 0.05, hand[2] + dz), (hand[0] + 0.14, hand[1] - 0.18, hand[2] + dz * 1.4)], (0.02, 0.0), TAN, sides=4)
    thorns(p, [sh, (-0.02, 2.0, z + 0.03 * s), el, (0.08, 1.35, z + 0.06 * s), hand], 8, 0.1, THORN, 0.024, side=(0, 0, 1))
    if s < 0:
        p.hard().ring((el[0] - 0.04, 1.95, el[2]), 0.075, 0.035, RED, rot=(90, 0, 8), seg=10, tseg=4)   # red armband
    if s > 0:   # Diplomacy: huge thorned club held diagonally, taller than he is
        d = (0.45, 0.89, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
        def at(f, off=(0, 0, 0)):
            return (hand[0] + d[0] * f + off[0], hand[1] + d[1] * f + off[1], hand[2] + off[2])
        p.hard().tube([at(-0.9), at(0.9), at(2.3), at(3.2)], ((0.06, 0.06), (0.1, 0.1), (0.17, 0.17), (0.15, 0.15)), WOOD, sides=8)
        p.hard().tube([at(3.15), at(3.72)], (0.13, 0.0), THORN, sides=6)
        up = (-d[1], d[0], 0.0)
        for i in range(11):
            f = 1.1 + i * 0.2
            p.hard().tube([at(f, (up[0] * 0.1, up[1] * 0.1, 0)), at(f, (up[0] * 0.36, up[1] * 0.36, 0))], (0.05, 0.0), THORN, sides=4)
            p.hard().tube([at(f, (0, 0, 0.1)), at(f, (0, 0, 0.34))], (0.045, 0.0), THORN, sides=4)
            p.hard().tube([at(f, (-up[0] * 0.1, -up[1] * 0.1, 0)), at(f, (-up[0] * 0.3, -up[1] * 0.3, 0))], (0.04, 0.0), THORN, sides=4)
            p.hard().tube([at(f, (0, 0, -0.1)), at(f, (0, 0, -0.3))], (0.04, 0.0), THORN, sides=4)
        p.hard().ring(at(1.05), 0.15, 0.03, BRASS, rot=(0, 0, 25), seg=10, tseg=4)
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=1500 if s > 0 else 560)

arm("arm_f", 0.34)
arm("arm_b", -0.34)

# ---- lantern + tattered olive sash (lag)
w = Part("weapon", (0.0, 2.2, 0.36))
w.hard().tube([(0, 2.2, 0.36), (0.0, 1.7, 0.36)], 0.012, WOOD, sides=4)
w.hard().blob((0, 1.58, 0.36), (0.1, 0.14, 0.1), AMBER, seg=10, ring=8)
w.hard().ring((0, 1.7, 0.36), 0.08, 0.02, BRASS, rot=(90, 0, 0), seg=10, tseg=4)
for k in range(3):
    zz = 0.21 + k * 0.1
    w.hard().tube([(-0.1, 2.1, zz), (-0.15, 1.5, zz), (-0.2, 1.0 + 0.1 * (k % 2), zz)], (0.06, 0.012), OLIVE if k % 2 == 0 else OLIVE2, wide=(1, 0, 0), sides=4)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=420)

# ---- torn translucent bat wings folded like a cloak (glass), bark finger bones, ragged lower edge
e = Part("extra", (-0.15, 2.3, 0))
for sd in (-1, 1):
    for k in range(3):
        ln = 1.3 - 0.2 * k
        x0 = -0.2 - 0.05 * k; z0 = (0.18 + 0.08 * k) * sd
        pts = [(x0, 2.2, z0), (x0 - 0.06, 2.2 - ln * 0.5, z0 * 1.05), (x0 - 0.1, 2.2 - ln, z0 * 1.1)]
        e.hard().tube(pts, ((0.07, 0.008), (0.16, 0.008), (0.05, 0.008)), WING if k % 2 == 0 else WING2, wide=(0, 0, 1), sides=4, caps=False)
        e.hard().tube(pts, (0.017, 0.01), WOOD, sides=4, caps=False)
        e.hard().tube([pts[0], (x0 - 0.04, 2.2 - ln * 0.3, z0 * 1.5), (x0 - 0.07, 2.2 - ln * 0.85, z0 * 1.7)], (0.012, 0.007), WOOD, sides=4, caps=False)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=500)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.export(os.path.join(OUT, "bramvex.glb"))
json.dump({}, open(os.path.join(OUT, "bramvex.json"), "w"))
