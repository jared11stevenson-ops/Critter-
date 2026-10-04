"""Dexter Mane: 1.85 m lean Dominion director. Long coat (collar up, red lining), sigil on the left shoulder, grey streak, cigarette."""
import numpy as np

import humanoid as hu

ID = "dexter"
HEIGHT = 1.85
PAL = {
    "skin": "#d29567", "hair": "#2a1d17", "streak": "#f0f0f8", "coat": "#38405f", "coat2": "#2a3050", "lining": "#ff3a2c",
    "shirt": "#1b2033", "trouser": "#454f74", "boot": "#20243a", "glove": "#171a28", "red": "#ff3a2c", "metal": "#aab3c8",
    "eye": "#16110e", "cig": "#f4efe6", "ember": ("#ff7a30", "glow"), "stubble": "#4b3a30", "leather": "#5a4636",
}
STYLE = {"chest": (-2, 0, 0)}
SECONDARY = [("coat", 38, 5, 30)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.02, torso=1.0, shoulders=1.05, hipw=0.95)
    J = b.j
    b.add_bone("coat", tuple(J("hips")), tuple(J("hips") + (0, 0.08, -0.55)), "hips")
    hu.body(b, "skin", "shirt", arms="coat", legs="trouser", boots="boot", hands="glove", tw=1.0, arm_r=1.05, hips_col="trouser")
    hc = hu.head_center(b, 0.42)
    # sleeves pushed up: bare forearms
    for s in (".L", ".R"):
        b.limb(J("elbow" + s) * 0.9 + J("wrist" + s) * 0.1, "wrist" + s, 0.029 * H, 0.023 * H, "forearm" + s, "skin", seg=6)
        b.ball(J("elbow" + s), 0.034 * H, "forearm" + s, "coat", seg=6, rings=4)
    # face: eyes, stubble, scar-brow, cigarette + ember
    for sg in (1, -1):
        b.ball(hc + (sg * 0.028, -0.057, 0.012), (0.01, 0.006, 0.012), "head", "eye", seg=5, rings=3)
    b.ball(hc + (0, -0.04, -0.045), (0.05, 0.03, 0.032), "head", "stubble", seg=7, rings=3)
    b.limb(hc + (-0.015, -0.068, -0.045), hc + (-0.05, -0.115, -0.04), 0.006, 0.006, "head", "cig", seg=4)
    b.ball(hc + (-0.05, -0.117, -0.04), 0.007, "head", "ember", seg=4, rings=3)
    # swept-back dark hair with a grey streak
    b.ball(hc + (0, 0.018, 0.026), (0.07, 0.07, 0.064), "head", "hair", seg=9, rings=4)
    b.ball(hc + (0.03, -0.03, 0.065), (0.02, 0.05, 0.012), "head", "streak", seg=5, rings=3, rot=(0, 0, 15))
    for sg in (1, -1):
        b.spike(hc + (sg * 0.04, 0.05, 0.05), hc + (sg * 0.08, 0.09, 0.0), 0.02, "head", "hair", seg=4)
    # collar up (hood-like popped collar, red inside)
    for sg in (1, -1):
        b.leaf(J("neck1") + (sg * 0.06, -0.01, -0.03), J("neck1") + (sg * 0.075, 0.03, 0.1), 0.1, (0, 1, 0), "chest", "coat2", n=2)
        b.leaf(J("neck1") + (sg * 0.055, 0.0, -0.02), J("neck1") + (sg * 0.068, 0.035, 0.09), 0.07, (0, 1, 0), "chest", "lining", n=2)
    b.leaf(J("neck1") + (0, 0.07, -0.03), J("neck1") + (0, 0.1, 0.11), 0.16, (1, 0, 0), "chest", "coat2", n=2)
    # coat: open front flaps + back panel (red lining panel on the back) falling to the knee
    zt, zb = J("hips")[2] + 0.04, 0.40
    wt = hu.hang_weights(b, zt, zb, 0.7)
    for sg in (1, -1):
        # front flaps (open coat, lining shows on the inner edge)
        b.strip([(sg * 0.17, -0.07, zt + 0.16), (sg * 0.11, -0.12, zt + 0.08), (sg * 0.10, -0.12, zt)],
                [(sg * 0.22, -0.07, zb + 0.1), (sg * 0.16, -0.13, zb), (sg * 0.13, -0.13, zb)], wt, "coat")
        b.strip([(sg * 0.10, -0.12, zt), (sg * 0.09, -0.12, zt)], [(sg * 0.13, -0.13, zb), (sg * 0.115, -0.13, zb)], wt, "lining")
        b.strip([(sg * 0.19, -0.04, zt + 0.1), (sg * 0.2, 0.0, zt)], [(sg * 0.25, -0.02, zb), (sg * 0.26, 0.06, zb + 0.05)], wt, "coat")
        b.strip([(sg * 0.2, 0.0, zt), (sg * 0.14, 0.1, zt)], [(sg * 0.26, 0.06, zb + 0.05), (sg * 0.15, 0.17, zb)], wt, "coat")
    b.strip([(0.14, 0.1, zt), (0.0, 0.12, zt), (-0.14, 0.1, zt)], [(0.15, 0.17, zb - 0.02), (0.0, 0.2, zb - 0.08), (-0.15, 0.17, zb - 0.02)], wt, "lining")
    b.strip([(0.14, 0.1, zt), (0.0, 0.12, zt), (-0.14, 0.1, zt)], [(0.15, 0.17, zb - 0.02), (0.0, 0.2, zb - 0.08), (-0.15, 0.17, zb - 0.02)], wt, "coat2")
    b.box(J("chest") + (0, 0.082, 0.02), (0.15, 0.016, 0.22), "chest", "coat2")
    b.ball(J("chest") + (0, 0.09, 0.03), (0.04, 0.01, 0.07), "chest", "red", seg=6, rings=3)
    # sigil left shoulder, red boot detail
    b.ball(J("shoulder.L") + (0.0, -0.03, 0.01), (0.024, 0.01, 0.034), "upperarm.L", "red", seg=6, rings=3)
    for s in (".L", ".R"):
        b.ball(J("ankle" + s) + (0, -0.03, 0.02), (0.026, 0.018, 0.022), "foot" + s, "red", seg=5, rings=3)
    # belt, pouches, thigh holster, lanyard badge
    b.ball(J("hips") + (0, -0.002, 0.05), (0.082, 0.06, 0.02), "hips", "leather", seg=8, rings=3)
    b.box(J("hips") + (0.085, -0.02, 0.03), (0.05, 0.05, 0.07), "hips", "leather")
    b.box(J("hip.R") + (-0.07, -0.0, -0.13), (0.04, 0.06, 0.15), "thigh.R", "boot", rot=(0, 0, 6))
    b.box(J("hip.R") + (-0.075, -0.005, -0.2), (0.03, 0.09, 0.05), "thigh.R", "metal", rot=(0, 0, 6))
    b.limb(J("neck1") + (0.03, -0.04, -0.01), J("chest") + (0, -0.06, -0.12), 0.006, 0.006, "chest", "red", seg=4)
    b.box(J("chest") + (0, -0.067, -0.15), (0.03, 0.006, 0.045), "chest", "metal")
    b.ball(J("wrist.R") + (0, 0, 0.0), (0.028, 0.028, 0.012), "forearm.R", "metal", seg=6, rings=3)
    return b
