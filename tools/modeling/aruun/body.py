"""Aruun game-topology geometry, built part by part from the measured landmarks
(design/model_sheets/aruun/landmarks.json): horn tip 2.40, cranium 2.13, jaw 1.97, neck base 1.77,
shoulder 1.63, elbow 1.31, waist 1.24, crotch 0.89, knee 0.60, ankle 0.25 (metres).

Blender space: Z up, character faces -Y, his LEFT side is +X. Left-side parts are built once and mirrored.
Materials: 0 = body (carapace / chitin / head), 1 = gear (cloth, belt, bone ornaments, fringe), 2 = Morrow.
"""
import math
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from mathutils import Vector, Matrix  # noqa: E402
from common.geo import MeshBuilder, V, catmull, smoothstep  # noqa: E402

BODY, GEAR, MORROW = 0, 1, 2

# ---------------------------------------------------------------------------------------------- skeleton
# Joint positions (left side; right mirrored). Used by geometry AND by the rig (rig.py).
J = {
    "root":       V(0, 0.0, 0.0),
    "hips":       V(0, 0.02, 1.00),
    "spine1":     V(0, 0.03, 1.16),
    "spine2":     V(0, 0.035, 1.34),
    "chest":      V(0, 0.03, 1.50),
    "neck1":      V(0, 0.015, 1.68),
    "neck2":      V(0, 0.0, 1.78),
    "neck3":      V(0, -0.005, 1.88),
    "head":       V(0, 0.01, 1.98),
    "head_end":   V(0, -0.22, 1.96),
    "jaw":        V(0, -0.015, 1.985),
    "jaw_end":    V(0, -0.2, 1.925),
    "clavicle.L": V(0.06, 0.0, 1.62),
    "shoulder.L": V(0.25, 0.02, 1.60),
    "elbow.L":    V(0.31, 0.06, 1.31),
    "wrist.L":    V(0.335, 0.01, 0.94),
    "hand_end.L": V(0.345, -0.01, 0.80),
    "hip.L":      V(0.115, 0.02, 0.99),
    "knee.L":     V(0.135, -0.035, 0.585),
    "ankle.L":    V(0.145, 0.03, 0.21),
    "toe.L":      V(0.15, -0.17, 0.05),
    "toe_end.L":  V(0.15, -0.30, 0.03),
}


def mirror_name(n):
    if n.endswith(".L"):
        return n[:-2] + ".R"
    if n.endswith(".R"):
        return n[:-2] + ".L"
    return n


def jm(name):
    """Joint position, handles .R by mirroring."""
    if name.endswith(".R"):
        p = J[name[:-2] + ".L"]
        return V(-p.x, p.y, p.z)
    return J[name]


def build_body(mb):
    """Everything except Morrow. Returns nothing; parts are tagged on faces."""
    _head(mb)
    _neck(mb)
    _torso(mb)
    s_v, s_f = len(mb.verts), len(mb.faces)
    _arm_left(mb)
    _leg_left(mb)
    mb.mirror_from(s_v, s_f, lambda n: n[:-2] + ".R" if n.endswith(".L") else n)
    _costume(mb)


