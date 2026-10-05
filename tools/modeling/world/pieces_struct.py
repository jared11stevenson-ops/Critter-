"""Spanwright / Dominion / settlement structure kit."""
import math
import random
from mathutils import Vector
from kitlib import *

TAU = math.tau


def _stone(rng, base=STONE, amt=0.08):
    return jit(mix(base, OCHRE, rng.uniform(0, 0.35)), rng, amt)


def ellipse_arch(L, rise, spring_z, u):
    a = math.pi * u
    return (-math.cos(a) * L * 0.5, spring_z + math.sin(a) * rise)


def span_bay(name="span_bay", L=13.0, W=7.0, seed=3, broken=False):
    """One bay of the Ochre Span. Local frame: +X along the span, deck top at z=0, centred on x=0."""
    km = KM(name, seed)
    km.dust = 0.25
    km.ao_dist = 1.6
    km.sharp = 35
    rng = random.Random(seed)
    hw = W / 2
    thick = 1.1
    # deck slab: paving courses (5 blocks along x, two across)
    nb = 5
    for i in range(nb):
        x0 = -L / 2 + L * i / nb
        for s in (-1, 1):
            c = _stone(rng, SURVEY, 0.07)
            km.box((x0 + L / nb / 2, s * hw * 0.5, -thick / 2 - 0.02 * rng.random()), (L / nb - 0.05, hw - 0.04, thick), c,
                   cols={"+z": mix(c, DUST, 0.3)}, jitter=0.01)
    # cornice bands under the deck edge (glyph band decal on outer faces)
    for s in (-1, 1):
        km.box((0, s * (hw + 0.18), -0.55), (L, 0.36, 0.5), mul(STONE_D, 1.0), decal="glyph", decal_face="-y" if s < 0 else "+y")
    # parapets
    pn = 10
    for s in (-1, 1):
        for i in range(pn):
            if broken and rng.random() < 0.3:
                continue
            x = -L / 2 + L * (i + 0.5) / pn
            h = 0.85 + rng.uniform(-0.05, 0.08)
            c = _stone(rng, SURVEY, 0.08)
            dec = "tally" if (i % 4 == 1 and s > 0) else None
            km.box((x, s * (hw - 0.3), h / 2), (L / pn - 0.06, 0.56, h), c, decal=dec, decal_face="-y", jitter=0.008)
            km.box((x, s * (hw - 0.3), h + 0.07), (L / pn + 0.02, 0.72, 0.14), mul(c, 1.08))
    # arch: intrados ellipse (crown just under the soffit), voussoirs, then coursed spandrel above the extrados
    inner_L = L - 2.2
    ow = W * 0.78
    ac = -5.9                       # ellipse centre z
    bi, bo = 3.7, 4.55              # intrados / extrados semi-heights (crown -2.2 / -1.35)
    ai, ao = inner_L / 2, inner_L / 2 + 0.85
    n = 15
    for i in range(n):
        u0, u1 = i / n, (i + 1) / n
        pt = lambda a_, b_, u: (-math.cos(math.pi * u) * a_, ac + math.sin(math.pi * u) * b_)
        x0, z0 = pt(ai, bi, u0)
        x1, z1 = pt(ai, bi, u1)
        xo0, zo0 = pt(ao, bo, u0)
        xo1, zo1 = pt(ao, bo, u1)
        c = _stone(rng, STONE if i % 2 else SURVEY, 0.08)
        y0, y1 = -ow / 2, ow / 2
        A = [Vector((x0, y0, z0)), Vector((x1, y0, z1)), Vector((xo1, y0, zo1)), Vector((xo0, y0, zo0))]
        B = [Vector((x0, y1, z0)), Vector((x1, y1, z1)), Vector((xo1, y1, zo1)), Vector((xo0, y1, zo0))]
        ctr = (0, 0, ac + 1.0)
        km.poly(A, c, out=(0, 50, 0))
        km.poly(B, mul(c, 0.95), out=(0, -50, 0))
        km.poly([A[0], A[1], B[1], B[0]], mul(c, 0.78), out=(0, 0, ac + 20))      # intrados faces down
        km.poly([A[3], A[2], B[2], B[3]], c, out=(0, 0, ac - 20))
    # springers/abutment blocks flush with the pier sides
    for sx in (-1, 1):
        km.box((sx * (ai + 0.4), 0, ac - 2.0), (0.9, ow, 4.2), _stone(rng, STONE_D, 0.05))
    km.box((0, 0, -thick - 0.15), (L, ow, 0.3), mul(STONE_D, 0.9))     # soffit
    for s in (-1, 1):
        steps = 12
        for i in range(steps):
            x = -L / 2 + L * (i + 0.5) / steps
            u = (x / ao + 1) / 2
            if abs(x) < ao:
                zc = ac + math.sin(math.acos(max(-1.0, min(1.0, -x / ao)))) * bo
            else:
                zc = ac - 1.0
            zt = -thick
            h = zt - zc
            if h < 0.15:
                continue
            courses = max(1, int(h / 0.7))
            for cidx in range(courses):
                ch = h / courses
                km.box((x, s * (ow / 2), zc + ch * (cidx + 0.5)), (L / steps - 0.03, 0.46, ch - 0.03), _stone(rng, STONE, 0.09))
    # keystone glyph + load-limit plaque
    for s in (-1, 1):
        km.box((0, s * (ow / 2 + 0.25), -1.8), (1.5, 0.14, 1.05), mul(OCHRE, 1.05), decal="glyph", decal_face="-y" if s < 0 else "+y")
    return km


