"""Shared humanoid body for NPC specs: standard bone set + default body parts (capsules), tunable per spec."""
import numpy as np

import npc_lib as L

V = np.array


def new(cid, H, palette, extra_bones=None, **proportions):
    J = L.humanoid_joints(H, **proportions)
    bones = L.mirror_bones(L.HUMANOID_BONES)
    b = L.Builder(cid, H, J, bones, palette)
    return b


def head_center(b, f=0.5):
    return b.j("head") * (1 - f) + b.j("head_end") * f


def body(b, skin, torso, arms=None, legs=None, boots=None, hands=None, fore=None, rs=1.0, tw=1.0, hips_col=None, arm_r=1.0,
         leg_r=1.0, head_r=(0.048, 0.054, 0.062), neck_col=None, seg=7, head=True, feet=True, hand_r=1.0, nose=True):
    """Default humanoid: hips, torso, neck, head, arms, hands, legs, feet. Colours are palette keys."""
    H = b.H
    arms = arms or torso
    legs = legs or torso
    boots = boots or legs
    hands = hands or skin
    fore = fore or arms
    hips_col = hips_col or legs
    neck_col = neck_col or skin
    R = H * rs
    J = b.j
    b.ball(J("hips") + (0, 0.0, 0.0), (0.075 * R * tw, 0.055 * R, 0.05 * R), "hips", hips_col, seg=seg, rings=4)
    b.limb("spine1", "spine2", (0.07 * R * tw, 0.05 * R), (0.078 * R * tw, 0.055 * R), "spine1", torso, seg=seg)
    b.limb("spine2", "chest", (0.078 * R * tw, 0.055 * R), (0.088 * R * tw, 0.06 * R), "spine2", torso, seg=seg)
    b.limb("chest", "neck1", (0.088 * R * tw, 0.06 * R), (0.05 * R * tw, 0.04 * R), "chest", torso, seg=seg)
    b.limb(J("neck1") + (0, 0, -0.03 * R), J("head") + (0, 0, 0.03 * R), 0.034 * R, 0.03 * R, "neck1", neck_col, seg=6)
    if head:
        hc = head_center(b, 0.42)
        b.hc = hc
        b.hr = V([x * R for x in head_r])
        b.ball(hc, tuple(x * R for x in head_r), "head", skin, seg=9, rings=6)
        if nose:
            b.spike(hc + (0, -head_r[1] * R * 0.85, -0.004 * R), hc + (0, -head_r[1] * R * 1.25, -0.016 * R), 0.011 * R, "head", skin, seg=4, smooth=True)
    for s in (".L", ".R"):
        b.limb("clav" + s, "shoulder" + s, 0.04 * R * arm_r, 0.038 * R * arm_r, "clavicle" + s, torso, seg=6)
        b.ball(b.j("shoulder" + s), 0.04 * R * arm_r, "upperarm" + s, arms, seg=6, rings=4)
        b.limb("shoulder" + s, "elbow" + s, 0.033 * R * arm_r, 0.027 * R * arm_r, "upperarm" + s, arms, seg=seg)
        b.limb("elbow" + s, "wrist" + s, 0.027 * R * arm_r, 0.021 * R * arm_r, "forearm" + s, fore, seg=seg)
        b.ball(b.j("wrist" + s) * 0.5 + b.j("hand_end" + s) * 0.5, (0.026 * R * hand_r, 0.02 * R * hand_r, 0.034 * R * hand_r),
               "hand" + s, hands, seg=6, rings=4)
        b.limb("hip" + s, "knee" + s, 0.05 * R * leg_r, 0.037 * R * leg_r, "thigh" + s, legs, seg=seg)
        b.limb("knee" + s, "ankle" + s, 0.037 * R * leg_r, 0.027 * R * leg_r, "shin" + s, legs, seg=seg)
        if feet:
            b.limb("ankle" + s, "ball" + s, (0.032 * R * leg_r, 0.032 * R * leg_r), (0.03 * R * leg_r, 0.02 * R * leg_r), "foot" + s, boots, seg=6)
            b.limb("ball" + s, "toe_end" + s, (0.03 * R * leg_r, 0.02 * R * leg_r), (0.022 * R * leg_r, 0.012 * R * leg_r), "toe" + s, boots, seg=6)


def sides(fn):
    """Call fn(sign, suffix) for left (+1, '.L') and right (-1, '.R')."""
    for sg, s in ((1, ".L"), (-1, ".R")):
        fn(sg, s)


def mir(p, sg):
    return (p[0] * sg, p[1], p[2])


def hang_weights(b, z_top, z_bot, thigh_w=0.75):
    """Weights for hanging cloth (coat skirt / sarong): hips at the top, blending into the thighs towards the hem."""
    def f(p):
        t = min(1.0, max(0.0, (z_top - p[2]) / max(z_top - z_bot, 1e-3)))
        s = ".L" if p[0] >= 0 else ".R"
        w = t * thigh_w
        return {"hips": 1.0 - w, "thigh" + s: w} if w > 0.02 else {"hips": 1.0}
    return f


def hp(b, x, y, z):
    """Point on/near the head ellipsoid in unit coordinates (x=left, y=-1 is the face, z=up)."""
    return b.hc + V((x * b.hr[0], y * b.hr[1], z * b.hr[2]))
