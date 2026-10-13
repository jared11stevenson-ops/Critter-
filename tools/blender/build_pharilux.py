"""PHARILUX - The Watcher Below (approved sheet: tools/source_art/pharilux_sheet.png; visual canon). Tall hunched ghost prey-mantis fused with antique
diving + lighthouse forms: brass lantern helmet with an amber beacon lens, long antennae arcing over him hung with chains and lanterns, two huge
rust-bronze raptorial scythe arms, teal barnacled body, a rust chain + anchor at the hip, long tattered pale yellow-green membranes like a cloak.
Layout matches the procedural design. Run: python3 tools/blender/build_pharilux.py -> v2/art/models/pharilux.glb + pharilux.json"""
import json, math, os, sys, random
sys.path.insert(0, os.path.dirname(__file__))
import lib
from lib import hexc, Part

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "v2", "art", "models")
TEAL = hexc("4a7f86"); TEAL2 = hexc("3a6a72"); RUST = hexc("8a4a28"); RUST2 = hexc("a8602e"); BRASS = hexc("a9803a"); AMBER = hexc("ffb83a", 1.0); IRON = hexc("2c3234")
MIST = hexc("cdd6b8"); MEM = hexc("c4cf94"); MEM2 = hexc("8fb89a"); BARN = hexc("cdd1b8"); DARK = hexc("1f2a2c"); LAMP = hexc("ffb83a", 0.9)
lib.reset()
parts = {}
rr = random.Random(12)

def lantern(p, c, sz):
    p.hard().blob((c[0], c[1] + sz * 1.3, c[2]), (sz * 0.7, sz * 0.25, sz * 0.7), BRASS, seg=6, ring=4)
    p.hard().blob(c, (sz * 0.75, sz, sz * 0.75), LAMP, seg=7, ring=5)
    p.hard().blob((c[0], c[1] - sz * 1.1, c[2]), (sz * 0.6, sz * 0.2, sz * 0.6), BRASS, seg=6, ring=4)

def chain(p, a, b, color=IRON, rad=0.03):
    n = max(2, int(math.dist(a, b) / (rad * 6)))
    for k in range(n):
        c = tuple(a[i] + (b[i] - a[i]) * (k + 0.5) / n for i in range(3))
        p.hard().ring(c, rad * 1.5, rad * 0.5, color, rot=(90 * (k % 2), 0, 0), seg=6, tseg=3)

def anchor(p, c, sz, color=IRON):
    p.hard().tube([(c[0], c[1] + sz, c[2]), (c[0], c[1] - sz, c[2])], sz * 0.15, color, sides=5)
    p.hard().tube([(c[0] - sz * 0.55, c[1] + sz * 0.55, c[2]), (c[0] + sz * 0.55, c[1] + sz * 0.55, c[2])], sz * 0.12, color, sides=4)
    p.hard().ring((c[0], c[1] + sz * 1.15, c[2]), sz * 0.2, sz * 0.07, color, seg=8, tseg=3)
    p.hard().tube([(c[0] - sz * 0.9, c[1] - sz * 0.35, c[2]), (c[0] - sz * 0.5, c[1] - sz * 0.9, c[2]), (c[0], c[1] - sz, c[2]), (c[0] + sz * 0.5, c[1] - sz * 0.9, c[2]), (c[0] + sz * 0.9, c[1] - sz * 0.35, c[2])], sz * 0.13, color, sides=4)

def barnacles(p, c, r, n):
    for i in range(n):
        a = i * 2.39
        p.hard().blob((c[0] + math.cos(a) * r, c[1] + math.sin(a * 1.7) * r * 0.8, c[2] + math.sin(a) * r * 0.6), (0.04, 0.035, 0.04), BARN, seg=5, ring=4)

# ---- legs: long digitigrade stilts, barnacled knees, hooked feet (hips at y = 1.35)
def leg(name, z, x0):
    p = Part(name, (x0, 1.35, z))
    knee = (x0 + 0.28, 0.9, z); hock = (x0 - 0.1, 0.4, z)
    p.tube([(x0, 1.35, z), (x0 + 0.14, 1.15, z), knee], (0.12, 0.09), TEAL, sides=8)
    p.tube([knee, (x0 + 0.12, 0.65, z), hock, (x0 - 0.02, 0.06, z)], (0.08, 0.045), TEAL2, sides=7)
    p.blob(knee, (0.12, 0.1, 0.1), RUST)
    for dz in (-0.06, 0.0, 0.06):
        p.hard().tube([(x0 - 0.02, 0.06, z + dz * 0.5), (x0 + 0.3, 0.04, z + dz * 1.8)], (0.04, 0.0), RUST2, sides=4)
    p.hard().tube([(x0 - 0.02, 0.06, z), (x0 - 0.26, 0.04, z)], (0.035, 0.0), RUST2, sides=4)
    barnacles(p, knee, 0.1, 3)
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=620)

