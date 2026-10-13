"""NYXARIS - The Frostbloom Weaver (approved sheet: tools/source_art/nyxaris_sheet.png). Reclusive yeti-crab / black-widow weaver: indigo carapace,
cream frost-fur ruff, six long jointed ice-tipped legs and two slender silk-wand arms, a big abdomen crowned with dragon-fruit ice-flower petals
(crystal blue + rose), glowing pink vein dots, crystal spinnerets, venom fangs, pink eyes, crystal crest, hanging pink teardrop pendants, a
translucent silk train. Layout matches the procedural design. Run: python3 tools/blender/build_nyxaris.py -> v2/art/models/nyxaris.glb"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
IND = hexc("2a2650"); IND2 = hexc("3a3466"); PLUM = hexc("4a2d6a"); PINK = hexc("ee4fa8", 0.8); ROSE = hexc("f08cc0"); ICE = hexc("7fd2ea", 0.4); CRYS = hexc("a8d8f0")
SILK = hexc("e8eaf2"); FUR = hexc("dcd8e4"); GOLDC = hexc("f4d24a", 0.8); DARK = hexc("14102a")
lib.reset()
parts = {}
rr = random.Random(9)

# six long jointed spider legs: front trio + rear trio (each trio spans both sides)
def legs(name, px, spec):
    p = Part(name, (px, 1.45, 0.0))
    for (dx, dz) in spec:
        pts = [(px, 1.45, dz * 0.12), (px + dx * 0.6, 2.0, dz * 0.55), (px + dx * 1.1 + 0.05, 1.7, dz * 1.15), (px + dx * 1.45 + 0.1, 0.05, dz * 1.45)]
        p.tube(pts, (0.1, 0.035), IND, sides=8)
        p.blob(pts[1], (0.13, 0.13, 0.13), PLUM)
        p.blob(pts[2], (0.1, 0.1, 0.1), PLUM)
        tip = pts[3]
        p.hard().tube([(tip[0], tip[1] + 0.35, tip[2]), (tip[0] + 0.03, tip[1] - 0.04, tip[2])], (0.045, 0.0), ICE, sides=5)
        mid = tuple(pts[2][i] + (pts[3][i] - pts[2][i]) * 0.35 for i in range(3))
        p.hard().ring(mid, 0.06, 0.02, SILK, rot=(80, 0, 0), seg=8, tseg=3)
        for q in range(3):   # frost tufts + crystal blades along the lower leg
            f = 0.2 + 0.25 * q
            c = tuple(pts[2][i] + (pts[3][i] - pts[2][i]) * f for i in range(3))
            p.hard().tube([c, (c[0] + 0.05, c[1] + 0.02, c[2] + 0.1 * (1 if dz > 0 else -1))], (0.05, 0.0), FUR, sides=4)
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=1100)

legs("leg_f", 0.35, [(0.45, 1.0), (0.45, -1.0), (-0.05, 1.15)])
legs("leg_b", -0.3, [(-0.05, -1.15), (-0.55, 1.0), (-0.55, -1.0)])

# torso: cephalothorax, fur ruff, pedicel, big abdomen with ice-flower petals and pink glow dots, spinnerets
t = Part("torso", (0, 1.45, 0))
t.blob((0.05, 1.9, 0), (0.4, 0.55, 0.4), IND)
t.blob((0.3, 1.9, 0), (0.22, 0.4, 0.3), FUR)
for k in range(12):
    a = k * 2.4
    d = (0.6, math.sin(a) * 0.8, math.cos(a) * 0.8); n = math.sqrt(sum(x * x for x in d)); d = tuple(x / n for x in d)
    c = (0.28, 1.9, 0)
    t.hard().tube([tuple(c[i] + d[i] * 0.2 for i in range(3)), tuple(c[i] + d[i] * 0.4 for i in range(3))], (0.06, 0.0), SILK, sides=4)
t.tube([(-0.2, 1.65, 0), (-0.7, 1.5, 0)], 0.15, IND, sides=8)
t.blob((-1.1, 1.45, 0), (0.7, 0.55, 0.52), IND2, rot=(0, 0, 10))
for k in range(8):    # ice-flower petals radiating on top of the abdomen (flattened blades)
    ang = -70 + 140 * k / 7
    ln = 0.55 + 0.2 * math.sin(k / 7 * math.pi)
    col = CRYS if k % 2 == 0 else ROSE
    ca = math.radians(ang)
    ctr = (-1.15, 1.82 + 0.5 * ln * math.cos(ca), 0.5 * ln * math.sin(ca) * 1.1)
    t.hard().blob(ctr, (0.13, ln * 0.5, 0.03), col, rot=(-ang, 0, 0), seg=8, ring=6)
t.hard().blob((-1.1, 1.88, 0), (0.1, 0.07, 0.1), GOLDC)
for k in range(5):
    for sd in (-1, 1):
        t.hard().blob((-0.8 - k * 0.12, 1.5 + 0.08 * math.sin(k), 0.45 * sd), (0.06, 0.06, 0.03), PINK, seg=6, ring=4)
for k in range(3):
    zz = (k - 1) * 0.12
    t.hard().tube([(-1.7, 1.4, zz), (-1.95, 1.33 - 0.05 * k, zz * 1.7), (-2.15, 1.2, zz * 2.2)], ((0.0, 0.02), (0.09, 0.03), (0.0, 0.02)), CRYS, wide=(0, 1, 0), sides=4)
parts["torso"] = t.finish(voxel=0.05, smooth_passes=2, target_tris=1700)

# head: furred cream face, venom fangs, big pink eyes (face shader) + small eyes, crystal crest and pink crest horns
hp = (0.45, 2.25, 0)
h = Part("head", hp)
h.blob((0.55, 2.35, 0), (0.4, 0.34, 0.4), FUR)
for k in range(14):
    a = k * 2.4
    d = (math.cos(a) * 0.5, math.sin(a * 1.3) * 0.7, math.sin(a)); n = math.sqrt(sum(x * x for x in d)); d = tuple(x / n for x in d)
    c = (0.55 + d[0] * 0.4, 2.35 + d[1] * 0.34, d[2] * 0.4)
    h.hard().tube([c, (c[0] + d[0] * 0.14, c[1] + d[1] * 0.12, c[2] + d[2] * 0.14)], (0.05, 0.0), SILK, sides=4)
for s in (-1, 1):
    h.hard().tube([(0.83, 2.13, 0.14 * s), (0.97, 1.87, 0.2 * s), (0.93, 1.6, 0.12 * s)], (0.07, 0.0), CRYS, sides=5)       # venom fangs
    h.hard().blob((0.87, 2.15, 0.22 * s), (0.1, 0.1, 0.1), IND)                                                                  # chelicerae
    h.hard().blob((0.81, 2.59, 0.1 * s), (0.045, 0.045, 0.045), PINK, seg=6, ring=4)
    h.hard().blob((0.75, 2.7, 0.2 * s), (0.04, 0.04, 0.04), PINK, seg=6, ring=4)
    h.hard().tube([(0.45, 2.65, 0.15 * s), (0.35, 3.1, 0.3 * s), (0.5, 3.45, 0.38 * s)], (0.05, 0.015), PINK, sides=5)           # crest horns
h.hard().tube([(0.55, 2.65, 0), (0.45, 3.05, 0), (0.4, 3.4, 0)], ((0.0, 0.03), (0.1, 0.03), (0.0, 0.02)), CRYS, wide=(0, 0, 1), sides=4)   # crystal crest
parts["head"] = h.finish(voxel=0.035, smooth_passes=2, target_tris=1000)

# arms: slender arms with silk-wand hands, silver wraps; the front arm holds a silk-line wand
sock = {}
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.3, 1.95, z)
    p = Part(name, sh)
    el = (0.42, 1.5, z + 0.08 * s); hand = (0.68, 1.09, z + 0.12 * s)
    p.tube([sh, el, hand], (0.1, 0.07), IND, sides=8)
    p.blob(el, (0.09, 0.09, 0.09), PLUM)
    p.hard().ring((0.4, 1.55, z + 0.08 * s), 0.1, 0.03, SILK, rot=(90, 0, 14), seg=8, tseg=3)
    p.blob(hand, (0.12, 0.1, 0.1), IND2)
    for dz in (-0.04, 0.0, 0.04):
        p.hard().tube([(hand[0] + 0.06, hand[1] - 0.04, hand[2] + dz), (hand[0] + 0.2, hand[1] - 0.16, hand[2] + dz * 1.5)], (0.025, 0.0), CRYS, sides=4)
    if s > 0:
        a0 = (hand[0] - 0.1, hand[1] - 0.3, hand[2]); a1 = (hand[0] + 0.5, hand[1] + 0.2, hand[2]); a2 = (hand[0] + 1.3, hand[1] + 0.5, hand[2])
        p.hard().tube([a0, a1, a2], (0.03, 0.01), SILK, sides=4)
        p.hard().blob(a2, (0.09, 0.09, 0.09), PINK, seg=7, ring=5)
        sock["weapon_tip"] = ["arm_f", round(a2[0] - sh[0], 4), round(a2[1] - sh[1], 4), round(a2[2] - sh[2], 4)]
        sock["weapon_base"] = ["arm_f", round(hand[0] - sh[0], 4), round(hand[1] - sh[1], 4), round(hand[2] - sh[2], 4)]
        sock["hand"] = sock["weapon_base"]
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=620)

arm("arm_f", 0.4)
arm("arm_b", -0.4)

# hanging pink teardrop pendants (lag)
w = Part("weapon", (0.55, 1.5, 0.45))
for k in range(3):
    zz = 0.35 + k * 0.1
    w.hard().tube([(0.55, 1.5, zz), (0.55, 1.3 - 0.1 * k, zz)], 0.012, SILK, sides=3)
    w.hard().blob((0.55, 1.16 - 0.1 * k, zz), (0.07, 0.12, 0.07), PINK, seg=7, ring=5)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=240)

# translucent silk train from the spinnerets (glass)
e = Part("extra", (-2.0, 1.45, 0))
for k in range(7):
    z = (k - 3) * 0.2
    ln = 1.6 + 0.3 * (3 - abs(k - 3))
    e.hard().tube([(-2.0, 1.45, z), (-2.4, 0.95, z * 1.3), (-2.9, 1.45 - ln * 0.7, z * 1.6), (-3.3, 1.45 - ln, z * 1.8)], ((0.13, 0.008), (0.14, 0.008), (0.1, 0.008), (0.0, 0.008)), SILK if k % 2 == 0 else hexc("c8e4f4"), wide=(0, 0, 1), sides=4, caps=False)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=500)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.export(os.path.join(OUT, "nyxaris.glb"))
json.dump({"sockets": sock}, open(os.path.join(OUT, "nyxaris.json"), "w"), indent=1)
