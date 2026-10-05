"""The Lumen Depths kit: crystal spires, glow colonies, lantern kelp, glass bloom, bell-moss, basalt columns, hanging walkway, den."""
import math
import random
from mathutils import Vector
from kitlib import *

TAU = math.tau
BASALT = (0.12, 0.15, 0.23)
BASALT_D = (0.07, 0.09, 0.15)
SHELF = (0.20, 0.28, 0.38)
CRYST = (0.30, 0.50, 0.85)
CYAN = (0.42, 0.82, 0.92)
PALE = (0.74, 0.90, 0.86)
GOLD = (0.92, 0.86, 0.55)
PINK = (0.85, 0.50, 0.70)
TEAL = (0.20, 0.62, 0.62)


def crystal_prism(km, base, top, r, tip_len, col_lo, col_hi, mat=1, seg=6, rot0=0.0):
    """Hex prism from base to top with a pointed termination; vertex colours fade lo -> hi along the length."""
    base, top = Vector(base), Vector(top)
    ax = (top - base)
    L = ax.length
    d = ax.normalized()
    ref = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
    u = d.cross(ref).normalized()
    v = d.cross(u).normalized()
    tip = top + d * tip_len
    ring0 = [base + (u * math.cos(rot0 + TAU * i / seg) + v * math.sin(rot0 + TAU * i / seg)) * r for i in range(seg)]
    ring1 = [top + (u * math.cos(rot0 + TAU * i / seg) + v * math.sin(rot0 + TAU * i / seg)) * r * 0.92 for i in range(seg)]
    mid = (base + top) / 2
    for i in range(seg):
        j = (i + 1) % seg
        shade = 0.82 + 0.3 * math.cos(TAU * i / seg + 0.7)       # facet-to-facet brightness for a faceted glassy read
        c0 = mul(col_lo, shade)
        c1 = mul(mix(col_lo, col_hi, 0.75), shade)
        km.poly([ring0[i], ring0[j], ring1[j], ring1[i]], [c0, c0, c1, c1], None, mat, out=mid)
        km.poly([ring1[i], ring1[j], tip], [c1, c1, mul(col_hi, shade * 1.1)], None, mat, out=mid)


def spire(name, seed, n=5, H=8.0, R=1.6, big=False):
    km = KM(name, seed)
    km.ao_dist = 1.0
    km.ground = 0.6
    km.dust = 0.0
    rng = random.Random(seed)
    # basalt/shelf base mound (dark)
    km.blob((0, 0, 0.25), (R * 1.15, R * 1.05, 0.5), BASALT, sub=2, noise=0.2, seed=seed,
            colfn=lambda nn: mix(BASALT_D, SHELF, max(0, nn.z) * 0.5), flat_bottom=-0.05)
    for i in range(n):
        a = TAU * i / n + rng.uniform(-0.3, 0.3)
        d = rng.uniform(0.0, R * 0.55) if i else 0.0
        h = H * (rng.uniform(0.35, 0.8) if i else 1.0)
        r = (0.28 + 0.1 * rng.random()) * (H / 8.0) ** 0.5 * (1.4 if i == 0 else 1.0)
        lean = rng.uniform(0.04, 0.3) if i else 0.03
        b = Vector((math.cos(a) * d, math.sin(a) * d, 0.2))
        t = b + Vector((math.cos(a) * lean * h, math.sin(a) * lean * h, h))
        crystal_prism(km, b, t, r, r * 2.4, mix(BASALT, CRYST, 0.25 + 0.2 * rng.random()), mix(CYAN, PALE, rng.random() * 0.6), rot0=rng.random())
    return km


