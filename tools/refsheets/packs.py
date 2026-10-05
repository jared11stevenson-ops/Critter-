"""Stage 3: palette, materials, head pack, detail sheets, proportion chart, derivation legend, overview + review images.
usage: packs.py <id> [stage ...]   stages: palette materials head details prop overview"""
import sys, os, json, textwrap, datetime
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST, LM_ORDER
import ortho as O

PAPER = BG
GREEN, YELLOW, RED = (60, 170, 70), (235, 190, 40), (210, 50, 50)


def canon_json(cid):
    d = json.load(open(os.path.join(ROOT, "game/canon/canon.json")))["characters"]
    for k, v in d.items():
        if cid in v.get("name", "").lower() or k == cid:
            return v
    return {}


def pdir(cid, *a):
    p = os.path.join(PACKS, cid, *a); os.makedirs(os.path.dirname(p) if "." in os.path.basename(p) else p, exist_ok=True); return p


def paste_fit(cv, im, box, bg=None):
    x0, y0, x1, y1 = box; w, h = x1 - x0, y1 - y0
    s = min(w / im.width, h / im.height); r = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    ox, oy = x0 + (w - r.width) // 2, y0 + (h - r.height) // 2
    if r.mode == "RGBA": cv.paste(r, (ox, oy), r)
    else: cv.paste(r, (ox, oy))
    return (ox, oy, r.width, r.height)


def wrap(d, xy, text, sz=20, width=60, fill=INK, bold=False, gap=4):
    x, y = xy
    for line in textwrap.wrap(text, width):
        d.text((x, y), line, font=font(sz, bold), fill=fill); y += sz + gap
    return y


def load_aligned(cid):
    meta = json.load(open(pdir(cid, "metadata.json")))
    al = {v: (Image.open(os.path.join(PACKS, cid, m["file"])).convert("RGBA"), m["axis_x_px"]) for v, m in meta["views"].items() if m.get("aligned", True)}
    return al, meta


# ---------------------------------------------------------------- palette
def sample_hex(im, fx, fy, r=7):
    W, H = im.size; x, y = int(fx * W), int(fy * H)
    a = np.asarray(im.crop((max(x - r, 0), max(y - r, 0), x + r, y + r)).convert("RGBA")).reshape(-1, 4)
    a = a[a[:, 3] > 200]
    if not len(a): return None
    m = np.median(a[:, :3], 0).astype(int); return "#%02x%02x%02x" % tuple(m)


def kmeans_palette(cid, k=10):
    from scipy.cluster.vq import kmeans2
    px = []
    for v in CAST[cid]["views"]:
        im = Image.open(os.path.join(CACHE, cid, f"cut_{v}.png")).convert("RGBA"); a = np.asarray(im).reshape(-1, 4); a = a[a[:, 3] > 230][:, :3]
        rng = np.random.default_rng(1); px.append(a[rng.choice(len(a), min(len(a), 40000), replace=False)])
    px = np.vstack(px).astype(np.float32); np.random.seed(2)
    cen, lab = kmeans2(px, k, minit="++", seed=2); share = np.bincount(lab, minlength=k) / len(lab)
    o = np.argsort(-share)
    return [("#%02x%02x%02x" % tuple(int(x) for x in cen[i]), float(share[i])) for i in o]


