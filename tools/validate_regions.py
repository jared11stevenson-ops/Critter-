#!/usr/bin/env python3
"""Validates game/canon/regions/*.json (region recipes + descent events). Exit 1 on errors.
Run: python3 tools/validate_regions.py"""
import json, os, sys, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
C = os.path.join(ROOT, "game", "canon")
errors = []
SPEC_KEYS = {"all", "any", "not", "event", "none", "opinion_min", "promise", "flag", "tally_min", "stage", "rival"}
FILTER_KEYS = {"type", "actor", "target", "entity", "region", "tag", "tags_any", "tags_all", "since", "min_weight", "data_eq", "count_min"}
REQ = ["id", "name", "summary", "layers", "ground", "sky", "props", "creatures", "music", "encounters", "world_states", "descent_events"]
AFFIXES = {"flood", "fire", "war", "migration", "overgrowth", "disease", "extraction", "predator_imbalance", "political_control"}


def spec(s, w):
    if not isinstance(s, dict):
        errors.append(f"{w}: spec must be an object"); return
    for k, v in s.items():
        if k not in SPEC_KEYS:
            errors.append(f"{w}: unknown spec key '{k}'"); continue
        if k in ("all", "any"):
            for i, x in enumerate(v): spec(x, f"{w}.{k}[{i}]")
        elif k == "not": spec(v, w + ".not")
        elif k in ("event", "none"):
            for fk in v:
                if fk not in FILTER_KEYS: errors.append(f"{w}: unknown filter key '{fk}'")


rules = json.load(open(os.path.join(C, "ledger_rules.json")))
canon = json.load(open(os.path.join(C, "canon.json")))
rivals = json.load(open(os.path.join(C, "rivals.json")))
known_tags = set()
for vals in rules["values"].values(): known_tags |= set(vals)
known_tags |= set(rules["summaries"])
known_tags |= {"combat", "kill", "social", "discovery", "curiosity", "evidence", "trust", "containment", "promise", "promise_made", "bond", "rival", "return", "descent", "casualty", "nonviolent", "spared", "kill_dominion", "kill_wildlife", "harm_wildlife", "calmed_wildlife", "protect_weak", "stewardship", "burden", "braced_structure", "extraction", "dominion_favor", "boss"}
templates = rules["promise_templates"]
rival_ids = {a["id"] for a in rivals.get("authored", [])}
chars = set(canon["characters"])
total_events = 0
for f in sorted(glob.glob(os.path.join(C, "regions", "*.json"))):
    n = os.path.basename(f)
    try:
        d = json.load(open(f, encoding="utf8"))
    except Exception as ex:
        errors.append(f"{n}: cannot parse ({ex})"); continue
    for k in REQ:
        if k not in d: errors.append(f"{n}: missing '{k}'")
    if d.get("id") != n[:-5]: errors.append(f"{n}: id must equal file name")
    for w in d.get("world_states", []):
        if w.get("id") not in AFFIXES: errors.append(f"{n}: world_state '{w.get('id')}' not in bible affix list")
    for r in d.get("encounters", {}).get("rivals", []):
        if r not in rival_ids: errors.append(f"{n}: rival '{r}' not authored in rivals.json")
    for c in d.get("homeland_of", []) + [b["character"] for b in d.get("bondable_here", [])]:
        if c not in chars: errors.append(f"{n}: unknown character '{c}'")
    ids = set()
    for e in d.get("descent_events", []):
        total_events += 1
        eid = e.get("id")
        if eid in ids: errors.append(f"{n}: duplicate event id {eid}")
        ids.add(eid)
        for k in ("id", "title", "kind", "weight", "text", "choices"):
            if k not in e: errors.append(f"{n}:{eid}: missing '{k}'")
        if "when" in e: spec(e["when"], f"{n}:{eid}.when")
        if not e.get("choices"): errors.append(f"{n}:{eid}: needs choices")
        for c in e.get("choices", []):
            w = f"{n}:{eid}.{c.get('id')}"
            if not c.get("label") or not c.get("result"): errors.append(f"{w}: needs label + result")
            if "requires" in c: spec(c["requires"], w + ".requires")
            if not c.get("records") and "promise" not in c: errors.append(f"{w}: needs records or promise")
            if "promise" in c and c["promise"].get("template") not in templates: errors.append(f"{w}: unknown promise template")
            for r in c.get("records", []):
                for t in r.get("tags", []):
                    if t not in known_tags: errors.append(f"{w}: tag '{t}' is not in ledger_rules values/summaries")
                if not 0 <= int(r.get("weight", 0)) <= 5: errors.append(f"{w}: weight out of range")
for e in errors: print("[REGIONS] ERROR:", e)
print(f"[REGIONS] events={total_events} errors={len(errors)}")
sys.exit(1 if errors else 0)
