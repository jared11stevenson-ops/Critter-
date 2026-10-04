#!/usr/bin/env python3
"""Generates the painted-ink ability icon set (128px PNG, transparent bg) into game/art/icons/.
Aruun = burden/force (ember reds/oranges), Cigarra = foresight (olive/lime + ghost teal), shared = parchment/cyan.
Usage: python3 tools/art_pipeline/make_icons.py"""
import math, random, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 512
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "art", "icons")
INK = (30, 20, 18, 255)
random.seed(7)

def H(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16), a)

EMBER, EMBER2, EMBER_HI = H("#ff5a2a"), H("#ff9a30"), H("#ffe08a")
LIME, LIME2, LIME_HI = H("#c8e03a"), H("#8fb82a"), H("#f4ffb0")
GHOST, GHOST2 = H("#59e6d2"), H("#2aa8a0")
VIOLET, VIOLET2 = H("#a070ff"), H("#5a3aa8")
BONE = H("#f2e6c8")
CYAN, CYAN2 = H("#59d2e6"), H("#1f8fa8")

class Canvas:
    def __init__(self):
        self.im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
    def layer(self):
        return Image.new("RGBA", (S, S), (0, 0, 0, 0))

def finish(cv, name, outline=16):
    im = cv.im
    a = im.split()[3]
    # thick dark ink outline via dilation of alpha
    k = outline * 2 + 1
    ol = a.filter(ImageFilter.MaxFilter(k if k % 2 else k + 1))
    ol = ol.filter(ImageFilter.GaussianBlur(2))
    ink = Image.new("RGBA", (S, S), INK)
    ink.putalpha(ol)
    # paper/brush grain on the colour fill
    noise = Image.effect_noise((S, S), 40).convert("L")
    grain = Image.merge("RGBA", (noise, noise, noise, Image.new("L", (S, S), 255)))
    mod = ImageChops.multiply(im, Image.blend(Image.new("RGBA", (S, S), (255,255,255,255)), grain, 0.12))
    mod.putalpha(a)
    out = Image.alpha_composite(ink, mod)
    out = out.resize((128, 128), Image.LANCZOS)
    out.save(os.path.join(OUT, name + ".png"), optimize=True)

def poly_blob(d, pts, fill):
    d.polygon(pts, fill=fill)

def star(cx, cy, r1, r2, n, rot=0.0):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = rot + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts

def thick_arc(d, box, a0, a1, w, fill):
    d.arc(box, a0, a1, fill=fill, width=w)

def mace(cv, cx, cy, ang, length, head_r, col, col2, hi):
    d = cv.d
    ux, uy = math.cos(ang), math.sin(ang)
    x0, y0 = cx - ux * length * 0.5, cy - uy * length * 0.5
    x1, y1 = cx + ux * length * 0.5, cy + uy * length * 0.5
    d.line([(x0, y0), (x1, y1)], fill=H("#7a5236"), width=34)
    d.line([(x0, y0), (x1, y1)], fill=H("#b07a4a"), width=14)
    d.ellipse([x1 - head_r, y1 - head_r, x1 + head_r, y1 + head_r], fill=col)
    for i in range(8):
        a = i * math.pi / 4 + ang
        px, py = x1 + math.cos(a) * head_r, y1 + math.sin(a) * head_r
        qx, qy = x1 + math.cos(a) * (head_r + 34), y1 + math.sin(a) * (head_r + 34)
        sx, sy = -math.sin(a) * 18, math.cos(a) * 18
        d.polygon([(px + sx, py + sy), (qx, qy), (px - sx, py - sy)], fill=col2)
    d.ellipse([x1 - head_r * .55, y1 - head_r * .55, x1 + head_r * .1, y1 + head_r * .1], fill=hi)

