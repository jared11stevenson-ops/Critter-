#!/usr/bin/env python3
"""Procedural music loops (numpy, no samples, no licences): audio/music/menu.wav (calm pad + pluck, A minor) and bout.wav (driving pulse, A minor).
22.05 kHz mono 16-bit; both loop seamlessly (the echo tail wraps). Usage: python3 v2/tools/gen/gen_music.py"""
import numpy as np, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "audio", "music")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

def hz(m): return 440.0 * 2 ** ((m - 69) / 12.0)
def tt(d): return np.arange(int(d * SR)) / SR
def adsr(n, a, r, curve=1.0):
    e = np.ones(n); na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na) ** curve; e[-nr:] *= np.linspace(1, 0, nr)
    return e
def saw(f, t, harm=8):
    return sum(np.sin(2 * np.pi * f * h * t) / h for h in range(1, harm + 1)) * 0.6
def pad(m, d):
    t = tt(d)
    v = sum(saw(hz(m) * (1 + dt), t, 6) for dt in (-0.004, 0.0, 0.004)) / 3
    return v * adsr(len(t), min(1.2, d * 0.4), min(1.5, d * 0.5), 1.5)
def pluck(m, d=0.6):
    t = tt(d); return (np.sin(2 * np.pi * hz(m) * t) + 0.3 * np.sin(2 * np.pi * hz(m) * 2 * t)) * np.exp(-t * 7.0)
def bass(m, d):
    t = tt(d); v = np.sin(2 * np.pi * hz(m) * t) + 0.35 * np.sin(2 * np.pi * hz(m) * 2 * t) + 0.12 * np.sin(2 * np.pi * hz(m) * 3 * t)
    return v * adsr(len(t), 0.01, min(0.12, d * 0.5))
def kick():
    t = tt(0.22); f = 45 + 90 * np.exp(-t * 28); ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 14)
def hat():
    t = tt(0.06); n = rng.standard_normal(len(t)); n = np.diff(n, prepend=0); return n * np.exp(-t * 70) * 0.5
def snare():
    t = tt(0.18); n = rng.standard_normal(len(t)); return (n * 0.6 + np.sin(2 * np.pi * 190 * t)) * np.exp(-t * 24) * 0.5
def stab(ms, d=0.28):
    t = tt(d); v = sum(saw(hz(m), t, 5) for m in ms) / len(ms); return v * np.exp(-t * 9)
def put(buf, x, start):
    i = int(start * SR); n = min(len(x), len(buf) - i)
    if n > 0: buf[i:i + n] += x[:n]
def echo(buf, delay, fb, mix):
    out = buf.copy(); d = int(delay * SR); cur = buf
    for _ in range(4):
        cur = np.roll(cur, d) * fb; out += cur * mix
    return out
def finish(buf, name, peak=0.8):
    buf = buf - np.mean(buf); buf = buf / (np.max(np.abs(buf)) + 1e-9) * peak
    w = wave.open(os.path.join(OUT, name), "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((buf * 32767).astype(np.int16).tobytes()); w.close()

CH = {"Am": (45, (57, 60, 64)), "F": (41, (53, 57, 60)), "C": (48, (60, 64, 67)), "G": (43, (55, 59, 62))}
# ---- menu: 70 bpm, 8 bars
bpm = 70; beat = 60.0 / bpm; bar = 4 * beat; bars = 8
buf = np.zeros(int(bars * bar * SR) + 1)
for b, name in enumerate(["Am", "F", "C", "G"] * 2):
    root, tri = CH[name]
    for m in tri: put(buf, pad(m, bar * 1.05) * 0.45, b * bar)
    put(buf, bass(root, bar * 0.95) * 0.5, b * bar)
    arp = [tri[0], tri[2], tri[1] + 12, tri[2], tri[0] + 12, tri[2], tri[1], tri[2] + 12]
    for k, m in enumerate(arp): put(buf, pluck(m + 12, 0.7) * 0.22, b * bar + k * beat / 2)
buf = buf[:int(bars * bar * SR)]
finish(echo(buf, beat * 0.75, 0.45, 0.5), "menu.wav", 0.7)
# ---- bout: 128 bpm, 16 bars
bpm = 128; beat = 60.0 / bpm; bar = 4 * beat; bars = 16
buf = np.zeros(int(bars * bar * SR) + 1)
prog = ["Am", "Am", "F", "G"] * 4
motif = [69, 72, 76, 72, 67, 69, 64, 67]
for b, name in enumerate(prog):
    root, tri = CH[name]; t0 = b * bar
    for k in range(4):
        put(buf, kick() * 0.9, t0 + k * beat)
        put(buf, hat() * 0.6, t0 + k * beat + beat / 2)
        if k in (1, 3): put(buf, snare() * 0.7, t0 + k * beat)
    for k in range(8):
        put(buf, bass(root + (12 if k % 4 == 3 else 0), beat * 0.45) * 0.55, t0 + k * beat / 2)
    for k in (0, 2.5, 3.5): put(buf, stab(tri) * 0.35, t0 + k * beat)
    if b >= 8 and b % 2 == 0:
        for k, m in enumerate(motif): put(buf, pluck(m, 0.5) * 0.3, t0 + k * beat / 2)
buf = buf[:int(bars * bar * SR)]
finish(echo(buf, beat * 0.75, 0.35, 0.25), "bout.wav", 0.85)
print("music written to", os.path.abspath(OUT))
