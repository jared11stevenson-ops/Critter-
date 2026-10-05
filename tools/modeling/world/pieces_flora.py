"""Reaches flora: flat tree, reach shrub, lichen mat/terrace, thorn tussock, dead tree, bones."""
import math
import random
from mathutils import Vector
from kitlib import *


def flat_tree(name="flat_tree", seed=4, H=4.2, spread=3.4):
    km = KM(name, seed)
    km.dust = 0.0
    km.ao_dist = 1.2
    km.ao_amt = 0.5
    km.ground = 0.5
    rng = random.Random(seed)
    # trunk: three curved segments + two limbs
    pts = [Vector((0, 0, -0.1))]
    cur = Vector((0, 0, 0))
    lean = Vector((rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), 0))
    for i in range(3):
        cur = cur + Vector((lean.x * 0.35, lean.y * 0.35, H * 0.3))
        pts.append(cur)
    bark = (0.40, 0.30, 0.26)
    rad = [0.30, 0.22, 0.16, 0.12]
    for i in range(3):
        km.cyl(pts[i], pts[i + 1], rad[i], rad[i + 1], 7, mul(bark, 1.0 + 0.1 * i), caps=(i == 2), jitter=0.06)
    # buttress roots
    for k in range(3):
        a = k * 2.1 + seed
        km.cyl((math.cos(a) * 0.5, math.sin(a) * 0.5, 0.0), (0, 0, 0.7), 0.1, 0.18, 4, bark, caps=False)
    top = pts[-1]
    limbs = []
    for k in range(4):
        a = k * math.tau / 4 + rng.uniform(-0.4, 0.4)
        e = top + Vector((math.cos(a) * spread * 0.55, math.sin(a) * spread * 0.55, rng.uniform(-0.2, 0.5)))
        km.cyl(top - Vector((0, 0, 0.4)), e, 0.12, 0.06, 5, mul(bark, 1.1), caps=False)
        limbs.append(e)
    # canopy: stacked flattened pads, olive top, shadowed underside
    def cf(n):
        t = n.z * 0.5 + 0.5
        return mix(mul(OLIVE, 0.55), mix(OLIVE, SAGE, 0.5), t) if n.z < 0.5 else mix(OLIVE, (0.72, 0.70, 0.40), n.z)
    km.blob(top + Vector((0, 0, 0.4)), (spread * 0.62, spread * 0.55, 0.55), OLIVE, sub=2, noise=0.15, seed=seed, colfn=cf)
    for i, e in enumerate(limbs):
        km.blob(e + Vector((0, 0, 0.25)), (spread * 0.38, spread * 0.34, 0.38), OLIVE, sub=2, noise=0.18, seed=seed + i + 1, colfn=cf)
    km.blob(top + Vector((0.3, 0.2, 0.95)), (spread * 0.34, spread * 0.3, 0.3), SAGE, sub=1, noise=0.15, seed=seed + 9, colfn=cf)
    return km


def reach_shrub(name="reach_shrub", seed=2):
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.3
    rng = random.Random(seed)
    for i in range(11):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.0, 0.35)
        h = rng.uniform(0.5, 1.15)
        lean = rng.uniform(0.15, 0.5)
        base = Vector((math.cos(a) * d, math.sin(a) * d, 0.0))
        tip = base + Vector((math.cos(a) * lean, math.sin(a) * lean, h))
        c = mix(OLIVE, mul(SAGE, 0.8), rng.random())
        km.cyl(base, tip, 0.09, 0.0, 4, mix(mul(c, 0.55), c, 0.0), caps=False, cols=[mul(c, 0.7), c, mul(c, 1.1), c])
    km.blob((0, 0, 0.18), (0.55, 0.5, 0.22), mul(OLIVE, 0.7), sub=1, noise=0.15, seed=seed,
            colfn=lambda n: mix(mul(OLIVE, 0.6), SAGE, max(0, n.z)))
    return km


def lichen_mat(name="lichen_mat", seed=3, R=1.4):
    km = KM(name, seed)
    km.ao_amt = 0.2
    km.dust = 0.0
    rng = random.Random(seed)
    for layer in range(3):
        n = 14
        z = 0.03 + layer * 0.045
        rr = R * (1.0 - layer * 0.28)
        ph = rng.uniform(0, 6)
        ring_o = []
        for i in range(n):
            a = math.tau * i / n
            q = rr * (0.82 + 0.28 * math.sin(a * 3 + ph) * rng.uniform(0.6, 1.0) + 0.1 * rng.uniform(-1, 1))
            ring_o.append(Vector((math.cos(a) * q, math.sin(a) * q, z)))
        c = LICHEN if layer != 1 else LICHEN_O
        c = jit(c, rng, 0.08)
        ctr = Vector((0, 0, z + 0.03))
        for i in range(n):
            j = (i + 1) % n
            km.poly([ctr, ring_o[i], ring_o[j]], [mul(c, 1.1), c, c])
            lo = [Vector((p.x * 1.0, p.y * 1.0, z - 0.04)) for p in (ring_o[i], ring_o[j])]
            km.poly([lo[0], lo[1], ring_o[j], ring_o[i]], mul(c, 0.7), out=(0, 0, z - 1))
    return km


