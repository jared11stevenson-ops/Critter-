extends Node
## Rivals — "Ledger Rivals" (Lead-owned autoload "Rivals"). Spec: design/LEDGER_SPEC.md §Rivals.
##
## A small cast of authored-archetype rivals (Dominion survey chiefs, poachers, Free Scale cell leaders, Helix
## recovery agents). Each has traits, remembers how the player fights (via the Ledger's per-encounter tallies),
## adapts (counter-tactics), carries scars from what hurt them, and can be resolved by force, negotiation,
## exposure, release — or a Bond Contract if they are bondable. See data game/canon/rivals.json for the design
## rules that keep this distinct from other studios' systems (no army hierarchy, no promotions, no NPC-vs-NPC
## vendettas). Not legal advice: IP review before launch.

signal rival_changed(rival_id: String, state: String)

const DATA_PATH := "res://game/canon/rivals.json"
const MAX_ADAPT := 3
const ACTIVE_STATES := ["unmet", "active", "escaped"]
const OUTCOME_TAGS := {
	"defeated": ["rival_defeated", "combat"], "escaped": ["rival_escaped"],
	"negotiated": ["rival_negotiated", "nonviolent"], "exposed": ["rival_exposed", "stewardship"],
	"released": ["rival_released", "spared"], "bonded": ["rival_bonded", "spared"],
}

var data: Dictionary = {}
var roster: Dictionary = {}
var save_path := "user://critter_rivals.json"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			data = d
	var args := OS.get_cmdline_user_args()
	if args.has("qa"):
		save_path = "user://qa_rivals.json"
		if not args.has("qa_keep_save") and FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if args.has("test_systems"):
		save_path = "user://test_rivals.json"
	if not _load():
		reset()


func reset() -> void:
	roster = {}
	for a in data.get("authored", []):
		spawn(str(a["archetype"]), str(a.get("region", "")), int(a.get("seed", -1)), a)


# =====================================================================  roster
func get_rival(id: String) -> Dictionary:
	return roster.get(id, {})


func all() -> Array:
	return roster.values()


## Rivals that can still show up in a region.
func active_in(region: String) -> Array:
	var out: Array = []
	for r in roster.values():
		if r["region"] == region and r["state"] in ACTIVE_STATES:
			out.append(r)
	return out


func _pick(rng: RandomNumberGenerator, arr: Array) -> Variant:
	return arr[rng.randi() % arr.size()]


## Generate a rival from an archetype. Deterministic for a given seed. `authored` may override id/name/title/traits.
func spawn(archetype_id: String, region: String, seed_value: int = -1, authored: Dictionary = {}) -> Dictionary:
	var arch: Dictionary = data.get("archetypes", {}).get(archetype_id, {})
	if arch.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value >= 0 else int(Time.get_ticks_usec())
	var nm: String = "%s %s" % [_pick(rng, arch["names"]["first"]), _pick(rng, arch["names"]["last"])]
	var trait_ids: Array = []
	for k in data.get("traits", {}):
		if not str(k).begins_with("_"):
			trait_ids.append(k)
	var picked: Array = []
	while picked.size() < 2 and picked.size() < trait_ids.size():
		var t: String = _pick(rng, trait_ids)
		if not (t in picked):
			picked.append(t)
	var id := str(authored.get("id", "%s_%d" % [archetype_id, rng.randi() % 100000]))
	var r := {
		"id": id, "archetype": archetype_id, "name": str(authored.get("name", nm)),
		"title": str(authored.get("title", arch.get("title", ""))), "faction": str(arch.get("faction", "")),
		"traits": authored.get("traits", picked).duplicate(), "region": region, "state": "unmet",
		"encounters": 0, "adaptations": [], "scars": [], "respect": 0, "grudge": 0,
		"last_outcome": "", "last_dominant": "", "bondable": bool(arch.get("bondable", false)),
	}
	roster[id] = r
	return r


# =====================================================================  encounters
func encounter_begin(id: String) -> void:
	var r: Dictionary = roster.get(id, {})
	if r.is_empty():
		return
	r["state"] = "active"
	Ledger.reset_encounter_tallies()
	Ledger.record("rival_encounter", "player", "rival:" + id, ["rival", "encounter"], {"n": int(r["encounters"]) + 1}, 2, str(r["region"]))
	rival_changed.emit(id, "active")


## Close an encounter. outcome: defeated | escaped | negotiated | exposed | released | bonded.
## hit_by: ability ids that landed on the rival this encounter (they leave scars).
func encounter_end(id: String, outcome: String, hit_by: Array = []) -> Dictionary:
	var r: Dictionary = roster.get(id, {})
	if r.is_empty():
		return {}
	r["encounters"] = int(r["encounters"]) + 1
	var dom := Ledger.dominant_ability_this_encounter(3)
	r["last_dominant"] = dom
	if outcome == "escaped" or outcome == "defeated":
		_adapt(r, dom)  # only the ones who walk away can use what they learned
	for ab in hit_by:
		_scar(r, str(ab))
	match outcome:
		"escaped":    r["grudge"] = int(r["grudge"]) + 1
		"negotiated": r["respect"] = int(r["respect"]) + 2
		"released":   r["respect"] = int(r["respect"]) + 2; r["grudge"] = maxi(0, int(r["grudge"]) - 1)
		"exposed":    r["grudge"] = int(r["grudge"]) + 3
	r["state"] = outcome
	r["last_outcome"] = outcome
	var tags: Array = ["rival"] + (OUTCOME_TAGS.get(outcome, []) as Array)
	Ledger.record("rival_resolved", "player", "rival:" + id, tags,
		{"outcome": outcome, "dominant": dom, "scars": r["scars"].duplicate()}, 3, str(r["region"]))
	rival_changed.emit(id, outcome)
	return r


