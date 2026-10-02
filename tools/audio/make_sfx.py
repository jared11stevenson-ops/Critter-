#!/usr/bin/env python3
"""Generates every SFX named in CONTRACTS §7 into game/audio/sfx/*.wav (44.1 kHz, 16-bit).
Run: python3 tools/audio/make_sfx.py"""
import os, sys
import numpy as np
import soundfile as sf
sys.path.insert(0, os.path.dirname(__file__))
from synth_lib import *  # noqa

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio", "sfx")
os.makedirs(OUT, exist_ok=True)
S = {}


def mono(dur):
    return np.zeros(int(dur * SR))


def save(name, x, peak=0.85, stereo=False, rev=None):
    if rev:
        x = reverb(x, **rev)
        x = x if stereo else x.mean(axis=1)
    x = normalize(x, peak)
    x = fade(x, 0.001, 0.015)
    sf.write(os.path.join(OUT, name + ".wav"), x.astype(np.float32), SR, subtype="PCM_16")
    S[name] = len(x) / SR


# ---------------- UI ----------------
def ui_tap():
    n = int(0.06 * SR)
    x = bp(noise(n), 1800, 4200) * env_exp(n, 160) * 0.6
    x += osc_sine(1250, 0.06) * env_exp(n, 90) * 0.5
    return x
save("ui_tap", ui_tap(), 0.6)

def ui_back():
    a = pluck(hz("A5"), 0.12, decay=14)
    b = pluck(hz("E5"), 0.2, decay=10)
    x = mono(0.3); x[: len(a)] += a; x[int(0.07 * SR): int(0.07 * SR) + len(b)] += b
    return x
save("ui_back", ui_back(), 0.6)

def ui_confirm():
    x = mono(0.55)
    for i, nme in enumerate(["D5", "A5", "D6"]):
        p = pluck(hz(nme), 0.45, decay=6)
        s = int(i * 0.055 * SR); x[s:s + len(p)] += p[: len(x) - s]
    return x
save("ui_confirm", ui_confirm(), 0.65, rev=dict(seconds=0.8, wet=0.2))

# ---------------- Melee ----------------
def whoosh(dur, f0, f1, q=0.5, amp_curve=2.0):
    n = int(dur * SR)
    x = sweep_filter(noise(n, "pink"), f0, f1, "band", q=q)
    e = np.sin(np.linspace(0, np.pi, n)) ** amp_curve
    return x * e
save("swing_light", whoosh(0.2, 700, 2600, 0.45), 0.7)
def swing_heavy():
    x = whoosh(0.38, 220, 1100, 0.5, 1.5)
    n = len(x)
    x += osc_sine(sweep(90, 60, 0.38), 0.38) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.35
    return x
save("swing_heavy", swing_heavy(), 0.8)

def hit_flesh():
    d = 0.22; n = int(d * SR)
    body = osc_sine(sweep(110, 48, d), d) * env_exp(n, 20)
    smack = lp(noise(n), 2500) * env_exp(n, 55) * 0.8
    crunch = bp(noise(n), 900, 3000) * env_exp(n, 90) * 0.4
    return np.tanh((body + smack + crunch) * 2.0)
save("hit_flesh", hit_flesh(), 0.9)

def hit_shell():
    d = 0.3; n = int(d * SR)
    crack = hp(noise(n), 2500) * env_exp(n, 120)
    res = bp(noise(n), 2600, 3400, order=4) * env_exp(n, 30) * 1.6 + bp(noise(n), 1500, 1900, order=4) * env_exp(n, 22) * 1.2
    thump = osc_sine(sweep(140, 70, d), d) * env_exp(n, 22) * 0.8
    return np.tanh((crack + res + thump) * 1.8)
save("hit_shell", hit_shell(), 0.9)

save("hit_metal", metal_hit(0.7, 420) + np.pad(hit_flesh() * 0.4, (0, int(0.7 * SR) - len(hit_flesh()))), 0.85)

def mace_extend():
    d = 0.5; n = int(d * SR)
    saw = saw_band(1, d, 1)  # placeholder shape
    tone = additive(1, d, 1)
    f = sweep(160, 720, d)
    x = osc_sine(f, d) * 0.5 + osc_sine(f * 1.5, d) * 0.25 + osc_sine(f * 2.01, d) * 0.2
    x *= env_adsr(n, 0.02, 0.1, 0.7, 0.2)
    chain = np.zeros(n)
    for i in range(14):
        s = int((0.02 + i * 0.028) * SR)
        c = bp(noise(int(0.02 * SR)), 3000, 8000) * env_exp(int(0.02 * SR), 200)
        chain[s:s + len(c)] += c[: n - s]
    return np.tanh(x * 1.2) + chain * 0.5 + whoosh(d, 400, 2000) * 0.4
