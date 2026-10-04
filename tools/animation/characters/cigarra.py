"""Cigarra (1.65 m, light and quick, Brazilian-treehopper crown, translucent wing cloak, no weapon).

Every clip = CMU mocap segment (tools/animation/SOURCES.md) retargeted onto the humanoid rig, then Cigarra's style
layer (light, head-led, curious tilt), foot-lock IK, wing-cloak secondary motion, and keyed hand/IK passes for the
psychic abilities. Works on the stand-in rig (tools/animation/standin.py) and on any later Cigarra model that uses
the same bone names (wings: wing.L/.R hanging from the chest; crown: child of head).
Pose offsets: (rx, ry, rz) deg about armature axes; rx > 0 tips an upward bone forward / swings a hanging limb back;
ry > 0 tilts toward her left (+X); rz > 0 turns the front toward her left. Forward is (0, -1, 0).
"""
import numpy as np

import lib
import retarget as rt
from retarget import FPS

CLIPS = ["idle", "walk", "run", "dash", "attack_1", "premonition", "false_memory", "brain_skip", "leap",
         "hit", "hit_back", "hit_left", "hit_right", "hit_heavy", "downed", "revive", "overwhelmed", "talk_idle"]

# light, curious carriage: head slightly forward and tilted, shoulders dropped, chest open
STYLE = {"chest": (-3, 0, 0), "neck1": (4, 0, 0), "head": (14, 3, 0), "clavicle.L": (0, 0, -4),
         "clavicle.R": (0, 0, 4)}
WINGS_FOLDED = {"wing.L": (6, -4, 0), "wing.R": (6, 4, 0)}

_cache = {}


def meta(tr, loop=False, impact=None, **kw):
    d = {"duration": round((tr.F - 1) / FPS, 4), "loop": loop, "impact": None if impact is None else round(impact, 3)}
    d.update(kw)
    return d


def has(tr, b):
    return b in tr.sk.index


def wings(tr, keys_l, keys_r=None):
    """Layer wing-cloak poses; keys_r defaults to the mirror of keys_l (ry, rz negated)."""
    if not has(tr, "wing.L"):
        return
    if keys_r is None:
        if isinstance(keys_l, tuple):
            keys_r = (keys_l[0], -keys_l[1], -keys_l[2])
        else:
            keys_r = [(t, (v[0], -v[1], -v[2])) for t, v in keys_l]
    lib.layer(tr, {"wing.L": keys_l, "wing.R": keys_r})


def flutter(tr, amp=6.0, hz=9.0, w=None):
    """Fast low-amplitude wing shiver (insect wings) under weight curve w."""
    if not has(tr, "wing.L"):
        return
    t = lib.timeline(tr.F)
    s = np.sin(t * 2 * np.pi * hz) * amp
    if w is not None:
        s = s * w
    z = np.zeros_like(s)
    lib.layer(tr, {"wing.L": np.stack([z, s, z], 1), "wing.R": np.stack([z, -s, z], 1)})


def wing_lag(tr, cyclic=False):
    if has(tr, "wing.L"):
        for b in ("wing.L", "wing.R"):
            rt.pendulum(tr, b, stiffness=60, damping=7, cyclic=cyclic, max_deg=18)


def base(sk, clip, t0=None, t1=None, warp=None, timescale=1.0, face=0.0, loop=False, style=True):
    src = lib.source(clip, t0, t1, timescale=timescale, warp=warp)
    src.straighten(face=face)
    if loop:
        src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {})
    if style:
        lib.layer(tr, STYLE)
        if has(tr, "wing.L"):
            lib.layer(tr, WINGS_FOLDED)
    return tr


def plant(tr, cyclic=False, v=None, floor=0.0):
    for s in ("L", "R"):
        rt.foot_lock(tr, s, inplace_v=v, cyclic=cyclic, floor=floor)


def curve1(tr, keys):
    return lib.curve(tr.F, [(t, (v,)) for t, v in keys])[:, 0]


