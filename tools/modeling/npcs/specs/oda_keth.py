"""Mother Oda Keth: low broad slate-shelled Keth, long callused forearms, white headcloth, turquoise water flask, tally-knot cord."""
import humanoid as hu
import npc_kit as K

ID = "oda_keth"
HEIGHT = 1.5
PAL = {"skin": "#8a7468", "skin2": "#6b5a52", "shell": "#5f86b0", "shell2": "#3e5878", "cloth": "#f4f1e8", "cloth2": "#d8d0c0", "robe": "#3f6a8a", "flask": "#19c3c9",
       "copper": "#e08a3a", "dark": "#2a1a16", "eye": "#1e1410", "knot": "#ffd66a", "boot": "#3c2e2a"}
STYLE = {"chest": (4, 0, 0)}
SECONDARY = [("shell", 28, 6, 8)]


def build():
    H = HEIGHT
    b = hu.new(ID, H, PAL, legs=0.72, torso=1.25, neck=0.6, head=1.1, shoulders=1.5, hipw=1.4, arms=1.35, stoop=0.5)
    hu.body(b, "skin", "robe", arms="robe", fore="skin2", legs="robe", boots="boot", hands="skin2", tw=1.25, arm_r=1.35, leg_r=1.25, head_r=(0.05, 0.056, 0.058), nose=False)
    K.eyes(b, size=1.1)
    b.ball(hu.hp(b, 0, -0.95, -0.4), (0.04, 0.012, 0.01), "head", "dark", seg=5, rings=3)
    K.shell_dome(b, "shell", "shell2", 1.1)
    K.hat(b, "wrap", "cloth", "cloth2")
    K.belt(b, "dark")
    J = b.j
    for s, sg in ((".L", 1), (".R", -1)):
        b.ball(J("elbow" + s), 0.05 * H, "forearm" + s, "robe", seg=6, rings=3)
    # turquoise flask + copper dipper + tally knots on the cord
    b.ball(J("hips") + (0.14, -0.04, -0.06), (0.05, 0.04, 0.08), "hips", "flask", seg=7, rings=4)
    b.ball(J("hips") + (0.14, -0.04, 0.03), (0.02, 0.02, 0.02), "hips", "copper", seg=5, rings=3)
    b.limb(J("wrist.R"), J("wrist.R") + (0, -0.1, -0.25), 0.012, 0.012, "hand.R", "copper", seg=4)
    b.ball(J("wrist.R") + (0, -0.12, -0.3), (0.05, 0.05, 0.03), "hand.R", "copper", seg=6, rings=3)
    for i in range(5):
        b.ball(J("hips") + (-0.1 + 0.03 * i, -0.085, -0.05 - 0.02 * (i % 2)), 0.014, "hips", "knot", seg=4, rings=3)
    return b
