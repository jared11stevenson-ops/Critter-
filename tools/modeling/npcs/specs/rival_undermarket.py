"""Ledger rival body, Undermarket: long brown coat with gold trim, goggled flat cap, bulging satchel, charm bandolier."""
import humanoid as hu
import npc_kit as K

ID = "rival_undermarket"
HEIGHT = 1.8
COMBAT = True
PAL = {"skin": "#c28a60", "coat": "#c8782e", "coat2": "#8a4a1c", "gold": "#ffd040", "cap": "#5a3a28", "goggle": ("#ffd890", "glow"), "trouser": "#4a3a30", "boot": "#2a1e18",
       "eye": "#12100e", "satchel": "#a06a30", "leather": "#6a4426", "gem": ("#ff6ad0", "glow")}
STYLE = {"chest": (3, 0, 0)}
SECONDARY = [("coat", 34, 5, 24)]
TSCN_EXTRA = 'combo_clips = PackedStringArray("attack_1", "attack_2")\nattack_map = {"heavy": "attack_3", "cast": "attack_1", "leap": "attack_2", "light": "attack_1"}\nmax_speed = 5.0\n'


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.0, torso=1.0, shoulders=1.0, hipw=0.95)
    b.add_bone("coat", tuple(b.j("hips")), tuple(b.j("hips") + (0, 0.05, -0.4)), "hips")
    hu.body(b, "skin", "coat", arms="coat", fore="coat", legs="trouser", boots="boot", hands="leather", tw=1.05, arm_r=1.0)
    K.eyes(b)
    K.hat(b, "cap", "cap", "gold")
    for sg in (1, -1):
        b.ball(hu.hp(b, sg * 0.45, -0.9, 0.55), (b.hr[0] * 0.3, 0.012, b.hr[2] * 0.2), "head", "goggle", seg=6, rings=3)
    K.coat(b, "coat", "coat2", 0.45)
    K.belt(b, "gold", "leather")
    J = b.j
    b.limb(J("neck1") + (0.1, -0.07, -0.03), J("hips") + (-0.12, -0.09, 0.0), 0.02, 0.02, "chest", "gold", seg=4)
    b.box(J("hips") + (-0.2, 0.05, -0.05), (0.12, 0.1, 0.16), "hips", "satchel")
    for s in (".L", ".R"):
        b.ball(J("wrist" + s), (0.05, 0.05, 0.03), "forearm" + s, "gold", seg=6, rings=3)
    b.ball(J("chest") + (0, -0.095, 0.0), (0.02, 0.01, 0.025), "chest", "gem", seg=5, rings=3)
    return b