def idle_pose(sk):
    if "idle" not in _cache:
        _cache["idle"] = idle(sk)[0]
    return _cache["idle"].local_quats()


def _blend_idle(tr, sk, k):
    Qi, li = idle_pose(sk)
    Q, locs = tr.local_quats()
    for i in range(Q.shape[1]):
        rt.blend_local(Q, i, Qi[0, i], k)
    for b, L in list(locs.items()) + [(b, np.zeros((tr.F, 3))) for b in li if b not in locs]:
        tgt = li.get(b, np.zeros((1, 3)))[0]
        locs[b] = L * (1 - k[:, None]) + tgt[None] * k[:, None]
    rt.from_local(tr, Q, locs)


def settle(tr, sk, t_from, t_to=None):
    t = np.arange(tr.F) / FPS
    t_to = (tr.F - 1) / FPS if t_to is None else t_to
    _blend_idle(tr, sk, lib.smoothstep(np.clip((t - t_from) / max(t_to - t_from, 1e-3), 0, 1)))


def from_idle(tr, sk, t_to):
    t = np.arange(tr.F) / FPS
    _blend_idle(tr, sk, lib.smoothstep(1 - np.clip(t / max(t_to, 1e-3), 0, 1)))


def hand_ik(tr, side, keys, w):
    """IK the wrist to character-frame targets keys [(t, (x, y, z))] (relative to the hips xy, absolute z)."""
    sk = tr.sk
    Y = rt.facing_frame(tr)
    loc = lib.curve(tr.F, keys)
    hip = tr.P[:, sk.index["hips"]].copy()
    tgt = np.einsum("fij,fj->fi", Y, np.c_[loc[:, :2], np.zeros(tr.F)]) + np.c_[hip[:, :2], loc[:, 2]]
    wr = tr.P[:, sk.index["hand." + side]]
    w = np.broadcast_to(np.asarray(w, dtype=np.float64), (tr.F,))
    tgt = wr * (1 - w[:, None]) + tgt * w[:, None]
    sx = 1 if side == "L" else -1
    pole = np.einsum("fij,j->fi", Y, np.array([0.7 * sx, 0.3, -0.6]))
    rt.two_bone_ik(tr, "upperarm." + side, "forearm." + side, "hand." + side, tgt, pole_dir=pole)


def _speed(v):
    return round(float(np.linalg.norm(v)) * FPS, 3)


# ------------------------------------------------------------------------------------------- locomotion
def idle(sk):
    """Light weight shifts (137_41, a later window than Aruun's), slow breathing, a curious head tilt cycle."""
    tr = base(sk, "137_41", 7.2333, 10.2333, loop=True)
    t = lib.timeline(tr.F)
    T = (tr.F - 1) / FPS
    br = np.sin(t / T * 2 * np.pi * 3)
    tilt = np.sin(t / T * 2 * np.pi)
    z = np.zeros_like(br)
    lib.layer(tr, {"chest": np.stack([-1.2 * br, z, z], 1), "head": np.stack([z, 6 * tilt, 3 * tilt], 1)})
    lib.remove_root_xy(tr, keep=0.3)
    plant(tr, cyclic=True)
    flutter(tr, amp=1.5, hz=1.0 / T * 6)
    wing_lag(tr, cyclic=True)
    lib.loop_blend(tr, 8)
    return tr, meta(tr, True)


def walk(sk):
    """Quick light walk (16_17), head held level, wings trailing with the step."""
    tr = base(sk, "16_17", 0.5333, 1.6667, loop=True)
    lib.layer(tr, {"spine1": (3, 0, 0), "head": (-3, 0, 0)})
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    wing_lag(tr, cyclic=True)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=_speed(v))


def run(sk):
    """Springy run (16_35), forward lean, wings swept back by the airflow."""
    tr = base(sk, "16_35", 0.4, 1.2, loop=True)
    lib.layer(tr, {"spine1": (8, 0, 0), "chest": (3, 0, 0), "head": (-9, 0, 0)})
    wings(tr, (18, -8, 0))
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    flutter(tr, amp=3.0, hz=10.0)
    wing_lag(tr, cyclic=True)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=_speed(v))