def slash(cv, cx, cy, r, a0, a1, w, col, hi=None):
    d = cv.d
    box = [cx - r, cy - r, cx + r, cy + r]
    d.arc(box, a0, a1, fill=col, width=w)
    if hi:
        d.arc([cx - r + w * .25, cy - r + w * .25, cx + r - w * .25, cy + r - w * .25], a0, a1, fill=hi, width=max(4, w // 3))

# ------------------------------------------------------------------ Aruun
def aruun_combo():
    c = Canvas(); d = c.d
    slash(c, 270, 300, 190, 200, 300, 44, EMBER, EMBER_HI)
    slash(c, 270, 300, 140, 210, 290, 26, EMBER2)
    mace(c, 240, 260, math.radians(-50), 300, 72, H("#8a3a2a"), H("#e0b078"), H("#d86a4a"))
    finish(c, "aruun_combo")

def reaching_strike():
    c = Canvas(); d = c.d
    for i, (y, w) in enumerate([(160, 40), (352, 40)]):
        d.polygon([(40, y), (330, y - 14), (330, y + 14)], fill=EMBER2)
    d.polygon([(40, 256 - 30), (360, 256 - 14), (360, 256 + 14), (40, 256 + 30)], fill=EMBER)
    d.polygon([(40, 256 - 10), (360, 256 - 4), (360, 256 + 4), (40, 256 + 10)], fill=EMBER_HI)
    mace(c, 400, 256, 0, 130, 78, H("#8a3a2a"), H("#e0b078"), H("#d86a4a"))
    # impact burst
    d.polygon(star(440, 256, 60, 30, 8, 0.2), fill=EMBER_HI)
    finish(c, "reaching_strike")

def gravity_pull():
    c = Canvas(); d = c.d
    cx = cy = 256
    for r, col in [(200, VIOLET2), (150, VIOLET), (100, H("#c9a8ff"))]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=26)
    d.ellipse([cx - 52, cy - 52, cx + 52, cy + 52], fill=H("#2a1850"))
    d.ellipse([cx - 28, cy - 28, cx + 28, cy + 28], fill=EMBER_HI)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        px, py = cx + math.cos(a) * 215, cy + math.sin(a) * 215
        tx, ty = cx + math.cos(a) * 130, cy + math.sin(a) * 130
        nx, ny = -math.sin(a), math.cos(a)
        d.polygon([(tx, ty), (px + nx * 40, py + ny * 40), (px - nx * 40, py - ny * 40)], fill=EMBER)
    finish(c, "gravity_pull", 14)

def beetle_rage():
    c = Canvas(); d = c.d
    d.polygon(star(256, 270, 230, 120, 9, -0.3), fill=EMBER)
    d.polygon(star(256, 270, 170, 90, 9, -0.1), fill=EMBER2)
    # beetle head with horn
    d.polygon([(256, 80), (226, 210), (206, 250), (306, 250), (286, 210)], fill=H("#3a1a14"))
    d.polygon([(256, 100), (240, 200), (272, 200)], fill=H("#7a3a2a"))
    d.ellipse([170, 230, 342, 400], fill=H("#3a1a14"))
    d.ellipse([190, 250, 322, 380], fill=H("#7a2a1a"))
    d.polygon([(200, 330), (150, 410), (230, 370)], fill=H("#3a1a14"))
    d.polygon([(312, 330), (362, 410), (282, 370)], fill=H("#3a1a14"))
    d.ellipse([205, 290, 245, 320], fill=EMBER_HI); d.ellipse([267, 290, 307, 320], fill=EMBER_HI)
    finish(c, "beetle_rage", 14)

# ------------------------------------------------------------------ Cigarra
def bad_thought():
    c = Canvas(); d = c.d
    for i, (dy, ln) in enumerate([(-70, 250), (0, 330), (70, 250)]):
        d.polygon([(60 + (330 - ln) * .3, 256 + dy), (300, 256 + dy - 22), (300, 256 + dy + 22)], fill=LIME2)
    d.polygon(star(340, 256, 150, 98, 9, 0.1), fill=LIME2)
    d.ellipse([240, 156, 440, 356], fill=LIME)
    d.ellipse([275, 190, 360, 270], fill=LIME_HI)
    d.ellipse([360, 240, 420, 300], fill=H("#5c7a1a"))
    finish(c, "bad_thought")

def eye(c, cx, cy, w, h, col, iris, pupil):
    d = c.d
    pts = []
    n = 24
    for i in range(n + 1):
        t = i / n; x = cx - w + 2 * w * t; y = cy - math.sin(math.pi * t) * h
        pts.append((x, y))
    for i in range(n + 1):
        t = 1 - i / n; x = cx - w + 2 * w * t; y = cy + math.sin(math.pi * t) * h
        pts.append((x, y))
    d.polygon(pts, fill=col)
    r = h * .8
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=iris)
    r2 = r * .45
    d.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=pupil)

