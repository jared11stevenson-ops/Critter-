#!/usr/bin/env python3
"""Ability icon generator for CRITTER v2 (PIL, supersampled). One emblem per ability + basics, in the critter's colors.
Run: python3 v2/tools/gen/gen_icons.py   -> v2/art/icons/<move_id>.png (256 px)"""
import math, os
from PIL import Image, ImageDraw
S = 4; N = 256 * S; C = N // 2
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "art", "icons")
INK = (22, 18, 26, 255)
PAL = {  # main, accent, glow
 "aruun": ((150, 40, 36), (232, 200, 150), (255, 110, 50)),
 "cigarra": ((60, 44, 92), (170, 210, 60), (224, 255, 90)),
 "bramvex": ((110, 96, 56), (200, 190, 140), (214, 70, 60)),
 "scarlith": ((190, 40, 60), (240, 200, 90), (255, 140, 60)),
 "mollusk": ((150, 100, 50), (110, 150, 90), (255, 160, 40)),
 "zephyr": ((120, 100, 60), (230, 150, 70), (255, 80, 200)),
 "nyxaris": ((40, 50, 110), (210, 235, 255), (120, 200, 255)),
 "basic": ((70, 70, 80), (230, 220, 200), (255, 210, 90)),
}
def P(x, y): return (C + x * C / 100.0, C + y * C / 100.0)   # coords -100..100
def poly(d, pts, fill, w=5):
    d.polygon([P(*p) for p in pts], fill=fill, outline=INK, width=w * S // 2)
def circ(d, x, y, r, fill, w=5):
    a = P(x - r, y - r); b = P(x + r, y + r); d.ellipse([a, b], fill=fill, outline=INK, width=w * S // 2)
def line(d, pts, col, w=6):
    d.line([P(*p) for p in pts], fill=col, width=w * S // 2, joint="curve")
def arc(d, x, y, r, a0, a1, col, w=6):
    a = P(x - r, y - r); b = P(x + r, y + r); d.arc([a, b], a0, a1, fill=col, width=w * S // 2)
def star(d, x, y, r1, r2, n, fill, rot=0, w=4):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2; a = rot + i * math.pi / n
        pts.append((x + r * math.cos(a), y + r * math.sin(a)))
    poly(d, pts, fill, w)
def spiral(d, x, y, r0, r1, turns, col, w=6):
    pts = []; n = 60
    for i in range(n + 1):
        f = i / n; a = f * turns * 2 * math.pi; r = r0 + (r1 - r0) * f
        pts.append((x + r * math.cos(a), y + r * math.sin(a)))
    line(d, pts, col, w)
def burst(d, cx, cy, r1, r2, n, col): star(d, cx, cy, r1, r2, n, col)
def drop(d, x, y, s, fill):
    poly(d, [(x, y - s), (x + s * .7, y + s * .3), (x + s * .5, y + s * .8), (x, y + s), (x - s * .5, y + s * .8), (x - s * .7, y + s * .3)], fill)
def arrow(d, x0, y0, x1, y1, col, w=7):
    line(d, [(x0, y0), (x1, y1)], col, w)
    a = math.atan2(y1 - y0, x1 - x0); h = 14
    poly(d, [(x1, y1), (x1 - h * math.cos(a - .5), y1 - h * math.sin(a - .5)), (x1 - h * math.cos(a + .5), y1 - h * math.sin(a + .5))], col, 3)

def make(name, who, draw_fn):
    main, acc, glow = PAL[who]
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    # sticker disc: dark ring, color body, light highlight
    circ(d, 0, 0, 92, INK, 0); circ(d, 0, 0, 86, main + (255,), 0)
    d.pieslice([P(-78, -78), P(78, 78)], 200, 290, fill=tuple(min(255, c + 40) for c in main) + (255,))
    draw_fn(d, main, acc, glow)
    d.ellipse([P(-90, -90), P(90, 90)], outline=INK, width=9 * S // 2)
    d.ellipse([P(-80, -80), P(80, 80)], outline=glow + (255,), width=3 * S // 2)
    im = im.resize((256, 256), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True); im.save(os.path.join(OUT, name + ".png"))

def mace(d, x, y, s, col, acc):
    line(d, [(x - s, y + s), (x, y)], (90, 60, 40, 255), 9)
    circ(d, x, y, s * .55, col)
    for a in range(0, 360, 60):
        r = math.radians(a); poly(d, [(x + s * .5 * math.cos(r - .2), y + s * .5 * math.sin(r - .2)), (x + s * .9 * math.cos(r), y + s * .9 * math.sin(r)), (x + s * .5 * math.cos(r + .2), y + s * .5 * math.sin(r + .2))], acc, 3)
def eye(d, x, y, w, col, acc):
    poly(d, [(x - w, y), (x, y - w * .6), (x + w, y), (x, y + w * .6)], acc); circ(d, x, y, w * .38, col); circ(d, x, y, w * .16, INK, 0)

ICONS = {}
def icon(name, who):
    def deco(f): ICONS[name] = (who, f); return f
    return deco
# ---------- Aruun
@icon("aruun_reaching_strike", "aruun")
def _(d, m, a, g):
    for i, o in enumerate([-30, -10, 10, 30]): line(d, [(-70, o), (-20 - i * 5, o)], g + (255,), 5)
    mace(d, 20, -10, 48, (50, 40, 50, 255), a + (255,)); line(d, [(-45, 55), (60, -55)], g + (255,), 4)
@icon("aruun_gravity_pull", "aruun")
def _(d, m, a, g):
    for k in range(4):
        r = math.radians(k * 90 + 45); arrow(d, 60 * math.cos(r), 60 * math.sin(r), 22 * math.cos(r), 22 * math.sin(r), a + (255,), 6)
    circ(d, 0, 0, 16, (30, 24, 36, 255)); spiral(d, 0, 0, 4, 14, 2, g + (255,), 4)
@icon("aruun_beetle_rage", "aruun")
def _(d, m, a, g):
    burst(d, 0, 0, 62, 36, 9, g + (255,)); burst(d, 0, 4, 44, 26, 9, (255, 220, 90, 255))
    poly(d, [(-34, -28), (-10, -52), (0, -20)], (40, 30, 40, 255)); poly(d, [(34, -28), (10, -52), (0, -20)], (40, 30, 40, 255)); circ(d, 0, 8, 22, (40, 30, 40, 255)); line(d, [(-12, 4), (-4, 10)], g + (255,), 5); line(d, [(12, 4), (4, 10)], g + (255,), 5)
@icon("aruun_carry_the_bridge", "aruun")
def _(d, m, a, g):
    arc(d, 0, 20, 50, 180, 360, a + (255,), 12); line(d, [(-52, 20), (52, 20)], a + (255,), 10); line(d, [(-52, 20), (-52, 54)], a + (255,), 9); line(d, [(52, 20), (52, 54)], a + (255,), 9)
    arrow(d, 0, -60, 0, -10, g + (255,), 9)
# ---------- Cigarra
@icon("cigarra_premonition", "cigarra")
def _(d, m, a, g):
    eye(d, 6, 4, 54, m, (230, 255, 160, 255)); eye(d, -12, -6, 44, (60, 44, 92, 120), (200, 230, 120, 110)); arc(d, 0, 0, 66, 200, 340, g + (255,), 5)
@icon("cigarra_false_memory", "cigarra")
def _(d, m, a, g):
    poly(d, [(-36, -40), (30, -40), (30, 36), (-36, 36)], (40, 30, 70, 200)); poly(d, [(-24, -30), (42, -30), (42, 46), (-24, 46)], a + (255,))
    circ(d, 2, -2, 6, INK, 0); circ(d, 24, -2, 6, INK, 0); arc(d, 14, 22, 12, 20, 160, INK, 5); line(d, [(-48, -50), (-36, -40)], g + (255,), 4)
@icon("cigarra_puppet_thought", "cigarra")
def _(d, m, a, g):
    for i, x in enumerate([-36, -12, 12, 36]): circ(d, x, -46 + (i % 2) * 8, 9, (20, 16, 26, 255)); line(d, [(x, -38 + (i % 2) * 8), (x * .3, 12)], g + (255,), 3)
    poly(d, [(-12, 14), (12, 14), (8, 54), (-8, 54)], a + (255,)); circ(d, 0, 4, 10, a + (255,)); line(d, [(-26, 24), (26, 24)], a + (255,), 7)
@icon("cigarra_future_touched", "cigarra")
def _(d, m, a, g):
    circ(d, 0, 0, 50, (235, 245, 200, 255)); line(d, [(0, 0), (0, -36)], INK, 6); line(d, [(0, 0), (26, 14)], INK, 6); star(d, 38, -38, 18, 8, 4, g + (255,), 0.3)
    arc(d, 0, 0, 62, 20, 120, g + (255,), 5)
@icon("cigarra_bad_thought", "cigarra")
def _(d, m, a, g):
    circ(d, -34, 30, 18, (20, 16, 26, 255)); line(d, [(-20, 18), (40, -40)], g + (255,), 6); circ(d, 44, -44, 12, g + (255,)); circ(d, 20, -14, 7, a + (255,))
# ---------- Bramvex
@icon("bramvex_ghost", "bramvex")
def _(d, m, a, g):
    poly(d, [(-28, 50), (-34, -10), (-12, -48), (12, -48), (34, -10), (28, 50), (14, 36), (0, 50), (-14, 36)], (210, 205, 170, 140)); circ(d, -10, -14, 6, INK, 0); circ(d, 10, -14, 6, INK, 0)
    for i in range(4): line(d, [(40 + i * 8, -30 + i * 14), (56 + i * 8, -30 + i * 14)], a + (160,), 3)
@icon("bramvex_ground_prep", "bramvex")
def _(d, m, a, g):
    line(d, [(-70, 50), (70, 50)], (60, 44, 30, 255), 12)
    for x, h in [(-40, 60), (0, 80), (40, 58)]: poly(d, [(x - 12, 48), (x, 48 - h), (x + 12, 48)], a + (255,), 4)
@icon("bramvex_detain", "bramvex")
def _(d, m, a, g):
    arc(d, 0, 0, 44, 0, 360, a + (255,), 12); arc(d, 0, 0, 44, 20, 160, INK, 4); circ(d, 0, 44, 10, g + (255,)); line(d, [(-44, 0), (-62, -30)], a + (255,), 7); line(d, [(44, 0), (62, -30)], a + (255,), 7)
@icon("bramvex_day_20", "bramvex")
def _(d, m, a, g):
    poly(d, [(-40, -44), (40, -44), (40, 44), (-40, 44)], (235, 230, 205, 255)); poly(d, [(-40, -44), (40, -44), (40, -26), (-40, -26)], g + (255,))
    line(d, [(-22, -2), (-8, -2), (-22, 28), (-8, 28)], INK, 7); circ(d, 22, 12, 14, (0, 0, 0, 0), 5); line(d, [(10, 32), (36, -8)], INK, 7)
@icon("bramvex_diplomacy1", "bramvex")
def _(d, m, a, g):
    line(d, [(-52, 56), (46, -46)], (90, 64, 40, 255), 10)
    for t in [0.55, 0.7, 0.85]:
        x = -52 + 98 * t; y = 56 - 102 * t; poly(d, [(x - 4, y - 4), (x - 20, y - 18), (x + 4, y - 12)], a + (255,), 3)
# ---------- Scarlith
@icon("scarlith_ferment", "scarlith")
def _(d, m, a, g):
    poly(d, [(-26, -10), (26, -10), (44, 50), (-44, 50)], (255, 220, 160, 220)); poly(d, [(-12, -44), (12, -44), (14, -10), (-14, -10)], (255, 220, 160, 220))
    poly(d, [(-38, 24), (38, 24), (44, 50), (-44, 50)], a + (255,)); circ(d, -8, 8, 7, g + (255,), 3); circ(d, 12, -2, 5, g + (255,), 3); circ(d, 4, 28, 6, (255, 255, 200, 255), 3); circ(d, 2, -58, 6, g + (255,), 3)
@icon("scarlith_decompose", "scarlith")
def _(d, m, a, g):
    arc(d, 0, -8, 40, 180, 360, a + (255,), 16); line(d, [(-40, -8), (40, -8)], a + (255,), 10); poly(d, [(-12, -8), (12, -8), (10, 38), (-10, 38)], (235, 225, 200, 255))
    for x, y in [(-30, 44), (0, 54), (30, 46), (-14, 60)]: drop(d, x, y, 9, (110, 180, 70, 255))
@icon("scarlith_cultivate", "scarlith")
def _(d, m, a, g):
    line(d, [(-60, 52), (60, 52)], (70, 40, 30, 255), 12); line(d, [(0, 50), (0, -10)], (110, 180, 70, 255), 9)
    poly(d, [(0, -4), (-40, -22), (-22, 6)], (110, 200, 80, 255)); poly(d, [(0, -22), (40, -44), (24, -12)], (110, 200, 80, 255)); circ(d, 0, -22, 10, g + (255,))
@icon("scarlith_aged_to_perfection", "scarlith")
def _(d, m, a, g):
    poly(d, [(-50, 30), (50, 30), (50, -4), (-50, 30)], (255, 215, 90, 255)); poly(d, [(-50, 30), (50, 30), (50, 46), (-50, 46)], (240, 190, 70, 255)); circ(d, 10, 28, 7, (210, 150, 40, 255), 3); circ(d, 30, 14, 5, (210, 150, 40, 255), 3)
    star(d, 8, -30, 28, 12, 6, g + (255,), 0.2)
# ---------- Mollusk
@icon("mollusk_inertia_field", "mollusk")
def _(d, m, a, g):
    for r in (62, 44, 26): arc(d, 0, 0, r, 0, 360, a + (255,), 5)
    spiral(d, 0, 0, 4, 16, 2.2, g + (255,), 5); circ(d, 0, 0, 6, g + (255,), 3)
@icon("mollusk_borrowed_seconds", "mollusk")
def _(d, m, a, g):
    circ(d, 0, 0, 48, (240, 230, 200, 255)); line(d, [(0, 0), (0, -32)], INK, 6); line(d, [(0, 0), (-24, 12)], INK, 6); arc(d, 0, 0, 62, 210, 330, g + (255,), 7); arrow(d, -40, -48, -30, -58, g + (255,), 5)
@icon("mollusk_lift", "mollusk")
def _(d, m, a, g):
    line(d, [(-30, 56), (-30, -20)], (220, 150, 40, 255), 10); poly(d, [(-30, 40), (50, 40), (50, 54), (-30, 54)], (200, 200, 210, 255)); poly(d, [(-30, 4), (40, 4), (40, 14), (-30, 14)], (200, 200, 210, 255)); arrow(d, 10, -10, 10, -56, g + (255,), 8)
@icon("mollusk_everything_arrives", "mollusk")
def _(d, m, a, g):
    for k in range(6):
        r = math.radians(k * 60); arrow(d, 64 * math.cos(r), 64 * math.sin(r), 16 * math.cos(r), 16 * math.sin(r), a + (255,), 5)
    burst(d, 0, 0, 22, 10, 8, g + (255,))
# ---------- Zephyr
@icon("zephyr_gust", "zephyr")
def _(d, m, a, g):
    for i, (y, w) in enumerate([(-30, 60), (0, 74), (30, 52)]): line(d, [(-60, y), (-10, y), (w - 30, y - 10)], a + (255,), 8); arc(d, w - 30, y + 2, 14, 270, 540, a + (255,), 7)
@icon("zephyr_pollen", "zephyr")
def _(d, m, a, g):
    for k in range(6):
        r = math.radians(k * 60); circ(d, 22 * math.cos(r), 22 * math.sin(r) - 4, 17, g + (255,), 4)
    circ(d, 0, -4, 14, (255, 220, 70, 255), 4)
    for x, y in [(-50, -40), (46, -48), (52, 36), (-44, 46)]: circ(d, x, y, 5, (255, 230, 90, 255), 3)
@icon("zephyr_promise", "zephyr")
def _(d, m, a, g):
    poly(d, [(-44, -34), (44, -34), (44, 30), (-44, 30)], (240, 225, 190, 255)); line(d, [(-26, -14), (26, -14)], INK, 5); line(d, [(-26, 4), (14, 4)], INK, 5); circ(d, 30, 26, 12, g + (255,), 4); line(d, [(24, 36), (20, 54)], g + (255,), 5); line(d, [(36, 36), (40, 54)], g + (255,), 5)
@icon("zephyr_a_promise_kept", "zephyr")
def _(d, m, a, g):
    poly(d, [(-44, -40), (44, -40), (44, 24), (-44, 24)], (240, 225, 190, 255)); line(d, [(-24, 0), (-6, 18), (30, -22)], (60, 160, 70, 255), 10); star(d, 40, -46, 16, 7, 5, g + (255,)); star(d, -44, 40, 12, 5, 5, a + (255,))
# ---------- Nyxaris
@icon("nyxaris_boundary", "nyxaris")
def _(d, m, a, g):
    line(d, [(-64, 40), (64, -40)], a + (255,), 8)
    for i in range(5): x = -48 + i * 24; y = 30 - i * 15; line(d, [(x, y), (x - 10, y - 30)], g + (255,), 4); line(d, [(x, y), (x + 10, y + 30)], g + (255,), 4)
    star(d, 0, 0, 14, 6, 6, (230, 250, 255, 255), 0.0, 3)
@icon("nyxaris_venom_fang", "nyxaris")
def _(d, m, a, g):
    poly(d, [(-28, -50), (28, -50), (18, 8), (0, 56), (-18, 8)], (240, 245, 255, 255)); drop(d, 0, 66, 12, (120, 230, 90, 255)); line(d, [(0, -44), (0, 22)], (170, 190, 210, 255), 4)
@icon("nyxaris_cocoon", "nyxaris")
def _(d, m, a, g):
    d.ellipse([P(-30, -52), P(30, 52)], fill=(220, 235, 255, 255), outline=INK, width=6 * S // 2)
    for y in range(-40, 50, 14): line(d, [(-28, y), (28, y + 10)], (120, 160, 210, 255), 4)
    for y in range(-40, 50, 14): line(d, [(28, y), (-28, y + 10)], (150, 190, 230, 255), 3)
@icon("nyxaris_cold_archive", "nyxaris")
def _(d, m, a, g):
    for k in range(6):
        r = math.radians(k * 60); line(d, [(0, 0), (56 * math.cos(r), 56 * math.sin(r))], (235, 248, 255, 255), 7)
        x, y = 36 * math.cos(r), 36 * math.sin(r); line(d, [(x, y), (x + 14 * math.cos(r + 1), y + 14 * math.sin(r + 1))], (235, 248, 255, 255), 5); line(d, [(x, y), (x + 14 * math.cos(r - 1), y + 14 * math.sin(r - 1))], (235, 248, 255, 255), 5)
    circ(d, 0, 0, 9, g + (255,), 3)
# ---------- basics (shared)
@icon("basic_strike", "basic")
def _(d, m, a, g):
    burst(d, 0, 0, 64, 34, 8, g + (255,)); circ(d, 0, 4, 22, a + (255,)); poly(d, [(-18, -10), (-4, -26), (8, -18), (18, -8)], a + (255,), 3)
@icon("basic_guard", "basic")
def _(d, m, a, g):
    poly(d, [(0, -56), (46, -36), (40, 18), (0, 58), (-40, 18), (-46, -36)], a + (255,)); poly(d, [(0, -42), (32, -28), (28, 12), (0, 42)], (210, 200, 180, 255), 3)
@icon("basic_dodge", "basic")
def _(d, m, a, g):
    arc(d, 0, 0, 44, 200, 520, g + (255,), 10); arrow(d, 44, -6, 52, 16, g + (255,), 8); line(d, [(-50, 46), (-20, 46)], a + (255,), 6); line(d, [(-60, 30), (-30, 30)], a + (255,), 6)
@icon("basic_grab", "basic")
def _(d, m, a, g):
    for i, x in enumerate([-34, -12, 10, 32]): poly(d, [(x - 8, 6), (x + 8, 6), (x + 6, -44 + abs(i - 1.5) * 6), (x - 6, -44 + abs(i - 1.5) * 6)], a + (255,), 3)
    poly(d, [(-42, 6), (42, 6), (34, 48), (-34, 48)], a + (255,))
@icon("basic_last_stand", "basic")
def _(d, m, a, g):
    burst(d, 0, 0, 66, 40, 12, g + (255,)); burst(d, 0, 0, 40, 24, 12, (255, 240, 160, 255)); circ(d, 0, -4, 22, (40, 30, 40, 255)); circ(d, -9, -8, 5, g + (255,), 0); circ(d, 9, -8, 5, g + (255,), 0); line(d, [(-8, 6), (8, 6)], g + (255,), 4)
ICONS["zephyr_promise_attack"] = ICONS["zephyr_promise"]
for name, (who, fn) in ICONS.items(): make(name, who, fn)
print(len(ICONS), "icons ->", os.path.abspath(OUT))