save("mace_extend", mace_extend(), 0.85, rev=dict(seconds=0.6, wet=0.2))

def gravity_hum():
    d = 1.8; n = int(d * SR); t = t_axis(d)
    f = 50 * (1 + 0.3 * t / d)
    x = osc_sine(f, d) + 0.6 * osc_sine(f * 2.005, d) + 0.25 * osc_sine(f * 3.01, d)
    x *= (1 + 0.5 * np.sin(2 * np.pi * (6 + 10 * t / d) * t))
    x *= env_adsr(n, 0.35, 0.2, 0.9, 0.4)
    x += sweep_filter(noise(n, "pink"), 200, 1800, "band", 0.4) * env_adsr(n, 0.8, 0.1, 0.8, 0.3) * 0.5
    return np.tanh(x * 0.9)
save("gravity_hum", gravity_hum(), 0.85, rev=dict(seconds=1.2, wet=0.25))

def slam():
    d = 1.3; n = int(d * SR)
    sub = osc_sine(sweep(70, 30, d), d) * env_exp(n, 4.5)
    blast = lp(noise(n), 900) * env_exp(n, 9) * 1.2
    crack = hp(noise(n), 1500) * env_exp(n, 60) * 0.6
    debris = np.zeros(n)
    for i in range(30):
        s = int(rng.uniform(0.08, 0.9) * SR); ln = int(0.03 * SR)
        g = bp(noise(ln), 1500, 6000) * env_exp(ln, 120) * rng.uniform(0.05, 0.25)
        debris[s:s + ln] += g[: n - s]
    return np.tanh((sub * 1.4 + blast + crack + debris) * 1.4)
save("slam", slam(), 0.95, rev=dict(seconds=1.4, wet=0.22))

def rage_roar():
    d = 1.2; n = int(d * SR); t = t_axis(d)
    f = 105 * (1 + 0.15 * np.sin(np.pi * t / d)) * (1 + 0.02 * np.sin(2 * np.pi * 7 * t))
    src = saw_band(1, d, 1) * 0
    # build saw with time-varying freq via phase accumulation
    ph = 2 * np.pi * np.cumsum(f) / SR
    saw = sum(np.sin(k * ph) / k for k in range(1, 30))
    grit = noise(n) * 0.3
    y = bp(saw + grit, 500, 900) * 1.4 + bp(saw + grit, 1100, 1700) * 1.0 + lp(saw, 300) * 0.8
    y = np.tanh(y * 2.5) * env_adsr(n, 0.08, 0.2, 0.8, 0.35)
    return y
save("rage_roar", rage_roar(), 0.9, rev=dict(seconds=1.0, wet=0.25))

# ---------------- Psychic (Cigarra) ----------------
def psychic_bolt():
    d = 0.32; n = int(d * SR); t = t_axis(d)
    fc = sweep(1300, 380, d)
    mod = np.sin(2 * np.pi * np.cumsum(fc * 1.41) / SR) * (3 * np.exp(-t * 8))
    x = np.sin(2 * np.pi * np.cumsum(fc) / SR + mod) * env_exp(n, 9)
    x += bp(noise(n), 3000, 9000) * env_exp(n, 40) * 0.3
    return x
save("psychic_bolt", psychic_bolt(), 0.7, rev=dict(seconds=0.6, wet=0.25))

def psychic_hit():
    d = 0.5; n = int(d * SR)
    x = bell(hz("F#5"), d, 6) + bell(hz("C6"), d, 7) * 0.6
    x += bp(noise(n), 2000, 7000) * env_exp(n, 30) * 0.4
    return x
save("psychic_hit", psychic_hit(), 0.75, rev=dict(seconds=0.7, wet=0.3))

def premonition():
    d = 1.6
    chord = sum(bell(hz(nm), d, 1.4) for nm in ["D5", "A5", "E6", "F#6"])
    st = reverb(chord, seconds=1.4, wet=0.8).mean(axis=1)
    rev_part = st[::-1][-int(0.55 * SR):]  # swell that ends on the attack
    out = np.concatenate([rev_part * 0.7, chord[: int(0.9 * SR)]])
    return out
