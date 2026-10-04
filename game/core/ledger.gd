extends Node
## Ledger — the game's memory (Lead-owned autoload "Ledger"). Spec: design/LEDGER_SPEC.md.
##
## One chronological log of "who did what to whom, where and why", plus the systems that read it:
##   * Opinion      — characters judge the player's events through their own values (tag -> score).
##   * Promises     — first-class objects with wording, letter/spirit conditions and permanent consequences.
##   * Bond Contracts — staged, character-specific trust quests (the way sapient characters are acquired).
##   * Reactions    — the Reaction Matrix: barks chosen by what the ledger remembers.
##   * Debrief      — "what changed because of you" lines.
## Events carry TAGS; tags are the shared vocabulary between all of the above (data: game/canon/*.json).

signal event_recorded(event: Dictionary)
signal promise_changed(promise_id: String, status: String)
signal bond_changed(character_id: String, stage: String)

const RULES_PATH := "res://game/canon/ledger_rules.json"
const BONDS_PATH := "res://game/canon/bonds.json"
const REACTIONS_PATH := "res://game/canon/reactions.json"
const MAX_EVENTS := 1500

var save_path := "user://critter_ledger.json"
var tick := 0
var era := "first_contact"
var current_region := "terrarium_one"
var events: Array = []
var tallies: Dictionary = {}
var promises: Dictionary = {}
var bonds: Dictionary = {}
var seen_reactions: Dictionary = {}
var rules: Dictionary = {}
var bond_defs: Dictionary = {}
var reaction_defs: Dictionary = {}
var _next_id := 1
var _run_start_tick := 0
var _in_hook := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rules = _load_json(RULES_PATH)
	bond_defs = _load_json(BONDS_PATH)
	reaction_defs = _load_json(REACTIONS_PATH)
	var args := OS.get_cmdline_user_args()
	if args.has("qa"):
		save_path = "user://qa_ledger.json"
		if not args.has("qa_keep_save") and FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if args.has("test_systems"):
		save_path = "user://test_ledger.json"
	if not _load():
		reset()
	_connect_events()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


# =====================================================================  recording & queries
## Record an event. tags are the shared vocabulary (see ledger_rules.json). weight 0..5 (0 = bookkeeping).
func record(type: String, actor: String = "player", target: String = "", tags: Array = [],
		data: Dictionary = {}, weight: int = 1, region: String = "") -> Dictionary:
	tick += 1
	var e := {"id": _next_id, "tick": tick, "era": era, "region": region if region != "" else current_region,
		"type": type, "actor": actor, "target": target, "tags": tags.duplicate(),
		"data": data.duplicate(true), "weight": weight}
	_next_id += 1
	events.append(e)
	if events.size() > MAX_EVENTS:
		_prune()
	event_recorded.emit(e)
	if not _in_hook:
		_in_hook = true
		_after_record(e)
		_in_hook = false
	return e


## Filter keys: type (String|Array), actor, target, entity (actor OR target), region, tag, tags_any, tags_all,
## since (tick >=), min_weight, data_eq (Dictionary). Extra key count_min is used by exists().
func matches(e: Dictionary, f: Dictionary) -> bool:
	if f.has("type"):
		var t: Variant = f["type"]
		if t is Array:
			if not (e["type"] in t):
				return false
		elif e["type"] != t:
			return false
	if f.has("actor") and e["actor"] != f["actor"]:
		return false
	if f.has("target") and e["target"] != f["target"]:
		return false
	if f.has("entity") and e["actor"] != f["entity"] and e["target"] != f["entity"]:
		return false
	if f.has("region") and e["region"] != f["region"]:
		return false
	if f.has("tag") and not (f["tag"] in e["tags"]):
		return false
	if f.has("tags_any"):
		var ok := false
		for t2 in f["tags_any"]:
			if t2 in e["tags"]:
				ok = true
				break
		if not ok:
			return false
	if f.has("tags_all"):
		for t3 in f["tags_all"]:
			if not (t3 in e["tags"]):
				return false
	if f.has("since") and int(e["tick"]) < int(f["since"]):
		return false
	if f.has("min_weight") and int(e["weight"]) < int(f["min_weight"]):
		return false
	if f.has("data_eq"):
		var d: Dictionary = f["data_eq"]
		for k in d:
			if not e["data"].has(k) or e["data"][k] != d[k]:
				return false
	return true


func events_where(f: Dictionary, limit: int = 0) -> Array:
	var out: Array = []
	for e in events:
		if matches(e, f):
			out.append(e)
	if limit > 0 and out.size() > limit:
		return out.slice(out.size() - limit)
	return out