def span_pier(name="span_pier", H=7.0, W=7.0, seed=5):
    """Pier shaft section (stack vertically). Origin at the top; extends down -H. Cutwater prow both ends."""
    km = KM(name, seed)
    km.dust = 0.0
    km.ao_dist = 1.4
    rng = random.Random(seed)
    pw = W * 0.8
    n = 4
    for i in range(n):
        z1 = -H * i / n
        z0 = -H * (i + 1) / n
        f1 = 1.0 + 0.012 * i
        f0 = 1.0 + 0.012 * (i + 1)
        c = _stone(rng, STONE, 0.07)
        # octagonal-ish prow plan (hex): elongated across Y
        def ring(f, z):
            pts = []
            for k in range(8):
                a = TAU * k / 8 + TAU / 16
                x = math.cos(a) * 1.5 * f
                y = math.sin(a) * pw * 0.5 * f
                pts.append(Vector((x * (1.4 if abs(math.cos(a)) > 0.9 else 1.0), y, z)))
            return pts
        r1, r0 = ring(f1, z1), ring(f0, z0)
        for k in range(8):
            j = (k + 1) % 8
            km.poly([r0[k], r0[j], r1[j], r1[k]], c, out=(0, 0, (z0 + z1) / 2))
        if i == 0:
            ctr = Vector((0, 0, z1))
            for k in range(8):
                j = (k + 1) % 8
                km.poly([ctr, r1[k], r1[j]], mul(c, 1.1), out=(0, 0, z1 - 50))
        # string course every section
        km.box((0, 0, z1 - 0.12), (3.1, pw + 0.2, 0.24), mul(STONE_D, 1.05))
    km.box((0, -pw * 0.5 - 0.02, -H * 0.5), (2.2, 0.08, H * 0.7), mul(STONE, 1.0), decal="rust", decal_face="-y")
    return km


def span_tower(name="span_tower", seed=6, S=6.0, H=13.0):
    """Spanwright gate tower (battered square tower, crenellations, cresset). Origin at base centre."""
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 2.0
    km.ground = 1.2
    rng = random.Random(seed)
    # plinth steps
    km.box((0, 0, 0.3), (S + 2.2, S + 2.2, 0.6), mul(STONE_D, 0.95))
    km.box((0, 0, 0.8), (S + 1.2, S + 1.2, 0.5), mul(STONE_D, 1.05))
    z = 1.05
    courses = 11
    for k in range(courses):
        ch = (H - 2.4) / courses
        t0 = k / courses
        t1 = (k + 1) / courses
        w0 = S * (1.0 - 0.18 * t0)
        w1 = S * (1.0 - 0.18 * t1)
        c = _stone(rng, SURVEY if k % 3 else STONE, 0.07)
        dec = None
        # one face each: glyph band at 3, tally at 7
        km.box((0, 0, z + ch / 2), (w0 * 0.5 + w1 * 0.5, w0 * 0.5 + w1 * 0.5, ch - 0.02), c, taper=0.0,
               decal="glyph" if k == 8 else ("tally" if k == 4 else None), decal_face="-y", jitter=0.0)
        z += ch
    # corbel + parapet
    km.box((0, 0, z + 0.2), (S * 0.82 + 1.0, S * 0.82 + 1.0, 0.4), mul(STONE_D, 1.0))
    z += 0.4
    for i in range(6):
        for s in (-1, 1):
            off = -S * 0.41 + i * (S * 0.82 / 5)
            km.box((off, s * S * 0.45, z + 0.45), (0.8, 0.7, 0.9), _stone(rng, SURVEY))
            if 0 < i < 5:
                km.box((s * S * 0.45, off, z + 0.45), (0.7, 0.8, 0.9), _stone(rng, SURVEY))
    # cresset bowl (mat 1 = fire glow)
    km.cyl((0, 0, z), (0, 0, z + 0.8), 0.25, 0.25, 5, mul(GUN, 0.8))
    km.blob((0, 0, z + 1.1), (0.55, 0.55, 0.35), (1.0, 0.62, 0.2), sub=1, noise=0.1, seed=1, mat=1)
    # door arch slot on the road-facing side (+Y local): dark niche
    km.box((0, -S * 0.5 + 0.02, 2.0), (1.6, 0.12, 2.6), mul(DEEP, 1.0))
    # banner pole + faded cloth
    km.cyl((S * 0.3, S * 0.3, z), (S * 0.3, S * 0.3, z + 3.2), 0.06, 0.05, 4, WOOD)
    km.box((S * 0.3 + 0.55, S * 0.3, z + 2.5), (1.0, 0.04, 1.2), mix(VERMIL, DUST, 0.3), tilt=(0, 0.1))
    return km


def marker_stone(name="marker_stone", seed=7):
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 1.0
    km.box((0, 0, 0.25), (2.4, 1.8, 0.5), mul(STONE_D, 1.0), jitter=0.02, decal="tally", decal_face="-y")
    km.box((0, 0, 2.5), (1.25, 0.7, 4.0), mix(STONE, OCHRE, 0.3), taper=0.14, tilt=(0.0, 0.035), decal="glyph", decal_face="-y")
    km.box((0, 0, 4.7), (1.55, 0.95, 0.45), mul(STONE, 1.0), tilt=(0, 0.035), decal="glyph", decal_face="-y")
    # glyph inlays (glowing, mat 1)
    for i in range(4):
        km.box((0.0 + (i % 2) * 0.1, -0.37, 1.5 + i * 0.6), (0.5 - (i % 2) * 0.25, 0.04, 0.07), THOUGHT, mat=1)
    return km