def lichen_terrace(name="lichen_terrace", seed=5, R=3.2):
    """Stepped lichen terraces (grazer flats): contour-line terraces with a bright rim."""
    km = KM(name, seed)
    km.ao_amt = 0.35
    km.dust = 0.0
    km.ao_dist = 0.8
    rng = random.Random(seed)
    L = [(1.0, 1.0, 0.95, False), (1.0, 0.8, 0.76, False), (1.0, 0.6, 0.56, False)]
    n = 18
    z = 0.0
    prev = None
    for k in range(4):
        rr = R * (1.0 - k * 0.22)
        h = 0.28
        ph = rng.uniform(0, 6)
        lo, hi = [], []
        for i in range(n):
            a = math.tau * i / n
            q = rr * (1.0 + 0.16 * math.sin(a * 3 + ph) + rng.uniform(-0.04, 0.04))
            lo.append(Vector((math.cos(a) * q, math.sin(a) * q * 0.8, z)))
            hi.append(Vector((math.cos(a) * q * 0.96, math.sin(a) * q * 0.96 * 0.8, z + h)))
        base = jit(mix(LICHEN, LICHEN_O, 0.25 + 0.25 * (k % 2)), rng, 0.07)
        for i in range(n):
            j = (i + 1) % n
            km.poly([lo[i], lo[j], hi[j], hi[i]], [mul(RUST, 1.0), mul(RUST, 1.0), mul(base, 0.8), mul(base, 0.8)], out=(0, 0, z))
            if prev is None:
                pass
        # top
        ctr = Vector((0, 0, z + h + 0.02))
        for i in range(n):
            j = (i + 1) % n
            km.poly([ctr, hi[i], hi[j]], [mul(base, 1.1), base, base])
        z += h
        prev = hi
    return km


def dead_tree(name="dead_tree", seed=7):
    km = KM(name, seed)
    km.ao_dist = 1.0
    km.ground = 0.4
    rng = random.Random(seed)
    bark = (0.46, 0.38, 0.33)
    km.cyl((0, 0, -0.1), (0.1, 0.05, 2.6), 0.26, 0.10, 6, bark, jitter=0.07, cols=[bark, mul(bark, 0.85), mul(bark, 1.1)])
    for i in range(5):
        a = i * 2.3 + rng.random()
        z0 = 1.2 + rng.random() * 1.1
        p0 = Vector((0.08, 0.04, z0))
        p1 = p0 + Vector((math.cos(a) * 1.2, math.sin(a) * 1.2, 0.6 + rng.random() * 0.7))
        km.cyl(p0, p1, 0.08, 0.03, 4, mul(bark, 1.1), caps=False)
        km.cyl(p1, p1 + Vector((math.cos(a + 0.8) * 0.5, math.sin(a + 0.8) * 0.5, 0.45)), 0.035, 0.0, 3, mul(bark, 1.2), caps=False)
    return km


def bone_ribs(name="bone_ribs", seed=2):
    km = KM(name, seed)
    km.ao_dist = 0.5
    km.ground = 0.15
    km.cyl((-1.3, 0, 0.12), (1.3, 0.05, 0.20), 0.085, 0.07, 5, mul(BONE, 0.92))
    for i in range(6):
        x = -1.0 + i * 0.4
        prev = Vector((x, 0.0, 0.16))
        for j in range(7):
            a = math.pi * (j + 1) / 7
            cur = Vector((x + j * 0.012, -math.cos(a) * 0.68 + 0.0, 0.16 + math.sin(a) * (0.82 - abs(i - 2.5) * 0.09)))
            km.cyl(prev, cur, 0.06 * (1 - j * 0.09), 0.055 * (1 - (j + 1) * 0.09), 4, mul(BONE, 0.95 + 0.01 * j), caps=False)
            prev = cur
    km.blob((1.45, 0.0, 0.2), (0.28, 0.2, 0.2), BONE, sub=1, noise=0.12, seed=3)
    return km


def registry():
    return {
        "flat_tree_a": lambda: flat_tree("flat_tree_a", 4, 4.2, 3.4),
        "flat_tree_b": lambda: flat_tree("flat_tree_b", 9, 3.2, 2.7),
        "reach_shrub": lambda: reach_shrub("reach_shrub", 2),
        "reach_shrub_b": lambda: reach_shrub("reach_shrub_b", 6),
        "lichen_mat": lambda: lichen_mat("lichen_mat", 3),
        "lichen_terrace": lambda: lichen_terrace("lichen_terrace", 5),
        "dead_tree": lambda: dead_tree("dead_tree", 7),
        "bone_ribs": lambda: bone_ribs("bone_ribs"),
    }
