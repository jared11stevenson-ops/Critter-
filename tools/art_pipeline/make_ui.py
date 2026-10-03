"""Generate CRITTER UI textures (Agent 1). Parchment panels + dark ability cards like the model sheets.
Run: python3 tools/art_pipeline/make_ui.py  -> game/art/ui/*.png"""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
import os
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'game', 'art', 'ui')
rng = np.random.default_rng(7)
PARCH = np.array([232, 220, 200]) / 255.0
PARCH_DARK = np.array([196, 176, 148]) / 255.0
INK = np.array([34, 26, 26]) / 255.0
CARD = np.array([30, 28, 31]) / 255.0
CARD_EDGE = np.array([120, 112, 108]) / 255.0
GOLD = np.array([214, 170, 92]) / 255.0


def fbm(h, w, scale, octaves=4):
    out = np.zeros((h, w))
    amp = 1.0
    tot = 0
    for o in range(octaves):
        s = max(2, int(scale / (2 ** o)))
        n = rng.random((h // s + 2, w // s + 2))
        n = ndimage.zoom(n, s, order=3)[:h, :w]
        out += n * amp
        tot += amp
        amp *= 0.5
    return out / tot


def save(rgb, a, name):
    img = np.dstack([np.clip(rgb, 0, 1), np.clip(a, 0, 1)])
    Image.fromarray((img * 255).astype(np.uint8), 'RGBA').save(os.path.join(OUT, name))


def rounded_mask(h, w, r, inset=0, soft=1.5):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    qx = np.abs(x - (w - 1) / 2) - ((w - 1) / 2 - inset - r)
    qy = np.abs(y - (h - 1) / 2) - ((h - 1) / 2 - inset - r)
    d = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - r
    return np.clip(0.5 - d / soft, 0, 1), d


def rough(h, w, amt):
    return (fbm(h, w, 8, 3) - 0.5) * amt


def parchment(size=128, name='panel_parchment.png'):
    h = w = size
    n1 = fbm(h, w, 32)
    n2 = fbm(h, w, 6, 2)
    rgb = PARCH[None, None, :] * (0.94 + 0.1 * n1[..., None]) - 0.04 * (n2[..., None] - 0.5)
    m, d = rounded_mask(h, w, 10, 2)
    d = d + rough(h, w, 1.6)
    # darker burnt edge + ink border (brushy)
    edge = np.clip(1 - (-d) / 14, 0, 1) ** 2
    rgb = rgb * (1 - edge[..., None] * 0.35) + PARCH_DARK * edge[..., None] * 0.35
    border = np.exp(-((d + 5.0) / 1.3) ** 2) * (0.75 + 0.25 * fbm(h, w, 4, 2))
    rgb = rgb * (1 - border[..., None]) + INK * border[..., None]
    inner = np.exp(-((d + 9.0) / 0.6) ** 2) * 0.35
    rgb = rgb * (1 - inner[..., None]) + INK * inner[..., None]
    a = np.clip(0.5 - (d + rough(h, w, 2.0)) / 1.2, 0, 1)
    save(rgb, a, name)


def dark_panel(size=128, name='panel_dark.png'):
    h = w = size
    n = fbm(h, w, 24)
    rgb = CARD[None, None, :] * (0.9 + 0.25 * n[..., None])
    m, d = rounded_mask(h, w, 8, 2)
    border = np.exp(-((d + 3.0) / 0.9) ** 2)
    rgb = rgb * (1 - border[..., None]) + CARD_EDGE * border[..., None]
    a = np.clip(0.5 - d / 1.2, 0, 1) * 0.96
    save(rgb, a, name)


def disc(size, r_frac):
    y, x = np.mgrid[0:size, 0:size].astype(float)
    c = (size - 1) / 2
    r = np.sqrt((x - c) ** 2 + (y - c) ** 2)
    return r, c * r_frac, x - c, y - c


def button(pressed, name):
    s = 192
    r, R, dx, dy = disc(s, 0.94)
    rr = r + rough(s, s, 2.0)
    a = np.clip(R - rr, 0, 1)
    shade = np.clip(1 - (dy / R) * (0.25 if not pressed else -0.15), 0, 2)
    base = CARD * (1.25 if not pressed else 0.85)
    rgb = base[None, None, :] * shade[..., None] * (0.92 + 0.15 * fbm(s, s, 20)[..., None])
    ring = np.exp(-((rr - (R - 6)) / 2.2) ** 2)
    ringcol = GOLD if pressed else CARD_EDGE * 1.3
    rgb = rgb * (1 - ring[..., None]) + ringcol * ring[..., None]
    ink = np.exp(-((rr - (R - 1.5)) / 1.4) ** 2)
    rgb = rgb * (1 - ink[..., None]) + INK * ink[..., None]
    save(rgb, a, name)


def joystick():
    s = 256
    r, R, dx, dy = disc(s, 0.96)
    rr = r + rough(s, s, 2.5)
    a = np.clip(R - rr, 0, 1) * 0.55
    rgb = np.ones((s, s, 3)) * PARCH * 0.9
    ring = np.exp(-((rr - (R - 5)) / 2.5) ** 2)
    a = np.maximum(a, ring * 0.95)
    rgb = rgb * (1 - ring[..., None]) + INK * ring[..., None]
    # direction ticks
    ang = np.arctan2(dy, dx)
    for k in range(4):
        t = k * np.pi / 2
        da = np.abs(np.angle(np.exp(1j * (ang - t))))
        tick = (da < 0.06) * (np.abs(rr - (R - 22)) < 8)
        rgb[tick] = INK
        a = np.maximum(a, tick * 0.9)
    save(rgb, a, 'joystick_base.png')
    s = 128
    r, R, dx, dy = disc(s, 0.92)
    rr = r + rough(s, s, 1.5)
    a = np.clip(R - rr, 0, 1)
    shade = 1.05 - 0.2 * (dy / R)
    rgb = PARCH[None, None, :] * shade[..., None] * (0.92 + 0.12 * fbm(s, s, 16)[..., None])
    ink = np.exp(-((rr - (R - 2.5)) / 1.8) ** 2)
    rgb = rgb * (1 - ink[..., None]) + INK * ink[..., None]
    save(rgb, a, 'joystick_knob.png')


def frame_portrait():
    s = 256
    h = w = s
    m, d = rounded_mask(h, w, 14, 3)
    d = d + rough(h, w, 2.0)
    band = np.clip((d + 14) / 2.0, 0, 1) * np.clip(0.5 - d / 1.2, 0, 1)   # 14 px frame ring
    n = fbm(h, w, 24)
    rgb = PARCH[None, None, :] * (0.88 + 0.12 * n[..., None])
    outer = np.exp(-((d + 1.5) / 1.3) ** 2)
    inner = np.exp(-((d + 13.0) / 1.2) ** 2)
    ink = np.clip(outer + inner, 0, 1)
    rgb = rgb * (1 - ink[..., None]) + INK * ink[..., None]
    # corner brush accents
    save(rgb, np.clip(band + inner * 0.9, 0, 1), 'frame_portrait.png')


def divider():
    h, w = 24, 512
    y, x = np.mgrid[0:h, 0:w].astype(float)
    t = x / (w - 1)
    thick = 3.2 * np.sin(np.pi * t) ** 0.6 + 0.4
    wob = (fbm(h, w, 32, 2)[h // 2] - 0.5) * 4
    d = np.abs(y - (h / 2 + wob[None, :])) - thick
    a = np.clip(0.5 - d / 1.0, 0, 1) * (0.8 + 0.2 * fbm(h, w, 3, 2))
    # dry-brush gaps
    a *= np.clip(fbm(h, w, 10, 2) * 2.2 - 0.25, 0, 1) ** 0.4
    rgb = np.ones((h, w, 3)) * INK
    save(rgb, a, 'divider_brush.png')


def cooldown_mask():
    # radial sweep mask: alpha encodes angle (clockwise from top), used with a threshold shader / TextureProgress
    s = 192
    r, R, dx, dy = disc(s, 0.94)
    ang = (np.arctan2(dx, -dy) / (2 * np.pi)) % 1.0
    a = np.clip(R - r, 0, 1)
    rgb = np.ones((s, s, 3)) * (1 - ang[..., None])
    save(rgb * 0 + 0.0, a * 0.65, 'cooldown_mask.png')
    save(np.dstack([ang] * 3), a, 'cooldown_sweep.png')


os.makedirs(OUT, exist_ok=True)
parchment()
dark_panel()
button(False, 'button_round.png')
button(True, 'button_round_pressed.png')
joystick()
frame_portrait()
divider()
cooldown_mask()
print('ok')