func count(f: Dictionary) -> int:
	var n := 0
	for e in events:
		if matches(e, f):
			n += 1
	return n


func exists(f: Dictionary) -> bool:
	return count(f) >= int(f.get("count_min", 1))


func last(f: Dictionary) -> Dictionary:
	for i in range(events.size() - 1, -1, -1):
		if matches(events[i], f):
			return events[i]
	return {}


## Everything the ledger remembers about an entity (as actor or target), newest last.
func memory_of(entity: String, limit: int = 10) -> Array:
	return events_where({"entity": entity, "min_weight": 1}, limit)


func add_tally(key: String, n: int = 1) -> void:
	tallies[key] = int(tallies.get(key, 0)) + n


func tally(key: String) -> int:
	return int(tallies.get(key, 0))


func reset_encounter_tallies() -> void:
	for k in tallies.keys():
		if str(k).begins_with("enc:"):
			tallies.erase(k)


## The ability the player leaned on most this encounter (needs min uses), "" if none.
func dominant_ability_this_encounter(min_uses: int = 3) -> String:
	var best := ""
	var best_n := 0
	for k in tallies:
		var ks := str(k)
		if ks.begins_with("enc:ability:") and int(tallies[k]) > best_n:
			best_n = int(tallies[k])
			best = ks.substr("enc:ability:".length())
	return best if best_n >= min_uses else ""


# =====================================================================  runs (descents)
func begin_run(region: String) -> void:
	current_region = region
	_run_start_tick = tick
	reset_encounter_tallies()
	record("descent", "player", region, ["descent"], {}, 1, region)


func end_run(all_conscious: bool = true) -> void:
	record("return", "player", current_region, ["return"], {"all_conscious": all_conscious}, 2)
	current_region = "terrarium_one"


# =====================================================================  opinion
## How a character feels about what the player has done (sum of weight x the character's value for each tag).
func opinion(character_id: String, since: int = 0) -> float:
	var vals: Dictionary = rules.get("values", {}).get(character_id, {})
	if vals.is_empty():
		return 0.0
	var total := 0.0
	for e in events:
		if int(e["tick"]) < since or e["actor"] != "player":
			continue
		var wit: Array = e["data"].get("witnesses", [])
		if not wit.is_empty() and not (character_id in wit):
			continue
		var s := 0.0
		for t in e["tags"]:
			if vals.has(t):
				s += float(vals[t])
		total += s * float(e["weight"])
	return total


func opinion_label(score: float) -> String:
	if score >= 12.0: return "devoted"
	if score >= 5.0: return "trusting"
	if score >= 1.5: return "warm"
	if score > -1.5: return "neutral"
	if score > -5.0: return "wary"
	return "hostile"


func opinion_shift_lines(since: int = -1) -> Array:
	var s := _run_start_tick if since < 0 else since
	var out: Array = []
	var lines: Dictionary = rules.get("opinion_lines", {})
	for c in rules.get("values", {}):
		var d := opinion(c, s)
		if absf(d) >= 2.0 and lines.has(c):
			out.append(lines[c]["up"] if d > 0.0 else lines[c]["down"])
	return out


# =====================================================================  promises
func make_promise(id: String, to: String, template_id: String, witnesses: Array = []) -> Dictionary:
	if promises.has(id):
		return promises[id]
	var tpl: Dictionary = rules.get("promise_templates", {}).get(template_id, {})
	var p := {"id": id, "to": to, "template": template_id, "wording": str(tpl.get("wording", template_id)),
		"made_tick": 0, "status": "open", "witnesses": witnesses.duplicate(),
		"resolve_on": str(tpl.get("resolve_on", "")), "deadline_tick": int(tpl.get("deadline_ticks", 0))}
	promises[id] = p
	record("promised", "player", to, ["promise", "promise_made"], {"promise": id, "wording": p["wording"], "witnesses": witnesses}, 2)
	p["made_tick"] = tick
	if p["deadline_tick"] > 0:
		p["deadline_tick"] = tick + int(p["deadline_tick"])
	promise_changed.emit(id, "open")
	return p


func promise_status(id: String) -> String:
	return str(promises.get(id, {}).get("status", ""))


func _eval_list(list: Array, since: int) -> bool:
	for spec in list:
		var s: Dictionary = (spec as Dictionary).duplicate(true)
		if s.has("none"):
			var nf: Dictionary = (s["none"] as Dictionary).duplicate()
			nf["since"] = since
			if exists(nf):
				return false
		else:
			s["since"] = since
			if not exists(s):
				return false
	return true