# ---------------------------------------------------------------------------------------------- head
def _head(mb):
    # cranium + snout: path from the back of the skull to the snout tip (points forward/down)
    back = V(0, 0.075, 2.07)
    path = [back, V(0, 0.03, 2.075), V(0, -0.03, 2.055), V(0, -0.10, 2.02), V(0, -0.17, 1.985), V(0, -0.225, 1.955)]
    # widths (half) / heights (half) along the head
    rx = [0.035, 0.075, 0.072, 0.050, 0.036, 0.022]
    ry = [0.040, 0.068, 0.062, 0.045, 0.034, 0.020]

    def shape(t, th, x, y):
        # flatter skull top, brow ridge bulge over the eyes, slight keel under the snout
        s = math.sin(th)
        if y > 0:
            y *= 0.88
        brow = math.exp(-((t - 0.38) / 0.12) ** 2) * max(0.0, s) * max(0.0, abs(math.cos(th)) - 0.2)
        x *= 1.0 + 0.25 * brow
        y *= 1.0 + 0.15 * brow
        return x, y

    mb.loft(path, rx, ry, n=16, part="head", mat=BODY, side=(1, 0, 0), front=(0, 0, 1), samples=11,
            shape=shape, cap0="flat", cap1="point", power=[2.0, 2.3, 2.3, 2.2, 2.0, 2.0])
    # downward mandible hook at the snout tip (front view: beak-like hook)
    mb.cone(V(0, -0.205, 1.950), V(0, -0.245, 1.905), 0.018, part="head", mat=BODY, n=6,
            bend=V(0, 0.02, 0.0), segs=3)
    # lower jaw (separate part -> jaw bone; opens for roars)
    jp = [V(0, 0.02, 1.995), V(0, -0.05, 1.975), V(0, -0.12, 1.950), V(0, -0.195, 1.928)]
    mb.loft(jp, [0.050, 0.045, 0.034, 0.018], [0.022, 0.024, 0.02, 0.012], n=10, part="jaw", mat=BODY,
            side=(1, 0, 0), front=(0, 0, -1), samples=6, cap0="flat", cap1="point")
    # fangs (white) at the jaw corners, upward
    for sx in (1, -1):
        mb.cone(V(sx * 0.03, -0.11, 1.960), V(sx * 0.033, -0.118, 1.995), 0.007, part="fang", mat=BODY, n=5, segs=2)
        mb.cone(V(sx * 0.024, -0.16, 1.955), V(sx * 0.026, -0.166, 1.978), 0.005, part="fang", mat=BODY, n=5, segs=2)
    # eyes: yellow, on the sides of the head, set under a brow plate
    for sx in (1, -1):
        mb.sphere(V(sx * 0.064, -0.035, 2.048), (0.017, 0.022, 0.017), part="eye", mat=BODY, n=10, rings=6)
        # brow plate (red carapace) over the eye
        mb.loft([V(sx * 0.045, 0.02, 2.085), V(sx * 0.07, -0.03, 2.078), V(sx * 0.062, -0.075, 2.06)],
                [0.022, 0.02, 0.012], [0.009, 0.011, 0.006], n=8, part="brow", mat=BODY,
                side=(0, 0, 1), front=(sx, 0, 0.5), samples=5, cap0="point", cap1="point")
    # crown crest: jagged red plates along the top of the skull (HEAD DETAILS panel)
    for i, (y, z, h) in enumerate([(0.05, 2.11, 0.035), (0.015, 2.12, 0.045), (-0.02, 2.115, 0.04), (-0.055, 2.10, 0.03)]):
        for sx in (1, -1):
            mb.cone(V(sx * 0.03, y, z - 0.012), V(sx * 0.045, y + 0.02, z + h), 0.016, part="crest", mat=BODY, n=5,
                    segs=2)
    # horns: rise from the crown, spread outward, lean forward, tips curl back inward (back view: lyre/crescent)
    for sx in (1, -1):
        hp = [V(sx * 0.032, 0.0, 2.10), V(sx * 0.05, -0.01, 2.18), V(sx * 0.085, -0.03, 2.26),
              V(sx * 0.105, -0.045, 2.32), V(sx * 0.095, -0.05, 2.37), V(sx * 0.06, -0.04, 2.40)]
        rings = mb.loft(hp, [0.022, 0.019, 0.016, 0.013, 0.010, 0.006], [0.020, 0.017, 0.015, 0.012, 0.009, 0.005],
                        n=8, part="horn", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=14, cap0="flat",
                        cap1="point",
                        shape=lambda t, th, x, y: (x * (1 + 0.18 * max(0, math.sin(t * 40))), y))
        # knobbed tines along the horn (front/side views)
        for (t, d, ln) in [(0.3, V(sx * 1, 0.2, 0.3), 0.035), (0.48, V(-sx * 0.4, -0.8, 0.4), 0.03),
                           (0.62, V(sx * 1, 0.1, 0.2), 0.028), (0.8, V(-sx * 0.3, 0.6, 0.5), 0.022)]:
            p = catmull(hp, 21)[int(t * 20)]
            mb.cone(p, p + d.normalized() * ln, 0.007, part="horn", mat=BODY, n=5, segs=2)
        # notched forked tip
        tip = hp[-1]
        mb.cone(tip, tip + V(-sx * 0.012, 0.0, 0.03), 0.005, part="horn", mat=BODY, n=4, segs=1)
    # temple bone tines (tan antler-like branches behind the eyes)
    for sx in (1, -1):
        b0 = V(sx * 0.06, 0.03, 2.08)
        b1 = b0 + V(sx * 0.07, 0.02, 0.04)
        mb.loft([b0, b0.lerp(b1, 0.5) + V(0, 0, 0.01), b1], [0.012, 0.009, 0.006], [0.011, 0.008, 0.005], n=6,
                part="tine", mat=GEAR, cap0="flat", cap1="point", samples=4)
        mb.cone(b0.lerp(b1, 0.6), b0.lerp(b1, 0.6) + V(sx * 0.01, -0.01, 0.04), 0.005, part="tine", mat=GEAR, n=4, segs=2)
        mb.cone(b1, b1 + V(sx * 0.03, 0.01, 0.02), 0.005, part="tine", mat=GEAR, n=4, segs=2)
        mb.cone(b1, b1 + V(sx * 0.02, 0.02, -0.025), 0.004, part="tine", mat=GEAR, n=4, segs=2)
    # fringe: pale-yellow / cream strands sweeping back from the crown over the nape, olive strands beneath
    import random
    rnd = random.Random(7)
    for i in range(14):
        sx = 1 if i % 2 == 0 else -1
        k = i // 2
        a = 0.35 + 0.55 * (k / 6.0)
        root = V(sx * (0.035 + 0.035 * math.sin(a * 2.5)), 0.045 - 0.05 * (1 - a), 2.09 - 0.05 * a)
        ln = 0.13 + 0.07 * rnd.random()
        p1 = root + V(sx * (0.04 + 0.03 * rnd.random()), 0.07, -0.02)
        p2 = root + V(sx * (0.07 + 0.03 * rnd.random()), 0.11, -ln * 0.6)
        p3 = root + V(sx * (0.06 + 0.04 * rnd.random()), 0.12 + 0.03 * rnd.random(), -ln)
        part = "fringe_cream" if k % 3 != 2 else "fringe_olive"
        mb.ribbon([root, p1, p2, p3], [0.035, 0.03, 0.02, 0.003], part=part, mat=GEAR,
                  normal_hint=(sx, 0.4, 0.4), samples=6, curl=0.25)


# ---------------------------------------------------------------------------------------------- neck
def _neck(mb):
    path = [V(0, 0.03, 1.60), J["neck1"], J["neck2"], J["neck3"], V(0, 0.01, 1.96), V(0, 0.04, 2.03)]
    rx = [0.085, 0.07, 0.058, 0.054, 0.052, 0.045]
    ry = [0.085, 0.07, 0.06, 0.056, 0.054, 0.045]

    def seg(t, th, x, y):
        # segmented neck carapace: slight ridges every ~8 cm, throat (front) slightly flatter
        k = 1.0 + 0.06 * max(0.0, math.sin(t * math.pi * 9.0)) ** 4
        if math.sin(th) > 0:
            y *= 0.94
        return x * k, y * k

    mb.loft(path, rx, ry, n=12, part="neck", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=13, shape=seg,
            cap0="flat", cap1="flat")