func _adapt(r: Dictionary, dominant: String) -> void:
	if dominant == "":
		return
	var tag: String = str(data.get("counters", {}).get(dominant, ""))
	if tag == "" or tag in r["adaptations"]:
		return
	r["adaptations"].append(tag)
	while r["adaptations"].size() > MAX_ADAPT:
		r["adaptations"].pop_front()


func _scar(r: Dictionary, ability_id: String) -> void:
	var options: Array = data.get("scars", {}).get(ability_id, [])
	for s in options:
		if not (s in r["scars"]):
			r["scars"].append(s)
			return


# =====================================================================  behaviour & dialogue (consumed by gameplay)
## What the AI should do this time: base tactics + learned counters + trait tactics, aggression, flee threshold.
func behavior_profile(id: String) -> Dictionary:
	var r: Dictionary = roster.get(id, {})
	if r.is_empty():
		return {}
	var arch: Dictionary = data["archetypes"][r["archetype"]]
	var tactics: Array = (arch.get("base_tactics", []) as Array).duplicate()
	var agg := float(arch.get("aggression", 0.5))
	var flee := float(arch.get("flee_at", 0.25))
	var taunts: Array = []
	for t in r["traits"]:
		var td: Dictionary = data.get("traits", {}).get(t, {})
		agg += float(td.get("aggression", 0.0))
		flee += float(td.get("flee", 0.0))
		tactics.append_array(td.get("tactics", []))
		if td.has("taunt"):
			taunts.append(td["taunt"])
	tactics.append_array(r["adaptations"])
	agg += 0.05 * float(r["grudge"])
	return {"id": id, "name": r["name"], "title": r["title"], "tactics": tactics,
		"aggression": clampf(agg, 0.0, 1.0), "flee_at": clampf(flee, 0.05, 0.6),
		"scars": r["scars"].duplicate(), "taunts": taunts}


func scar_phrase(r: Dictionary) -> String:
	if r["scars"].is_empty():
		return ""
	return str(data.get("scar_phrases", {}).get(r["scars"][r["scars"].size() - 1], ""))


func adapt_line(r: Dictionary) -> String:
	if r["adaptations"].is_empty():
		return ""
	return str(data.get("adapt_lines", {}).get(r["adaptations"][r["adaptations"].size() - 1], ""))


## What the rival says when you meet them — shaped by what the ledger and the rival remember.
func greeting(id: String) -> Dictionary:
	var r: Dictionary = roster.get(id, {})
	if r.is_empty():
		return {}
	var arch: Dictionary = data["archetypes"][r["archetype"]]
	var pool: Array
	if int(r["encounters"]) == 0:
		pool = arch.get("intro", ["..."])
	else:
		pool = data.get("greetings", {}).get(str(r["last_outcome"]), data.get("greetings", {}).get("default_return", ["..."]))
	var tpl: String = str(pool[(int(r["encounters"]) + int(r["grudge"])) % pool.size()])
	var text := tpl.replace("{name}", str(r["name"])).replace("{title}", str(r["title"])) \
		.replace("{scar_phrase}", scar_phrase(r)).replace("{adapt_line}", adapt_line(r)).strip_edges()
	return {"text": text, "expr": "serious"}


func _deep_replace(v: Variant, from: String, to: String) -> Variant:
	if v is String:
		return to if v == from else v
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(_deep_replace(x, from, to))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _deep_replace(v[k], from, to)
		return d
	return v


## Resolution choices currently available for this rival (data-driven; see rivals.json 'resolutions').
func resolution_options(id: String) -> Array:
	var r: Dictionary = roster.get(id, {})
	var out: Array = []
	if r.is_empty():
		return out
	for res in data.get("resolutions", []):
		if res.has("needs_trait_any"):
			var ok := false
			for t in res["needs_trait_any"]:
				if t in r["traits"]:
					ok = true
					break
			if not ok:
				continue
		if res.get("needs_bondable", false) and not r["bondable"]:
			continue
		if res.has("requires"):
			var spec: Dictionary = _deep_replace(res["requires"], "$rival", "rival:" + id)
			if not Ledger.check(spec):
				continue
		out.append({"id": res["id"], "label": res["label"], "outcome": res["outcome"]})
	return out


# =====================================================================  persistence
func to_dict() -> Dictionary:
	return {"v": 1, "roster": roster}


func from_dict(d: Dictionary) -> void:
	roster = d.get("roster", {})
	for k in roster:
		for key in ["encounters", "respect", "grudge"]:
			roster[k][key] = int(roster[k].get(key, 0))


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