leg("leg_f", 0.2, 0.12)
leg("leg_b", -0.2, -0.18)

# ---- torso: hunched thorax leaning forward, pale chest plates, banded abdomen, chain harness, mantle cloak
t = Part("torso", (0, 1.4, 0))
t.tube([(-0.05, 1.4, 0), (0.2, 1.85, 0), (0.42, 2.35, 0)], (0.3, 0.22), TEAL, sides=10)
t.tube([(0.06, 1.5, 0), (0.28, 1.9, 0), (0.45, 2.28, 0)], (0.27, 0.19), MIST, sides=9)
t.hard().blob((0.38, 2.35, 0), (0.26, 0.2, 0.34), RUST)                                       # shoulder yoke
t.tube([(-0.25, 1.4, 0), (-0.65, 1.22, 0), (-1.05, 0.85, 0)], (0.2, 0.06), TEAL2, sides=8)    # abdomen
for k in range(4):
    t.hard().ring((-0.4 - 0.18 * k, 1.34 - 0.1 * k, 0), 0.17 - 0.03 * k, 0.025, RUST, rot=(0, 90, -25), seg=9, tseg=3)
chain(t, (0.5, 2.45, 0.28), (0.3, 1.95, 0.3))
chain(t, (0.3, 1.95, 0.3), (0.1, 1.5, 0.22))
chain(t, (0.5, 2.45, -0.28), (0.3, 1.95, -0.3))
chain(t, (0.3, 1.95, -0.3), (0.1, 1.5, -0.22))
lantern(t, (0.2, 1.4, 0.3), 0.07)
barnacles(t, (0.38, 2.4, 0.18), 0.2, 5)
barnacles(t, (0.0, 1.6, 0.2), 0.2, 4)
for k in range(8):   # tattered mantle hanging from the shoulders (a cloak of membrane)
    z = (k - 3.5) * 0.11
    ln = 1.5 + 0.35 * ((k * 3) % 4)
    t.hard().tube([(0.25, 2.3, z), (-0.15, 1.6, z * 1.4), (-0.3, 0.9, z * 1.8), (-0.3, 2.3 - ln, z * 2.0)], ((0.0, 0.01), (0.07, 0.01), (0.1, 0.01), (0.0, 0.01)), MEM2 if k % 2 == 0 else MEM, wide=(0, 0, 1), sides=4)
parts["torso"] = t.finish(voxel=0.045, smooth_passes=2, target_tris=1400)

# ---- head: small insect skull inside a big brass lantern helmet, amber lens, chimney cap, chain-hung antenna arcs
hp = (0.62, 2.45, 0)
h = Part("head", hp)
h.blob((0.62, 2.45, 0), (0.2, 0.26, 0.2), TEAL)                                               # skull
h.blob((0.72, 2.79, 0), (0.36, 0.34, 0.34), BRASS)                                             # helmet dome
h.hard().ring((0.72, 2.63, 0), 0.36, 0.05, RUST, rot=(0, 90, 0), seg=14, tseg=4)
h.hard().blob((0.92, 2.75, 0), (0.24, 0.26, 0.26), AMBER, seg=10, ring=7)                      # lantern lens
h.hard().ring((1.0, 2.75, 0), 0.2, 0.035, BRASS, rot=(0, 0, 0), seg=10, tseg=4)
h.hard().tube([(0.67, 3.07, 0), (0.67, 3.25, 0)], (0.09, 0.05), BRASS, sides=6)
h.hard().blob((0.67, 3.31, 0), (0.11, 0.05, 0.11), RUST, seg=6, ring=4)
for s in (-1, 1):
    ant = [(0.55, 3.05, 0.12 * s), (0.42, 3.5, 0.28 * s), (0.77, 3.9, 0.42 * s), (1.27, 3.85, 0.52 * s), (1.57, 3.5, 0.58 * s)]
    h.hard().tube(ant, (0.04, 0.018), BRASS, sides=5)
    chain(h, (ant[4][0], ant[4][1] - 0.05, ant[4][2]), (ant[4][0] + 0.02, ant[4][1] - 0.4, ant[4][2]), IRON, 0.018)
    lantern(h, (ant[4][0] + 0.02, ant[4][1] - 0.55, ant[4][2]), 0.08)
    chain(h, (ant[3][0], ant[3][1] - 0.03, ant[3][2]), (ant[3][0], ant[3][1] - 0.3, ant[3][2]), IRON, 0.016)
    lantern(h, (ant[3][0], ant[3][1] - 0.42, ant[3][2]), 0.06)
    chain(h, (ant[1][0], ant[1][1] - 0.03, ant[1][2]), (ant[1][0] - 0.04, ant[1][1] - 0.28, ant[1][2]), IRON, 0.016)
    lantern(h, (ant[1][0] - 0.04, ant[1][1] - 0.38, ant[1][2]), 0.05)
