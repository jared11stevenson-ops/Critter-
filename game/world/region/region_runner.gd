class_name RegionRunner
extends RefCounted
## Generic region runner: reads game/canon/regions/<id>.json (the region recipe) and runs its optional content in any
## level that offers the small host interface below. A new homeland is data: write the recipe, give its level layout.json
## floors for the spokes, and add this runner. Nothing here knows about the Red Reaches.
##
## Recipe keys used: descent_events[], world_states[], spokes[] {id,name,trigger,blurb,codex,fresh}, sites[] {id,spoke,pos,
## kind(event|cache|lore),event,label,r,secret,requires_flag,item,n,codex,text}.
## Host interface (all optional except the first three): ground(Vector3, lift)->Vector3, runner: DialogueRunner,
## party: PartyController, spawn_pickup(kind,pos,n,key), field.
##
## Descent-event contract (design/DATA_REQUESTS.md section 3): events are filtered by `when` (Ledger.check), `once`
## events already taken are dropped (Ledger descent_event record), the pick is weighted by `weight` plus the active
## world-state `event_weight_mods`. A choice records its `records[]` in the Ledger for the current region, makes its
## `promise`, and always logs {type: descent_event, target: <event id>, tags: [descent], weight: 0, data: {choice}}.

signal site_done(site_id: String)
signal spoke_entered(spoke_id: String)

const DIR := "res://game/canon/regions/"
const PICK := "rg:"

var id := ""
var recipe: Dictionary = {}
var host: Node = null
var affix := ""
var _events: Dictionary = {}
var _spokes: Dictionary = {}
var _sites: Dictionary = {}
var _site_nodes: Dictionary = {}     # site id -> Label3D marker
var _revealed: Dictionary = {}
var _pending_event := ""

static func load_recipe(region_id: String) -> Dictionary:
	var p := DIR + region_id + ".json"
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	return d if d is Dictionary else {}

func setup(region_id: String, host_node: Node) -> bool:
	id = region_id
	host = host_node
	recipe = load_recipe(id)
	if recipe.is_empty():
		push_warning("RegionRunner: no recipe for %s" % id)
		return false
	for e in recipe.get("descent_events", []):
		_events[str(e["id"])] = e
	for s in recipe.get("spokes", []):
		_spokes[str(s["id"])] = s
	for s in recipe.get("sites", []):
		_sites[str(s["id"])] = s
	var states: Array = recipe.get("world_states", [])
	if not states.is_empty():
		affix = str(states[0].get("id", ""))
	return true

# ---------------------------------------------------------------- events
func event_taken(event_id: String) -> bool:
	return Ledger.exists({"type": "descent_event", "target": event_id}) or bool(GameState.flags.get("_rg_" + event_id, false))

func event_weight(e: Dictionary) -> float:
	var w := float(e.get("weight", 1))
	for st in recipe.get("world_states", []):
		if str(st.get("id", "")) == affix:
			w += float(st.get("event_weight_mods", {}).get(str(e["id"]), 0))
	return maxf(w, 0.0)

func available_events(depth: int = 0, kind: String = "") -> Array:
	var out: Array = []
	for e in recipe.get("descent_events", []):
		if int(e.get("min_depth", 0)) > depth:
			continue
		if kind != "" and str(e.get("kind", "")) != kind:
			continue
		if bool(e.get("once", false)) and event_taken(str(e["id"])):
			continue
		if e.has("when") and not Ledger.check(e["when"]):
			continue
		out.append(e)
	return out

## Weighted pick among the events that qualify right now ({} when none).
func pick_event(depth: int = 0, kind: String = "") -> Dictionary:
	var pool := available_events(depth, kind)
	var total := 0.0
	for e in pool:
		total += event_weight(e)
	if pool.is_empty() or total <= 0.0:
		return {}
	var r := randf() * total
	for e in pool:
		r -= event_weight(e)
		if r <= 0.0:
			return e
	return pool[-1]

## Dialogue data (DialogueRunner format) for an event: narration, then its choices, then the chosen result.
func build_dialogue(e: Dictionary) -> Dictionary:
	var lines: Array = [{"who": "narration", "text": str(e.get("text", ""))}]
	var opts: Array = []
	for c in e.get("choices", []):
		if c.has("requires") and not Ledger.check(c["requires"]):
			continue
		opts.append({"text": str(c["label"]), "event": "%s%s:%s" % [PICK, e["id"], c["id"]], "goto": "res_" + str(c["id"])})
	lines.append({"choice": opts})
	for c in e.get("choices", []):
		lines.append({"label": "res_" + str(c["id"]), "who": "narration", "text": str(c.get("result", "..."))})
		lines.append({"goto": "end"})
	lines.append({"label": "end", "end": true})
	return {"lines": lines}

func play_event(event_id: String) -> bool:
	var e: Dictionary = _events.get(event_id, {})
	if e.is_empty() or host == null or host.runner == null:
		return false
	_pending_event = event_id
	return host.runner.play_data("rg_" + event_id, build_dialogue(e))

## Dialogue event hook: the host forwards every event string; returns true when it was ours.
func handle_dialogue_event(ev: String) -> bool:
	if not ev.begins_with(PICK):
		return false
	var parts := ev.substr(PICK.length()).split(":")
	if parts.size() == 2:
		apply_choice(parts[0], parts[1])
	return true

