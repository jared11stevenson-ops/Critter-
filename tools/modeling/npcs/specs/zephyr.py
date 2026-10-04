"""Zephyr: 1.65 m hawk-moth nectar seeker. Bird-skull mask with long proboscis, leaf-feather crest, tasselled antennae, folded pink/olive wings, vial belt, hooked staff."""
import math

import numpy as np

import humanoid as hu

ID = "zephyr"
HEIGHT = 1.65
PAL = {
    "chitin": "#8a5238", "chitin2": "#5a3224", "bone": "#fff0cc", "eye": ("#ffae2a", "glow"), "prob": "#ff5a78", "crest1": "#ee2c58",
    "crest2": "#a8c43a", "wing1": "#ff8cb8", "wing2": "#bcd04a", "wing3": "#fff0c8", "cloth1": "#a8c43a", "cloth2": "#e8305a", "cloth3": "#fff0cc",
    "vial": ("#ff4fc0", "glow"), "gold": "#ffd040", "flower": "#ff5a9a", "blossom": "#ff9a2a", "tassel": "#ee2c58", "staff": "#6a4630", "belt": "#7a2a30",
}
STYLE = {"chest": (-2, 0, 0)}
SECONDARY = [("wing.L", 38, 5, 20), ("wing.R", 38, 5, 20), ("ant.L", 30, 4, 22), ("ant.R", 30, 4, 22), ("cloth", 32, 5, 18)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.12, torso=0.9, neck=1.1, head=1.0, shoulders=0.75, hipw=0.8, arms=1.2, stoop=0.3)
    J = b.j
    b.add_bone_pair("wing", (0.05, 0.08, J("chest")[2] + 0.02), (0.5, 0.3, J("hips")[2] - 0.5), "chest")
    b.add_bone_pair("ant", (0.04, J("head_end")[1], J("head_end")[2] - 0.04), (0.2, J("head_end")[1], J("head_end")[2] + 0.45), "head")
    b.add_bone("cloth", tuple(J("hips")), tuple(J("hips") + (0, 0, -0.5)), "hips")
    hu.body(b, "chitin", "cloth2", arms="chitin", fore="chitin", legs="chitin2", boots="chitin2", hands="chitin2", tw=0.75, arm_r=0.6, leg_r=0.6,
            head_r=(0.045, 0.062, 0.065), nose=False, hips_col="cloth2")
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    # bird-skull mask (bone) over the face, dark orange-glint eyes, long curved proboscis
    b.ball(P(0, -0.5, 0.0), (0.056, 0.09, 0.08), "head", "bone", seg=9, rings=5)
    for sg in (1, -1):
        b.ball(P(sg * 0.55, -0.95, 0.15), (0.02, 0.014, 0.026), "head", "eye", seg=6, rings=4)
    pts = [P(0, -1.2, -0.2), P(0, -1.9, -0.45), P(0, -2.3, -0.9), P(0, -2.2, -1.5)]
    b.tube(pts, [0.02, 0.014, 0.01, 0.005], "head", "prob", seg=5)
    # crest of leaf-feathers
    for k, (x, y, z, c) in enumerate(((0, 0.3, 1.0, "crest1"), (0.35, 0.4, 0.95, "crest2"), (-0.35, 0.4, 0.95, "crest2"), (0.0, 0.8, 0.8, "crest1"))):
        b.leaf(P(x * 0.4, y * 0.3, 0.8), P(x * 1.3, y * 0.9 + 0.3, z + 0.9), 0.14, (1, 0, 0), "head", c, n=3, bend=(0, 0.08, 0))
    # antennae with red tassels
    for sg, s in ((1, ".L"), (-1, ".R")):
        h0 = J("head_end") + (sg * 0.04, 0.0, -0.05)
        pts = [h0, h0 + (sg * 0.08, 0.0, 0.25), h0 + (sg * 0.2, 0.0, 0.42), h0 + (sg * 0.3, -0.04, 0.25)]
        b.tube(pts, [0.01, 0.009, 0.007, 0.006], "ant" + s, "chitin2", seg=4)
        b.tatter(pts[-1], 0.07, 0.3, "ant" + s, "tassel", n=3, jag=0.2)
        b.ball(pts[-1], 0.014, "ant" + s, "gold", seg=4, rings=3)
    # flowers at the throat and on the shoulders
    for c, pos, r in (("flower", J("neck1") + (0.0, -0.06, -0.05), 0.055), ("blossom", J("shoulder.L") + (0.0, -0.02, 0.06), 0.035),
                      ("blossom", J("shoulder.R") + (0.0, -0.02, 0.06), 0.035), ("blossom", J("shoulder.L") + (0.04, 0.0, 0.1), 0.028)):
        bone = "chest" if c == "flower" else "upperarm.L" if pos[0] > 0 else "upperarm.R"
        b.ball(pos, r, bone, c, seg=6, rings=3)
        for a in range(5):
            an = a * 1.256
            b.spike(pos + (0.3 * r * math.cos(an), -0.2 * r, 0.3 * r * math.sin(an)), pos + (1.4 * r * math.cos(an), -0.4 * r, 1.4 * r * math.sin(an)), r * 0.7, bone, c, seg=4)
        b.ball(pos + (0, -0.02, 0), r * 0.35, bone, "gold", seg=4, rings=3)
    # layered ragged skirts
    wt = hu.hang_weights(b, J("hips")[2] + 0.05, 0.3, 0.5)
    hz = J("hips")[2]
    b.ring_skirt(J("hips") + (0, 0, 0.05), 0.12, 0.3, hz + 0.05, 0.28, wt, ["cloth2", "cloth1", "cloth3"], n=10, jag=0.5, wobble=0.15)
    b.ring_skirt(J("hips") + (0, 0, 0.03), 0.1, 0.22, hz + 0.0, 0.45, wt, ["cloth1", "cloth2"], n=8, jag=0.4, wobble=0.1)
    b.ball(J("hips") + (0, -0.01, 0.05), (0.1, 0.075, 0.025), "hips", "belt", seg=8, rings=3)
    # nectar vials with gold caps
    for i, (x, big) in enumerate(((0.07, 0), (-0.04, 0), (0.15, 1), (-0.12, 0))):
        p = J("hips") + (x, -0.1, -0.03 - (0.05 if big else 0.0))
        r = 0.04 if big else 0.026
        b.ball(p, (r, r, r * 1.3), "hips", "vial", seg=6, rings=4)
        b.ball(p + (0, 0, r * 1.3), (r * 0.6, r * 0.6, 0.012), "hips", "gold", seg=5, rings=2)
    # two pairs of hawk-moth wings, folded down the back
    for sg, s in ((1, ".L"), (-1, ".R")):
        r = J("chest") + (sg * 0.05, 0.08, 0.03)
        b.leaf(r, r + (sg * 0.35, 0.22, -0.55), 0.3, (0, 1, 0.3), "wing" + s, "wing1", n=4, col2="wing3", bend=(sg * 0.1, 0.05, 0))
        b.leaf(r + (0, 0.02, -0.04), r + (sg * 0.28, 0.3, -1.05), 0.26, (0, 1, 0.3), "wing" + s, "wing2", n=4, col2="wing3", bend=(sg * 0.08, 0.04, 0))
        b.leaf(r + (0, 0.0, 0.0), r + (sg * 0.62, 0.15, -0.25), 0.28, (0, 1, 0.5), "wing" + s, "wing1", n=3, bend=(0, 0.05, 0.05))
    # hooked staff in the left hand
    h = J("wrist.L")
    b.limb(h + (0.0, 0.0, 0.2), h + (0.04, -0.2, -0.95), 0.012, 0.012, "hand.L", "staff", seg=4)
    b.tube([h + (0.0, 0.0, 0.2), h + (0.0, -0.1, 0.32), h + (0.0, -0.2, 0.3)], [0.012, 0.01, 0.008], "hand.L", "staff", seg=4)
    # bird claws
    for s, sg in ((".L", 1), (".R", -1)):
        for k in (-1, 0, 1):
            b.spike(J("ball" + s) + (0.0, 0.0, 0.0), J("toe_end" + s) + (k * 0.025, -0.07, 0.0), 0.012, "toe" + s, "chitin2", seg=4)
    return b