def cairn(name="cairn", seed=8, n=8, R=0.9, names=False):
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 0.5
    km.sharp = 28
    rng = random.Random(seed)
    z = 0.0
    for i in range(n):
        r = R * (1.0 - i / (n + 1)) * rng.uniform(0.85, 1.1)
        h = r * rng.uniform(0.35, 0.5)
        c = (rng.uniform(-0.08, 0.08), rng.uniform(-0.08, 0.08))
        tint = rng.choice([STONE, SURVEY, BUFF, RUST])
        km.blob((c[0], c[1], z + h * 0.5), (r, r * rng.uniform(0.8, 1.0), h), tint, sub=2, noise=0.12, seed=seed + i,
                colfn=lambda nn, t=tint: mix(mul(t, 0.9), DUST, max(0, nn.z) * 0.35))
        z += h * 1.55
    if names:
        km.box((0, -R * 0.75, 0.55), (0.9, 0.12, 1.1), mul(SURVEY, 1.1), tilt=(-0.18, 0), decal="tally", decal_face="-y")
        km.box((0.55, -R * 0.62, 0.35), (0.7, 0.1, 0.7), mul(SURVEY, 1.2), tilt=(-0.2, 0.2))  # the blank stone
    return km


def load_post(name="load_post", seed=9):
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 0.6
    km.box((0, 0, 0.7), (0.42, 0.42, 1.4), mix(SURVEY, STONE, 0.4), taper=0.08, decal="tally", decal_face="-y", jitter=0.01)
    km.box((0, 0, 1.46), (0.52, 0.52, 0.14), mul(SURVEY, 1.1))
    km.box((0, 0, 0.12), (0.6, 0.6, 0.24), mul(STONE_D, 1.0))
    return km


def rail_run(name="rail_run", L=4.0, seed=10):
    km = KM(name, seed)
    km.ao_dist = 0.5
    for sx in (-1, 1):
        km.box((sx * L / 2, 0, 0.55), (0.3, 0.3, 1.1), mul(SURVEY, 0.95), taper=0.06)
        km.box((sx * L / 2, 0, 1.15), (0.4, 0.4, 0.1), mul(SURVEY, 1.1))
    # chain sag
    prev = Vector((-L / 2, 0, 0.95))
    for i in range(1, 9):
        u = i / 8
        cur = Vector((-L / 2 + L * u, 0, 0.95 - 0.28 * math.sin(math.pi * u)))
        km.cyl(prev, cur, 0.03, 0.03, 4, GUN_D, caps=False)
        prev = cur
    return km


def well_head(name="well_head", seed=11):
    km = KM(name, seed)
    km.dust = 0.15
    km.ao_dist = 1.0
    km.ground = 0.3
    rng = random.Random(seed)
    # ring wall: three courses of segmented blocks
    seg = 12
    for course in range(3):
        for i in range(seg):
            a0 = TAU * i / seg + course * 0.13
            a1 = TAU * (i + 1) / seg + course * 0.13
            r0, r1 = 0.8, 1.25
            z0, z1 = course * 0.32, (course + 1) * 0.32 - 0.02
            c = _stone(rng, SURVEY, 0.09)
            P = lambda r, a, z: Vector((math.cos(a) * r, math.sin(a) * r, z))
            out = (0, 0, 0.5)
            km.poly([P(r1, a0, z0), P(r1, a1, z0), P(r1, a1, z1), P(r1, a0, z1)], c, out=out)
            km.poly([P(r0, a1, z0), P(r0, a0, z0), P(r0, a0, z1), P(r0, a1, z1)], mul(c, 0.55), out=(0, 0, -50))
            km.poly([P(r0, a0, z1), P(r0, a1, z1), P(r1, a1, z1), P(r1, a0, z1)], mul(c, 1.1), out=(0, 0, -50))
    # dark water disc
    km.poly([Vector((math.cos(TAU * i / 12) * 0.82, math.sin(TAU * i / 12) * 0.82, 0.2)) for i in range(12)], (0.05, 0.09, 0.12))
    # crank frame
    for s in (-1, 1):
        km.cyl((s * 1.15, 0.0, 0.5), (s * 0.95, 0, 3.0), 0.1, 0.08, 5, WOOD)
        km.cyl((s * 1.15, 0.0, 0.5), (s * 1.6, 0.0, 0.0), 0.07, 0.07, 4, WOOD, caps=False)
    km.cyl((-1.1, 0, 2.9), (1.1, 0, 2.9), 0.1, 0.1, 6, mul(WOOD, 1.15), jitter=0.03)
    km.cyl((1.1, 0, 2.9), (1.55, 0, 2.9), 0.04, 0.04, 4, GUN_D)
    km.cyl((1.55, 0, 2.9), (1.55, 0.45, 2.9), 0.05, 0.05, 4, WOOD)
    # rope with tally knots + bucket
    km.cyl((0, 0, 2.8), (0, 0, 0.9), 0.04, 0.04, 4, ROPE, caps=False)
    for k in range(7):
        km.blob((0, 0, 1.0 + k * 0.26), (0.07, 0.07, 0.07), mul(ROPE, 0.9), sub=1, noise=0.1, seed=k)
    km.cyl((0, 0, 0.7), (0, 0, 1.0), 0.2, 0.26, 7, WOOD_D)
    return km


