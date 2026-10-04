"""Imre Dahl: narrow-shouldered stooped Dominion surveyor, pale grey coat, cyan hi-vis vest, survey backpack with cyan flags, clipboard."""
import humanoid as hu
import npc_kit as K

ID = "imre_dahl"
HEIGHT = 1.78
PAL = {"skin": "#e0a878", "hair": "#6a5040", "coat": "#e6eaf0", "coat2": "#b8c0cc", "vest": "#52e0ff", "pack": "#8a7a6a", "trouser": "#5a5a6a", "boot": "#3a3028",
       "eye": "#1e1410", "flag": ("#52e0ff", "glow"), "board": "#8a6a44", "paper": "#fffdf4", "red": "#e04030"}
STYLE = {"chest": (3, 0, 0), "head": (-3, 0, 0)}
SECONDARY = [("coat", 34, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=1.0, neck=1.1, head=0.95, shoulders=0.8, hipw=0.85, arms=1.05, stoop=0.9)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "vest", arms="coat", fore="coat", legs="trouser", boots="boot", hands="skin", tw=0.9, arm_r=0.95)
    K.eyes(b)
    b.ball(hu.hp(b, 0, 0.1, 0.35), (b.hr[0] * 1.06, b.hr[1] * 1.06, b.hr[2] * 0.7), "head", "hair", seg=9, rings=4)
    K.coat(b, "coat", "coat2", 0.38)
    b.ball(b.j("chest") + (0, 0.0, 0.0), (0.1, 0.075, 0.12), "chest", "coat", seg=7, rings=3)
    K.backpack(b, "pack", "vest", 1.1)
    J = b.j
    for i, x in enumerate((-0.07, 0.0, 0.07)):
        b.limb(J("spine2") + (x, 0.12, 0.2), J("spine2") + (x * 2, 0.14, 0.55), 0.008, 0.008, "chest", "board", seg=3)
        b.leaf(J("spine2") + (x * 2, 0.14, 0.5), J("spine2") + (x * 2 + 0.07, 0.14, 0.55), 0.05, (0, 0, 1), "chest", "flag", n=1)
    K.clipboard(b, "R", "board", "paper")
    K.belt(b, "pack")
    return b
