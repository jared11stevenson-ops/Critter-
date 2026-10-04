"""Aruun HQ sculpt: signed-distance anatomy + separate chitin shells (high-poly bake sources).

Every component is meshed on its own (marching cubes), decimated separately for the game mesh, and baked
high->low per component. Measurements from design/model_sheets/aruun/hires (side/back at 2.40 m):
the stance leans forward (feet back, chest/neck forward), long feet (0.40 m), wide A-stance, neck rising
from the FRONT-top of a hunched torso, horns rising and leaning forward with hooked tips.

Blender space: Z up, character faces -Y, his LEFT is +X. Joint table J is shared with the rig.
"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from common.sdf2 import (ellipsoid, capsule, tube, rbox, halfspace, torus, union, smooth_union, intersect,  # noqa
                         subtract, offset, shell_cut, displace, mirror_x, transform, bbox_guard, euler, rot_to,
                         fbm, ridged, voronoi, T)
import torch  # noqa: E402

V = np.array

# ------------------------------------------------------------------------------------------------ skeleton
J = {
    "root": V([0, 0.0, 0.0]),
    "hips": V([0, -0.03, 1.00]),
    "spine1": V([0, -0.025, 1.15]),
    "spine2": V([0, -0.035, 1.32]),
    "chest": V([0, -0.05, 1.47]),
    "neck1": V([0, -0.085, 1.66]),
    "neck2": V([0, -0.105, 1.78]),
    "neck3": V([0, -0.105, 1.90]),
    "head": V([0, -0.095, 2.01]),
    "head_end": V([0, -0.30, 2.0]),
    "jaw": V([0, -0.115, 1.995]),
    "jaw_end": V([0, -0.27, 1.955]),
    "clavicle.L": V([0.045, -0.06, 1.60]),
    "shoulder.L": V([0.205, -0.02, 1.585]),
    "elbow.L": V([0.28, 0.065, 1.30]),
    "wrist.L": V([0.33, 0.035, 0.975]),
    "hand_end.L": V([0.345, 0.02, 0.825]),
    "hip.L": V([0.13, -0.025, 0.975]),
    "knee.L": V([0.185, 0.0, 0.585]),
    "ankle.L": V([0.205, 0.085, 0.235]),
    "toe.L": V([0.275, -0.07, 0.055]),
    "toe_end.L": V([0.33, -0.19, 0.03]),
}


def jm(n):
    if n.endswith(".R"):
        p = J[n[:-2] + ".L"].copy()
        p[0] = -p[0]
        return p
    return J[n].copy()


def lerp(a, b, t):
    return a + (b - a) * t


def frame(a, b, side=(1, 0, 0)):
    """Rotation (local->world) with local Z along a->b, local X ~ side."""
    z = b - a
    z = z / np.linalg.norm(z)
    x = np.asarray(side, float)
    x = x - (x @ z) * z
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    return np.stack([x, y, z], 1)


def at(a, b, t, side=0.0, front=0.0, sidev=(1, 0, 0)):
    """Point at fraction t along a->b, offset along the limb frame (side = +local X, front = -local Y... -> we use
    front = toward -Y world)."""
    R = frame(a, b, sidev)
    p = lerp(a, b, t) + R[:, 0] * side
    p = p + np.array([0, -1.0, 0]) * front
    return p


# ------------------------------------------------------------------------------------------------ detail fields
def chitin_detail(amp=0.0012, freq=60.0, seed=3):
    """Pitted / micro-cracked chitin: voronoi cell walls raised slightly + pits."""
    def fn(P):
        f1, f2 = voronoi(P, freq, seed)
        edge = torch.clamp(1.0 - (f2 - f1) * 6.0, 0, 1)
        pits = torch.clamp(0.25 - f1, 0, 1) * 4
        return amp * (0.6 * fbm(P, freq * 0.25, 3, seed + 5) - 0.8 * pits - 0.5 * edge)
    return fn


def skin_detail(amp=0.0009, seed=7):
    def fn(P):
        return amp * (fbm(P, 45.0, 3, seed) + 0.5 * ridged(P, 18.0, 2, seed + 3) - 0.5)
    return fn


def disp(f, fn):
    return lambda P: f(P) - fn(P)


# ------------------------------------------------------------------------------------------------ body
def _arm(side):
    s = 1 if side == "L" else -1
    sh, el, wr, he = jm("shoulder." + side), jm("elbow." + side), jm("wrist." + side), jm("hand_end." + side)
    sv = (s, 0, 0)
    Ru = frame(sh, el, sv)
    Rf = frame(el, wr, sv)
    fs = [
        capsule(sh, el, 0.056, 0.043),
        ellipsoid(at(sh, el, 0.05, s * 0.012), (0.075, 0.072, 0.07), Ru),                       # deltoid mass
        ellipsoid(at(sh, el, 0.48, 0, 0.022), (0.042, 0.04, 0.095), Ru),                       # biceps
        ellipsoid(at(sh, el, 0.42, s * 0.006, -0.026), (0.048, 0.044, 0.11), Ru),               # triceps
        capsule(el, wr, 0.044, 0.031),
        ellipsoid(at(el, wr, 0.25, s * 0.012, 0.0), (0.05, 0.046, 0.11), Rf),                  # forearm flexors
        ellipsoid(at(el, wr, 0.0, 0, -0.02), (0.035, 0.035, 0.035), Rf),                        # elbow point
    ]
    arm = smooth_union(fs, 0.035)
    return arm


def _hand(side, fist):
    """Clawed four-fingered hand + thumb. fist=True curls fingers around a haft (right hand holds Morrow)."""
    s = 1 if side == "L" else -1
    wr, he = jm("wrist." + side), jm("hand_end." + side)
    R = frame(wr, he, (s, 0, 0))        # local z down the hand, x outward, y = back of hand (+Y-ish)
    # make the palm face inward (-x): local axes ok. palm centre:
    pc = lerp(wr, he, 0.33)
    palm = rbox(pc, (0.022, 0.042, 0.045), 0.018, R)
    parts = [palm, capsule(wr, pc, 0.032, 0.03)]
    claws = []
    knuck_z = 0.075
    for i, off in enumerate((-0.03, -0.01, 0.01, 0.03)):
        base = wr + R[:, 2] * knuck_z + R[:, 1] * off + R[:, 0] * (-0.003)
        ln = (0.032, 0.026, 0.02) if i not in (1, 2) else (0.036, 0.03, 0.022)
        curl = (0.55, 0.9, 1.1) if fist else (0.25, 0.35, 0.45)
        d = R[:, 2].copy()
        pts = [base]
        ang = 0.0
        for k in range(3):
            ang += curl[k]
            # curl toward the palm (-x local)
            dirv = R[:, 2] * math.cos(ang) - R[:, 0] * math.sin(ang)
            pts.append(pts[-1] + dirv * ln[k])
        rad = [0.012, 0.011, 0.0095, 0.008]
        parts.append(tube(pts, rad, 0.006))
        # knuckle plate bump
        parts.append(ellipsoid(base + R[:, 0] * 0.008, (0.012, 0.013, 0.012), R))
        tipdir = pts[-1] - pts[-2]
        tipdir /= np.linalg.norm(tipdir)
        hook = tipdir * math.cos(0.5) - R[:, 0] * math.sin(0.5)
        claws.append(tube([pts[-1] - tipdir * 0.006, pts[-1] + tipdir * 0.018, pts[-1] + tipdir * 0.026 + hook * 0.012],
                          [0.008, 0.005, 0.0012], 0.0))
    # thumb from the inner side
    tb = wr + R[:, 2] * 0.03 + R[:, 0] * (-0.02) + R[:, 1] * (-0.025)
    tc = (0.5, 0.6) if fist else (0.25, 0.3)
    tpts = [tb]
    dirv = R[:, 2] * 0.5 - R[:, 0] * 0.6 - R[:, 1] * 0.5
    dirv /= np.linalg.norm(dirv)
    for k, ln in enumerate((0.03, 0.026)):
        dirv = dirv * math.cos(tc[k]) + (-R[:, 0]) * math.sin(tc[k])
        dirv /= np.linalg.norm(dirv)
        tpts.append(tpts[-1] + dirv * ln)
    parts.append(tube(tpts, [0.014, 0.012, 0.009], 0.006))
    tdir = (tpts[-1] - tpts[-2]) / np.linalg.norm(tpts[-1] - tpts[-2])
    claws.append(tube([tpts[-1] - tdir * 0.005, tpts[-1] + tdir * 0.02], [0.008, 0.0012]))
    return smooth_union(parts, 0.012), union(claws)


def _leg(side):
    s = 1 if side == "L" else -1
    hp, kn, an = jm("hip." + side), jm("knee." + side), jm("ankle." + side)
    sv = (s, 0, 0)
    Rt = frame(hp, kn, sv)
    Rs = frame(kn, an, sv)
    fs = [
        capsule(hp + V([0, 0, 0.03]), kn, 0.12, 0.078),
        ellipsoid(at(hp, kn, 0.45, s * 0.016, 0.04), (0.112, 0.102, 0.22), Rt),       # quads
        ellipsoid(at(hp, kn, 0.70, s * 0.04, 0.035), (0.07, 0.06, 0.12), Rt),         # vastus lateralis
        ellipsoid(at(hp, kn, 0.72, -s * 0.035, 0.03), (0.056, 0.054, 0.095), Rt),     # vastus medialis
        ellipsoid(at(hp, kn, 0.42, 0, -0.045), (0.104, 0.096, 0.21), Rt),            # hamstrings
        ellipsoid(at(hp, kn, 0.28, -s * 0.04, 0.0), (0.078, 0.08, 0.15), Rt),        # adductors
        ellipsoid(at(kn, an, 0.0, 0, 0.012), (0.062, 0.06, 0.066), Rs),               # knee
        capsule(kn, an, 0.068, 0.046),
        ellipsoid(at(kn, an, 0.27, s * 0.018, -0.048), (0.07, 0.072, 0.145), Rs),     # gastrocnemius lateral
        ellipsoid(at(kn, an, 0.24, -s * 0.02, -0.046), (0.07, 0.072, 0.14), Rs),     # gastrocnemius medial
        ellipsoid(at(kn, an, 0.45, 0, 0.022), (0.036, 0.032, 0.17), Rs),              # tibialis ridge
    ]
    return smooth_union(fs, 0.04)


def _foot(side):
    """Long beetle foot: heel, tarsal body, three forward toes with claws, a rear spur."""
    s = 1 if side == "L" else -1
    an, toe, te = jm("ankle." + side), jm("toe." + side), jm("toe_end." + side)
    heel = an + V([0, 0.075, -0.17])
    parts = [
        capsule(an + V([0, 0, 0.02]), an + V([0, 0.01, -0.12]), 0.042, 0.05),
        ellipsoid(heel + V([0, -0.01, 0.025]), (0.048, 0.06, 0.045)),
        capsule(an + V([0, 0.0, -0.13]), toe + V([0, 0.03, 0.0]), 0.05, 0.042),
        ellipsoid(lerp(an, toe, 0.65) + V([0, 0.0, -0.035]), (0.06, 0.09, 0.035)),    # sole pad
    ]
    claws = []
    for k, (ox, ln, dz) in enumerate(((-0.035, 0.10, 0.0), (0.0, 0.125, 0.004), (0.035, 0.095, 0.0))):
        fwd = toe - an
        fwd[2] = 0
        fwd /= np.linalg.norm(fwd)                       # foot yaw (toes turned out, sheet back view)
        lat = V([-fwd[1], fwd[0], 0.0]) * s
        b = toe + lat * ox - fwd * 0.02
        dirv = fwd + lat * ox * 0.9 + V([0, 0, -0.12])
        dirv /= np.linalg.norm(dirv)
        p1 = b + dirv * ln * 0.5 + V([0, 0, 0.012])
        p2 = b + dirv * ln
        parts.append(tube([b, p1, p2], [0.026, 0.022, 0.017], 0.01))
        tip = p2 + dirv * 0.045 + V([0, 0, -0.03])
        claws.append(tube([p2 - dirv * 0.004, p2 + dirv * 0.03 + V([0, 0, -0.006]), tip], [0.015, 0.009, 0.0015]))
    # rear spur (dewclaw) on the inner heel
    sp = heel + V([-s * 0.03, 0.03, 0.03])
    claws.append(tube([sp, sp + V([-s * 0.01, 0.045, -0.02]), sp + V([-s * 0.012, 0.06, -0.045])], [0.012, 0.007, 0.0015]))
    foot = intersect(smooth_union(parts, 0.03), lambda P: -P[:, 2])     # flat sole: nothing below the ground
    return foot, union(claws)


SUB = {}     # sub-fields of the body (torso, neck, arm.L, leg.L, ...) for conformal plates


def body_field():
    T_ = []
    tilt = euler(0.18, 0, 0)
    T_ += [
        ellipsoid((0, -0.035, 1.42), (0.16, 0.122, 0.185), tilt),                   # ribcage
        ellipsoid((0, 0.045, 1.50), (0.165, 0.115, 0.15), euler(0.35, 0, 0)),        # hunched upper back
        ellipsoid((0, -0.03, 1.575), (0.2, 0.105, 0.072), euler(0.2, 0, 0)),         # shoulder girdle
        ellipsoid((0, -0.06, 1.24), (0.118, 0.098, 0.15)),                           # abdomen
        ellipsoid((0, -0.01, 1.03), (0.16, 0.125, 0.115)),                           # pelvis
        capsule((0, -0.06, 1.58), (0, -0.092, 1.70), 0.08, 0.06),                    # neck root
    ]
    for s in (1, -1):
        T_ += [
            ellipsoid((s * 0.08, -0.14, 1.465), (0.088, 0.05, 0.068), euler(0.3, 0, s * 0.3)),    # pectoral
            ellipsoid((s * 0.1, -0.06, 1.20), (0.058, 0.078, 0.12)),                           # obliques
            ellipsoid((s * 0.09, 0.085, 0.975), (0.115, 0.1, 0.12)),                          # glutes
            ellipsoid((s * 0.125, 0.04, 1.37), (0.068, 0.085, 0.15), euler(0.25, 0, 0)),        # lats
            ellipsoid((s * 0.085, 0.0, 1.62), (0.10, 0.075, 0.06), euler(0.4, 0, s * -0.3)),    # trapezius
            ellipsoid((s * 0.095, 0.115, 1.48), (0.075, 0.035, 0.095), euler(0.35, 0, 0)),     # scapula
        ]
        for k, z in enumerate((1.33, 1.25, 1.17)):                                         # abdominal segments
            T_.append(ellipsoid((s * 0.043, -0.136 + k * 0.006, z), (0.04, 0.022, 0.034)))
    torso = smooth_union(T_, 0.05)
    neck = tube([V([0, -0.09, 1.66]), V([0, -0.105, 1.78]), V([0, -0.105, 1.90]), V([0, -0.098, 2.0])],
                [0.06, 0.047, 0.042, 0.04], 0.03)
    SUB["torso"], SUB["neck"] = torso, neck
    parts = [torso, neck]
    claws = []
    for side in ("L", "R"):
        SUB["arm." + side] = _arm(side)
        hand, hc = _hand(side, fist=(side == "R"))
        SUB["hand." + side] = hand
        SUB["leg." + side] = _leg(side)
        ft, fc = _foot(side)
        SUB["foot." + side] = ft
        parts += [SUB["arm." + side], hand, SUB["leg." + side], ft]
        claws.append(fc)
        claws.append(hc)
    body = smooth_union(parts, 0.025)
    return body, union(claws)


# ------------------------------------------------------------------------------------------------ head
HEAD_C = V([0, -0.08, 2.07])


def head_fields():
    """Beetle-mask head (sheet side: ~0.23 m long, eye high at the back, deep snout pointing forward-down ending in
    a mandible hook). Separate: jaw, eyes, fangs."""
    c = HEAD_C
    H = [
        ellipsoid(c + V([0, 0.015, 0.0]), (0.064, 0.072, 0.068)),                     # cranium
        ellipsoid(c + V([0, 0.055, -0.02]), (0.055, 0.045, 0.055)),                    # occiput / nape cap
        capsule(c + V([0, -0.03, -0.005]), c + V([0, -0.115, -0.06]), 0.048, 0.03),     # deep snout
        ellipsoid(c + V([0, -0.07, 0.0]), (0.03, 0.07, 0.032), euler(0.55, 0, 0)),      # nasal ridge (face plate)
        capsule(c + V([0, -0.115, -0.06]), c + V([0, -0.145, -0.075]), 0.03, 0.02),
    ]
    for s in (1, -1):
        H += [
            ellipsoid(c + V([s * 0.045, -0.025, 0.035]), (0.032, 0.052, 0.022), euler(0.2, 0, s * 0.35)),  # brow
            ellipsoid(c + V([s * 0.042, -0.05, -0.03]), (0.028, 0.055, 0.03), euler(0.45, 0, s * 0.12)),  # cheek
            ellipsoid(c + V([s * 0.05, 0.03, -0.035]), (0.028, 0.04, 0.035)),                          # jaw muscle
        ]
    head = smooth_union(H, 0.028)
    # crown ridge plates (red crown on the sheet): a raised keel and two side crests
    crown = [ellipsoid(c + V([0, 0.0, 0.06]), (0.018, 0.06, 0.018), euler(-0.2, 0, 0))]
    for s in (1, -1):
        crown.append(ellipsoid(c + V([s * 0.035, 0.01, 0.05]), (0.012, 0.05, 0.02), euler(-0.1, 0, s * 0.4)))
    head = smooth_union([head] + crown, 0.012)
    hook = tube([c + V([0, -0.14, -0.07]), c + V([0, -0.17, -0.08]), c + V([0, -0.185, -0.1]),
                 c + V([0, -0.178, -0.125])], [0.019, 0.014, 0.009, 0.002], 0.008)
    head = smooth_union([head, hook], 0.012)
    for s in (1, -1):
        head = subtract(head, ellipsoid(c + V([s * 0.06, -0.035, 0.018]), (0.02, 0.027, 0.019)), 0.006)
    eyes = union([ellipsoid(c + V([s * 0.055, -0.035, 0.018]), (0.016, 0.023, 0.016)) for s in (1, -1)])
    jw = [capsule(c + V([0, 0.01, -0.06]), c + V([0, -0.12, -0.1]), 0.036, 0.016)]
    for s in (1, -1):
        jw.append(capsule(c + V([s * 0.036, 0.03, -0.045]), c + V([s * 0.016, -0.09, -0.09]), 0.017, 0.012))
    jaw = smooth_union(jw, 0.02)
    fangs = union([tube([c + V([s * 0.02, -0.105, -0.07]), c + V([s * 0.021, -0.11, -0.105])], [0.0055, 0.001])
                   for s in (1, -1)])
    return head, jaw, eyes, fangs


def horn_field():
    """Two red horns from the crown, leaning ~40 deg forward (sheet side), diverging (sheet back), tips hooking
    outward-down with flat notched blades; knobbed tines along the shaft; ring ridges at the base."""
    c = HEAD_C
    fs = []
    for s in (1, -1):
        pts = [c + V([s * 0.025, -0.02, 0.05]), c + V([s * 0.04, -0.05, 0.12]), c + V([s * 0.055, -0.09, 0.19]),
               c + V([s * 0.07, -0.13, 0.245]), c + V([s * 0.09, -0.17, 0.285]), c + V([s * 0.115, -0.2, 0.305]),
               c + V([s * 0.14, -0.215, 0.297]), c + V([s * 0.158, -0.215, 0.27])]
        rad = [0.022, 0.0185, 0.0165, 0.015, 0.0135, 0.012, 0.0105, 0.0065]
        fs.append(tube(pts, rad, 0.01))
        for i, dv, ln in ((2, V([s * 1.0, 0.3, 0.2]), 0.034), (3, V([-s * 0.5, 0.6, 0.5]), 0.028),
                          (4, V([s * 0.3, 0.6, 0.8]), 0.03), (5, V([0.2 * s, 0.1, 1.0]), 0.026)):
            dv = dv / np.linalg.norm(dv)
            b = pts[i]
            e = b + dv * ln
            fs.append(tube([b, e], [0.0085, 0.0055], 0.006))
            fs.append(ellipsoid(e, (0.0075, 0.0075, 0.0075)))
        tip = pts[-1]
        blade = subtract(ellipsoid(tip + V([s * 0.004, 0.0, -0.01]), (0.015, 0.0055, 0.02), euler(0, 0, s * 0.3)),
                         ellipsoid(tip + V([0, 0.0, -0.03]), (0.005, 0.02, 0.008)), 0.002)
        fs.append(blade)
        for i in range(1, 4):
            fs.append(torus(lerp(pts[i - 1], pts[i], 0.6), rad[i] * 0.95, 0.0038, rot_to((0, 0, 1), pts[i] - pts[i - 1])))
    return union(fs)


def tine_field():
    """Bone tines at the temples (cream), pointing out/back with knobs, plus small cheek tines."""
    c = HEAD_C
    fs = []
    for s in (1, -1):
        b = c + V([s * 0.055, 0.015, 0.03])
        pts = [b, b + V([s * 0.045, 0.02, 0.005]), b + V([s * 0.08, 0.045, -0.005]), b + V([s * 0.1, 0.06, -0.02])]
        fs.append(tube(pts, [0.011, 0.009, 0.007, 0.0045], 0.006))
        fs.append(tube([pts[1], pts[1] + V([s * 0.01, 0.0, 0.032])], [0.0055, 0.004], 0.004))
        fs.append(ellipsoid(pts[1] + V([s * 0.01, 0.0, 0.032]), (0.0055, 0.0055, 0.0055)))
        b2 = c + V([s * 0.05, -0.01, -0.035])
        fs.append(tube([b2, b2 + V([s * 0.045, 0.03, -0.025]), b2 + V([s * 0.06, 0.055, -0.055])], [0.008, 0.0055, 0.002], 0.004))
    return union(fs)


def fringe_field():
    """Pale-yellow / olive fringe strands sweeping back from the nape (tapered strands)."""
    c = HEAD_C
    rng = np.random.default_rng(5)
    fs = []
    for k in range(15):
        a = -1.3 + 2.6 * k / 14
        base = c + V([0.06 * math.sin(a), 0.045 + 0.02 * math.cos(a), 0.015 - 0.04 * abs(math.sin(a))])
        out = V([math.sin(a) * 0.9, 0.9, -0.35 - rng.uniform(0, 0.5)])
        out /= np.linalg.norm(out)
        ln = rng.uniform(0.08, 0.14)
        p1 = base + out * ln * 0.5 + V([0, 0, 0.008])
        p2 = base + out * ln + V([0, 0.01, -0.03])
        fs.append(tube([base, p1, p2], [0.0085, 0.006, 0.0012], 0.004))
    return union(fs)


# ------------------------------------------------------------------------------------------------ chitin plates
def _ss(e0, e1, x):
    t = torch.clamp((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def neck_rings():
    """Telescoping dorsal neck plates, open at the throat: each ring hugs the neck at its top and flares at its
    lower edge, overlapping the ring below."""
    neck = SUB["neck"]
    zs = [(1.665, 1.765), (1.75, 1.845), (1.83, 1.92), (1.905, 1.985)]
    segs = []
    for z0, z1 in zs:
        def base(P, z0=z0, z1=z1):
            t = _ss(z1, z0, P[:, 2])              # 0 at the top, 1 at the bottom edge
            return neck(P) - (0.0025 + 0.0012 * t)
        region = intersect(intersect(lambda P, z0=z0: z0 - P[:, 2], lambda P, z1=z1: P[:, 2] - z1),
                           halfspace((0, -1, 0.0), (0, -0.118, 0)), 0.004)
        segs.append(shell_cut(base, 0.0062, region, 0.003))
    return union(segs)


def _patch(base, center, radii, R, thick, lift=0.002, k=0.005):
    """Conformal plate: shell over `base` (a body sub-field) clipped by an ellipsoidal region (oval outline)."""
    return shell_cut(base, thick, ellipsoid(center, radii, R), k, lift)


def plates():
    out = {}
    for side in ("L", "R"):
        s = 1 if side == "L" else -1
        sh, el, wr = jm("shoulder." + side), jm("elbow." + side), jm("wrist." + side)
        hp, kn, an = jm("hip." + side), jm("knee." + side), jm("ankle." + side)
        arm, leg = SUB["arm." + side], SUB["leg." + side]
        hi = 1.0 if side == "L" else 0.0     # sheet asymmetry: left pauldron higher / forward
        # PAULDRON: rounded ladybug-elytron dome covering the shoulder ball, with a rolled rim, and two lames
        pc = sh + V([s * 0.04, 0.03 - 0.02 * hi, -0.005 + 0.02 * hi])
        Rp = euler(0.08, s * -0.3, 0)
        cut_n = V([s * 0.55, -0.15, -1.0])
        cut_p = pc + V([0, 0, -0.06])
        dome = shell_cut(ellipsoid(pc, (0.1, 0.106, 0.097), Rp), 0.013, halfspace(cut_n, cut_p), 0.005)
        rim = intersect(torus(cut_p + V([s * 0.006, 0, 0.006]), 0.087, 0.008, rot_to((0, 0, 1), -cut_n)),
                        lambda P: -halfspace(cut_n, cut_p - cut_n / np.linalg.norm(cut_n) * 0.012)(P))
        lames = []
        Ru = frame(sh, el, (s, 0, 0))
        for k in range(2):
            lc = at(sh, el, 0.2 + 0.13 * k, s * 0.025)
            lames.append(_patch(arm, lc, (0.075, 0.09, 0.045), Ru, 0.008, lift=0.006 - 0.002 * k))
        out["pauldron." + side] = (union([dome, rim]), "upperarm." + side)
        out["lame." + side] = (union(lames), "upperarm." + side)
        # UPPER ARM: oval plate on the outer arm
        out["armplate." + side] = (_patch(arm, at(sh, el, 0.62, s * 0.05), (0.05, 0.06, 0.09), Ru, 0.008),
                                   "upperarm." + side)
        # FOREARM BRACER: big domed red plate over the outer forearm (elbow->wrist), wrist cuff, elbow cap
        Rf = frame(el, wr, (s, 0, 0))
        bc = at(el, wr, 0.5, s * 0.045, 0.01)
        bracer = _patch(offset(arm, 0.004), bc, (0.06, 0.07, 0.19), Rf, 0.011, lift=0.002)
        cuff = shell_cut(offset(arm, 0.003), 0.009,
                         intersect(halfspace(-Rf[:, 2], at(el, wr, 0.86)), halfspace(Rf[:, 2], at(el, wr, 0.97))), 0.003)
        out["bracer." + side] = (union([bracer, cuff]), "forearm." + side)
        out["elbowcap." + side] = (_patch(arm, el + V([0, 0.04, 0.0]), (0.045, 0.04, 0.05), Rf, 0.009), "forearm." + side)
        # KNEE CAP + lower knee scale
        Rs = frame(kn, an, (s, 0, 0))
        out["kneecap." + side] = (union([_patch(leg, kn + V([0, -0.06, 0.005]), (0.055, 0.05, 0.06), Rs, 0.011, 0.003),
                                         _patch(leg, at(kn, an, 0.12) + V([0, -0.05, 0]), (0.045, 0.04, 0.04), Rs, 0.008, 0.001)]),
                                  "shin." + side)
        # SHIN: two overlapping plates down the front of the shin
        segs = [_patch(leg, at(kn, an, 0.36) + V([0, -0.05, 0]), (0.05, 0.05, 0.15), Rs, 0.009, 0.003),
                _patch(leg, at(kn, an, 0.74) + V([0, -0.04, 0]), (0.045, 0.045, 0.12), Rs, 0.009, 0.0015)]
        out["shinplate." + side] = (union(segs), "shin." + side)
        # THIGH: small outer hip scale (most of the thigh is painted on the sheet, not armoured)
        Rt = frame(hp, kn, (s, 0, 0))
        out["thighplate." + side] = (_patch(leg, at(hp, kn, 0.2, s * 0.08), (0.06, 0.08, 0.1), Rt, 0.009), "thigh." + side)
        # HAND back plate
        he = jm("hand_end." + side)
        Rh = frame(wr, he, (s, 0, 0))
        out["handplate." + side] = (_patch(SUB["hand." + side], lerp(wr, he, 0.33) + Rh[:, 0] * 0.03,
                                           (0.03, 0.05, 0.05), Rh, 0.007), "hand." + side)
        # FOOT: two tarsal scutes on top
        toe = jm("toe." + side)
        ft = SUB["foot." + side]
        fps = [_patch(ft, lerp(an, toe, t) + V([0, 0, 0.05]), (0.06, 0.07, 0.05), None, 0.008, 0.002 - 0.001 * k)
               for k, t in enumerate((0.3, 0.6))]
        out["footplate." + side] = (union(fps), "foot." + side)
    # BACK CARAPACE: pronotum + 3 tergites stepping down the hunched spine (each overlaps the one below)
    torso = SUB["torso"]
    segs = []
    for k, (cz, rz) in enumerate(((1.57, 0.07), (1.48, 0.055), (1.40, 0.05), (1.32, 0.045))):
        band = intersect(ellipsoid(V([0, 0.14, cz]), (0.2 - 0.02 * k, 0.16, 0.3), euler(0.3, 0, 0)),
                         intersect(halfspace((0, 0.3, 1), V([0, 0.12, cz + rz])),
                                   halfspace((0, -0.3, -1), V([0, 0.12, cz - rz]))), 0.02)
        segs.append(shell_cut(torso, 0.011, band, 0.005, 0.002 + 0.004 * (3 - k)))
    out["carapace"] = (union(segs), "chest")
    # STERNUM: cream overlapping plates down the chest
    st = [_patch(torso, V([0, -0.17, cz]), (w, 0.08, rz), euler(0.25, 0, 0), 0.008, lift=0.002 + 0.003 * (2 - k))
          for k, (cz, w, rz) in enumerate(((1.51, 0.1, 0.05), (1.43, 0.085, 0.045), (1.36, 0.07, 0.04)))]
    out["sternum"] = (union(st), "chest")
    return out


# ------------------------------------------------------------------------------------------------ components
def components():
    """name -> dict(field, lo, hi, step, kind, bind, budget). kind: skin|chitin|bone|eye|claw|horn|fringe."""
    body, claws = body_field()
    head, jaw, eyes, fangs = head_fields()
    C = {}
    C["body"] = dict(field=disp(body, skin_detail()), lo=(-0.45, -0.38, 0.0), hi=(0.45, 0.30, 2.06), step=0.003,
                     kind="skin", bind="auto", budget=11000)
    C["claws"] = dict(field=claws, lo=(-0.45, -0.40, 0.0), hi=(0.45, 0.35, 1.1), step=0.0015, kind="claw",
                      bind="auto", budget=1600)
    C["head"] = dict(field=disp(head, chitin_detail(0.0008, 90)), lo=HEAD_C - 0.25, hi=HEAD_C + 0.15, step=0.0018,
                     kind="chitin", bind="head", budget=2400)
    C["jaw"] = dict(field=disp(jaw, chitin_detail(0.0006, 90, 9)), lo=HEAD_C - 0.2, hi=HEAD_C + 0.1, step=0.0018,
                    kind="chitin", bind="jaw", budget=500)
    C["eyes"] = dict(field=eyes, lo=HEAD_C - 0.1, hi=HEAD_C + 0.1, step=0.0012, kind="eye", bind="head", budget=200)
    C["fangs"] = dict(field=fangs, lo=HEAD_C - 0.2, hi=HEAD_C + 0.05, step=0.001, kind="bone", bind="jaw", budget=100)
    C["horns"] = dict(field=disp(horn_field(), chitin_detail(0.0007, 120, 4)), lo=HEAD_C + V([-0.25, -0.28, 0.0]),
                      hi=HEAD_C + V([0.25, 0.05, 0.34]), step=0.0018, kind="horn", bind="head", budget=2400)
    C["tines"] = dict(field=tine_field(), lo=HEAD_C - 0.2, hi=HEAD_C + 0.2, step=0.0015, kind="bone", bind="head",
                      budget=500)
    C["fringe"] = dict(field=fringe_field(), lo=HEAD_C + V([-0.2, -0.05, -0.2]), hi=HEAD_C + V([0.2, 0.25, 0.1]),
                       step=0.0015, kind="fringe", bind="head", budget=700)
    C["neckrings"] = dict(field=disp(neck_rings(), chitin_detail(0.0007, 70, 6)), lo=(-0.12, -0.22, 1.6),
                          hi=(0.12, 0.02, 2.02), step=0.002, kind="chitin", bind="neck", budget=1400)
    for name, (f, bone) in plates().items():
        C[name] = dict(field=disp(f, chitin_detail(0.0009, 55, sum(map(ord, name)) % 97)), lo=None, hi=None,
                       step=0.0022, kind="chitin", bind=bone, budget=None)
    return C
