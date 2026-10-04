class_name RrNpcs
extends Node
## Red Reaches living NPCs (design/DATA_REQUESTS.md section 8). Spawns the 12 sapient locals as skinned 3D models
## (res://game/art/models/npcs/npc_registry.json), moves them between schedule stations on a slow world clock
## (dawn, day, dusk, night), gives each a Talk interactable that picks meet / turnin / quest / react / repeat,
## shows gated barks above their heads, handles the dialogue events rec:<id>, offer:<quest>, lead:<id>, and
## places the readable ambient signs/placards. Cost: 12 pooled nodes, one 1 Hz timer, models hidden when far.

const DATA := "res://game/canon/npcs/red_reaches.json"
const AMBIENT := "res://game/canon/npcs/red_reaches_ambient.json"
const REGISTRY := "res://game/art/models/npcs/npc_registry.json"
const PHASES := ["dawn", "day", "dusk", "night"]
const PHASE_SECONDS := 100.0
const SHOW_RANGE := 70.0
const BARK_RANGE := 9.0
const REACT_FLAGS := ["rr_act1_done", "rr_act2_done", "rr_act3_done", "boss_defeated", "rr_complete"]
## Station id (region layer, spoke, spoke hub or landmark) -> world XZ in the Red Reaches layout.
const STATIONS := {
	"gate_pad": Vector2(2, 6), "valley": Vector2(58, -2), "fracture_valley": Vector2(58, -2), "echo_hollow": Vector2(64, -22),
	"waystation": Vector2(116, -4), "drovers_rest": Vector2(128, -26), "salt_pans": Vector2(111, 26), "boulder_pass": Vector2(146, -1),
	"thought_vault": Vector2(160, -26), "basin": Vector2(196, 8), "drill_basin": Vector2(196, 6), "cistern": Vector2(186, -34),
	"span_approach": Vector2(240, -14), "overlook": Vector2(238, -28), "ochre_span": Vector2(262, 6), "red_span_remnant": Vector2(96, -6),
	"spanwright_yard": Vector2(226, -6), "well_line": Vector2(106, 28), "grazer_flats": Vector2(126, 8), "augur_pit": Vector2(212, -4),
}

var level: Node3D
var runner: DialogueRunner
var region: RegionRunner
var _defs: Dictionary = {}
var _reg: Dictionary = {}
var _npcs: Dictionary = {}        # id -> {def, root, model, label, inter, phase, pos, bark_t, bark_i}
var _amb: Array = []              # [{def, pos, label3d}]
var _inter: Array = []
var _clock := 0.0
var _tick_t := 0.0
var _talking := ""
var _pending_offer := ""
var _rng := RandomNumberGenerator.new()
var _bubble_ids: Array = []


func setup(lvl: Node3D, run: DialogueRunner, reg: RegionRunner) -> void:
	level = lvl
	runner = run
	region = reg
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	_defs = _load_json(DATA)
	_reg = _load_json(REGISTRY)
	_clock = PHASE_SECONDS * 0.5       # the run starts mid-"dawn" light; day follows soon
	for n in _defs.get("npcs", []):
		_make_npc(n)
	for a in _load_json(AMBIENT).get("lines", []):
		_make_ambient(a)
	runner.finished.connect(_on_finished)
	_refresh(true)


