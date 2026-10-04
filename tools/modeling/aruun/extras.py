"""Aruun round-2 additions (sheet differences): bone armour plates on thigh/shin/forearm, forearm bandage wraps,
hanging belt tassels, a fuller ragged cloak across the back. Called from build.py after body.build_body."""
import math
import random

from mathutils import Vector

from common.geo import V
import body
from body import jm, GEAR, BODY, _strap, _limb_rot


def _plate(mb, a, b, t, off, radii, part, n=8, rings=5, sx=1):
    cen = a.lerp(b, t) + off
    mb.sphere(cen, radii, part=part, mat=BODY, n=n, rings=rings, rot=_limb_rot(a, b))


def _limb_ring(c, ax, rad, hint=V(0, -1, 0)):
    X = ax.cross(hint).normalized()
    Y = ax.cross(X).normalized()
    return [c + X * rad * math.cos(a) + Y * rad * math.sin(a) for a in [i / 12 * math.tau for i in range(13)]]


def build_extras(mb):
    s_v, s_f = len(mb.verts), len(mb.faces)
    sh, el, wr = jm("shoulder.L"), jm("elbow.L"), jm("wrist.L")
    hip, kn, an = jm("hip.L"), jm("knee.L"), jm("ankle.L")
    # --- thigh: large front plate + outer plate (bone), shin plate, forearm plate
    _plate(mb, hip, kn, 0.40, V(0.012, -0.093, 0), (0.058, 0.017, 0.14), "thighplate.L")
    _plate(mb, hip, kn, 0.33, V(0.082, -0.02, 0), (0.018, 0.05, 0.11), "thighplate.L", n=8, rings=5)
    _plate(mb, kn, an, 0.45, V(0.0, -0.062, 0), (0.034, 0.015, 0.14), "shinplate.L")
    _plate(mb, kn, an, 0.26, V(0.045, -0.02, 0), (0.014, 0.036, 0.09), "shinplate.L", n=8, rings=4)
    _plate(mb, el, wr, 0.38, V(0.012, -0.05, 0), (0.038, 0.014, 0.1), "bracer.L")
    # --- forearm bandage wraps (tan), tapering toward the wrist
    ax = (wr - el).normalized()
    for k in range(6):
        t = 0.52 + 0.075 * k
        c = el.lerp(wr, t)
        rad = 0.046 - 0.012 * (t - 0.5) / 0.5
        pts = [p + ax * 0.012 * math.sin(i * 0.9) for i, p in enumerate(_limb_ring(c, ax, rad))]
        _strap(mb, pts, 0.034, "band_cream", n_hint_center=c)
    # calf bandage under the knee plate
    ax2 = (an - kn).normalized()
    for k in range(3):
        c = kn.lerp(an, 0.62 + 0.07 * k)
        _strap(mb, _limb_ring(c, ax2, 0.052 - 0.006 * k), 0.032, "band_cream", n_hint_center=c)
    # --- belt tassels (left hip): cords + tufted ends
    rnd = random.Random(21)
    for k, (x, y, z, ln) in enumerate(((0.19, -0.09, 1.14, 0.30), (0.215, -0.04, 1.13, 0.38), (0.15, -0.115, 1.14, 0.22))):
        top = V(x, y, z)
        bot = top + V(0.015 * (k - 1), -0.01, -ln)
        mb.ribbon([top, top.lerp(bot, 0.5) + V(0.01, 0, 0), bot], 0.008, part="strip_cord", mat=GEAR, normal_hint=(0, -1, 0), samples=5)
        mb.sphere(bot + V(0, 0, -0.025), (0.018, 0.016, 0.034), part="talisman", mat=GEAR, n=6, rings=4)
        for j in range(3):
            o = V((j - 1) * 0.008, 0, -0.05)
            mb.ribbon([bot + o, bot + o + V(0.003 * (j - 1.5), -0.004, -0.09 - 0.02 * rnd.random())], 0.009,
                      part="strip_olive", mat=GEAR, normal_hint=(0, -1, 0))
    mb.mirror_from(s_v, s_f, lambda n: n[:-2] + ".R" if n.endswith(".L") else n)
    # --- fuller ragged cloak: layered torn panels across the whole back from the mantle down to the thighs
    for layer in range(2):
        for k in range(10):
            u = k / 9.0
            x0 = -0.27 + 0.54 * u + 0.01 * (rnd.random() - 0.5)
            zt = 1.70 - 0.03 * layer - 0.04 * abs(u - 0.5)
            ln = 0.75 + 0.35 * rnd.random() - 0.15 * layer
            yb = 0.19 + 0.012 * layer
            top = V(x0, 0.115 + 0.01 * layer, zt)
            p1 = V(x0 * 1.04, yb - 0.005, zt - 0.2)
            p2 = V(x0 * 1.12 + 0.02 * (rnd.random() - 0.5), yb + 0.02, zt - ln * 0.62)
            p3 = V(x0 * 1.2 + 0.04 * (rnd.random() - 0.5), yb + 0.05 + 0.03 * rnd.random(), zt - ln)
            w = 0.050 + 0.03 * rnd.random()
            mb.ribbon([top, p1, p2, p3], [w, w * 1.1, w * 0.85, 0.006], part="cloak_back", mat=GEAR,
                      normal_hint=(0, 1, 0), samples=5, across=2 - layer, curl=0.25)
