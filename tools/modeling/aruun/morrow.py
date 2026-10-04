"""Morrow: Aruun's telescoping mace (detail_morrow.png): dark forged/stone ball with cream bone bosses (concentric
rings), forged conical spikes, a large red Thoughtstone core set in a bezel (cracked, emissive veins in the
texture), claw-prong collar, telescoping haft (3 segments: grip = bone `weapon`, middle = `weapon_ext1`,
upper + head = `weapon_ext2`), leather-wrapped grip, pommel spike.

Built in a local frame (grip at the origin, haft along -Z) and placed in the right fist by MORROW_M.
"""
import math
import os
import sys

import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from common.sdf2 import (ellipsoid, capsule, tube, torus, union, smooth_union, intersect, subtract, offset,  # noqa
                         shell_cut, halfspace, euler, rot_to, fbm, ridged, voronoi, transform, sphere, T)
import sculpt as S  # noqa: E402

V = np.array
HEAD_Z = -0.78
HEAD_R = 0.25


def grip_frame():
    """World placement: grip point inside the right fist, haft running forward-down-outward."""
    wr, he = S.jm("wrist.R"), S.jm("hand_end.R")
    R = S.frame(wr, he, (-1, 0, 0))
    grip = wr + R[:, 2] * 0.075 - R[:, 0] * 0.012
    axis = V([-0.35, -0.42, -0.84])         # = HAFT_CARRY (Agent 4 carry pose)
    axis = axis / np.linalg.norm(axis)                 # world direction of local -Z
    z = -axis
    x = np.cross(V([0, -1.0, 0]), z)
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    Rm = np.stack([x, y, z], 1)
    M = np.eye(4)
    M[:3, :3] = Rm
    M[:3, 3] = grip
    return M


def _fib(n):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    th = math.pi * (1 + 5 ** 0.5) * i
    return np.stack([np.cos(th) * np.sin(phi), np.sin(th) * np.sin(phi), np.cos(phi)], 1)


def _core_dir_local():
    M = grip_frame()
    want = V([-0.55, -0.75, 0.35])                      # face out/forward/up so the core reads on screen
    want /= np.linalg.norm(want)
    d = M[:3, :3].T @ want
    return d / np.linalg.norm(d)


