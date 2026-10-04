"""Mollusk: 2.2 m snail-person elder. Orange spotted slug skin, eyestalks, huge striped spiral shell with ferns and hibiscus, red sarong, mossy club."""
import math

import numpy as np

import humanoid as hu

ID = "mollusk"
HEIGHT = 2.2
PAL = {
    "skin": "#ffa95c", "belly": "#ffdca0", "spot": "#c2602c", "shell1": "#c9531d", "shell2": "#ffd7a0", "shell3": "#7d3a1a",
    "cloth": "#e0322e", "cloth2": "#ffb83a", "cloth3": "#fff0cf", "boot": "#9c3a24", "fern": "#47cf4a", "fern2": "#1f8f45",
    "flower": "#ff3f6a", "bead": "#26d6c8", "eyew": "#ffffff", "pupil": "#2a1410", "club": "#7a5a34", "moss": "#4cbf48",
    "gold": "#ffd23a",
}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("shell", 30, 6, 12), ("eye.L", 40, 4, 25), ("eye.R", 40, 4, 25), ("tail", 35, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.75, torso=1.2, neck=1.4, head=1.1, shoulders=1.3, hipw=1.35, arms=1.1, stoop=0.5)
    J = b.j
    b.add_bone("shell", tuple(J("chest") + (0, 0.1, 0)), tuple(J("chest") + (0, 0.55, 0.0)), "chest")
    b.add_bone_pair("eye", (0.05, J("head_end")[1] - 0.02, J("head_end")[2] - 0.02), (0.1, J("head_end")[1] - 0.04, J("head_end")[2] + 0.38), "head")
    b.add_bone("tail", tuple(J("hips") + (0, 0.15, -0.3)), tuple(J("hips") + (0, 0.9, -0.38)), "hips")
    hu.body(b, "skin", "belly", arms="skin", legs="skin", boots="boot", hands="skin", tw=1.15, arm_r=1.3, leg_r=1.25,
            head_r=(0.047, 0.062, 0.07), hips_col="cloth", nose=False)
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    # eyestalks with eyes
    for sg in (1, -1):
        s = ".L" if sg > 0 else ".R"
        base = P(sg * 0.35, -0.2, 0.9)
        top = base + (sg * 0.05, -0.03, 0.4)
        b.limb(base, top, 0.026, 0.02, "eye" + s, "skin", seg=6)
        b.ball(top + (0, -0.01, 0.02), (0.04, 0.04, 0.045), "eye" + s, "eyew", seg=7, rings=4)
        b.ball(top + (0, -0.045, 0.02), (0.018, 0.01, 0.022), "eye" + s, "pupil", seg=5, rings=3)
    # face: mouth line + nostrils, spotted cheeks
    b.ball(P(0, -0.95, -0.45), (0.04, 0.012, 0.008), "head", "spot", seg=6, rings=3)
    for sg in (1, -1):
        b.ball(P(sg * 0.5, -0.8, 0.2), (0.012, 0.01, 0.012), "head", "spot", seg=4, rings=3)
    for i in range(6):
        b.ball(J("chest") + (((i * 37) % 11 - 5) * 0.018, -0.055, 0.12 - 0.045 * i), (0.012, 0.006, 0.012), "chest", "spot", seg=4, rings=3)
    # shell: big egg behind, spiral axis pointing back (bands run around it), cap spiral on the rear face
    sc = J("spine2") + (0, 0.42, -0.02)
    b.ball(sc, (0.43, 0.5, 0.5), "shell", "shell1", seg=10, rings=9, rot=(90, 0, 0), bands=["shell1", "shell2", "shell3", "shell2"])
    for k, (r, y, c) in enumerate(((0.3, 0.5, "shell2"), (0.22, 0.56, "shell3"), (0.13, 0.6, "shell1"), (0.06, 0.63, "gold"))):
        b.ball(sc + (0, y, 0), (r, 0.05, r), "shell", c, seg=9, rings=3)
    # ferns + hibiscus on the shell crown
    top = sc + (0, 0.0, 0.46)
    for k in range(7):
        ang = k * 0.9 + 0.3
        d = V3(math.cos(ang), math.sin(ang) * 0.6, 0)
        b.leaf(top + d * 0.05, top + d * 0.4 + (0, 0, 0.32 - 0.03 * k), 0.15, (-d[1], d[0], 0), "shell", "fern" if k % 2 else "fern2", n=3, bend=(0, 0, 0.1))
    for fx, fy in ((0.1, 0.12), (-0.12, 0.02)):
        fc = top + (fx, fy, 0.08)
        b.ball(fc, 0.05, "shell", "flower", seg=7, rings=4)
        for a in range(5):
            an = a * 1.256
            b.spike(fc + (0.03 * math.cos(an), 0.03 * math.sin(an), 0.02), fc + (0.1 * math.cos(an), 0.1 * math.sin(an), 0.06), 0.035, "shell", "flower", seg=4)
        b.ball(fc + (0, 0, 0.05), 0.016, "shell", "gold", seg=4, rings=3)
    # shell harness straps across the chest (red cloth + beads)
    b.limb(J("neck1") + (0.1, -0.07, -0.05), J("hips") + (-0.12, -0.1, 0.1), 0.025, 0.025, "chest", "cloth", seg=5)
    b.limb(J("neck1") + (-0.1, -0.07, -0.05), J("hips") + (0.12, -0.1, 0.1), 0.025, 0.025, "chest", "cloth2", seg=5)
    for i in range(5):
        t = i / 4
        b.ball(J("neck1") * (1 - t) + J("hips") * t + (0.08 - 0.16 * t, -0.1, -0.05 + 0.1 * t), 0.022, "chest", "bead", seg=5, rings=3)
    # shoulder pads (mossy), arm bracelets
    for s, sg in ((".L", 1), (".R", -1)):
        b.ball(J("shoulder" + s) + (sg * 0.03, 0, 0.03), (0.09, 0.08, 0.06), "upperarm" + s, "cloth2", seg=7, rings=4)
        b.ball(J("shoulder" + s) + (sg * 0.03, 0, 0.08), (0.06, 0.05, 0.03), "upperarm" + s, "moss", seg=6, rings=3)
        b.ball(J("wrist" + s), (0.05, 0.05, 0.03), "forearm" + s, "bead", seg=6, rings=3)
    # sarong: ragged layered cloth to the ankles
    wt = hu.hang_weights(b, J("hips")[2], 0.15, 0.8)
    hz = J("hips")[2]
    b.ring_skirt(J("hips") + (0, 0, 0.05), 0.27, 0.42, hz + 0.05, 0.18, wt, ["cloth", "cloth2", "cloth", "cloth3"], n=12, jag=0.35, wobble=0.08)
    b.ring_skirt(J("hips") + (0, -0.03, 0.04), 0.25, 0.34, hz + 0.04, 0.5, wt, ["cloth2", "cloth", "cloth3"], n=9, jag=0.3)
    b.ball(J("hips") + (0, -0.02, 0.06), (0.28, 0.24, 0.04), "hips", "cloth", seg=10, rings=3)
    # slug tail dragging behind
    pts = [J("hips") + (0, 0.18, -0.28), J("hips") + (0, 0.45, -0.34), J("hips") + (0, 0.75, -0.38), J("hips") + (0, 1.0, -0.4)]
    b.tube(pts, [0.2, 0.15, 0.09, 0.03], "tail", "skin", seg=7)
    # mossy club in the right hand
    hand = J("wrist.R")
    b.limb(hand + (0, 0.1, 0.1), hand + (0, -0.45, -0.55), 0.04, 0.05, "hand.R", "club", seg=6)
    b.ball(hand + (0, -0.52, -0.62), (0.15, 0.15, 0.18), "hand.R", "club", seg=7, rings=4)
    b.ball(hand + (0, -0.5, -0.5), (0.12, 0.12, 0.09), "hand.R", "moss", seg=6, rings=3)
    return b


def V3(*a):
    return np.array(a, float)