def shade_awning(name="shade_awning", seed=12, W=7.0, D=5.0):
    km = KM(name, seed)
    km.ao_dist = 1.0
    rng = random.Random(seed)
    posts = [(-W / 2, -D / 2, 3.0), (W / 2, -D / 2, 3.0), (-W / 2, D / 2, 2.4), (W / 2, D / 2, 2.4)]
    for (x, y, h) in posts:
        km.cyl((x, y, 0), (x, y, h), 0.13, 0.1, 6, mul(WOOD, 1.05), jitter=0.05)
        km.box((x, y, 0.1), (0.5, 0.5, 0.2), mul(STONE, 0.9))
    for (a, b) in ((0, 1), (2, 3), (0, 2), (1, 3)):
        km.cyl(Vector(posts[a]), Vector(posts[b]), 0.07, 0.07, 5, WOOD_D, caps=False)
    # cloth sheet (sagging) with ochre/rust stripes
    nx, ny = 8, 6
    grid = []
    for i in range(nx + 1):
        row = []
        for j in range(ny + 1):
            u, v = i / nx, j / ny
            x = -W / 2 + W * u
            y = -D / 2 + D * v
            z = 3.0 + (2.4 - 3.0) * v + 0.0 - 0.28 * math.sin(math.pi * u) * math.sin(math.pi * v) + 0.04 * math.sin(u * 20)
            row.append(Vector((x, y, z + 0.12)))
        grid.append(row)
    km.sheet(grid, lambda i, j: mix(CREAM, VERMIL, 0.55 if i % 2 else 0.1), flip=False)
    km.sheet(grid, lambda i, j: mul(mix(CREAM, VERMIL, 0.55 if i % 2 else 0.1), 0.7), flip=True)
    # fringe ropes
    for i in range(0, nx + 1, 2):
        p = grid[i][ny]
        km.cyl(p, p - Vector((0, 0, 0.35)), 0.025, 0.012, 3, ROPE, caps=False)
    return km


def rope_rack(name="rope_rack", seed=13):
    km = KM(name, seed)
    km.ao_dist = 0.6
    rng = random.Random(seed)
    for s in (-1, 1):
        km.cyl((s * 1.3, 0, 0), (s * 0.6, 0, 2.3), 0.09, 0.07, 5, WOOD)
        km.cyl((s * 1.3, 0.0, 0), (s * 1.3, 0.9, 0.0), 0.07, 0.07, 4, WOOD, caps=False)
    km.cyl((-0.65, 0, 2.2), (0.65, 0, 2.2), 0.07, 0.07, 5, WOOD_D)
    for k in range(5):
        x = -0.5 + k * 0.25
        km.torus((x, 0, 1.75), 0.38, 0.06, 10, 4, mix(ROPE, RUST, rng.random() * 0.3), axis="y")
    km.cyl((0.0, 0, 2.2), (0.15, 0.0, 1.0), 0.04, 0.03, 4, ROPE, caps=False)
    km.torus((0.9, 0.5, 0.2), 0.45, 0.08, 10, 4, ROPE, axis="z")
    return km


def vault_door(name="vault_door", seed=14):
    """Sealed Spanwright vault set in the cliff, facing -Y (Godot +Z). Origin at ground centre of the door."""
    km = KM(name, seed)
    km.dust = 0.15
    km.ao_dist = 1.4
    km.ground = 0.8
    rng = random.Random(seed)
    # buttress rock behind (cliff mass)
    km.box((0, 2.6, 4.0), (11.0, 3.4, 8.0), mix(RUST, PLUM, 0.3), jitter=0.2, cols={"-y": mix(RUST, PLUM, 0.2)})
    # jambs + lintel
    km.box((-3.0, 0.6, 3.2), (1.5, 1.4, 6.4), _stone(rng, SURVEY), decal="ashlar", decal_face="-y")
    km.box((3.0, 0.6, 3.2), (1.5, 1.4, 6.4), _stone(rng, SURVEY), decal="ashlar", decal_face="-y")
    km.box((0, 0.6, 6.8), (8.0, 1.4, 1.1), mul(SURVEY, 1.05), decal="glyph", decal_face="-y")
    km.box((0, 0.6, 7.6), (8.6, 1.5, 0.5), mul(SURVEY, 0.9))
    # door slab recessed
    km.box((0, 1.15, 3.0), (4.6, 0.6, 6.0), mix(GUN, STONE_D, 0.6), cols={"-y": mix(GUN, STONE_D, 0.5)})
    # pulse-lock disc (glowing)
    km.box((0, 0.82, 3.3), (2.4, 0.06, 2.4), (1, 1, 1), decal="pulse", decal_face="-y")
    km.box((0, 0.84, 4.9), (3.4, 0.06, 0.6), (1, 1, 1), decal="glyph", decal_face="-y")
    # threshold steps
    km.box((0, -1.2, 0.18), (6.6, 2.4, 0.36), mul(STONE_D, 1.1))
    km.box((0, -0.6, 0.45), (5.6, 1.4, 0.18), mul(STONE_D, 1.2))
    # side rubble
    for sx in (-1, 1):
        km.blob((sx * 4.4, -0.8, 0.5), (1.1, 0.9, 0.5), RUST, sub=1, noise=0.2, seed=sx + 3,
                colfn=lambda n: mix(RUST, DUST, max(0, n.z) * 0.4))
    return km


