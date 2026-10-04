"""Generic NPC clip set (hub / world characters built by tools/modeling/npcs).

Every clip = a CMU mocap segment (tools/animation/SOURCES.md) retargeted onto the NPC's humanoid rig (same bone
names as the hero rigs), then a per-character style layer (npc.STYLE, set by the build driver: posture, arm
carriage), foot-lock, and pendulum lag on every extra bone listed in npc.SECONDARY (cloaks, wings, shells,
antennae). Clips: idle, walk, talk_idle, gesture, wave, react (+ hit alias), nod.
"""
import numpy as np

import lib
import retarget as rt
from retarget import FPS

CLIPS = ["idle", "walk", "talk_idle", "gesture", "wave", "react", "hit"]
COMBAT_CLIPS = ["jog", "run", "attack_1", "attack_2", "attack_3", "downed", "revive", "hit_left", "hit_right", "hit_back"]

STYLE = {}
SECONDARY = []       # [(bone, stiffness, damping, max_deg)]
LEG_SCALE = 1.0
TALK_WINDOW = (1.7, 3.6667)
_cache = {}


def meta(tr, loop=False, impact=None, **kw):
    d = {"duration": round((tr.F - 1) / FPS, 4), "loop": loop, "impact": None if impact is None else round(impact, 3)}
    d.update(kw)
    return d


def has(tr, b):
    return b in tr.sk.index


def base(sk, clip, t0=None, t1=None, warp=None, timescale=1.0, face=0.0, loop=False):
    src = lib.source(clip, t0, t1, timescale=timescale, warp=warp)
    src.straighten(face=face)
    if loop:
        src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {})
    if STYLE:
        lib.layer(tr, STYLE)
    return tr


def plant(tr, cyclic=False, v=None):
    for s in ("L", "R"):
        rt.foot_lock(tr, s, inplace_v=v, cyclic=cyclic)


def secondary(tr, cyclic=False):
    for b, st, dm, mx in SECONDARY:
        if has(tr, b):
            rt.pendulum(tr, b, stiffness=st, damping=dm, cyclic=cyclic, max_deg=mx)


def _speed(v):
    return round(float(np.linalg.norm(v)) * FPS, 3)


def idle(sk):
    tr = base(sk, "137_41", 7.2333, 10.2333, loop=True)
    t = lib.timeline(tr.F)
    T = (tr.F - 1) / FPS
    br = np.sin(t / T * 2 * np.pi * 3)
    z = np.zeros_like(br)
    lib.layer(tr, {"chest": np.stack([-1.2 * br, z, z], 1)})
    lib.remove_root_xy(tr, keep=0.3)
    plant(tr, cyclic=True)
    secondary(tr, True)
    lib.loop_blend(tr, 8)
    return tr, meta(tr, True)


def walk(sk):
    tr = base(sk, "35_01", 1.7667, 2.9, timescale=1.0, loop=True)
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    secondary(tr, True)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=_speed(v))


def talk_idle(sk):
    tr = base(sk, "138_11", TALK_WINDOW[0], TALK_WINDOW[1], loop=True)
    lib.remove_root_xy(tr, keep=0.0)
    plant(tr, cyclic=True)
    secondary(tr, True)
    lib.loop_blend(tr, 10)
    return tr, meta(tr, True)


def gesture(sk):
    """Open-armed explaining gesture (138_11 spread), settles back to idle posture."""
    tr = base(sk, "138_11", 0.25, 1.65)
    lib.remove_root_xy(tr, keep=0.0)
    plant(tr)
    secondary(tr)
    return tr, meta(tr, False, impact=0.6)


def wave(sk):
    """Greeting: right hand raised and waved (IK over the idle body)."""
    tr = base(sk, "137_41", 7.2333, 8.9)
    lib.remove_root_xy(tr, keep=0.0)
    T = (tr.F - 1) / FPS
    Y = rt.facing_frame(tr)
    sk_ = tr.sk
    hi = sk_.index["hips"]
    t = lib.timeline(tr.F)
    sway = np.sin(t * 2 * np.pi * 2.6) * 0.07
    up = lib.curve(tr.F, [(0, (0.0, 0.0, 0.0)), (0.3, (1.0, 0.0, 0.0)), (T - 0.35, (1.0, 0.0, 0.0)), (T, (0.0, 0.0, 0.0))])[:, 0]
    key = np.c_[-0.24 - 0.0 * up, -0.1 - 0.0 * up, 0.9 + 0.55 * up] + np.c_[sway * up, 0 * up, 0 * up]
    key = key * (sk_.tail_rest('head')[2] / 1.57)
    hip = tr.P[:, hi].copy()
    tgt = np.einsum("fij,fj->fi", Y, np.c_[key[:, 0], key[:, 1], np.zeros(tr.F)]) + np.c_[hip[:, :2], key[:, 2]]
    wr = tr.P[:, sk_.index["hand.R"]]
    w = up[:, None]
    tgt = wr * (1 - w) + tgt * w
    pole = np.einsum("fij,j->fi", Y, np.array([-0.7, 0.4, -0.5]))
    rt.two_bone_ik(tr, "upperarm.R", "forearm.R", "hand.R", tgt, pole_dir=pole)
    plant(tr)
    secondary(tr)
    return tr, meta(tr, False, impact=0.5)