# ---------------------------------------------------------------------------------------------- torso
def _torso(mb):
    zs = [0.88, 0.95, 1.03, 1.12, 1.20, 1.30, 1.40, 1.50, 1.58, 1.65, 1.71]
    rx = [0.12, 0.165, 0.18, 0.162, 0.158, 0.172, 0.200, 0.215, 0.205, 0.15, 0.09]
    ry = [0.09, 0.12, 0.13, 0.118, 0.113, 0.122, 0.136, 0.142, 0.130, 0.11, 0.08]
    ys = [0.02, 0.025, 0.025, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.035, 0.035]
    path = [V(0, y, z) for y, z in zip(ys, zs)]

    def shape(t, th, x, y):
        s, c = math.sin(th), math.cos(th)
        # chest: flatter front (pecs), rounded back with scapula bulge; abdomen: slightly flat front
        if s > 0:   # +Y frame axis = front
            y *= 0.92
        else:
            y *= 1.0 + 0.12 * smoothstep(0.55, 0.8, t) * abs(c)
        return x, y

    mb.loft(path, rx, ry, n=20, part="torso", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=17,
            shape=shape, power=2.2, cap0="flat", cap1="flat")
    # trapezius / collar plates around the neck base
    for sx in (1, -1):
        mb.sphere(V(sx * 0.12, 0.04, 1.65), (0.09, 0.075, 0.05), part="torso", mat=BODY, n=10, rings=6,
                  rot=Matrix.Rotation(sx * -0.35, 3, "Y"))


# ---------------------------------------------------------------------------------------------- arm (left)
def _arm_left(mb):
    sh, el, wr, he = J["shoulder.L"], J["elbow.L"], J["wrist.L"], J["hand_end.L"]
    # deltoid / shoulder ball (navy) under the pauldron
    mb.sphere(sh + V(0.01, 0, 0.0), (0.085, 0.085, 0.08), part="upperarm.L", mat=BODY, n=10, rings=7)
    # upper arm
    mb.loft([sh, sh.lerp(el, 0.5) + V(0.005, 0, 0), el], [0.068, 0.062, 0.05], [0.07, 0.066, 0.052], n=12,
            part="upperarm.L", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=5, cap0="flat", cap1="flat")
    # elbow joint ball
    mb.sphere(el, 0.052, part="forearm.L", mat=BODY, n=10, rings=6)
    # forearm
    mb.loft([el, el.lerp(wr, 0.45), wr], [0.05, 0.058, 0.04], [0.052, 0.06, 0.038], n=12, part="forearm.L", mat=BODY,
            side=(1, 0, 0), front=(0, -1, 0), samples=6, cap0="flat", cap1="flat")
    # pauldron: red ladybug dome over the shoulder (front/side: ~0.25 m dia)
    pc = sh + V(0.035, 0.0, 0.035)
    mb.sphere(pc, (0.125, 0.135, 0.115), part="pauldron.L", mat=BODY, n=14, rings=9,
              rot=Matrix.Rotation(-0.35, 3, "Y"),
              deform=lambda ph, th, d: d * (0.82 if ph > 2.2 else 1.0))
    # bicep plate (red, under the pauldron, front view tier)
    mb.sphere(sh.lerp(el, 0.55) + V(0.03, -0.01, 0), (0.06, 0.068, 0.10), part="armplate.L", mat=BODY, n=10, rings=6,
              rot=Matrix.Rotation(-0.2, 3, "Y"))
    # forearm bracer: big red rounded plate on the outer forearm, bulging at the elbow end
    fa = (wr - el).normalized()
    bc = el.lerp(wr, 0.35) + V(0.032, 0.0, 0.0)
    rot = fa.to_track_quat("Z", "X").to_matrix()
    mb.sphere(bc, (0.062, 0.07, 0.17), part="bracer.L", mat=BODY, n=12, rings=8, rot=rot,
              deform=lambda ph, th, d: d * (1.0 + 0.12 * math.exp(-((ph - 0.6) / 0.5) ** 2)))
    # wrist cuff
    mb.loft([wr + fa * -0.03, wr + fa * 0.01], [0.047, 0.045], [0.044, 0.042], n=10, part="forearm.L", mat=BODY,
            side=(1, 0, 0), front=(0, -1, 0), cap0="flat", cap1="flat")
    _hand_left(mb, wr, he)


def _hand_left(mb, wr, he):
    d = (he - wr).normalized()
    side = V(0.15, -1, 0).normalized()   # palm faces inward (-X) slightly forward
    side = (side - side.dot(d) * d).normalized()
    out = d.cross(side).normalized()     # back of the hand
    if out.x < 0:
        out = -out
    k0 = wr + d * 0.015
    k1 = wr + d * 0.10
    # palm block
    mb.loft([k0, k0.lerp(k1, 0.5), k1], [0.040, 0.046, 0.044], [0.024, 0.027, 0.022], n=10, part="hand.L", mat=BODY,
            side=side, front=out, samples=4, power=2.6, cap0="flat", cap1="flat")
    # three fingers + thumb, each 2 segments + tan claw (back view: 3 fingers + thumb)
    for i, (o, ln, curl) in enumerate([(-0.028, 0.085, 0.5), (0.0, 0.095, 0.55), (0.028, 0.085, 0.5)]):
        base = k1 + side * o
        p1 = base + d * ln * 0.55 - out * 0.008
        p2 = p1 + (d * math.cos(curl) - out * math.sin(curl)) * ln * 0.45
        mb.loft([base, p1, p2], [0.0145, 0.013, 0.011], [0.0135, 0.012, 0.010], n=7, part="hand.L", mat=BODY,
                side=side, front=out, samples=4, cap0="flat", cap1="flat")
        tipd = (d * math.cos(curl * 2.0) - out * math.sin(curl * 2.0)).normalized()
        mb.cone(p2, p2 + tipd * 0.04, 0.011, part="claw.L", mat=BODY, n=6, segs=2, bend=-out * 0.006)
    tb = k0 + d * 0.035 - side * 0.04
    tp = tb - side * 0.03 + d * 0.04 - out * 0.01
    mb.loft([tb, tp], [0.015, 0.012], [0.014, 0.011], n=7, part="hand.L", mat=BODY, side=d, front=out,
            cap0="flat", cap1="flat")
    mb.cone(tp, tp + (d - side * 0.4 - out * 0.4).normalized() * 0.035, 0.011, part="claw.L", mat=BODY, n=6, segs=2)


