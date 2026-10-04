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

# ---------------------------------------------------------------------------
# Region lore layer: story arc, side quests, secrets, landmarks, ambient, loot, mood
# ---------------------------------------------------------------------------
import re
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
gear_path = os.path.join(C, "gear.json")
gear = json.load(open(gear_path, encoding="utf8")) if os.path.exists(gear_path) else {"items": [], "materials": []}
gear_by_id = {g["id"]: g for g in gear["items"]}
mat_by_id = {m["id"]: m for m in gear["materials"]}
all_flags_set = set()
all_flags_used = []  # (where, flag)
quest_count = secret_count = act_count = 0
primaries = {}
LORE_ONLY_FLAGS = set()


def flags_in(sp, out):
    if isinstance(sp, dict):
        for k, v in sp.items():
            if k == "flag": out.append(v)
            elif k in ("all", "any"):
                for x in v: flags_in(x, out)
            elif k == "not": flags_in(v, out)


for f in sorted(glob.glob(os.path.join(C, "regions", "*.json"))):
    n = os.path.basename(f)
    d = json.load(open(f, encoding="utf8"))
    rid = d.get("id")
    for k in ("story", "side_quests", "secrets", "landmarks", "ambient", "loot_table", "mood"):
        if k not in d: errors.append(f"{n}: missing lore layer '{k}'")
    if any(k not in d for k in ("story", "side_quests", "secrets", "landmarks", "ambient", "loot_table", "mood")):
        continue
    lm = {x["id"] for x in d["landmarks"]}
    if len(lm) < 4: errors.append(f"{n}: needs >= 4 landmarks")
    for x in d["landmarks"]:
        for k in ("id", "name", "kind", "desc"):
            if not x.get(k): errors.append(f"{n}: landmark missing '{k}'")
    # story
    st = d["story"]
    acts = st.get("acts", [])
    if not st.get("title") or not st.get("logline"): errors.append(f"{n}: story needs title + logline")
    if [a.get("act") for a in acts] != [1, 2, 3]: errors.append(f"{n}: story needs exactly acts 1,2,3")
    act_ids = set()
    quest_ids = {q["id"] for q in d["side_quests"]}
    secret_ids = {s["id"] for s in d["secrets"]}
    for a in acts:
        act_count += 1
        aid = a.get("id"); w = f"{n}:{aid}"
        act_ids.add(aid)
        for k in ("id", "title", "beat", "trigger", "completes_flag"):
            if not a.get(k): errors.append(f"{w}: act missing '{k}'")
        spec(a.get("trigger", {}), w + ".trigger")
        tf = []; flags_in(a.get("trigger", {}), tf)
        for x in tf: all_flags_used.append((w + ".trigger", x))
        all_flags_set.add(a.get("completes_flag"))
        if a.get("completes_flag") not in rules.get("flag_events", {}):
            errors.append(f"{w}: completes_flag '{a.get('completes_flag')}' not in ledger_rules.flag_events")
        for v in a.get("variants", []):
            spec(v.get("when", {}), w + ".variant." + str(v.get("id")))
            if not v.get("text") or not v.get("sets_flag"): errors.append(f"{w}: variant needs text + sets_flag")
            all_flags_set.add(v.get("sets_flag"))
        if a["act"] == 3 and len(a.get("variants", [])) < 2: errors.append(f"{w}: act 3 needs >= 2 ledger-driven variants")
        for u in a.get("unlocks", []):
            if u not in quest_ids and u not in secret_ids: errors.append(f"{w}: unlocks unknown '{u}'")
        for gid in a.get("reward_gear", []):
            gi = gear_by_id.get(gid)
            if not gi or gi["source"] != {"region": rid, "kind": "act", "ref": aid}: errors.append(f"{w}: reward_gear '{gid}' does not match gear.json source")
    # side quests
    if len(d["side_quests"]) < 6: errors.append(f"{n}: needs >= 6 side quests")
    unlocked = set()
    for a in acts: unlocked |= set(a.get("unlocks", []))
    for q in d["side_quests"]:
        quest_count += 1
        qid = q.get("id"); w = f"{n}:{qid}"
        for k in ("id", "title", "giver", "landmark", "summary", "choices"):
            if not q.get(k): errors.append(f"{w}: quest missing '{k}'")
        if q.get("landmark") not in lm: errors.append(f"{w}: landmark '{q.get('landmark')}' not in landmarks")
        if qid not in unlocked: errors.append(f"{w}: no act unlocks this quest")
        if len(q.get("choices", [])) < 2: errors.append(f"{w}: needs >= 2 choices")
        cids = set()
        for c in q.get("choices", []):
            cw = f"{w}.{c.get('id')}"
            if c.get("id") in cids: errors.append(f"{cw}: duplicate choice id")
            cids.add(c.get("id"))
            for k in ("label", "result", "consequence"):
                if not c.get(k): errors.append(f"{cw}: missing '{k}'")
            if not c.get("records"): errors.append(f"{cw}: choice must be Ledger-visible (records)")
            for r in c.get("records", []):
                if not r.get("type") or not r.get("target"): errors.append(f"{cw}: record needs type + target")
                for t in r.get("tags", []):
                    if t not in known_tags: errors.append(f"{cw}: tag '{t}' is not in ledger_rules values/summaries")
                if not 0 <= int(r.get("weight", 0)) <= 5: errors.append(f"{cw}: weight out of range")
            if c.get("sets_flag"):
                if c["sets_flag"] in all_flags_set: errors.append(f"{cw}: duplicate flag '{c['sets_flag']}'")
                all_flags_set.add(c["sets_flag"])
        for ch in q.get("cares", []):
            if ch not in chars: errors.append(f"{w}: unknown character '{ch}' in cares")
        for gid in q.get("reward_gear", []):
            gi = gear_by_id.get(gid)
            if not gi or gi["source"] != {"region": rid, "kind": "quest", "ref": qid}: errors.append(f"{w}: reward_gear '{gid}' does not match gear.json source")
    # secrets
    if len(d["secrets"]) < 2: errors.append(f"{n}: needs >= 2 secrets")
    for s in d["secrets"]:
        secret_count += 1
        w = f"{n}:{s.get('id')}"
        for k in ("id", "name", "hint", "how_found", "reward"):
            if not s.get(k): errors.append(f"{w}: secret missing '{k}'")
        if s.get("id") not in unlocked: errors.append(f"{w}: no act unlocks this secret")
        for t in s.get("ledger_tags", []):
            if t not in known_tags: errors.append(f"{w}: tag '{t}' unknown")
        for gid in s.get("reward_gear", []):
            gi = gear_by_id.get(gid)
            if not gi or gi["source"] != {"region": rid, "kind": "secret", "ref": s.get("id")}: errors.append(f"{w}: reward_gear '{gid}' does not match gear.json source")
    # ambient
    amb = d["ambient"]
    if len(amb.get("npcs", [])) < 3: errors.append(f"{n}: ambient needs >= 3 npcs")
    if len(amb.get("creature_behaviors", [])) < 3: errors.append(f"{n}: ambient needs >= 3 creature_behaviors")
    creature_ids = {c["id"] for c in d.get("creatures", [])}
    for x in amb.get("npcs", []):
        for k in ("id", "name", "species", "behavior", "schedule", "reacts"):
            if not x.get(k): errors.append(f"{n}: ambient npc missing '{k}'")
        if x.get("reacts", {}).get("flag"): all_flags_used.append((f"{n}:{x.get('id')}.reacts", x["reacts"]["flag"]))
    for x in amb.get("creature_behaviors", []):
        if x.get("creature") not in creature_ids: errors.append(f"{n}: creature_behaviors uses unknown creature '{x.get('creature')}'")
        if not x.get("behavior") or not x.get("trigger"): errors.append(f"{n}: creature behavior needs behavior + trigger")
    # loot
    if len(d["loot_table"]) < 6: errors.append(f"{n}: loot_table needs >= 6 entries")
    for e in d["loot_table"]:
        m = mat_by_id.get(e.get("item"))
        if not m: errors.append(f"{n}: loot item '{e.get('item')}' not in gear.json materials")
        elif m["origin_region"] != rid: errors.append(f"{n}: loot item '{e.get('item')}' has origin_region {m['origin_region']}")
        if not e.get("weight", 0) > 0: errors.append(f"{n}: loot weight must be > 0")
    # mood
    mo = d["mood"]
    pal = mo.get("palette", {})
    if len(pal) < 5 or any(not HEX.match(str(v)) for v in pal.values()): errors.append(f"{n}: mood.palette needs >= 5 hex colors")
    primaries.setdefault(pal.get("primary"), []).append(rid)
    if len(mo.get("weather", [])) < 3: errors.append(f"{n}: mood.weather needs >= 3")
    if len(mo.get("sounds", [])) < 4: errors.append(f"{n}: mood.sounds needs >= 4")
    slots = mo.get("music_slots", [])
    if len(slots) < 5: errors.append(f"{n}: mood.music_slots needs >= 5")
    for s in slots:
        if not all(s.get(k) for k in ("slot", "use", "notes")): errors.append(f"{n}: music slot needs slot/use/notes")
for pc, rs in primaries.items():
    if len(rs) > 1: errors.append(f"mood palettes: primary color {pc} shared by {rs}; each region needs a unique look")
for w, fl in all_flags_used:
    if fl not in all_flags_set: errors.append(f"{w}: flag '{fl}' is never set by any act, variant or choice")

for e in errors: print("[REGIONS] ERROR:", e)
print(f"[REGIONS] events={total_events} acts={act_count} quests={quest_count} secrets={secret_count} errors={len(errors)}")
sys.exit(1 if errors else 0)
