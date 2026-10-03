"""Aruun keyframed actions, authored as data.

Pose = {bone: (rx, ry, rz)} in degrees, rotations about ARMATURE axes (Z up, character faces -Y, his left +X):
  rx > 0 tips an upward bone forward / swings a hanging limb BACK; ry > 0 tilts toward his left (+X) for
  upward bones; rz > 0 turns the front toward his left. Special keys: "hips_loc": (x, y, z) metres
  (armature space offset), "weapon_len": haft scale (Morrow's telescoping reach), "jaw": open angle.
Mirroring helper `M()` builds .R from .L values (ry, rz negate).
"""
import math

import bpy
from mathutils import Euler, Quaternion, Vector

FPS = 30


def M(bone, rx, ry=0.0, rz=0.0):
    """Mirror a left-side rotation to the right side."""
    return {bone.replace(".L", ".R"): (rx, -ry, -rz)}


def P(**kw):
    """Pose builder: P(spine1=(5,0,0), ...); dots in names written as '_L' / '_R'."""
    out = {}
    for k, v in kw.items():
        k = k.replace("_L", ".L").replace("_R", ".R")
        out[k] = v
    return out


def mix(*poses):
    out = {}
    for p in poses:
        out.update(p)
    return out


ARMS_REST = P(upperarm_L=(0, -4, 0), upperarm_R=(0, 4, 0), forearm_L=(-8, 0, 0), forearm_R=(-14, 0, 0))

# ------------------------------------------------------------------------------------------- clips
def idle():
    a = mix(ARMS_REST, P(chest=(0, 0, 0), head=(0, 0, 0), neck1=(0, 0, 0), hips_loc=(0, 0, 0)))
    b = mix(ARMS_REST, P(chest=(-2.5, 0, 0), head=(3, 0, 2), neck1=(-1.5, 0, 0), hips_loc=(0, 0, -0.008),
                         upperarm_L=(0, -6, 0)))
    return dict(dur=2.4, loop=True, keys=[(0, a), (1.2, b), (2.4, a)], impact=None)


def _gait(dur, thigh, shin, arm, lean, bob, rh=0.35):
    keys = []
    for i, ph in enumerate((0, 0.25, 0.5, 0.75, 1.0)):
        s = math.cos(ph * 2 * math.pi)
        lift_l = max(0.0, math.sin(ph * 2 * math.pi))
        lift_r = max(0.0, -math.sin(ph * 2 * math.pi))
        p = mix(ARMS_REST, P(
            thigh_L=(-thigh * s, 0, 0), thigh_R=(thigh * s, 0, 0),
            shin_L=(shin * (0.25 + lift_l), 0, 0), shin_R=(shin * (0.25 + lift_r), 0, 0),
            foot_L=(-shin * 0.3 * lift_l, 0, 0), foot_R=(-shin * 0.3 * lift_r, 0, 0),
            upperarm_L=(arm * s, -5, 0), upperarm_R=(-arm * rh * s, 5, 0),
            spine1=(lean, 0, 4 * s), chest=(lean * 0.5, 0, -6 * s), head=(-lean * 0.8, 0, 2 * s),
            hips_loc=(0, 0, -bob * abs(math.sin(ph * 2 * math.pi + math.pi / 2)))))
        keys.append((ph * dur, p))
    return dict(dur=dur, loop=True, keys=keys, impact=None)


def walk():
    return _gait(1.1, 24, 30, 16, 3, 0.03)


def run():
    d = _gait(0.66, 40, 60, 32, 12, 0.07, rh=0.5)
    for _, p in d["keys"]:
        p["forearm.L"] = (-60, 0, 0)
    return d