# ---------------------------------------------------------------------------------------------- leg (left)
def _leg_left(mb):
    hip, kn, an = J["hip.L"], J["knee.L"], J["ankle.L"]

    def thigh_shape(t, th, x, y):
        s = math.sin(th)
        # strong front quad bulge high, hamstring bulge at back
        if s > 0:
            y *= 1.0 + 0.10 * math.sin(t * math.pi)
        else:
            y *= 1.0 + 0.06 * math.sin(t * math.pi)
        return x, y

    mb.loft([hip + V(-0.01, 0, 0.06), hip, hip.lerp(kn, 0.5), kn + V(0, 0, 0.03)], [0.105, 0.105, 0.088, 0.066],
            [0.11, 0.11, 0.092, 0.066], n=14, part="thigh.L", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=8,
            shape=thigh_shape, cap0="flat", cap1="flat")
    # knee joint + tan knee plate (front)
    mb.sphere(kn, (0.06, 0.06, 0.065), part="shin.L", mat=BODY, n=10, rings=6)
    mb.sphere(kn + V(0.0, -0.05, 0.01), (0.055, 0.03, 0.075), part="kneeplate.L", mat=BODY, n=10, rings=6,
              rot=Matrix.Rotation(0.2, 3, "X"))

    def shin_shape(t, th, x, y):
        s = math.sin(th)
        if s < 0:   # calf at the back
            y *= 1.0 + 0.35 * math.exp(-((t - 0.3) / 0.22) ** 2)
        else:       # shin plate ridge at the front
            y *= 1.0 + 0.08 * (1 - t)
        return x, y

    mb.loft([kn, kn.lerp(an, 0.3), kn.lerp(an, 0.7), an + V(0, 0, -0.02)], [0.06, 0.064, 0.05, 0.045],
            [0.06, 0.066, 0.05, 0.045], n=12, part="shin.L", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=8,
            shape=shin_shape, cap0="flat", cap1="flat")
    _foot_left(mb, an)


def _foot_left(mb, an):
    x = an.x
    # ankle cuff (big banded sabaton top, tan plates)
    mb.loft([V(x, 0.03, 0.30), V(x, 0.025, 0.24), V(x, 0.02, 0.16)], [0.062, 0.07, 0.078], [0.062, 0.075, 0.09],
            n=12, part="foot.L", mat=BODY, side=(1, 0, 0), front=(0, -1, 0), samples=4, cap0="flat", cap1="flat",
            power=2.3)
    # foot body heel -> toes, low wedge
    path = [V(x, 0.11, 0.07), V(x, 0.05, 0.085), V(x, -0.04, 0.075), V(x + 0.005, -0.13, 0.05), V(x + 0.01, -0.19, 0.035)]
    mb.loft(path, [0.055, 0.075, 0.078, 0.07, 0.055], [0.06, 0.085, 0.07, 0.045, 0.03], n=12, part="foot.L", mat=BODY,
            side=(1, 0, 0), front=(0, 0, 1), samples=8, power=2.6, cap0="flat", cap1="flat",
            shape=lambda t, th, xx, yy: (xx, yy * (0.65 if math.sin(th) < 0 else 1.0)))
    # toe claws (tan): 3 forward claws, spread, hooking down
    for o, ln in ((-0.045, 0.10), (0.0, 0.12), (0.045, 0.095)):
        b = V(x + o + 0.01, -0.16, 0.04)
        mb.cone(b, b + V(o * 0.6, -ln, -0.03), 0.022, part="toeclaw.L", mat=BODY, n=6, segs=3, bend=V(0, -0.005, -0.012))
    # heel spur
    mb.cone(V(x, 0.10, 0.06), V(x, 0.17, 0.025), 0.022, part="toeclaw.L", mat=BODY, n=6, segs=2)
    # dew-claw / side spur at the ankle cuff (front view)
    mb.cone(V(x + 0.07, 0.0, 0.13), V(x + 0.11, -0.02, 0.07), 0.016, part="toeclaw.L", mat=BODY, n=5, segs=2)


