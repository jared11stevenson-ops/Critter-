#!/usr/bin/env python3
"""Validates the Red Reaches living-world data: rr_npcs.json, world_extra.json, npc_registry.json against the region
recipe (quest ids, event ids, loot_table items, gear ids). Exit 1 on errors. Called by tools/validate.sh."""
import json, os, sys, re

ROOT = os.path.join(os.path.dirname(__file__), "..")
R = os.path.join(ROOT, "game", "world", "red_reaches")
errors = []
def load(p):
    try:
        return json.load(open(p, encoding="utf8"))
    except Exception as ex:
        errors.append(f"{p}: cannot parse ({ex})"); return {}
region = load(os.path.join(ROOT, "game/canon/regions/red_reaches.json"))
npcs = load(os.path.join(R, "rr_npcs.json"))
extra = load(os.path.join(R, "world_extra.json"))
reg = load(os.path.join(ROOT, "game/art/models/npcs/npc_registry.json"))
quests = {q["id"] for q in region.get("side_quests", [])}
events = {e["id"] for e in region.get("descent_events", [])}
loot_items = {l["item"] for l in region.get("loot_table", [])}
layout = load(os.path.join(R, "layout.json"))
floors = {f["id"]: f for f in layout.get("floors", [])}

def in_floor(x, z):
    import math
    for f in floors.values():
        if f["type"] == "disc":
            if math.hypot(x - f["c"][0], z - f["c"][1]) <= f["r"] + 0.5: return True
        else:
            ax, az = f["a"]; bx, bz = f["b"]
            dx, dz = bx - ax, bz - az
            t = max(0, min(1, ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz or 1)))
            if math.hypot(x - (ax + t * dx), z - (az + t * dz)) <= f["r"] + 0.5: return True
    return False

ids = set()
n_quest = 0
for n in npcs.get("npcs", []):
    i = n.get("id", "?")
    if i in ids: errors.append(f"npc {i}: duplicate id")
    ids.add(i)
    for k in ("name", "role", "stations", "talk", "barks", "hotspot"):
        if not n.get(k): errors.append(f"npc {i}: missing '{k}'")
    if n.get("quest"):
        n_quest += 1
        if n["quest"] not in quests: errors.append(f"npc {i}: unknown quest {n['quest']}")
    for e in n.get("events", []):
        if e not in events: errors.append(f"npc {i}: unknown event {e}")
    for s in n.get("stations", []):
        if not in_floor(*s["p"]): errors.append(f"npc {i}: station {s['p']} is off the walkable floor")
    for ph, idx in n.get("schedule", {}).items():
        if ph not in ("dawn", "day", "dusk") or idx >= len(n["stations"]): errors.append(f"npc {i}: bad schedule {ph}:{idx}")
    for t in n.get("talk", []):
        if t.get("quest") and not n.get("quest"): errors.append(f"npc {i}: talk entry has quest but npc has none")
        if t.get("play_event") and t["play_event"] not in events: errors.append(f"npc {i}: unknown play_event {t['play_event']}")
        for ln in t.get("lines", []):
            if len(ln.get("text", "")) < 3: errors.append(f"npc {i}: empty line")
    if i not in reg.get("npcs", {}): errors.append(f"npc {i}: missing from npc_registry.json")
for p in npcs.get("pairs", []):
    for k in ("a", "b"):
        if p[k] not in ids: errors.append(f"pair: unknown npc {p[k]}")
missing = quests - {n["quest"] for n in npcs.get("npcs", []) if n.get("quest")}
if missing: errors.append(f"quests without an NPC giver: {sorted(missing)}")
for l in extra.get("loot", []):
    if l["item"] not in loot_items: errors.append(f"loot: {l['item']} not in region loot_table")
    if not in_floor(*l["p"]): errors.append(f"loot {l['item']} at {l['p']} is off the walkable floor")
for s in extra.get("settlements", []):
    for p in s["props"]:
        x, z = s["center"][0] + p["p"][0], s["center"][1] + p["p"][1]
        if not in_floor(x, z): errors.append(f"settlement {s['id']}: prop {p['k']} at ({x:.1f},{z:.1f}) is off the walkable floor")
for sc in extra.get("secrets", []):
    for it in sc.get("reward_items", {}):
        if it not in loot_items: errors.append(f"secret {sc['id']}: reward item {it} not in loot_table")
print(f"[WORLD] npcs={len(ids)} quest_givers={n_quest} settlements={len(extra.get('settlements', []))} loot={len(extra.get('loot', []))} secrets={len(extra.get('secrets', []))} errors={len(errors)}")
for e in errors: print("[WORLD] ERROR:", e)
sys.exit(1 if errors else 0)