def talk_idle(sk):
    """Storytelling gestures (138_11), loops."""
    tr = base(sk, "138_11", 1.7, 3.6667, loop=True)
    lib.remove_root_xy(tr, keep=0.0)
    plant(tr, cyclic=True)
    wing_lag(tr, cyclic=True)
    lib.loop_blend(tr, 10)
    return tr, meta(tr, True)


# ------------------------------------------------------------------------------------------- combat
def dash(sk):
    """Hop-dash: crouch, low forward hop with wings flicked open, land on the balls of the feet (13_11 jump)."""
    warp = [(0.0, 1.55), (0.07, 1.80), (0.12, 1.92), (0.22, 2.20), (0.32, 2.45), (0.40, 2.62), (0.55, 3.0)]
    tr = base(sk, "13_11", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.0)
    # the gameplay moves her 5 m; keep the hop low (<= 0.25 m) so it reads as a skim, not a jump
    hi = tr.sk.index["hips"]
    hz = tr.P[:, hi, 2]
    top = sk.H0[hi, 2] + 0.25
    lib.shift(tr, np.stack([np.zeros(tr.F), np.zeros(tr.F), -np.clip(hz - top, 0, None) * 0.8], 1))
    lib.layer(tr, {"spine1": [(0, (0, 0, 0)), (0.07, (18, 0, 0)), (0.22, (10, 0, 0)), (0.4, (6, 0, 0)), (0.55, (0, 0, 0))]})
    wings(tr, [(0, (0, 0, 0)), (0.08, (30, 35, 0)), (0.3, (30, 40, 0)), (0.45, (0, 0, 0))])
    flutter(tr, amp=8.0, hz=14.0, w=curve1(tr, [(0, 0), (0.1, 1), (0.32, 1), (0.42, 0)]))
    from_idle(tr, sk, 0.05)
    settle(tr, sk, 0.4)
    wing_lag(tr)
    return tr, meta(tr, impact=0.07, cancel=0.36)


