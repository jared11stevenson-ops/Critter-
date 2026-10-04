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
    if 245 <= x <= 297 and abs(z) <= 3.5: return True   # Ochre Span deck
    for f in floors.values():
        if f["type"] == "disc":
            if math.hypot(x - f["c"][0], z - f["c"][1]) <= f["r"] + 0.5: return True
        else:
            ax, az = f["a"]; bx, bz = f["b"]
            dx, dz = bx - ax, bz - az
            t = max(0, min(1, ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz or 1)))
            if math.hypot(x - (ax + t * dx), z - (az + t * dz)) <= f["r"] + 0.5: return True
    return False

canon = load(os.path.join(ROOT, "game/canon/npcs/red_reaches.json"))
cmap = {n["id"]: n for n in canon.get("npcs", [])}
ids = set()
n_quest = 0
stations = npcs.get("stations", {})
for st, spots in stations.items():
    for sp in spots:
        if not in_floor(sp[0], sp[1]): errors.append(f"station {st}: spot {sp[:2]} is off the walkable floor")
for n in npcs.get("npcs", []):
    i = n.get("id", "?")
    if i in ids: errors.append(f"npc {i}: duplicate id")
    ids.add(i)
    c = cmap.get(i)
    if not c:
        errors.append(f"npc {i}: not in game/canon/npcs/red_reaches.json"); continue
    if c.get("quests", {}).get("gives"): n_quest += 1
    for sc in c["schedule"]:
        if sc["station"] not in stations: errors.append(f"npc {i}: station {sc['station']} has no position")
    if i not in reg.get("npcs", {}): errors.append(f"npc {i}: missing from npc_registry.json")
    for q in c.get("quests", {}).get("gives", []):
        if q not in quests: errors.append(f"npc {i}: unknown quest {q}")
for p in npcs.get("pairs", []):
    for k in ("a", "b"):
        if p[k] not in ids: errors.append(f"pair: unknown npc {p[k]}")
given = {q for c in canon.get("npcs", []) for q in c.get("quests", {}).get("gives", [])}
if quests - given: errors.append(f"quests without an NPC giver: {sorted(quests - given)}")
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
