"""Reusable accessories for NPC specs (head-relative so they scale with any humanoid): ears, snout, beak, hats, scarf,
poncho, coat, backpack, tail, eyes, shell, props.  All take the Builder `b` after humanoid.body()."""
import math

import numpy as np

import humanoid as hu

A = np.array


def P(b, x, y, z):
    return hu.hp(b, x, y, z)


def eyes(b, col="eye", size=1.0, y=-0.93, x=0.42, z=0.08):
    for sg in (1, -1):
        b.ball(P(b, sg * x, y, z), (0.011 * b.H * size, 0.007 * b.H * size, 0.014 * b.H * size), "head", col, seg=5, rings=3)


def brows(b, col, z=0.3):
    for sg in (1, -1):
        b.ball(P(b, sg * 0.42, -0.9, z), (0.02 * b.H * 0.6, 0.006, 0.006), "head", col, seg=4, rings=2)


def ears(b, col, inner=None, length=1.8, width=0.28, tilt=0.15, lop=0.0, spread=0.55):
    """Long (hare) or short (badger) ears: leaf blades from the head top."""
    for sg in (1, -1):
        base = P(b, sg * spread, 0.1, 0.8)
        tip = base + A((sg * tilt * b.hr[0] * 2 + sg * lop, 0.05 * b.hr[1], length * b.hr[2]))
        b.leaf(base, tip, width * b.hr[0] * 2, (1, 0, 0), "head", col, n=3, bend=(sg * lop * 0.4, 0, 0))
        if inner:
            b.leaf(base + A((0, -0.012, 0.01)), tip * 0.97 + base * 0.03 + A((0, -0.012, 0)), width * b.hr[0] * 1.2, (1, 0, 0), "head", inner, n=3)


def snout(b, col, nose, length=0.9, drop=-0.25, w=0.5):
    b.ball(P(b, 0, -1.0 - length * 0.4, drop), (b.hr[0] * w, b.hr[1] * length * 0.55, b.hr[2] * 0.35), "head", col, seg=7, rings=4)
    b.ball(P(b, 0, -1.0 - length * 0.95, drop + 0.08), (b.hr[0] * 0.18, b.hr[1] * 0.15, b.hr[2] * 0.14), "head", nose, seg=5, rings=3)


def beak(b, col, length=1.8, drop=-0.2, thick=0.2):
    base = P(b, 0, -0.9, drop)
    tip = P(b, 0, -0.9 - length, drop - 0.35)
    b.spike(base, tip, (b.hr[0] * thick, b.hr[2] * thick), "head", col, seg=5)


def tail_bone(b, name="tail", length=0.6, drop=-0.05):
    h = b.j("hips")
    b.add_bone(name, tuple(h + (0, 0.05, -0.03)), tuple(h + (0, length, drop - 0.1)), "hips")
    return name


def tail(b, col, length=0.6, r=0.05, name="tail", drop=-0.12, curl=0.0):
    h = b.j("hips")
    pts = [h + (0, 0.05, -0.03), h + (0, length * 0.4, drop * 0.5), h + (curl, length * 0.75, drop), h + (curl * 2, length, drop * 0.6)]
    b.tube(pts, [r, r * 0.8, r * 0.55, r * 0.15], name, col, seg=6)


def scarf(b, col, col2=None, trail=0.5):
    n = b.j("neck1")
    b.ball(n + (0, 0, 0.0), (b.H * 0.045, b.H * 0.04, b.H * 0.022), "neck1", col, seg=8, rings=3)
    b.ball(n + (0, -0.01, -0.03), (b.H * 0.052, b.H * 0.045, b.H * 0.02), "chest", col2 or col, seg=8, rings=3)
    b.tatter(n + (0.04, 0.04, -0.03), 0.07, trail * b.H * 0.3, "chest", col, n=1, jag=0.3)