func apply_choice(event_id: String, choice_id: String) -> void:
	var e: Dictionary = _events.get(event_id, {})
	for c in e.get("choices", []):
		if str(c["id"]) != choice_id:
			continue
		for r in c.get("records", []):
			Ledger.record(str(r["type"]), "player", str(r.get("target", "")), r.get("tags", []), r.get("data", {}), int(r.get("weight", 1)), id)
		if c.has("promise"):
			var pr: Dictionary = c["promise"]
			Ledger.make_promise(str(pr["id"]), str(pr["to"]), str(pr["template"]))
	Ledger.record("descent_event", "player", event_id, ["descent"], {"choice": choice_id}, 0, id)
	GameState.flags["_rg_" + event_id] = true
	for sid in _sites:
		if str(_sites[sid].get("event", "")) == event_id:
			_finish_site(sid)
	GameState.save_game()

# ---------------------------------------------------------------- spokes & sites
func spoke(spoke_id: String) -> Dictionary:
	return _spokes.get(spoke_id, {})

func spoke_triggers() -> Array:
	var out: Array = []
	for sid in _spokes:
		var s: Dictionary = _spokes[sid]
		if s.has("trigger"):
			out.append({"id": "t_" + str(sid), "pos": s["trigger"]["pos"], "r": s["trigger"]["r"], "event": "spoke:" + str(sid)})
	return out

func visited_spokes() -> int:
	var n := 0
	for sid in _spokes:
		if bool(GameState.flags.get("_spoke_" + str(sid), false)):
			n += 1
	return n

func total_spokes() -> int:
	return _spokes.size()

## First entry: mark visited, unlock the codex page, record a discovery, and toast the progress.
func enter_spoke(spoke_id: String) -> void:
	var s: Dictionary = _spokes.get(spoke_id, {})
	if s.is_empty() or bool(GameState.flags.get("_spoke_" + spoke_id, false)):
		return
	GameState.flags["_spoke_" + spoke_id] = true
	if s.has("codex"):
		GameState.unlock_codex(str(s["codex"]))
	Ledger.record("discovered", "player", spoke_id, ["discovery", "curiosity"], {}, 1, id)
	Events.toast.emit("Found: %s (%d/%d side areas)" % [s.get("name", spoke_id), visited_spokes(), total_spokes()], "codex")
	spoke_entered.emit(spoke_id)

func site_done_flag(site_id: String) -> bool:
	return bool(GameState.flags.get("_site_" + site_id, false))

func _finish_site(site_id: String) -> void:
	GameState.flags["_site_" + site_id] = true
	site_done.emit(site_id)

func _site_visible(s: Dictionary) -> bool:
	var sid := str(s["id"])
	if site_done_flag(sid):
		return false
	if s.has("requires_flag") and not bool(GameState.get_flag(str(s["requires_flag"]), false)):
		return false
	if bool(s.get("secret", false)) and not _revealed.has(sid) and not bool(GameState.flags.get("_rev_" + sid, false)):
		return false
	return true

## Reveal secret sites within `radius` of `p` (a SCAN or a close approach). Returns how many were revealed.
func reveal_near(p: Vector3, radius: float) -> int:
	var n := 0
	for sid in _sites:
		var s: Dictionary = _sites[sid]
		if not bool(s.get("secret", false)) or _revealed.has(sid) or site_done_flag(str(sid)):
			continue
		var sp: Array = s["pos"]
		if Vector2(p.x - float(sp[0]), p.z - float(sp[2])).length() <= radius:
			_revealed[sid] = true
			GameState.flags["_rev_" + str(sid)] = true
			n += 1
	if n > 0:
		Events.toast.emit("Scan: something is hidden nearby", "codex")
		Audio.sfx("scan")
	return n

func has_unrevealed_near(p: Vector3, radius: float) -> bool:
	for sid in _sites:
		var s: Dictionary = _sites[sid]
		if bool(s.get("secret", false)) and not _revealed.has(sid) and not site_done_flag(str(sid)):
			var sp: Array = s["pos"]
			if Vector2(p.x - float(sp[0]), p.z - float(sp[2])).length() <= radius:
				return true
	return false

func sites_done() -> int:
	var n := 0
	for sid in _sites:
		if site_done_flag(str(sid)):
			n += 1
	return n

func total_sites() -> int:
	return _sites.size()

## Interactable dictionaries in the level's own format ({id,pos,r,label,cond,act}). The host adds its own marker.
func interactables() -> Array:
	var out: Array = []
	for sid in _sites:
		var s: Dictionary = _sites[sid]
		var sp: Array = s["pos"]
		out.append({"id": "rg_" + str(sid), "pos": Vector3(sp[0], sp[1], sp[2]), "r": float(s.get("r", 3.6)),
			"label": str(s.get("label", "Examine")), "cond": _site_visible.bind(s), "act": _activate.bind(s)})
	return out

func _activate(s: Dictionary) -> void:
	var sid := str(s["id"])
	match str(s.get("kind", "event")):
		"event":
			play_event(str(s.get("event", "")))
		"cache":
			_finish_site(sid)
			var item := str(s.get("item", "salvage"))
			var n := int(s.get("n", 1))
			if host and host.has_method("spawn_pickup"):
				var sp: Array = s["pos"]
				for k in n:
					host.spawn_pickup(item, Vector3(float(sp[0]) + randf_range(-1.2, 1.2), float(sp[1]), float(sp[2]) + randf_range(-1.2, 1.2)), 1, "")
			if s.has("text"):
				Events.toast.emit(str(s["text"]), "item")
			Ledger.record("discovered", "player", sid, ["discovery"], {}, 1, id)
			Audio.sfx("ui_confirm")
		"lore":
			_finish_site(sid)
			if s.has("codex"):
				GameState.unlock_codex(str(s["codex"]))
			Events.toast.emit(str(s.get("text", "")), "codex")
			Ledger.record("discovered", "player", sid, ["discovery", "curiosity"], {}, 1, id)
