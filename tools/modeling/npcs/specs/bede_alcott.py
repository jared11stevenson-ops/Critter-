"""Bede Alcott: heavy-shouldered calf keeper in a stained bottle-green field coat, hand on a calf's neck; pink calf blanket over the shoulder, feed bottles at the belt."""
import humanoid as hu
import npc_kit as K

ID = "bede_alcott"
HEIGHT = 1.8
PAL = {"skin": "#cc9068", "hair": "#4a2a20", "coat": "#20c27a", "coat2": "#12703f", "cream": "#f6eedc", "pink": "#ff6ea0", "trouser": "#7a6a50", "boot": "#3a2a20",
       "eye": "#1e1410", "bottle": ("#fff6e8", "glow"), "stain": "#7a5a30", "leather": "#8a5a30"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("coat", 32, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.95, torso=1.05, neck=0.8, head=0.98, shoulders=1.25, hipw=1.1, arms=1.05, stoop=0.4)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "coat", arms="coat", fore="coat", legs="trouser", boots="boot", hands="skin", tw=1.2, arm_r=1.2, leg_r=1.1)
    K.eyes(b)
    K.brows(b, "hair")
    b.ball(hu.hp(b, 0, 0.12, 0.38), (b.hr[0] * 1.07, b.hr[1] * 1.07, b.hr[2] * 0.72), "head", "hair", seg=9, rings=4)
    b.ball(hu.hp(b, 0, -0.75, -0.62), (b.hr[0] * 0.7, b.hr[1] * 0.35, b.hr[2] * 0.3), "head", "hair", seg=6, rings=3)
    K.coat(b, "coat", "coat2", 0.4)
    K.belt(b, "leather", "leather")
    J = b.j
    b.ball(J("shoulder.R") + (-0.03, 0, 0.04), (0.12, 0.1, 0.05), "upperarm.R", "pink", seg=8, rings=3)
    b.tatter(J("shoulder.R") + (-0.04, 0.0, 0.0), 0.14, 0.5, "upperarm.R", "pink", n=2, jag=0.2)
    for i, x in enumerate((0.12, 0.17)):
        b.limb(J("hips") + (x, -0.07, -0.02), J("hips") + (x, -0.07, -0.16), 0.022, 0.022, "hips", "bottle", seg=5)
    for i in range(3):
        b.ball(J("chest") + (0.07 - 0.07 * i, -0.09, -0.05 - 0.07 * (i % 2)), (0.03, 0.01, 0.03), "chest", "stain", seg=4, rings=2)
    return b
