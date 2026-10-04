"""Ledger rival body, Free Scale: leaf-green cloak, feathered wide hat, bark-and-bone armour bits, long bow-staff."""
import humanoid as hu
import npc_kit as K

ID = "rival_free_scale"
HEIGHT = 1.75
COMBAT = True
PAL = {"skin": "#b8905a", "cloak": "#4acc6a", "cloak2": "#1f8a45", "hat": "#8a6a2c", "feather": "#ffe060", "bone": "#f4ecd0", "trouser": "#6a5a38", "boot": "#3a2e1c",
       "eye": "#12100e", "wood": "#9a7040", "leather": "#6a4a2a"}
STYLE = {"chest": (2, 0, 0)}
SECONDARY = [("cloak", 32, 5, 24)]
TSCN_EXTRA = 'combo_clips = PackedStringArray("attack_1", "attack_2")\nattack_map = {"heavy": "attack_3", "cast": "attack_1", "leap": "attack_2", "light": "attack_1"}\nmax_speed = 5.0\n'


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.05, torso=0.95, shoulders=0.95, hipw=0.9)
    b.add_bone("cloak", tuple(b.j("chest")), tuple(b.j("chest") + (0, 0.1, -0.6)), "chest")
    hu.body(b, "skin", "cloak2", arms="cloak2", fore="skin", legs="trouser", boots="boot", hands="skin", tw=0.95, arm_r=0.95)
    K.eyes(b)
    K.hat(b, "wide", "hat", "cloak")
    b.leaf(hu.hp(b, 0.7, 0.0, 0.8), hu.hp(b, 1.4, 0.6, 2.2), 0.05, (0, 1, 0), "head", "feather", n=2)
    J = b.j
    b.ring_skirt(J("neck1") + (0, 0.04, -0.02), 0.1, 0.24, J("chest")[2] + 0.06, J("hips")[2] - 0.3, lambda p: {"cloak": 1.0}, ["cloak", "cloak2"], n=10, jag=0.35, front_slit=1.0)
    K.belt(b, "leather", "leather")
    for s in (".L", ".R"):
        b.ball(J("shoulder" + s), (0.07, 0.065, 0.05), "upperarm" + s, "bone", seg=6, rings=3)
        b.ball(J("knee" + s) + (0, -0.03, 0), (0.045, 0.04, 0.055), "shin" + s, "bone", seg=6, rings=3)
    K.staff(b, "R", "wood", 1.9, tip="bone")
    return b