# ---------------------------------------------------------------------------------------------- costume
def _costume(mb):
    # --- red sash belt around the waist (front view: thick red sash, knot at the back)
    def sash_ring(z, rx, ry, cy):
        return [V(rx * math.cos(a), cy + ry * math.sin(a), z + 0.012 * math.sin(2 * a)) for a in
                [i / 20 * math.tau for i in range(20)]]
    zs = [1.13, 1.17, 1.21, 1.25]
    rings = [sash_ring(z, 0.172 + 0.006 * i, 0.128 + 0.005 * i, 0.03) for i, z in enumerate(zs)]
    _band(mb, rings, "belt", GEAR, thick=0.012)
    # sash knot + hanging tails at the back
    mb.sphere(V(0.05, 0.165, 1.19), (0.04, 0.03, 0.035), part="belt", mat=GEAR, n=8, rings=5)
    for o in (0.02, 0.07):
        mb.ribbon([V(o + 0.04, 0.17, 1.18), V(o + 0.05, 0.19, 1.05), V(o + 0.06, 0.2, 0.92)], 0.05, part="cloth_sash",
                  mat=GEAR, normal_hint=(0, 1, 0), samples=4)
    # --- bone ring buckle (front, on his right of centre) with dark inner disc + hanging medallion
    bc = V(-0.06, -0.135, 1.185)
    ring_pts = [bc + V(0.062 * math.cos(a), 0, 0.062 * math.sin(a)) for a in [i / 14 * math.tau for i in range(14)]]
    ring_pts.append(ring_pts[0])
    mb.loft(ring_pts, 0.016, 0.02, n=6, part="buckle", mat=GEAR, side=(0, -1, 0), front=(0, 0, 1), cap0=None, cap1=None)
    mb.sphere(bc + V(0, 0.01, 0), (0.048, 0.012, 0.048), part="buckle_disc", mat=GEAR, n=10, rings=5)
    med = bc + V(0.0, -0.01, -0.12)
    mb.sphere(med, (0.032, 0.012, 0.045), part="medallion", mat=GEAR, n=10, rings=6)
    mb.sphere(med + V(0, -0.008, 0.0), (0.014, 0.008, 0.014), part="gold", mat=GEAR, n=8, rings=4)
    mb.ribbon([bc + V(0, -0.01, -0.06), med + V(0, 0, 0.04)], 0.012, part="strip_cord", mat=GEAR, normal_hint=(0, -1, 0))
    # --- cream loincloth strips hanging at the front from the sash (front view: 4-5 strips to mid thigh)
    for i, (x, ln, w) in enumerate([(-0.10, 0.36, 0.05), (-0.05, 0.42, 0.055), (0.0, 0.40, 0.05), (0.05, 0.33, 0.045),
                                    (0.09, 0.28, 0.04)]):
        top = V(x, -0.15 + 0.01 * abs(x) * 5, 1.14)
        mb.ribbon([top, top + V(0, -0.025, -ln * 0.4), top + V(0, -0.02, -ln)], [w, w * 0.95, w * 0.85],
                  part="strip_cream", mat=GEAR, normal_hint=(0, -1, 0), samples=6)
    # red bead strings beside the strips
    for x in (-0.015, 0.075):
        top = V(x, -0.16, 1.13)
        for k in range(6):
            mb.sphere(top + V(0, -0.012, -0.045 * k), 0.012, part="beads", mat=GEAR, n=6, rings=4)
    # --- olive leaf skirt panels around the sides/back of the hips (front view: olive panels each side)
    import random
    rnd = random.Random(3)
    for i in range(11):
        a = math.radians(-60 + 300 * i / 10.0 - 90)   # skip the front centre
        a = math.radians(210 - i * 24)
        if -0.6 < math.sin(a) < 0 and abs(math.cos(a)) < 0.45:
            continue
        c, s = math.cos(a), math.sin(a)
        top = V(0.19 * c, 0.03 + 0.145 * s, 1.15)
        ln = 0.62 + 0.12 * rnd.random()
        outv = V(c, s, 0)
        bot = top + outv * 0.12 + V(0, 0, -ln)
        mid = top.lerp(bot, 0.5) + outv * 0.03
        part = "leaf_olive" if i % 3 else "leaf_dark"
        mb.ribbon([top, mid, bot], [0.11, 0.12, 0.0], part=part, mat=GEAR, normal_hint=tuple(outv), samples=7,
                  across=2, curl=0.25, width_fn=lambda t, w: w * (1.0 - 0.9 * smoothstep(0.65, 1.0, t)) + 0.0)
    # --- chest bandages: diagonal strap L shoulder -> R hip, plus a horizontal chest wrap
    diag = []
    for i in range(13):
        a = i / 12 * math.tau
        # tilted ellipse around the torso
        p = V(0.215 * math.cos(a), 0.03 + 0.15 * math.sin(a), 1.42 + 0.17 * math.cos(a))
        diag.append(p)
    _strap(mb, diag, 0.055, "band_cream")
    wrap = [V(0.21 * math.cos(a), 0.03 + 0.148 * math.sin(a), 1.36 + 0.015 * math.sin(a)) for a in
            [i / 12 * math.tau for i in range(13)]]
    _strap(mb, wrap, 0.04, "band_cream")
    # chest pendant: gold ring + hanging bits
    pc = V(-0.02, -0.17, 1.50)
    rp = [pc + V(0.03 * math.cos(a), 0, 0.03 * math.sin(a)) for a in [i / 10 * math.tau for i in range(11)]]
    mb.loft(rp, 0.006, 0.006, n=5, part="gold", mat=GEAR, side=(0, -1, 0), front=(0, 0, 1), cap0=None, cap1=None)
    mb.sphere(pc + V(0, -0.005, -0.045), (0.012, 0.008, 0.02), part="gold", mat=GEAR, n=6, rings=4)
    # talisman tassel hanging on his left side of the chest (olive)
    tt = V(0.17, -0.11, 1.40)
    mb.ribbon([tt, tt + V(0.01, -0.01, -0.07)], 0.006, part="strip_cord", mat=GEAR, normal_hint=(0, -1, 0))
    mb.sphere(tt + V(0.01, -0.01, -0.09), (0.02, 0.015, 0.025), part="talisman", mat=GEAR, n=8, rings=5)
    for k in range(3):
        o = V(0.01 + (k - 1) * 0.012, -0.012, -0.11)
        mb.ribbon([tt + o, tt + o + V(0, 0, -0.08)], 0.012, part="strip_olive", mat=GEAR, normal_hint=(0, -1, 0))
    # upper-arm bandage wraps under the pauldrons
    for sx in (1, -1):
        sh, el = jm("shoulder.L" if sx > 0 else "shoulder.R"), jm("elbow.L" if sx > 0 else "elbow.R")
        for k in range(2):
            cen = sh.lerp(el, 0.38 + 0.12 * k)
            ax = (el - sh).normalized()
            X = ax.cross(V(0, 1, 0)).normalized()
            Y = ax.cross(X).normalized()
            pts = [cen + X * 0.072 * math.cos(a) + Y * 0.074 * math.sin(a) + ax * 0.01 * math.sin(a) for a in
                   [i / 10 * math.tau for i in range(11)]]
            _strap(mb, pts, 0.03, "band_cream", n_hint_center=cen)
    # --- dark mantle / hood: bunched collar behind the neck over both shoulders, cape over his RIGHT shoulder
    _mantle(mb)