save("premonition", premonition(), 0.75, rev=dict(seconds=1.2, wet=0.25))

def false_memory():
    d = 1.0; n = int(d * SR); t = t_axis(d)
    x = np.zeros(n)
    for det in (-7, 0, 7):
        f = hz("A5") * 2 ** (det / 1200)
        x += bell(f, d, 2.5)
    x *= 1 + 0.5 * np.sin(2 * np.pi * 5 * t)
    x += whoosh(d, 3000, 500, 0.6) * 0.5
    return x
save("false_memory", false_memory(), 0.7, rev=dict(seconds=1.0, wet=0.35))

def brain_skip():
    d = 0.5; n = int(d * SR)
    base = osc_sine(sweep(900, 140, d), d) * 0.6 + bp(noise(n), 800, 5000) * 0.3
    out = np.zeros(n); blk = int(0.035 * SR)
    for i in range(0, n, blk):
        seg = base[i:i + blk]
        if (i // blk) % 3 == 1:
            seg = base[max(0, i - blk):max(0, i - blk) + len(seg)]  # stutter repeat
        if (i // blk) % 5 == 4:
            seg = seg * 0.1
        out[i:i + len(seg)] = seg
    return np.tanh(out * 2)
save("brain_skip", brain_skip(), 0.55)

def leap():
    d = 0.55; n = int(d * SR); t = t_axis(d)
    whistle = osc_sine(sweep(300, 1300, d), d) * env_adsr(n, 0.02, 0.1, 0.5, 0.25) * 0.4
    flutter = bp(noise(n), 400, 3000) * (0.5 + 0.5 * np.sin(2 * np.pi * 32 * t)) * env_adsr(n, 0.05, 0.1, 0.6, 0.2)
    return whistle + flutter * 0.6 + whoosh(d, 500, 2500) * 0.5
save("leap", leap(), 0.75)

def land():
    d = 0.35; n = int(d * SR)
    thud = osc_sine(sweep(120, 55, d), d) * env_exp(n, 16)
    dust = lp(noise(n, "pink"), 1800) * env_exp(n, 12) * 0.6
    return np.tanh((thud + dust) * 1.5)
save("land", land(), 0.75)

def footstep_dirt():
    d = 0.09; n = int(d * SR)
    return lp(bp(noise(n), 300, 4000), 3000) * env_exp(n, 55) + osc_sine(90, d) * env_exp(n, 60) * 0.3
save("footstep_dirt", footstep_dirt(), 0.4)

# ---------------- Handler tools ----------------
def scan():
    d = 1.4; n = int(d * SR); t = t_axis(d)
    ping = osc_sine(1480, d) * env_exp(n, 4.5) * 0.6 + osc_sine(2960, d) * env_exp(n, 7) * 0.15
    sw = osc_sine(sweep(400, 2400, 0.3), 0.3) * env_adsr(int(0.3 * SR), 0.01, 0.1, 0.4, 0.15) * 0.3
    ping[: len(sw)] += sw
    return ping
save("scan", scan(), 0.65, rev=dict(seconds=1.6, wet=0.4, predelay=0.08))

def codex():
    d = 1.0; n = int(d * SR)
    flip = np.zeros(n)
    for i in range(5):
        s = int(i * 0.025 * SR); ln = int(0.03 * SR)
        flip[s:s + ln] += bp(noise(ln), 1500, 7000) * env_exp(ln, 90) * 0.5
    ch = np.zeros(n)
    for i, nm in enumerate(["E5", "B5"]):
        b = bell(hz(nm), 0.8, 3); s = int((0.12 + i * 0.1) * SR)
        ch[s:s + len(b)] += b[: n - s]
    return flip + ch
save("codex", codex(), 0.7, rev=dict(seconds=1.0, wet=0.3))

def capture():
    d = 1.3; n = int(d * SR); t = t_axis(d)
    f = sweep(200, 900, 1.0)
    f = np.concatenate([f, np.full(n - len(f), 900)])
    x = np.sin(2 * np.pi * np.cumsum(f) / SR + 2 * np.sin(2 * np.pi * np.cumsum(f * 0.5) / SR)) * 0.4
    x *= env_adsr(n, 0.1, 0.1, 0.8, 0.25)
    lock = np.zeros(n); s = int(1.0 * SR)
    lk = metal_hit(0.3, 900)[: n - s]; lock[s:s + len(lk)] += lk
    b = bell(hz("A6"), 0.3, 6)[: n - s]; lock[s:s + len(b)] += b * 0.6
    return x + lock
save("capture", capture(), 0.8, rev=dict(seconds=0.9, wet=0.25))

def pickup():
    x = mono(0.5)
    for i, nm in enumerate(["A5", "C#6", "E6"]):
        b = bell(hz(nm), 0.4, 5); s = int(i * 0.05 * SR)
        x[s:s + len(b)] += b[: len(x) - s]
    return x
save("pickup", pickup(), 0.6, rev=dict(seconds=0.6, wet=0.25))

# ---------------- Dominion ----------------
def drone_hum():
    d = 1.0; t = t_axis(d)
    x = sum((0.5 / k) * np.sin(2 * np.pi * 180 * k * t) for k in range(1, 6))
    x += 0.3 * np.sin(2 * np.pi * 183 * t)
    x *= 1 + 0.15 * np.sin(2 * np.pi * 9 * t)
    return x  # loopable: integer cycles in 1 s
x = drone_hum(); x = normalize(x, 0.5)
sf.write(os.path.join(OUT, "drone_hum.wav"), x.astype(np.float32), SR, subtype="PCM_16"); S["drone_hum"] = 1.0

def drone_shot():
    d = 0.18; n = int(d * SR); t = t_axis(d)
    f = sweep(1400, 220, d)
    ph = 2 * np.pi * np.cumsum(f) / SR
    sq = np.sign(np.sin(ph)) * 0.4 + np.sin(ph) * 0.3
    return lp(sq, 6000) * env_exp(n, 14) + hp(noise(n), 4000) * env_exp(n, 60) * 0.2
save("drone_shot", drone_shot(), 0.7)

def drill():
    d = 1.5; n = int(d * SR); t = t_axis(d)
    motor = sum((0.6 / k) * np.sin(2 * np.pi * 70 * k * t) for k in range(1, 8))
    grind = bp(noise(n), 300, 2500) * (0.6 + 0.4 * np.sin(2 * np.pi * 26 * t))
    return np.tanh((motor + grind * 1.4) * 1.3)  # 70 Hz & 26 Hz: integer cycles in 1.5 s -> loopable
x = normalize(drill(), 0.7)
sf.write(os.path.join(OUT, "drill.wav"), x.astype(np.float32), SR, subtype="PCM_16"); S["drill"] = 1.5

def vent():
    d = 1.3; n = int(d * SR)
    hiss = hp(noise(n), 2500) * env_adsr(n, 0.02, 0.3, 0.6, 0.6)
    burst = lp(noise(n), 600) * env_exp(n, 8) * 0.5
    return hiss + burst
save("vent", vent(), 0.75, rev=dict(seconds=0.8, wet=0.2))

def explosion():
    d = 2.0; n = int(d * SR)
    sub = osc_sine(sweep(60, 25, d), d) * env_exp(n, 2.8)
    body = lp(noise(n, "brown"), 700) * env_exp(n, 3.0) * 1.5
    crack = hp(noise(n), 1200) * env_exp(n, 25)
    crackle = np.zeros(n)
    for i in range(80):
        s = int(rng.uniform(0.05, 1.6) * SR); ln = int(0.01 * SR)
        crackle[s:s + ln] += hp(noise(ln), 2000) * rng.uniform(0.05, 0.3)
    return np.tanh((sub * 1.5 + body + crack + crackle) * 1.6)
save("explosion", explosion(), 0.95, rev=dict(seconds=1.8, wet=0.25))

def boulder_break():
    d = 1.4; n = int(d * SR)
    crack = np.zeros(n)
    for i in range(6):
        s = int(i * 0.04 * SR); ln = int(0.06 * SR)
        crack[s:s + ln] += hp(noise(ln), 1200) * env_exp(ln, 60) * (1 - i * 0.12)
    rumble = lp(noise(n, "brown"), 300) * env_exp(n, 3.5) * 1.6
    debris = np.zeros(n)
    for i in range(40):
        s = int(rng.uniform(0.1, 1.2) * SR); ln = int(0.04 * SR)
        debris[s:s + ln] += bp(noise(ln), 800, 5000) * env_exp(ln, 80) * rng.uniform(0.05, 0.3)
    thud = osc_sine(sweep(90, 40, d), d) * env_exp(n, 5)
    return np.tanh((crack + rumble + debris + thud) * 1.5)
save("boulder_break", boulder_break(), 0.95, rev=dict(seconds=1.2, wet=0.2))

def rope_unroll():
    d = 1.1; n = int(d * SR)
    x = whoosh(d, 300, 1500, 0.6, 1.0) * 0.4
    tt = 0.0; gap = 0.09
    while tt < 0.95:
        s = int(tt * SR); ln = int(0.025 * SR)
        x[s:s + ln] += bp(noise(ln), 1500, 5000) * env_exp(ln, 120) * 0.6
        tt += gap; gap = max(0.022, gap * 0.88)
    thump = land() * 0.6; s = int(0.95 * SR)
    x[s:s + len(thump)] += thump[: n - s]
    return x
save("rope_unroll", rope_unroll(), 0.75)

def span_creak():
    d = 2.2; n = int(d * SR); t = t_axis(d)
    f = 140 + 40 * np.sin(2 * np.pi * 0.7 * t) + 20 * np.sin(2 * np.pi * 3.1 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    fric = sum(np.sin(k * ph) / k for k in range(1, 18)) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 9 * t)))
    groan = bp(fric, 200, 1200) * env_adsr(n, 0.3, 0.3, 0.8, 0.6)
    rumble = lp(noise(n, "brown"), 120) * 0.8 * env_adsr(n, 0.4, 0.2, 0.7, 0.6)
    return np.tanh((groan * 1.5 + rumble) * 1.2)
