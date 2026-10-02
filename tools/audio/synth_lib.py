"""Small vectorized synthesis toolkit for CRITTER's procedural audio (Lead-owned).
Everything is numpy; no samples from anywhere — all sounds are generated from math."""
import numpy as np
from scipy import signal

SR = 44100
rng = np.random.default_rng(7)


def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env_adsr(n, a=0.005, d=0.05, s=0.6, r=0.1, sr=SR):
    a_n, d_n, r_n = int(a * sr), int(d * sr), int(r * sr)
    s_n = max(0, n - a_n - d_n - r_n)
    e = np.concatenate([
        np.linspace(0, 1, max(a_n, 1), endpoint=False),
        np.linspace(1, s, max(d_n, 1), endpoint=False),
        np.full(s_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    if len(e) < n:
        e = np.pad(e, (0, n - len(e)))
    return e[:n]


def env_exp(n, decay, sr=SR):
    return np.exp(-np.arange(n) / sr * decay)


def noise(n, color="white"):
    w = rng.standard_normal(n)
    if color == "white":
        return w
    if color == "pink":
        b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
        return signal.lfilter(b, a, w) * 3.0
    if color == "brown":
        x = np.cumsum(w)
        x = x - signal.savgol_filter(x, 2001 if n > 2001 else (n // 2) * 2 - 1, 2) if n > 11 else x
        return x / (np.max(np.abs(x)) + 1e-9)
    return w


def _sos(kind, f, sr=SR, order=2):
    nyq = sr / 2
    if kind == "band":
        lo, hi = max(20, f[0]) / nyq, min(f[1], nyq * 0.95) / nyq
        return signal.butter(order, [lo, hi], btype="band", output="sos")
    return signal.butter(order, min(f, nyq * 0.95) / nyq, btype=kind, output="sos")


def lp(x, f, order=2):
    return signal.sosfilt(_sos("low", f, order=order), x)


def hp(x, f, order=2):
    return signal.sosfilt(_sos("high", f, order=order), x)


def bp(x, lo, hi, order=2):
    return signal.sosfilt(_sos("band", (lo, hi), order=order), x)


def sweep_filter(x, f0, f1, kind="band", q=0.35, steps=48):
    """Time-varying filter by block processing with crossfaded blocks."""
    n = len(x)
    out = np.zeros(n)
    edges = np.linspace(0, n, steps + 1).astype(int)
    for i in range(steps):
        a, b = edges[i], edges[i + 1]
        pad = min(2048, a)
        seg = x[a - pad:b]
        f = f0 * (f1 / f0) ** (i / max(1, steps - 1)) if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * i / steps
        if kind == "band":
            y = bp(seg, f * (1 - q), f * (1 + q))
        elif kind == "low":
            y = lp(seg, f)
        else:
            y = hp(seg, f)
        out[a:b] = y[pad:]
    return out


def osc_sine(freq, dur, phase=0.0):
    """freq can be scalar or array (len = samples) for sweeps."""
    n = int(dur * SR)
    f = np.full(n, freq) if np.isscalar(freq) else np.asarray(freq)[:n]
    ph = 2 * np.pi * np.cumsum(f) / SR + phase
    return np.sin(ph)


def sweep(f0, f1, dur, curve="exp"):
    n = int(dur * SR)
    if curve == "exp":
        return f0 * (f1 / f0) ** np.linspace(0, 1, n)
    return np.linspace(f0, f1, n)


def additive(freq, dur, harmonics=16, rolloff=1.0, decay0=0.0, decay_k=0.0, inharm=0.0, odd_only=False):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        if odd_only and k % 2 == 0:
            continue
        fk = freq * k * (1 + inharm * k * k)
        if fk > SR * 0.45:
            break
        amp = 1.0 / (k ** rolloff)
        out += amp * np.sin(2 * np.pi * fk * t) * np.exp(-t * (decay0 + decay_k * k))
    return out


def pluck(freq, dur=1.2, bright=1.0, decay=3.0):
    """Harp/oud/kalimba-like pluck: harmonics decay faster the higher they are."""
    y = additive(freq, dur, harmonics=14, rolloff=1.15 / bright, decay0=decay, decay_k=decay * 0.55, inharm=0.0004)
    n = len(y)
    att = np.minimum(1, np.arange(n) / (0.003 * SR))
    click = bp(noise(n), freq * 2, min(freq * 8, 16000)) * env_exp(n, 220) * 0.15
    return (y * att + click) * 0.5


def bell(freq, dur=2.0, decay=2.2):
    t = t_axis(dur)
    ratios = [(1, 1.0, 1.0), (2.0, 0.55, 1.4), (2.76, 0.4, 2.0), (4.07, 0.25, 2.8), (5.43, 0.18, 3.6), (6.8, 0.1, 4.6)]
    y = np.zeros_like(t)
    for r, a, dk in ratios:
        y += a * np.sin(2 * np.pi * freq * r * t) * np.exp(-t * decay * dk)
    return y * np.minimum(1, t / 0.002) * 0.4


def saw_band(freq, dur, harmonics=24, bright_env=None):
    t = t_axis(dur)
    y = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        if freq * k > SR * 0.45:
            break
        amp = 1.0 / k
        if bright_env is not None:
            amp = amp * np.exp(-k * bright_env)
        y += amp * np.sin(2 * np.pi * freq * k * t + k * 0.3)
    return y


def pad(freq, dur, detune=0.006, harmonics=12, attack=0.6, release=0.8, bright=0.6):
    n = int(dur * SR)
    y = np.zeros(n)
    for d in (-detune, 0, detune):
        y += saw_band(freq * (1 + d), dur, harmonics=harmonics, bright_env=np.full(n, 1.0 / max(bright, 0.05) * 0.18))
    e = env_adsr(n, attack, 0.2, 0.85, release)
    trem = 1 + 0.06 * np.sin(2 * np.pi * 0.23 * t_axis(dur))
    return y * e * trem * 0.18


def flute(freq, dur, vib=5.2, breath=0.12):
    n = int(dur * SR)
    t = t_axis(dur)
    vib_amt = np.clip((t - 0.18) / 0.3, 0, 1) * 0.011
    f = freq * (1 + vib_amt * np.sin(2 * np.pi * vib * t))
    y = osc_sine(f, dur) + 0.22 * osc_sine(f * 2, dur) + 0.08 * osc_sine(f * 3, dur)
    br = bp(noise(n), freq * 0.8, freq * 3.5) * breath
    e = env_adsr(n, 0.07, 0.1, 0.8, 0.18)
    return (y * 0.6 + br) * e * 0.5


def brass(freq, dur, attack=0.03):
    n = int(dur * SR)
    t = t_axis(dur)
    bright = 0.12 + 0.5 * (1 - np.exp(-t * 6))
    y = saw_band(freq, dur, harmonics=18, bright_env=bright)
    return np.tanh(y * 1.6) * env_adsr(n, attack, 0.08, 0.7, 0.12) * 0.35


def strings_stac(freq, dur=0.18):
    n = int(dur * SR)
    y = saw_band(freq, dur, harmonics=16, bright_env=np.full(n, 0.12))
    y += saw_band(freq * 1.004, dur, harmonics=16, bright_env=np.full(n, 0.12))
    return y * env_adsr(n, 0.008, 0.06, 0.4, 0.06) * 0.25


def bass(freq, dur, drive=1.4):
    n = int(dur * SR)
    y = osc_sine(freq, dur) + 0.35 * osc_sine(freq * 2, dur) + 0.12 * osc_sine(freq * 3, dur)
    return np.tanh(y * drive) * env_adsr(n, 0.01, 0.1, 0.75, 0.08) * 0.5


def kick(dur=0.45, f0=130, f1=42):
    n = int(dur * SR)
    y = osc_sine(sweep(f0, f1, dur), dur) * env_exp(n, 7.5)
    click = hp(noise(n), 2000) * env_exp(n, 300) * 0.25
    return np.tanh((y + click) * 1.6) * 0.9


def taiko(dur=0.9, f0=110, f1=58):
    n = int(dur * SR)
    body = osc_sine(sweep(f0, f1, dur), dur) * env_exp(n, 5.0)
    skin = lp(noise(n), 1200) * env_exp(n, 28) * 0.6
    return np.tanh((body + skin) * 1.3) * 0.9


def frame_drum(dur=0.35, f=190):
    n = int(dur * SR)
    body = osc_sine(sweep(f * 1.15, f, dur), dur) * env_exp(n, 14)
    slap = bp(noise(n), 600, 4000) * env_exp(n, 60) * 0.5
    return (body + slap) * 0.55


def snare(dur=0.3):
    n = int(dur * SR)
    tone = osc_sine(sweep(240, 180, dur), dur) * env_exp(n, 25)
    rattle = bp(noise(n), 1500, 9000) * env_exp(n, 18)
    return (tone * 0.5 + rattle * 0.7) * 0.6


def shaker(dur=0.09):
    n = int(dur * SR)
    return hp(noise(n), 5000) * env_adsr(n, 0.01, 0.03, 0.3, 0.04) * 0.25


def metal_hit(dur=1.0, base=310):
    t = t_axis(dur)
    y = np.zeros_like(t)
    for r, a, d in [(1, 1, 3), (2.31, 0.7, 4), (3.79, 0.6, 5), (5.12, 0.4, 6.5), (7.33, 0.3, 8)]:
        y += a * np.sin(2 * np.pi * base * r * t) * np.exp(-t * d)
    n = len(t)
    y += hp(noise(n), 3000) * env_exp(n, 40) * 0.4
    return y * 0.35


def reverb(x, seconds=1.6, wet=0.3, predelay=0.012, stereo=True, damp=5000, wrap=False):
    """Convolution reverb with a synthetic decaying-noise IR. Returns stereo (n,2).
    wrap=True folds the tail back to the start for seamless music loops."""
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    n_ir = int(seconds * SR)
    out = np.zeros((x.shape[0] + n_ir, 2))
    for ch in range(2):
        ir = noise(n_ir) * np.exp(-np.arange(n_ir) / SR * (6.9 / seconds))
        ir = lp(ir, damp)
        pd = int(predelay * SR)
        ir = np.concatenate([np.zeros(pd), ir])[:n_ir]
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
        wetsig = signal.fftconvolve(x[:, ch], ir)[: x.shape[0] + n_ir]
        out[: len(wetsig), ch] += wetsig * wet
        out[: x.shape[0], ch] += x[:, ch] * (1 - wet * 0.5)
    if wrap:
        body = out[: x.shape[0]].copy()
        tail = out[x.shape[0]:]
        body[: len(tail)] += tail[: len(body)]
        return body
    return out


def pan(x, p):
    """p in [-1,1] -> stereo (n,2) equal-power."""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], axis=1)


def place(buf, x, start_s, gain=1.0, p=0.0):
    """Mix mono or stereo x into stereo buf at time start_s (wraps around for loops)."""
    if x.ndim == 1:
        x = pan(x, p)
    s = int(start_s * SR)
    n = len(buf)
    end = s + len(x)
    if end <= n:
        buf[s:end] += x * gain
    else:
        k = n - s
        buf[s:] += x[:k] * gain
        rem = x[k:]
        buf[: len(rem)] += rem[: n] * gain


def normalize(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def soft_limit(x, drive=1.15):
    return np.tanh(x * drive) / np.tanh(drive)


def fade(x, fin=0.003, fout=0.02):
    n = len(x)
    a, b = int(fin * SR), int(fout * SR)
    e = np.ones(n)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if b > 0:
        e[-b:] = np.linspace(1, 0, b)
    return x * (e[:, None] if x.ndim == 2 else e)


NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
        "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def hz(name):
    """'D4' -> Hz."""
    if name[1:2] in ("#", "b"):
        p, o = name[:2], int(name[2:])
    else:
        p, o = name[:1], int(name[1:])
    midi = 12 * (o + 1) + NOTE[p]
    return 440.0 * 2 ** ((midi - 69) / 12)
