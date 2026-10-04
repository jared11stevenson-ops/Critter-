"""Ledger rival body, Helix: white lab-suit with teal piping, mirrored teal visor hood, sample case, injector gauntlet."""
import humanoid as hu
import npc_kit as K

ID = "rival_helix"
HEIGHT = 1.85
COMBAT = True
PAL = {"skin": "#d8b090", "suit": "#f2f6f8", "suit2": "#c8d4da", "teal": "#16c8d0", "visor": ("#6af0f8", "glow"), "hood": "#e0e8ec", "trouser": "#d8e0e6", "boot": "#2a3a44",
       "eye": "#12100e", "case": "#2a5a68", "glove": "#16c8d0"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("coat", 34, 5, 22)]
TSCN_EXTRA = 'combo_clips = PackedStringArray("attack_1", "attack_2")\nattack_map = {"heavy": "attack_3", "cast": "attack_1", "leap": "attack_2", "light": "attack_1"}\nmax_speed = 5.0\n'


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.02, torso=1.0, shoulders=0.95, hipw=0.9)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "suit", arms="suit", fore="suit", legs="trouser", boots="boot", hands="glove", tw=0.98, arm_r=0.95)
    K.hat(b, "helmet", "hood", "visor")
    K.coat(b, "suit", "teal", 0.4)
    K.belt(b, "teal", "case")
    J = b.j
    for s in (".L", ".R"):
        b.ball(J("shoulder" + s) + (0, 0, 0.0), (0.07, 0.065, 0.05), "upperarm" + s, "teal", seg=6, rings=3)
        b.ball(J("elbow" + s), (0.04, 0.04, 0.03), "forearm" + s, "suit2", seg=6, rings=3)
    b.limb(J("neck1") + (0.0, -0.06, -0.03), J("hips") + (0, -0.1, 0.08), 0.012, 0.012, "chest", "teal", seg=4)
    b.box(J("hips") + (-0.19, 0.0, -0.1), (0.07, 0.16, 0.18), "hips", "case")
    b.limb(J("wrist.R") + (0, 0, 0.0), J("wrist.R") + (0, -0.18, 0.0), 0.022, 0.012, "hand.R", "teal", seg=5)
    return b