def crystals(name="thoughtstone_a", seed=15, n=7, H=2.4, R=0.9):
    km = KM(name, seed)
    km.ao_dist = 0.7
    km.dust = 0.0
    rng = random.Random(seed)
    # rock base (inert, dull) + crystal prisms (glow slot)
    km.blob((0, 0, 0.15), (R * 1.15, R * 1.05, 0.3), mix(RUST, PLUM, 0.5), sub=2, noise=0.18, seed=seed,
            colfn=lambda nn: mix(mul(PLUM, 0.9), DUST, max(0, nn.z) * 0.3), flat_bottom=-0.02)
    for i in range(n):
        a = TAU * i / n + rng.uniform(-0.3, 0.3)
        d = rng.uniform(0.0, R * 0.6) if i else 0.0
        h = H * (rng.uniform(0.45, 1.0) if i else 1.0)
        r = 0.16 * (h / H) + 0.1
        lean = rng.uniform(0.05, 0.4) if i else 0.0
        b = Vector((math.cos(a) * d, math.sin(a) * d, 0.1))
        t = b + Vector((math.cos(a) * lean * h, math.sin(a) * lean * h, h))
        mid = b.lerp(t, 0.78)
        c = mix(THOUGHT, (0.85, 0.97, 1.0), rng.random() * 0.6)
        km.cyl(b, mid, r, r * 0.95, 6, c, caps=False, mat=1, rot0=rng.random())
        km.cyl(mid, t, r * 0.95, 0.0, 6, mix(c, (1, 1, 1), 0.3), caps=False, mat=1, rot0=0)
    return km


def cart_wreck(name="cart_wreck", seed=16):
    km = KM(name, seed)
    km.dust = 0.1
    km.ao_dist = 0.8
    km.ground = 0.3
    rng = random.Random(seed)
    # bed (tilted: one wheel gone)
    tl = (0.05, 0.0)
    km.box((0, 0, 1.0), (3.6, 1.7, 0.2), WOOD, tilt=(0.0, 0.14))
    for s in (-1, 1):
        km.box((0, s * 0.86, 1.35), (3.4, 0.12, 0.7), WOOD_D, tilt=(0.0, 0.14))
    km.box((-1.7, 0, 1.4), (0.12, 1.7, 0.8), WOOD_D, tilt=(0.0, 0.14))
    # wheel (standing) + broken wheel (lying)
    def wheel(cx, cy, cz, flat):
        for k in range(10):
            a0 = TAU * k / 10
            a1 = TAU * (k + 1) / 10
            R_ = 0.78
            if flat:
                p0 = Vector((cx + math.cos(a0) * R_, cy + math.sin(a0) * R_, cz))
                p1 = Vector((cx + math.cos(a1) * R_, cy + math.sin(a1) * R_, cz))
            else:
                p0 = Vector((cx + math.cos(a0) * R_, cy, cz + math.sin(a0) * R_))
                p1 = Vector((cx + math.cos(a1) * R_, cy, cz + math.sin(a1) * R_))
            km.cyl(p0, p1, 0.07, 0.07, 4, mul(WOOD_D, 1.1), caps=False)
            if k % 2 == 0:
                km.cyl(Vector((cx, cy, cz)), p0, 0.05, 0.05, 4, WOOD, caps=False)
    wheel(0.9, 1.0, 0.8, False)
    wheel(-1.4, 2.2, 0.08, True)
    # drop axle on ground and broken yoke
    km.cyl((1.9, 0.0, 0.7), (3.6, 0.2, 0.3), 0.08, 0.06, 5, WOOD)
    km.cyl((-1.0, 0.0, 0.0), (-1.0, 1.9, 0.0), 0.06, 0.06, 5, WOOD_D, caps=False)
    # sacks
    for i in range(4):
        km.blob((-0.8 + i * 0.7, rng.uniform(-0.3, 0.3), 1.35), (0.34, 0.28, 0.24), mix(CREAM, BUFF, rng.random()), sub=1, noise=0.12, seed=i)
    return km


def salt_crystals(name="salt_crystals", seed=17):
    km = KM(name, seed)
    km.ao_dist = 0.4
    rng = random.Random(seed)
    for i in range(9):
        a = rng.uniform(0, TAU)
        d = rng.uniform(0, 0.5)
        h = rng.uniform(0.25, 0.8)
        b = Vector((math.cos(a) * d, math.sin(a) * d, 0))
        t = b + Vector((rng.uniform(-0.1, 0.1), rng.uniform(-0.1, 0.1), h))
        r = 0.07 + h * 0.07
        c = mix(SALT, (0.8, 0.9, 0.95), rng.random() * 0.5)
        km.cyl(b, b.lerp(t, 0.8), r, r * 0.9, 5, c, caps=False)
        km.cyl(b.lerp(t, 0.8), t, r * 0.9, 0.0, 5, mul(c, 1.05), caps=False)
    return km