def _band(mb, rings, part, mat, thick=0.01):
    """Closed band through several horizontal rings (outer surface only, tucked against the body)."""
    n = len(rings[0])
    idx = [[mb.add_v(p) for p in r] for r in rings]
    C = sum((rings[0][i] - rings[0][(i + 1) % n]).length for i in range(n))
    for k in range(len(rings) - 1):
        for i in range(n):
            j = (i + 1) % n
            q = [idx[k][i], idx[k][j], idx[k + 1][j], idx[k + 1][i]]
            uv = [(i / n * C, k * 0.04), ((i + 1) / n * C, k * 0.04), ((i + 1) / n * C, (k + 1) * 0.04),
                  (i / n * C, (k + 1) * 0.04)]
            mb.face(q, uv, mat, part)
    # top/bottom lips facing inward to give thickness at the edges
    for k, sgn in ((0, -1), (len(rings) - 1, 1)):
        inner = [mb.add_v(p + V(-p.x, -(p.y - 0.03), 0).normalized() * thick) for p in rings[k]]
        for i in range(n):
            j = (i + 1) % n
            q = [idx[k][i], idx[k][j], inner[j], inner[i]]
            mb.face(q, [(0, 0), (0.01, 0), (0.01, 0.01), (0, 0.01)], mat, part)


def _strap(mb, pts, width, part, n_hint_center=None):
    """Closed strap loop following pts around a body part (outer surface)."""
    m = len(pts)
    cen = n_hint_center if n_hint_center is not None else sum(pts[:-1], V(0, 0, 0)) / (m - 1)
    rows = []
    L = [0.0]
    for i in range(1, m):
        L.append(L[-1] + (pts[i] - pts[i - 1]).length)
    for i, p in enumerate(pts):
        T = (pts[(i + 1) % m] - pts[i - 1]).normalized() if 0 < i < m - 1 else (pts[1] - pts[-2]).normalized()
        out = (p - cen)
        out = (out - out.dot(T) * T).normalized()
        B = T.cross(out).normalized()
        rows.append((mb.add_v(p + B * width * 0.5 + out * 0.004), mb.add_v(p - B * width * 0.5 + out * 0.004), out))
    for i in range(m - 1):
        a, b = rows[i], rows[i + 1]
        q = [a[0], a[1], b[1], b[0]]
        uv = [(0, L[i]), (width, L[i]), (width, L[i + 1]), (0, L[i + 1])]
        va, vb, vd = mb.verts[q[0]], mb.verts[q[1]], mb.verts[q[3]]
        if (vb - va).cross(vd - va).dot(a[2]) < 0:
            q.reverse()
            uv.reverse()
        mb.face(q, uv, GEAR, part)


def _mantle(mb):
    import random
    rnd = random.Random(11)
    # collar/hood roll behind the neck from shoulder to shoulder (front view: hood bunched behind the neck)
    pts = []
    for i in range(11):
        a = math.radians(-20 + 220 * i / 10)  # wraps around the back
        pts.append(V(0.17 * math.cos(a), 0.05 + 0.12 * math.sin(a), 1.70 + 0.04 * math.sin(a)))
    mb.loft(pts, 0.055, 0.045, n=8, part="cloak_hood", mat=GEAR, side=(0, 0, 1), front=(0, 1, 0.3), samples=13,
            cap0="flat", cap1="flat",
            shape=lambda t, th, x, y: (x * (0.75 + 0.5 * math.sin(math.pi * t)), y * (0.8 + 0.5 * math.sin(math.pi * t))))
    # cape draped over his RIGHT shoulder (-X) and down the back (back view), ragged strips at the hem
    for k in range(7):
        u = k / 6.0
        x0 = -0.30 + 0.30 * u          # from the right shoulder tip toward the spine
        top = V(x0, 0.06 + 0.06 * (1 - u), 1.74 - 0.08 * (1 - u))
        ln = 0.75 + 0.2 * rnd.random() - 0.25 * u
        p1 = V(x0 * 1.05, 0.16 + 0.03 * (1 - u), 1.55)
        p2 = V(x0 * 1.1, 0.19, 1.35 - 0.05 * rnd.random())
        p3 = V(x0 * 1.1 + 0.02 * rnd.random(), 0.21, 1.72 - ln)
        mb.ribbon([top, p1, p2, p3], [0.1, 0.11, 0.1, 0.06], part="cloak_back", mat=GEAR, normal_hint=(0, 1, 0),
                  samples=8, across=2, curl=0.15)
    # over-shoulder flap (front side of the right shoulder)
    mb.ribbon([V(-0.28, 0.08, 1.75), V(-0.33, -0.02, 1.70), V(-0.34, -0.07, 1.58), V(-0.33, -0.08, 1.48)],
              [0.16, 0.18, 0.16, 0.10], part="cloak_back", mat=GEAR, normal_hint=(-1, -0.3, 0), samples=7, across=2,
              curl=0.2)
    # long dark cloak tails behind the legs (front view: dark tails behind the olive skirt to ~0.35 m)
    for k in range(6):
        u = k / 5.0
        a = math.radians(200 + 140 * u)
        c, s = math.cos(a), math.sin(a)
        top = V(0.2 * c, 0.03 + 0.15 * abs(s) + 0.02, 1.16)
        ln = 0.78 + 0.08 * rnd.random()
        bot = top + V(0.08 * c, 0.1, -ln)
        mb.ribbon([top, top.lerp(bot, 0.5) + V(0.02 * c, 0.03, 0), bot], [0.13, 0.15, 0.02], part="cloak_tail",
                  mat=GEAR, normal_hint=(c * 0.5, 1, 0), samples=7, across=2, curl=0.2)


# ---------------------------------------------------------------------------------------------- Morrow
MORROW_HEAD_R = 0.25
MORROW_HAFT = 0.78     # grip -> head centre, retracted