def attack_1(sk):
    """Bad Thought: a sharp head flick launches a crown sphere; the right hand flicks it on toward the target."""
    tr = base(sk, "137_41", 4.3, 4.3 + 0.55)
    lib.remove_root_xy(tr, keep=0.0)
    lib.layer(tr, {
        "neck1": [(0, (0, 0, 0)), (0.06, (-10, 0, 0)), (0.11, (14, 0, 0)), (0.2, (6, 0, 0)), (0.5, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (0.06, (-16, 0, -6)), (0.11, (22, 0, 6)), (0.22, (8, 0, 2)), (0.5, (0, 0, 0))],
        "spine1": [(0, (0, 0, 0)), (0.06, (-4, 0, 6)), (0.12, (6, 0, -8)), (0.5, (0, 0, 0))],
        "hand.R": [(0, (0, 0, 0)), (0.07, (0, 0, -30)), (0.12, (0, 0, 40)), (0.3, (0, 0, 0))],
    })
    hand_ik(tr, "R", [(0, (-0.22, -0.05, 0.85)), (0.07, (-0.18, -0.1, 1.35)), (0.12, (-0.12, -0.45, 1.3)),
                      (0.3, (-0.15, -0.3, 1.1)), (0.55, (-0.22, -0.05, 0.85))],
            curve1(tr, [(0, 0.0), (0.05, 1.0), (0.3, 1.0), (0.5, 0.0)]))
    if has(tr, "crown"):
        lib.layer(tr, {"crown": [(0, (0, 0, 0)), (0.06, (-14, 0, 0)), (0.11, (20, 0, 0)), (0.3, (0, 0, 0))]})
    wings(tr, [(0, (0, 0, 0)), (0.11, (-8, 10, 0)), (0.4, (0, 0, 0))])
    from_idle(tr, sk, 0.04)
    settle(tr, sk, 0.35)
    plant(tr)
    wing_lag(tr)
    return tr, meta(tr, impact=0.11, cancel=0.25)


def premonition(sk):
    """Fingertips to temples, head tips back as the futures flood in, wing cloak flares open and shivers."""
    tr = base(sk, "137_41", 5.0, 5.0 + 1.1)
    lib.remove_root_xy(tr, keep=0.0)
    for s, x in (("L", 0.13), ("R", -0.13)):
        hand_ik(tr, s, [(0, (x * 1.6, 0.0, 0.85)), (0.18, (x, -0.08, 1.45)), (0.7, (x, -0.06, 1.47)),
                        (1.1, (x * 1.6, 0.0, 0.85))], curve1(tr, [(0, 0.0), (0.14, 1.0), (0.75, 1.0), (1.05, 0.0)]))
    lib.layer(tr, {"head": [(0, (0, 0, 0)), (0.18, (8, 0, 0)), (0.3, (-22, 0, 0)), (0.7, (-18, 6, 0)), (1.1, (0, 0, 0))],
                   "chest": [(0, (0, 0, 0)), (0.3, (-8, 0, 0)), (0.7, (-6, 0, 0)), (1.1, (0, 0, 0))]})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (0.18, (0, 0, -0.04)), (0.3, (0, 0, 0.02)), (1.1, (0, 0, 0))]))
    wings(tr, [(0, (0, 0, 0)), (0.25, (20, 55, 0)), (0.8, (18, 50, 0)), (1.1, (0, 0, 0))])
    flutter(tr, amp=7.0, hz=12.0, w=curve1(tr, [(0, 0), (0.28, 1), (0.8, 1), (1.0, 0)]))
    settle(tr, sk, 0.85)
    plant(tr)
    return tr, meta(tr, impact=0.3, cancel=0.6)


def false_memory(sk):
    """Both arms sweep open to the side (138_11 'spread' gesture) - the echo peels away from her."""
    tr = base(sk, "138_11", 0.25, 1.35)
    lib.remove_root_xy(tr, keep=0.0)
    lib.layer(tr, {"spine1": [(0, (0, 0, 0)), (0.3, (-6, 0, 10)), (0.6, (-4, 0, 6)), (1.1, (0, 0, 0))],
                   "head": [(0, (0, 0, 0)), (0.3, (-6, 0, 18)), (0.7, (0, 0, 10)), (1.1, (0, 0, 0))]})
    wings(tr, [(0, (0, 0, 0)), (0.35, (10, 45, 0)), (0.7, (8, 30, 0)), (1.1, (0, 0, 0))])
    flutter(tr, amp=5.0, hz=11.0, w=curve1(tr, [(0, 0), (0.35, 1), (0.75, 0)]))
    from_idle(tr, sk, 0.08)
    settle(tr, sk, 0.8)
    plant(tr)
    wing_lag(tr)
    return tr, meta(tr, impact=0.35, cancel=0.6)