parts["head"] = h.finish(voxel=0.035, smooth_passes=2, target_tris=950)

# ---- arms: huge raptorial scythes (rust bronze, serrated); the front one is the weapon arm
sock = {}
def arm(name, z):
    s = 1.0 if z > 0 else -1.0
    sh = (0.45, 2.3, z)
    p = Part(name, sh)
    el = (0.7, 1.6, z + 0.05 * s)
    p.hard().blob(sh, (0.14, 0.14, 0.14), RUST)
    p.tube([sh, (0.7, 1.95, z + 0.03 * s), el], (0.1, 0.085), TEAL, sides=8)
    p.blob(el, (0.13, 0.12, 0.12), RUST)
    blade = [el, (1.2, 1.75, z + 0.06 * s), (1.75, 1.35, z + 0.07 * s), (1.75, 0.8, z + 0.07 * s), (1.5, 0.35, z + 0.07 * s)]
    p.hard().tube(blade, ((0.17, 0.045), (0.17, 0.05), (0.15, 0.045), (0.1, 0.03), (0.0, 0.01)), RUST, wide=(0, 0, 1), sides=4)
    p.hard().tube(blade, (0.07, 0.01), BRASS, sides=5)
    for k in range(3):
        q = blade[k + 1]
        p.hard().tube([(q[0] - 0.1, q[1] + 0.0, q[2]), (q[0] - 0.28, q[1] - 0.1, q[2])], (0.03, 0.0), BRASS, sides=4)
    barnacles(p, el, 0.12, 3)
    if s > 0:
        tip = blade[-1]
        sock["weapon_tip"] = ["arm_f", round(tip[0] - sh[0], 4), round(tip[1] - sh[1], 4), round(tip[2] - sh[2], 4)]
        sock["weapon_base"] = ["arm_f", round(el[0] - sh[0], 4), round(el[1] - sh[1], 4), round(el[2] - sh[2], 4)]
        sock["hand"] = sock["weapon_base"]
    parts[name] = p.finish(voxel=0.04, smooth_passes=2, target_tris=800)

arm("arm_f", 0.4)
arm("arm_b", -0.4)

# ---- weapon (lagging): a long rust chain and a big anchor swinging from the hip
w = Part("weapon", (-0.15, 1.5, 0.42))
chain(w, (-0.15, 1.5, 0.42), (-0.15, 0.55, 0.42), RUST, 0.035)
anchor(w, (-0.15, 0.2, 0.42), 0.34)
parts["weapon"] = w.finish(voxel=0.0, smooth_passes=0, target_tris=500)

# ---- membranes: long tattered translucent pale-gold/green wings behind him, holes and a frayed hem down to the ground
e = Part("extra", (-0.1, 2.25, 0))
for z in (0.16, -0.16):
    sd = 1 if z > 0 else -1
    pts = [(-0.3, 2.2, z * 2.4), (-0.4, 1.2, z * 2.8), (-0.5, 0.2, z * 3.2)]
    e.hard().tube(pts, ((0.05, 0.008), (0.5, 0.008), (0.3, 0.008)), MEM, wide=(0, 0, 1), sides=4, caps=False)
    for k in range(5):
        e.hard().blob((-0.4 - 0.02 * k, 1.9 - 0.35 * k, z * (2.6 + 0.2 * k) + 0.1 * sd * (k % 2)), (0.06, 0.06, 0.03), MIST, seg=6, ring=4)
    for k in range(4):
        zz = z * 2.4 + (k - 1.5) * 0.25 * sd
        e.hard().tube([(-0.5, 0.45, zz), (-0.55, 0.0 + 0.1 * (k % 2), zz * 1.05)], ((0.12, 0.008), (0.0, 0.008)), MEM2, wide=(0, 0, 1), sides=4, caps=False)
parts["extra"] = e.finish(voxel=0.0, smooth_passes=0, target_tris=500)

total = sum(lib.tris(o) for o in parts.values())
print("TRIS", {k: lib.tris(o) for k, o in parts.items()}, "total", total)
lib.bake(parts)
lib.export(os.path.join(OUT, "pharilux.glb"))
meta = {"sockets": dict(sock, head=["head", 0.3, 0.3, 0.0]), "face": {"center": [0.3, 0.3, 0.0], "radii": [0.24, 0.26, 0.26], "half_lon": 0.9, "half_lat": 0.6, "lat_center": 0.0, "e": 0.9}}
json.dump(meta, open(os.path.join(OUT, "pharilux.json"), "w"), indent=1)