func _finalize_promise(p: Dictionary, status: String, letter_ok: bool, spirit_ok: bool) -> void:
	p["status"] = status
	record("promise_resolved", "player", str(p["to"]), ["promise", "promise_" + status],
		{"promise": p["id"], "status": status, "letter_ok": letter_ok, "spirit_ok": spirit_ok,
		"witnesses": p["witnesses"]}, 3)
	promise_changed.emit(str(p["id"]), status)


func _status_from(letter_ok: bool, spirit_ok: bool) -> String:
	if letter_ok and spirit_ok:
		return "kept"
	if letter_ok:
		return "loophole"
	if spirit_ok:
		return "bent"
	return "broken"


func _check_promises(e: Dictionary) -> void:
	if e["type"] == "promise_resolved":
		return
	for id in promises.keys():
		var p: Dictionary = promises[id]
		if p["status"] != "open":
			continue
		var tpl: Dictionary = rules.get("promise_templates", {}).get(p["template"], {})
		var since := int(p["made_tick"])
		for f in tpl.get("break_on", []):
			var bf: Dictionary = (f as Dictionary).duplicate()
			bf["since"] = since
			if exists(bf):
				_finalize_promise(p, "broken", false, false)
				break
		if p["status"] != "open":
			continue
		var letter_ok := _eval_list(tpl.get("letter", []), since)
		var spirit_ok := _eval_list(tpl.get("spirit", []), since)
		if p["resolve_on"] != "":
			if e["type"] == p["resolve_on"]:
				_finalize_promise(p, _status_from(letter_ok, spirit_ok), letter_ok, spirit_ok)
		elif letter_ok and spirit_ok and (not tpl.get("letter", []).is_empty()):
			_finalize_promise(p, "kept", true, true)
		elif int(p["deadline_tick"]) > 0 and tick > int(p["deadline_tick"]):
			_finalize_promise(p, _status_from(letter_ok, spirit_ok), letter_ok, spirit_ok)


# =====================================================================  bonds
func bond_stage(character_id: String) -> String:
	return str(bonds.get(character_id, {}).get("stage", "unmet"))


func set_bond(character_id: String, stage: String) -> void:
	if bond_stage(character_id) == stage:
		return
	bonds[character_id] = {"stage": stage}
	record("bond_stage", "player", character_id, ["bond", "bond_" + stage], {"stage": stage}, 2 if stage == "bonded" else 1)
	bond_changed.emit(character_id, stage)


func stage_rank(character_id: String, stage: String) -> int:
	return (bond_defs.get(character_id, {}).get("stages", []) as Array).find(stage)


func advance_bond(character_id: String) -> String:
	var def: Dictionary = bond_defs.get(character_id, {})
	if def.is_empty():
		return bond_stage(character_id)
	var cur := bond_stage(character_id)
	if cur == "estranged":
		if def.has("reconcile_if") and check(def["reconcile_if"]):
			set_bond(character_id, str(def.get("reconcile_to", "interested")))
		return bond_stage(character_id)
	if cur != "bonded" and def.has("estrange_if") and check(def["estrange_if"]):
		set_bond(character_id, "estranged")
		return "estranged"
	var stages: Array = def.get("stages", [])
	var guard := 0
	while guard < 8:
		guard += 1
		var idx := stages.find(cur)
		if idx < 0 or idx >= stages.size() - 1:
			break
		var nxt: String = stages[idx + 1]
		var req: Dictionary = def.get("requires", {}).get(nxt, {})
		if req.is_empty() or not check(req):
			break
		cur = nxt
		set_bond(character_id, cur)
	return cur


func _advance_all_bonds() -> void:
	for cid in bond_defs:
		if cid.begins_with("_"):
			continue
		advance_bond(cid)


## Characters the player can currently bond with / has bonded (for UI).
func bonded_characters() -> Array:
	var out: Array = []
	for c in bonds:
		if bonds[c]["stage"] == "bonded":
			out.append(c)
	return out


