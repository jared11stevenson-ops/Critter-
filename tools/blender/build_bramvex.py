"""BRAMVEX - the Quiet Command (v2 design; the sheet is inspiration only). A tall, lanky stick-insect sergeant with big round glossy eyes,
a smart olive peaked cap with a red badge, a patched field jacket and harness with pouches, one red armband, long jointed bark-brown limbs with
thorn ridges and chunky boots, folded translucent bat wings like a cloak, a lantern, and Diplomacy, a huge thorned club taller than he is.
Pivots/sockets match the rig. Run: python3 tools/blender/build_bramvex.py -> v2/art/models/bramvex.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part, eye, fur

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
BARK = hexc("7a5e40"); BARK2 = hexc("8e7050"); TAN = hexc("d8c496"); OLIVE = hexc("6e7a40"); OLIVE2 = hexc("56622e"); WOOD = hexc("604628"); THORN = hexc("a67e44")
BRASS = hexc("d0a850"); RED = hexc("c0382c"); AMBER = hexc("ffb040", 1.0); WING = hexc("b4bc86"); WING2 = hexc("98a06a"); DARK = hexc("2a1e16"); BLACK = hexc("140e0c")
lib.reset()
parts = {}

def thorns(p, pts, n, ln, color, rad=0.03, side=(0, 0, 1)):
    for i in range(n):
        f = (i + 0.5) / n
        k = min(int(f * (len(pts) - 1)), len(pts) - 2)
        t = f * (len(pts) - 1) - k
        a, b = pts[k], pts[k + 1]
        c = tuple(a[j] + (b[j] - a[j]) * t for j in range(3))
        sgn = 1 if i % 2 == 0 else -1
        p.hard().tube([c, (c[0] + side[0] * ln * sgn, c[1] + side[1] * ln * sgn + 0.02, c[2] + side[2] * ln * sgn)], (rad, 0.0), color, sides=4)

def leg(name, z, x0):
    p = Part(name, (x0, 1.5, z))
    hip = (x0, 1.5, z); knee = (x0 + 0.26, 0.8, z); ank = (x0 - 0.02, 0.12, z)
    p.tube([hip, (x0 + 0.15, 1.15, z), knee], (0.14, 0.1), BARK, sides=12)
    p.tube([knee, (x0 + 0.12, 0.45, z), ank], (0.1, 0.065), BARK2, sides=10)
    p.blob(knee, (0.14, 0.14, 0.14), BARK)
    p.hard().blob((x0 + 0.2, 0.8, z), (0.08, 0.17, 0.1), TAN, rot=(0, 0, -20), e=0.8, seg=10, ring=8)
    p.blob((x0 + 0.14, 0.1, z), (0.36, 0.13, 0.18), WOOD, e=0.8, seg=12, ring=8)
    p.hard().blob((x0 + 0.42, 0.1, z), (0.1, 0.09, 0.12), DARK, e=0.8, seg=8, ring=6)
    p.hard().blob((x0 + 0.0, 0.42, z), (0.13, 0.24, 0.13), OLIVE2, e=0.8, seg=10, ring=8)
    thorns(p, [hip, (x0 + 0.15, 1.15, z), knee, (x0 + 0.12, 0.45, z)], 8, 0.14, THORN, 0.035)
    parts[name] = p.finish(voxel=0.04, smooth_passes=3, target_tris=800)

leg("leg_f", 0.2, 0.1)
leg("leg_b", -0.2, -0.12)

t = Part("torso", (0, 1.5, 0))
t.blob((0, 1.55, 0), (0.28, 0.2, 0.24), BARK2)
t.blob((0.02, 1.92, 0), (0.3, 0.32, 0.26), BARK)
t.blob((0.05, 2.36, 0), (0.34, 0.34, 0.28), BARK2)
t.blob((-0.38, 1.55, 0), (0.44, 0.24, 0.26), BARK2)
t.hard().blob((0.1, 2.15, 0), (0.28, 0.5, 0.36), OLIVE, e=0.8, seg=14, ring=10)                      # jacket
t.hard().ring((0.02, 1.7, 0), 0.3, 0.05, WOOD, rot=(90, 0, 0), seg=16, tseg=4)                         # belt
for z in (-0.22, 0.0, 0.22):
    t.hard().blob((0.24, 1.64, z), (0.11, 0.13, 0.09), OLIVE2, e=0.8, seg=9, ring=7)
    t.hard().blob((0.3, 1.68, z), (0.03, 0.045, 0.055), BRASS, seg=6, ring=5)
t.hard().tube([(0.15, 2.58, 0.24), (0.3, 2.1, 0.0), (0.15, 1.72, -0.24)], 0.045, WOOD, sides=5)
t.hard().tube([(0.15, 2.58, -0.24), (0.3, 2.05, 0.0), (0.15, 1.72, 0.24)], 0.045, WOOD, sides=5)
t.hard().tube([(0.2, 1.9, -0.22), (0.3, 1.5, -0.26), (0.26, 1.1, -0.28)], ((0.08, 0.014), (0.08, 0.014), (0.01, 0.01)), RED, wide=(0, 0, 1), sides=4)  # sash scrap
thorns(t, [(-0.22, 1.7, 0), (-0.22, 2.1, 0), (-0.16, 2.5, 0)], 8, 0.24, THORN, 0.045, side=(-1, 0.6, 0))
parts["torso"] = t.finish(voxel=0.04, smooth_passes=3, target_tris=1500)

hp = (0.12, 2.65, 0)
HS = 1.3
h = Part("head", hp, sc=HS)
h.blob((0.25, 2.72, 0), (0.32, 0.27, 0.25), BARK2)
h.blob((0.52, 2.58, 0), (0.24, 0.14, 0.17), TAN, rot=(0, 0, -15))
eye(h, (0.38, 2.8, 0.19), 0.13, "1a0e0c", white="2a1e1a", look=(1, 0, 0.55), glow=0.0)
eye(h, (0.38, 2.8, -0.19), 0.13, "1a0e0c", white="2a1e1a", look=(1, 0, -0.55), glow=0.0)
for s in (-1, 1):
    h.hard().tube([(0.64, 2.48, 0.08 * s), (0.76, 2.34, 0.06 * s)], (0.05, 0.0), THORN, sides=5)
    ant = [(0.24, 2.94, 0.1 * s), (0.14, 3.45, 0.22 * s), (0.04, 3.98, 0.3 * s), (0.14, 4.4, 0.34 * s)]
    h.hard().tube(ant, (0.035, 0.014), BARK, sides=5)
    thorns(h, ant, 7, 0.1, THORN, 0.024, side=(-1, 0.2, 0))
# the sergeant's cap: crown, peak, red badge
h.hard().blob((0.2, 2.96, 0), (0.33, 0.14, 0.3), OLIVE, e=0.8, seg=14, ring=8)
h.hard().blob((0.42, 2.9, 0), (0.22, 0.04, 0.26), OLIVE2, e=0.8, seg=10, ring=6)                       # peak
h.hard().ring((0.2, 2.9, 0), 0.31, 0.03, DARK, rot=(90, 0, 0), seg=14, tseg=3)
h.hard().blob((0.45, 3.0, 0), (0.035, 0.06, 0.06), RED, seg=7, ring=5)                                  # badge
parts["head"] = h.finish(voxel=0.032, smooth_passes=3, target_tris=1200)

def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.05, 2.3, z)
    p = Part(name, sh)
    el = (-0.05, 1.7, z + 0.04 * s); hand = (0.19, 1.02, z + 0.07 * s)
    p.hard().blob(sh, (0.17, 0.15, 0.17), OLIVE, e=0.8, seg=12, ring=8)
    p.tube([sh, (-0.02, 2.0, z + 0.03 * s), el], (0.08, 0.065), BARK2, sides=10)
    p.tube([el, (0.08, 1.35, z + 0.06 * s), hand], (0.065, 0.06), BARK2, sides=10)
    p.blob(el, (0.095, 0.095, 0.095), BARK)
    p.hard().blob((el[0] + 0.05, el[1], el[2]), (0.07, 0.12, 0.08), TAN, e=0.8, seg=8, ring=6)
    p.blob(hand, (0.12, 0.14, 0.11), TAN)
    for dz in (-0.045, 0.0, 0.045):
        p.hard().tube([(hand[0] + 0.05, hand[1] - 0.05, hand[2] + dz), (hand[0] + 0.14, hand[1] - 0.18, hand[2] + dz * 1.4)], (0.024, 0.0), TAN, sides=4)
    thorns(p, [sh, (-0.02, 2.0, z + 0.03 * s), el, (0.08, 1.35, z + 0.06 * s), hand], 7, 0.1, THORN, 0.026)
    if s < 0:
        p.hard().ring((el[0] - 0.04, 1.95, el[2]), 0.085, 0.04, RED, rot=(90, 0, 8), seg=10, tseg=4)
    if s > 0:   # Diplomacy
        d = (0.45, 0.89, 0.0); dl = math.hypot(d[0], d[1]); d = (d[0] / dl, d[1] / dl, 0.0)
        def at(f, off=(0, 0, 0)):
            return (hand[0] + d[0] * f + off[0], hand[1] + d[1] * f + off[1], hand[2] + off[2])
        p.hard().tube([at(-0.9), at(0.9), at(2.3), at(3.2)], ((0.07, 0.07), (0.12, 0.12), (0.2, 0.2), (0.18, 0.18)), WOOD, sides=9)
        p.hard().tube([at(3.15), at(3.75)], (0.16, 0.0), THORN, sides=7)
        up = (-d[1], d[0], 0.0)
        for i in range(10):
            f = 1.1 + i * 0.22
            for (ox, oy, oz, ln_) in ((up[0], up[1], 0, 0.34), (0, 0, 1, 0.3), (-up[0], -up[1], 0, 0.3), (0, 0, -1, 0.3)):
                p.hard().tube([at(f, (ox * 0.12, oy * 0.12, oz * 0.12)), at(f, (ox * ln_, oy * ln_, oz * ln_))], (0.06, 0.0), THORN, sides=4)
        p.hard().ring(at(1.05), 0.17, 0.035, BRASS, rot=(0, 65, 0), seg=10, tseg=4)
    parts[name] = p.finish(voxel=0.035, smooth_passes=3, target_tris=1700 if s > 0 else 700)

arm("arm_f", 0.34)
arm("arm_b", -0.34)

w = Part("weapon", (0.0, 2.2, 0.36))
w.hard().tube([(0, 2.2, 0.36), (0.0, 1.7, 0.36)], 0.014, WOOD, sides=4)
w.hard().blob((0, 1.56, 0.36), (0.11, 0.15, 0.11), AMBER, seg=10, ring=8)
w.hard().ring((0, 1.7, 0.36), 0.09, 0.022, BRASS, rot=(90, 0, 0), seg=10, tseg=4)
for k in range(3):
    zz = 0.21 + k * 0.1
    w.hard().mat(0, 1).tube([(-0.1, 2.1, zz), (-0.15, 1.5, zz), (-0.2, 1.0 + 0.1 * (k % 2), zz)], ((0.07, 0.012), (0.07, 0.012), (0.01, 0.01)), OLIVE if k % 2 == 0 else OLIVE2, wide=(1, 0, 0), sides=4)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=420)

e = Part("extra", (-0.15, 2.3, 0))
for sd in (-1, 1):
    for k in range(3):
        ln = 1.4 - 0.2 * k
        ctr = (-0.3 - 0.05 * k, 1.6 - 0.05 * k, (0.22 + 0.1 * k) * sd)
        e.hard().blob(ctr, (0.014, ln * 0.5, 0.22), WING if k % 2 == 0 else WING2, rot=(sd * (6 + 5 * k), 0, 8 + 6 * k), seg=10, ring=8)
        e.hard().tube([(ctr[0] + 0.02, ctr[1] + ln * 0.4, ctr[2]), (ctr[0] + 0.02, ctr[1] - ln * 0.4, ctr[2])], 0.02, WOOD, sides=4, caps=False)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=600)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "bramvex.glb"))
json.dump({"sockets": {"head": ["head", 0.12 * HS, 0.06 * HS, 0.0]}, "face_off": True}, open(os.path.join(OUT, "bramvex.json"), "w"))
