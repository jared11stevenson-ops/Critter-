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

var _quests: Dictionary = {}
var _secrets: Dictionary = {}
var _stand: Dictionary = {}          # secret id -> seconds stood in range
var _pending_quest := ""
var _tick_t := 0.0

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
	for q in recipe.get("side_quests", []):
		_quests[str(q["id"])] = q
	for sc in recipe.get("secrets", []):
		_secrets[str(sc["id"])] = sc
	if not Events.ability_used.is_connected(_on_ability):
		Events.ability_used.connect(_on_ability)
	var states: Array = recipe.get("world_states", [])
	if not states.is_empty():
		affix = str(states[0].get("id", ""))
	return true

## Layer extra sites / secrets (e.g. a level's world_extra.json) on top of the recipe without editing canon data.
func merge_extra(extra: Dictionary) -> void:
	for st in extra.get("sites", []):
		if not _sites.has(str(st["id"])):
			recipe["sites"] = recipe.get("sites", []) + [st]
			_sites[str(st["id"])] = st
	for sc in extra.get("secrets", []):
		if not _secrets.has(str(sc["id"])):
			recipe["secrets"] = recipe.get("secrets", []) + [sc]
			_secrets[str(sc["id"])] = sc

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
		lines.append({"label": "res_" + str(c["id"])})
		lines.append({"who": "narration", "text": str(c.get("result", "..."))})
		lines.append({"goto": "end"})
	lines.append({"label": "end"})
	lines.append({"end": true})
	return {"lines": lines}

func play_event(event_id: String) -> bool:
	var e: Dictionary = _events.get(event_id, {})
	if e.is_empty() or host == null or host.runner == null:
		return false
	_pending_event = event_id
	return host.runner.play_data("rg_" + event_id, build_dialogue(e))

## Dialogue event hook: the host forwards every event string; returns true when it was ours.
func handle_dialogue_event(ev: String) -> bool:
	if ev.begins_with("rq:"):
		var qp := ev.substr(3).split(":")
		if qp.size() == 2:
			apply_quest_choice(qp[0], qp[1])
		return true
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
	if str(s.get("kind", "")) == "quest":
		return quest_available(str(s.get("quest", "")))
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
	for scid in _secrets:
		var sc: Dictionary = _secrets[scid]
		var t: Dictionary = sc.get("trigger", {})
		if str(t.get("mode", "")) == "interact" and t.get("pos") is Array:
			var tp: Array = t["pos"]
			out.append({"id": "rs_" + str(scid), "pos": Vector3(tp[0], tp[1], tp[2]), "r": float(t.get("r", 3.6)),
				"label": str(t.get("label", "Examine")), "cond": secret_ready.bind(sc), "act": discover_secret.bind(str(scid))})
	return out

func _activate(s: Dictionary) -> void:
	var sid := str(s["id"])
	match str(s.get("kind", "event")):
		"quest":
			play_quest(str(s.get("quest", "")))
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


# ---------------------------------------------------------------- story acts (region quest / act flags)
## Called by the host a few times a second. Completes acts whose Ledger spec is satisfied (and whose predecessor is done),
## sets the act's flag (which the Ledger turns into an event through ledger_rules.flag_events), grants its gear and, for the
## final act, picks the ending variant. Act 3 additionally waits for story.final_flag (the region's finale) when one is named.
func tick(player_pos: Vector3, delta: float) -> void:
	_tick_t -= delta
	_tick_secrets(player_pos, delta)
	if _tick_t > 0.0:
		return
	_tick_t = 0.5
	var story: Dictionary = recipe.get("story", {})
	var acts: Array = story.get("acts", [])
	for a in acts:
		var flag := str(a.get("completes_flag", ""))
		if flag == "" or bool(GameState.get_flag(flag, false)):
			continue
		if int(a.get("act", 0)) >= 3 and story.has("final_flag") and not bool(GameState.get_flag(str(story["final_flag"]), false)):
			break
		if not Ledger.check(a.get("trigger", {})):
			break
		_complete_act(a)

func _complete_act(a: Dictionary) -> void:
	GameState.set_flag(str(a["completes_flag"]), true)
	for g in a.get("reward_gear", []):
		Gear.grant(str(g))
	Events.toast.emit("%s: %s" % ["Chapter %d" % int(a.get("act", 0)), str(a.get("title", ""))], "codex")
	for v in a.get("variants", []):
		if Ledger.check(v.get("when", {})):
			GameState.set_flag(str(v.get("sets_flag", "")), true)
			Events.toast.emit(str(v.get("text", "")), "info")
			break
	var unlocked: Array = a.get("unlocks", [])
	if not unlocked.is_empty():
		Events.toast.emit("New: %d side story lead(s) in the field" % unlocked.size(), "info")

func act_done(n: int) -> bool:
	for a in recipe.get("story", {}).get("acts", []):
		if int(a.get("act", 0)) == n:
			return bool(GameState.get_flag(str(a["completes_flag"]), false))
	return false

# ---------------------------------------------------------------- side quests
func quest_available(qid: String) -> bool:
	if not _quests.has(qid) or bool(GameState.flags.get("_quest_" + qid, false)):
		return false
	for a in recipe.get("story", {}).get("acts", []):
		if qid in a.get("unlocks", []):
			return bool(GameState.get_flag(str(a["completes_flag"]), false))
	return true

