"""Dominion survey drone (r ~0.6, hover): gunmetal disc, four rotor rings (spinning bones), red visor band, sensor pod."""
import math

import numpy as np

import npc_lib as L

ID = "dominion_drone"
HEIGHT = 0.7
RIG = "creature"
WALK_SPEED = 3.0
WALK_PERIOD = 1.0
IDLE_T = 3.0
ATTACK_T = 0.75
PAL = {"gun": "#6a7488", "dark": "#3a3e4c", "red": "#ff3a2c", "visor": ("#ff3a22", "glow"), "lens": ("#ff6a40", "glow")}
LEGS = []
A = np.array


def build():
    b = L.Builder(ID, HEIGHT, {}, [], PAL)
    b.add_bone("hips", (0, 0, 0.3), (0, 0, 0.5), "root")
    b.add_bone("pod", (0, -0.1, 0.05), (0, -0.25, -0.1), "hips")
    for i in range(4):
        a = math.tau * (i + 0.5) / 4
        d = A((math.cos(a), math.sin(a), 0))
        c = d * 0.72 + A((0, 0, 0.38))
        b.add_bone("rotor%d" % i, tuple(c), tuple(c + A((0, 0, 0.1))), "hips")
        b.limb(d * 0.3 + A((0, 0, 0.3)), c - d * 0.2, 0.04, 0.035, "hips", "dark", seg=4)
        for k in range(8):
            a0, a1 = math.tau * k / 8, math.tau * (k + 1) / 8
            r0, r1 = 0.24, 0.2
            b.quad(c + A((math.cos(a0) * r0, math.sin(a0) * r0, 0)), c + A((math.cos(a1) * r0, math.sin(a1) * r0, 0)),
                   c + A((math.cos(a1) * r1, math.sin(a1) * r1, 0)), c + A((math.cos(a0) * r1, math.sin(a0) * r1, 0)), "rotor%d" % i, "gun" if k % 2 else "dark")
        b.box(c, (0.46, 0.05, 0.02), "rotor%d" % i, "dark")
        b.box(c, (0.05, 0.46, 0.02), "rotor%d" % i, "dark")
    b.ball((0, 0, 0.3), (0.42, 0.42, 0.2), "hips", "gun", seg=10, rings=4)
    b.ball((0, 0, 0.45), (0.3, 0.3, 0.14), "hips", "dark", seg=8, rings=3)
    b.ball((0, 0, 0.2), (0.28, 0.28, 0.12), "hips", "dark", seg=8, rings=3)
    b.ball((0, -0.4, 0.31), (0.3, 0.07, 0.07), "hips", "visor", seg=8, rings=3)
    b.box((0, 0, 0.32), (0.9, 0.06, 0.04), "hips", "red")
    b.limb(A((0, -0.1, 0.18)), A((0, -0.25, 0.02)), 0.07, 0.05, "pod", "dark", seg=5)
    b.ball(A((0, -0.27, 0.0)), 0.05, "pod", "lens", seg=5, rings=3)
    return b


def idle_pose(w):
    return {"hips_loc": (0, 0, 0.03 * math.sin(w)), "hips": (2 * math.sin(w), 0, 0), "pod": (8 * math.sin(w * 1.7), 0, 0)}


def walk_pose(w):
    return {"hips": (-10, 0, 0), "hips_loc": (0, 0, 0.02 * math.sin(w * 2))}


def attack_pose(u):
    k = math.sin(math.pi * u) ** 1.3
    return {"hips": (20 * k, 0, 0), "hips_loc": (0, -0.3 * k, 0)}


def telegraph_pose(u):
    k = 0.5 + 0.5 * math.sin(math.tau * u * 4)
    return {"hips": (-14, 0, 0), "pod": (25 * k, 0, 0)}


def react_pose(k):
    return {"hips": (-18 * k, 0, 14 * k)}


def spin_pose(u):
    p = {}
    for i in range(4):
        p["rotor%d" % i] = (0, 0, 360.0 * u * (1 if i % 2 else -1))
    return p
TSCN = "creature"