def dash():
    a = mix(ARMS_REST)
    b = mix(P(spine1=(22, 0, 0), chest=(10, 0, 0), head=(-20, 0, 0), thigh_L=(-45, 0, 0), shin_L=(60, 0, 0),
              thigh_R=(35, 0, 0), shin_R=(30, 0, 0), upperarm_L=(40, -10, 0), upperarm_R=(30, 20, 0),
              forearm_L=(-50, 0, 0), hips_loc=(0, 0, -0.1)))
    return dict(dur=0.45, loop=False, keys=[(0, a), (0.08, b), (0.32, b), (0.45, a)], impact=0.08)


def _swing(dur, wind, strike, follow, t_imp):
    rest = mix(ARMS_REST)
    return dict(dur=dur, loop=False,
                keys=[(0, rest), (t_imp * 0.55, wind), (t_imp, strike), (t_imp + 0.12, follow), (dur, rest)],
                impact=t_imp)


def attack_1():   # horizontal right-to-left sweep
    wind = P(spine1=(0, 0, -25), chest=(0, 0, -20), upperarm_R=(-40, 55, -30), forearm_R=(-40, 0, 0),
             upperarm_L=(-20, -10, 0), hips_loc=(0, 0, -0.03))
    strike = P(spine1=(8, 0, 25), chest=(4, 0, 25), upperarm_R=(-85, 10, 40), forearm_R=(-10, 0, 0),
               upperarm_L=(20, -20, 0), thigh_R=(-15, 0, 0), shin_R=(15, 0, 0), hips_loc=(0, 0, -0.06))
    follow = P(spine1=(8, 0, 32), chest=(4, 0, 30), upperarm_R=(-70, -10, 55), forearm_R=(-15, 0, 0),
               hips_loc=(0, 0, -0.05))
    return _swing(0.62, wind, strike, follow, 0.28)


def attack_2():   # overhead slam
    wind = P(spine1=(-12, 0, 0), chest=(-8, 0, 0), upperarm_R=(-165, 10, 0), forearm_R=(-30, 0, 0),
             upperarm_L=(-150, -10, 0), forearm_L=(-40, 0, 0), head=(-10, 0, 0))
    strike = P(spine1=(28, 0, 0), chest=(14, 0, 0), upperarm_R=(-55, 5, 0), forearm_R=(-5, 0, 0),
               upperarm_L=(-50, -5, 0), forearm_L=(-10, 0, 0), thigh_L=(-30, 0, 0), shin_L=(35, 0, 0),
               thigh_R=(-10, 0, 0), shin_R=(25, 0, 0), head=(10, 0, 0), hips_loc=(0, 0, -0.14))
    follow = mix(strike, P(spine1=(32, 0, 0)))
    return _swing(0.75, wind, strike, follow, 0.36)


def attack_3():   # spinning two-handed finisher
    wind = P(spine1=(0, 0, -45), chest=(0, 0, -30), upperarm_R=(-60, 40, -40), upperarm_L=(-70, -10, -40),
             forearm_L=(-60, 0, 0), forearm_R=(-30, 0, 0), hips_loc=(0, 0, -0.08))
    strike = P(spine1=(10, 0, 50), chest=(5, 0, 40), upperarm_R=(-90, 0, 50), upperarm_L=(-90, 20, 50),
               forearm_L=(-30, 0, 0), thigh_R=(-25, 0, 0), shin_R=(25, 0, 0), hips_loc=(0, 0, -0.12))
    follow = mix(strike, P(spine1=(10, 0, 65), chest=(5, 0, 50)))
    return _swing(0.95, wind, strike, follow, 0.46)


def reaching_strike():   # Morrow's haft telescopes forward
    wind = P(spine1=(-5, 0, -20), upperarm_R=(-30, 20, -20), forearm_R=(-70, 0, 0), weapon_len=1.0)
    strike = P(spine1=(18, 0, 15), chest=(8, 0, 10), upperarm_R=(-92, 0, 10), forearm_R=(0, 0, 0), weapon_len=2.3,
               thigh_R=(-35, 0, 0), shin_R=(30, 0, 0), thigh_L=(20, 0, 0), hips_loc=(0, 0, -0.1))
    follow = mix(strike, P(weapon_len=2.3))
    d = _swing(0.95, wind, strike, follow, 0.42)
    d["keys"][-1][1]["weapon_len"] = 1.0
    d["keys"][0][1]["weapon_len"] = 1.0
    return d


