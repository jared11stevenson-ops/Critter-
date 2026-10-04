#!/usr/bin/env python3
"""Validates Red Reaches NPC content: game/canon/npcs/*.json (+ _ambient), their dialogue files (rrn_*.json), quest/act/event/site
references, Ledger specs/tags/records, flags, portrait expressions, codex entries. Exit 1 on errors.
Run: python3 tools/validate_npcs.py   (also called by tools/validate.sh)"""
import json, os, sys, re, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
C = os.path.join(ROOT, "game", "canon")
D = os.path.join(ROOT, "game", "narrative", "dialogue")
errors = []
SPEC_KEYS = {"all", "any", "not", "event", "none", "opinion_min", "promise", "flag", "tally_min", "stage", "rival"}
FILTER_KEYS = {"type", "actor", "target", "entity", "region", "tag", "tags_any", "tags_all", "since", "min_weight", "data_eq", "count_min"}
PORTRAIT_VOCAB = {"default", "neutral", "warm", "wary", "tired", "amused", "stern", "grave", "curious", "surprised"}
ENGINE_FLAGS = {"rr_complete", "boulder_broken", "boss_defeated", "combo_unlocked", "has_specimen", "briefed", "first_scan_done"}
BANNED = re.compile(r"\b(my pet|pets?|owner|owned|belongs to me|my property|livestock)\b", re.I)
NPC_KEYS = ["id", "name", "species", "role", "faction", "sapient", "personality", "contradiction", "voice", "portrait_expressions",
            "schedule", "barks", "look", "quests", "records", "dialogue"]
DLG_KINDS = ["meet", "repeat", "quest", "turnin", "react"]
WHEN = {"dawn", "day", "dusk", "night"}


def err(m): errors.append(m)


def load(p):
    try:
        return json.load(open(p, encoding="utf8"))
    except Exception as ex:
        err(f"{os.path.relpath(p, ROOT)}: cannot parse ({ex})"); return {}


def spec(s, w):
    if not isinstance(s, dict):
        err(f"{w}: spec must be an object"); return
    for k, v in s.items():
        if k not in SPEC_KEYS: err(f"{w}: unknown spec key '{k}'"); continue
        if k in ("all", "any"):
            for i, x in enumerate(v): spec(x, f"{w}.{k}[{i}]")
        elif k == "not": spec(v, w + ".not")
        elif k in ("event", "none"):
            for fk in v:
                if fk not in FILTER_KEYS: err(f"{w}: unknown filter key '{fk}'")


rules = load(os.path.join(C, "ledger_rules.json"))
canon = load(os.path.join(C, "canon.json"))
reg = load(os.path.join(C, "regions", "red_reaches.json"))
codex = load(os.path.join(C, "codex.json")).get("entries", {})
npcf = load(os.path.join(C, "npcs", "red_reaches.json"))
ambf = load(os.path.join(C, "npcs", "red_reaches_ambient.json"))

# vocab
tags = set()
for v in rules.get("values", {}).values(): tags |= set(v)
tags |= set(rules.get("summaries", {}))
tags |= {"combat", "kill", "social", "discovery", "curiosity", "evidence", "trust", "containment", "promise", "promise_made", "bond",
         "rival", "return", "descent", "casualty", "nonviolent", "spared", "kill_dominion", "kill_wildlife", "harm_wildlife",
         "calmed_wildlife", "protect_weak", "stewardship", "burden", "braced_structure", "extraction", "dominion_favor", "boss"}
for q in reg.get("side_quests", []):
    for c in q["choices"]:
        for r in c.get("records", []): tags |= set(r.get("tags", []))
for e in reg.get("descent_events", []):
    for c in e.get("choices", []):
        for r in c.get("records", []): tags |= set(r.get("tags", []))
flags = set(ENGINE_FLAGS) | set(rules.get("flag_events", {}))
for q in reg.get("side_quests", []):
    for c in q["choices"]:
        if c.get("sets_flag"): flags.add(c["sets_flag"])
for a in reg.get("story", {}).get("acts", []):
    flags.add(a.get("completes_flag"))
    for v in a.get("variants", []): flags.add(v.get("sets_flag"))
quest_ids = {q["id"]: q for q in reg.get("side_quests", [])}
act_ids = {a["id"] for a in reg.get("story", {}).get("acts", [])}
event_ids = {e["id"] for e in reg.get("descent_events", [])}
site_ids = {s["id"] for s in reg.get("sites", [])}
stations = {l["id"] for l in reg.get("layers", [])} | {l["id"] for l in reg.get("landmarks", [])}
for sp in reg.get("spokes", []):
    stations |= {sp["id"], sp["hub"]}
chars = set(canon.get("characters", {}))
char_expr = {c: set(v.get("expressions", [])) | {"default"} for c, v in canon.get("characters", {}).items()}

npcs = {n.get("id"): n for n in npcf.get("npcs", [])}
if len(npcs) != len(npcf.get("npcs", [])): err("npcs: duplicate ids")
if not 10 <= len(npcs) <= 14: err(f"npcs: expected 10-14 NPCs, found {len(npcs)}")

