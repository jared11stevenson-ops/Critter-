"""Aruun round-2 hand-authored region paint (replaces the camera-projected sheet paint).
Regions come from the geometry's part names; patterns are worley cells (plate seams, spots) + smooth noise.
Palette: sheet hues, pushed for the game: near-black violet chitin, deep wine plates with cream/ochre spots, white bone,
olive skirt, tan bandages (see design/model_sheets/aruun/palette.json game_palette)."""
import numpy as np


def hx(h):
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)], np.float32)


BLACK, PLUM = hx("#130e18"), hx("#2b2033")
WINE, WINE2, WINE_D = hx("#6c0f1c"), hx("#8e1b24"), hx("#3d0a14")
BONE, BONE_D, OCHRE = hx("#f0e6cf"), hx("#c9b992"), hx("#e0a24a")
OLIVE, OLIVE_L, OLIVE_D = hx("#6b7a35"), hx("#8c9446"), hx("#404b24")
TAN, LEATHER, CLOAK, CLOAK_D = hx("#cdae7a"), hx("#4a3626"), hx("#3d3827"), hx("#25221a")

RED = {"head", "brow", "crest", "horn", "pauldron", "armplate", "bracer", "neck"}
DARK = {"torso", "upperarm", "forearm", "hand", "thigh", "shin", "jaw"}
BONES = {"tine", "claw", "toeclaw", "kneeplate", "fang", "buckle", "medallion", "thighplate", "shinplate", "foot"}
SPOTTED = {"pauldron", "armplate", "bracer", "neck", "head", "brow", "crest"}


def worley(P, size, seed=0, chunk=400000):
    """3D cellular noise. Returns F1, F2 (distances in cell units) and a per-cell hash in [0,1)."""
    F1 = np.empty(len(P), np.float32)
    F2 = np.empty(len(P), np.float32)
    H = np.empty(len(P), np.float32)
    offs = np.array([(i, j, k) for i in (-1, 0, 1) for j in (-1, 0, 1) for k in (-1, 0, 1)], np.float32)
    for s in range(0, len(P), chunk):
        Q = P[s:s + chunk].astype(np.float32) / size
        B = np.floor(Q)
        d1 = np.full(len(Q), 9.0, np.float32)
        d2 = np.full(len(Q), 9.0, np.float32)
        hh = np.zeros(len(Q), np.float32)
        for o in offs:
            C = B + o
            h = np.sin(C @ np.array([127.1, 311.7, 74.7], np.float32) + seed) * 43758.5453
            h = h - np.floor(h)
            h2 = np.sin(C @ np.array([269.5, 183.3, 246.1], np.float32) + seed) * 43758.5453
            h2 = h2 - np.floor(h2)
            h3 = np.sin(C @ np.array([113.5, 271.9, 124.6], np.float32) + seed) * 43758.5453
            h3 = h3 - np.floor(h3)
            Fp = C + np.stack([h, h2, h3], 1)
            d = np.linalg.norm(Q - Fp, axis=1)
            m = d < d1
            d2 = np.where(m, d1, np.minimum(d2, d))
            hh = np.where(m, h, hh)
            d1 = np.where(m, d, d1)
        F1[s:s + chunk], F2[s:s + chunk], H[s:s + chunk] = d1, d2, hh
    return F1, F2, H