def hat(b, kind, col, col2=None):
    if kind == "wide":
        b.ball(P(b, 0, 0.0, 0.62), (b.hr[0] * 1.9, b.hr[1] * 1.9, 0.012 * b.H), "head", col, seg=10, rings=3)
        b.ball(P(b, 0, 0.0, 0.8), (b.hr[0] * 1.05, b.hr[1] * 1.05, b.hr[2] * 0.45), "head", col, seg=9, rings=4)
        if col2:
            b.ball(P(b, 0, 0.0, 0.7), (b.hr[0] * 1.08, b.hr[1] * 1.08, 0.008 * b.H), "head", col2, seg=9, rings=2)
    elif kind == "cap":
        b.ball(P(b, 0, 0.05, 0.55), (b.hr[0] * 1.06, b.hr[1] * 1.06, b.hr[2] * 0.55), "head", col, seg=9, rings=4)
        b.ball(P(b, 0, -0.55, 0.52), (b.hr[0] * 0.9, b.hr[1] * 0.6, 0.008 * b.H), "head", col2 or col, seg=8, rings=2)
    elif kind == "wrap":       # head wrap / headcloth
        b.ball(P(b, 0, 0.05, 0.5), (b.hr[0] * 1.1, b.hr[1] * 1.1, b.hr[2] * 0.62), "head", col, seg=9, rings=4)
        b.tatter(P(b, 0, 1.0, 0.4), b.hr[0] * 0.7, b.hr[2] * 1.4, "head", col2 or col, n=2, jag=0.3)
    elif kind == "helmet":
        b.ball(P(b, 0, 0.0, 0.3), (b.hr[0] * 1.12, b.hr[1] * 1.12, b.hr[2] * 0.85), "head", col, seg=10, rings=5)
        if col2:
            b.ball(P(b, 0, -0.78, 0.15), (b.hr[0] * 0.95, b.hr[1] * 0.35, b.hr[2] * 0.22), "head", col2, seg=8, rings=3)
    elif kind == "hood":
        b.ball(P(b, 0, 0.12, 0.2), (b.hr[0] * 1.2, b.hr[1] * 1.2, b.hr[2] * 1.05), "head", col, seg=9, rings=5)
        b.spike(P(b, 0, 0.9, 0.5), P(b, 0, 1.7, -0.2), (b.hr[0] * 0.8, b.hr[0] * 0.8), "head", col, seg=6)
    elif kind == "tricorn":
        b.ball(P(b, 0, 0, 0.7), (b.hr[0] * 1.6, b.hr[1] * 1.6, 0.012 * b.H), "head", col, seg=3, rings=2)


def poncho(b, col, col2=None, length=0.55, spread=0.2):
    wt = hu.hang_weights(b, b.j("hips")[2] + 0.35, b.j("hips")[2] - 0.2, 0.3)
    sz = b.j("chest")[2] + 0.1
    top = b.j("neck1") + (0, 0.0, -0.03)
    b.ring_skirt(top, b.H * 0.08, b.H * (0.16 + spread), sz, sz - length * b.H, lambda p: {"chest": 1.0}, [col, col2 or col], n=10, jag=0.2)


def coat(b, col, lining, length=0.45, collar=True):
    """Long open coat hanging from the hips (front slit), lining colour on the back panel."""
    H = b.H
    zt = b.j("hips")[2] + 0.04
    zb = zt - length * H
    wt = hu.hang_weights(b, zt, zb, 0.7)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips") if "coat" not in [x[0] for x in b.bones] else None
    for sg in (1, -1):
        b.strip([(sg * 0.15 * H * 0.6, -0.065 * H * 0.7, zt + 0.1), (sg * 0.1 * H * 0.6, -0.07 * H * 0.7, zt)],
                [(sg * 0.2 * H * 0.6, -0.08 * H * 0.7, zb), (sg * 0.12 * H * 0.6, -0.085 * H * 0.7, zb)], wt, col)
        b.strip([(sg * 0.16 * H * 0.6, -0.02, zt + 0.05), (sg * 0.13 * H * 0.6, 0.06 * H * 0.7, zt)],
                [(sg * 0.23 * H * 0.6, 0.0, zb + 0.03), (sg * 0.15 * H * 0.6, 0.1 * H * 0.7, zb)], wt, col)
    b.strip([(0.14 * H * 0.6, 0.06 * H * 0.7, zt), (0.0, 0.075 * H * 0.7, zt), (-0.14 * H * 0.6, 0.06 * H * 0.7, zt)],
            [(0.15 * H * 0.6, 0.1 * H * 0.7, zb), (0, 0.12 * H * 0.7, zb - 0.04), (-0.15 * H * 0.6, 0.1 * H * 0.7, zb)], wt, lining)
    if collar:
        n = b.j("neck1")
        for sg in (1, -1):
            b.leaf(n + (sg * 0.05, 0.0, -0.03), n + (sg * 0.065, 0.03, 0.07), 0.09, (0, 1, 0), "chest", col, n=2)