def gravity_pull():
    rest = mix(ARMS_REST)
    reach = P(upperarm_L=(-95, -15, 10), forearm_L=(-5, 0, 0), hand_L=(30, 0, 0), spine1=(6, 0, 10),
              head=(-5, 0, 0))
    pull = P(upperarm_L=(-45, -30, 0), forearm_L=(-100, 0, 0), hand_L=(-20, 0, 0), spine1=(-10, 0, -15),
             chest=(-6, 0, -10), thigh_L=(15, 0, 0), hips_loc=(0, 0, -0.05))
    return dict(dur=1.05, loop=False, keys=[(0, rest), (0.3, reach), (0.42, reach), (0.55, pull), (1.05, rest)],
                impact=0.55)


def beetle_rage():
    rest = mix(ARMS_REST)
    crouch = P(spine1=(25, 0, 0), chest=(15, 0, 0), head=(10, 0, 0), upperarm_L=(-20, -20, 0),
               upperarm_R=(-20, 20, 0), forearm_L=(-90, 0, 0), forearm_R=(-90, 0, 0),
               thigh_L=(-35, 0, 0), thigh_R=(-35, 0, 0), shin_L=(60, 0, 0), shin_R=(60, 0, 0), foot_L=(-25, 0, 0),
               foot_R=(-25, 0, 0), hips_loc=(0, 0, -0.18))
    roar = P(spine1=(-14, 0, 0), chest=(-10, 0, 0), head=(-30, 0, 0), jaw=(30, 0, 0), neck1=(-8, 0, 0),
             upperarm_L=(-30, -70, 0), upperarm_R=(-30, 70, 0), forearm_L=(-50, 0, 0), forearm_R=(-50, 0, 0),
             hips_loc=(0, 0, 0.02))
    return dict(dur=1.5, loop=False, keys=[(0, rest), (0.35, crouch), (0.6, roar), (1.15, roar), (1.5, rest)],
                impact=0.6)


def hit():
    rest = mix(ARMS_REST)
    h = P(spine1=(-14, 0, 6), chest=(-8, 0, 0), head=(-18, 0, 8), upperarm_L=(10, -25, 0), upperarm_R=(10, 25, 0),
          hips_loc=(0, 0.08, -0.03))
    return dict(dur=0.42, loop=False, keys=[(0, rest), (0.07, h), (0.42, rest)], impact=0.07)


DOWN = P(hips_loc=(0, 0.05, -0.52), thigh_L=(-85, -5, 0), thigh_R=(-80, 5, 0), shin_L=(150, 0, 0),
         shin_R=(145, 0, 0), foot_L=(-40, 0, 0), foot_R=(-40, 0, 0), spine1=(35, 0, 0), chest=(20, 0, 0),
         neck1=(15, 0, 0), head=(30, 0, 5), upperarm_L=(5, -8, 0), upperarm_R=(-25, 10, 0), forearm_L=(-10, 0, 0),
         forearm_R=(-40, 0, 0))


def downed():
    rest = mix(ARMS_REST)
    mid = P(hips_loc=(0, 0.04, -0.25), thigh_L=(-40, 0, 0), thigh_R=(-30, 0, 0), shin_L=(80, 0, 0),
            shin_R=(60, 0, 0), spine1=(20, 0, 0), head=(15, 0, 0))
    return dict(dur=1.0, loop=False, keys=[(0, rest), (0.35, mid), (0.75, DOWN), (1.0, DOWN)], impact=0.75)


