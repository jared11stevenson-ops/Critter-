"""Terrarium One (hub) kit: Scale Transition Array gate, ducts with spore growth, planters, tanks, lamp strings."""
import math
import random
from mathutils import Vector
from kitlib import *

TAU = math.tau
BRASS = (0.66, 0.52, 0.34)
BRASS_D = (0.44, 0.34, 0.24)
STEEL = (0.42, 0.44, 0.48)
STEEL_D = (0.26, 0.27, 0.30)
TEAL = (0.30, 0.55, 0.52)
MOSS = (0.34, 0.52, 0.30)
SPORE = (0.55, 1.0, 0.82)
LAMP = (1.0, 0.82, 0.45)
PATINA = (0.36, 0.58, 0.50)


def scale_array(name="scale_array", seed=40):
    """Scale Transition Array (the Gate): segmented coil ring on a hazard-striped cradle. Faces -Y. Origin at ground centre."""
    km = KM(name, seed)
    km.ao_dist = 1.6
    km.ground = 0.8
    km.sharp = 40
    rng = random.Random(seed)
    # cradle: octagonal dais, steps, hazard rim
    km.lathe((0, 0, 0), [(5.3, 0.0), (5.1, 0.35), (4.6, 0.5), (4.5, 0.7)], 16, lambda t: mix(STEEL_D, STEEL, t))
    km.lathe((0, 0, 0.7), [(4.5, 0.0), (4.4, 0.12), (3.6, 0.14)], 16, mul(STEEL, 0.9))
    seg = 16
    for i in range(seg):
        if i % 2 == 0:
            a0, a1 = TAU * i / seg, TAU * (i + 1) / seg
            P = lambda r, a: Vector((math.cos(a) * r, math.sin(a) * r, 0.52))
            km.poly([P(4.62, a0), P(4.62, a1), P(5.05, a1), P(5.05, a0)], DOM_RED)
    # ring: 12 coil segments (copper windings) between brass clamps; ring axis = Y, ring centre z=4.3
    R = 3.5
    cz = 4.3
    n = 12
    for i in range(n):
        a0 = TAU * i / n + 0.05
        a1 = TAU * (i + 1) / n - 0.05
        p0 = Vector((math.cos(a0) * R, 0, cz + math.sin(a0) * R))
        p1 = Vector((math.cos(a1) * R, 0, cz + math.sin(a1) * R))
        km.cyl(p0, p1, 0.42, 0.42, 8, mix(BRASS_D, (0.72, 0.42, 0.24), 0.5 + 0.2 * (i % 2)))
        # winding bands
        for k in range(1, 5):
            u = k / 5
            pp = p0.lerp(p1, u)
            km.torus(pp, 0.44, 0.07, 8, 4, mix((0.72, 0.42, 0.24), BRASS, 0.3), axis="y") if False else None
        # clamp
        c = Vector((math.cos(a1 + 0.05) * R, 0, cz + math.sin(a1 + 0.05) * R))
        km.box(c, (0.5, 1.1, 0.5), BRASS, rot=0.0, taper=0.0) if False else km.cyl(c + Vector((0, -0.55, 0)), c + Vector((0, 0.55, 0)), 0.36, 0.36, 8, mul(BRASS, 1.1))
        # capacitor drum on every other joint, outside the ring
        if i % 2 == 0:
            o = Vector((math.cos(a1 + 0.05) * (R + 0.9), -0.0, cz + math.sin(a1 + 0.05) * (R + 0.9)))
            km.cyl(o + Vector((0, -0.45, 0)), o + Vector((0, 0.45, 0)), 0.28, 0.28, 8, mul(STEEL, 1.05))
            km.cyl(c, o, 0.06, 0.06, 4, STEEL_D, caps=False)
    # inner glow ring (membrane lip)
    km.torus((0, 0, cz), R - 0.55, 0.1, 24, 5, THOUGHT, axis="y", mat=1)
    # feet / struts to the dais
    for sx in (-1, 1):
        km.box((sx * 2.9, 0, 1.55), (0.9, 1.4, 1.7), STEEL_D, taper=0.2)
        km.cyl((sx * 3.1, 0, 1.4), (sx * 3.0, 0, 3.2), 0.28, 0.3, 6, STEEL)
    # control pylon with screen (glow) and chevron base, to the side
    km.box((6.0, -1.2, 0.9), (1.0, 0.8, 1.8), STEEL_D, decal="stencil", decal_face="-y")
    km.box((6.0, -1.5, 1.35), (0.75, 0.05, 0.5), SPORE, mat=1)
    # cable runs
    for k in range(4):
        a = TAU * (0.12 + 0.08 * k)
        km.cyl((math.cos(a) * 4.6, math.sin(a) * 4.6, 0.7), (6.0, -1.0, 0.8), 0.07, 0.07, 4, GUN_D, caps=False)
    return km