def survey_flag(name="survey_flag", seed=18):
    km = KM(name, seed)
    km.ao_dist = 0.4
    for k in range(3):
        a = TAU * k / 3
        km.cyl((math.cos(a) * 0.55, math.sin(a) * 0.55, 0.0), (math.cos(a) * 0.04, math.sin(a) * 0.04, 1.35), 0.035, 0.028, 4, GUN_D, caps=False)
    km.cyl((0, 0, 0.9), (0, 0, 2.6), 0.032, 0.028, 5, mul(GUN, 1.1))
    km.box((0, 0, 1.45), (0.14, 0.14, 0.26), GUN_D)   # theodolite head
    km.cyl((0.0, 0.0, 1.5), (0.14, 0.0, 1.5), 0.05, 0.05, 5, mul(GUN, 0.8))
    # flag cloth with sigil
    P = [Vector((0.03, 0, 2.55)), Vector((0.85, 0.06, 2.4)), Vector((0.85, 0.08, 1.85)), Vector((0.03, 0, 1.95))]
    km.poly(P, [(1, 1, 1)] * 4, uv=[cell_uv("stencil", 0, 1), cell_uv("stencil", 1, 1), cell_uv("stencil", 1, 0), cell_uv("stencil", 0, 0)])
    km.poly(P[::-1], [mul(DOM_RED, 0.8)] * 4)
    return km


def dom_stack(name="dom_stack", seed=19):
    """Dominion supply stack: crates with hazard bands, drums, tarp."""
    km = KM(name, seed)
    km.ao_dist = 0.6
    km.ground = 0.3
    rng = random.Random(seed)
    for i, (x, y, z, s) in enumerate([(0, 0, 0, 1.2), (1.25, 0.1, 0, 1.0), (0.2, 0.05, 1.2, 0.9), (-1.2, 0.3, 0, 0.9)]):
        km.box((x, y, z + s * 0.45), (s * 1.1, s * 0.9, s * 0.9), mix(GUN, GUN_D, 0.3), rot=rng.uniform(-0.3, 0.3),
               decal="hazard" if i % 2 == 0 else "stencil", decal_face="-y", jitter=0.01)
    for k in range(3):
        km.cyl((2.4 + k * 0.62, 0.4 * (k % 2), 0), (2.4 + k * 0.62, 0.4 * (k % 2), 0.95), 0.27, 0.27, 8,
               mix(DOM_RED, GUN, 0.35 * k), cols=[mix(DOM_RED, GUN, 0.35 * k), mul(mix(DOM_RED, GUN, 0.35 * k), 0.85)])
    km.box((0.4, 0.0, 1.95), (1.9, 1.5, 0.08), mix(GUN, DUST, 0.3), tilt=(0.05, 0.1))
    return km


def floodlight(name="floodlight", seed=20):
    km = KM(name, seed)
    km.ao_dist = 0.4
    km.cyl((0, 0, 0), (0, 0, 7.0), 0.12, 0.08, 6, GUN)
    km.box((0, 0, 0.15), (0.8, 0.8, 0.3), GUN_D)
    km.box((0, -0.15, 7.1), (1.5, 0.3, 0.9), GUN_D)
    km.box((0, -0.34, 7.1), (1.3, 0.04, 0.7), (1.0, 0.92, 0.7), mat=1)
    km.box((0, -0.05, 7.62), (1.6, 0.5, 0.08), DOM_RED)
    return km


def augur_derrick(name="augur_derrick", seed=21, H=36.0, B=11.0):
    """AUGUR deepcore rig: tall lattice derrick over a machine house. Origin at base centre. ~1.9k tris."""
    km = KM(name, seed)
    km.ao_dist = 2.5
    km.ao_amt = 0.5
    km.ground = 1.5
    km.sharp = 50
    rng = random.Random(seed)
    levels = 9
    top_w = B * 0.22
    def half(z):
        return (B * 0.5) + (top_w * 0.5 - B * 0.5) * (z / H)
    legs = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    for sx, sy in legs:
        km.cyl((sx * half(0), sy * half(0), 0), (sx * half(H), sy * half(H), H), 0.38, 0.24, 4, GUN, rot0=0.785, cols=[GUN, GUN_D, mul(GUN, 1.15), GUN_D])
    for k in range(levels + 1):
        z = H * k / levels
        h = half(z)
        col = DOM_RED if k % 3 == 0 else mul(GUN, 0.95)
        for (a, b) in ((0, 1), (1, 2), (2, 3), (3, 0)):
            pa = Vector((legs[a][0] * h, legs[a][1] * h, z))
            pb = Vector((legs[b][0] * h, legs[b][1] * h, z))
            km.cyl(pa, pb, 0.13, 0.13, 3, col, caps=False)
        if k < levels:
            z2 = H * (k + 1) / levels
            h2 = half(z2)
            for (a, b) in ((0, 1), (1, 2), (2, 3), (3, 0)):
                pa = Vector((legs[a][0] * h, legs[a][1] * h, z))
                pb = Vector((legs[b][0] * h2, legs[b][1] * h2, z2))
                km.cyl(pa, pb, 0.08, 0.08, 3, GUN_D, caps=False)
    # crown block + beacon
    km.box((0, 0, H + 0.9), (top_w + 1.2, top_w + 1.2, 1.8), GUN_D)
    km.box((0, 0, H + 2.0), (top_w * 0.7, top_w * 0.7, 0.5), DOM_RED)
    km.blob((0, 0, H + 2.7), (0.45, 0.45, 0.45), (1.0, 0.2, 0.12), sub=1, noise=0.0, seed=1, mat=1)
    # working platform
    zp = H * 0.58
    h = half(zp)
    km.box((0, 0, zp), (h * 2 + 1.4, h * 2 + 1.4, 0.3), mul(GUN, 0.8))
    for (sx, sy) in legs:
        km.cyl((sx * (h + 0.7), sy * (h + 0.7), zp), (sx * (h + 0.7), sy * (h + 0.7), zp + 1.1), 0.05, 0.05, 3, DOM_RED, caps=False)
    # drill string (centre pipe) + travelling block
    km.cyl((0, 0, 1.0), (0, 0, H), 0.28, 0.28, 8, mul(GUN, 1.25))
    for z in range(3, int(H), 6):
        km.cyl((0, 0, z), (0, 0, z + 0.7), 0.4, 0.4, 8, mul(GUN, 0.8))
    # machine house
    km.box((0, -B * 0.95, 1.9), (B * 0.9, 5.4, 3.8), mix(GUN, GUN_D, 0.4), decal="stencil", decal_face="-y")
    km.box((0, -B * 0.95, 3.95), (B * 0.98, 5.7, 0.3), GUN_D)
    km.box((-B * 0.2, -B * 0.95 - 2.75, 1.0), (3.0, 0.1, 1.6), (1, 1, 1), decal="hazard", decal_face="-y")
    # pipe rack leaning at the side
    for i in range(7):
        km.cyl((B * 0.9, -2 + i * 0.42, 0.2), (B * 0.9 + 3.6, -2 + i * 0.42, 1.2), 0.18, 0.18, 6, mul(GUN, 0.95 + 0.04 * (i % 3)))
    # anchor guy cables
    for sx, sy in legs:
        km.cyl((sx * half(H * 0.8), sy * half(H * 0.8), H * 0.8), (sx * (B * 1.3), sy * (B * 1.3), 0.2), 0.04, 0.04, 3, GUN_D, caps=False)
    return km