def local_fields():
    """name -> (local field, kind, bone)."""
    hc = V([0, 0, HEAD_Z])
    cd = _core_dir_local()
    dirs = _fib(30)
    top = V([0, 0, 1.0])
    dirs = [d for d in dirs if d @ top < 0.82 and d @ cd < 0.85]
    spikes, bosses = [], []
    for k, d in enumerate(dirs):
        if k % 2 == 0:
            spikes.append(d)
        else:
            bosses.append(d)

    def hammered(P):
        f1, f2 = voronoi(P, 38.0, 71)
        return 0.0022 * torch.clamp(f2 - f1, 0, 0.5) * 2 + 0.0015 * fbm(P, 20.0, 3, 72)

    ball = sphere(hc, HEAD_R)
    ball = subtract(ball, sphere(hc + cd * (HEAD_R + 0.04), 0.13), 0.01)          # socket for the core
    ball = lambda P, b=ball: b(P) - hammered(P)
    parts = [ball]
    for d in bosses:
        c = hc + d * HEAD_R
        R = rot_to((0, 0, 1), d)
        parts.append(subtract(ellipsoid(c, (0.045, 0.045, 0.02), R), ellipsoid(c + d * 0.02, (0.025, 0.025, 0.012), R), 0.003))
    head = smooth_union(parts, 0.006)
    sp = []
    rng = np.random.default_rng(4)
    for d in spikes:
        b = hc + d * (HEAD_R - 0.01)
        ln = rng.uniform(0.07, 0.1)
        # forged: slightly bent, hexagonal-ish via a ridged displacement
        bend = np.cross(d, V([0.3, 0.5, 0.8]))
        bend /= np.linalg.norm(bend) + 1e-9
        sp.append(tube([b, b + d * ln * 0.55 + bend * 0.004, b + d * ln + bend * 0.01], [0.03, 0.017, 0.002], 0.0))
    spikes_f = union(sp)
    spikes_f = lambda P, f=spikes_f: f(P) - 0.0012 * ridged(P, 90.0, 2, 75)
    # bezel + core
    cc = hc + cd * (HEAD_R - 0.03)
    bezel = torus(cc + cd * 0.025, 0.105, 0.014, rot_to((0, 0, 1), cd))
    core = sphere(cc - cd * 0.02, 0.122)
    core = intersect(core, halfspace(-cd, cc - cd * 0.05), 0.004)
    core = lambda P, f=core: f(P) - 0.0012 * fbm(P, 30.0, 3, 77)
    # collar with claw prongs gripping the ball
    collar = [capsule(V([0, 0, HEAD_Z + HEAD_R + 0.05]), V([0, 0, HEAD_Z + HEAD_R - 0.02]), 0.045, 0.06)]
    for k in range(5):
        a = k / 5 * 2 * math.pi
        d = V([math.cos(a), math.sin(a), 0.0])
        p0 = V([0, 0, HEAD_Z + HEAD_R + 0.02]) + d * 0.04
        p1 = hc + (d * 0.72 + V([0, 0, 0.7])) / np.linalg.norm(d * 0.72 + V([0, 0, 0.7])) * (HEAD_R + 0.012)
        p2 = hc + (d * 0.95 + V([0, 0, 0.32])) / np.linalg.norm(d * 0.95 + V([0, 0, 0.32])) * (HEAD_R + 0.005)
        collar.append(tube([p0, p1, p2], [0.016, 0.012, 0.004], 0.006))
    collar_f = smooth_union(collar, 0.01)
    # haft segments (telescoping: ext2 thickest near the head, ext1 slides inside it, grip slides inside ext1)
    def wrap(f, freq, amp):
        return lambda P: f(P) - amp * torch.sin(P[:, 2] * freq + 3 * torch.atan2(P[:, 1], P[:, 0]))

    grip = wrap(capsule(V([0, 0, 0.1]), V([0, 0, -0.15]), 0.022), 220.0, 0.0018)
    pommel = smooth_union([sphere(V([0, 0, 0.12]), 0.032), tube([V([0, 0, 0.13]), V([0, 0, 0.2])], [0.02, 0.002])], 0.006)
    seg1 = capsule(V([0, 0, -0.13]), V([0, 0, -0.42]), 0.026)
    rings1 = union([torus(V([0, 0, z]), 0.027, 0.006) for z in (-0.15, -0.28, -0.4)])
    seg2 = capsule(V([0, 0, -0.4]), V([0, 0, HEAD_Z + HEAD_R + 0.04]), 0.031)
    rings2 = union([torus(V([0, 0, z]), 0.032, 0.007) for z in (-0.42,)])
    return {
        "morrow_head": (head, "morrow", "weapon_ext2"),
        "morrow_spikes": (spikes_f, "morrow_metal", "weapon_ext2"),
        "morrow_core": (core, "stone", "weapon_ext2"),
        "morrow_bezel": (union([bezel, collar_f]), "morrow_metal", "weapon_ext2"),
        "morrow_seg2": (smooth_union([seg2, rings2], 0.004), "morrow_metal", "weapon_ext2"),
        "morrow_seg1": (smooth_union([seg1, rings1], 0.004), "morrow_metal", "weapon_ext1"),
        "morrow_grip": (union([grip, pommel]), "leather", "weapon"),
    }


def fields():
    """World-space fields (local fields placed by grip_frame)."""
    M = grip_frame()
    out = {}
    for n, (f, kind, bone) in local_fields().items():
        out[n] = (transform(f, M[:3, :3], M[:3, 3]), kind, bone)
    return out
