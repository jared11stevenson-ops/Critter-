"""Geology kit: layered strata mesas/buttes/hoodoos/arches, boulders, scree, spoil heaps, salt crust."""
import math
import random
from mathutils import Vector
from kitlib import *

PAL_MAIN = [VERMIL, RUST, CREAM, BUFF, PLUM, RUST, VERMIL, CREAM]
PAL_DEEP = [RUST, PLUM, VERMIL, RUST, DEEP, BUFF]


def _wob(rng, wobble):
    ph = [rng.uniform(0, math.tau) for _ in range(5)]
    amp = [rng.uniform(0.5, 1.0) for _ in range(5)]
    def f(theta, k):
        s = (amp[0] * math.sin(2 * theta + ph[0] + k * 0.31) + amp[1] * math.sin(3 * theta + ph[1])
             + amp[2] * math.sin(5 * theta + ph[2] + k * 0.17) + amp[3] * math.sin(7 * theta + ph[3]))
        return 1.0 + wobble * s / 2.2
    return f


def layered(name, R, H, layers, seed, aspect=1.0, N=20, wobble=0.16, palette=PAL_MAIN, dust=0.22, cap_dome=0.04,
            rough=0.05, rows=2, ao_dist=None):
    """layers: list of (thickness_weight, r_lo, r_hi, hard) from bottom to top. Radii are fractions of R."""
    km = KM(name, seed)
    km.dust = dust
    km.ao_dist = ao_dist or max(1.2, R * 0.25)
    km.ao_amt = 0.6
    km.ground = max(0.5, H * 0.06)
    rng = random.Random(seed)
    wf = _wob(rng, wobble)
    tw = sum(l[0] for l in layers)
    z = 0.0
    prev_hi = None
    prev_col = None
    jr = [[1.0 + rng.uniform(-rough, rough) * 2 for _ in range(N)] for _ in range(layers.__len__() * (rows + 1) + 2)]
    ji = 0
    flute = [1.0 + 0.04 * math.sin(i * 1.9 + seed) + rng.uniform(-0.02, 0.02) for i in range(N)]
    for k, (w, rl, rh, hard) in enumerate(layers):
        t = H * w / tw
        base = palette[k % len(palette)]
        col = jit(base, rng, 0.07)
        if not hard:
            col = mul(col, 0.9)
        zs = [z + t * r / rows for r in range(rows + 1)]
        rings = []
        for ri in range(rows + 1):
            u = ri / rows
            rr = rl + (rh - rl) * u
            # weathering: soft layers carve in the middle row
            if ri not in (0, rows):
                rr *= (0.97 if hard else 0.92)
            ring = []
            for i in range(N):
                th = math.tau * (i + rng.uniform(-0.15, 0.15)) / N
                q = R * rr * wf(th, k) * jr[ji][i] * flute[i]
                ring.append(Vector((math.cos(th) * q, math.sin(th) * q * aspect, zs[ri])))
            ji += 1
            rings.append(ring)
        # ledge from prev layer top to this layer bottom
        if prev_hi is not None:
            for i in range(N):
                j = (i + 1) % N
                km.poly([prev_hi[i], prev_hi[j], rings[0][j], rings[0][i]], mix(prev_col, DUST, 0.35), out=(0, 0, z - 5))
        for ri in range(rows):
            for i in range(N):
                j = (i + 1) % N
                c0 = mul(col, 0.80 + 0.12 * (ri / rows) + 0.0)
                c1 = mul(col, 0.88 + 0.12 * ((ri + 1) / rows))
                # per-column colour jitter for a streaky, hand-painted face
                sj = 1.0 + 0.05 * math.sin(i * 2.7 + k)
                km.poly([rings[ri][i], rings[ri][j], rings[ri + 1][j], rings[ri + 1][i]],
                        [mul(c0, sj), mul(c0, sj), mul(c1, sj), mul(c1, sj)], out=(0, 0, (zs[ri] + zs[ri + 1]) * 0.5))
        prev_hi = rings[-1]
        prev_col = col
        z += t
    # cap
    ctr = Vector((0, 0, z + H * cap_dome))
    capc = mix(prev_col, DUST, 0.45)
    for i in range(N):
        j = (i + 1) % N
        km.poly([ctr, prev_hi[i], prev_hi[j]], [mul(capc, 1.05), capc, capc], out=(0, 0, z - 3))
    # fix winding of cap (up facing)
    return km


