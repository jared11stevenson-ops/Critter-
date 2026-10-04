"""Solmara: 5.5 m sea-spider tide balancer. Tiny body, 8 very long ivory/gold/navy legs, long beak proboscis, gold sun disc with rays and a black-and-white moon crescent."""
import math

import numpy as np

import npc_lib as L

ID = "solmara"
HEIGHT = 5.5
RIG = "creature"
WALK_SPEED = 1.4
SWING = 9.0
EMIT = 2.2
PAL = {
    "ivory": "#fff0d0", "ivory2": "#e8cc9c", "gold": "#ffb430", "sun": ("#ffc23a", "glow"), "ray": ("#ffa820", "glow"), "navy": "#2f56c0",
    "navy2": "#1c2f78", "eye": "#0c1030", "glint": ("#9bd8ff", "glow"), "moon": "#f4f6ff", "moonk": "#14122a", "silk": "#9fe0ff", "rust": "#c8682a",
}
LEGS = []
A = np.array


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    b.add_bone("hips", (0, 0.35, 3.1), (0, -0.2, 3.15), "root")
    b.add_bone("head", (0, -0.2, 3.15), (0, -1.1, 3.0), "hips")
    b.add_bone("sun", (0, 0.1, 3.8), (0, 0.15, 4.9), "hips")
    b.add_bone("moon", (0.9, -0.1, 3.9), (1.5, -0.1, 4.7), "hips")
    ys = (-1.0, -0.35, 0.35, 1.0)
    for li, y in enumerate(ys):
        for sg, s in ((1, ".L"), (-1, ".R")):
            hip = A((sg * 0.35, y * 0.5, 3.1))
            knee = A((sg * 1.3, y * 2.0, 4.5))
            ank = A((sg * 2.6, y * 2.9, 1.6))
            tip = A((sg * 3.1, y * 3.3, 0.0))
            pts = [hip, knee, ank, tip]
            names = ["leg%d%s%s" % (li, c, s) for c in "abc"]
            par = "hips"
            for k, nm in enumerate(names):
                b.add_bone(nm, tuple(pts[k]), tuple(pts[k + 1]), par)
                par = nm
            L_ = sum(np.linalg.norm(pts[i + 1] - pts[i]) for i in range(3))
            ph = 0.0 if (li + (sg > 0)) % 2 == 0 else 0.5
            LEGS.append((tuple(names), sg, ph, L_ * 0.7))
            # geometry: ivory plates, navy joint balls, gold edging
            b.limb(hip, knee, 0.13, 0.1, names[0], "ivory", seg=6)
            b.limb(knee, ank, 0.1, 0.07, names[1], "navy", seg=6)
            b.limb(ank, tip, 0.07, 0.015, names[2], "ivory2", seg=5)
            b.ball(knee, 0.14, names[0], "gold", seg=6, rings=4)
            b.ball(ank, 0.1, names[1], "navy2", seg=6, rings=3)
            b.ball((knee * 0.5 + ank * 0.5), (0.11, 0.11, 0.11), names[1], "gold", seg=5, rings=3)
    # body + abdomen + head with proboscis and eyes
    b.ball((0, 0.2, 3.1), (0.5, 0.75, 0.38), "hips", "ivory", seg=9, rings=5)
    b.ball((0, 0.2, 3.35), (0.3, 0.5, 0.12), "hips", "gold", seg=7, rings=3)
    b.ball((0, -0.45, 3.12), (0.38, 0.4, 0.34), "head", "navy2", seg=8, rings=5)
    b.limb(A((0, -0.7, 3.1)), A((0, -1.6, 2.7)), 0.14, 0.04, "head", "ivory", seg=6)
    b.limb(A((0, -0.9, 3.04)), A((0, -1.55, 2.76)), 0.05, 0.03, "head", "gold", seg=5)
    for sg in (1, -1):
        b.ball((sg * 0.28, -0.62, 3.3), (0.13, 0.1, 0.15), "head", "eye", seg=7, rings=4)
        b.ball((sg * 0.28, -0.7, 3.36), (0.04, 0.03, 0.04), "head", "glint", seg=4, rings=3)
    # sun disc (gold) with radiating spikes, behind and above the head
    sc = A((0, 0.2, 4.0))
    b.ball(sc, (0.9, 0.18, 0.9), "sun", "sun", seg=12, rings=5, rot=(0, 0, 0))
    b.ball(sc + (0, -0.12, 0), (0.55, 0.12, 0.55), "sun", "gold", seg=10, rings=4)
    for k in range(18):
        a = 2 * math.pi * k / 18
        r0, r1 = 0.85, (1.5 if k % 2 else 1.15)
        b.spike(sc + A((math.cos(a) * r0, 0, math.sin(a) * r0)), sc + A((math.cos(a) * r1, 0, math.sin(a) * r1)), 0.09, "sun", "ray", seg=4)
    # moon crescent: white disc with a black disc biting it, off to the right of the head
    mc = A((1.0, -0.1, 4.2))
    b.ball(mc, (0.45, 0.1, 0.45), "moon", "moon", seg=10, rings=4)
    b.ball(mc + (0.18, -0.07, 0.0), (0.4, 0.1, 0.4), "moon", "moonk", seg=10, rings=4)
    b.spike(A((1.0, -0.1, 4.6)), A((1.2, -0.1, 5.5)), 0.06, "moon", "ivory", seg=4)
    return b


def idle_pose(w):
    return {"sun": (0, 0, 5 * math.sin(w)), "moon": (0, 0, -5 * math.sin(w)), "head": (2 * math.sin(w), 0, 3 * math.sin(w * 0.5))}


def walk_pose(w):
    return {"hips": (0, 0, 3 * math.sin(w)), "sun": (0, 0, 8 * math.sin(w)), "head": (0, 0, -4 * math.sin(w))}


def talk_pose(w):
    return {"head": (5 * math.sin(w * 2), 0, 8 * math.sin(w)), "sun": (0, 0, 12 * math.sin(w)), "moon": (0, 0, -12 * math.sin(w)),
            "leg0a.L": (6 * math.sin(w), 0, 0), "leg0a.R": (-6 * math.sin(w), 0, 0)}


def gesture_pose(u):
    k = math.sin(math.pi * u) ** 1.2
    return {"sun": (0, 0, 25 * k), "moon": (0, 0, -25 * k), "head": (-8 * k, 0, 0), "leg0a.L": (-20 * k, 0, 0), "leg0a.R": (-20 * k, 0, 0)}


def react_pose(k):
    return {"head": (-12 * k, 0, 0), "sun": (0, 0, 20 * k), "leg0a.L": (15 * k, 0, 0), "leg0a.R": (15 * k, 0, 0)}
