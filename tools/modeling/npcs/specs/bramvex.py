"""Bramvex: 2.3 m stick-insect sergeant. Bark-brown thorny limbs, peaked cap, olive jacket, red banner tabard, ragged bat wings, hooked lantern pole."""
import math

import numpy as np

import humanoid as hu

ID = "bramvex"
HEIGHT = 2.3
PAL = {
    "bark": "#c88a3a", "bark2": "#8a5428", "jacket": "#9fbc3a", "jacket2": "#6f8a28", "cap": "#6e7a2c", "red": "#ee3226",
    "gold": "#ffd53a", "leather": "#a2622c", "wing": "#f0cf92", "wing2": "#9a7a4a", "eye": ("#ff3a1c", "glow"),
    "lamp": ("#ffa030", "glow"), "iron": "#554a40", "thorn": "#f4e2b8", "face": "#d9a24e",
}
STYLE = {"chest": (3, 0, 0), "head": (-2, 0, 0)}
SECONDARY = [("wing.L", 40, 5, 22), ("wing.R", 40, 5, 22), ("banner", 36, 5, 22), ("ant.L", 30, 4, 20), ("ant.R", 30, 4, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.12, torso=0.95, neck=1.3, head=0.9, shoulders=0.8, hipw=0.75, arms=1.25, stoop=0.8)
    J = b.j
    for sg, s in ((1, ".L"), (-1, ".R")):
        pass
    b.add_bone_pair("wing", (0.06, 0.1, J("chest")[2] + 0.04), (0.5, 0.35, J("hips")[2] - 0.55), "chest")
    b.add_bone_pair("ant", (0.04, J("head_end")[1], J("head_end")[2] - 0.03), (0.25, J("head_end")[1] - 0.2, J("head_end")[2] + 0.6), "head")
    b.add_bone("banner", tuple(J("hips") + (0, -0.08, 0.0)), tuple(J("hips") + (0, -0.1, -0.9)), "hips")
    hu.body(b, "face", "jacket", arms="bark", fore="bark", legs="bark", boots="bark2", hands="bark2", tw=0.75, arm_r=0.55, leg_r=0.5,
            head_r=(0.034, 0.06, 0.068), nose=False, hips_col="jacket2")
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    # narrow mantis face: long muzzle, red eyes
    b.ball(P(0, -0.85, -0.45), (0.03, 0.05, 0.04), "head", "face", seg=6, rings=4)
    for sg in (1, -1):
        b.ball(P(sg * 0.85, -0.75, 0.2), (0.016, 0.02, 0.03), "head", "eye", seg=6, rings=4)
    b.spike(P(0, -1.2, -0.35), P(0, -1.9, -0.9), 0.03, "head", "bark2", seg=4)
    # peaked cap, low over the brow, red band
    b.ball(P(0, 0.0, 0.62), (0.07, 0.08, 0.04), "head", "cap", seg=9, rings=4)
    b.ball(P(0, -0.35, 0.5), (0.065, 0.1, 0.012), "head", "cap", seg=9, rings=3)
    b.ball(P(0, 0.0, 0.52), (0.074, 0.084, 0.012), "head", "red", seg=9, rings=3)
    # antennae (long, red tips)
    for sg, s in ((1, ".L"), (-1, ".R")):
        h0 = J("head_end") + (sg * 0.03, 0.0, -0.03)
        pts = [h0, h0 + (sg * 0.09, 0.0, 0.3), h0 + (sg * 0.2, -0.12, 0.55), h0 + (sg * 0.3, -0.3, 0.6)]
        b.tube(pts, [0.012, 0.01, 0.008, 0.006], "ant" + s, "bark2", seg=4)
        b.ball(pts[-1], 0.016, "ant" + s, "red", seg=4, rings=3)
    # thorn spurs on every limb segment
    for s, sg in ((".L", 1), (".R", -1)):
        for a, c in (("shoulder", "elbow"), ("elbow", "wrist"), ("hip", "knee"), ("knee", "ankle")):
            for t in (0.3, 0.7):
                p = J(a + s) * (1 - t) + J(c + s) * t
                b.spike(p + (sg * 0.02, 0.0, 0), p + (sg * 0.11, 0.02, 0.03), 0.014, "upperarm" + s if a == "shoulder" else "forearm" + s if a == "elbow" else "thigh" + s if a == "hip" else "shin" + s, "thorn", seg=4)
        for k in range(3):
            b.spike(J("wrist" + s) + (0, 0, 0), J("hand_end" + s) + (sg * 0.02 * (k - 1), -0.1, -0.08), 0.01, "hand" + s, "thorn", seg=3)
    # crossed straps, pouch belt
    b.limb(J("neck1") + (0.1, -0.06, -0.03), J("hips") + (-0.12, -0.08, 0.05), 0.02, 0.02, "chest", "leather", seg=4)
    b.limb(J("neck1") + (-0.1, -0.06, -0.03), J("hips") + (0.12, -0.08, 0.05), 0.02, 0.02, "chest", "leather", seg=4)
    b.ball(J("hips") + (0, -0.01, 0.05), (0.12, 0.09, 0.03), "hips", "leather", seg=8, rings=3)
    for i, x in enumerate((-0.12, -0.06, 0.06, 0.12)):
        b.box(J("hips") + (x, -0.1, 0.0), (0.06, 0.04, 0.07), "hips", "leather" if i % 2 else "bark2")
    b.ball(J("shoulder.L") + (0.03, 0, 0.02), (0.08, 0.07, 0.05), "upperarm.L", "jacket2", seg=6, rings=3)
    b.ball(J("shoulder.R") + (-0.03, 0, 0.02), (0.08, 0.07, 0.05), "upperarm.R", "jacket2", seg=6, rings=3)
    # tattered banner tabard with gold chevrons (front and back)
    wt = lambda p: {"banner": 1.0}
    for y, sgn in ((-0.11, 1), (0.1, -1)):
        for k, x in enumerate((-0.1, 0.0, 0.1)):
            b.tatter(J("hips") + (x, y, 0.02), 0.11, 0.95 - 0.12 * (k % 2), "banner", "red", n=1, jag=0.45, sway=0.2)
        for i in range(3):
            c = J("hips") + (0, y - 0.003 * sgn, -0.2 - 0.12 * i)
            b.tri(c + (-0.07, 0, 0.0), c + (0.07, 0, 0.0), c + (0, 0, -0.05), "banner", "gold")
    # ragged bat wings folded like a cloak
    for sg, s in ((1, ".L"), (-1, ".R")):
        r = J("chest") + (sg * 0.06, 0.1, 0.06)
        for k, (dx, dy, dz, c) in enumerate(((0.55, 0.3, -0.5, "wing"), (0.4, 0.35, -1.05, "wing2"), (0.25, 0.3, -1.4, "wing"))):
            b.leaf(r, r + (sg * dx, dy, dz), 0.38, (0, 1, 0.2), "wing" + s, c, n=3, bend=(sg * 0.08, 0.05, 0))
    # lantern on a hooked pole held in the right hand, over the shoulder
    hnd = J("wrist.R")
    b.limb(hnd + (0, 0.1, -0.5), hnd + (-0.05, 0.25, 1.1), 0.014, 0.012, "hand.R", "iron", seg=4)
    b.tube([hnd + (-0.05, 0.25, 1.1), hnd + (-0.05, 0.12, 1.28), hnd + (-0.05, -0.08, 1.2)], [0.012, 0.01, 0.01], "hand.R", "iron", seg=4)
    lp = hnd + (-0.05, -0.08, 1.1)
    b.box(lp, (0.1, 0.1, 0.16), "hand.R", "lamp")
    b.spike(lp + (0, 0, 0.08), lp + (0, 0, 0.17), 0.06, "hand.R", "iron", seg=4)
    b.ball(J("hips") + (0.17, -0.06, -0.15), (0.04, 0.04, 0.06), "hips", "lamp", seg=6, rings=3)
    return b
