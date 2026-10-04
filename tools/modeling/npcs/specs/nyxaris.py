"""Nyxaris: 2.0 m crystal-petalled fluff-crab. Violet-black body, white fluff ruff, glowing pink eyes, crystal petal fan on the back, four cyan-clawed legs, raised fluffy forearms."""
import math

import numpy as np

import npc_lib as L

ID = "nyxaris"
HEIGHT = 2.0
RIG = "creature"
WALK_SPEED = 1.3
SWING = 16.0
PAL = {
    "body": "#4a2d78", "body2": "#6b45a8", "fluff": "#fff2f8", "fluff2": "#e6c8f0", "pink": "#ff4aa8", "pink2": "#ffa0d8", "ice": "#7ee8ff",
    "eye": ("#ff4ab8", "glow"), "drop": ("#ff6ac8", "glow"), "bone": "#fff0d8", "claw": "#2a1850",
}
LEGS = []


def pair(b, name, h, t, parent, sided=False):
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.add_bone(name + s, (h[0] * sg, h[1], h[2]), (t[0] * sg, t[1], t[2]), parent + s if sided else parent)


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    A = np.array
    b.add_bone("hips", (0, 0.4, 0.95), (0, -0.1, 1.0), "root")
    b.add_bone("chest", (0, -0.1, 1.0), (0, -0.55, 1.1), "hips")
    b.add_bone("head", (0, -0.55, 1.1), (0, -0.95, 1.15), "chest")
    pair(b, "ant", (0.1, -0.8, 1.35), (0.45, -1.0, 1.95), "head")
    b.add_bone("petals", (0, 0.3, 1.25), (0, 0.42, 2.0), "hips")
    pair(b, "arm", (0.35, -0.45, 1.15), (0.7, -0.85, 1.45), "chest")
    pair(b, "farm", (0.7, -0.85, 1.45), (0.78, -1.15, 1.95), "arm", sided=True)
    legs = []
    for li, (y, yk, yt) in enumerate(((-0.25, -0.45, -0.7), (0.3, 0.35, 0.55), (0.75, 0.9, 1.15))[:2]):
        n = "leg%d" % li
        pair(b, n + "a", (0.4, y, 0.95), (1.05, yk, 1.45), "hips")
        pair(b, n + "b", (1.05, yk, 1.45), (1.6, yt, 0.0), n + "a", sided=True)
    for li in range(2):
        for sg, s in ((1, ".L"), (-1, ".R")):
            ph = (0.0 if (li + (sg > 0)) % 2 == 0 else 0.5)
            LEGS.append((("leg%da%s" % (li, s), "leg%db%s" % (li, s)), sg, ph, 2.2))
    # --- body
    b.ball((0, 0.4, 1.0), (0.55, 0.75, 0.45), "hips", "body", seg=9, rings=6)
    b.ball((0, 0.4, 1.3), (0.4, 0.55, 0.2), "hips", "body2", seg=8, rings=4)
    b.ball((0, -0.3, 1.05), (0.42, 0.5, 0.4), "chest", "body", seg=9, rings=5)
    # fluffy ruff around the neck + shoulders
    for k in range(16):
        a = 2 * math.pi * k / 16
        c = A((0.4 * math.cos(a), -0.58 + 0.08 * math.sin(a), 1.1 + 0.3 * math.sin(a) * 0.9))
        b.spike(c, c + A((0.35 * math.cos(a), -0.2 + 0.1 * math.sin(a), 0.3 * math.sin(a))), 0.1, "chest", "fluff" if k % 2 else "fluff2", seg=4)
    # head
    b.ball((0, -0.78, 1.12), (0.3, 0.32, 0.27), "head", "body", seg=9, rings=5)
    b.ball((0, -0.95, 1.05), (0.2, 0.15, 0.17), "head", "fluff", seg=7, rings=4)
    for sg, rr, z in ((1, 0.09, 1.2), (-1, 0.09, 1.2), (1, 0.05, 1.07), (-1, 0.05, 1.07)):
        b.ball((sg * 0.2, -0.98, z), (rr, 0.05, rr), "head", "eye", seg=6, rings=4)
    for sg in (1, -1):
        b.spike((sg * 0.07, -1.05, 0.98), (sg * 0.11, -1.25, 0.8), 0.035, "head", "bone", seg=4)
        b.spike((sg * 0.28, -0.8, 1.38), (sg * 0.4, -0.7, 1.6), 0.05, "head", "fluff", seg=4)
    # antennae with glowing crystal drops
    for sg, s in ((1, ".L"), (-1, ".R")):
        pts = [A((sg * 0.1, -0.8, 1.35)), A((sg * 0.25, -0.9, 1.7)), A((sg * 0.45, -1.0, 1.95)), A((sg * 0.7, -1.05, 1.8))]
        b.tube(pts, [0.025, 0.02, 0.015, 0.01], "ant" + s, "claw", seg=4)
        b.ball(pts[-1] + (0, 0, -0.1), (0.05, 0.05, 0.1), "ant" + s, "drop", seg=5, rings=3)
    # crystal petal fan on the back
    for k in range(13):
        u = (k - 6) / 6.0
        ang = u * 1.15
        base = A((0.0, 0.3 + 0.1 * abs(u), 1.3))
        tip = base + A((math.sin(ang) * (0.9 + 0.2 * (k % 2)), 0.25 + 0.2 * (1 - abs(u)), 0.95 * math.cos(ang * 0.8) * (0.8 + 0.3 * ((k + 1) % 2))))
        c = ("pink", "ice", "pink2")[k % 3]
        b.leaf(base, tip, 0.35, (0, 1, 0), "petals", c, n=3, bend=(0, 0.05, 0))
    # legs: dark segments, white fluff tufts at the knees, cyan claw tips
    for li in range(2):
        for sg, s in ((1, ".L"), (-1, ".R")):
            y, yk, yt = ((-0.25, -0.45, -0.7), (0.3, 0.35, 0.55))[li]
            hip, knee, tip = A((sg * 0.4, y, 0.95)), A((sg * 1.05, yk, 1.45)), A((sg * 1.6, yt, 0.0))
            b.limb(hip, knee, 0.13, 0.1, "leg%da%s" % (li, s), "body", seg=6)
            b.limb(knee, tip, 0.1, 0.03, "leg%db%s" % (li, s), "body2", seg=6)
            for k in range(5):
                a = k * 1.25
                b.spike(knee + A((0, 0, 0)), knee + A((0.2 * math.cos(a) + sg * 0.05, 0.2 * math.sin(a), 0.1 + 0.12 * (k % 2))), 0.06, "leg%db%s" % (li, s), "fluff", seg=4)
            b.spike(tip + A((-sg * 0.02, 0, 0.35)), tip + A((sg * 0.05, 0.0, -0.02)), 0.045, "leg%db%s" % (li, s), "ice", seg=4)
    # raised fluffy forearms with pink claws
    for sg, s in ((1, ".L"), (-1, ".R")):
        sh, el, wr = A((sg * 0.35, -0.45, 1.15)), A((sg * 0.7, -0.85, 1.45)), A((sg * 0.78, -1.15, 1.95))
        b.limb(sh, el, 0.14, 0.12, "arm" + s, "body", seg=6)
        b.limb(el, wr, 0.14, 0.09, "farm" + s, "fluff", seg=6)
        for k in range(3):
            b.spike(wr + A((0.03 * (k - 1) * sg, 0, 0)), wr + A((sg * (0.06 + 0.03 * (k - 1)), -0.1, 0.25)), 0.035, "farm" + s, "pink", seg=4)
    return b


