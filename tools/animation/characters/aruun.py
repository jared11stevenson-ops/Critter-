"""Aruun (2.4 m, long neck, hunched, heavy; Morrow = spiked mace on the right hand, haft telescopes).

Every clip = CMU mocap segment (tools/animation/SOURCES.md) retargeted onto the 36-bone rig, then Aruun's
style layer (weight, hunch, wide arms clearing the pauldrons), foot-lock IK, Morrow momentum, and hand polish.
Pose offsets use the anims.py convention: (rx, ry, rz) degrees about armature axes; rx > 0 tips an upward bone
forward / swings a hanging limb back; ry > 0 tilts toward his left (+X); rz > 0 turns the front toward his left.
"""
import numpy as np

import lib
import retarget as rt
from retarget import FPS

CLIPS = ["idle", "walk", "run"]

# global style: arms out to clear the bulky torso, a bit more hunch, heavy head carriage
STYLE = {
    "upperarm.L": (0, -9, 0), "upperarm.R": (0, 9, 0),
    "forearm.L": (-6, 0, 0), "forearm.R": (-8, 0, 0),
    "chest": (4, 0, 0), "neck1": (3, 0, 0), "head": (-7, 0, 0),
}


# Morrow carried, not dragged: right elbow bent, haft angled forward/outward so the head clears the ground
CARRY = {"upperarm.R": (-6, 6, 0), "forearm.R": (-22, 0, 0)}
HAFT_CARRY = (-0.35, -0.42, -0.84)     # character frame: his right, forward, down


def carry(tr, d=HAFT_CARRY, w=1.0):
    rt.aim(tr, "weapon", d, w, axis_bone="weapon_ext1")


def _finish_loop(tr, contacts_from=None):
    v = lib.make_inplace(tr)
    for s in ("L", "R"):
        rt.foot_lock(tr, s, inplace_v=v, cyclic=True)
    return v


def walk(sk):
    a, b = 1.7667, 2.9
    src = lib.source("35_01", a, b, timescale=1.12)    # slightly slower cadence: bigger body
    src.straighten(face=0)
    src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {"stride": 1.0})
    lib.layer(tr, STYLE)
    lib.hold_local(tr, ["upperarm.R", "forearm.R", "hand.R"], 0.45)   # heavy weapon arm swings less
    lib.layer(tr, CARRY)
    carry(tr)
    lib.layer(tr, {"spine1": (5, 0, 0)})
    lib.shift(tr, (0, 0, -0.04))          # sink the hips: knees stay soft under the weight
    v = _finish_loop(tr)
    rt.pendulum(tr, "weapon", stiffness=55, damping=7, cyclic=True, max_deg=25)
    lib.loop_blend(tr, 3)
    speed = float(np.linalg.norm(v)) * FPS
    return tr, {"duration": (tr.F - 1) / FPS, "loop": True, "impact": None, "speed": round(speed, 3)}


def run(sk):
    a, b = 0.6, 1.3667
    src = lib.source("35_17", a, b, timescale=1.0)
    src.straighten(face=0)
    src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {"stride": 1.0})
    lib.layer(tr, STYLE)
    lib.hold_local(tr, ["upperarm.R", "forearm.R", "hand.R"], 0.35)
    lib.layer(tr, CARRY)
    carry(tr)
    lib.layer(tr, {"spine1": (10, 0, 0), "chest": (4, 0, 0), "head": (-10, 0, 0)})
    lib.shift(tr, (0, 0, -0.05))
    v = _finish_loop(tr)
    rt.pendulum(tr, "weapon", stiffness=45, damping=6, cyclic=True, max_deg=35)
    lib.loop_blend(tr, 3)
    speed = float(np.linalg.norm(v)) * FPS
    return tr, {"duration": (tr.F - 1) / FPS, "loop": True, "impact": None, "speed": round(speed, 3)}


def idle(sk):
    src = lib.source("137_41", 4.0, 7.0)
    src.straighten(face=0)
    src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {})
    lib.layer(tr, STYLE)
    lib.layer(tr, CARRY)
    carry(tr)
    lib.remove_root_xy(tr, keep=0.3)
    for s in ("L", "R"):
        rt.foot_lock(tr, s, cyclic=True)
    rt.pendulum(tr, "weapon", stiffness=40, damping=6, cyclic=True, max_deg=10)
    lib.loop_blend(tr, 8)
    return tr, {"duration": (tr.F - 1) / FPS, "loop": True, "impact": None}


def build(name, sk):
    return globals()[name](sk)