def mesa(name, R, H, seed, layers=15, aspect=1.0, taper=0.2, skirt=0.2, N=24, wobble=0.15, ledge=0.018):
    rng = random.Random(seed + 9)
    L = []
    L.append((skirt * 12, 1.30, 1.03, False))      # talus apron
    for k in range(layers):
        hard = rng.random() < 0.4
        f0 = 1.0 - taper * (k / layers) + (ledge if hard else -ledge)
        f1 = f0 - (0.004 if hard else 0.012)
        L.append((rng.uniform(0.5, 1.2) * (1.5 if hard else 0.8), f0, f1, hard))
    L.append((2.2, 1.0 - taper + 0.03, 1.0 - taper + 0.005, True))   # hard caprock band
    return layered(name, R, H, L, seed, aspect=aspect, N=N, wobble=wobble, rough=0.012, rows=1)


def butte(name, R, H, seed, layers=10):
    """Tall narrow chimney butte w/ hard cap."""
    rng = random.Random(seed + 3)
    L = [(1.2, 1.5, 1.0, False)]
    f = 1.0
    for k in range(layers):
        hard = rng.random() < 0.45
        f0 = 1.0 - 0.18 * k / layers + (0.10 if hard else -0.05)
        L.append((rng.uniform(0.8, 1.4), f0, f0 - 0.03, hard))
    L.append((1.0, 1.2, 1.12, True))      # cap overhang
    L.append((0.35, 1.1, 0.6, True))
    return layered(name, R, H, L, seed, aspect=0.8, N=18, wobble=0.14, palette=PAL_MAIN)


def hoodoo(name, R, H, seed):
    rng = random.Random(seed)
    L = [(0.9, 1.45, 1.0, False)]
    n = 7
    for k in range(n):
        neck = 0.62 + 0.18 * math.sin(k * 1.9 + seed)
        L.append((rng.uniform(0.6, 1.1), neck + 0.08, neck, k % 2 == 0))
    L.append((0.7, 1.25, 1.15, True))     # caprock
    L.append((0.3, 1.1, 0.5, True))
    return layered(name, R, H, L, seed, N=16, wobble=0.12, palette=PAL_DEEP + [CREAM, VERMIL])


def arch_rock(name, seed=4, span=16.0, rise=9.0, thick=3.2, depth=5.0):
    km = KM(name, seed)
    km.dust = 0.2
    km.ao_dist = 2.0
    km.ground = 0.8
    rng = random.Random(seed)
    nseg = 18
    nz = 6
    # path: half-ellipse in XZ, cross-section (thickness t along path normal, depth along Y)
    grid = []
    for i in range(nseg + 1):
        u = i / nseg
        a = math.pi * u
        cx = -math.cos(a) * span / 2
        cz = math.sin(a) * rise
        nx_, nz_ = -math.cos(a) * 0.0 + (-math.cos(a)), math.sin(a)  # outward direction (approx)
        # outward normal of ellipse
        ox = -math.cos(a) / (span / 2)
        oz = math.sin(a) / rise
        L = math.hypot(ox, oz)
        ox, oz = ox / L, oz / L
        th = thick * (0.8 + 0.5 * math.sin(a)) * (1.0 + rng.uniform(-0.06, 0.06))
        dp = depth * (0.85 + 0.25 * math.sin(a * 0.7 + 1)) * (1 + rng.uniform(-0.05, 0.05))
        row = []
        for (s, y) in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
            row.append(Vector((cx + ox * th * s * 2 * 0.5, y * dp, cz + oz * th * s * 2 * 0.5)))
        grid.append(row)
    # extend legs to ground
    for i in range(nseg):
        for e in range(4):
            e2 = (e + 1) % 4
            zc = (grid[i][e].z + grid[i + 1][e].z) * 0.5
            col = jit(PAL_MAIN[int(zc * 0.9 / 1.0) % len(PAL_MAIN)], rng, 0.05)
            km.poly([grid[i][e], grid[i + 1][e], grid[i + 1][e2], grid[i][e2]], col, out=(0, 0, rise * 0.3))
    # end caps
    for end in (0, nseg):
        km.poly(grid[end][::-1] if end == 0 else grid[end], mul(RUST, 0.9), out=(0, 0, rise * 0.3))
    # foot talus
    for sx in (-1, 1):
        km.blob((sx * span * 0.5, 0, 0.9), (thick * 1.7, depth * 0.62, 1.7), RUST, sub=1, noise=0.15, seed=sx + 7,
                colfn=lambda n: mix(RUST, DUST, max(0, n.z) * 0.5))
    return km