def revive():
    rest = mix(ARMS_REST)
    push = P(hips_loc=(0, 0.02, -0.3), thigh_L=(-60, 0, 0), thigh_R=(-30, 0, 0), shin_L=(90, 0, 0),
             shin_R=(70, 0, 0), spine1=(25, 0, 0), head=(-5, 0, 0), upperarm_L=(-30, -10, 0), forearm_L=(-30, 0, 0))
    return dict(dur=1.2, loop=False, keys=[(0, DOWN), (0.55, push), (1.0, rest), (1.2, rest)], impact=1.0)


def burden_hold():
    a = P(upperarm_L=(-60, -12, 15), upperarm_R=(-60, 12, -15), forearm_L=(-65, 0, 0), forearm_R=(-65, 0, 0),
          spine1=(-6, 0, 0), chest=(-4, 0, 0), head=(6, 0, 0), thigh_L=(-8, 0, 0), thigh_R=(-8, 0, 0),
          shin_L=(14, 0, 0), shin_R=(14, 0, 0), hips_loc=(0, 0, -0.04))
    b = mix(a, P(spine1=(-8, 0, 0), hips_loc=(0, 0, -0.055)))
    return dict(dur=2.0, loop=True, keys=[(0, a), (1.0, b), (2.0, a)], impact=None)


def talk_idle():
    a = mix(ARMS_REST, P(head=(0, 0, 0), jaw=(0, 0, 0)))
    b = mix(ARMS_REST, P(upperarm_L=(-35, -15, 10), forearm_L=(-60, 0, 0), hand_L=(-15, 0, 0), head=(6, 0, -6),
                         jaw=(12, 0, 0)))
    c = mix(ARMS_REST, P(upperarm_L=(-25, -20, 0), forearm_L=(-50, 0, 0), head=(-3, 0, 4), jaw=(4, 0, 0)))
    return dict(dur=3.0, loop=True, keys=[(0, a), (0.8, b), (1.6, c), (2.3, b), (3.0, a)], impact=None)


CLIPS = ["idle", "walk", "run", "dash", "attack_1", "attack_2", "attack_3", "reaching_strike", "gravity_pull",
         "beetle_rage", "hit", "downed", "revive", "burden_hold", "talk_idle"]


# ------------------------------------------------------------------------------------------- baking
def _local_quat(rest_q, rx, ry, rz):
    w = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), "ZYX").to_quaternion()
    return rest_q.inverted() @ w @ rest_q


def build_all(rig):
    pb = rig.pose.bones
    rest = {b.name: b.bone.matrix_local.to_quaternion() for b in pb}
    for b in pb:
        b.rotation_mode = "QUATERNION"
    rig.animation_data_create()
    out = {}
    allb = {"hips_loc", "weapon_len"}
    for name in CLIPS:
        for _, p in globals()[name]()["keys"]:
            allb |= set(p)
    for name in CLIPS:
        clip = globals()[name]()
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        bones = allb   # key every animated channel in every clip (no leftovers when switching clips)
        for t, p in clip["keys"]:
            f = 1 + round(t * FPS)
            for bn in sorted(bones):
                if bn == "hips_loc":
                    v = Vector(p.get(bn, (0, 0, 0)))
                    pb["hips"].location = rest["hips"].inverted() @ v
                    pb["hips"].keyframe_insert("location", frame=f)
                elif bn == "weapon_len":
                    s = p.get(bn, 1.0)
                    pb["weapon"].scale = (1, s, 1)
                    pb["weapon"].keyframe_insert("scale", frame=f)
                else:
                    r = p.get(bn, (0, 0, 0))
                    pb[bn].rotation_quaternion = _local_quat(rest[bn], *r)
                    pb[bn].keyframe_insert("rotation_quaternion", frame=f)
        out[name] = {"duration": clip["dur"], "loop": clip["loop"], "impact": clip["impact"]}
        for b in pb:
            b.rotation_quaternion = (1, 0, 0, 0)
            b.location = (0, 0, 0)
            b.scale = (1, 1, 1)
    rig.animation_data.action = None
    return out