# =====================================================================  spec DSL
## Spec keys: all[], any[], not{}, event{filter}, none{filter}, opinion_min{character,min}, promise{id,status_in[]},
## flag, tally_min{key,min}, stage{character,at_least}, rival{id,state_in[]}.
func check(spec: Dictionary, ctx: Dictionary = {}) -> bool:
	if spec.is_empty():
		return true
	if spec.has("all"):
		for s in spec["all"]:
			if not check(s, ctx):
				return false
	if spec.has("any"):
		var any_ok := false
		for s2 in spec["any"]:
			if check(s2, ctx):
				any_ok = true
				break
		if not any_ok:
			return false
	if spec.has("not") and check(spec["not"], ctx):
		return false
	if spec.has("event") and not exists(spec["event"]):
		return false
	if spec.has("none") and exists(spec["none"]):
		return false
	if spec.has("opinion_min"):
		var om: Dictionary = spec["opinion_min"]
		if opinion(str(om.get("character", ""))) < float(om.get("min", 0)):
			return false
	if spec.has("promise"):
		var pm: Dictionary = spec["promise"]
		var p: Dictionary = promises.get(str(pm.get("id", "")), {})
		if p.is_empty():
			return false
		if pm.has("status_in") and not (p["status"] in pm["status_in"]):
			return false
	if spec.has("flag") and not GameState.get_flag(str(spec["flag"])):
		return false
	if spec.has("tally_min"):
		var tm: Dictionary = spec["tally_min"]
		if tally(str(tm.get("key", ""))) < int(tm.get("min", 1)):
			return false
	if spec.has("stage"):
		var st: Dictionary = spec["stage"]
		var cid := str(st.get("character", ""))
		if stage_rank(cid, bond_stage(cid)) < stage_rank(cid, str(st.get("at_least", ""))):
			return false
	if spec.has("rival"):
		var rv: Dictionary = spec["rival"]
		var rs := get_node_or_null("/root/Rivals")
		var r: Dictionary = rs.get_rival(str(rv.get("id", ""))) if rs else {}
		if r.is_empty() or (rv.has("state_in") and not (r.get("state", "") in rv["state_in"])):
			return false
	return true


# =====================================================================  reaction matrix
func reactions_for(character_id: String, trigger: String) -> Array:
	var out: Array = []
	for r in reaction_defs.get(character_id, []):
		if str(r.get("trigger", "")) != trigger:
			continue
		if r.get("once", false) and seen_reactions.has(r["id"]):
			continue
		if not check(r.get("when", {})):
			continue
		out.append(r)
	out.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	return out


## Pick (and mark as seen) the best reaction for a character at a trigger. {} if none.
func take_reaction(character_id: String, trigger: String) -> Dictionary:
	var rs := reactions_for(character_id, trigger)
	if rs.is_empty():
		return {}
	var r: Dictionary = rs[0]
	seen_reactions[r["id"]] = tick
	record("reaction", character_id, "player", ["reaction"], {"id": r["id"]}, 0)
	return r


# =====================================================================  debrief
func pretty(entity: String) -> String:
	if entity.begins_with("rival:"):
		var rs := get_node_or_null("/root/Rivals")
		var r: Dictionary = rs.get_rival(entity.substr(6)) if rs else {}
		return str(r.get("name", entity.substr(6).capitalize()))
	var c := Canon.character(entity)
	if not c.is_empty():
		return str(c.get("name", entity))
	var sp := Canon.species(entity)
	if not sp.is_empty():
		return str(sp.get("name", entity))
	return entity.replace("_", " ").capitalize()


## "What changed because of you" — one line per notable tag from this run (highest weight first).
func debrief_lines(limit: int = 6, since: int = -1) -> Array:
	var s := _run_start_tick if since < 0 else since
	var cands := events_where({"since": s, "min_weight": 2})
	cands.sort_custom(func(a, b):
		return int(a["weight"]) > int(b["weight"]) or (int(a["weight"]) == int(b["weight"]) and int(a["tick"]) > int(b["tick"])))
	var templates: Dictionary = rules.get("summaries", {})
	var used := {}
	var out: Array = []
	for e in cands:
		for t in e["tags"]:
			if templates.has(t) and not used.has(t):
				used[t] = true
				out.append(str(templates[t]).replace("{target}", pretty(str(e["target"]))).replace("{region}", pretty(str(e["region"]))))
				break
		if out.size() >= limit:
			break
	return out


# =====================================================================  engine hooks
func _after_record(e: Dictionary) -> void:
	_check_promises(e)
	_advance_all_bonds()


func _connect_events() -> void:
	Events.actor_died.connect(_on_actor_died)
	Events.ability_used.connect(_on_ability_used)
	Events.world_flag_changed.connect(_on_flag_changed)
	Events.enemy_captured.connect(_on_captured)
	Events.codex_unlocked.connect(_on_codex)
	Events.dialogue_finished.connect(_on_dialogue_finished)
	Events.scan_finished.connect(func(): add_tally("scans"))