def region_paint(P, part, noise3):
    """P (N,3) texel positions, part (N,) base part names. Returns col, height, rough, metal, emissive (all (N,..))."""
    N = len(P)
    n1 = noise3(P, 2.2, 11)
    n2 = noise3(P, 4.0, 23)
    n3 = noise3(P, 9.0, 37)
    A1, A2, Ah = worley(P, 0.085, 3)       # plates / spots
    B1, B2, Bh = worley(P, 0.012, 7)       # speckle
    seam = np.clip(1 - (A2 - A1) / 0.10, 0, 1)
    col = np.tile(np.array([0.5, 0.5, 0.5], np.float32), (N, 1))
    h = np.zeros(N, np.float32)
    rough = np.full(N, 0.6, np.float32)
    metal = np.zeros(N, np.float32)
    emis = np.zeros((N, 3), np.float32)
    inn = lambda s: np.isin(part, list(s))  # noqa: E731

    def setc(mask, c):
        col[mask] = c if np.ndim(c) == 1 else c[mask]

    # ---- near-black chitin with plum sheen, plate seams, a few wine plates and star specks
    m = inn(DARK)
    mix = np.clip(0.5 + 0.5 * n1, 0, 1)[:, None]
    base = BLACK * (1 - mix * 0.55) + PLUM * (mix * 0.55)
    base = base * (1 - 0.5 * seam[:, None]) + PLUM * 1.5 * (0.5 * seam[:, None])
    wine_plate = (Ah < 0.17) & (A1 < 0.6)
    bone_patch = (Ah > 0.90) & (A1 < 0.55)
    base = np.where(wine_plate[:, None], WINE_D + (WINE - WINE_D) * np.clip(n2[:, None], 0, 1), base)
    base = np.where(bone_patch[:, None], BONE_D * (1 - 0.3 * seam[:, None]), base)
    star = (B1 < 0.10) & (Bh > 0.80)
    base = np.where(star[:, None], BONE, base)
    col[m] = base[m]
    h[m] = (-0.6 * seam + 0.15 * n3)[m]
    rough[m] = 0.42
    # ---- red carapace: deep wine, darker seams, cream spots with ochre rings
    m = inn(RED)
    wine = WINE * (1 - np.clip(0.5 + 0.5 * n1, 0, 1)[:, None] * 0.6) + WINE2 * (np.clip(0.5 + 0.5 * n1, 0, 1)[:, None] * 0.6)
    wine = wine * (1 - 0.45 * seam[:, None])
    rad = 0.26 + 0.18 * Ah
    spot = (A1 < rad) & inn(SPOTTED)
    ring = (A1 < rad + 0.07) & inn(SPOTTED) & ~spot
    wine = np.where(ring[:, None], OCHRE * 0.9, wine)
    wine = np.where(spot[:, None], BONE * (0.9 + 0.1 * np.clip(A1 / rad, 0, 1))[:, None], wine)
    col[m] = wine[m]
    h[m] = (0.5 * spot + 0.2 * ring - 0.6 * seam)[m]
    rough[m] = 0.35
    # horns: cream growth bands + bone tips
    hm = np.isin(part, ["horn"])
    band = (np.sin(P[:, 2] * 70 + 2 * n2) > 0.82)[:, None]
    col[hm] = np.where(band, BONE_D, wine)[hm]
    # neck is orange-red on the sheet: lift it toward hot wine
    nm = np.isin(part, ["neck"])
    col[nm] = np.where(spot[:, None], BONE, WINE * 1.1)[nm]
    # ---- bone: white plates, soft ochre staining, hairline cracks
    m = inn(BONES)
    bone = BONE * (1 - 0.14 * np.clip(0.5 + 0.5 * n1, 0, 1)[:, None]) + OCHRE * 0.12 * np.clip(n2, 0, 1)[:, None]
    bone = bone * (1 - 0.35 * seam[:, None])
    col[m] = bone[m]
    h[m] = (-0.5 * seam + 0.1 * n3)[m]
    rough[m] = 0.5
    fm = np.isin(part, ["foot"])
    col[fm] = (BONE_D * 0.85 * (1 - 0.3 * seam[:, None]))[fm]
    # ---- skirt / cloth
    stripe = (0.5 + 0.5 * np.sin(P[:, 0] * 260))[:, None]
    def cloth(names, c0, c1, r=0.9):
        mm = np.isin(part, names)
        col[mm] = (c0 * (1 - stripe * 0.35) + c1 * stripe * 0.35 + 0 * np.clip(n3, -1, 1)[:, None] * 0.05)[mm]
        h[mm] = (0.12 * np.sin(P[:, 0] * 260) + 0.1 * n2)[mm]
        rough[mm] = r
    cloth(["strip_olive", "leaf_olive", "fringe_olive", "talisman"], OLIVE, OLIVE_L)
    cloth(["strip_cream"], OLIVE_L, OLIVE)
    cloth(["leaf_dark"], OLIVE_D, OLIVE)
    cloth(["fringe_cream"], TAN, BONE_D)
    cloth(["strip_cord", "belt"], LEATHER, LEATHER * 1.4)
    cloth(["cloth_sash"], WINE, WINE2)
    fold = (0.5 + 0.5 * np.sin(P[:, 0] * 46 + 3 * n2 + 6 * n1))[:, None]
    cloth(["cloak_back", "cloak_tail", "cloak_hood"], CLOAK_D, CLOAK)
    cm = np.isin(part, ["cloak_back", "cloak_tail", "cloak_hood"])
    col[cm] = (CLOAK_D * (1 - fold) + CLOAK * 1.15 * fold)[cm]
    # bandages: tan wraps with dark edge lines
    bm = np.isin(part, ["band_cream"])
    wrap = (0.5 + 0.5 * np.sin(P[:, 2] * 210 + P[:, 0] * 90))[:, None]
    col[bm] = (TAN * (0.78 + 0.22 * wrap) * (1 - 0.1 * np.clip(n2, 0, 1)[:, None]))[bm]
    h[bm] = (0.3 * wrap[:, 0])[bm]
    rough[bm] = 0.9
    # beads + gold + eyes
    setc(np.isin(part, ["beads"]), hx("#a8121f"))
    gm = np.isin(part, ["gold"])
    col[gm] = hx("#d8a63c")
    metal[gm] = 0.85
    rough[gm] = 0.35
    em = np.isin(part, ["eye"])
    col[em] = hx("#ffd24a")
    emis[em] = hx("#ffd24a")
    setc(np.isin(part, ["buckle_disc"]), BLACK)
    # ---- Morrow
    mh = np.isin(part, ["morrow_head"])
    mspot = (A1 < 0.22 + 0.12 * Ah) & mh
    mring = (A1 < 0.34 + 0.12 * Ah) & mh & ~mspot
    mc = BLACK * 1.15 + PLUM * 0.4 * np.clip(n1, 0, 1)[:, None]
    mc = np.where(mring[:, None], OCHRE * 0.55, mc)
    mc = np.where(mspot[:, None], BONE_D, mc)
    col[mh] = mc[mh]
    h[mh] = (0.4 * mspot + 0.2 * mring)[mh]
    rough[mh] = 0.5
    setc(np.isin(part, ["morrow_stud"]), BONE_D)
    setc(np.isin(part, ["morrow_spike", "morrow_pommel"]), TAN)
    setc(np.isin(part, ["morrow_rim"]), BLACK)
    cm2 = np.isin(part, ["morrow_core"])
    col[cm2] = hx("#d9261f")
    emis[cm2] = hx("#e03a22") * 0.35
    sg = np.isin(part, ["morrow_seg0", "morrow_seg1", "morrow_seg2"])
    col[sg] = (hx("#3a2a22") * (0.8 + 0.3 * np.clip(n1, 0, 1)[:, None]))[sg]
    # ice-teal game accents on bone ornaments
    em = np.isin(part, ["tine", "medallion", "buckle"])
    emis[em] = hx("#2fe8d6") * 0.85
    return np.clip(col, 0, 1), h, rough, metal, np.clip(emis, 0, 1)