def backpack(b, col, trim=None, size=1.0):
    pc = b.j("spine2") + (0, 0.1 * size, 0.04)
    s = b.H / 1.7 * size
    b.box(pc, (0.24 * s, 0.14 * s, 0.34 * s), "chest", col, taper=0.92)
    if trim:
        b.box(pc + (0, 0.075 * s, 0), (0.05 * s, 0.01, 0.3 * s), "chest", trim)
        b.box(pc + (0.12 * s, 0, -0.1 * s), (0.04 * s, 0.09 * s, 0.1 * s), "chest", trim)


def belt(b, col, pouches=None, z=0.05):
    b.ball(b.j("hips") + (0, -0.002, z), (0.08 * b.H / 1.7 * 1.2, 0.06 * b.H / 1.7 * 1.2, 0.02 * b.H / 1.7 * 1.2), "hips", col, seg=8, rings=3)
    if pouches:
        for x in (0.1, -0.1, 0.0):
            b.box(b.j("hips") + (x * b.H / 1.7, -0.08 * b.H / 1.7, -0.01), (0.04 * b.H / 1.7, 0.04 * b.H / 1.7, 0.06 * b.H / 1.7), "hips", pouches)


def staff(b, side, col, length=1.5, tip=None, hook=False):
    s = ".R" if side == "R" else ".L"
    h = b.j("wrist" + s)
    b.limb(h + (0, 0.0, 0.25 * b.H / 1.7), h + (0.02, -0.05, -length * 0.55), 0.013 * b.H / 1.7 * 1.5, 0.014 * b.H / 1.7 * 1.5, "hand" + s, col, seg=5)
    top = h + (0, 0.0, 0.25 * b.H / 1.7)
    if hook:
        b.tube([top, top + (0, -0.03, 0.08), top + (0, -0.12, 0.1), top + (0, -0.16, 0.03)], [0.015, 0.014, 0.012, 0.01], "hand" + s, col, seg=5)
    if tip:
        b.ball(top + (0, 0, 0.04), 0.035 * b.H / 1.7, "hand" + s, tip, seg=6, rings=3)


def clipboard(b, side, col, paper):
    s = ".R" if side == "R" else ".L"
    h = b.j("wrist" + s)
    k = b.H / 1.7
    b.box(h + (0.03 * k * (1 if side == "L" else -1), -0.07 * k, 0.0), (0.02 * k, 0.2 * k, 0.26 * k), "hand" + s, col, rot=(0, 0, 8))
    b.box(h + (0.04 * k * (1 if side == "L" else -1), -0.07 * k, 0.0), (0.005, 0.17 * k, 0.22 * k), "hand" + s, paper, rot=(0, 0, 8))


def shell_dome(b, col, col2, scale=1.0):
    c = b.j("spine2") + (0, 0.16 * scale, 0.03)
    k = b.H / 1.5
    b.add_bone("shell", tuple(b.j("chest") + (0, 0.1, 0)), tuple(b.j("chest") + (0, 0.4, 0)), "chest") if "shell" not in [x[0] for x in b.bones] else None
    b.ball(c, (0.34 * k * scale, 0.3 * k * scale, 0.3 * k * scale), "shell", col, seg=10, rings=6, bands=[col, col2])
    for i in range(5):
        a = i * 1.26
        b.spike(c + A((0.2 * k * math.cos(a), 0.12 * k, 0.2 * k * math.sin(a) + 0.05)), c + A((0.3 * k * math.cos(a), 0.2 * k, 0.3 * k * math.sin(a) + 0.08)), 0.04 * k, "shell", col2, seg=4)


def charms(b, cols, z0=-0.02, n=6, bone="chest", spread=0.12):
    for i in range(n):
        t = i / max(n - 1, 1)
        b.ball(b.j("neck1") * (1 - t) + b.j("spine1") * t + A(((t - 0.5) * spread * 2, -0.075 * b.H / 1.7, z0)), 0.014 * b.H / 1.7, bone, cols[i % len(cols)], seg=4, rings=3)
