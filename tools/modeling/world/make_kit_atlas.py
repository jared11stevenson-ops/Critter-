"""512x512 shared decal atlas for the world kit (4x4 cells of 128). RGBA: painted-over where alpha>0.
Bluish pixels glow (Thoughtstone / pulse-lock). Output: game/art/world/kit/kit_atlas.webp"""
import os, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "game", "art", "world", "kit"))
os.makedirs(OUT, exist_ok=True)
S = 128
rng = random.Random(11)
atlas = Image.new("RGBA", (512, 512), (255, 255, 255, 0))

def cell(cx, cy):
    return Image.new("RGBA", (S, S), (255, 255, 255, 0))

def paste(im, cx, cy):
    atlas.paste(im, (cx * S, cy * S))

def glow_edge(im, dark=(60, 30, 24), light=(230, 190, 150)):
    """Carved look: dark inset from alpha + light lower-right edge."""
    a = im.split()[3]
    sh = a.filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    hl = Image.new("RGBA", im.size, light + (0,))
    hl.putalpha(a.transform(a.size, Image.AFFINE, (1, 0, -1.5, 0, 1, -1.5)).point(lambda v: int(v * 0.5)))
    out.alpha_composite(hl)
    d = Image.new("RGBA", im.size, dark + (0,))
    d.putalpha(a.point(lambda v: int(v * 0.88)))
    out.alpha_composite(d)
    return out