def build_morrow(mb):
    """Morrow in its own local frame: grip at origin, haft along -Z to the head centre at z=-MORROW_HAFT.
    Telescoping haft = 3 nested segments (parts morrow_seg0/1/2) so the rig can extend it."""
    import random
    rnd = random.Random(5)
    R = MORROW_HEAD_R
    hc = V(0, 0, -MORROW_HAFT)
    # head sphere (slightly lumpy)
    mb.sphere(hc, R, part="morrow_head", mat=MORROW, n=20, rings=14,
              deform=lambda ph, th, d: d * (1.0 + 0.025 * math.sin(3 * th + 2 * ph) * math.sin(5 * ph)))
    # spikes: fibonacci distribution, conical tan spikes on a ring stud
    pts = []
    N = 22
    for i in range(N):
        z = 1 - 2 * (i + 0.5) / N
        r = math.sqrt(1 - z * z)
        th = i * math.pi * (3 - math.sqrt(5))
        pts.append(V(r * math.cos(th), r * math.sin(th), z))
    core_dir = V(0, -1, -0.15).normalized()     # the red eye core faces forward when held
    for i, d in enumerate(pts):
        if d.dot(core_dir) > 0.8 or d.z > 0.88:
            continue   # leave room for the core eye and the haft socket
        base = hc + d * (R * 0.96)
        ln = 0.075 + 0.03 * rnd.random()
        if i % 3 == 0:
            # ring stud (cream disc with dark centre) instead of a spike
            mb.loft([base - d * 0.01, base + d * 0.018, base + d * 0.022], [0.045, 0.04, 0.02], [0.045, 0.04, 0.02],
                    n=10, part="morrow_stud", mat=MORROW, side=d.orthogonal(), front=d.cross(d.orthogonal()),
                    cap0=None, cap1="flat")
        else:
            mb.loft([base - d * 0.01, base + d * 0.02], [0.05, 0.042], [0.05, 0.042], n=10, part="morrow_stud",
                    mat=MORROW, side=d.orthogonal(), front=d.cross(d.orthogonal()), cap0=None, cap1="flat")
            mb.cone(base + d * 0.015, base + d * (0.02 + ln), 0.032, part="morrow_spike", mat=MORROW, n=7, segs=3,
                    side=d.orthogonal(), front=d.cross(d.orthogonal()), cap0=None)
    # core eye: glowing red dome set in a dark socket rim
    cc = hc + core_dir * (R * 0.93)
    mb.loft([cc - core_dir * 0.02, cc + core_dir * 0.025], [0.105, 0.098], [0.105, 0.098], n=16, part="morrow_rim",
            mat=MORROW, side=core_dir.orthogonal(), front=core_dir.cross(core_dir.orthogonal()), cap0=None, cap1=None)
    mb.sphere(cc + core_dir * 0.005, (0.09, 0.09, 0.05), part="morrow_core", mat=MORROW, n=16, rings=8,
              rot=core_dir.to_track_quat("Z", "Y").to_matrix())
    # haft: knotted, segmented column; 3 telescoping segments (outer = near the head)
    segs = [("morrow_seg2", 0.0, -0.30, 0.030), ("morrow_seg1", -0.26, -0.56, 0.034), ("morrow_seg0", -0.52, -0.80, 0.038)]
    for part, z0, z1, r in segs:
        zz = [z0 + (z1 - z0) * k / 8 for k in range(9)]
        rr = [r * (1.0 + 0.28 * math.exp(-((k % 4 - 2) / 0.7) ** 2)) for k in range(9)]
        mb.loft([V(0, 0, z) for z in zz], rr, rr, n=8, part=part, mat=MORROW, side=(1, 0, 0), front=(0, -1, 0),
                cap0="flat", cap1="flat",
                shape=lambda t, th, x, y: (x * (1 + 0.1 * math.sin(3 * th + t * 9)), y * (1 + 0.1 * math.cos(2 * th + t * 7))))
        # knots / ring collars
        for zc in (z0 - 0.01, (z0 + z1) / 2):
            mb.sphere(V(0, 0, zc), (r * 1.45, r * 1.45, 0.022), part=part, mat=MORROW, n=8, rings=4)
    # organic tendrils wrapping the haft near the head (front view)
    for k in range(3):
        a0 = k * math.tau / 3
        pts_t = [V(0.045 * math.cos(a0 + u * 5), 0.045 * math.sin(a0 + u * 5), -0.50 - 0.3 * u) for u in
                 [i / 8 for i in range(9)]]
        pts_t.append(hc + V(0.11 * math.cos(a0 + 5), 0.11 * math.sin(a0 + 5), R * 0.75))
        mb.loft(pts_t, [0.014, 0.011, 0.008], [0.014, 0.011, 0.008], n=5, part="morrow_seg0", mat=MORROW,
                side=(1, 0, 0), front=(0, -1, 0), samples=12, cap0="point", cap1="point")
    # pommel: tan spike below the grip (vertical study)
    mb.loft([V(0, 0, 0.0), V(0, 0, 0.05), V(0, 0, 0.09)], [0.036, 0.042, 0.03], [0.036, 0.042, 0.03], n=8,
            part="morrow_seg2", mat=MORROW, cap0="flat", cap1="flat")
    mb.cone(V(0, 0, 0.09), V(0, 0, 0.17), 0.026, part="morrow_pommel", mat=MORROW, n=7, segs=3)


# ---------------------------------------------------------------------------------------------- anatomy SDF
def _limb_rot(a, b):
    """Rotation matrix whose local Z runs a->b (for limb-aligned ellipsoids)."""
    d = (b - a).normalized()
    return d.to_track_quat("Z", "Y").to_matrix()