# dialogue pass 1: collect flags set by NPC dialogues
dfiles = {}
for n in npcs.values():
    for k in DLG_KINDS:
        i = n.get("dialogue", {}).get(k)
        p = os.path.join(D, f"{i}.json")
        if not i or not os.path.exists(p):
            err(f"npc {n['id']}: dialogue '{k}' missing file ({i})"); continue
        dfiles[i] = load(p)
        for ln in dfiles[i].get("lines", []):
            for src in [ln] + ln.get("choice", []):
                if isinstance(src, dict) and isinstance(src.get("set"), dict): flags |= set(src["set"])


def check_flag(f, w):
    if f.startswith("ledger_"):
        if f[7:] not in tags: err(f"{w}: derived flag '{f}' names unknown tag '{f[7:]}'")
    elif f not in flags:
        err(f"{w}: unknown flag '{f}'")


def check_gate(g, w):
    for k in ("if", "if_not"):
        if k in g: check_flag(str(g[k]), w)


for nid, n in npcs.items():
    w = f"npc {nid}"
    for k in NPC_KEYS:
        if k not in n: err(f"{w}: missing '{k}'")
    if n.get("sapient") is not True: err(f"{w}: must be a sapient person (sapient: true)")
    for fld in ("personality", "contradiction", "voice", "role", "species", "faction"):
        if BANNED.search(str(n.get(fld, ""))): err(f"{w}.{fld}: ownership language")
    ex = n.get("portrait_expressions", [])
    if "default" not in ex: err(f"{w}: portrait_expressions must include 'default'")
    for e in ex:
        if e not in PORTRAIT_VOCAB: err(f"{w}: unknown portrait expression '{e}'")
    look = n.get("look", {})
    for c in look.get("palette", []):
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", c): err(f"{w}: bad palette color {c}")
    if len(look.get("palette", [])) < 3: err(f"{w}: look.palette needs 3+ colors")
    for k in ("silhouette", "pops_against_ochre", "props"):
        if not look.get(k): err(f"{w}: look.{k} missing")
    sched = n.get("schedule", [])
    if not sched: err(f"{w}: empty schedule")
    for s in sched:
        if s.get("when") not in WHEN: err(f"{w}: schedule when '{s.get('when')}'")
        if s.get("station") not in stations: err(f"{w}: unknown station '{s.get('station')}'")
        if s.get("site") and s["site"] not in site_ids: err(f"{w}: unknown site '{s['site']}'")
    if len(n.get("barks", [])) < 3: err(f"{w}: needs 3+ barks")
    for i, b in enumerate(n.get("barks", [])):
        if not b.get("text"): err(f"{w}.barks[{i}]: empty")
        check_gate(b, f"{w}.barks[{i}]")
        if "when" in b: spec(b["when"], f"{w}.barks[{i}].when")
        if BANNED.search(b.get("text", "")): err(f"{w}.barks[{i}]: ownership language")
    q = n.get("quests", {})
    for qi in q.get("gives", []):
        if qi not in quest_ids: err(f"{w}: gives unknown quest '{qi}'")
        elif not all(t.lower() in quest_ids[qi]["giver"].lower() for t in n["name"].replace("Warden ", "").replace("Mother ", "").split()[-1:]):
            err(f"{w}: quest {qi} giver '{quest_ids[qi]['giver']}' does not match NPC name")
    for qi in q.get("reacts", []):
        if qi not in quest_ids: err(f"{w}: reacts to unknown quest '{qi}'")
    for a in q.get("acts", []):
        if a not in act_ids: err(f"{w}: unknown act '{a}'")
    for e in q.get("events", []):
        if e not in event_ids: err(f"{w}: unknown descent event '{e}'")
    for s in q.get("sites", []):
        if s not in site_ids: err(f"{w}: unknown site '{s}'")
    recs = n.get("records", {})
    for rid, r in recs.items():
        if not r.get("type"): err(f"{w}.records[{rid}]: needs type")
        if not 0 <= r.get("weight", 1) <= 5: err(f"{w}.records[{rid}]: weight 0..5")
        for t in r.get("tags", []):
            if t not in tags: err(f"{w}.records[{rid}]: unknown tag '{t}' (add it to ledger_rules values/summaries)")
        if not r.get("tags"): err(f"{w}.records[{rid}]: no tags")
    used_rec = set()
    rec_choices = 0
    for k in DLG_KINDS:
        did = n.get("dialogue", {}).get(k)
        d = dfiles.get(did)
        if d is None: continue
        dw = f"dialogue {did}"
        if d.get("id") != did: err(f"{dw}: id mismatch")
        lines = d.get("lines", [])
        labels = {l["label"] for l in lines if isinstance(l, dict) and "label" in l}
        if len(labels) != len([1 for l in lines if isinstance(l, dict) and "label" in l]): err(f"{dw}: duplicate labels")
        has_gate = False
        events = []

        def ev_check(e, where):
            events.append(e)
            if e.startswith("rec:"):
                used_rec.add(e[4:])
                if e[4:] not in recs: err(f"{where}: unknown record '{e}'")
            elif e.startswith("offer:"):
                if e[6:] not in quest_ids: err(f"{where}: offer of unknown quest '{e}'")
                elif e[6:] not in q.get("gives", []): err(f"{where}: {nid} does not give '{e[6:]}'")
            elif e.startswith("lead:"):
                if e[5:] not in event_ids | site_ids | act_ids | set(quest_ids): err(f"{where}: lead target '{e}' not an event/site/act/quest")
            else:
                err(f"{where}: unknown event '{e}'")

        for i, ln in enumerate(lines):
            lw = f"{dw}[{i}]"
            if not isinstance(ln, dict): err(f"{lw}: not an object"); continue
            check_gate(ln, lw)
            if "if" in ln or "if_not" in ln: has_gate = True
            if "goto" in ln and ln["goto"] not in labels: err(f"{lw}: goto '{ln['goto']}' missing label")
            if "event" in ln: ev_check(ln["event"], lw)
            if "text" in ln:
                who = ln.get("who", "")
                base = who[6:] if who.startswith("comms:") else who
                if BANNED.search(ln["text"]): err(f"{lw}: ownership language")
                if who == "narration": continue
                if base == nid: allowed = set(ex)
                elif base in chars: allowed = char_expr[base]
                else: err(f"{lw}: unknown speaker '{who}'"); continue
                if ln.get("expr", "default") not in allowed: err(f"{lw}: expression '{ln.get('expr')}' not available for {base}")
                if "expr" not in ln: err(f"{lw}: missing expr")
            if "choice" in ln:
                for j, o in enumerate(ln["choice"]):
                    ow = f"{lw}.choice[{j}]"
                    if o.get("goto") not in labels: err(f"{ow}: goto '{o.get('goto')}' missing label")
                    check_gate(o, ow)
                    if not o.get("text"): err(f"{ow}: empty text")
        if k in ("meet", "turnin"):
            # count choice branches that end in a rec: event (label block scan)
            for i, ln in enumerate(lines):
                if isinstance(ln, dict) and "label" in ln:
                    j = i + 1
                    while j < len(lines) and not (isinstance(lines[j], dict) and ("label" in lines[j])):
                        e = lines[j].get("event", "") if isinstance(lines[j], dict) else ""
                        if e.startswith("rec:"): rec_choices += 1
                        j += 1
        if k in ("repeat", "react") and not has_gate: err(f"{dw}: needs flag-gated reactions")
        if k == "quest" and not any(e.startswith(("offer:", "lead:")) for e in events): err(f"{dw}: needs an offer:/lead: event")
        if k == "quest" and q.get("gives") and not any(e.startswith("offer:") for e in events): err(f"{dw}: giver must emit offer:")
        if k in ("meet", "turnin") and not any(isinstance(l, dict) and "choice" in l for l in lines): err(f"{dw}: needs a choice")
    if rec_choices < 2: err(f"{w}: needs 2+ choice branches that record Ledger events (meet/turnin); found {rec_choices}")
    for rid in recs:
        if rid not in used_rec: err(f"{w}: record '{rid}' is never used by a dialogue")

