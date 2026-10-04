"""Skitter Mite creature (r ~0.5): rust-red mineral-stripping mite, 6 legs, mandibles, antennae. Rigged, procedural gait."""
import math

import numpy as np

import npc_lib as L

ID = "skitter_mite"
HEIGHT = 0.6
RIG = "creature"
WALK_SPEED = 2.6
SWING = 28.0
WALK_PERIOD = 0.4
PAL = {"rust": "#ff5a24", "dark": "#8a2a14", "chit": "#ffd070", "eye": "#140a0a", "glint": ("#ffe0a0", "glow")}
LEGS = []
A = np.array
TSCN = "creature"


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    b.add_bone("hips", (0, 0.1, 0.3), (0, 0.2, 0.3), "root")
    b.add_bone("head", (0, -0.2, 0.28), (0, -0.4, 0.27), "hips")
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.add_bone("ant" + s, (sg * 0.05, -0.36, 0.33), (sg * 0.22, -0.6, 0.55), "head")
        b.add_bone("mand" + s, (sg * 0.06, -0.38, 0.24), (sg * 0.02, -0.5, 0.2), "head")
        for i in range(3):
            z = -0.16 + i * 0.14
            hip, knee, foot = A((sg * 0.12, z, 0.28)), A((sg * 0.36, z + (i - 1) * 0.08, 0.42)), A((sg * 0.52, z + (i - 1) * 0.2, 0.0))
            na, nb = "leg%da%s" % (i, s), "leg%db%s" % (i, s)
            b.add_bone(na, tuple(hip), tuple(knee), "hips")
            b.add_bone(nb, tuple(knee), tuple(foot), na)
            LEGS.append(((na, nb), sg, 0.0 if (i + (sg > 0)) % 2 == 0 else 0.5, 0.45))
            b.limb(hip, knee, 0.035, 0.03, na, "dark", seg=5)
            b.limb(knee, foot, 0.03, 0.01, nb, "dark", seg=5)
    b.ball((0, 0.16, 0.3), (0.3, 0.3, 0.22), "hips", "rust", seg=8, rings=5)
    b.ball((0, 0.18, 0.38), (0.16, 0.18, 0.1), "hips", "chit", seg=6, rings=3)
    b.ball((0, -0.12, 0.28), (0.17, 0.15, 0.14), "hips", "dark", seg=7, rings=4)
    b.ball((0, -0.3, 0.27), (0.14, 0.12, 0.11), "head", "rust", seg=7, rings=4)
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.spike(A((sg * 0.06, -0.38, 0.24)), A((sg * 0.02, -0.52, 0.2)), 0.035, "mand" + s, "chit", seg=4)
        b.limb(A((sg * 0.05, -0.36, 0.33)), A((sg * 0.22, -0.6, 0.55)), 0.015, 0.006, "ant" + s, "dark", seg=3)
        b.ball(A((sg * 0.08, -0.36, 0.32)), 0.04, "head", "eye", seg=5, rings=3)
        b.ball(A((sg * 0.09, -0.39, 0.34)), 0.012, "head", "glint", seg=4, rings=2)
    return b


def idle_pose(w):
    return {"head": (3 * math.sin(w), 0, 5 * math.sin(w * 1.3)), "ant.L": (6 * math.sin(w * 2), 0, 0), "ant.R": (-6 * math.sin(w * 2), 0, 0)}


def walk_pose(w):
    return {"head": (0, 0, 4 * math.sin(w)), "ant.L": (8 * math.sin(w * 2), 0, 0), "ant.R": (8 * math.cos(w * 2), 0, 0)}


def attack_pose(u):
    k = math.sin(math.pi * u) ** 1.5
    return {"head": (22 * k, 0, 0), "mand.L": (0, 0, 25 * k), "mand.R": (0, 0, -25 * k), "hips": (-10 * k, 0, 0)}


def telegraph_pose(u):
    k = 0.5 + 0.5 * math.sin(math.tau * u * 3)
    return {"hips": (-20, 0, 0), "head": (-10, 0, 0), "mand.L": (0, 0, -22 * k), "mand.R": (0, 0, 22 * k)}


def react_pose(k):
    return {"hips": (-14 * k, 0, 8 * k), "head": (-12 * k, 0, 0)}