def brain_skip(sk):
    """Points two fingers at the target, a hard snap of the wrist - and her own head glitches sideways."""
    tr = base(sk, "137_41", 5.6, 5.6 + 0.85)
    lib.remove_root_xy(tr, keep=0.0)
    hand_ik(tr, "R", [(0, (-0.22, -0.05, 0.85)), (0.12, (-0.12, -0.55, 1.38)), (0.5, (-0.12, -0.52, 1.36)),
                      (0.85, (-0.22, -0.05, 0.85))], curve1(tr, [(0, 0.0), (0.1, 1.0), (0.5, 1.0), (0.8, 0.0)]))
    lib.layer(tr, {
        "hand.R": [(0, (0, 0, 0)), (0.15, (-20, 0, 0)), (0.19, (35, 0, 0)), (0.3, (10, 0, 0)), (0.6, (0, 0, 0))],
        "spine1": [(0, (0, 0, 0)), (0.12, (4, 0, 12)), (0.5, (3, 0, 10)), (0.85, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (0.18, (4, 0, 0)), (0.2, (0, 16, -10)), (0.23, (0, -6, 4)), (0.27, (2, 10, -6)),
                 (0.4, (2, 2, 0)), (0.85, (0, 0, 0))],
    })
    wings(tr, [(0, (0, 0, 0)), (0.2, (8, 20, 0)), (0.5, (0, 0, 0))])
    flutter(tr, amp=10.0, hz=16.0, w=curve1(tr, [(0.15, 0), (0.2, 1), (0.32, 0)]))
    from_idle(tr, sk, 0.06)
    settle(tr, sk, 0.6)
    plant(tr)
    return tr, meta(tr, impact=0.19, cancel=0.45)


def leap(sk):
    """Grasshopper Thought: deep crouch, explosive launch, legs tuck, wing cloak spread wide to glide, land soft.
    Gameplay flies her along a 1.15 s arc, so the clip removes the mocap's own vertical travel in the air."""
    warp = [(0.0, 0.40), (0.25, 0.85), (0.33, 0.97), (0.40, 1.05), (0.55, 1.18), (0.95, 1.30), (1.30, 1.42),
            (1.45, 1.52), (1.60, 1.62), (1.95, 1.95)]
    tr = base(sk, "16_01", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.0)
    hi = tr.sk.index["hips"]
    hz = tr.P[:, hi, 2]
    rest = sk.H0[hi, 2]
    lib.shift(tr, np.stack([np.zeros(tr.F), np.zeros(tr.F), -np.clip(hz - rest, 0, None)], 1))
    air = curve1(tr, [(0.0, 0), (0.38, 0), (0.5, 1), (1.4, 1), (1.5, 0)])
    lib.layer(tr, {"thigh.L": np.c_[-55 * air, 0 * air, 0 * air], "thigh.R": np.c_[-40 * air, 0 * air, 0 * air],
                   "shin.L": np.c_[70 * air, 0 * air, 0 * air], "shin.R": np.c_[55 * air, 0 * air, 0 * air],
                   "spine1": np.c_[12 * air, 0 * air, 0 * air], "head": np.c_[-14 * air, 0 * air, 0 * air],
                   "upperarm.L": np.c_[10 * air, -35 * air, 0 * air], "upperarm.R": np.c_[10 * air, 35 * air, 0 * air]})
    wings(tr, [(0, (0, 0, 0)), (0.35, (10, 10, 0)), (0.5, (45, 75, 0)), (1.35, (45, 75, 0)), (1.55, (10, 15, 0)),
               (1.95, (0, 0, 0))])
    flutter(tr, amp=4.0, hz=18.0, w=air)
    from_idle(tr, sk, 0.08)
    settle(tr, sk, 1.65)
    return tr, meta(tr, impact=1.45, cancel=1.6)


# ------------------------------------------------------------------------------------------- reactions
def _hit(sk, recoil, dur=0.42, peak=0.06, hips=(0, 0.07, -0.03), scale=1.0):
    tr = base(sk, "137_41", 7.3, 7.3 + dur)

    def keys(v):
        v = np.array(v) * scale
        return [(0, (0, 0, 0)), (peak, tuple(v)), (peak + 0.1, tuple(v * 0.5)), (dur, (0, 0, 0))]
    lib.layer(tr, {b: keys(v) for b, v in recoil.items()})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (peak, tuple(np.array(hips) * scale)), (dur, (0, 0, 0))]))
    wings(tr, [(0, (0, 0, 0)), (peak, (-15 * scale, 25 * scale, 0)), (dur, (0, 0, 0))])
    settle(tr, sk, dur * 0.6)
    plant(tr)
    wing_lag(tr)
    return tr, meta(tr, impact=peak)


def hit(sk):
    return _hit(sk, {"spine1": (-14, 0, 4), "chest": (-8, 0, 0), "head": (-20, 0, 8), "upperarm.L": (14, -18, 0),
                     "upperarm.R": (14, 18, 0)})