def duct(name="hub_duct", seed=41, L=6.0):
    """Ventilation duct run along X with flanges, grille vents and spore/moss growth (the ecosystem inside the lab)."""
    km = KM(name, seed)
    km.ao_dist = 0.7
    km.ground = 0.0
    rng = random.Random(seed)
    km.box((0, 0, 0), (L, 0.9, 0.9), STEEL, decal="rust", decal_face="-y")
    for i in range(5):
        x = -L / 2 + (i + 0.5) * L / 5
        km.box((x, 0, 0), (0.14, 1.06, 1.06), STEEL_D)
        if i % 2 == 0:
            km.box((x + 0.55, -0.46, 0), (0.7, 0.06, 0.6), STEEL_D)   # grille plate
            for g in range(4):
                km.box((x + 0.55, -0.50, -0.2 + g * 0.13), (0.62, 0.04, 0.05), BRASS_D)
    # moss / spore growths creeping from the vents
    for i in range(7):
        x = rng.uniform(-L / 2 + 0.3, L / 2 - 0.3)
        z = rng.choice([0.5, -0.5, 0.0])
        km.blob((x, -0.5 + rng.uniform(0, 0.1), z - 0.15), (rng.uniform(0.15, 0.32), 0.12, rng.uniform(0.12, 0.25)), MOSS, sub=1, noise=0.25, seed=i,
                colfn=lambda n: mix(mul(MOSS, 0.75), (0.62, 0.78, 0.40), max(0, n.z)))
        if i % 3 == 0:
            km.blob((x, -0.58, z - 0.05), (0.06, 0.06, 0.09), SPORE, sub=1, noise=0.0, seed=i, mat=1)
    # drip streaks
    km.box((0.3, -0.455, 0), (0.1, 0.012, 0.7), mul(PATINA, 0.7))
    # hanger rods
    for sx in (-1, 1):
        km.cyl((sx * L * 0.35, 0, 0.45), (sx * L * 0.35, 0, 1.6), 0.03, 0.03, 4, STEEL_D, caps=False)
    return km


def planter(name="hub_planter", seed=42, W=2.2, D=1.0):
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.2
    rng = random.Random(seed)
    km.box((0, 0, 0.4), (W, D, 0.8), BRASS_D, taper=0.0, decal="rust", decal_face="-y")
    km.box((0, 0, 0.82), (W + 0.12, D + 0.12, 0.08), BRASS)
    km.box((0, 0, 0.78), (W - 0.1, D - 0.1, 0.06), (0.30, 0.20, 0.15))
    for i in range(9):
        x = rng.uniform(-W / 2 + 0.2, W / 2 - 0.2)
        y = rng.uniform(-D / 2 + 0.2, D / 2 - 0.2)
        h = rng.uniform(0.4, 1.1)
        a = rng.uniform(0, TAU)
        c = mix(MOSS, (0.55, 0.72, 0.36), rng.random())
        km.cyl((x, y, 0.8), (x + math.cos(a) * 0.3, y + math.sin(a) * 0.3, 0.8 + h), 0.06, 0.0, 4, c, caps=False, cols=[mul(c, 0.7), c, mul(c, 1.1), c])
        if i % 3 == 0:
            km.blob((x + math.cos(a) * 0.3, y + math.sin(a) * 0.3, 0.9 + h), (0.1, 0.1, 0.07), SPORE, sub=1, noise=0.0, seed=i, mat=1)
    km.blob((0, 0, 0.9), (W * 0.35, D * 0.35, 0.12), mul(MOSS, 0.85), sub=1, noise=0.2, seed=3)
    return km


