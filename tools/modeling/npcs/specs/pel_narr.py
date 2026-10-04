"""Warden Pel Narr: very tall thin crane in a long drab coat, white plumage, cobalt sash, long beak, silver whistle, cable key."""
import humanoid as hu
import npc_kit as K

ID = "pel_narr"
HEIGHT = 2.6
PAL = {"feather": "#f8f8f4", "feather2": "#d8dcd8", "beak": "#f0b030", "coat": "#a8b4c4", "coat2": "#7a8898", "sash": "#2a6aea", "silver": "#e8eef4", "eye": "#12100e",
       "leg": "#8a8a90", "boot": "#4a4a50", "crest": "#e8404a", "board": "#8a6a44", "paper": "#fffdf4", "key": "#d0a030"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("coat", 34, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.3, torso=0.85, neck=2.6, head=0.8, shoulders=0.8, hipw=0.7, arms=1.1, stoop=0.3)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.5)), "hips")
    hu.body(b, "feather", "coat", arms="coat", fore="coat", legs="leg", boots="boot", hands="feather2", tw=0.85, arm_r=0.7, leg_r=0.5, head_r=(0.036, 0.05, 0.05), nose=False, neck_col="feather")
    K.eyes(b, size=1.0, x=0.7, y=-0.8)
    K.beak(b, "beak", 2.0, -0.15, 0.35)
    for sg in (1, -1):
        b.spike(hu.hp(b, sg * 0.1, 0.3, 0.8), hu.hp(b, sg * 0.3, 1.3, 1.5), (0.012, 0.012), "head", "crest", seg=3)
    K.coat(b, "coat", "coat2", 0.46)
    J = b.j
    b.limb(J("neck1") + (0.1, -0.06, -0.05), J("hips") + (-0.1, -0.08, 0.1), 0.02, 0.02, "chest", "sash", seg=4)
    b.ball(J("hips") + (0, -0.01, 0.06), (0.11, 0.08, 0.025), "hips", "sash", seg=8, rings=3)
    b.ball(J("neck1") + (0.0, -0.075, -0.03), (0.018, 0.012, 0.03), "chest", "silver", seg=5, rings=3)      # whistle
    b.limb(J("hips") + (0.12, -0.09, 0.0), J("hips") + (0.14, -0.1, -0.12), 0.006, 0.006, "hips", "key", seg=3)
    K.clipboard(b, "L", "board", "paper")
    return b