def hit_back(sk):
    return _hit(sk, {"spine1": (16, 0, 0), "chest": (8, 0, 0), "head": (14, 0, 0), "upperarm.L": (-18, -12, 0),
                     "upperarm.R": (-18, 12, 0)}, hips=(0, -0.07, -0.04))


def hit_left(sk):
    return _hit(sk, {"spine1": (-4, -14, -12), "chest": (0, -8, -6), "head": (0, -16, -12), "upperarm.L": (0, -30, 0)},
                hips=(-0.07, 0, -0.03))


def hit_right(sk):
    return _hit(sk, {"spine1": (-4, 14, 12), "chest": (0, 8, 6), "head": (0, 16, 12), "upperarm.R": (0, 30, 0)},
                hips=(0.07, 0, -0.03))


def hit_heavy(sk):
    return _hit(sk, {"spine1": (-22, 0, 8), "chest": (-10, 0, 0), "head": (-26, 0, 10), "upperarm.L": (20, -28, 0),
                     "upperarm.R": (16, 20, 0)}, dur=0.75, peak=0.1, hips=(0, 0.12, -0.14))


def revive(sk):
    """Sitting on the ground -> knees -> rises (get up 111_06), quick and light."""
    warp = [(0.0, 7.0), (0.4, 8.2), (0.8, 9.4), (1.1, 9.9), (1.35, 10.3), (1.5, 10.6)]
    tr = base(sk, "111_06", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.0)
    lib.ground_body(tr)
    settle(tr, sk, 1.2)
    plant(tr)
    wing_lag(tr)
    return tr, meta(tr, impact=1.2)


def downed(sk):
    """Legs give way, she folds down onto her side (111_06 get-up reversed, accelerated)."""
    warp = [(0.0, 10.4), (0.15, 10.1), (0.35, 9.7), (0.6, 8.6), (0.85, 7.0), (1.1, 6.2)]
    tr = base(sk, "111_06", warp=warp, face=0)
    lib.layer(tr, {"head": [(0, (0, 0, 0)), (0.12, (-16, 0, 8)), (0.6, (10, 0, 0)), (1.1, (12, 0, 0))]})
    lib.remove_root_xy(tr, keep=0.0)
    from_idle(tr, sk, 0.1)
    lib.ground_body(tr)
    wings(tr, [(0, (0, 0, 0)), (0.5, (-10, 20, 0)), (1.1, (-4, 30, 0))])
    plant(tr)
    return tr, meta(tr, impact=0.85)


def overwhelmed(sk):
    """Future-noise overload (loop): hunched, both hands clamped to her head, rocking, wings buzzing in spasms."""
    tr = base(sk, "137_41", 4.3, 6.3, loop=True)
    T = (tr.F - 1) / FPS
    t = lib.timeline(tr.F)
    rock = np.sin(t / T * 2 * np.pi * 2)
    z = np.zeros_like(rock)
    lib.layer(tr, {"spine1": np.c_[18 + 4 * rock, z, 5 * rock], "chest": np.c_[10 + z, z, z],
                   "head": np.c_[12 + 6 * rock, 8 * np.sin(t / T * 2 * np.pi * 3), z]})
    lib.shift(tr, (0, 0, -0.1))
    lib.remove_root_xy(tr, keep=0.0)
    for s, x in (("L", 0.11), ("R", -0.11)):
        hand_ik(tr, s, [(0, (x, -0.12, 1.33)), (T, (x, -0.12, 1.33))], 1.0)
    plant(tr, cyclic=True)
    spasm = np.clip(np.sin(t / T * 2 * np.pi * 4), 0, 1) ** 4
    flutter(tr, amp=12.0, hz=20.0, w=spasm)
    wings(tr, (12, 18, 0))
    lib.loop_blend(tr, 8)
    return tr, meta(tr, True)


def build(name, sk):
    if name == "idle":
        _cache.clear()
    return globals()[name](sk)
