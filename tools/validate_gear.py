#!/usr/bin/env python3
"""Validates game/canon/gear.json against canon.json, game/combat/balance.json and the region files.
Exit 1 on errors.  Run: python3 tools/validate_gear.py"""
import json, os, sys, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
C = os.path.join(ROOT, "game", "canon")
errors = []

gear = json.load(open(os.path.join(C, "gear.json"), encoding="utf8"))
canon = json.load(open(os.path.join(C, "canon.json"), encoding="utf8"))
bal = json.load(open(os.path.join(ROOT, "game", "combat", "balance.json"), encoding="utf8"))
regions = {}
for f in glob.glob(os.path.join(C, "regions", "*.json")):
    d = json.load(open(f, encoding="utf8"))
    regions[d["id"]] = d

OBTAINABLE = ["aruun", "cigarra", "nerit", "mollusk", "zephyr", "nyxaris", "pharilux", "scarlith", "solmara", "bramvex", "solthrin"]
SLOTS = gear["slots"]
RAR = gear["rarities"]
OPS = {"add", "mult"}
COMMON_ACTOR_KEYS = {"hp", "speed", "accel", "friction", "dash_dist", "dash_time", "dash_iframes", "dash_cd", "poise"}
LOWER_IS_BETTER = {"cd", "dash_cd", "dash_time", "strain_per_s", "strain_per_tremor", "revive_time", "swap_cooldown", "contain_channel",
                   "fall_damage_frac", "interval", "windup", "recover", "telegraph"}
GLOBAL_SECTIONS = {"global", "pickups", "burden"}


def resolve(path):
    """Return the base number at path in balance.json, or None if it does not exist as a number (or a list of numbers)."""
    cur = bal
    for p in path.split("."):
        if isinstance(cur, dict) and p in cur: cur = cur[p]
        else: return None
    if isinstance(cur, (int, float)) and not isinstance(cur, bool): return cur
    if isinstance(cur, list) and cur and all(isinstance(x, (int, float)) for x in cur): return cur[0]
    return None


def stat_ok(stat, owner):
    parts = stat.split(".")
    if len(parts) < 2: return "stat path needs '<section>.<key>'"
    sec, leaf = parts[0], parts[-1]
    if sec in GLOBAL_SECTIONS:
        return None if resolve(stat) is not None else f"'{stat}' does not exist in balance.json"
    if sec != owner: return f"stat section '{sec}' must be the item's character '{owner}' or global/pickups/burden"
    if sec in bal:
        return None if resolve(stat) is not None else f"'{stat}' does not exist in balance.json"
    # character has no balance section yet: only the common actor vocabulary
    if len(parts) == 2 and leaf in COMMON_ACTOR_KEYS: return None
    return f"'{stat}': {sec} has no balance.json section; only {sorted(COMMON_ACTOR_KEYS)} are allowed until one exists"


def is_buff(stat, op, value):
    leaf = stat.split(".")[-1]
    lower = leaf in LOWER_IS_BETTER
    up = (value > 1.0) if op == "mult" else (value > 0)
    return (not up) if lower else up