def lamp_string(name="hub_lamp_string", seed=43, L=7.0, n=8):
    km = KM(name, seed)
    km.ao_dist = 0.3
    rng = random.Random(seed)
    prev = Vector((-L / 2, 0, 0))
    for i in range(1, 25):
        u = i / 24
        cur = Vector((-L / 2 + L * u, 0, -0.9 * math.sin(math.pi * u)))
        km.cyl(prev, cur, 0.02, 0.02, 3, GUN_D, caps=False)
        prev = cur
    for i in range(n):
        u = (i + 0.5) / n
        p = Vector((-L / 2 + L * u, 0, -0.9 * math.sin(math.pi * u) - 0.12))
        c = rng.choice([LAMP, (0.7, 1.0, 0.85), (1.0, 0.7, 0.55), (0.75, 0.8, 1.0)])
        km.cyl(p + Vector((0, 0, 0.1)), p, 0.03, 0.03, 3, GUN_D, caps=False)
        km.blob(p - Vector((0, 0, 0.1)), (0.1, 0.1, 0.13), c, sub=1, noise=0.0, seed=i, mat=1)
    return km


def tank(name="hub_tank", seed=44):
    """Specimen tank: brass frame, dark teal water slab, bright life-form glow blobs."""
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.2
    rng = random.Random(seed)
    km.box((0, 0, 0.45), (1.8, 1.0, 0.9), BRASS_D, decal="rust", decal_face="-y")
    for sx in (-1, 1):
        for sy in (-1, 1):
            km.cyl((sx * 0.85, sy * 0.45, 0.9), (sx * 0.85, sy * 0.45, 2.3), 0.05, 0.05, 5, BRASS)
    km.box((0, 0, 2.32), (1.8, 1.0, 0.1), BRASS)
    km.box((0, 0, 1.6), (1.6, 0.86, 1.34), (0.14, 0.30, 0.32))   # water volume (opaque dark teal)
    for i in range(4):
        km.blob((rng.uniform(-0.5, 0.5), -0.3, 1.2 + rng.uniform(0, 0.8)), (0.12, 0.06, 0.08), (0.6, 1.0, 0.9), sub=1, noise=0.1, seed=i, mat=1)
    km.blob((0.2, 0, 1.0), (0.4, 0.3, 0.22), MOSS, sub=1, noise=0.25, seed=5)
    return km


def crate_stack(name="hub_crates", seed=45):
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.3
    rng = random.Random(seed)
    cols = [WOOD, TEAL, STEEL, (0.72, 0.30, 0.22), (0.80, 0.62, 0.30)]
    items = [(0, 0, 0, 1.0, 0.9, 0.8), (1.1, 0.1, 0, 0.8, 0.8, 0.8), (0.1, 0.05, 0.8, 0.9, 0.8, 0.7), (-1.0, 0.2, 0, 0.7, 0.7, 0.6)]
    for (x, y, z, sx, sy, sz) in items:
        c = rng.choice(cols)
        km.box((x, y, z + sz / 2), (sx, sy, sz), c, rot=rng.uniform(-0.2, 0.2), decal=rng.choice(["stencil", "hazard", "rust", "wood"]), decal_face="-y", jitter=0.008)
    return km


def hub_pipes(name="hub_pipes", seed=46, L=5.0):
    km = KM(name, seed)
    km.ao_dist = 0.4
    rng = random.Random(seed)
    for k, (y, z, r, c) in enumerate([(0.0, 0.0, 0.14, BRASS), (0.0, 0.34, 0.1, PATINA), (0.0, 0.6, 0.18, STEEL), (0.0, -0.3, 0.07, DOM_RED)]):
        km.cyl((-L / 2, y, z), (L / 2, y, z), r, r, 7, c)
        for i in range(4):
            x = -L / 2 + (i + 0.5) * L / 4
            km.cyl((x - 0.05, y, z), (x + 0.05, y, z), r * 1.35, r * 1.35, 7, mul(c, 0.7))
    for i in range(3):
        x = -L / 2 + (i + 0.5) * L / 3
        km.box((x, 0.12, 0.15), (0.1, 0.06, 1.2), STEEL_D)
    return km


def registry():
    return {
        "scale_array": lambda: scale_array("scale_array"),
        "hub_duct": lambda: duct("hub_duct"),
        "hub_planter": lambda: planter("hub_planter"),
        "hub_lamp_string": lambda: lamp_string("hub_lamp_string"),
        "hub_tank": lambda: tank("hub_tank"),
        "hub_crates": lambda: crate_stack("hub_crates"),
        "hub_pipes": lambda: hub_pipes("hub_pipes"),
    }