def stage_palette(cid):
    c = CAST[cid]; cj = canon_json(cid)
    ms = os.path.join(ROOT, "design/model_sheets", cid, "palette.json")
    ms_pal = json.load(open(ms)) if os.path.exists(ms) else {}
    km = kmeans_palette(cid)
    data = dict(art_sampled_kmeans=[dict(hex=h, share=round(s, 3)) for h, s in km], sheet_palette_json=ms_pal, game_palette_canon_json=cj.get("palette", []),
                note="game palette = game/canon/canon.json characters.%s.palette (the colours UI/FX use); art_sampled = k-means over the cut views of this pack." % c["name"])
    json.dump(data, open(pdir(cid, "palette.json"), "w"), indent=1)
    # swatch image
    W = 1400; cv = Image.new("RGB", (W, 520), PAPER); d = ImageDraw.Draw(cv)
    d.text((20, 12), f"{c['name']} - sampled art palette (share of pixels)", font=font(26), fill=INK)
    for i, (h, s) in enumerate(km):
        x = 20 + i * 136; d.rectangle((x, 60, x + 124, 190), fill=h, outline=INK); d.text((x, 196), h, font=font(18), fill=INK); d.text((x, 220), f"{s*100:.0f}%", font=font(16, False), fill=INK)
    d.text((20, 270), "Game palette (canon.json) - used by UI / FX / portraits frames", font=font(22), fill=INK)
    for i, h in enumerate(cj.get("palette", [])):
        x = 20 + i * 136; d.rectangle((x, 310, x + 124, 410), fill=h, outline=INK); d.text((x, 416), h, font=font(18), fill=INK)
    d.text((20, 460), "Rule: base colours for PBR come from the art-sampled row; the game palette is for accents/UI and must not be used to recolour the model.", font=font(15, False), fill=INK)
    cv.save(pdir(cid, "swatches", f"{cid}_palette.png"), optimize=True)
    return km


# ---------------------------------------------------------------- materials
def stage_materials(cid):
    c = CAST[cid]; mats = c.get("materials", [])
    out = []
    ims = {v: Image.open(os.path.join(CACHE, cid, f"cut_{v}.png")).convert("RGBA") for v in c["views"]}
    for i, m in enumerate(mats):
        v, fx, fy = m["sample"]; h = m.get("hex") or sample_hex(ims[v], fx, fy) or "#808080"
        out.append(dict(m, hex=h, n=i + 1))
    json.dump(out, open(pdir(cid, "materials.json"), "w"), indent=1)
    # figure: view with numbered pins + table
    vkey = c.get("material_view", "side") if c.get("material_view", "side") in ims else list(ims)[0]
    base = ims[vkey]; H = 1500; s = H / base.height; base = base.resize((int(base.width * s), H), Image.LANCZOS)
    rows = 34 + 30 * len(out); Wt = 1500; cv = Image.new("RGB", (base.width + Wt + 60, max(H + 80, rows + 120)), PAPER); d = ImageDraw.Draw(cv)
    d.text((20, 15), f"{c['name']} - material callouts ({vkey} view)  rough = roughness, met = metalness, emi = emissive strength", font=font(24), fill=INK)
    cv.paste(base, (20, 60), base)
    for m in out:
        v, fx, fy = m["sample"]
        if v != vkey or m.get("hex"): continue
        x, y = 20 + fx * base.width, 60 + fy * H
        d.ellipse((x - 16, y - 16, x + 16, y + 16), fill=(255, 255, 255), outline=(200, 0, 0), width=3); d.text((x - 8 if m["n"] < 10 else x - 12, y - 11), str(m["n"]), font=font(20), fill=(200, 0, 0))
    x0 = base.width + 50; y = 70
    for m in out:
        d.rectangle((x0, y, x0 + 36, y + 36), fill=m["hex"], outline=INK); d.text((x0 + 48, y - 2), f'{m["n"]}. {m["name"]}  [{m["cls"]}]  {m["hex"]}', font=font(19), fill=INK)
        d.text((x0 + 48, y + 20), f'rough {m["rough"]:.2f}  met {m["metal"]:.2f}  emi {m.get("emi", 0):.1f}   {m.get("note","")}', font=font(15, False), fill=(70, 55, 50)); y += 62
    if c.get("layers"):
        y += 20; d.text((x0, y), "Costume / layer order (inner -> outer)", font=font(21), fill=INK); y += 32
        for i, l in enumerate(c["layers"]): y = wrap(d, (x0, y), f"{i+1}. {l}", 17, 90, bold=False)
    cv = cv.crop((0, 0, cv.width, max(y + 40, H + 80)))
    cv.save(pdir(cid, "details", f"{cid}_materials.jpg"), quality=92)
    return out


