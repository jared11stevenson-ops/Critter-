"""Procedural albedo + normal textures for Bramvex's club 'Diplomacy' (u = around the shaft, v = along it, handle at v=0.1-0.26)."""
import numpy as np
from PIL import Image
W, H = 1024, 2048
rng = np.random.default_rng(7)
def noise(sx, sy, seed):
    r = np.random.default_rng(seed).random((sy, sx)).astype(np.float32)
    im = Image.fromarray((r * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32) / 255.0
def fbm(base, octs, stretch, seed):
    out = np.zeros((H, W), np.float32); amp = 1.0; tot = 0.0
    for o in range(octs):
        out += amp * noise(max(2, base[0] * 2 ** o), max(2, int(base[1] * stretch) * 2 ** o), seed + o); tot += amp; amp *= 0.5
    return out / tot
v = np.linspace(0, 1, H, dtype=np.float32)[:, None] * np.ones((1, W), np.float32)
u = np.linspace(0, 1, W, dtype=np.float32)[None, :] * np.ones((H, 1), np.float32)
grain = fbm((6, 3), 5, 5.0, 11)                      # long streaks along the shaft
rings = 0.5 + 0.5 * np.sin((grain * 14.0 + u * 6.0) * 3.14159)
cracks = np.clip((fbm((10, 6), 4, 3.0, 40) - 0.58) * 9.0, 0, 1)
knots = np.clip((fbm((5, 5), 3, 1.0, 70) - 0.66) * 7.0, 0, 1)
height = 0.55 * grain + 0.25 * rings - 0.7 * cracks - 0.4 * knots
wood_dark = np.array([0.13, 0.08, 0.05]); wood_lt = np.array([0.34, 0.22, 0.13])
t = np.clip(0.35 * rings + 0.6 * grain, 0, 1)[..., None]
col = wood_dark + (wood_lt - wood_dark) * t
col *= (1.0 - 0.75 * cracks[..., None]); col *= (1.0 - 0.45 * knots[..., None])
# red insignia cloth wrapped on the grip: diagonal bands, frayed
wrap = ((v > 0.075) & (v < 0.27)).astype(np.float32)
band = 0.5 + 0.5 * np.sin((v * 160.0 + u * 14.0) * 3.14159)
cloth = wrap * (band > 0.35)
weave = 0.85 + 0.15 * np.sin(u * 1400.0) * np.sin(v * 2600.0)
red = np.array([0.46, 0.11, 0.09]) * weave[..., None] * (0.7 + 0.5 * fbm((8, 8), 3, 1.0, 90)[..., None])
col = np.where(cloth[..., None] > 0, red, col)
height = np.where(cloth > 0, 0.55 + 0.1 * weave, height)
# charred striking head
char = np.clip((v - 0.78) / 0.18, 0, 1)[..., None] * (0.55 + 0.35 * fbm((9, 9), 4, 1.0, 120)[..., None])
col = col * (1 - 0.8 * char) + np.array([0.03, 0.025, 0.02]) * 0.8 * char
height -= 0.3 * char[..., 0] * cracks
# normal from height
hs = height * 6.0
dx = np.roll(hs, -1, 1) - np.roll(hs, 1, 1); dy = np.roll(hs, -1, 0) - np.roll(hs, 1, 0)
n = np.stack([-dx, -dy, np.ones_like(hs) * 0.9], -1); n /= np.linalg.norm(n, axis=-1, keepdims=True)
Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8)).save("v2/art/props/club_albedo.png")
Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save("v2/art/props/club_normal.png")
print("ok")