def premonition():
    c = Canvas(); d = c.d
    # ghost eyes trailing to the upper right (the future)
    eye(c, 330, 190, 150, 70, (89, 230, 210, 120), (89, 230, 210, 160), (30, 80, 90, 170))
    eye(c, 256, 270, 200, 105, BONE, LIME, H("#2a2a10"))
    d.ellipse([236, 220, 276, 250], fill=(255, 255, 255, 255))
    for i in range(5):
        a = math.radians(-150 + 30 * i)
        d.line([(256 + math.cos(a) * 150, 150 + math.sin(a) * 40 - 20), (256 + math.cos(a) * 205, 130 + math.sin(a) * 70 - 20)], fill=LIME, width=16)
    finish(c, "premonition", 14)

def figure(d, cx, cy, s, col, hi=None):
    d.ellipse([cx - 52 * s, cy - 150 * s, cx + 52 * s, cy - 46 * s], fill=col)
    d.polygon([(cx - 36 * s, cy - 36 * s), (cx + 36 * s, cy - 36 * s), (cx + 80 * s, cy + 150 * s), (cx - 80 * s, cy + 150 * s)], fill=col)
    if hi:
        d.ellipse([cx - 30 * s, cy - 130 * s, cx + 2 * s, cy - 90 * s], fill=hi)

def false_memory():
    c = Canvas(); d = c.d
    figure(c.d, 330, 270, 1.0, (89, 230, 210, 150), (255, 255, 255, 190))
    # echo outlines
    for dx in (14, 28):
        d.line([(330 + 80 + dx, 420), (330 + 36 + dx, 234)], fill=(89, 230, 210, 110), width=8)
    figure(d, 190, 290, 1.1, LIME, LIME_HI)
    finish(c, "false_memory", 14)

def brain_skip():
    c = Canvas(); d = c.d
    for k, off in enumerate((0, 140)):
        x = 70 + off
        d.polygon([(x, 120), (x + 120, 256), (x, 392), (x + 60, 392), (x + 180, 256), (x + 60, 120)], fill=LIME if k else LIME2)
    # glitch bars
    for y, w in [(90, 150), (420, 200), (60, 90)]:
        d.rectangle([300 + (y % 40), y, 300 + w, y + 22], fill=GHOST)
    d.rectangle([380, 230, 470, 282], fill=BONE)
    finish(c, "brain_skip", 14)

def grasshopper_thought():
    c = Canvas(); d = c.d
    # leap arc
    d.arc([40, 150, 460, 560], 200, 340, fill=LIME2, width=44)
    d.arc([40, 150, 460, 560], 200, 340, fill=LIME_HI, width=14)
    # wing cloak
    d.polygon([(256, 150), (110, 70), (160, 200)], fill=GHOST)
    d.polygon([(256, 150), (402, 70), (352, 200)], fill=GHOST2)
    d.ellipse([206, 130, 306, 230], fill=LIME)
    d.polygon([(256, 230), (200, 330), (312, 330)], fill=LIME2)
    # landing marks
    d.polygon([(60, 400), (120, 360), (110, 440)], fill=LIME)
    d.polygon([(452, 400), (392, 360), (402, 440)], fill=LIME)
    finish(c, "grasshopper_thought", 14)