# --- procedural body motion (armature axes, degrees)
def idle_pose(w):
    s = math.sin(w)
    return {"chest": (1.5 * s, 0, 0), "head": (2 * math.sin(w * 0.5), 0, 4 * math.sin(w)), "petals": (3 * s, 0, 0),
            "arm.L": (4 * s, 0, 0), "arm.R": (-4 * s, 0, 0)}


def walk_pose(w):
    return {"chest": (0, 0, 3 * math.sin(w)), "petals": (3 * math.sin(2 * w), 0, 4 * math.sin(w)), "head": (0, 0, -4 * math.sin(w))}


def talk_pose(w):
    return {"head": (6 * math.sin(2 * w), 0, 8 * math.sin(w)), "chest": (3 * math.sin(w), 0, 0),
            "arm.L": (-10 + 14 * math.sin(w), 0, 15 * math.sin(w)), "arm.R": (-8 - 12 * math.sin(w), 0, -15 * math.sin(w)),
            "farm.L": (12 * math.sin(w * 2), 0, 0), "farm.R": (-12 * math.sin(w * 2), 0, 0), "petals": (5 * math.sin(w), 0, 0)}


def gesture_pose(u):
    k = math.sin(math.pi * u) ** 1.2
    return {"arm.L": (-45 * k, 0, 25 * k), "arm.R": (-45 * k, 0, -25 * k), "farm.L": (-25 * k, 0, 0), "farm.R": (-25 * k, 0, 0),
            "petals": (10 * k, 0, 0), "head": (-8 * k, 0, 0)}


def react_pose(k):
    return {"chest": (-12 * k, 0, 0), "head": (-14 * k, 0, 8 * k), "petals": (-10 * k, 0, 0), "arm.L": (20 * k, 0, 0), "arm.R": (20 * k, 0, 0)}