# ---------------------------------------------------------------- proportions
def stage_prop(cid):
    c = CAST[cid]; canon = O.canon_fracs(c); H = c["height_m"]; m = lambda k: (1 - canon[k]) * H
    head = m("crown") - m("chin"); body = m("crown")
    rows = [("Total height (canon)", f"{H:.3f} m  ({c['height_note']})"), ("Body height (ground to crown/top of head)", f"{body:.3f} m"),
            ("Head height (crown to chin)", f"{head:.3f} m"), ("Heads tall (body / head)", f"{body/head:.1f}"),
            ("Neck (chin to neck base)", f"{m('chin')-m('neck'):.3f} m"), ("Torso (neck base to crotch)", f"{m('neck')-m('crotch'):.3f} m"),
            ("Arm (shoulder to wrist)", f"{m('shoulder')-m('wrist'):.3f} m  = {100*(m('shoulder')-m('wrist'))/H:.0f}% of height"),
            ("Upper arm (shoulder to elbow)", f"{m('shoulder')-m('elbow'):.3f} m"), ("Forearm+hand (elbow to wrist)", f"{m('elbow')-m('wrist'):.3f} m"),
            ("Leg (crotch to ground)", f"{m('crotch'):.3f} m  = {100*m('crotch')/H:.0f}% of height"), ("Thigh (crotch to knee)", f"{m('crotch')-m('knee'):.3f} m"),
            ("Shin (knee to ankle)", f"{m('knee')-m('ankle'):.3f} m"), ("Ankle height", f"{m('ankle'):.3f} m"),
            ("Leg : torso ratio", f"{m('crotch')/(m('neck')-m('crotch')):.2f}")]
    json.dump(dict(rows=rows, landmarks_m={k: round(m(k), 3) for k in LM_ORDER}, source=c["lm_src"]), open(pdir(cid, "proportions.json"), "w"), indent=1)
    cv = Image.new("RGB", (1500, 100 + 40 * len(rows) + 120), PAPER); d = ImageDraw.Draw(cv)
    d.text((20, 15), f"{c['name']} - proportion chart (measured from the sheet art)", font=font(28), fill=INK)
    for i, (a, b) in enumerate(rows):
        y = 70 + i * 40
        if i % 2 == 0: d.rectangle((10, y - 4, 1490, y + 32), fill=(240, 232, 215))
        d.text((24, y), a, font=font(21, False), fill=INK); d.text((620, y), b, font=font(21), fill=INK)
    y = 70 + len(rows) * 40 + 10; d.text((24, y), "Landmark source: " + c["lm_src"], font=font(16, False), fill=(90, 70, 60))
    d.text((24, y + 26), "Landmarks are measured/read to +-1-1.5% of height. Views are NOT perfect orthographics where flagged in metadata.json (orthographic:false).", font=font(16, False), fill=(90, 70, 60))
    cv.save(pdir(cid, "ortho", f"{cid}_proportion_chart.png"), optimize=True)
    return rows


# ---------------------------------------------------------------- head pack
def head_crop(aligned, canon, view, pad=0.02):
    """crop head rows (top .. chin+) from an aligned 4096 view; width = alpha extent in those rows."""
    im, ax = aligned[view]; H = O.GROUND - O.TOP
    y0 = O.TOP; y1 = int(O.TOP + (canon["chin"] + 0.035) * H)
    a = np.asarray(im.getchannel("A"))[y0:y1] > 30
    cols = np.where(a.any(0))[0]
    return im.crop((max(cols.min() - 20, 0), y0 - 20, min(cols.max() + 20, im.width), y1)), (cols.min() - 20, y0 - 20), y0, y1