func _load_json(p: String) -> Dictionary:
	var f := FileAccess.open(p, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	return d if d is Dictionary else {}


func phase() -> String:
	return PHASES[int(_clock / PHASE_SECONDS) % PHASES.size()]


# ------------------------------------------------------------------ building
func _make_npc(def: Dictionary) -> void:
	var id := str(def["id"])
	var root := Node3D.new()
	root.name = "RRNpc_" + id
	level.add_child(root)
	var model: Node3D = null
	var scene_path := str(_reg.get(id, {}).get("scene", "res://game/art/models/npcs/%s/%s_model.tscn" % [id, id]))
	if ResourceLoader.exists(scene_path):
		var ps: PackedScene = load(scene_path)
		model = ps.instantiate() as Node3D
	if model == null:
		model = VisualFactory.character(id)
	model.name = "Model"
	root.add_child(model)
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.fixed_size = true
	lab.pixel_size = 0.0011
	lab.font_size = 32
	lab.outline_size = 10
	lab.no_depth_test = true
	lab.modulate = UiKit.char_color(id).lightened(0.55)
	lab.visible = false
	lab.position = Vector3(0, float(model.call("get_height")) + 0.5 if model.has_method("get_height") else 2.2, 0)
	root.add_child(lab)
	var inter := {"id": "rrn_" + id, "pos": Vector3.ZERO, "r": 3.4, "label": "Talk: " + str(def.get("name", id)),
		"cond": _npc_active.bind(id), "act": _talk.bind(id)}
	_inter.append(inter)
	_npcs[id] = {"def": def, "root": root, "model": model, "label": lab, "inter": inter, "phase": "", "pos": Vector3.ZERO,
		"bark_t": _rng.randf_range(4.0, 12.0), "bark_i": 0, "hide": false}


func _make_ambient(a: Dictionary) -> void:
	var st := str(a.get("station", ""))
	if not STATIONS.has(st):
		return
	var kind := str(a.get("kind", "sign"))
	var p2: Vector2 = STATIONS[st] + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4))
	var pos := Vector3(p2.x, level.height_at(p2.x, p2.y), p2.y)
	var entry := {"def": a, "pos": pos, "read": false}
	_amb.append(entry)
	if kind == "sign" or kind == "placard":
		_inter.append({"id": "rra_" + str(a["id"]), "pos": pos, "r": 3.0, "label": "Read" if kind == "sign" else "Examine",
			"cond": _amb_ready.bind(entry), "act": _read_amb.bind(entry)})


func interactables() -> Array:
	return _inter


func _amb_ready(e: Dictionary) -> bool:
	return _gate(e["def"])


func _read_amb(e: Dictionary) -> void:
	Events.toast.emit(str(e["def"].get("text", "")), "info")
	e["read"] = true


# ------------------------------------------------------------------ schedule / presence
func _station_for(def: Dictionary, ph: String) -> Dictionary:
	var best: Dictionary = {}
	for s in def.get("schedule", []):
		if str(s.get("when", "")) == ph:
			return s
		if best.is_empty():
			best = s
	return best


func _site_pos(site: String) -> Variant:
	for s in region.recipe.get("sites", []) if region else []:
		if str(s["id"]) == site:
			var p: Array = s["pos"]
			return Vector2(float(p[0]) + 2.2, float(p[2]) + 1.0)
	return null


func _station_pos(entry: Dictionary) -> Vector3:
	var st := str(entry.get("station", ""))
	var p2: Vector2 = STATIONS.get(st, Vector2(116, -4))
	if entry.has("site"):
		var sp: Variant = _site_pos(str(entry["site"]))
		if sp is Vector2:
			p2 = sp
	else:
		# spread the cast around a shared station so nobody overlaps
		p2 += Vector2(float(hash(str(entry.get("who", ""))) % 7) - 3.0, float(hash(str(entry.get("who", ""))) % 5) - 2.0)
	return Vector3(p2.x, level.height_at(p2.x, p2.y), p2.y)


func _refresh(force: bool = false) -> void:
	var ph := phase()
	var pp := _player_pos()
	for id in _npcs:
		var n: Dictionary = _npcs[id]
		if n["phase"] != ph:
			var st := _station_for(n["def"], ph).duplicate()
			st["who"] = id
			var np := _station_pos(st)
			# relocate only while the player cannot see it happen
			if force or pp.distance_to(n["pos"]) > 32.0 or n["phase"] == "":
				n["phase"] = ph
				n["pos"] = np
				(n["root"] as Node3D).global_position = np
				(n["inter"] as Dictionary)["pos"] = np
				_face_player(n, pp, true)
		var hide: bool = id == "vesk_dunmore" and _vesk_rival_active()
		n["hide"] = hide
		var near: bool = pp.distance_to(n["pos"]) < SHOW_RANGE and not hide
		(n["root"] as Node3D).visible = near
		(n["root"] as Node3D).process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED


