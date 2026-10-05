"""Writes QUESTIONS.md / STYLE.md per pack and design/reference_packs/INDEX.md (status table preserved for Lead-set statuses)."""
import sys, os, re, json, datetime
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST, LM_ORDER
import packs as P


def line_weight(cid):
    from scipy import ndimage
    ws = []
    for v in CAST[cid]["views"]:
        im = Image.open(os.path.join(CACHE, cid, f"cut_{v}.png")).convert("RGBA"); a = np.asarray(im)
        sc = 1500 / im.height
        small = Image.fromarray(a).resize((int(im.width * sc), 1500), Image.LANCZOS); a = np.asarray(small).astype(np.float32)
        lum = a[..., :3].mean(-1); dark = (lum < 55) & (a[..., 3] > 200)
        dt = ndimage.distance_transform_edt(dark); mx = ndimage.maximum_filter(dt, 3)
        ridge = dt[(dt == mx) & (dt > 0.5) & (dt <= 7)]
        if len(ridge): ws.append(2 * float(np.median(ridge)))
    return float(np.mean(ws)) if ws else 0.0     # px at 1500-px-tall figure


def write_questions(cid):
    c = CAST[cid]; q = c.get("questions", [])
    t = [f"# {c['name']} - open questions for the Lead (reference pack)", "", "Nothing below was resolved silently; each item is a design ambiguity or an unknown that a modeller would otherwise have to invent. Answer inline (or tell the artist) and the pack will be revised.", ""]
    for i, x in enumerate(q): t.append(f"{i+1}. {x}")
    open(P.pdir(cid, "QUESTIONS.md"), "w").write("\n".join(t) + "\n")


def write_style(cid):
    c = CAST[cid]; st = c.get("style", {}); lw = line_weight(cid); H = c["height_m"]
    km = json.load(open(P.pdir(cid, "palette.json")))["art_sampled_kmeans"][:6]
    t = [f"# {c['name']} - style guide", "", "Everything here is read off the original sheet art (see ortho/ and head/); `[measured]` = computed by tools/refsheets, the rest is the artist's reading and is the checklist for matching the look in 3D.", "",
         "## Line weight", f"- [measured] outline stroke is about {lw:.1f} px on a 1500-px-tall figure = {100*lw/1500:.2f}% of height = {lw/1500*H*1000:.0f} mm at canon height.",
         f"- {st.get('line','Variable-weight black ink contour, heavier on the outer silhouette, hairline on interior folds/plates.')}", "",
         "## Colour blocking", f"- [measured] dominant colours (share of opaque pixels): " + ", ".join(f"{x['hex']} {x['share']*100:.0f}%" for x in km),
         f"- {st.get('color','')}", "", "## Shading style", f"- {st.get('shading','Flat cel/paint blocks: 2-3 tones per material, hard-edged shadow shapes, small painted specular ovals; no soft gradients except on translucent parts.')}", "- For 3D: use a toon/stepped ramp or very low-frequency baked AO; do NOT bake photographic soft shadows into albedo.", "",
         "## Shape language / silhouette", f"- {st.get('shape','')}", "", "## Design locks (must never change)"]
    for x in st.get("locks", ["(none recorded)"]): t.append(f"- {x}")
    t += ["", "## Views and authority", "- Proportions and heights: side/back views (orthographic where marked in metadata.json). Costume/colour: all views. 3/4 'front' views are NOT orthographic - never snap to them for widths without checking the side/back."]
    open(P.pdir(cid, "STYLE.md"), "w").write("\n".join(t) + "\n")


def write_review(cid):
    from scipy import ndimage
    c = CAST[cid]; meta = json.load(open(P.pdir(cid, "metadata.json")))
    t = [f"# {c['name']} - artist's review of this pack against the originals", "", f"Pack built {datetime.date.today()}. Critique written after opening every output image next to the source sheet.", "", "## Findings"]
    t += [f"- {x}" for x in c.get("review", ["(not yet reviewed)"])]
    t += ["", "## Automatic checks (tools/refsheets/docs.py)", "| view | size px | alpha components >200px | specks <=200px | pose |", "|---|---|---|---|---|"]
    for v, m in meta["views"].items():
        im = Image.open(os.path.join(PACKS, cid, m["file"])).convert("RGBA"); a = np.asarray(im.getchannel("A")) > 40
        lab, n = ndimage.label(a); sz = np.bincount(lab.ravel())[1:] if n else np.array([])
        t.append(f"| {v} | {im.width}x{im.height} | {int((sz > 200).sum())} | {int((sz <= 200).sum())} | {m['pose']}{'' if m['orthographic'] else ' (NOT ortho)'} |")
    t += ["", "Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips."]
    open(P.pdir(cid, "REVIEW.md"), "w").write("\n".join(t) + "\n")


def write_index(status):
    path = os.path.join(PACKS, "INDEX.md"); old = {}
    if os.path.exists(path):
        for l in open(path).read().splitlines():
            m = re.match(r"\|\s*\[?([a-z_]+)\]?.*?\|\s*(draft|ready for review|approved|changes requested)\s*\|\s*([^|]*)\|\s*([^|]*)\|", l)
            if m: old[m.group(1)] = (m.group(2), m.group(3).strip(), m.group(4).strip())
    ids = ["aruun", "cigarra", "mara", "dexter", "zephyr", "bramvex", "scarlith", "solmara", "mollusk", "nerit", "nyxaris", "pharilux"]
    rows = []
    for i in ids:
        mine = status.get(i, "not started"); st, date, note = mine, str(datetime.date.today()) if i in status else "", ""
        if i in old and old[i][0] in ("approved", "changes requested"): st, date, note = old[i]
        elif i in old and i not in status and old[i][0] in ("draft", "ready for review"): st, date, note = old[i]
        elif i in old: note = old[i][2]
        rows.append(f"| [{i}]({i}/review/{i}_pack_overview.png) | {st} | {date} | {note} |")
    t = ["# Reference packs - index", "", "Only the Lead sets `approved` / `changes requested` (after the creator answers). The artist sets `draft` / `ready for review`. **No pack is modelling authority until it is `approved`.**", "",
         "| character | status | date | creator's notes |", "|---|---|---|---|"] + rows + ["", open(os.path.join(os.path.dirname(__file__), "index_sources.md")).read()]
    open(path, "w").write("\n".join(t))


if __name__ == "__main__":
    for cid in sys.argv[1:]:
        write_questions(cid); write_style(cid); write_review(cid); print("docs", cid)
