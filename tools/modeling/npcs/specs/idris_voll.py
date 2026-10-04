"""Master Idris Voll: tall long-limbed cable weaver (spider-kin) in layered indigo robes; six silver cable threads trail from the sleeves, copper collar, bound ledger, plumb weight."""
import math

import humanoid as hu
import npc_kit as K

ID = "idris_voll"
HEIGHT = 2.3
PAL = {"skin": "#d8d4e4", "skin2": "#9a90b8", "robe": "#4a56d8", "robe2": "#2a3090", "robe3": "#7a86f0", "silver": "#eef4ff", "copper": "#ff9a3a", "eye": ("#ffb050", "glow"),
       "boot": "#2a2860", "book": "#8a5a30", "plumb": "#d0d8e0", "dark": "#1a1a22"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("robe", 32, 5, 20), ("thread", 22, 3, 40)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.15, torso=1.0, neck=1.2, head=0.9, shoulders=0.85, hipw=0.8, arms=1.3, stoop=0.5)
    J = b.j
    b.add_bone("robe", tuple(J("hips")), tuple(J("hips") + (0, 0.05, -0.5)), "hips")
    b.add_bone_pair("thread", (0.2, 0.0, J("chest")[2] - 0.4), (0.7, 0.6, J("chest")[2] - 1.2), "chest")
    hu.body(b, "skin", "robe", arms="robe", fore="robe2", legs="robe2", boots="boot", hands="skin2", tw=0.9, arm_r=0.7, leg_r=0.8, head_r=(0.042, 0.052, 0.058), nose=False)
    for sg in (1, -1):
        for k in range(2):
            b.ball(hu.hp(b, sg * (0.3 + 0.35 * k), -0.9, 0.3 + 0.05 * k), (0.012, 0.01, 0.012), "head", "eye", seg=5, rings=3)
    K.hat(b, "hood", "robe2")
    wt = hu.hang_weights(b, J("hips")[2] + 0.1, 0.1, 0.7)
    b.ring_skirt(J("hips") + (0, 0, 0.08), 0.15, 0.38, J("hips")[2] + 0.08, 0.1, wt, ["robe", "robe2", "robe3"], n=11, jag=0.3, wobble=0.1)
    b.ring_skirt(J("chest") + (0, 0, 0.04), 0.13, 0.17, J("chest")[2] + 0.04, J("hips")[2] - 0.1, lambda p: {"hips": 1.0}, ["robe3", "robe"], n=8, front_slit=0.8)
    b.ball(J("neck1") + (0, 0, -0.03), (0.1, 0.085, 0.035), "chest", "copper", seg=9, rings=3)
    K.belt(b, "copper", None)
    for s, sg in ((".L", 1), (".R", -1)):
        b.tatter(J("elbow" + s), 0.14, 0.34, "forearm" + s, "robe3", n=2, jag=0.3)
        for k in range(3):    # silver cable threads from the sleeves
            a = k * 0.5
            pts = [J("wrist" + s) + (0, 0, 0), J("wrist" + s) + (sg * (0.12 + 0.06 * k), 0.08, -0.25), J("wrist" + s) + (sg * (0.25 + 0.1 * k), 0.4, -0.55), J("wrist" + s) + (sg * (0.3 + 0.12 * k), 0.8, -0.85)]
            b.tube(pts, [0.012, 0.01, 0.008, 0.004], "forearm" + s, "silver", seg=3)
    b.box(J("hips") + (0.2, -0.04, -0.02), (0.08, 0.14, 0.18), "hips", "book")
    b.limb(J("hips") + (-0.16, -0.06, 0.02), J("hips") + (-0.16, -0.06, -0.35), 0.004, 0.004, "hips", "silver", seg=3)
    b.spike(J("hips") + (-0.16, -0.06, -0.35), J("hips") + (-0.16, -0.06, -0.48), (0.03, 0.03), "hips", "plumb", seg=5)
    return b