def boulder(name, rx, ry, rz, seed, sub=2, noise=0.2, tint=0.0):
    km = KM(name, seed)
    km.dust = 0.25
    km.ao_dist = max(0.6, rx * 0.7)
    km.sharp = 30
    rng = random.Random(seed)
    bands = [VERMIL, RUST, BUFF, RUST]
    def cf(n):
        z = n.z * 0.5 + 0.5
        c = bands[int(z * 4) % 4] if n.z < 0.6 else DUST
        return mul(mix(c, GUN, tint), 0.9 + 0.2 * n.z)
    km.blob((0, 0, rz * 0.55), (rx, ry, rz), RUST, sub=sub, noise=noise, seed=seed, colfn=cf, flat_bottom=-rz * 0.25 + rz * 0.55 * 0.0 - 0.0, facet=0.0)
    return km


def scree(name, seed=2, n=7, r=1.6):
    km = KM(name, seed)
    km.dust = 0.25
    km.ao_dist = 0.5
    rng = random.Random(seed)
    for i in range(n):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, r)
        s = rng.uniform(0.22, 0.6) * (1.2 if i == 0 else 1.0)
        c = (math.cos(a) * d, math.sin(a) * d, s * 0.3)
        tint = rng.choice([VERMIL, RUST, BUFF, PLUM])
        km.blob(c, (s * 1.1, s, s * 0.7), tint, sub=1, noise=0.25, seed=i + seed,
                colfn=lambda nn, t=tint: mix(t, DUST, max(0, nn.z) * 0.45), flat_bottom=-s * 0.1)
    return km


def spoil_heap(name, seed=3, R=5.0, H=2.6):
    """Dominion extraction spoil heap: grey-red tailings cone with bulldozed terraces and stray ore chunks."""
    km = KM(name, seed)
    km.dust = 0.1
    km.ao_dist = 1.0
    rng = random.Random(seed)
    L = [(1.0, 1.0, 0.82, False), (1.0, 0.78, 0.60, False), (1.0, 0.56, 0.36, False), (0.8, 0.32, 0.1, False)]
    base = layered(name, R, H, L, seed, N=16, wobble=0.22, palette=[mix(RUST, GUN, 0.55), mix(VERMIL, GUN, 0.4), GUN, mix(RUST, GUN, 0.3)], dust=0.0, rows=1)
    base.polys.extend([])
    for i in range(6):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(R * 0.7, R * 1.2)
        s = rng.uniform(0.2, 0.4)
        base.blob((math.cos(a) * d, math.sin(a) * d, s * 0.3), (s, s * 0.8, s * 0.6), GUN, sub=1, noise=0.25, seed=i)
    return base


def salt_crust(name, seed=5, R=2.6):
    """Cracked salt-crust plates: polygonal slabs tilted/heaved, white with ochre edges."""
    km = KM(name, seed)
    km.dust = 0.0
    km.ao_dist = 0.4
    km.sharp = 25
    rng = random.Random(seed)
    for i in range(9):
        a = rng.uniform(0, math.tau)
        d = math.sqrt(rng.random()) * R
        cx, cy = math.cos(a) * d, math.sin(a) * d
        n = rng.choice([5, 6, 7])
        rr = rng.uniform(0.45, 0.85)
        lift = rng.uniform(0.0, 0.18)
        tx, ty = rng.uniform(-0.12, 0.12), rng.uniform(-0.12, 0.12)
        top, bot = [], []
        for k in range(n):
            th = math.tau * k / n + rng.uniform(-0.2, 0.2)
            q = rr * rng.uniform(0.8, 1.1)
            x, y = cx + math.cos(th) * q, cy + math.sin(th) * q
            top.append(Vector((x, y, 0.12 + lift + tx * (x - cx) + ty * (y - cy))))
            bot.append(Vector((x, y, 0.0)))
        c = jit(SALT, rng, 0.04)
        km.poly(top, [c] * n, out=(cx, cy, -5)) if False else km.poly(top, [c] * n)
        for k in range(n):
            j = (k + 1) % n
            km.poly([bot[k], bot[j], top[j], top[k]], mix(c, OCHRE, 0.45), out=(cx, cy, 0))
    return km
