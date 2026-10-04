"""Hobb Sarrane: squat wide-shouldered ridge badger, battered wide-brim hat, violet hood, lime neckerchief, hauling harness, notched tally stick."""
import humanoid as hu
import npc_kit as K

ID = "hobb_sarrane"
HEIGHT = 1.25
PAL = {"fur": "#bdb8ac", "fur2": "#4a4440", "stripe": "#f4f0e4", "hood": "#8a50d0", "hood2": "#5a2f98", "lime": "#c4f04a", "hat": "#5a3a28", "hat2": "#2a1a16",
       "harness": "#8a5a30", "boot": "#3a2a20", "eye": "#12100e", "nose": "#201816", "cloth": "#d8c8a0", "wood": "#c09a60"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("tail", 30, 5, 18)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.65, torso=1.1, neck=0.5, head=1.2, shoulders=1.4, hipw=1.3, arms=0.95, stoop=0.3)
    K.tail_bone(b, "tail", 0.35)
    hu.body(b, "fur", "hood", arms="hood", fore="fur", legs="fur2", boots="boot", hands="fur2", tw=1.3, arm_r=1.3, leg_r=1.25, head_r=(0.05, 0.06, 0.056), nose=False)
    K.eyes(b, size=0.9, y=-0.92, x=0.38)
    K.snout(b, "fur", "nose", 0.9, -0.2, 0.45)
    b.ball(hu.hp(b, 0, -0.6, 0.12), (b.hr[0] * 0.14, b.hr[1] * 0.9, 0.012), "head", "stripe", seg=5, rings=3)
    for sg in (1, -1):
        b.ball(hu.hp(b, sg * 0.5, -0.4, 0.15), (b.hr[0] * 0.2, b.hr[1] * 0.9, b.hr[2] * 0.35), "head", "fur2", seg=5, rings=3, rot=(0, 0, sg * 15))
        b.ball(hu.hp(b, sg * 0.62, 0.15, 0.82), (b.hr[0] * 0.28, b.hr[1] * 0.2, b.hr[2] * 0.26), "head", "fur2", seg=5, rings=3)
    K.hat(b, "wide", "hat", "hat2")
    K.scarf(b, "lime", "lime", 0.8)
    b.ball(b.j("neck1") + (0, 0.04, 0.0), (0.12, 0.1, 0.07), "chest", "hood2", seg=8, rings=3)
    K.belt(b, "harness", "harness")
    J = b.j
    for sg in (1, -1):
        b.limb(J("neck1") + (sg * 0.1, -0.06, -0.03), J("hips") + (-sg * 0.1, -0.08, 0.04), 0.014, 0.014, "chest", "harness", seg=4)
    b.ball(J("hips") + (0, 0.1, -0.02), (0.1, 0.1, 0.1), "hips", "wood", seg=8, rings=4)       # spare wheel hub
    b.limb(J("hip.R") + (-0.05, -0.05, -0.05), J("hip.R") + (-0.05, -0.05, -0.3), 0.01, 0.01, "thigh.R", "wood", seg=4)
    K.tail(b, "fur2", 0.35, 0.05)
    return b