func _on_actor_died(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var team = actor.get("team")
	var sp = actor.get("species_id")
	if str(team) == "enemy" and sp != null and str(sp) != "":
		var cls := str(Canon.species(str(sp)).get("class", "")).to_lower()
		var tags: Array = ["combat", "kill"]
		if cls == "wildlife":
			tags.append("kill_wildlife")
		elif cls == "dominion asset":
			tags.append("kill_dominion")
		if str(sp) == "augur_rig":
			tags.append("boss")
		record("killed", "player", str(sp), tags, {"species": str(sp)}, 4 if str(sp) == "augur_rig" else 1)
	elif str(team) != "enemy":
		var cid = actor.get("char_id")
		if cid != null and str(cid) != "":
			record("downed", "player", str(cid), ["casualty"], {}, 2)


func _on_ability_used(character_id: String, ability_id: String) -> void:
	add_tally("ability:%s" % ability_id)
	add_tally("enc:ability:%s" % ability_id)


func _on_flag_changed(flag: String, value: Variant) -> void:
	var key := flag
	if not (value is bool):
		key = "%s=%s" % [flag, str(value)]
	elif not value:
		return
	var fe: Dictionary = rules.get("flag_events", {})
	if not fe.has(key):
		return
	var d: Dictionary = fe[key]
	if d.has("promise"):
		var pr: Dictionary = d["promise"]
		make_promise(str(pr["id"]), str(pr["to"]), str(pr["template"]))
		return
	record(str(d.get("type", "flag")), "player", str(d.get("target", "")), d.get("tags", []), {"flag": flag}, int(d.get("weight", 2)))


func _on_captured(species_id: String) -> void:
	record("contained", "player", species_id, ["containment", "wildlife"], {}, 2)


func _on_codex(entry_id: String) -> void:
	record("discovered", "player", entry_id, ["discovery"], {}, 1)


func _on_dialogue_finished(dialogue_id: String) -> void:
	var de: Dictionary = rules.get("dialogue_events", {})
	if de.has(dialogue_id):
		var d: Dictionary = de[dialogue_id]
		record(str(d.get("type", "talked")), "player", str(d.get("target", "")), d.get("tags", []), {}, 1)
	elif dialogue_id.begins_with("hub_npc_"):
		record("talked", "player", dialogue_id.substr(8), ["social"], {}, 1)


# =====================================================================  persistence
func reset() -> void:
	tick = 0
	_next_id = 1
	_run_start_tick = 0
	era = "first_contact"
	current_region = "terrarium_one"
	events = []
	tallies = {}
	promises = {}
	bonds = {}
	seen_reactions = {}
	for c in rules.get("initial_bonds", []):
		set_bond(str(c), "bonded")


func _prune() -> void:
	var keep: Array = []
	var drop := events.size() - int(MAX_EVENTS * 0.8)
	for e in events:
		if drop > 0 and int(e["weight"]) <= 1:
			drop -= 1
		else:
			keep.append(e)
	events = keep


func to_dict() -> Dictionary:
	return {"v": 1, "tick": tick, "era": era, "region": current_region, "events": events, "tallies": tallies,
		"promises": promises, "bonds": bonds, "seen": seen_reactions, "next_id": _next_id, "run_start": _run_start_tick}


func from_dict(d: Dictionary) -> void:
	tick = int(d.get("tick", 0))
	era = str(d.get("era", "first_contact"))
	current_region = str(d.get("region", "terrarium_one"))
	events = d.get("events", [])
	for e in events:
		e["id"] = int(e["id"])
		e["tick"] = int(e["tick"])
		e["weight"] = int(e["weight"])
	tallies = d.get("tallies", {})
	for k in tallies:
		tallies[k] = int(tallies[k])
	promises = d.get("promises", {})
	for k in promises:
		promises[k]["made_tick"] = int(promises[k]["made_tick"])
		promises[k]["deadline_tick"] = int(promises[k].get("deadline_tick", 0))
	bonds = d.get("bonds", {})
	seen_reactions = d.get("seen", {})
	_next_id = int(d.get("next_id", events.size() + 1))
	_run_start_tick = int(d.get("run_start", 0))


func save() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict()))


func _load() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return false
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return false
	from_dict(d)
	return true


## QA helper: print what the ledger learned (used by tools/qa scripts).
func qa_dump() -> void:
	print("[LEDGER] events=%d tick=%d promises=%s" % [events.size(), tick, str(promises.keys())])
	for c in ["aruun", "cigarra", "zephyr", "mara", "dexter"]:
		print("[LEDGER] opinion %s = %.1f (%s) bond=%s" % [c, opinion(c), opinion_label(opinion(c)), bond_stage(c)])
	for l in debrief_lines(8, 0):
		print("[LEDGER] debrief: ", l)
	for l in opinion_shift_lines(0):
		print("[LEDGER] shift: ", l)
	var kinds := {}
	for e in events:
		kinds[e["type"]] = int(kinds.get(e["type"], 0)) + 1
	print("[LEDGER] event types: ", kinds)