def probable_impact():
    c = Canvas(); d = c.d
    d.polygon(star(256, 256, 235, 120, 12, 0.1), fill=VIOLET)
    d.polygon(star(256, 256, 180, 95, 12, 0.3), fill=EMBER)
    eye(c, 256, 256, 150, 80, BONE, LIME, H("#2a2a10"))
    finish(c, "probable_impact", 14)

# ------------------------------------------------------------------ shared UI
def dash():
    c = Canvas(); d = c.d
    for i, x in enumerate((60, 190, 320)):
        col = BONE if i == 2 else H("#c8b890")
        d.polygon([(x, 110), (x + 110, 256), (x, 402), (x + 60, 402), (x + 170, 256), (x + 60, 110)], fill=col)
    finish(c, "dash", 14)

def scan():
    c = Canvas(); d = c.d
    cx = cy = 256
    for r in (200, 140, 80):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=CYAN2 if r != 140 else CYAN, width=22)
    d.pieslice([cx - 200, cy - 200, cx + 200, cy + 200], -75, -15, fill=(89, 210, 230, 200))
    d.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=BONE)
    d.ellipse([360, 130, 420, 190], fill=EMBER_HI)
    finish(c, "scan", 14)

def capture():
    c = Canvas(); d = c.d
    cx = cy = 256
    hexp = [(cx + math.cos(math.radians(60 * i - 30)) * 210, cy + math.sin(math.radians(60 * i - 30)) * 210) for i in range(6)]
    d.polygon(hexp, outline=CYAN, fill=(31, 143, 168, 255))
    inner = [(cx + math.cos(math.radians(60 * i - 30)) * 140, cy + math.sin(math.radians(60 * i - 30)) * 140) for i in range(6)]
    d.polygon(inner, fill=H("#123a46"))
    for i in range(6):
        d.line([hexp[i], inner[i]], fill=CYAN, width=18)
    d.ellipse([cx - 55, cy - 55, cx + 55, cy + 55], fill=CYAN)
    finish(c, "capture", 14)

def swap():
    c = Canvas(); d = c.d
    d.arc([70, 90, 442, 422], 200, 340, fill=BONE, width=44)
    d.polygon([(420, 150), (470, 250), (350, 240)], fill=BONE)
    d.arc([70, 90, 442, 422], 20, 160, fill=H("#c8b890"), width=44)
    d.polygon([(92, 362), (42, 262), (162, 272)], fill=H("#c8b890"))
    finish(c, "swap", 14)

def interact():
    c = Canvas(); d = c.d
    d.polygon(star(256, 256, 220, 150, 8, 0.2), fill=EMBER2)
    d.ellipse([196, 70, 316, 190], fill=BONE)
    d.polygon([(206, 190), (306, 190), (286, 320), (226, 320)], fill=BONE)
    d.ellipse([206, 370, 306, 450], fill=BONE)
    finish(c, "interact", 14)

for fn in [aruun_combo, reaching_strike, gravity_pull, beetle_rage, bad_thought, premonition, false_memory,
           brain_skip, grasshopper_thought, probable_impact, dash, scan, capture, swap, interact]:
    fn()
# contact sheet for review
names = [f.__name__ for f in [aruun_combo, reaching_strike, gravity_pull, beetle_rage, bad_thought, premonition, false_memory,
           brain_skip, grasshopper_thought, probable_impact, dash, scan, capture, swap, interact]]
sheet = Image.new("RGBA", (128 * 5, 128 * 3), (60, 48, 42, 255))
for i, n in enumerate(names):
    im = Image.open(os.path.join(OUT, n + ".png"))
    sheet.alpha_composite(im, ((i % 5) * 128, (i // 5) * 128))
sheet.save(os.environ.get("ICON_SHEET", "/tmp/icon_sheet.png"))
print("ok", len(names))
