"""Ledger rival body, Human Dominion: gunmetal tac-coat, red visor helmet, red sigil, utility belt, carbine on the back."""
import humanoid as hu
import npc_kit as K

ID = "rival_dominion"
HEIGHT = 1.85
COMBAT = True
PAL = {"skin": "#c89468", "coat": "#6a7488", "coat2": "#454c5c", "red": "#ff3a2c", "visor": ("#ff4a30", "glow"), "helmet": "#3c4252", "trouser": "#4a5062", "boot": "#262a36",
       "metal": "#aab3c8", "eye": "#12100e", "leather": "#5a4636"}
STYLE = {"chest": (3, 0, 0)}
SECONDARY = [("coat", 34, 5, 24)]
TSCN_EXTRA = 'combo_clips = PackedStringArray("attack_1", "attack_2")\nattack_map = {"heavy": "attack_3", "cast": "attack_1", "leap": "attack_2", "light": "attack_1"}\nmax_speed = 5.0\n'


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.02, torso=1.0, shoulders=1.1, hipw=0.95)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "coat", arms="coat", fore="coat2", legs="trouser", boots="boot", hands="coat2", tw=1.05, arm_r=1.05)
    K.hat(b, "helmet", "helmet", "visor")
    K.coat(b, "coat", "red", 0.38)
    K.belt(b, "leather", "leather")
    J = b.j
    b.ball(J("shoulder.L") + (0, -0.03, 0.01), (0.024, 0.01, 0.034), "upperarm.L", "red", seg=6, rings=3)
    b.ball(J("chest") + (0, -0.09, 0.02), (0.05, 0.012, 0.07), "chest", "red", seg=6, rings=3)
    for s in (".L", ".R"):
        b.ball(J("shoulder" + s), (0.075, 0.07, 0.06), "upperarm" + s, "coat2", seg=6, rings=3)
        b.ball(J("knee" + s) + (0, -0.03, 0), (0.05, 0.04, 0.06), "shin" + s, "coat2", seg=6, rings=3)
    b.limb(J("chest") + (0.1, 0.1, 0.2), J("chest") + (-0.1, 0.1, -0.35), 0.02, 0.02, "chest", "metal", seg=5)
    return b
