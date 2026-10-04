"""Tavik Roon: tall stooped drover, cobalt poncho, bone-white bandana, brass bell, herding crook, satchel."""
import humanoid as hu
import npc_kit as K

ID = "tavik_roon"
HEIGHT = 1.9
PAL = {"skin": "#c98a5e", "hair": "#4a2a20", "poncho": "#3a52e0", "poncho2": "#2438a8", "bone": "#f6eedc", "brass": "#ffc01a", "trouser": "#8a6a44", "boot": "#4a3020",
       "leather": "#7a5030", "eye": "#1e1410", "wood": "#9a7040", "seed": "#9fd05a"}
STYLE = {"chest": (3, 0, 0)}
SECONDARY = [("poncho", 30, 5, 18)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=1.05, torso=1.0, neck=1.1, head=0.95, shoulders=0.95, hipw=0.9, arms=1.1, stoop=0.8)
    b.add_bone("poncho", tuple(b.j("chest")), tuple(b.j("chest") + (0, 0.05, -0.5)), "chest")
    hu.body(b, "skin", "poncho", arms="poncho", fore="skin", legs="trouser", boots="boot", hands="skin", tw=1.0, arm_r=0.9, leg_r=0.95)
    K.eyes(b)
    K.brows(b, "hair")
    b.ball(hu.hp(b, 0, 0.1, 0.35), (b.hr[0] * 1.06, b.hr[1] * 1.06, b.hr[2] * 0.7), "head", "hair", seg=9, rings=4)
    K.scarf(b, "bone", "bone", 0.6)
    J = b.j
    wt = lambda p: {"poncho": 1.0}
    sz = J("chest")[2] + 0.08
    b.ring_skirt(J("neck1") + (0, 0, -0.02), 0.15, 0.36, sz, sz - 0.62, wt, ["poncho", "poncho2", "poncho"], n=10, jag=0.25, front_slit=0.0)
    b.ball(J("neck1") + (0, 0, -0.05), (0.14, 0.12, 0.05), "chest", "poncho2", seg=9, rings=3)
    K.belt(b, "leather", "leather")
    b.ball(J("hips") + (0.17, -0.02, -0.08), (0.025, 0.025, 0.04), "hips", "brass", seg=5, rings=3)
    b.box(J("hips") + (-0.2, 0.08, -0.04), (0.1, 0.07, 0.12), "hips", "leather")
    K.staff(b, "R", "wood", 1.8, hook=True)
    return b