def _react(sk, dur=0.5, peak=0.07):
    tr = base(sk, "137_41", 7.3, 7.3 + dur)
    lib.remove_root_xy(tr, keep=0.0)

    def keys(v):
        v = np.array(v)
        return [(0, (0, 0, 0)), (peak, tuple(v)), (peak + 0.12, tuple(v * 0.5)), (dur, (0, 0, 0))]
    lib.layer(tr, {"spine1": keys((-12, 0, 4)), "chest": keys((-8, 0, 0)), "head": keys((-18, 0, 8)),
                   "upperarm.L": keys((14, -18, 0)), "upperarm.R": keys((14, 18, 0))})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (peak, (0, 0.06, -0.03)), (dur, (0, 0, 0))]))
    plant(tr)
    secondary(tr)
    return tr, meta(tr, False, impact=peak)


def react(sk):
    return _react(sk)


def hit(sk):
    return _react(sk, 0.42, 0.06)


# ------------------------------------------------------------------------------------------- combat set (rivals)
def _blend_idle(tr, sk, k):
    if "idle" not in _cache:
        _cache["idle"] = idle(sk)[0]
    Qi, li = _cache["idle"].local_quats()
    Q, locs = tr.local_quats()
    for i in range(Q.shape[1]):
        rt.blend_local(Q, i, Qi[0, i], k)
    for b, L in list(locs.items()) + [(b, np.zeros((tr.F, 3))) for b in li if b not in locs]:
        tgt = li.get(b, np.zeros((1, 3)))[0]
        locs[b] = L * (1 - k[:, None]) + tgt[None] * k[:, None]
    rt.from_local(tr, Q, locs)


def settle(tr, sk, t_from):
    t = np.arange(tr.F) / FPS
    T = (tr.F - 1) / FPS
    _blend_idle(tr, sk, lib.smoothstep(np.clip((t - t_from) / max(T - t_from, 1e-3), 0, 1)))


def from_idle(tr, sk, t_to):
    t = np.arange(tr.F) / FPS
    _blend_idle(tr, sk, lib.smoothstep(1 - np.clip(t / max(t_to, 1e-3), 0, 1)))


def _gait(sk, clip, t0, t1, lean):
    tr = base(sk, clip, t0, t1, loop=True)
    lib.layer(tr, lean)
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    secondary(tr, True)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=_speed(v))


def jog(sk):
    return _gait(sk, "35_17", 0.6, 1.3667, {"spine1": (8, 0, 0), "head": (-8, 0, 0)})


def run(sk):
    return _gait(sk, "09_01", 0.4, 1.1333, {"spine1": (12, 0, 0), "chest": (4, 0, 0), "head": (-12, 0, 0)})


def _swing(sk, clip, warp, face, impact_t, cancel):
    tr = base(sk, clip, warp=warp, face=face)
    lib.remove_root_xy(tr, keep=0.2)
    from_idle(tr, sk, 0.1)
    settle(tr, sk, impact_t + 0.25)
    plant(tr)
    secondary(tr)
    return tr, meta(tr, False, impact=impact_t, cancel=cancel)


def attack_1(sk):
    return _swing(sk, "124_07", [(0.0, 2.30), (0.16, 2.72), (0.22, 2.86), (0.27, 2.98), (0.38, 3.10), (0.55, 3.25), (0.85, 3.50)], -70, 0.27, 0.4)


def attack_2(sk):
    return _swing(sk, "79_01", [(0.0, 0.55), (0.12, 0.80), (0.18, 0.90), (0.26, 1.03), (0.40, 1.20), (0.75, 1.55)], 0, 0.28, 0.4)


def attack_3(sk):
    return _swing(sk, "79_01", [(0.0, 2.30), (0.18, 2.62), (0.30, 2.70), (0.38, 2.80), (0.44, 2.86), (0.62, 3.00), (1.0, 3.35)], 0, 0.42, 0.55)


def downed(sk):
    tr = base(sk, "139_16", warp=[(0.0, 3.7), (0.15, 3.45), (0.45, 2.75), (0.7, 2.25), (0.85, 1.95), (1.1, 1.8)])
    lib.remove_root_xy(tr, keep=0.0)
    from_idle(tr, sk, 0.1)
    lib.ground_body(tr)
    plant(tr)
    return tr, meta(tr, False, impact=0.85)


def revive(sk):
    tr = base(sk, "139_16", warp=[(0.0, 1.8), (0.3, 2.1), (0.6, 2.6), (0.9, 3.3), (1.2, 3.8), (1.4, 4.1)])
    lib.remove_root_xy(tr, keep=0.0)
    lib.ground_body(tr)
    settle(tr, sk, 1.0)
    plant(tr)
    return tr, meta(tr, False, impact=1.2)


def hit_left(sk):
    return _react_dir(sk, {"spine1": (-4, -14, -12), "head": (0, -16, -12), "upperarm.L": (0, -30, 0)}, (-0.07, 0, -0.03))


def hit_right(sk):
    return _react_dir(sk, {"spine1": (-4, 14, 12), "head": (0, 16, 12), "upperarm.R": (0, 30, 0)}, (0.07, 0, -0.03))


def hit_back(sk):
    return _react_dir(sk, {"spine1": (16, 0, 0), "chest": (8, 0, 0), "head": (14, 0, 0)}, (0, -0.07, -0.04))


def _react_dir(sk, rec, hips, dur=0.42, peak=0.06):
    tr = base(sk, "137_41", 7.3, 7.3 + dur)
    lib.remove_root_xy(tr, keep=0.0)
    lib.layer(tr, {b: [(0, (0, 0, 0)), (peak, tuple(v)), (peak + 0.1, tuple(np.array(v) * 0.5)), (dur, (0, 0, 0))] for b, v in rec.items()})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (peak, tuple(hips)), (dur, (0, 0, 0))]))
    plant(tr)
    secondary(tr)
    return tr, meta(tr, False, impact=peak)


def build(name, sk):
    if name == "idle":
        _cache.clear()
    return globals()[name](sk)
