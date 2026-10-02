#!/usr/bin/env python3
"""CRITTER original score (procedural synthesis, Lead-composed). Writes game/audio/music/*.ogg (seamless loops).
Run: python3 tools/audio/make_music.py [track ...]"""
import os, sys
import numpy as np
import soundfile as sf
sys.path.insert(0, os.path.dirname(__file__))
from synth_lib import *  # noqa

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio", "music")
os.makedirs(OUT, exist_ok=True)


def m(name):
    """note name -> midi"""
    if name[1:2] in ("#", "b"):
        p, o = name[:2], int(name[2:])
    else:
        p, o = name[:1], int(name[1:])
    return 12 * (o + 1) + NOTE[p]


def f(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def chord(*names):
    return [m(n) for n in names]


def write_ogg(path, data, block=8192):
    """Chunked Vorbis write (libsndfile 1.2 segfaults on large single writes)."""
    with sf.SoundFile(path, "w", SR, data.shape[1], format="OGG", subtype="VORBIS") as fh:
        for i in range(0, len(data), block):
            fh.write(data[i:i + block].astype(np.float32))


class Track:
    def __init__(self, bpm, bars, beats_per_bar=4):
        self.bpm, self.bars, self.bpb = bpm, bars, beats_per_bar
        self.beat = 60.0 / bpm
        self.length = bars * beats_per_bar * self.beat
        self.buf = np.zeros((int(self.length * SR), 2))
        self.dry = np.zeros_like(self.buf)  # non-reverbed bus (drums/bass)

    def t(self, bar, beat=0.0):
        return (bar * self.bpb + beat) * self.beat

    def add(self, x, bar, beat, gain=1.0, p=0.0, dry=False):
        place(self.dry if dry else self.buf, x, self.t(bar, beat), gain, p)

    def render(self, name, rev_s=2.0, wet=0.32, peak=0.85):
        wetbus = reverb(self.buf, seconds=rev_s, wet=wet, wrap=True)
        drybus = reverb(self.dry, seconds=0.6, wet=0.12, wrap=True)
        mix = wetbus + drybus
        mix = soft_limit(normalize(mix, 0.97), 1.3)
        mix = normalize(mix, peak)
        path = os.path.join(OUT, name + ".ogg")
        write_ogg(path, mix)
        print(f"{name:16s} {self.length:5.1f}s  {os.path.getsize(path)/1024:6.0f} KB")


def melody(tr, notes, inst, gain=1.0, p=0.0, start_bar=0, **kw):
    """notes: list of (note_name or None, beats). Sequential from start_bar."""
    pos = 0.0
    for nm, beats in notes:
        if nm:
            dur = beats * tr.beat
            x = inst(f(m(nm)), max(dur * 1.05, 0.12), **kw)
            tr.add(x, start_bar, pos, gain, p)
        pos += beats


# =====================================================================  TITLE
def title():
    tr = Track(bpm=72, bars=16)
    prog = [chord("D3", "A3", "C4", "E4", "F4"), chord("Bb2", "F3", "A3", "D4"),
            chord("F2", "C3", "A3", "C4", "E4"), chord("E2", "C3", "G3", "E4")]
    for bar in range(16):
        ch = prog[bar % 4]
        for i, n in enumerate(ch):
            tr.add(pad(f(n), tr.t(1) * 1.04, attack=0.9, release=1.2, bright=0.45), bar, 0, 0.55, p=(-0.4 + 0.8 * i / len(ch)))
        tr.add(bass(f(ch[0] - 12 if ch[0] > 40 else ch[0]), tr.t(1)), bar, 0, 0.35, dry=True)
        # harp arpeggio (from bar 2)
        if bar >= 2:
            tones = sorted(set([n + 12 for n in ch] + [ch[1] + 24, ch[2] + 24]))
            pat = [0, 2, 4, 2, 3, 5, 3, 1]
            for k, ix in enumerate(pat):
                n = tones[ix % len(tones)]
                tr.add(pluck(f(n), 1.6, bright=0.9, decay=2.5), bar, k * 0.5, 0.42 if k % 2 == 0 else 0.3, p=0.35 * np.sin(k))
        if bar % 2 == 0 and bar >= 4:
            tr.add(frame_drum(0.6, 120), bar, 0, 0.35, dry=True)
            tr.add(frame_drum(0.4, 150), bar, 2.5, 0.18, dry=True)
    mel = [("A4", 1), ("C5", .5), ("D5", 1.5), ("E5", 1), ("F5", 2), ("E5", 1), ("D5", 1),
           ("C5", 1.5), ("A4", .5), ("G4", 1), ("A4", 1), ("A4", 4),
           ("D5", 1), ("E5", .5), ("F5", 1.5), ("G5", 1), ("A5", 2), ("G5", 1), ("F5", 1),
           ("E5", 1), ("D5", 1), ("C5", 1), ("E5", 1), ("D5", 4)]
    melody(tr, mel, flute, 0.5, -0.1, start_bar=4)
    for bar, nm in [(12, "A5"), (13, "F5"), (14, "C6"), (15, "E5")]:
        tr.add(bell(f(m(nm)), 3.0, 1.2), bar, 0, 0.3, p=0.4)
        tr.add(bell(f(m(nm) - 5), 3.0, 1.2), bar, 2, 0.2, p=-0.4)
    tr.render("title", rev_s=2.8, wet=0.38)


# =====================================================================  HUB
def hub():
    tr = Track(bpm=96, bars=16)
    prog = [chord("F3", "A3", "C4", "E4"), chord("G3", "B3", "D4", "F4"),
            chord("A3", "C4", "E4", "G4"), chord("Bb3", "D4", "F4", "A4")]
    roots = ["F2", "G2", "A2", "Bb2"]
    for bar in range(16):
        ch = prog[bar % 4]
        for i, n in enumerate(ch):
            tr.add(pad(f(n), tr.t(1) * 1.02, attack=0.3, release=0.6, bright=0.5), bar, 0, 0.32, p=(-0.5 + i / 3))
        r = m(roots[bar % 4])
        for b, n in [(0, r), (1.5, r + 7), (2, r + 12), (3, r + 7)]:
            tr.add(pluck(f(n), 0.5, bright=0.6, decay=7), bar, b, 0.55, dry=True)
        # marimba ostinato
        pat = [0, 2, 1, 3, 2, 1, 3, 2]
        for k, ix in enumerate(pat):
            n = ch[ix % 4] + 12
            tr.add(pluck(f(n), 0.5, bright=1.6, decay=9), bar, k * 0.5, 0.33, p=0.3 if k % 2 else -0.3)
        # hand percussion
        for b in (0, 2.5):
            tr.add(frame_drum(0.35, 170), bar, b, 0.45, dry=True)
        for b in (1, 3):
            tr.add(frame_drum(0.25, 260), bar, b, 0.3, p=0.3, dry=True)
        for k in range(8):
            tr.add(shaker(), bar, k * 0.5 + 0.25, 0.5 if k % 2 else 0.3, p=0.5, dry=True)
    mel = [("C5", 1), ("A4", .5), ("C5", .5), ("D5", 1), ("E5", 1), ("D5", 1.5), ("B4", .5), ("G4", 2),
           ("E5", 1), ("C5", .5), ("E5", .5), ("G5", 1.5), ("F5", .5), ("D5", 2), ("F5", 1), ("E5", 1)]
    melody(tr, mel, bell, 0.42, 0.15, start_bar=4, decay=2.0)
    mel2 = [("A5", 1.5), ("G5", .5), ("E5", 1), ("C5", 1), ("B4", 1.5), ("C5", .5), ("D5", 2),
            ("C5", 1), ("D5", .5), ("E5", .5), ("G5", 2), ("F5", 4)]
    melody(tr, mel2, flute, 0.42, -0.15, start_bar=8)
    tr.render("hub", rev_s=1.6, wet=0.25)


# =====================================================================  EXPLORE (Red Reaches)
def explore_reaches():
    tr = Track(bpm=84, bars=20)
    D = m("D2")
    # drone: D + A, slowly breathing
    for bar in range(0, 20, 2):
        tr.add(pad(f(D), tr.t(2) * 1.03, attack=1.5, release=1.5, bright=0.35), bar, 0, 0.5, -0.2)
        tr.add(pad(f(D + 7), tr.t(2) * 1.03, attack=1.5, release=1.5, bright=0.35), bar, 0, 0.35, 0.2)
        tr.add(pad(f(D + 12), tr.t(2) * 1.03, attack=1.8, release=1.5, bright=0.3), bar, 0, 0.18, 0.0)
    # wind swells
    n = int(tr.t(4) * SR)
    for bar in range(0, 20, 4):
        w = sweep_filter(noise(n, "pink"), 300, 1400, "band", 0.4) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.25
        tr.add(w, bar, 0, 0.6, p=0.6 if (bar // 4) % 2 else -0.6)
    # percussion: slow taiko + frame drum
    for bar in range(20):
        tr.add(taiko(1.2, 95, 55), bar, 0, 0.55, dry=True)
        if bar >= 2:
            tr.add(frame_drum(0.4, 170), bar, 1.5, 0.35, dry=True)
            tr.add(frame_drum(0.4, 210), bar, 2.75, 0.22, p=0.3, dry=True)
            tr.add(frame_drum(0.4, 170), bar, 3.0, 0.3, dry=True)
            tr.add(shaker(0.12), bar, 3.5, 0.3, p=-0.4, dry=True)
    # oud phrases (phrygian dominant: D Eb F# G A Bb C)
    oud = lambda fr, d, **k: pluck(fr, d + 0.6, bright=1.25, decay=4.5)
    ph1 = [("D4", .5), ("Eb4", .5), ("F#4", 1), ("G4", .5), ("F#4", .5), ("Eb4", 1),
           ("D4", 2), (None, 2),
           ("A4", .5), ("Bb4", .5), ("A4", .5), ("G4", .5), ("F#4", 1), ("G4", 1),
           ("A4", 3), (None, 1)]
    ph2 = [("D5", .5), ("C5", .5), ("Bb4", .5), ("A4", .5), ("G4", 1), ("F#4", 1),
           ("G4", .5), ("A4", .5), ("Bb4", 1), ("A4", 2),
           ("F#4", .5), ("G4", .5), ("F#4", .5), ("Eb4", .5), ("D4", 2),
           ("D4", 4)]
    melody(tr, ph1, oud, 0.55, -0.15, start_bar=4)
    melody(tr, ph2, oud, 0.55, 0.15, start_bar=8)
    melody(tr, ph1, oud, 0.5, -0.1, start_bar=12)
    call = [("A5", 2), ("Bb5", .5), ("A5", .5), ("F#5", 3), (None, 2), ("D6", 1.5), ("C6", .5), ("A5", 4)]
    melody(tr, call, flute, 0.38, 0.3, start_bar=16)
    tr.render("explore_reaches", rev_s=3.0, wet=0.4)


# =====================================================================  COMBAT
def combat():
    tr = Track(bpm=132, bars=16)
    prog = [("D2", chord("D4", "F4", "A4")), ("Bb1", chord("D4", "F4", "Bb4")),
            ("C2", chord("C4", "E4", "G4")), ("A1", chord("C#4", "E4", "A4"))]
    riff = [0, 0, 12, 0, 3, 0, 7, 10]
    for bar in range(16):
        r, ch = prog[bar % 4]
        rm = m(r)
        for k, iv in enumerate(riff):
            tr.add(bass(f(rm + iv), tr.beat * 0.48, drive=2.2), bar, k * 0.5, 0.6, dry=True)
        for k in range(16):
            if k % 4 != 3:
                for n in ch:
                    tr.add(strings_stac(f(n), 0.12), bar, k * 0.25, 0.22 if k % 2 == 0 else 0.13, p=0.25)
        tr.add(taiko(0.8, 105, 55), bar, 0, 0.8, dry=True)
        tr.add(taiko(0.6, 125, 70), bar, 1.5, 0.45, dry=True)
        tr.add(kick(0.4), bar, 2.0, 0.6, dry=True)
        tr.add(taiko(0.6, 115, 60), bar, 2.75, 0.5, dry=True)
        tr.add(snare(), bar, 1.0, 0.45, dry=True)
        tr.add(snare(), bar, 3.0, 0.5, dry=True)
        for k in range(8):
            tr.add(shaker(), bar, k * 0.5 + 0.25, 0.35, p=-0.4, dry=True)
        if bar % 4 == 0:
            for n in ch:
                tr.add(brass(f(n - 12), tr.beat * 1.5), bar, 0, 0.35, p=-0.2)
        if bar >= 8:
            hook = [("A4", .75), ("D5", .75), ("F5", .5), ("E5", 1), ("D5", 1)]
            melody(tr, hook, brass, 0.42, -0.1, start_bar=bar) if bar % 2 == 0 else None
    tr.render("combat", rev_s=1.4, wet=0.22, peak=0.9)


# =====================================================================  BOSS
def boss():
    tr = Track(bpm=144, bars=24)
    riff = [("D2", .5), ("D2", .5), ("Eb2", .5), ("D2", .5), ("F2", .5), ("D2", .5), ("Eb2", .5), ("C2", .5)]
    stab_prog = [chord("D4", "F4", "A4"), chord("Eb4", "G4", "Bb4"), chord("D4", "F4", "A4"), chord("C4", "Eb4", "G4")]
    for bar in range(24):
        pos = 0
        for nm, b in riff:
            tr.add(bass(f(m(nm)), tr.beat * b * 0.9, drive=3.0), bar, pos, 0.62, dry=True)
            pos += b
        for b in range(4):
            tr.add(kick(0.35, 140, 40), bar, b, 0.7, dry=True)
        tr.add(snare(), bar, 1, 0.5, dry=True)
        tr.add(snare(), bar, 3, 0.55, dry=True)
        tr.add(metal_hit(0.5, 330), bar, 0.5, 0.25, p=0.5, dry=True)
        tr.add(metal_hit(0.5, 280), bar, 2.5, 0.22, p=-0.5, dry=True)
        if bar % 2 == 1:
            tr.add(taiko(1.0, 95, 50), bar, 3.5, 0.7, dry=True)
        ch = stab_prog[bar % 4]
        for k in range(16):
            for n in ch:
                tr.add(strings_stac(f(n + 12), 0.1), bar, k * 0.25, 0.12, p=0.3)
        if bar % 2 == 0:
            for n in ch:
                tr.add(brass(f(n - 12), tr.beat * 0.9), bar, 0, 0.32)
    theme = [("D5", 1.5), ("Eb5", .5), ("D5", 1), ("A4", 1), ("Bb4", 1.5), ("A4", .5), ("G4", 1), ("F4", 1),
             ("D5", 1.5), ("F5", .5), ("Eb5", 1), ("D5", 1), ("C5", 2), ("D5", 2)]
    melody(tr, theme, brass, 0.48, -0.1, start_bar=8)
    melody(tr, theme, brass, 0.5, 0.1, start_bar=16)
    tr.render("boss", rev_s=1.6, wet=0.22, peak=0.9)


# =====================================================================  ENDING
def ending():
    tr = Track(bpm=66, bars=12)
    prog = [chord("D3", "F#3", "A3", "E4"), chord("B2", "F#3", "A3", "D4"),
            chord("G2", "D3", "B3", "F#4"), chord("A2", "E3", "A3", "C#4")]
    for bar in range(12):
        ch = prog[bar % 4]
        for i, n in enumerate(ch):
            tr.add(pad(f(n), tr.t(1) * 1.05, attack=1.0, release=1.4, bright=0.4), bar, 0, 0.45, p=(-0.4 + 0.8 * i / 3))
        tones = sorted([n + 12 for n in ch])
        for k, ix in enumerate([0, 1, 2, 3, 2, 1]):
            tr.add(pluck(f(tones[ix]), 2.2, bright=0.7, decay=1.6), bar, k * (4 / 6), 0.3, p=0.3 * np.cos(k))
    mel = [("F#5", 2), ("E5", 1), ("D5", 1), ("D5", 2), ("C#5", 1), ("B4", 1), ("B4", 2), ("A4", 1), ("B4", 1), ("A4", 4),
           ("A5", 2), ("F#5", 1), ("E5", 1), ("D5", 2), ("E5", 1), ("F#5", 1), ("G5", 2), ("F#5", 1), ("E5", 1), ("D5", 4)]
    melody(tr, mel, flute, 0.45, 0, start_bar=2)
    for bar in (10, 11):
        tr.add(bell(f(m("D6")), 3.5, 1.0), bar, 0, 0.25, 0.4)
    tr.render("ending", rev_s=3.2, wet=0.42)


TRACKS = {"title": title, "hub": hub, "explore_reaches": explore_reaches, "combat": combat, "boss": boss, "ending": ending}
if __name__ == "__main__":
    for name in (sys.argv[1:] or TRACKS):
        TRACKS[name]()
