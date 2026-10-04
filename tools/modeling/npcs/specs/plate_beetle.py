"""Plate Beetle creature (r ~1.4): slow heavy lichen grazer, layered slate plates, horned mandibles, orange belly, glow eyes."""
import math

import numpy as np

import npc_lib as L

ID = "plate_beetle"
HEIGHT = 1.6
RIG = "creature"
WALK_SPEED = 1.7
SWING = 16.0
PAL = {"slate": "#5a6a8a", "slate2": "#8294b4", "dark": "#2f3548", "belly": "#e08a44", "lichen": "#7ad058", "eye": ("#ffb040", "glow"), "horn": "#c8d0e0"}
LEGS = []
A = np.array


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    b.add_bone("hips", (0, 0.4, 0.8), (0, 0.0, 0.85), "root")
    b.add_bone("head", (0, -0.9, 0.85), (0, -1.5, 0.8), "hips")
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.add_bone("mand" + s, (sg * 0.28, -1.55, 0.65), (sg * 0.12, -2.1, 0.6), "head")
        for i in range(3):
            z = -0.7 + i * 0.7
            hip, knee, foot = A((sg * 0.8, z, 0.7)), A((sg * 1.45, z + (i - 1) * 0.25, 1.0)), A((sg * 1.75, z + (i - 1) * 0.5, 0.0))
            na, nb = "leg%da%s" % (i, s), "leg%db%s" % (i, s)
            b.add_bone(na, tuple(hip), tuple(knee), "hips")
            b.add_bone(nb, tuple(knee), tuple(foot), na)
            LEGS.append(((na, nb), sg, 0.0 if (i + (sg > 0)) % 2 == 0 else 0.5, 1.4))
            b.limb(hip, knee, 0.14, 0.12, na, "dark", seg=6)
            b.limb(knee, foot, 0.12, 0.05, nb, "dark", seg=6)
    b.ball((0, 0.15, 0.75), (1.05, 1.35, 0.5), "hips", "belly", seg=9, rings=5)
    for i in range(5):
        z = 1.05 - i * 0.48
        w = 1.12 - abs(i - 1.5) * 0.09
        b.ball((0, z, 1.08 + math.sin(i * 0.9) * 0.05), (w, 0.42, 0.36), "hips", "slate" if i % 2 else "slate2", seg=9, rings=4)
        b.ball((0, z - 0.05, 1.3), (w * 0.55, 0.3, 0.12), "hips", "slate2", seg=7, rings=3)
    for i in range(4):
        b.ball(((i - 1.5) * 0.35, 0.5 - i * 0.3, 1.42), (0.16, 0.14, 0.08), "hips", "lichen", seg=5, rings=3)
    b.ball((0, -1.25, 0.8), (0.55, 0.45, 0.42), "head", "dark", seg=8, rings=5)
    b.ball((0, -1.2, 1.05), (0.45, 0.38, 0.16), "head", "slate", seg=8, rings=3)
    for sg, s in ((1, ".L"), (-1, ".R")):
        b.spike(A((sg * 0.28, -1.55, 0.65)), A((sg * 0.12, -2.1, 0.6)), 0.13, "mand" + s, "horn", seg=5)
        b.ball(A((sg * 0.32, -1.6, 0.92)), 0.09, "head", "eye", seg=6, rings=3)
        b.limb(A((sg * 0.2, -1.55, 1.05)), A((sg * 0.55, -1.95, 1.5)), 0.04, 0.015, "head", "dark", seg=4)
    return b


def idle_pose(w):
    return {"head": (3 * math.sin(w), 0, 6 * math.sin(w * 0.7)), "hips": (1.5 * math.sin(w), 0, 0)}


def walk_pose(w):
    return {"head": (0, 0, 5 * math.sin(w)), "hips": (0, 0, 2 * math.sin(w))}


def attack_pose(u):
    k = math.sin(math.pi * u) ** 1.4
    return {"head": (25 * k, 0, 0), "mand.L": (0, 0, 30 * k), "mand.R": (0, 0, -30 * k), "hips": (8 * k, 0, 0)}


def telegraph_pose(u):
    k = 0.5 + 0.5 * math.sin(math.tau * u * 2)
    return {"hips": (-16, 0, 0), "head": (-14, 0, 0), "mand.L": (0, 0, -20 * k), "mand.R": (0, 0, 20 * k)}


def react_pose(k):
    return {"hips": (-6 * k, 0, 6 * k), "head": (-16 * k, 0, 0)}
TSCN = "creature"