def anatomy():
    """Sculpted anatomy as smooth-union SDF groups (torso, neck, head, limbs). Mirrored L/R."""
    from common.sdf import SDF
    s = SDF()
    T = "torso"
    s.ellip((0, 0.03, 1.44), (0.185, 0.13, 0.19), T, 0.05)                 # ribcage
    s.ellip((0, 0.045, 1.575), (0.215, 0.115, 0.085), T, 0.05)             # shoulder girdle
    s.ellip((0, -0.005, 1.25), (0.13, 0.10, 0.16), T, 0.06)                 # abdomen
    s.ellip((0, 0.025, 1.025), (0.16, 0.115, 0.11), T, 0.06)                # pelvis
    for sx in (1, -1):
        s.ellip((sx * 0.085, -0.06, 1.485), (0.10, 0.06, 0.075), T, 0.04,
                rot=_rot_xyz(0.25, 0, sx * 0.25))                            # pectoral plates
        s.ellip((sx * 0.105, 0.015, 1.20), (0.065, 0.085, 0.12), T, 0.05)   # obliques
        s.ellip((sx * 0.075, 0.08, 0.985), (0.088, 0.075, 0.095), T, 0.04)  # glutes
        s.ellip((sx * 0.135, 0.065, 1.38), (0.07, 0.08, 0.15), T, 0.05)     # lats
        s.ellip((sx * 0.09, 0.06, 1.635), (0.095, 0.07, 0.06), T, 0.05)     # trapezius
        s.ellip((sx * 0.095, 0.115, 1.50), (0.075, 0.035, 0.09), T, 0.03)   # scapula plates
    N = "neck"
    pts = [(0, 0.035, 1.58), (0, 0.02, 1.70), (0, 0.003, 1.82), (0, 0.005, 1.93), (0, 0.035, 2.02)]
    rs = [0.088, 0.068, 0.057, 0.052, 0.046]
    for i in range(len(pts) - 1):
        s.rcone(pts[i], pts[i + 1], rs[i], rs[i + 1], N, 0.02)
    s.ellip((0, -0.035, 1.70), (0.035, 0.03, 0.11), N, 0.03)                # throat ridge
    H = "head"
    s.ellip((0, 0.025, 2.065), (0.068, 0.07, 0.058), H, 0.03)              # cranium
    s.rcone((0, -0.03, 2.045), (0, -0.215, 1.962), 0.048, 0.02, H, 0.04)    # snout
    s.ellip((0, -0.12, 2.012), (0.032, 0.07, 0.03), H, 0.03, rot=_rot_xyz(0.3, 0, 0))  # nasal ridge
    for sx in (1, -1):
        s.ellip((sx * 0.048, -0.025, 2.078), (0.032, 0.055, 0.02), H, 0.025, rot=_rot_xyz(0.15, 0, sx * 0.3))  # brow
        s.ellip((sx * 0.045, -0.05, 2.02), (0.03, 0.06, 0.028), H, 0.03)    # cheek
        s.ellip((sx * 0.05, 0.035, 2.03), (0.03, 0.04, 0.035), H, 0.03)     # jaw muscle
    s.rcone((0, 0.015, 1.99), (0, -0.19, 1.928), 0.036, 0.014, "jaw", 0.02)
    for side in ("L", "R"):
        sx = 1 if side == "L" else -1
        def m(p):
            return (p.x * sx if False else p.x, p.y, p.z)
        sh, el, wr = jm("shoulder." + side), jm("elbow." + side), jm("wrist." + side)
        hip, kn, an = jm("hip." + side), jm("knee." + side), jm("ankle." + side)
        U = "upperarm." + side
        s.ellip(tuple(sh + V(sx * 0.008, 0, -0.01)), (0.085, 0.09, 0.095), U, 0.04)   # deltoid
        s.rcone(tuple(sh), tuple(el), 0.06, 0.047, U, 0.03)
        r = _limb_rot(sh, el)
        s.ellip(tuple(sh.lerp(el, 0.5) + V(0, -0.022, 0)), (0.048, 0.045, 0.095), U, 0.04, rot=r)  # biceps
        s.ellip(tuple(sh.lerp(el, 0.45) + V(sx * 0.005, 0.028, 0)), (0.05, 0.05, 0.11), U, 0.04, rot=r)  # triceps
        F = "forearm." + side
        s.rcone(tuple(el), tuple(wr), 0.05, 0.034, F, 0.03)
        r = _limb_rot(el, wr)
        s.ellip(tuple(el.lerp(wr, 0.28) + V(sx * 0.012, -0.01, 0)), (0.054, 0.052, 0.12), F, 0.04, rot=r)
        s.ellip(tuple(el), (0.05, 0.05, 0.05), F, 0.03)
        TH = "thigh." + side
        s.rcone(tuple(hip + V(0, 0, 0.04)), tuple(kn), 0.098, 0.06, TH, 0.03)
        r = _limb_rot(hip, kn)
        s.ellip(tuple(hip.lerp(kn, 0.42) + V(sx * 0.008, -0.03, 0)), (0.085, 0.075, 0.19), TH, 0.05, rot=r)   # quads
        s.ellip(tuple(hip.lerp(kn, 0.40) + V(0, 0.038, 0)), (0.075, 0.068, 0.17), TH, 0.05, rot=r)            # hamstring
        s.ellip(tuple(hip.lerp(kn, 0.30) + V(-sx * 0.035, -0.005, 0)), (0.06, 0.065, 0.13), TH, 0.05, rot=r)  # adductor
        S_ = "shin." + side
        s.rcone(tuple(kn), tuple(an), 0.056, 0.04, S_, 0.03)
        r = _limb_rot(kn, an)
        s.ellip(tuple(kn.lerp(an, 0.28) + V(0, 0.035, 0)), (0.055, 0.058, 0.13), S_, 0.05, rot=r)   # calf
        s.ellip(tuple(kn.lerp(an, 0.35) + V(0, -0.025, 0)), (0.035, 0.03, 0.16), S_, 0.03, rot=r)   # shin plate
        s.ellip(tuple(kn), (0.058, 0.058, 0.062), S_, 0.03)
    return s


def _rot_xyz(rx, ry, rz):
    from mathutils import Euler
    return Euler((rx, ry, rz), "XYZ").to_matrix()


# parts whose low-poly vertices are snapped onto the anatomy SDF (part prefix -> SDF group)
SNAP = {"torso": "torso", "neck": "neck", "head": "head", "jaw": "jaw", "upperarm": "upperarm", "forearm": "forearm",
        "thigh": "thigh", "shin": "shin"}