def colony(name="glow_colony", seed=60):
    """Bioluminescent colony: a basalt knuckle studded with glowing bulbs on short stalks (rhythm = language)."""
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.2
    rng = random.Random(seed)
    km.blob((0, 0, 0.35), (1.0, 0.9, 0.55), BASALT, sub=2, noise=0.25, seed=seed,
            colfn=lambda nn: mix(BASALT_D, SHELF, max(0, nn.z) * 0.4), flat_bottom=-0.05)
    cols = [GOLD, CYAN, PINK, (0.7, 1.0, 0.7)]
    for i in range(13):
        a = rng.uniform(0, TAU)
        d = rng.uniform(0.0, 0.8)
        h = rng.uniform(0.25, 0.9)
        b = Vector((math.cos(a) * d, math.sin(a) * d, 0.5))
        t = b + Vector((math.cos(a) * 0.15, math.sin(a) * 0.15, h))
        km.cyl(b, t, 0.04, 0.025, 4, mix(BASALT, TEAL, 0.5), caps=False)
        c = cols[(i + seed) % 2 if i % 4 else 2]
        r = rng.uniform(0.07, 0.17)
        km.blob(t + Vector((0, 0, r * 0.7)), (r, r, r * 1.2), c, sub=1, noise=0.05, seed=i, mat=1)
    return km


def kelp(name="lantern_kelp", seed=61, H=5.0):
    km = KM(name, seed)
    km.ao_dist = 0.3
    rng = random.Random(seed)
    for k in range(4):
        a = TAU * k / 4 + rng.uniform(-0.4, 0.4)
        base = Vector((math.cos(a) * 0.35, math.sin(a) * 0.35, 0))
        h = H * rng.uniform(0.7, 1.0)
        prev = base
        n = 8
        for i in range(1, n + 1):
            u = i / n
            sway = math.sin(u * 3.0 + k) * 0.4 * u
            cur = base + Vector((math.cos(a + 1.2) * sway, math.sin(a + 1.2) * sway, h * u))
            r0 = 0.07 * (1 - (i - 1) / n) + 0.015
            r1 = 0.07 * (1 - i / n) + 0.015
            km.cyl(prev, cur, r0, r1, 4, mix(mul(TEAL, 0.5), TEAL, u), caps=False)
            if i in (3, 5, 7):
                km.blob(cur + Vector((math.cos(a) * 0.12, math.sin(a) * 0.12, 0)), (0.11, 0.11, 0.16), mix(GOLD, (0.8, 1.0, 0.6), rng.random()), sub=1, noise=0.0, seed=i, mat=1)
            prev = cur
    return km


def bloom(name="glass_bloom", seed=62):
    km = KM(name, seed)
    km.ao_dist = 0.3
    rng = random.Random(seed)
    for f in range(3):
        a = rng.uniform(0, TAU)
        d = rng.uniform(0.0, 0.5)
        base = Vector((math.cos(a) * d, math.sin(a) * d, 0))
        h = rng.uniform(0.8, 1.7)
        top = base + Vector((0.1 * math.cos(a), 0.1 * math.sin(a), h))
        km.cyl(base, top, 0.035, 0.025, 4, mix(TEAL, BASALT, 0.3), caps=False)
        for p in range(6):
            pa = TAU * p / 6
            tip = top + Vector((math.cos(pa) * 0.34, math.sin(pa) * 0.34, 0.28))
            l1 = top + Vector((math.cos(pa - 0.3) * 0.12, math.sin(pa - 0.3) * 0.12, 0.05))
            l2 = top + Vector((math.cos(pa + 0.3) * 0.12, math.sin(pa + 0.3) * 0.12, 0.05))
            km.poly([l1, l2, tip], [PALE, PALE, mix(CYAN, PALE, 0.4)], None, 1)
            km.poly([l2, l1, tip], [PALE, PALE, mix(CYAN, PALE, 0.4)], None, 1)
        km.blob(top + Vector((0, 0, 0.05)), (0.07, 0.07, 0.07), GOLD, sub=1, noise=0, seed=f, mat=1)
    return km