func _vesk_rival_active() -> bool:
	var r: Variant = level.get("rivals")
	if r == null:
		return false
	var live: Dictionary = r.get("live")
	var e: Variant = live.get("poacher_vesk")
	return e != null and is_instance_valid(e)


func _npc_active(id: String) -> bool:
	var n: Dictionary = _npcs[id]
	return not n["hide"] and (n["root"] as Node3D).visible and not _is_busy()


func _is_busy() -> bool:
	return runner != null and runner.is_running()


func _player_pos() -> Vector3:
	return level.call("player_position") if level.has_method("player_position") else Vector3.ZERO


func _face_player(n: Dictionary, pp: Vector3, snap: bool = false) -> void:
	var m: Node = n["model"]
	var d: Vector3 = pp - (n["root"] as Node3D).global_position
	d.y = 0.0
	if d.length() > 0.1 and m.has_method("set_facing"):
		m.call("set_facing", d)


func _process(delta: float) -> void:
	_clock += delta
	_tick_t -= delta
	if _tick_t > 0.0:
		return
	_tick_t = 1.0
	_clock += 0.0
	_refresh()
	_barks()


# ------------------------------------------------------------------ flags / gates
func _flag(f: String) -> bool:
	var v: Variant = GameState.get_flag(f, false)
	if v is bool:
		return v
	return v != null and v != "" and v != 0


func _gate(d: Dictionary) -> bool:
	DialogueRunner.sync_derived_flags()
	if d.has("if") and not _flag(str(d["if"])):
		return false
	if d.has("if_not") and _flag(str(d["if_not"])):
		return false
	return true


func _barks() -> void:
	if _is_busy():
		return
	var pp := _player_pos()
	for id in _npcs:
		var n: Dictionary = _npcs[id]
		var lab: Label3D = n["label"]
		n["bark_t"] -= 1.0
		if n["bark_t"] < -5.0 or (lab.visible and n["bark_t"] < 0.0):
			lab.visible = false
			n["bark_t"] = _rng.randf_range(14.0, 26.0)
			continue
		if n["bark_t"] > 0.0 or lab.visible or n["hide"]:
			continue
		var d: float = pp.distance_to(n["pos"])
		if d > BARK_RANGE:
			n["bark_t"] = 3.0
			continue
		var ok: Array = []
		for b in n["def"].get("barks", []):
			if _gate(b):
				ok.append(b)
		if ok.is_empty():
			n["bark_t"] = 20.0
			continue
		n["bark_i"] = (int(n["bark_i"]) + 1 + _rng.randi() % 2) % ok.size()
		lab.text = str(ok[n["bark_i"]].get("text", ""))
		lab.width = 520.0
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.visible = true
		n["bark_t"] = 0.0
		_face_player(n, pp)
	# overheard / wind lines: only when no NPC is within earshot
	for e in _amb:
		var k := str(e["def"].get("kind", ""))
		if (k == "wind" or k == "overheard") and not e["read"] and pp.distance_to(e["pos"]) < 7.0 and _gate(e["def"]):
			e["read"] = true
			Events.toast.emit(str(e["def"].get("text", "")), "info")


# ------------------------------------------------------------------ talking
func _react_key() -> String:
	var k := ""
	for f in REACT_FLAGS:
		if _flag(f):
			k += f[3] if f.length() > 3 else "x"
			k += str(REACT_FLAGS.find(f))
	return k


