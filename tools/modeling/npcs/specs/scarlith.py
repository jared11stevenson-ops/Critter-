"""Scarlith: 12 cm fermented kingpin. Round crimson velvet mite, gold-trimmed black tricorn, black-and-gold coat, huge holey cheese carapace, lantern gaff."""
import math

import humanoid as hu

ID = "scarlith"
HEIGHT = 0.12
PAL = {
    "fur": "#e0302a", "fur2": "#a01c22", "hat": "#262030", "gold": "#ffd040", "coat": "#2a2030", "coat2": "#8c2428", "cheese": "#ffd27a",
    "cheese2": "#e8a850", "hole": "#b87832", "eye": "#12080a", "glint": "#ffe9a0", "lamp": ("#ff9a30", "glow"), "wood": "#8a5a30", "iron": "#554a50",
    "barrel": "#a0602a",
}
STYLE = {"chest": (1, 0, 0)}
SECONDARY = [("cheese", 30, 5, 10), ("coat", 34, 5, 18)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.55, torso=1.2, neck=0.5, head=1.25, shoulders=1.15, hipw=1.25, arms=0.9, stoop=0.3)
    J = b.j
    b.add_bone("cheese", tuple(J("chest") + (0, 0.02, 0)), tuple(J("chest") + (0, 0.1, 0.0)), "chest")
    b.add_bone("coat", tuple(J("hips")), tuple(J("hips") + (0, 0, -0.04)), "hips")
    hu.body(b, "fur", "fur", arms="fur", legs="fur2", boots="fur2", hands="fur2", tw=1.4, arm_r=1.1, leg_r=1.1, head_r=(0.075, 0.08, 0.075),
            nose=False, hips_col="coat")
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    for sg in (1, -1):
        b.ball(P(sg * 0.42, -0.85, 0.1), (0.008, 0.005, 0.009), "head", "eye", seg=6, rings=4)
        b.ball(P(sg * 0.42, -0.95, 0.2), (0.002, 0.002, 0.002), "head", "glint", seg=3, rings=2)
        b.spike(P(sg * 0.2, -0.9, -0.5), P(sg * 0.55, -1.2, -0.95), 0.004, "head", "fur2", seg=4)
    # tricorn hat with gold trim and emblem
    hc = P(0, 0, 0.75)
    b.ball(hc, (0.1, 0.1, 0.014), "head", "hat", seg=10, rings=3)
    b.ball(hc + (0, -0.03, 0.02), (0.06, 0.055, 0.03), "head", "hat", seg=9, rings=4)
    b.ball(hc + (0, -0.075, 0.0), (0.02, 0.012, 0.016), "head", "gold", seg=6, rings=3)
    b.ball(hc + (0, 0, 0.0), (0.103, 0.103, 0.004), "head", "gold", seg=10, rings=2)
    # coat panels and sash
    wt = hu.hang_weights(b, J("hips")[2] + 0.01, 0.0, 0.5)
    b.ring_skirt(J("hips") + (0, 0, 0.01), 0.04, 0.075, J("hips")[2] + 0.01, 0.012, wt, ["coat", "coat2", "coat"], n=9, jag=0.25)
    for i in range(4):
        b.ball(J("chest") + (0.015 * (i - 1.5), -0.045, 0.01 - 0.014 * i), 0.004, "chest", "gold", seg=4, rings=3)
    # huge cheese carapace with holes + barrel
    cc = J("chest") + (0, 0.065, 0.03)
    b.ball(cc, (0.065, 0.055, 0.07), "cheese", "cheese", seg=10, rings=7)
    for k, (x, y, z, r) in enumerate(((0.035, 0.035, 0.03, 0.012), (-0.035, 0.03, 0.0, 0.014), (0.015, 0.05, -0.03, 0.01), (-0.015, 0.045, 0.05, 0.009),
                                      (0.05, 0.0, -0.01, 0.01), (-0.055, 0.0, 0.04, 0.009), (0.0, 0.055, 0.02, 0.013))):
        b.ball(cc + (x, y, z), (r, r * 0.5, r), "cheese", "hole", seg=6, rings=3)
    b.ball(cc + (0, 0.02, -0.06), (0.06, 0.05, 0.02), "cheese", "cheese2", seg=8, rings=3)
    b.box(cc + (0.0, 0.01, 0.075), (0.035, 0.035, 0.03), "cheese", "barrel")
    b.tatter(cc + (0, 0.0, -0.04), 0.09, 0.07, "cheese", "cheese", n=4, jag=0.4)
    # extra red legs
    for sg in (1, -1):
        b.limb(J("hips") + (sg * 0.03, 0.02, 0), J("hips") + (sg * 0.09, 0.05, -0.04), 0.008, 0.006, "hips", "fur2", seg=4)
        b.limb(J("hips") + (sg * 0.09, 0.05, -0.04), J("hips") + (sg * 0.11, 0.07, -0.1), 0.006, 0.003, "hips", "fur", seg=4)
    # lantern gaff in the right hand
    h = J("wrist.R")
    b.limb(h + (0, 0.0, -0.05), h + (0.0, -0.02, 0.2), 0.004, 0.004, "hand.R", "wood", seg=4)
    b.tube([h + (0, -0.02, 0.2), h + (0, -0.05, 0.22), h + (0, -0.07, 0.19)], [0.004, 0.003, 0.003], "hand.R", "iron", seg=3)
    b.ball(h + (0, -0.07, 0.15), (0.012, 0.012, 0.018), "hand.R", "lamp", seg=6, rings=4)
    return b