# reactions to acts and ledger tags: overall coverage
all_text = json.dumps(list(dfiles.values()))
for fl in ("rr_act1_done", "rr_act2_done", "boss_defeated"):
    if fl not in all_text: err(f"npc dialogues never react to act flag '{fl}'")
if all_text.count('"if": "ledger_') < 12: err("npc dialogues should react to 12+ Ledger tag flags")

# ambient
amb = ambf.get("lines", [])
if len(amb) < 20: err(f"ambient: need 20+ lines, found {len(amb)}")
ids = set()
for a in amb:
    w = f"ambient {a.get('id')}"
    if a.get("id") in ids: err(f"{w}: duplicate")
    ids.add(a.get("id"))
    if a.get("station") not in stations: err(f"{w}: unknown station '{a.get('station')}'")
    if a.get("kind") not in {"sign", "placard", "wind", "overheard"}: err(f"{w}: bad kind")
    if not a.get("text"): err(f"{w}: empty text")
    check_gate(a, w)

# codex
need = ["place_red_span_remnant", "place_spanwright_yard", "place_well_line", "place_grazer_flats", "place_augur_pit", "place_waystation",
        "place_boulder_pass", "lore_load_marks", "lore_keth_tally", "lore_permit_7k"]
for k in need:
    e = codex.get(k)
    if not e: err(f"codex: missing '{k}'"); continue
    for f in ("category", "title", "subtitle", "body", "unlock"):
        if f not in e: err(f"codex {k}: missing '{f}'")
    if e.get("category") not in ("places", "lore"): err(f"codex {k}: category")
for sp in reg.get("spokes", []):
    if sp.get("codex") and sp["codex"] not in codex: err(f"spoke {sp['id']}: codex '{sp['codex']}' missing")

for e in errors: print("[NPCS] ERROR:", e)
print(f"[NPCS] npcs={len(npcs)} dialogues={len(dfiles)} ambient={len(amb)} errors={len(errors)}")
sys.exit(1 if errors else 0)
