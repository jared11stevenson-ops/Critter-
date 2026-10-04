"""Ilsa Brandt: tall thin stick mantis apprentice, leaf-green body, magenta chalk apron, chalk and plumb line in the forelimbs."""
import humanoid as hu
import npc_kit as K

ID = "ilsa_brandt"
HEIGHT = 2.0
PAL = {"skin": "#8bd13f", "skin2": "#5fa02a", "apron": "#e0348a", "apron2": "#a01c60", "chalk": "#fff6e4", "eye": ("#2a1a16", "glow"), "dark": "#2a1a16",
       "plumb": "#c8c8d0", "cord": "#efe6cf", "boot": "#3a5a22", "roll": "#e8d8b0"}
STYLE = {"chest": (2, 0, 0), "head": (-2, 0, 0)}
SECONDARY = [("apron", 36, 5, 22), ("ant.L", 30, 4, 22), ("ant.R", 30, 4, 22)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.15, torso=0.95, neck=1.3, head=0.9, shoulders=0.75, hipw=0.7, arms=1.3, stoop=0.6)
    J = b.j
    b.add_bone("apron", tuple(J("hips")), tuple(J("hips") + (0, -0.05, -0.45)), "hips")
    b.add_bone_pair("ant", (0.03, J("head_end")[1], J("head_end")[2] - 0.04), (0.14, J("head_end")[1] - 0.05, J("head_end")[2] + 0.4), "head")
    hu.body(b, "skin", "skin", arms="skin", fore="skin2", legs="skin2", boots="boot", hands="skin2", tw=0.75, arm_r=0.55, leg_r=0.55, head_r=(0.036, 0.056, 0.062), nose=False)
    for sg in (1, -1):
        b.ball(hu.hp(b, sg * 0.8, -0.75, 0.2), (0.018, 0.02, 0.032), "head", "eye", seg=6, rings=4)
    b.spike(hu.hp(b, 0, -1.0, -0.4), hu.hp(b, 0, -1.5, -0.8), (0.02, 0.02), "head", "skin2", seg=4)
    for sg, s in ((1, ".L"), (-1, ".R")):
        h0 = J("head_end") + (sg * 0.03, 0, -0.03)
        pts = [h0, h0 + (sg * 0.06, -0.02, 0.2), h0 + (sg * 0.13, -0.05, 0.38), h0 + (sg * 0.2, -0.12, 0.42)]
        b.tube(pts, [0.01, 0.008, 0.006, 0.004], "ant" + s, "skin2", seg=4)
        for a, c in (("shoulder", "elbow"), ("elbow", "wrist")):
            p = J(a + s) * 0.4 + J(c + s) * 0.6
            b.spike(p + (sg * 0.02, 0, 0), p + (sg * 0.1, 0.03, 0.03), 0.012, "upperarm" + s if a == "shoulder" else "forearm" + s, "skin2", seg=3)
    # magenta chalk apron, front bib + skirt, with chalk dust marks
    wt = hu.hang_weights(b, J("hips")[2] + 0.1, 0.5, 0.6)
    b.strip([(-0.08, -0.07, J("chest")[2] + 0.02), (0.08, -0.07, J("chest")[2] + 0.02)], [(-0.1, -0.09, J("hips")[2]), (0.1, -0.09, J("hips")[2])], lambda p: {"chest": 1.0}, "apron")
    b.strip([(-0.1, -0.09, J("hips")[2]), (0.1, -0.09, J("hips")[2])], [(-0.13, -0.11, 0.62), (0.13, -0.11, 0.62)], wt, "apron")
    b.strip([(-0.1, -0.09, J("hips")[2] - 0.2), (0.1, -0.09, J("hips")[2] - 0.2)], [(-0.12, -0.11, J("hips")[2] - 0.3), (0.12, -0.11, J("hips")[2] - 0.3)], wt, "apron2")
    for i in range(4):
        b.ball(J("chest") + (0.04 * (i % 2) - 0.02, -0.095, -0.05 - 0.05 * i), (0.012, 0.004, 0.006), "chest", "chalk", seg=4, rings=2)
    # chalk stick in the right forelimb, plumb line in the left, rolled sketches
    b.limb(J("wrist.R"), J("wrist.R") + (0, -0.1, 0.0), 0.01, 0.01, "hand.R", "chalk", seg=4)
    b.limb(J("wrist.L"), J("wrist.L") + (0, 0, -0.4), 0.004, 0.004, "hand.L", "cord", seg=3)
    b.spike(J("wrist.L") + (0, 0, -0.4), J("wrist.L") + (0, 0, -0.5), (0.025, 0.025), "hand.L", "plumb", seg=5)
    b.limb(J("hips") + (-0.12, 0.05, 0.02), J("hips") + (-0.2, 0.0, -0.3), 0.025, 0.025, "hips", "roll", seg=5)
    return b
