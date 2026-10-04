"""Dessa Harl: wiry dune hare, tall ears wrapped in a fuchsia salt-stained cloth, white dust cloak, long salt rake, brine flask, lesson slate."""
import humanoid as hu
import npc_kit as K

ID = "dessa_harl"
HEIGHT = 1.5
PAL = {"fur": "#f0e4d4", "fur2": "#b09880", "fuchsia": "#ff4aa0", "fuchsia2": "#c0207a", "cloak": "#fffaf0", "cloak2": "#d8d0c0", "teal": "#10d0bc", "brown": "#8a6a48",
       "boot": "#5a4a3a", "eye": "#1e1410", "nose": "#e07a8a", "wood": "#b08850", "slate": "#4a5058", "trouser": "#8a7a68", "inner": "#f0a0b0"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("cloak", 30, 5, 22), ("tail", 30, 5, 14), ("ear.L", 30, 4, 20), ("ear.R", 30, 4, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=0.95, neck=0.9, head=1.1, shoulders=0.8, hipw=0.85, arms=1.0, stoop=0.3)
    J = b.j
    b.add_bone("cloak", tuple(J("chest")), tuple(J("chest") + (0, 0.1, -0.6)), "chest")
    K.tail_bone(b, "tail", 0.18)
    b.add_bone_pair("ear", (0.05, J("head_end")[1], J("head_end")[2] - 0.04), (0.1, J("head_end")[1], J("head_end")[2] + 0.5), "head")
    hu.body(b, "fur", "trouser", arms="trouser", fore="fur", legs="trouser", boots="boot", hands="fur", tw=0.85, arm_r=0.8, leg_r=0.8, head_r=(0.048, 0.058, 0.056), nose=False)
    K.eyes(b, size=1.1, x=0.5, y=-0.85)
    K.snout(b, "fur", "nose", 0.45, -0.3, 0.4)
    for sg, s in ((1, ".L"), (-1, ".R")):
        base = hu.hp(b, sg * 0.4, 0.1, 0.8)
        tip = base + (sg * 0.03, 0.0, 0.5 * H * 0.6)
        b.leaf(base, tip, 0.1, (1, 0, 0), "ear" + s, "fuchsia", n=4, bend=(sg * 0.05, 0, 0))
        b.leaf(base + (0, -0.01, 0.0), tip + (0, -0.01, -0.06), 0.05, (1, 0, 0), "ear" + s, "inner", n=3)
    K.hat(b, "wrap", "fuchsia", "fuchsia2")
    b.ring_skirt(J("chest") + (0, 0.02, 0.06), 0.1, 0.22, J("chest")[2] + 0.04, J("hips")[2] - 0.35, lambda p: {"cloak": 1.0}, ["cloak", "cloak2"], n=10, jag=0.3, front_slit=1.0)
    K.belt(b, "brown", "brown")
    b.ball(J("hips") + (0.13, -0.05, -0.06), (0.04, 0.03, 0.06), "hips", "teal", seg=6, rings=4)
    h = J("wrist.R")
    b.limb(h + (0, 0.0, 0.5), h + (0.0, -0.05, -0.9), 0.014, 0.014, "hand.R", "wood", seg=5)
    b.box(h + (0, -0.06, -0.95), (0.3, 0.02, 0.03), "hand.R", "wood")
    for i in range(5):
        b.spike(h + (-0.12 + 0.06 * i, -0.06, -0.95), h + (-0.12 + 0.06 * i, -0.06, -1.08), 0.01, "hand.R", "wood", seg=3)
    b.box(J("hips") + (-0.12, -0.08, 0.1), (0.1, 0.02, 0.13), "hips", "slate", rot=(0, 0, 10))
    K.tail(b, "fur", 0.18, 0.06)
    return b