def bell_moss(name="bell_moss", seed=63):
    km = KM(name, seed)
    km.ao_dist = 0.3
    rng = random.Random(seed)
    km.blob((0, 0, 0.12), (0.7, 0.6, 0.18), mul(TEAL, 0.45), sub=2, noise=0.2, seed=seed,
            colfn=lambda nn: mix(mul(TEAL, 0.35), mul(TEAL, 0.8), max(0, nn.z)), flat_bottom=0.0)
    for i in range(12):
        a = rng.uniform(0, TAU)
        d = rng.uniform(0.0, 0.55)
        r = rng.uniform(0.05, 0.11)
        c = (math.cos(a) * d, math.sin(a) * d, 0.25 + r * 0.6)
        km.blob(c, (r, r, r * 1.2), mix(TEAL, GOLD, rng.random() * 0.4), sub=1, noise=0.05, seed=i, mat=1 if i % 3 == 0 else 0)
    return km


def basalt_cols(name="basalt_cols", seed=64, n=14, R=2.2, H=3.0):
    """Wet basalt column field (hexagonal prisms of varying height) -- the mineral forest's floor."""
    km = KM(name, seed)
    km.ao_dist = 0.8
    km.ground = 0.0
    km.sharp = 20
    rng = random.Random(seed)
    placed = []
    sp = 0.78
    rows = 4
    for i in range(-rows, rows + 1):
        for j in range(-rows, rows + 1):
            x = (i + j * 0.5) * sp * 1.0
            y = j * sp * 0.866
            dd = math.hypot(x, y)
            if dd > R:
                continue
            h = H * rng.uniform(0.15, 1.0) * (1.0 - dd / (R * 1.3))
            if h < 0.2:
                continue
            c = mix(BASALT_D, SHELF, rng.uniform(0.0, 0.5))
            top = (x, y, h)
            ring0 = [Vector((x + math.cos(TAU * k / 6) * sp * 0.52, y + math.sin(TAU * k / 6) * sp * 0.52, 0)) for k in range(6)]
            ring1 = [Vector((p.x, p.y, h + rng.uniform(-0.05, 0.05))) for p in ring0]
            for k in range(6):
                m = (k + 1) % 6
                km.poly([ring0[k], ring0[m], ring1[m], ring1[k]], [mul(c, 0.7), mul(c, 0.7), c, c], out=(x, y, h / 2))
            km.poly(ring1, [mul(mix(c, CRYST, 0.25), 1.2)] * 6)
    return km


def walkway(name="hanging_walkway", seed=65, L=6.0, W=1.6):
    """Woven rope/silk walkway segment (along X, deck top ~0): plank deck, sagging side ropes, lantern posts."""
    km = KM(name, seed)
    km.ao_dist = 0.5
    rng = random.Random(seed)
    n = 12
    for i in range(n):
        x = -L / 2 + L * (i + 0.5) / n
        sag = -0.18 * math.sin(math.pi * (i + 0.5) / n)
        km.box((x, 0, sag - 0.04), (L / n - 0.05, W, 0.08), jit(mix(WOOD, (0.55, 0.45, 0.35), rng.random()), rng, 0.08), decal="plank" if i % 3 == 0 else None, decal_face="+z")
    for s in (-1, 1):
        prev = None
        for i in range(0, 13):
            u = i / 12
            p = Vector((-L / 2 + L * u, s * (W / 2 + 0.05), 0.95 - 0.18 * math.sin(math.pi * u)))
            if prev:
                km.cyl(prev, p, 0.03, 0.03, 4, ROPE, caps=False)
            if i % 3 == 0:
                km.cyl(Vector((p.x, p.y, p.z - 0.95 + 0.0)), p, 0.025, 0.025, 4, mul(ROPE, 0.9), caps=False)
            prev = p
        # lantern post at each end
        for ex in (-1, 1):
            b = Vector((ex * L / 2, s * (W / 2 + 0.05), -0.05))
            km.cyl(b, b + Vector((0, 0, 1.5)), 0.05, 0.04, 5, WOOD_D)
            km.blob(b + Vector((0, 0, 1.62)), (0.1, 0.1, 0.13), GOLD, sub=1, noise=0, seed=1, mat=1)
    for k in range(3):
        km.cyl(Vector((-L / 2 + L * (k + 1) / 4, 0, -0.1)), Vector((-L / 2 + L * (k + 1) / 4 + 0.1, 0, -1.5)), 0.015, 0.015, 3, ROPE, caps=False)
    return km


