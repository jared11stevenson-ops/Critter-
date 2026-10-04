"""Clerk Odalys Penhallow: upright, narrow, prim Dominion clerk; pale lavender suit, cyan lanyard, brass stamp case, crimson stamp pad, rolled permit scroll, glasses on a chain."""
import humanoid as hu
import npc_kit as K

ID = "odalys_penhallow"
HEIGHT = 1.7
PAL = {"skin": "#e8b890", "hair": "#8a7a90", "suit": "#efe8fa", "suit2": "#c8bede", "cyan": "#52e0ff", "crimson": "#c02050", "brass": "#ffc040", "boot": "#3a2e48",
       "eye": "#1e1410", "paper": "#fff8e8", "glass": ("#cfeaff", "glow"), "trouser": "#d8d0ec"}
STYLE = {"chest": (-3, 0, 0), "head": (2, 0, 0)}
SECONDARY = []


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=1.0, neck=1.1, head=0.95, shoulders=0.8, hipw=0.85, arms=1.0, stoop=-0.2)
    hu.body(b, "skin", "suit", arms="suit", fore="suit", legs="trouser", boots="boot", hands="skin", tw=0.9, arm_r=0.85, leg_r=0.9)
    K.eyes(b)
    b.ball(hu.hp(b, 0, 0.15, 0.3), (b.hr[0] * 1.08, b.hr[1] * 1.08, b.hr[2] * 0.75), "head", "hair", seg=9, rings=4)
    b.ball(hu.hp(b, 0, 0.9, 0.3), (b.hr[0] * 0.8, b.hr[1] * 0.5, b.hr[2] * 0.45), "head", "hair", seg=7, rings=3)     # tight bun
    for sg in (1, -1):
        b.ball(hu.hp(b, sg * 0.42, -1.0, 0.08), (b.hr[0] * 0.3, 0.004, b.hr[2] * 0.24), "head", "glass", seg=6, rings=3)
    J = b.j
    b.limb(J("neck1") + (0.04, -0.06, -0.02), J("hips") + (0.0, -0.1, 0.1), 0.007, 0.007, "chest", "cyan", seg=3)
    b.limb(J("neck1") + (-0.04, -0.06, -0.02), J("hips") + (0.0, -0.1, 0.1), 0.007, 0.007, "chest", "cyan", seg=3)
    b.box(J("chest") + (0, -0.085, -0.1), (0.045, 0.006, 0.06), "chest", "paper")
    K.coat(b, "suit", "suit2", 0.28, collar=False)
    K.belt(b, "suit2", None)
    b.box(J("hips") + (0.11, -0.04, 0.0), (0.07, 0.06, 0.09), "hips", "brass")      # stamp case
    b.box(J("hips") + (-0.1, -0.04, 0.0), (0.06, 0.05, 0.04), "hips", "crimson")    # stamp pad
    h = J("wrist.L")
    b.limb(h + (0, -0.09, 0.0), h + (0, 0.1, -0.02), 0.03, 0.03, "hand.L", "paper", seg=7, rot=None) if False else b.limb(h + (0, -0.12, 0.0), h + (0, 0.1, -0.02), 0.03, 0.03, "hand.L", "paper", seg=7)
    return b
