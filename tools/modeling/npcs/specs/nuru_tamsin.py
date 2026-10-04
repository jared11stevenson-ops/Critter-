"""Nuru Tamsin: small long-tailed dune skink in a layered travel wrap; teal scarf, silver rings, bandolier of evidence cylinders, hand lens."""
import humanoid as hu
import npc_kit as K

ID = "nuru_tamsin"
HEIGHT = 1.25
PAL = {"skin": "#c8d26a", "skin2": "#8a9a40", "wrap": "#f0eadc", "wrap2": "#c9bfa8", "teal": "#10d0bc", "orange": "#ff9a10", "silver": "#e8eef4", "eye": ("#1a1008", "glow"),
       "trouser": "#6a5a48", "boot": "#3a2e24", "cyl": "#ffffff", "dark": "#2a1a16", "lens": ("#9ff0ff", "glow")}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("tail", 28, 4, 26), ("wrap", 34, 5, 20)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.85, torso=1.0, neck=0.8, head=1.15, shoulders=0.85, hipw=0.85, arms=1.0, stoop=0.3)
    b.add_bone("wrap", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.04, -0.3)), "hips")
    K.tail_bone(b, "tail", 0.8)
    hu.body(b, "skin", "wrap", arms="wrap", fore="skin", legs="trouser", boots="boot", hands="skin2", tw=0.9, arm_r=0.8, leg_r=0.8, head_r=(0.046, 0.058, 0.05), nose=False)
    for sg in (1, -1):
        b.ball(hu.hp(b, sg * 0.62, -0.7, 0.35), (0.016, 0.014, 0.02), "head", "eye", seg=6, rings=4)
        b.ball(hu.hp(b, sg * 1.0, -0.1, -0.1), (0.008, 0.008, 0.008), "head", "silver", seg=4, rings=3)
    snout = K.snout
    snout(b, "skin", "dark", 0.7, -0.2, 0.5)
    K.scarf(b, "teal", "teal", 1.2)
    J = b.j
    wt = hu.hang_weights(b, J("hips")[2] + 0.05, 0.3, 0.5)
    b.ring_skirt(J("hips") + (0, 0, 0.05), 0.1, 0.2, J("hips")[2] + 0.04, 0.3, wt, ["wrap", "wrap2", "wrap"], n=9, jag=0.3, wobble=0.1)
    b.limb(J("neck1") + (0.08, -0.06, -0.03), J("hips") + (-0.08, -0.08, 0.04), 0.014, 0.014, "chest", "orange", seg=4)
    for i in range(5):
        t = i / 4
        b.limb(J("neck1") * (1 - t) + J("hips") * t + (0.07 - 0.14 * t, -0.09, 0.0), J("neck1") * (1 - t) + J("hips") * t + (0.07 - 0.14 * t, -0.09, -0.07), 0.012, 0.012, "chest", "cyl", seg=4)
    b.ball(J("wrist.R") + (0, -0.03, 0.0), (0.03, 0.01, 0.03), "hand.R", "lens", seg=6, rings=3)
    K.tail(b, "skin", 0.8, 0.045, "tail", drop=-0.12, curl=0.1)
    return b
