"""Dust Grazer creature (r ~0.9): passive long-legged lichen grazer; sand body slung between six stilt legs, long neck, grazing head."""
import math

import numpy as np

import npc_lib as L

ID = "dust_grazer"
HEIGHT = 2.5
RIG = "creature"
WALK_SPEED = 1.2
SWING = 14.0
PAL = {"sand": "#f0b070", "sand2": "#a06a40", "lichen": "#7ad07a", "stripe": "#e04a30", "eye": "#140a0a", "glint": ("#ffe0a0", "glow")}
LEGS = []
A = np.array


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    b.add_bone("hips", (0, 0.3, 2.0), (0, -0.2, 2.0), "root")
    b.add_bone("neck", (0, -0.6, 2.0), (0, -1.35, 1.45), "hips")
    b.add_bone("head", (0, -1.35, 1.45), (0, -1.7, 1.38), "neck")
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.add_bone("ant" + s, (sg * 0.06, -1.6, 1.48), (sg * 0.35, -1.9, 1.95), "head")
        for i in range(3):
            z = -0.35 + i * 0.4
            hip, knee, foot = A((sg * 0.3, z, 1.9)), A((sg * 0.95, z + (i - 1) * 0.3, 2.5)), A((sg * 1.15, z + (i - 1) * 0.7, 0.0))
            na, nb = "leg%da%s" % (i, s), "leg%db%s" % (i, s)
            b.add_bone(na, tuple(hip), tuple(knee), "hips")
            b.add_bone(nb, tuple(knee), tuple(foot), na)
            LEGS.append(((na, nb), sg, 0.0 if (i + (sg > 0)) % 2 == 0 else 0.5, 2.2))
            b.limb(hip, knee, 0.08, 0.07, na, "sand", seg=5)
            b.limb(knee, foot, 0.07, 0.025, nb, "sand2", seg=5)
    b.ball((0, 0.3, 2.0), (0.48, 0.75, 0.38), "hips", "sand", seg=9, rings=5)
    b.ball((0, 0.45, 2.22), (0.36, 0.55, 0.16), "hips", "lichen", seg=7, rings=3)
    for i in range(3):
        b.ball((0, 0.85 - i * 0.32, 1.98), (0.5, 0.08, 0.06), "hips", "stripe", seg=6, rings=3)
    b.ball((0, -0.45, 1.95), (0.28, 0.3, 0.26), "hips", "sand2", seg=7, rings=4)
    b.limb(A((0, -0.6, 2.0)), A((0, -1.35, 1.45)), 0.13, 0.09, "neck", "sand", seg=6)
    b.ball((0, -1.5, 1.38), (0.17, 0.25, 0.15), "head", "sand2", seg=7, rings=4)
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.limb(A((sg * 0.06, -1.6, 1.48)), A((sg * 0.35, -1.9, 1.95)), 0.02, 0.01, "ant" + s, "sand2", seg=3)
        b.ball(A((sg * 0.12, -1.58, 1.42)), 0.045, "head", "eye", seg=5, rings=3)
        b.ball(A((sg * 0.13, -1.62, 1.44)), 0.012, "head", "glint", seg=4, rings=2)
    return b


def idle_pose(w):
    graze = 0.5 + 0.5 * math.sin(w * 0.8)
    return {"neck": (18 * graze, 0, 0), "head": (8 * graze, 0, 0), "ant.L": (5 * math.sin(w * 2), 0, 0), "ant.R": (-5 * math.sin(w * 2), 0, 0)}


def walk_pose(w):
    return {"neck": (-6 + 4 * math.sin(w * 2), 0, 0), "head": (0, 0, 4 * math.sin(w)), "hips": (0, 0, 3 * math.sin(w))}


def attack_pose(u):
    k = math.sin(math.pi * u)
    return {"neck": (-20 * k, 0, 0), "hips": (6 * k, 0, 0)}


def telegraph_pose(u):
    return {"neck": (-25, 0, 0), "hips": (-8, 0, 0)}


def react_pose(k):
    return {"neck": (-20 * k, 0, 10 * k), "hips": (-5 * k, 0, 5 * k)}
TSCN = "creature"