func _talk(id: String) -> void:
	var n: Dictionary = _npcs[id]
	var def: Dictionary = n["def"]
	var dl: Dictionary = def.get("dialogue", {})
	var gives: Array = def.get("quests", {}).get("gives", [])
	_face_player(n, _player_pos())
	(n["label"] as Label3D).visible = false
	var pick := ""
	var met := _flag(str(def.get("flag_met", "rrn_%s_met" % id)))
	if not met:
		pick = str(dl.get("meet", ""))
	else:
		for q in gives:
			if _flag("_quest_" + str(q)) and not _flag("_rrn_turnin_" + str(q)):
				GameState.set_flag("_rrn_turnin_" + str(q), true)
				pick = str(dl.get("turnin", ""))
				break
		if pick == "":
			for q in gives:
				if region and region.quest_available(str(q)) and not _flag("rrn_%s_offered" % str(q)) and not _flag("_offered_" + str(q)):
					pick = str(dl.get("quest", ""))
					break
		if pick == "":
			var key := _react_key()
			if key != "" and str(GameState.get_flag("_rrn_react_" + id, "")) != key and dl.has("react"):
				GameState.set_flag("_rrn_react_" + id, key)
				pick = str(dl.get("react", ""))
		if pick == "":
			pick = str(dl.get("repeat", ""))
	if pick == "" or not DialogueRunner.exists(pick):
		return
	_talking = id
	runner.play(pick, true)
	GameState.set_flag(str(def.get("flag_met", "rrn_%s_met" % id)), true)
	var m: Node = n["model"]
	if m.has_method("play_anim") and m.has_method("has_anim") and m.call("has_anim", "gesture"):
		m.call("play_anim", "gesture")


func _on_finished(_id: String) -> void:
	_talking = ""
	if _pending_offer != "":
		var q := _pending_offer
		_pending_offer = ""
		if region and region.quest_available(q) and not _flag("_quest_" + q):
			region.play_quest.call_deferred(q)


func handle_dialogue_event(ev: String) -> bool:
	if ev.begins_with("rec:"):
		_record(ev.substr(4))
		return true
	if ev.begins_with("offer:"):
		var q := ev.substr(6)
		GameState.flags["_offered_" + q] = true
		Events.toast.emit("Quest offered: %s" % _quest_title(q), "info")
		_pending_offer = q
		return true
	if ev.begins_with("lead:"):
		var l := ev.substr(5)
		GameState.flags["_lead_" + l] = true
		Events.toast.emit("Journal lead: %s" % l.replace("_", " ").capitalize(), "codex")
		return true
	return false


func _quest_title(q: String) -> String:
	for s in region.recipe.get("side_quests", []) if region else []:
		if str(s["id"]) == q:
			return str(s.get("title", q))
	return q


func _record(rid: String) -> void:
	var def: Dictionary = {}
	if _talking != "" and _npcs.has(_talking):
		def = _npcs[_talking]["def"]
	if not def.get("records", {}).has(rid):
		for id in _npcs:                       # fall back to whichever NPC owns this record id
			if _npcs[id]["def"].get("records", {}).has(rid):
				def = _npcs[id]["def"]
				break
	var r: Dictionary = def.get("records", {}).get(rid, {})
	if r.is_empty():
		return
	Ledger.record(str(r.get("type", "chose")), "player", str(r.get("target", "")), r.get("tags", []), {"npc_record": rid},
		int(r.get("weight", 1)), "red_reaches")


## QA: stand the cast in a line (rows of six) in front of the player, ignoring the schedule, for screenshots.
func qa_lineup(origin: Vector3) -> void:
	var i := 0
	for id in _npcs:
		var n: Dictionary = _npcs[id]
		var p := origin + Vector3(-9.0 + float(i % 6) * 3.6, 0, -4.0 - float(i / 6) * 4.0)
		p.y = level.height_at(p.x, p.z)
		n["pos"] = p
		n["phase"] = phase()
		n["hide"] = false
		(n["root"] as Node3D).global_position = p
		(n["root"] as Node3D).visible = true
		(n["inter"] as Dictionary)["pos"] = p
		_face_player(n, origin)
		i += 1
	_clock = PHASE_SECONDS * 0.5