def bore_collar(name="bore_collar", seed=22, R=6.0):
    km = KM(name, seed)
    km.dust = 0.1
    km.ao_dist = 2.0
    km.ground = 0.8
    seg = 20
    prof_out = [(R * 1.35, 0.0), (R * 1.15, 0.45), (R * 1.05, 0.95), (R * 0.82, 0.95)]
    km.lathe((0, 0, 0), prof_out, seg, lambda t: mix(GUN, DUST, 0.35 * (1 - t)))
    # inner wall straight down into darkness
    km.lathe((0, 0, 0), [(R * 0.82, 0.95), (R * 0.8, -3.0), (R * 0.7, -9.0)], seg, lambda t: (0.06, 0.04, 0.05))
    # hazard stripe ring segments
    for i in range(seg):
        if i % 2 == 0:
            a0, a1 = TAU * i / seg, TAU * (i + 1) / seg
            r0, r1 = R * 0.84, R * 1.04
            P = lambda r, a: Vector((math.cos(a) * r, math.sin(a) * r, 0.97))
            km.poly([P(r0, a0), P(r0, a1), P(r1, a1), P(r1, a0)], DOM_RED)
    for i in range(8):
        a = TAU * i / 8
        km.cyl((math.cos(a) * R * 1.1, math.sin(a) * R * 1.1, 0.6), (math.cos(a) * R * 1.1, math.sin(a) * R * 1.1, 1.0), 0.28, 0.2, 6, mul(GUN, 1.2))
    return km


def pylon(name="resonance_pylon", seed=23, H=9.0):
    """Dominion resonance pylon: tapered gunmetal spire, red banded, cyan-white resonance coil (glow)."""
    km = KM(name, seed)
    km.ao_dist = 1.2
    km.ground = 0.6
    km.box((0, 0, 0.3), (2.6, 2.6, 0.6), GUN_D)
    km.cyl((0, 0, 0.6), (0, 0, H), 0.62, 0.16, 6, GUN, cols=[GUN, mul(GUN, 0.8), mul(GUN, 1.15)])
    for k in range(4):
        z = 1.6 + k * 1.8
        r = 0.62 - (z / H) * 0.46 + 0.14
        km.torus((0, 0, z), r, 0.1, 10, 4, DOM_RED if k % 2 == 0 else mul(GUN, 1.3))
    km.blob((0, 0, H + 0.3), (0.34, 0.34, 0.55), (1.0, 0.3, 0.2), sub=1, noise=0.0, seed=1, mat=1)
    for s in range(3):
        a = TAU * s / 3
        km.cyl((math.cos(a) * 1.2, math.sin(a) * 1.2, 0.2), (math.cos(a) * 0.3, math.sin(a) * 0.3, 3.6), 0.12, 0.08, 4, GUN_D, caps=False)
    return km


def glyph_wall(name="glyph_wall", seed=24):
    """Echo Hollow wall: a slab of cliff with Spanwright maintenance marks. Faces -Y."""
    km = KM(name, seed)
    km.dust = 0.1
    km.ao_dist = 1.2
    rng = random.Random(seed)
    x = -4.0
    for i in range(4):
        w = rng.uniform(1.9, 2.3)
        h = rng.uniform(4.2, 5.2)
        km.box((x + w / 2, 0, h / 2), (w - 0.05, 1.6, h), _stone(rng, SURVEY, 0.07), jitter=0.04,
               decal="glyph" if i != 2 else "tally", decal_face="-y")
        x += w
    km.box((0, 0.9, 6.0), (9.0, 1.2, 1.4), mix(RUST, PLUM, 0.4), jitter=0.2)
    return km


