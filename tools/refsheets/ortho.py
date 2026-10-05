"""Stage 2: align every view on shared landmark rows at one scale; export 4096-px-tall transparent PNGs + metadata for Blender."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST, LM_ORDER

CANVAS_H = 4096
TOP, GROUND = 96, 4096 - 96          # silhouette top / sole rows on the 4096 canvas
LM_COL = {"top": (150, 40, 40), "crown": (170, 60, 50), "eyes": (200, 90, 30), "chin": (190, 130, 20), "neck": (150, 150, 20), "shoulder": (60, 140, 40),
          "elbow": (30, 140, 120), "wrist": (30, 120, 170), "waist": (60, 80, 190), "crotch": (110, 60, 190), "knee": (170, 50, 170), "ankle": (150, 60, 100), "ground": (30, 30, 30)}


def canon_fracs(c):
    """canonical landmark fractions (top=0, ground=1): mean over views, except aruun (json metres)."""
    lm = c["lm"]; out = {}
    if "canon_m" in c:
        cm = c["canon_m"]; H = c["height_m"]; out = {k: 1 - cm[k] / H for k in cm}
        for k in LM_ORDER:                     # keys the json lacks: mean of the views
            if k not in out: out[k] = float(np.mean([lm[v][k] for v in lm if k in lm[v]]))
        out["eyes"] = out["crown"] + 0.33 * (out["chin"] - out["crown"])
        return out
    for k in LM_ORDER:
        vals = [lm[v][k] for v in lm if k in lm[v]]
        out[k] = float(np.mean(vals))
    return out


def load_cut(cid, v):
    p = os.path.join(CACHE, cid, f"cut_{v}_up.png")
    if not os.path.exists(p): p = os.path.join(CACHE, cid, f"cut_{v}.png")
    return Image.open(p).convert("RGBA")


def warp_rows(img, src_fr, dst_fr, scale_ref=None):
    """img: trimmed RGBA; src_fr/dst_fr landmark fractions. Returns RGBA of height GROUND-TOP, uniform horizontal scale, rows remapped piecewise-linearly."""
    H = GROUND - TOP
    s = H / img.height
    big = img.resize((max(1, round(img.width * s)), H), Image.LANCZOS)
    a = np.asarray(big).astype(np.float32); a[..., :3] *= a[..., 3:] / 255.0      # premultiply
    keys = [k for k in LM_ORDER if k in src_fr and k in dst_fr]
    sx = np.array([src_fr[k] for k in keys]) * H; dx = np.array([dst_fr[k] for k in keys]) * H
    # enforce monotonic
    for i in range(1, len(sx)):
        sx[i] = max(sx[i], sx[i - 1] + 1); dx[i] = max(dx[i], dx[i - 1] + 1)
    sx[-1] = H; dx[-1] = H; sx[0] = 0; dx[0] = 0
    rows = np.interp(np.arange(H), dx, sx)
    r0 = np.clip(np.floor(rows).astype(int), 0, H - 1); r1 = np.clip(r0 + 1, 0, H - 1); w = (rows - r0)[:, None, None]
    o = a[r0] * (1 - w) + a[r1] * w
    al = o[..., 3:4]
    o[..., :3] = np.where(al > 1, o[..., :3] / np.maximum(al, 1) * 255.0, 0)
    return Image.fromarray(np.clip(o, 0, 255).astype(np.uint8), "RGBA")


def body_axis(img, fr):
    """x of the body centreline: centre of the alpha extent between neck and crotch rows of the aligned image."""
    H = GROUND - TOP
    a = np.asarray(img.getchannel("A")) > 40
    r0, r1 = int(fr["neck"] * H), int(fr["crotch"] * H)
    cols = np.where(a[r0:r1].any(0))[0]
    return float((cols.min() + cols.max()) / 2) if len(cols) else img.width / 2


def run(cid):
    c = CAST[cid]; canon = canon_fracs(c); out = os.path.join(PACKS, cid, "ortho"); os.makedirs(out, exist_ok=True)
    ppm = (GROUND - TOP) / c["height_m"]; meta = dict(id=cid, height_m=c["height_m"], px_per_m=ppm, canvas_h=CANVAS_H, ground_y=GROUND, top_y=TOP,
                                                    landmarks_m={k: round((1 - canon[k]) * c["height_m"], 4) for k in LM_ORDER}, views={})
    aligned = {}
    for v, s in c["views"].items():
        if not s.get("lineup", True):                         # hero / variant / top-bottom art: kept at its own x4 resolution, not aligned
            h = trim(load_cut(cid, v)); save_art(h, os.path.join(out, f"{cid}_{v}_x4.png"))
            meta["views"][v] = dict(file=f"ortho/{cid}_{v}_x4.png", width_px=h.width, height_px=h.height, pose=s.get("pose", ""), orthographic=False, aligned=False)
            continue
        im = trim(load_cut(cid, v)); fr = c["lm"][v]
        if s.get("flip"):
            from PIL import ImageOps
            im = ImageOps.mirror(im)
        al = warp_rows(im, fr, canon)
        bb = al.getchannel("A").point(lambda x: 255 if x > 20 else 0).getbbox(); m = 64
        ax = body_axis(al, canon)
        x0 = max(bb[0] - m, 0); x1 = min(bb[2] + m, al.width)
        cv = Image.new("RGBA", (x1 - x0, CANVAS_H), (0, 0, 0, 0)); cv.paste(al, (-x0, TOP))
        aligned[v] = (cv, ax - x0)
        p = os.path.join(out, f"{cid}_{v}_4096.png"); save_art(cv, p)
        meta["views"][v] = dict(file=f"ortho/{cid}_{v}_4096.png", width_px=cv.width, height_px=CANVAS_H, axis_x_px=round(ax - x0, 1), ground_y_px=GROUND,
                                pose=s.get("pose", ""), orthographic=bool(s.get("ortho", True)), source_landmarks=fr)
        print(cid, v, cv.size, os.path.getsize(p) // 1024, "KB", flush=True)
    json.dump(meta, open(os.path.join(PACKS, cid, "metadata.json"), "w"), indent=1)
    return aligned, canon, meta


def lineup(cid, aligned, canon, meta, guides=True, height=1400, labels=True):
    """Side-by-side lineup on shared landmark rows (ground and top at the same y)."""
    c = CAST[cid]; f = height / CANVAS_H; items = []
    for v, (im, ax) in aligned.items():
        if ax is None: continue
        items.append((v, im.resize((max(1, int(im.width * f)), height), Image.LANCZOS), ax * f))
    gap = 90; margin_l = 150
    W = margin_l + sum(i[1].width + gap for i in items) + 160; Himg = height + 150
    cv = Image.new("RGB", (W, Himg), BG); d = ImageDraw.Draw(cv); x = margin_l; pos = {}
    pos_y = lambda fr: 60 + (TOP + fr * (GROUND - TOP)) * f
    if guides:
        for k in LM_ORDER:
            y = pos_y(canon[k]); col = LM_COL[k]
            d.line((margin_l - 30, y, W - 150, y), fill=col, width=1)
            hm = (1 - canon[k]) * c["height_m"]
            d.text((W - 145, y - 7), f"{k} {hm:.2f} m", fill=col, font=font(15))
            d.text((10, y - 7), f"{hm:.2f}", fill=col, font=font(14))
    for v, im, ax in items:
        cv.paste(im, (x, 60), im)
        pos[v] = (x, ax)
        d.line((x + ax, 60, x + ax, 60 + height), fill=(120, 120, 120), width=1)
        if labels: d.text((x + 10, height + 70), v.upper(), fill=INK, font=font(26))
        x += im.width + gap
    return cv


def main(cid):
    al, canon, meta = run(cid)
    lineup(cid, al, canon, meta, guides=False, height=2048).save(os.path.join(PACKS, cid, "ortho", f"{cid}_ortho_lineup_clean.jpg"), quality=90)
    lineup(cid, al, canon, meta, guides=True, height=2048).save(os.path.join(PACKS, cid, "ortho", f"{cid}_ortho_lineup_landmarks.jpg"), quality=90)


if __name__ == "__main__":
    main(sys.argv[1])
