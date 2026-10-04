"""Pharilux: 2.6 m armoured lighthouse-bearer. Hunched blue-steel armour, brass fittings, glowing wheel eyes, lantern tower on the back, big pale wings, hanging chains."""
import math

import humanoid as hu

ID = "pharilux"
HEIGHT = 2.6
PAL = {
    "armor": "#4f7fc0", "armor2": "#2f4f86", "dark": "#2c4a64", "brass": "#ffbc3a", "brass2": "#c98a28", "rust": "#e0502e", "lamp": ("#ffe06a", "glow"),
    "eye": ("#ffd24a", "glow"), "wing": "#f4f8ea", "wing2": "#c8d8c0", "cloak": "#2a6f86", "cloak2": "#1a4a60", "chain": "#e9c870", "chitin": "#6f8aa0",
}
STYLE = {"chest": (4, 0, 0), "head": (-3, 0, 0)}
SECONDARY = [("wing.L", 38, 5, 22), ("wing.R", 38, 5, 22), ("cloak", 32, 5, 20), ("tower", 20, 6, 6)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=1.0, neck=0.8, head=0.9, shoulders=1.2, hipw=1.0, arms=1.2, stoop=1.0, headfwd=0.03)
    J = b.j
    b.add_bone_pair("wing", (0.08, 0.14, J("chest")[2] + 0.05), (0.7, 0.45, J("hips")[2] - 0.3), "chest")
    b.add_bone("cloak", tuple(J("hips") + (0, 0.1, 0.0)), tuple(J("hips") + (0, 0.15, -0.9)), "chest")
    b.add_bone("tower", tuple(J("chest") + (0, 0.3, 0)), tuple(J("chest") + (0, 0.35, 1.2)), "chest")
    hu.body(b, "chitin", "armor", arms="armor2", fore="dark", legs="dark", boots="armor2", hands="chitin", tw=1.15, arm_r=1.15, leg_r=1.1,
            head_r=(0.045, 0.062, 0.062), nose=False, hips_col="armor2")
    P = lambda x, y, z: hu.hp(b, x, y, z)  # noqa: E731
    # insect head: glowing wheel eyes, mandibles, antenna stubs
    for sg in (1, -1):
        b.ball(P(sg * 0.6, -0.8, 0.2), (0.04, 0.03, 0.045), "head", "eye", seg=7, rings=4)
        b.ball(P(sg * 0.6, -0.95, 0.2), (0.015, 0.008, 0.015), "head", "brass", seg=5, rings=3)
        b.spike(P(sg * 0.3, -0.9, -0.6), P(sg * 0.2, -1.5, -1.2), 0.02, "head", "brass2", seg=4)
        b.spike(P(sg * 0.3, 0.0, 0.9), P(sg * 0.9, 0.4, 1.9), 0.012, "head", "chitin", seg=4)
    b.ball(P(0, 0.0, 0.7), (0.07, 0.075, 0.04), "head", "armor2", seg=8, rings=3)
    # armour plates: shoulder domes with brass gear, chest plate, knee guards
    for s, sg in ((".L", 1), (".R", -1)):
        b.ball(J("shoulder" + s) + (sg * 0.05, 0.0, 0.05), (0.15, 0.13, 0.11), "upperarm" + s, "armor", seg=8, rings=4)
        b.ball(J("shoulder" + s) + (sg * 0.15, -0.03, 0.05), (0.03, 0.07, 0.07), "upperarm" + s, "brass", seg=6, rings=3)
        b.ball(J("elbow" + s), (0.07, 0.07, 0.07), "forearm" + s, "brass2", seg=6, rings=3)
        b.ball(J("knee" + s) + (0, -0.04, 0), (0.08, 0.07, 0.09), "shin" + s, "brass2", seg=6, rings=3)
        b.ball(J("wrist" + s), (0.07, 0.07, 0.05), "forearm" + s, "brass", seg=6, rings=3)
    b.ball(J("chest") + (0, -0.1, 0.0), (0.2, 0.08, 0.22), "chest", "armor", seg=8, rings=4)
    b.ball(J("chest") + (0, -0.17, 0.0), (0.07, 0.02, 0.07), "chest", "brass", seg=8, rings=3)
    b.ball(J("hips") + (0, -0.01, 0.07), (0.17, 0.12, 0.04), "hips", "brass2", seg=8, rings=3)
    # lantern tower on the back
    base = J("chest") + (0, 0.25, -0.05)
    b.box(base, (0.34, 0.3, 0.12), "chest", "brass2")
    b.limb(base + (0, 0.02, 0.05), base + (0, 0.05, 0.75), 0.15, 0.12, "tower", "rust", seg=8)
    b.ball(base + (0, 0.05, 0.4), (0.17, 0.17, 0.03), "tower", "brass", seg=8, rings=2)
    b.box(base + (0, 0.05, 0.9), (0.2, 0.2, 0.26), "tower", "lamp")
    b.spike(base + (0, 0.05, 1.03), base + (0, 0.05, 1.3), (0.17, 0.17), "tower", "rust", seg=6)
    b.ball(base + (0, 0.05, 1.33), 0.035, "tower", "brass", seg=5, rings=3)
    b.box(base + (0, 0.05, 0.77), (0.24, 0.24, 0.03), "tower", "brass")
    # big translucent wings
    for sg, s in ((1, ".L"), (-1, ".R")):
        r = J("chest") + (sg * 0.12, 0.16, 0.08)
        b.leaf(r, r + (sg * 0.9, 0.55, -0.1), 0.55, (0, 1, 0.5), "wing" + s, "wing", n=4, col2="wing2", bend=(sg * 0.1, 0.1, 0.1))
        b.leaf(r + (0, 0, -0.1), r + (sg * 0.55, 0.5, -1.0), 0.4, (0, 1, 0.3), "wing" + s, "wing2", n=4, col2="wing", bend=(sg * 0.1, 0.05, 0))
    # tattered cloak behind
    wt = hu.hang_weights(b, J("hips")[2] + 0.2, 0.4, 0.5)
    b.ring_skirt(J("hips") + (0, 0.1, 0.2), 0.2, 0.3, J("hips")[2] + 0.2, 0.35, wt, ["cloak", "cloak2"], n=10, jag=0.5, front_slit=1.9)
    # chains: sagging across the chest and a hanging anchor charm
    for sg in (1, -1):
        pts = [J("shoulder.L" if sg > 0 else "shoulder.R") + (0, -0.1, 0.05), J("chest") + (sg * 0.1, -0.15, -0.1), J("chest") + (0, -0.17, -0.2)]
        for i in range(len(pts) - 1):
            for t in (0.0, 0.25, 0.5, 0.75):
                b.ball(pts[i] * (1 - t) + pts[i + 1] * t, 0.016, "chest", "chain", seg=4, rings=3)
    b.ball(J("chest") + (0, -0.18, -0.26), (0.04, 0.015, 0.06), "chest", "brass", seg=5, rings=3)
    return b
