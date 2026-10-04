"""Dr. Mara Venn: lean 1.70 m physicist, messy high bun, cream expedition suit, harness, big black pack with orange strips."""
import numpy as np

import humanoid as hu

ID = "mara"
HEIGHT = 1.70
PAL = {
    "skin": "#d9966a", "hair": "#55301f", "suit": "#f0dcb8", "suit2": "#d8bf96", "harness": "#22345c",
    "band": "#1d2b4d", "boot": "#2b2f45", "pack": "#2f3d63", "orange": "#ff8a24", "patch": "#202533",
    "white": "#ffffff", "eye": "#1e1410", "glove": "#1d2b4d", "tablet": ("#46d6ff", "glow"), "scar": "#b8714e",
}
STYLE = {"chest": (-1, 0, 0), "head": (-2, 0, 0)}
SECONDARY = [("hair", 45, 6, 25)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=1.0, shoulders=0.95, hipw=1.0)
    b.add_bone("hair", tuple(b.j("head_end") + (0, 0.05, -0.02)), tuple(b.j("head_end") + (0, 0.09, 0.08)), "head")
    hu.body(b, "skin", "suit", arms="suit", legs="suit", boots="boot", hands="glove", tw=0.95, arm_r=0.95)
    J = b.j
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    for sg in (1, -1):
        b.ball(P(sg * 0.42, -0.93, 0.08), (0.012, 0.008, 0.016), "head", "eye", seg=5, rings=3)
        b.ball(P(sg * 0.42, -0.92, 0.32), (0.02, 0.006, 0.006), "head", "hair", seg=4, rings=2)
    b.ball(P(0.35, -0.9, -0.3), (0.012, 0.006, 0.006), "head", "scar", seg=4, rings=2)
    b.ball(P(0, 0.12, 0.28), (0.056, 0.056, 0.05), "head", "hair", seg=9, rings=4)
    bun = P(0, 0.35, 1.0)
    b.ball(bun, (0.05, 0.05, 0.045), "hair", "hair", seg=8, rings=4)
    for a in range(6):
        ang = a * 1.05
        b.spike(bun + (0.02 * np.cos(ang), 0.02 * np.sin(ang), 0.02), bun + (0.08 * np.cos(ang), 0.08 * np.sin(ang), 0.04 + 0.03 * (a % 2)), 0.014, "hair", "hair", seg=4)
    for sg in (1, -1):
        b.spike(P(sg * 0.85, -0.1, 0.3), P(sg * 0.9, -0.5, -0.9), 0.011, "head", "hair", seg=4)
        b.spike(P(sg * 0.5, -0.85, 0.6), P(sg * 0.3, -1.0, 0.1), 0.009, "head", "hair", seg=4)
    # harness: crossing chest straps, waist belt, thigh straps
    b.limb(J("neck1") + (0.05, -0.058, -0.02), J("spine1") + (-0.075, -0.052, 0.0), 0.012, 0.012, "chest", "harness", seg=4)
    b.limb(J("neck1") + (-0.05, -0.058, -0.02), J("spine1") + (0.075, -0.052, 0.0), 0.012, 0.012, "chest", "harness", seg=4)
    b.ball(J("hips") + (0, -0.002, 0.045), (0.08, 0.06, 0.02), "hips", "harness", seg=8, rings=3)
    for s in (".L", ".R"):
        b.ball(J("hip" + s) * 0.7 + J("knee" + s) * 0.3, (0.056, 0.05, 0.016), "thigh" + s, "harness", seg=7, rings=3)
        b.ball(J("shoulder" + s) * 0.55 + J("elbow" + s) * 0.45, (0.036, 0.036, 0.022), "upperarm" + s, "band", seg=7, rings=3)
        b.ball(J("knee" + s) + (0, -0.02, 0.0), (0.05, 0.04, 0.05), "shin" + s, "band", seg=7, rings=4)
        b.ball(J("ankle" + s) + (0, 0.0, 0.06), (0.047, 0.047, 0.04), "shin" + s, "suit2", seg=7, rings=4)
    b.ball(J("shoulder.L") + (0.0, -0.03, 0.0), (0.03, 0.012, 0.03), "upperarm.L", "patch", seg=7, rings=3)
    b.ball(J("shoulder.L") + (0.0, -0.043, 0.0), (0.014, 0.004, 0.014), "upperarm.L", "white", seg=5, rings=3)
    pc = J("spine2") + (0, 0.115, 0.03)
    b.box(pc, (0.26, 0.15, 0.36), "chest", "pack", taper=0.92)
    for x, w in ((0, 0.05), (0.085, 0.03), (-0.085, 0.03)):
        b.box(pc + (x, 0.078, 0.0), (w, 0.012, 0.3), "chest", "orange")
    for x in (0.15, -0.15):
        b.box(pc + (x, 0.0, -0.1), (0.05, 0.1, 0.12), "chest", "pack")
    b.box(pc + (0, 0.0, 0.2), (0.2, 0.12, 0.05), "chest", "orange")
    b.box(J("hip.R") + (-0.07, -0.01, -0.05), (0.025, 0.09, 0.13), "thigh.R", "patch", rot=(0, 0, 8))
    b.box(J("hip.R") + (-0.082, -0.01, -0.05), (0.004, 0.07, 0.1), "thigh.R", "tablet", rot=(0, 0, 8))
    b.ball(J("wrist.L") + (0, 0, 0.02), (0.03, 0.03, 0.012), "forearm.L", "tablet", seg=6, rings=3)
    return b