def den(name="sleeping_den", seed=66):
    """A dark hollow in the rock: arch mouth, claw-scarred threshold, a dim violet glow far inside (light disturbs it)."""
    km = KM(name, seed)
    km.ao_dist = 2.0
    km.ground = 0.8
    rng = random.Random(seed)
    for sx in (-1, 1):
        km.blob((sx * 2.4, 0.4, 1.8), (1.6, 1.4, 2.0), BASALT, sub=2, noise=0.25, seed=seed + sx,
                colfn=lambda nn: mix(BASALT_D, SHELF, max(0, nn.z) * 0.4))
    km.blob((0, 0.5, 3.8), (3.6, 1.6, 1.1), BASALT, sub=2, noise=0.22, seed=seed + 5,
            colfn=lambda nn: mix(BASALT_D, SHELF, max(0, nn.z) * 0.4))
    km.box((0, 1.4, 1.5), (3.0, 0.2, 3.0), (0.01, 0.01, 0.03))                 # the dark
    km.blob((0.4, 1.3, 0.9), (0.18, 0.04, 0.1), (0.62, 0.34, 0.9), sub=1, noise=0, seed=1, mat=1)  # a slit of violet far inside
    km.blob((-0.3, 1.3, 0.95), (0.18, 0.04, 0.1), (0.62, 0.34, 0.9), sub=1, noise=0, seed=2, mat=1)
    for i in range(4):
        km.blob((rng.uniform(-2, 2), -rng.uniform(0.3, 1.5), 0.1), (0.2, 0.08, 0.06), BONE, sub=1, noise=0.2, seed=i)
    return km


def shelf_slab(name="mineral_shelf", seed=67):
    """Stack of crystalline plates (a ledge that rings when struck): glinting pale edges."""
    km = KM(name, seed)
    km.ao_dist = 0.8
    km.sharp = 25
    rng = random.Random(seed)
    for i in range(5):
        n = rng.choice([6, 7, 8])
        a0 = rng.uniform(0, TAU)
        r = 2.6 - i * 0.45 + rng.uniform(-0.2, 0.2)
        z0, z1 = 0.0 + i * 0.28, 0.3 + i * 0.28
        top, bot = [], []
        for k in range(n):
            a = a0 + TAU * k / n
            q = r * rng.uniform(0.85, 1.1)
            top.append(Vector((math.cos(a) * q * 0.96, math.sin(a) * q * 0.96, z1)))
            bot.append(Vector((math.cos(a) * q, math.sin(a) * q, z0)))
        c = mix(SHELF, CRYST, 0.18 * i)
        km.poly(top, [mul(c, 1.15)] * n)
        for k in range(n):
            m = (k + 1) % n
            km.poly([bot[k], bot[m], top[m], top[k]], [mul(c, 0.7), mul(c, 0.7), mix(c, PALE, 0.35), mix(c, PALE, 0.35)], out=(0, 0, z0))
    return km


def registry():
    return {
        "lumen_spire_a": lambda: spire("lumen_spire_a", 70, 5, 8.0, 1.6),
        "lumen_spire_b": lambda: spire("lumen_spire_b", 71, 4, 5.0, 1.2),
        "lumen_spire_c": lambda: spire("lumen_spire_c", 72, 6, 2.6, 0.9),
        "lumen_spire_big": lambda: spire("lumen_spire_big", 73, 6, 22.0, 3.2),
        "glow_colony": lambda: colony("glow_colony"),
        "lantern_kelp": lambda: kelp("lantern_kelp"),
        "glass_bloom": lambda: bloom("glass_bloom"),
        "bell_moss": lambda: bell_moss("bell_moss"),
        "basalt_cols": lambda: basalt_cols("basalt_cols"),
        "hanging_walkway": lambda: walkway("hanging_walkway"),
        "sleeping_den": lambda: den("sleeping_den"),
        "mineral_shelf": lambda: shelf_slab("mineral_shelf"),
    }