save("span_creak", span_creak(), 0.85, rev=dict(seconds=1.6, wet=0.3))

def gate_whoosh():
    d = 2.6; n = int(d * SR); t = t_axis(d)
    rise = sweep_filter(noise(n, "pink"), 150, 5000, "band", 0.5) * np.clip(t / 1.6, 0, 1) ** 2
    rise *= np.where(t < 1.7, 1, np.exp(-(t - 1.7) * 5))
    shimmer = sum(bell(hz(nm), d, 0.9) for nm in ["D4", "A4", "D5", "F#5"]) * np.clip((t - 1.5) / 0.1, 0, 1)
    sub = osc_sine(sweep(30, 80, d), d) * np.clip(t / 1.6, 0, 1) * np.where(t < 1.7, 1, np.exp(-(t - 1.7) * 4)) * 0.8
    return rise + shimmer * 0.5 + sub
save("gate_whoosh", gate_whoosh(), 0.9, rev=dict(seconds=2.2, wet=0.35))

def trust_up():
    x = mono(1.0)
    for i, nm in enumerate(["D5", "F#5", "A5", "D6"]):
        p = pluck(hz(nm), 0.9, decay=3); s = int(i * 0.07 * SR)
        x[s:s + len(p)] += p[: len(x) - s]
    return x
