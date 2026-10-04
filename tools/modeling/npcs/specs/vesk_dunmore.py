"""Vesk Dunmore: wiry hunched claims-broker, charcoal coat hung with glass charms and tally beads, acid-yellow scarf, survey stake, red-corded claim flag."""
import humanoid as hu
import npc_kit as K

ID = "vesk_dunmore"
HEIGHT = 1.75
PAL = {"skin": "#c89468", "hair": "#2a2018", "coat": "#4a505e", "coat2": "#2a2d33", "scarf": "#d8f800", "yellow": "#f0dc50", "trouser": "#6a4a38", "boot": "#2a2018",
       "eye": "#12100e", "charm1": ("#7affd8", "glow"), "charm2": ("#ff9ad0", "glow"), "bead": "#ff6a30", "wood": "#9a7040", "cord": "#e03a30", "flag": "#f0ece0"}
STYLE = {"chest": (4, 0, 0), "head": (-3, 0, 0)}
SECONDARY = [("coat", 34, 5, 24)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.98, torso=1.0, neck=1.0, head=0.95, shoulders=0.85, hipw=0.85, arms=1.1, stoop=1.1)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "coat", arms="coat", fore="coat", legs="trouser", boots="boot", hands="skin", tw=0.95, arm_r=0.95)
    K.eyes(b, size=1.1)
    K.brows(b, "hair")
    b.ball(hu.hp(b, 0, 0.1, 0.38), (b.hr[0] * 1.06, b.hr[1] * 1.06, b.hr[2] * 0.7), "head", "hair", seg=9, rings=4)
    K.coat(b, "coat", "coat2", 0.5)
    K.scarf(b, "scarf", "scarf", 1.0)
    K.belt(b, "coat2", "coat2")
    K.charms(b, ["charm1", "charm2", "bead", "yellow"], n=9, spread=0.14)
    J = b.j
    for i in range(7):       # charms and beads dangling from the coat hem
        x = -0.14 + 0.047 * i
        b.limb(J("hips") + (x, -0.1, -0.05), J("hips") + (x, -0.1, -0.2 - 0.05 * (i % 3)), 0.003, 0.003, "hips", "bead", seg=3)
        b.ball(J("hips") + (x, -0.1, -0.22 - 0.05 * (i % 3)), 0.018, "hips", ("charm1", "charm2", "yellow")[i % 3], seg=5, rings=3)
    K.staff(b, "L", "wood", 1.5, tip=None)
    h = J("wrist.L")
    b.leaf(h + (0, 0, 0.3), h + (0, -0.2, 0.26), 0.16, (0, 0, 1), "hand.L", "flag", n=2)
    b.limb(h + (0, 0, 0.3), h + (0, -0.04, 0.2), 0.004, 0.004, "hand.L", "cord", seg=3)
    return b