ids = set()
per_char = {c: {s: 0 for s in SLOTS} for c in OBTAINABLE}
for it in gear["items"]:
    iid = it.get("id"); w = f"gear:{iid}"
    if iid in ids: errors.append(f"{w}: duplicate id")
    ids.add(iid)
    for k in ("id", "name", "character", "slot", "rarity", "source", "lore_reason", "stats"):
        if not it.get(k): errors.append(f"{w}: missing '{k}'")
    ch = it.get("character")
    if ch not in OBTAINABLE: errors.append(f"{w}: character '{ch}' is not in the First Ten + Solthrin"); continue
    if ch not in canon["characters"]: errors.append(f"{w}: character '{ch}' not in canon.json")
    if it.get("slot") not in SLOTS: errors.append(f"{w}: bad slot"); continue
    per_char[ch][it["slot"]] += 1
    if it.get("rarity") not in RAR: errors.append(f"{w}: bad rarity"); continue
    if len(it.get("lore_reason", "")) < 60: errors.append(f"{w}: lore_reason too short to tie to the contradiction")
    buffs = costs = 0
    seen = set()
    for s in it.get("stats", []):
        st, op, val = s.get("stat"), s.get("op"), s.get("value")
        if op not in OPS: errors.append(f"{w}: op '{op}' must be add or mult"); continue
        if not isinstance(val, (int, float)): errors.append(f"{w}: value for {st} must be a number"); continue
        if st in seen: errors.append(f"{w}: duplicate stat {st}")
        seen.add(st)
        e = stat_ok(st, ch)
        if e: errors.append(f"{w}: {e}")
        if op == "mult" and not 0.5 <= val <= 1.5: errors.append(f"{w}: mult {val} on {st} outside 0.5..1.5")
        if (op == "add" and (st.endswith(".hp") and abs(val) > 120)): errors.append(f"{w}: hp add too large")
        if is_buff(st, op, val): buffs += 1
        else: costs += 1
    lo, hi = RAR[it["rarity"]]["buffs"]
    if not lo <= buffs <= hi: errors.append(f"{w}: {it['rarity']} items need {lo}-{hi} buffs, has {buffs}")
    if RAR[it["rarity"]]["cost_required"] and costs < 1: errors.append(f"{w}: {it['rarity']} items need a cost stat (a trade-off)")
    if not RAR[it["rarity"]]["cost_required"] and costs > 1: errors.append(f"{w}: too many cost stats for {it['rarity']}")
    src = it.get("source", {})
    reg = regions.get(src.get("region"))
    if not reg: errors.append(f"{w}: source region '{src.get('region')}' unknown"); continue
    pool = {"act": reg["story"]["acts"], "quest": reg["side_quests"], "secret": reg["secrets"]}.get(src.get("kind"))
    if pool is None: errors.append(f"{w}: source.kind must be act|quest|secret"); continue
    entry = next((x for x in pool if x["id"] == src.get("ref")), None)
    if not entry: errors.append(f"{w}: source ref '{src.get('ref')}' not found in {src['region']}"); continue
    if iid not in entry.get("reward_gear", []): errors.append(f"{w}: {src['region']}:{src['ref']} does not list it in reward_gear")

for c in OBTAINABLE:
    total = sum(per_char[c].values())
    if total < 6: errors.append(f"character {c}: needs >= 6 gear items, has {total}")
    for s in SLOTS:
        if per_char[c][s] < 1: errors.append(f"character {c}: no {s} item")
    rars = [i["rarity"] for i in gear["items"] if i["character"] == c]
    if "legendary" not in rars: errors.append(f"character {c}: needs a legendary signature item")

# reward_gear in regions must exist
for rid, reg in regions.items():
    for pool in (reg.get("story", {}).get("acts", []), reg.get("side_quests", []), reg.get("secrets", [])):
        for e in pool:
            for gid in e.get("reward_gear", []):
                if gid not in ids: errors.append(f"{rid}:{e['id']}: reward_gear '{gid}' not in gear.json")

# materials
mids = set()
for m in gear["materials"]:
    mid = m.get("id"); w = f"material:{mid}"
    if mid in mids: errors.append(f"{w}: duplicate id")
    mids.add(mid)
    for k in ("id", "name", "kind", "rarity", "desc", "uses", "origin_region"):
        if not m.get(k): errors.append(f"{w}: missing '{k}'")
    if m.get("origin_region") not in regions: errors.append(f"{w}: unknown origin_region")
    if m.get("rarity") not in RAR: errors.append(f"{w}: bad rarity")
    if m.get("kind") not in ("material", "consumable"): errors.append(f"{w}: kind must be material|consumable")
for rid in regions:
    n = len([m for m in gear["materials"] if m["origin_region"] == rid])
    if n < 6: errors.append(f"region {rid}: needs >= 6 materials with its origin, has {n}")
# pickups already in balance.json should exist in the catalog
for p in bal.get("pickups", {}).get("amount", {}):
    if p not in mids: errors.append(f"balance pickup '{p}' missing from the material catalog")

for e in errors: print("[GEAR] ERROR:", e)
print(f"[GEAR] items={len(gear['items'])} materials={len(gear['materials'])} errors={len(errors)}")
sys.exit(1 if errors else 0)
