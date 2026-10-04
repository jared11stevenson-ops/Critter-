"""Nerit: 1.75 m lantern-keeper. Slender mint insect-folk, big pointed plum hat, long antennae with glowing lanterns, iridescent glowing abdomen sac, glowing belt orbs."""
import math

import humanoid as hu

ID = "nerit"
HEIGHT = 1.75
PAL = {
    "skin": "#9fe0cf", "skin2": "#6fb8a8", "hat": "#4a2f78", "hat2": "#7a54b8", "tunic": "#fff1c4", "tunic2": "#d9c98a", "trouser": "#7a4fd0",
    "boot": "#8a5a30", "eye": ("#7dffe0", "glow"), "abd": ("#59e6ff", "glow"), "orb1": ("#59e6ff", "glow"), "orb2": ("#c46bff", "glow"),
    "orb3": ("#ff7ad0", "glow"), "lamp": ("#9bff7a", "glow"), "ant": "#3a2a52", "belt": "#7a4a28",
}
STYLE = {"chest": (-1, 0, 0)}
SECONDARY = [("abdomen", 28, 4, 14), ("ant.L", 30, 4, 22), ("ant.R", 30, 4, 22), ("tunic", 35, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.1, torso=0.9, neck=1.0, head=1.0, shoulders=0.8, hipw=0.85, arms=1.1, stoop=0.25)
    J = b.j
    b.add_bone("abdomen", tuple(J("hips") + (0, 0.1, 0.1)), tuple(J("hips") + (0, 0.5, -0.05)), "hips")
    b.add_bone_pair("ant", (0.04, J("head_end")[1], J("head_end")[2] - 0.05), (0.2, J("head_end")[1], J("head_end")[2] + 0.5), "head")
    b.add_bone("tunic", tuple(J("hips")), tuple(J("hips") + (0, 0, -0.4)), "hips")
    hu.body(b, "skin", "tunic", arms="tunic", fore="skin", legs="trouser", boots="boot", hands="skin2", tw=0.8, arm_r=0.7, leg_r=0.85,
            head_r=(0.042, 0.05, 0.06), nose=False, hips_col="trouser")
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    for sg in (1, -1):
        b.ball(P(sg * 0.5, -0.8, 0.15), (0.022, 0.016, 0.03), "head", "eye", seg=6, rings=4)
    b.ball(P(0, -0.9, -0.45), (0.02, 0.02, 0.018), "head", "skin2", seg=5, rings=3)
    # large pointed hat (hood) leaning back
    hc = P(0, 0.1, 0.62)
    b.ball(hc + (0, -0.02, 0.0), (0.09, 0.1, 0.03), "head", "hat", seg=10, rings=3)
    b.spike(hc + (0, 0.0, 0.0), hc + (0, 0.3, 0.2), (0.07, 0.07), "head", "hat", seg=8, smooth=True)
    b.ball(hc + (0, -0.1, 0.0), (0.075, 0.03, 0.012), "head", "hat2", seg=8, rings=3)
    b.ball(P(0, 0.2, 0.3), (0.075, 0.07, 0.07), "head", "hat", seg=8, rings=4)
    # antennae with lanterns
    for sg, s in ((1, ".L"), (-1, ".R")):
        h0 = J("head_end") + (sg * 0.04, 0.02, -0.04)
        pts = [h0, h0 + (sg * 0.1, -0.02, 0.28), h0 + (sg * 0.2, -0.12, 0.52), h0 + (sg * 0.3, -0.25, 0.46)]
        b.tube(pts, [0.012, 0.01, 0.008, 0.006], "ant" + s, "ant", seg=4)
        b.limb(pts[-1], pts[-1] + (0, 0, -0.1), 0.004, 0.004, "ant" + s, "ant", seg=3)
        b.ball(pts[-1] + (0, 0, -0.16), (0.05, 0.05, 0.07), "ant" + s, "lamp", seg=7, rings=4)
        b.box(pts[-1] + (0, 0, -0.07), (0.04, 0.04, 0.02), "ant" + s, "ant")
    # tunic: ragged cream skirt panels, sash
    wt = hu.hang_weights(b, J("hips")[2] + 0.05, 0.35, 0.6)
    b.ring_skirt(J("hips") + (0, 0, 0.05), 0.13, 0.26, J("hips")[2] + 0.04, 0.5, wt, ["tunic", "tunic2", "tunic"], n=9, jag=0.4, wobble=0.1)
    b.ball(J("hips") + (0, -0.01, 0.06), (0.1, 0.075, 0.025), "hips", "belt", seg=8, rings=3)
    for i, (c, x) in enumerate((("orb2", 0.1), ("orb1", -0.11), ("orb3", 0.0))):
        pos = J("hips") + (x, -0.09, -0.04 - 0.04 * i)
        b.limb(J("hips") + (x, -0.08, 0.04), pos, 0.004, 0.004, "hips", "belt", seg=3)
        b.ball(pos + (0, 0, -0.04), (0.035, 0.035, 0.05), "hips", c, seg=7, rings=4)
    # glowing iridescent abdomen sac on the back
    ab = J("hips") + (0, 0.3, 0.0)
    b.ball(ab, (0.2, 0.3, 0.22), "abdomen", "abd", seg=10, rings=7)
    for k, (dx, dy, dz, r, c) in enumerate(((0.1, 0.2, 0.12, 0.06, "orb2"), (-0.1, 0.18, -0.08, 0.07, "orb3"), (0.02, 0.32, 0.0, 0.08, "orb2"),
                                          (-0.12, 0.1, 0.16, 0.045, "orb3"), (0.13, 0.12, -0.1, 0.05, "orb3"))):
        b.ball(ab + (dx, dy, dz), (r, r * 0.5, r), "abdomen", c, seg=6, rings=3)
    b.limb(J("chest") + (0, 0.07, 0.0), ab + (0, -0.15, 0.1), 0.06, 0.1, "chest", "skin2", seg=6)
    # hanging sleeve tatters
    for s, sg in ((".L", 1), (".R", -1)):
        b.tatter(J("elbow" + s) + (0, 0, 0.0), 0.12, 0.3, "forearm" + s, "tunic2", n=2, jag=0.4)
    return b