func quest_dialogue(q: Dictionary) -> Dictionary:
	var lines: Array = [{"who": "narration", "text": "%s. %s" % [str(q.get("giver", "")), str(q.get("summary", ""))]}]
	var opts: Array = []
	for c in q.get("choices", []):
		opts.append({"text": str(c["label"]), "event": "rq:%s:%s" % [q["id"], c["id"]], "goto": "qr_" + str(c["id"])})
	lines.append({"choice": opts})
	for c in q.get("choices", []):
		lines.append({"label": "qr_" + str(c["id"])})
		lines.append({"who": "narration", "text": str(c.get("result", "..."))})
		lines.append({"goto": "qend"})
	lines.append({"label": "qend"})
	lines.append({"end": true})
	return {"lines": lines}

func play_quest(qid: String) -> bool:
	var q: Dictionary = _quests.get(qid, {})
	if q.is_empty() or host == null or host.runner == null:
		return false
	return host.runner.play_data("rq_" + qid, quest_dialogue(q))

func apply_quest_choice(qid: String, cid: String) -> void:
	var q: Dictionary = _quests.get(qid, {})
	for c in q.get("choices", []):
		if str(c["id"]) != cid:
			continue
		for r in c.get("records", []):
			Ledger.record(str(r["type"]), "player", str(r.get("target", "")), r.get("tags", []), r.get("data", {}), int(r.get("weight", 1)), id)
		if c.has("sets_flag"):
			GameState.set_flag(str(c["sets_flag"]), true)
		if c.has("consequence"):
			GameState.flags["_cons_" + qid] = str(c["consequence"])
	GameState.flags["_quest_" + qid] = true
	for g in q.get("reward_gear", []):
		Gear.grant(str(g))
	Ledger.record("descent_event", "player", qid, ["descent"], {"choice": cid}, 0, id)
	for sid in _sites:
		if str(_sites[sid].get("quest", "")) == qid:
			_finish_site(sid)
	GameState.save_game()

## Consequence lines for finished quests (hub, codex or journal can show them).
func consequences() -> Array:
	var out: Array = []
	for qid in _quests:
		var c := str(GameState.flags.get("_cons_" + str(qid), ""))
		if c != "":
			out.append(c)
	return out

# ---------------------------------------------------------------- secrets
func secret_found(sid: String) -> bool:
	return bool(GameState.flags.get("_secret_" + sid, false))

func _needs_ok(t: Dictionary) -> bool:
	var need := str(t.get("needs", ""))
	return need == "" or bool(GameState.get_flag("world_" + need, false))

func secret_ready(sc: Dictionary) -> bool:
	var t: Dictionary = sc.get("trigger", {})
	if t.is_empty() or secret_found(str(sc["id"])):
		return false
	if t.has("when") and not Ledger.check(t["when"]):
		return false
	return _needs_ok(t)

func _in_range(t: Dictionary, p: Vector3) -> bool:
	if not t.get("pos") is Array:
		return false
	var tp: Array = t["pos"]
	return Vector2(p.x - float(tp[0]), p.z - float(tp[2])).length() <= float(t.get("r", 4.0))

func _tick_secrets(p: Vector3, delta: float) -> void:
	for sid in _secrets:
		var sc: Dictionary = _secrets[sid]
		var t: Dictionary = sc.get("trigger", {})
		if str(t.get("mode", "")) != "stand" or not _in_range(t, p) or not secret_ready(sc):
			_stand.erase(sid)
			continue
		_stand[sid] = float(_stand.get(sid, 0.0)) + delta
		if float(_stand[sid]) >= float(t.get("stand_s", 2.0)):
			discover_secret(str(sid))

func _on_ability(_char: String, ability: String) -> void:
	if host == null or not host.has_method("player_position"):
		return
	var p: Vector3 = host.player_position()
	for sid in _secrets:
		var sc: Dictionary = _secrets[sid]
		var t: Dictionary = sc.get("trigger", {})
		if str(t.get("mode", "")) == "ability" and str(t.get("ability", "")) == ability and _in_range(t, p) and secret_ready(sc):
			discover_secret(str(sid))

func discover_secret(sid: String) -> void:
	var sc: Dictionary = _secrets.get(sid, {})
	if sc.is_empty() or secret_found(sid):
		return
	GameState.flags["_secret_" + sid] = true
	Ledger.record("discovered", "player", sid, sc.get("ledger_tags", ["discovery"]), {}, 3, id)
	for g in sc.get("reward_gear", []):
		Gear.grant(str(g))
	var ri: Dictionary = sc.get("reward_items", {})
	for it in ri:
		GameState.add_item(str(it), int(ri[it]))
		Events.toast.emit("+%d %s" % [int(ri[it]), UiKit.item_name(str(it))], "item")
	Events.toast.emit("Secret found: %s" % str(sc.get("name", sid)), "codex")
	Audio.sfx("ui_confirm")
	if host and host.runner:
		host.runner.play_data("rs_" + sid, {"lines": [{"who": "narration", "text": str(sc.get("reward", ""))}]})
	GameState.save_game()

func secrets_found() -> int:
	var n := 0
	for sid in _secrets:
		if secret_found(str(sid)):
			n += 1
	return n
