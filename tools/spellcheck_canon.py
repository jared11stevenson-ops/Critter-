#!/usr/bin/env python3
"""Spell pass over player-facing text in game/canon/gear.json, regions/*.json, npcs/*.json, game/narrative/dialogue/rrn_*.json and the Red Reaches codex entries.
Needs `pip install pyspellchecker`; skips (exit 0) with a note if it is not installed.
Lore words (names, invented terms) live in tools/lore_words.txt, one per line. Also flags British spellings.
Run: python3 tools/spellcheck_canon.py [--list]"""
import json, os, re, sys, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
C = os.path.join(ROOT, "game", "canon")
try:
    from spellchecker import SpellChecker
except ImportError:
    print("[SPELL] pyspellchecker not installed; skipped (pip install pyspellchecker)")
    sys.exit(0)

SKIP_KEYS = {"id", "stat", "op", "slot", "rarity", "character", "region", "kind", "ref", "landmark", "target", "type", "template",
             "item", "origin_region", "completes_flag", "sets_flag", "flag", "species_id", "creature", "tags", "ledger_tags",
             "unlocks", "reward_gear", "cares", "hooks", "uses", "color", "palette", "density", "fog_color", "sky", "relief", "layers", "stinger_on_event", "tempo", "trigger", "when", "requires", "records", "station", "site", "dialogue", "flag_met", "portrait_expressions", "quests", "if", "if_not", "goto", "label", "event", "who", "expr", "set", "when_", "race_note"}
spell = SpellChecker()
lore = set()
lw = os.path.join(os.path.dirname(__file__), "lore_words.txt")
if os.path.exists(lw):
    lore = {w.strip().lower() for w in open(lw, encoding="utf8") if w.strip() and not w.startswith("#")}
spell.word_frequency.load_words(lore)
BRIT = re.compile(r"\b(colour\w*|favour\w*|honour\w*|neighbour\w*|armour\w*|behaviour\w*|grey\w*|centre\w*|metre\w*|labour\w*|organis\w*|recognis\w*|realis\w*|analys(e|ed|es|ing)|travell\w*|cancell\w*|defence|licence|ageing|mould\w*|plough\w*|towards|whilst|amongst|learnt|spelt|burnt)\b", re.I)


def walk(o, key=None):
    if isinstance(o, dict):
        for k, v in o.items():
            if k in SKIP_KEYS or k.startswith("_"): continue
            yield from walk(v, k)
    elif isinstance(o, list):
        for x in o: yield from walk(x, key)
    elif isinstance(o, str):
        if key in SKIP_KEYS: return
        yield o


bad = {}
brit = []
files = [os.path.join(C, "gear.json")] + sorted(glob.glob(os.path.join(C, "regions", "*.json")))
files += sorted(glob.glob(os.path.join(C, "npcs", "*.json")))
files += sorted(glob.glob(os.path.join(ROOT, "game", "narrative", "dialogue", "rrn_*.json")))
CODEX = os.path.join(C, "codex.json")  # only the Red Reaches entries added with the NPC pass
for f in files + [CODEX]:
    d = json.load(open(f, encoding="utf8"))
    n = os.path.basename(f)
    if f == CODEX:
        d = {k: v for k, v in d["entries"].items() if k in ("place_red_span_remnant", "place_spanwright_yard", "place_well_line", "place_grazer_flats", "place_augur_pit", "place_waystation", "place_boulder_pass", "lore_load_marks", "lore_keth_tally", "lore_permit_7k")}
    for text in walk(d):
        for m in BRIT.finditer(text): brit.append((n, m.group(0)))
        for w in re.findall(r"[A-Za-z][A-Za-z']*", text.replace("’", "'")):
            wl = w.lower().strip("'")
            if len(wl) < 3 or wl in lore: continue
            if wl.endswith("'s"): wl = wl[:-2]
            if not wl or wl in lore: continue
            if wl in spell: continue
            if "'" in wl:
                continue
            bad.setdefault(wl, set()).add(n)
for n, w in brit: print(f"[SPELL] ERROR: British spelling '{w}' in {n}")
for w, fs in sorted(bad.items()):
    print(f"[SPELL] ERROR: unknown word '{w}' in {', '.join(sorted(fs))}" + (f" (maybe {spell.correction(w)})" if spell.correction(w) else ""))
print(f"[SPELL] unknown={len(bad)} british={len(brit)}")
sys.exit(1 if bad or brit else 0)