save("trust_up", trust_up(), 0.65, rev=dict(seconds=1.0, wet=0.3))

def trust_down():
    x = mono(1.0)
    for i, nm in enumerate(["A4", "F4"]):
        p = pluck(hz(nm), 0.9, decay=3); s = int(i * 0.16 * SR)
        x[s:s + len(p)] += p[: len(x) - s]
    return x
save("trust_down", trust_down(), 0.6, rev=dict(seconds=1.0, wet=0.3))

def noise_overload():
    d = 1.3; n = int(d * SR); t = t_axis(d)
    swell = sum(osc_sine(hz(nm) * (1 + 0.02 * np.sin(2 * np.pi * 11 * t)), d) for nm in ["D5", "D#5", "A5"])
    swell *= np.clip(t / 0.8, 0, 1) ** 2
    crackle = hp(noise(n), 3000) * (rng.random(n) > 0.995) * 3
    x = np.tanh((swell * 0.6 + crackle) * 3) * env_adsr(n, 0.05, 0.1, 0.9, 0.3)
    return brain_skip_tail(x)
def brain_skip_tail(x):
    return x
save("noise_overload", noise_overload(), 0.75, rev=dict(seconds=0.8, wet=0.2))

def downed():
    d = 1.1; n = int(d * SR)
    tone = osc_sine(sweep(320, 90, d), d) * env_adsr(n, 0.01, 0.2, 0.6, 0.5) * 0.5
    thump = land()
    x = tone.copy(); x[: len(thump)] += thump * 0.8
    return lp(x, 2500)
save("downed", downed(), 0.75, rev=dict(seconds=1.0, wet=0.3))

for k, v in sorted(S.items()):
    print(f"{k:16s} {v:5.2f}s")
print(len(S), "sfx")