def stage_head(cid):
    c = CAST[cid]; aligned, meta = load_aligned(cid); canon = O.canon_fracs(c); H = O.GROUND - O.TOP; out = pdir(cid, "head")
    crops = {}
    for v in aligned:
        cr, off, y0, y1 = head_crop(aligned, canon, v); crops[v] = (cr, off)
        save_art(cr, os.path.join(out, f"{cid}_head_{v}.png"))
    # turnaround on shared rows (same scale as ortho)
    gap = 80; hh = max(cr.height for cr, _ in crops.values()); W = sum(cr.width + gap for cr, _ in crops.values()) + 200
    for guides in (False, True):
        cv = Image.new("RGB", (W, hh + 120), PAPER); d = ImageDraw.Draw(cv); x = 60; ypos = {}
        for v, (cr, off) in crops.items():
            cv.paste(cr, (x, 70), cr); d.text((x, 20), v.upper(), font=font(30), fill=INK); x += cr.width + gap
        if guides:
            for k in ("top", "crown", "eyes", "chin"):
                y = 70 + (O.TOP + canon[k] * H) - (O.TOP - 20) ; d.line((20, y, W - 20, y), fill=O.LM_COL[k], width=2); d.text((W - 190, y - 22), k, font=font(20), fill=O.LM_COL[k])
        # note: crops start at y = TOP-20, so row for fraction f is (TOP + f*H) - (TOP-20)
        cv.save(os.path.join(out, f"{cid}_head_turnaround{'_landmarks' if guides else ''}.jpg"), quality=92)
    # panels (face close-ups / eye detail): copy cached x4 panels
    exps = []
    cdir = os.path.join(CACHE, cid)
    for p in sorted(os.listdir(cdir)) if os.path.isdir(cdir) else []:
        if not p.startswith("panel_"): continue
        n = p[6:-4]; im = Image.open(os.path.join(cdir, p))
        if n.startswith("expr_"): exps.append((n[5:], im))
        elif n in c.get("head_panels", ["head_details", "eye_detail", "face_closeup"]): save_art(im, os.path.join(out, f"{cid}_{n}.png"))
    # expression sheet: uniform tiles
    order = c["expressions"]; tiles = [(e, dict(exps).get(e)) for e in order if dict(exps).get(e) is not None]
    if not tiles:  # fall back to game portraits
        pd = os.path.join(ROOT, "game/art/portraits", cid)
        for e in order:
            f = os.path.join(pd, e + ".png")
            if os.path.exists(f): tiles.append((e, Image.open(f).convert("RGBA")))
    if tiles:
        T = 520; cols = min(4, len(tiles)); rows = (len(tiles) + cols - 1) // cols
        cv = Image.new("RGB", (cols * (T + 30) + 30, rows * (T + 80) + 90), PAPER); d = ImageDraw.Draw(cv)
        d.text((30, 20), f"{c['name']} - expressions (sheet art, x4 upscaled, uniform tiles; first = neutral/default)", font=font(26), fill=INK)
        for i, (e, im) in enumerate(tiles):
            x, y = 30 + (i % cols) * (T + 30), 80 + (i // cols) * (T + 80)
            paste_fit(cv, im.convert("RGB") if im.mode != "RGBA" else im, (x, y, x + T, y + T)); d.rectangle((x, y, x + T, y + T), outline=INK); d.text((x, y + T + 8), e.upper(), font=font(24), fill=INK)
        cv.save(os.path.join(out, f"{cid}_expressions.jpg"), quality=92)
    # callouts on the face close-up panel
    fp = os.path.join(cdir, f"panel_{c.get('callout_panel', 'head_details')}.png")
    if os.path.exists(fp) and c.get("callouts"):
        im = Image.open(fp).convert("RGB"); W0, H0 = im.size; n = len(c["callouts"]); T = 560
        cv = Image.new("RGB", (T * (n + 1) + 40 * (n + 2), T + 160), PAPER); d = ImageDraw.Draw(cv); d.text((40, 15), f"{c['name']} - eye / nose / mouth callouts (from the sheet face panel)", font=font(26), fill=INK)
        big = im.copy(); ds = ImageDraw.Draw(big)
        for i, (nm, (a, b, c2, d2)) in enumerate(c["callouts"].items()):
            ds.rectangle((a * W0, b * H0, c2 * W0, d2 * H0), outline=(220, 40, 40), width=max(2, W0 // 150)); ds.text((a * W0 + 4, b * H0 + 2), str(i + 1), fill=(220, 40, 40), font=font(max(16, W0 // 20)))
        paste_fit(cv, big, (40, 70, 40 + T, 70 + T + 40))
        for i, (nm, (a, b, c2, d2)) in enumerate(c["callouts"].items()):
            x = 40 + (i + 1) * (T + 40); crop = im.crop((int(a * W0), int(b * H0), int(c2 * W0), int(d2 * H0))); paste_fit(cv, crop, (x, 70, x + T, 70 + T + 40)); d.text((x, 70 + T + 50), f"{i+1}. {nm}", font=font(22), fill=INK)
        cv.save(os.path.join(out, f"{cid}_face_callouts.jpg"), quality=92)
    return crops


# ---------------------------------------------------------------- detail sheets
def stage_details(cid):
    c = CAST[cid]; out = pdir(cid, "details"); cdir = os.path.join(CACHE, cid)
    items = []
    for p, (box, bg) in c.get("sheet_panels", {}).items():
        if p.startswith("expr_") or p in c.get("head_panels", ["head_details", "eye_detail", "face_closeup", "palette_strip"]): continue
        f = os.path.join(cdir, f"panel_{p}.png")
        if os.path.exists(f): items.append((p.replace("_", " "), Image.open(f).convert("RGBA")))
    # crops from the aligned views (hands, feet) - fractions of the aligned view image, same scale as the ortho sheets
    for name, (v, fx0, fy0, fx1, fy1) in c.get("view_details", {}).items():
        f = os.path.join(cdir, f"cut_{v}.png")
        if not os.path.exists(f): continue
        im = Image.open(f).convert("RGBA"); W, H = im.size
        cr = im.crop((int(fx0 * W), int(fy0 * H), int(fx1 * W), int(fy1 * H)))
        if max(cr.size) > 1400: cr = cr.resize((int(cr.width * 1400 / max(cr.size)), int(cr.height * 1400 / max(cr.size))), Image.LANCZOS)
        items.append((name.replace("_", " "), cr))
    for n, im in items: save_art(im, os.path.join(out, f"{cid}_panel_{n.replace(' ', '_')}.png"))
    if not items: return
    T = 640; cols = 4; rows = (len(items) + cols - 1) // cols
    cv = Image.new("RGB", (cols * (T + 30) + 30, rows * (T + 70) + 90), PAPER); d = ImageDraw.Draw(cv)
    d.text((30, 20), f"{c['name']} - detail sheet: hands, feet, costume, props (original art, x4 upscaled)", font=font(26), fill=INK)
    for i, (n, im) in enumerate(items):
        x, y = 30 + (i % cols) * (T + 30), 80 + (i // cols) * (T + 70)
        cv.paste(Image.new("RGB", (T, T), (244, 238, 224)), (x, y)); paste_fit(cv, im, (x + 8, y + 8, x + T - 8, y + T - 8)); d.rectangle((x, y, x + T, y + T), outline=INK); d.text((x, y + T + 8), n.upper(), font=font(22), fill=INK)
    cv.save(os.path.join(out, f"{cid}_detail_sheet.jpg"), quality=90)


if __name__ == "__main__":
    cid = sys.argv[1]; st = sys.argv[2:] or ["palette", "materials", "prop", "head", "details"]
    for s in st:
        globals()["stage_" + s](cid); print("done", cid, s, flush=True)