def lamp_post(name="lamp_post", seed=25):
    km = KM(name, seed)
    km.cyl((0, 0, 0), (0, 0, 2.6), 0.07, 0.05, 5, WOOD)
    km.box((0, 0, 2.8), (0.3, 0.3, 0.4), GUN_D)
    km.blob((0, 0, 2.8), (0.17, 0.17, 0.2), (1.0, 0.8, 0.4), sub=1, noise=0.0, seed=1, mat=1)
    return km


def span_stump(name="span_stump", seed=26):
    """Red Span remnant: broken pier + arch springer + parapet fragment, dangling cable. Faces +X broken end."""
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 1.4
    km.ground = 0.8
    rng = random.Random(seed)
    # pier block
    km.box((0, 0, 3.0), (3.6, 5.4, 6.0), _stone(rng, STONE, 0.05), taper=0.05, decal="ashlar", decal_face="-y")
    # deck stub with jagged end
    for i in range(5):
        L = 6.0 - i * 0.9 + rng.uniform(-0.3, 0.3)
        km.box((L / 2 + 1.0, 0, 6.2 + 0.0), (L, 5.0 - i * 0.2, 0.9), _stone(rng, SURVEY, 0.08), jitter=0.05) if i == 0 else None
    km.box((3.0, 2.3, 7.0), (4.6, 0.55, 0.8), _stone(rng, SURVEY), jitter=0.06)
    km.box((2.0, -2.3, 7.0), (2.4, 0.55, 0.7), _stone(rng, SURVEY), jitter=0.06, tilt=(0.0, 0.08))
    # springer stones of the arch (broken)
    for i in range(3):
        km.box((2.2 + i * 1.0, 0, 5.0 - i * 0.9), (1.0, 4.2, 0.9), _stone(rng, STONE), tilt=(0, -0.3 - 0.1 * i), jitter=0.04)
    # rubble
    for i in range(5):
        km.blob((rng.uniform(2.5, 6), rng.uniform(-2.5, 2.5), 0.3), (0.8, 0.7, 0.45), STONE, sub=1, noise=0.2, seed=i + 40,
                colfn=lambda n: mix(STONE, DUST, max(0, n.z) * 0.4))
    # dangling cable
    km.cyl((4.3, 1.8, 6.1), (4.4, 1.8, 3.2), 0.07, 0.05, 4, ROPE, caps=False)
    return km


def pillar_broken(name="pillar_broken", seed=27):
    """Spanwright survey column: base block, three drums, broken top, toppled drum beside it."""
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 0.9
    km.ground = 0.4
    rng = random.Random(seed)
    km.box((0, 0, 0.2), (1.7, 1.7, 0.4), mul(STONE_D, 1.0), jitter=0.02)
    z = 0.4
    for i in range(3):
        h = rng.uniform(0.55, 0.8)
        r = 0.55 - i * 0.03
        km.cyl((0, 0, z), (0, 0, z + h), r, r - 0.01, 9, _stone(rng, SURVEY, 0.08), jitter=0.015, rot0=rng.random())
        km.cyl((0, 0, z + h - 0.03), (0, 0, z + h + 0.04), r + 0.05, r + 0.05, 9, mul(STONE_D, 1.05))
        z += h + 0.04
    km.cyl((0, 0, z), (0.1, 0.0, z + 0.45), 0.5, 0.35, 7, mul(SURVEY, 1.05), jitter=0.12)
    km.cyl((0.8, -1.0, 0.5), (1.9, -1.4, 0.5), 0.5, 0.5, 9, _stone(rng, SURVEY, 0.08), jitter=0.015)
    return km


def registry():
    return {
        "span_bay": lambda: span_bay("span_bay"),
        "span_bay_broken": lambda: span_bay("span_bay_broken", seed=4, broken=True),
        "span_pier": lambda: span_pier("span_pier"),
        "span_tower": lambda: span_tower("span_tower"),
        "marker_stone": lambda: marker_stone("marker_stone"),
        "cairn": lambda: cairn("cairn", 8, 8, 0.9),
        "cairn_small": lambda: cairn("cairn_small", 12, 5, 0.55),
        "cairn_names": lambda: cairn("cairn_names", 15, 9, 1.1, names=True),
        "load_post": lambda: load_post("load_post"),
        "rail_run": lambda: rail_run("rail_run"),
        "well_head": lambda: well_head("well_head"),
        "shade_awning": lambda: shade_awning("shade_awning"),
        "rope_rack": lambda: rope_rack("rope_rack"),
        "vault_door": lambda: vault_door("vault_door"),
        "thoughtstone_a": lambda: crystals("thoughtstone_a", 15, 7, 2.4, 0.9),
        "thoughtstone_b": lambda: crystals("thoughtstone_b", 17, 5, 1.1, 0.6),
        "cart_wreck": lambda: cart_wreck("cart_wreck"),
        "salt_crystals": lambda: salt_crystals("salt_crystals"),
        "survey_flag": lambda: survey_flag("survey_flag"),
        "dom_stack": lambda: dom_stack("dom_stack"),
        "floodlight": lambda: floodlight("floodlight"),
        "augur_derrick": lambda: augur_derrick("augur_derrick"),
        "bore_collar": lambda: bore_collar("bore_collar"),
        "resonance_pylon": lambda: pylon("resonance_pylon"),
        "glyph_wall": lambda: glyph_wall("glyph_wall"),
        "lamp_post": lambda: lamp_post("lamp_post"),
        "span_stump": lambda: span_stump("span_stump"),
        "pillar_broken": lambda: pillar_broken("pillar_broken"),
    }
