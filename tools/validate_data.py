#!/usr/bin/env python3
"""Validates CRITTER's data files (game/canon/*.json) against the Ledger spec. Exit 1 on errors.
Run: python3 tools/validate_data.py   (also called by tools/validate.sh)"""
import json, os, sys, re

ROOT = os.path.join(os.path.dirname(__file__), "..")
C = os.path.join(ROOT, "game", "canon")
errors, warnings = [], []
SPEC_KEYS = {"all", "any", "not", "event", "none", "opinion_min", "promise", "flag", "tally_min", "stage", "rival"}
FILTER_KEYS = {"type", "actor", "target", "entity", "region", "tag", "tags_any", "tags_all", "since", "min_weight", "data_eq", "count_min"}
TRIGGERS = {"return", "hub_idle", "camp", "descent", "boss", "rival_met", "bond_up", "era_start", "pause_menu"}


def load(name):
    p = os.path.join(C, name)
    try:
        return json.load(open(p, encoding="utf8"))
    except Exception as ex:
        errors.append(f"{name}: cannot parse ({ex})")
        return {}


def check_filter(f, where):
    if not isinstance(f, dict):
        errors.append(f"{where}: filter must be an object"); return
    for k in f:
        if k not in FILTER_KEYS:
            errors.append(f"{where}: unknown filter key '{k}'")


def check_spec(s, where):
    if not isinstance(s, dict):
        errors.append(f"{where}: spec must be an object"); return
    for k, v in s.items():
        if k not in SPEC_KEYS:
            errors.append(f"{where}: unknown spec key '{k}'"); continue
        if k in ("all", "any"):
            for i, sub in enumerate(v):
                check_spec(sub, f"{where}.{k}[{i}]")
        elif k == "not":
            check_spec(v, f"{where}.not")
        elif k in ("event", "none"):
            check_filter(v, f"{where}.{k}")


canon = load("canon.json")
chars = set(canon.get("characters", {}).keys())
rules = load("ledger_rules.json")
bonds = load("bonds.json")
reacts = load("reactions.json")
rivals = load("rivals.json")

# ---- ledger_rules
for c in rules.get("values", {}):
    if c not in chars:
        errors.append(f"ledger_rules.values: unknown character '{c}'")
for c in rules.get("initial_bonds", []):
    if c not in chars:
        errors.append(f"ledger_rules.initial_bonds: unknown character '{c}'")
templates = rules.get("promise_templates", {})
for k, fe in rules.get("flag_events", {}).items():
    if "promise" in fe:
        if fe["promise"].get("template") not in templates:
            errors.append(f"flag_events[{k}]: unknown promise template")
    else:
        if not isinstance(fe.get("tags"), list) or not fe.get("type"):
            errors.append(f"flag_events[{k}]: needs type + tags[]")
for tid, t in templates.items():
    for key in ("letter", "spirit", "break_on"):
        for i, f in enumerate(t.get(key, [])):
            check_filter(f.get("none", f) if isinstance(f, dict) else f, f"promise_templates[{tid}].{key}[{i}]")
for tag, tpl in rules.get("summaries", {}).items():
    for ph in re.findall(r"\{(\w+)\}", tpl):
        if ph not in ("target", "region"):
            errors.append(f"summaries[{tag}]: unknown placeholder {{{ph}}}")
for c in rules.get("opinion_lines", {}):
    if c not in chars:
        errors.append(f"opinion_lines: unknown character '{c}'")

# ---- bonds
for cid, b in bonds.items():
    if cid.startswith("_"):
        continue
    if cid not in chars:
        errors.append(f"bonds: unknown character '{cid}'")
    st = b.get("stages", [])
    if not st or st[0] != "unmet" or st[-1] != "bonded":
        errors.append(f"bonds[{cid}]: stages must start 'unmet' and end 'bonded'")
    for s, spec in b.get("requires", {}).items():
        if s not in st:
            errors.append(f"bonds[{cid}].requires: stage '{s}' not in stages")
        check_spec(spec, f"bonds[{cid}].requires.{s}")
    for key in ("estrange_if", "reconcile_if"):
        if key in b:
            check_spec(b[key], f"bonds[{cid}].{key}")
    if not b.get("contradiction"):
        warnings.append(f"bonds[{cid}]: missing 'contradiction' (the bond test should be built on it)")

# ---- reactions
seen_ids = set()
for cid, lst in reacts.items():
    if cid.startswith("_"):
        continue
    if cid not in chars:
        errors.append(f"reactions: unknown character '{cid}'")
    for r in lst:
        if r.get("id") in seen_ids:
            errors.append(f"reactions: duplicate id {r.get('id')}")
        seen_ids.add(r.get("id"))
        if r.get("trigger") not in TRIGGERS:
            errors.append(f"reactions[{r.get('id')}]: unknown trigger '{r.get('trigger')}' (allowed: {sorted(TRIGGERS)})")
        if not r.get("text"):
            errors.append(f"reactions[{r.get('id')}]: empty text")
        check_spec(r.get("when", {}), f"reactions[{r.get('id')}].when")

# ---- rivals
traits = set(rivals.get("traits", {}).keys())
arch = rivals.get("archetypes", {})
for a in rivals.get("authored", []):
    if a.get("archetype") not in arch:
        errors.append(f"rivals.authored[{a.get('id')}]: unknown archetype")
    for t in a.get("traits", []):
        if t not in traits:
            errors.append(f"rivals.authored[{a.get('id')}]: unknown trait '{t}'")
tags_used = set(rivals.get("counters", {}).values())
for t in tags_used:
    if t not in rivals.get("adapt_lines", {}):
        errors.append(f"rivals.counters: adaptation '{t}' has no adapt_line")
for ab, scars in rivals.get("scars", {}).items():
    for s in scars:
        if s not in rivals.get("scar_phrases", {}):
            errors.append(f"rivals.scars: '{s}' has no scar_phrase")
for res in rivals.get("resolutions", []):
    if "requires" in res:
        check_spec(res["requires"], f"rivals.resolutions[{res['id']}].requires")

for w in warnings:
    print("[DATA] warn:", w)
for e in errors:
    print("[DATA] ERROR:", e)
print(f"[DATA] errors={len(errors)} warnings={len(warnings)}")
sys.exit(1 if errors else 0)