# blank cell stays transparent
# glyph band: rows of geometric Spanwright symbols (drawn on an L mask, then carved)
mask = Image.new("L", (S, S), 0); d = ImageDraw.Draw(mask)
for row in range(4):
    y0 = 6 + row * 31
    x = 6
    while x < 112:
        k = rng.randrange(6); w = rng.choice([14, 18, 22])
        if k == 0: d.ellipse([x, y0 + 4, x + w - 4, y0 + 4 + w - 4], outline=255, width=3)
        elif k == 1: d.line([x, y0 + 20, x + w // 2, y0 + 2, x + w, y0 + 20], fill=255, width=3)
        elif k == 2: d.rectangle([x, y0 + 4, x + w - 5, y0 + 18], outline=255, width=3); d.line([x + 3, y0 + 11, x + w - 8, y0 + 11], fill=255, width=2)
        elif k == 3: d.arc([x, y0, x + w, y0 + 22], 200, 340, fill=255, width=3); d.line([x + w // 2, y0 + 10, x + w // 2, y0 + 24], fill=255, width=3)
        elif k == 4: d.line([x, y0 + 4, x + w - 4, y0 + 4], fill=255, width=3); d.line([x + 4, y0 + 12, x + w, y0 + 12], fill=255, width=3); d.line([x, y0 + 20, x + w - 4, y0 + 20], fill=255, width=3)
        else: d.polygon([(x + w // 2, y0), (x + w - 3, y0 + 12), (x + w // 2, y0 + 24), (x + 2, y0 + 12)], outline=255)
        x += w + rng.choice([4, 6, 9])
g = Image.new("RGBA", (S, S), (255, 255, 255, 0)); g.putalpha(mask)
paste(glow_edge(g), 1, 0)

# tally scratches: groups of 4 + slash
im = cell(2, 0); d = ImageDraw.Draw(im)
for gr in range(7):
    gx = 8 + (gr % 2) * 58 + rng.randint(-3, 3); gy = 8 + (gr // 2) * 30 + rng.randint(-2, 2)
    for k in range(4):
        x = gx + k * 8 + rng.randint(-1, 1)
        d.line([x, gy + rng.randint(-1, 1), x + rng.randint(-1, 1), gy + 22], fill=(60, 34, 26, 235), width=2)
    d.line([gx - 3, gy + 17, gx + 31, gy + 4], fill=(60, 34, 26, 235), width=2)
paste(im, 2, 0)

# hazard stripes (Dominion red / charcoal)
im = cell(3, 0); px = im.load()
for y in range(S):
    for x in range(S):
        px[x, y] = (200, 28, 24, 255) if ((x + y) // 14) % 2 == 0 else (36, 34, 36, 255)
paste(im, 3, 0)

# stencil: Dominion sigil (ring + bar + three ticks)
im = cell(0, 1); d = ImageDraw.Draw(im)
d.ellipse([22, 22, 106, 106], outline=(236, 228, 214, 235), width=7)
d.rectangle([14, 58, 114, 70], fill=(236, 228, 214, 235))
for k in range(3):
    d.rectangle([44 + k * 18, 30, 52 + k * 18, 52], fill=(236, 228, 214, 235))
paste(im.filter(ImageFilter.GaussianBlur(0.6)), 0, 1)

# wood grain
im = cell(1, 1); d = ImageDraw.Draw(im)
d.rectangle([0, 0, S, S], fill=(120, 80, 54, 255))
for p in range(5):
    y0 = p * 26
    d.rectangle([0, y0, S, y0 + 2], fill=(52, 32, 22, 255))
    for k in range(7):
        y = y0 + 4 + rng.randint(0, 18)
        x0 = rng.randint(0, 40)
        d.line([x0, y, x0 + rng.randint(40, 90), y + rng.randint(-2, 2)], fill=(92, 60, 40, 255), width=1)
paste(im, 1, 1)

# rope weave
im = cell(2, 1); d = ImageDraw.Draw(im)
d.rectangle([0, 0, S, S], fill=(204, 168, 108, 255))
for k in range(-S, S * 2, 12):
    d.line([k, 0, k + S, S], fill=(150, 112, 70, 255), width=4)
paste(im, 2, 1)

# salt speckle
im = cell(3, 1); px = im.load()
for i in range(900):
    x, y = rng.randrange(S), rng.randrange(S)
    v = rng.randint(225, 255)
    px[x, y] = (v, v, v - 6, rng.randint(120, 230))
paste(im.filter(ImageFilter.GaussianBlur(0.5)), 3, 1)

# rust streaks (vertical)
im = cell(0, 2); d = ImageDraw.Draw(im)
for k in range(14):
    x = rng.randint(0, S); h = rng.randint(30, 120)
    d.line([x, 0, x + rng.randint(-3, 3), h], fill=(124, 58, 28, rng.randint(70, 150)), width=rng.randint(2, 7))
paste(im.filter(ImageFilter.GaussianBlur(1.4)), 0, 2)

# cracks
im = cell(1, 2); d = ImageDraw.Draw(im)
def crack(x, y, a, n):
    for i in range(n):
        a += rng.uniform(-0.5, 0.5)
        nx, ny = x + math.cos(a) * rng.randint(5, 12), y + math.sin(a) * rng.randint(5, 12)
        d.line([x, y, nx, ny], fill=(40, 20, 16, 210), width=2 if i < n // 2 else 1)
        if rng.random() < 0.25 and n > 3: crack(nx, ny, a + rng.choice([-1, 1]) * 0.9, n // 2)
        x, y = nx, ny
for k in range(4): crack(rng.randint(10, 118), rng.randint(10, 118), rng.uniform(0, 6.28), 9)
paste(im, 1, 2)

# pulse lock: concentric rings, glowing cyan
im = cell(2, 2); d = ImageDraw.Draw(im)
d.ellipse([2, 2, 126, 126], fill=(40, 52, 60, 255))
for k, r in enumerate([58, 46, 34, 22, 10]):
    d.ellipse([64 - r, 64 - r, 64 + r, 64 + r], outline=(110, 230, 255, 255), width=3 if k % 2 == 0 else 2)
for a in range(0, 360, 45):
    x, y = 64 + math.cos(math.radians(a)) * 52, 64 + math.sin(math.radians(a)) * 52
    d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(150, 240, 255, 255))
paste(im, 2, 2)

# chevrons (survey tape yellow/black)
im = cell(3, 2); px = im.load()
for y in range(S):
    for x in range(S):
        px[x, y] = (232, 190, 40, 255) if ((abs(x - 64) + y) // 16) % 2 == 0 else (30, 28, 28, 255)
paste(im, 3, 2)

# ashlar block joints
im = cell(0, 3); d = ImageDraw.Draw(im)
for r in range(6):
    y = r * 21
    d.line([0, y, S, y], fill=(44, 24, 20, 170), width=2)
    off = (r % 2) * 21
    for x in range(off, S, 42):
        d.line([x, y, x, y + 21], fill=(44, 24, 20, 150), width=2)
paste(im, 0, 3)

# lichen blotches
im = cell(1, 3); d = ImageDraw.Draw(im)
for k in range(26):
    x, y, r = rng.randint(0, S), rng.randint(0, S), rng.randint(5, 16)
    c = rng.choice([(190, 186, 80), (222, 140, 60), (150, 170, 90)])
    d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=c + (rng.randint(150, 230),))
paste(im.filter(ImageFilter.GaussianBlur(0.8)), 1, 3)

# planks
im = cell(2, 3); d = ImageDraw.Draw(im)
d.rectangle([0, 0, S, S], fill=(150, 108, 72, 255))
for p in range(4):
    y = p * 32
    d.rectangle([0, y, S, y + 31], outline=(60, 38, 28, 255), width=2)
    for k in range(5):
        yy = y + rng.randint(4, 28); xx = rng.randint(0, 60)
        d.line([xx, yy, xx + rng.randint(30, 70), yy], fill=(112, 76, 50, 255))
paste(im, 2, 3)

# scale cell: dust gradient
im = cell(3, 3); px = im.load()
for y in range(S):
    for x in range(S):
        px[x, y] = (214, 168, 126, int(200 * (y / S) ** 2))
paste(im, 3, 3)

# pad gutters so mip filtering does not drag neighbours in
rgba = np.array(atlas)
atlas.save(os.path.join(OUT, "kit_atlas.png"))
atlas.save(os.path.join(OUT, "kit_atlas.webp"), quality=94, method=6)
os.remove(os.path.join(OUT, "kit_atlas.png"))
print("atlas ok", os.path.getsize(os.path.join(OUT, "kit_atlas.webp")))
