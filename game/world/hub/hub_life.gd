class_name HubLife
extends Node
## Terrarium One ambient life: the cast wander between a few stations, glance around, speak short barks in a bubble, and
## occasionally walk over to each other for a short exchange. All data lives in game/narrative/hub_ambient.json.
## Cost model: 8 NPCs, one timer, two pooled bubbles; nothing allocates per frame, nothing runs while a dialogue/menu is up
## (the tree is paused) or the camera is far from the speaker.

const DATA := "res://game/narrative/hub_ambient.json"
const WALK_SPEED := 1.25
const HEAR_RANGE := 15.0

var hub: Node3D
var cam: Camera3D
var ui_root: Control
var focus_getter: Callable
var anchor_getter: Callable     # id -> Rect2 of that NPC's hotspot label on screen (or an empty Rect2)
var _npcs: Dictionary = {}      # id -> {node, bb, home, stations[], state, target, wait, y, face}
var _lines: Dictionary = {}
var _pairs: Array = []
var _bubbles: Array = []        # [{panel, label, who, t, node}]
var _bark_t := 4.0
var _pair_t := 22.0
var _pair: Dictionary = {}      # active pair state
var _rng := RandomNumberGenerator.new()
var enabled := true

func setup(hub_node: Node3D, visual: Node3D, camera: Camera3D, ui: Control, focus_fn: Callable, anchor_fn: Callable) -> void:
	hub = hub_node
	cam = camera
	ui_root = ui
	focus_getter = focus_fn
	anchor_getter = anchor_fn
	_rng.randomize()
	var f := FileAccess.open(DATA, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if not (d is Dictionary):
		enabled = false
		return
	_lines = d.get("lines", {})
	_pairs = d.get("pairs", [])
	var faces: Dictionary = {}
	var scr: Script = visual.get_script()
	if scr:
		faces = scr.get_script_constant_map().get("NPC_FACING", {})
	var stations: Dictionary = d.get("stations", {})
	for id in stations:
		var n := visual.find_child("NPC_" + str(id), true, false) as Node3D
		if n == null:
			continue
		var bb := n.get_node_or_null("Model")
		var st: Array = []
		for p in stations[id]:
			st.append(Vector3(float(p[0]), n.position.y, float(p[1])))
		_npcs[id] = {"node": n, "bb": bb, "home": n.position, "stations": st, "state": "idle", "target": n.position,
			"wait": _rng.randf_range(2.0, 8.0), "face": Vector3(0, 0, 1)}
		_npcs[id]["face"] = faces.get(id, Vector3(0, 0, 1))
	for i in 2:
		_bubbles.append(_make_bubble())

func _make_bubble() -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.94), UiKit.PARCHMENT_DARK.darkened(0.3), 16, 3, 14))
	var l := UiKit.label("", 22, UiKit.INK, "dialogue")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(250, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)
	panel.visible = false
	panel.z_index = -1
	ui_root.add_child(panel)
	return {"panel": panel, "label": l, "who": "", "t": 0.0, "node": null}

# ------------------------------------------------------------------ per frame
func _process(delta: float) -> void:
	if not enabled:
		return
	for id in _npcs:
		_tick_npc(_npcs[id], delta)
	_tick_bubbles(delta)
	_bark_t -= delta
	if _bark_t <= 0.0:
		_bark_t = _rng.randf_range(6.0, 11.0)
		_bark()
	_pair_t -= delta
	if _pair_t <= 0.0 and _pair.is_empty():
		_pair_t = _rng.randf_range(40.0, 70.0)
		_start_pair()
	if not _pair.is_empty():
		_tick_pair(delta)

func _tick_npc(n: Dictionary, delta: float) -> void:
	var node: Node3D = n["node"]
	var bb: Node = n["bb"]
	match n["state"]:
		"walk":
			var tp: Vector3 = n["target"]
			var d := tp - node.position
			d.y = 0.0
			var dist := d.length()
			if dist < 0.12:
				n["state"] = "idle"
				n["wait"] = _rng.randf_range(4.0, 11.0)
				if bb and bb.has_method("set_move_amount"):
					bb.set_move_amount(0.0)
				return
			var step := minf(dist, WALK_SPEED * delta)
			node.position += d / dist * step
			if bb and bb.has_method("set_facing"):
				bb.set_facing(d)
		"idle":
			n["wait"] = float(n["wait"]) - delta
			if float(n["wait"]) <= 0.0:
				n["wait"] = _rng.randf_range(4.0, 10.0)
				var roll := _rng.randf()
				var sts: Array = n["stations"]
				if roll < 0.45 and sts.size() > 1 and _pair.is_empty():
					walk_to(n, sts[_rng.randi() % sts.size()])
				elif bb and bb.has_method("set_facing"):
					# glance somewhere else
					var base: Vector3 = n["face"]
					bb.set_facing(base.rotated(Vector3.UP, _rng.randf_range(-1.6, 1.6)))
		_:
			pass

func walk_to(n: Dictionary, p: Vector3) -> void:
	n["target"] = p
	n["state"] = "walk"
	var bb: Node = n["bb"]
	if bb and bb.has_method("set_move_amount"):
		bb.set_move_amount(1.0)

# ------------------------------------------------------------------ barks
func _near_focus(node: Node3D) -> bool:
	var f: Vector3 = focus_getter.call()
	return Vector2(node.global_position.x - f.x, node.global_position.z - f.z).length() < HEAR_RANGE

func _eligible(line: Dictionary) -> bool:
	if line.has("if") and not bool(GameState.get_flag(str(line["if"]), false)):
		return false
	if line.has("if_not") and bool(GameState.get_flag(str(line["if_not"]), false)):
		return false
	return true

func _bark() -> void:
	if not _pair.is_empty():
		return
	var ids: Array = _npcs.keys()
	ids.shuffle()
	for id in ids:
		var n: Dictionary = _npcs[id]
		if not _near_focus(n["node"]) or _speaking(n["node"]):
			continue
		var pool: Array = []
		for l in _lines.get(id, []):
			if _eligible(l):
				pool.append(l)
		if pool.is_empty():
			continue
		say(id, str(pool[_rng.randi() % pool.size()]["text"]))
		return

func _speaking(node: Node3D) -> bool:
	for b in _bubbles:
		if b["node"] == node and (b["panel"] as Control).visible:
			return true
	return false

func say(id: String, text: String, free_bubble_only: bool = false) -> void:
	var n: Dictionary = _npcs.get(id, {})
	if n.is_empty():
		return
	var slot: Dictionary = {}
	for b in _bubbles:
		if not (b["panel"] as Control).visible:
			slot = b
			break
	if slot.is_empty():
		if free_bubble_only:
			return
		slot = _bubbles[0]
	slot["who"] = id
	slot["node"] = n["node"]
	slot["t"] = clampf(1.8 + text.length() * 0.05, 2.4, 5.5)
	var l: Label = slot["label"]
	l.text = text
	var p: Control = slot["panel"]
	p.reset_size()
	p.modulate.a = 1.0
	p.visible = true
	_place_bubble(slot)

func _tick_bubbles(delta: float) -> void:
	for b in _bubbles:
		var p: Control = b["panel"]
		if not p.visible:
			continue
		b["t"] = float(b["t"]) - delta
		if float(b["t"]) <= 0.0:
			p.visible = false
			continue
		p.modulate.a = clampf(float(b["t"]) / 0.4, 0.0, 1.0)
		_place_bubble(b)

func _place_bubble(b: Dictionary) -> void:
	var node: Node3D = b["node"]
	var p: Control = b["panel"]
	var h := float(Canon.character(str(b["who"])).get("height_m", 1.8)) + 0.5
	var wp := node.global_position + Vector3(0, clampf(h, 1.4, 4.5), 0)
	if cam == null or cam.is_position_behind(wp):
		p.visible = false
		return
	var sp := cam.unproject_position(wp)
	var vs := ui_root.get_viewport_rect().size
	var anchor: Variant = anchor_getter.call(str(b["who"])) if anchor_getter.is_valid() else null
	if anchor is Rect2 and (anchor as Rect2).size.x > 1.0:
		# sit just above the person's name tag
		var r: Rect2 = anchor
		p.position = Vector2(clampf(r.get_center().x - p.size.x * 0.5, 8.0, vs.x - p.size.x - 8.0), maxf(r.position.y - p.size.y - 4.0, 108.0))
		return
	if sp.x < -60.0 or sp.x > vs.x + 60.0 or sp.y < 100.0 or sp.y > vs.y:
		p.visible = false
		b["t"] = 0.0
		return
	p.position = Vector2(clampf(sp.x - p.size.x * 0.5, 8.0, vs.x - p.size.x - 8.0), clampf(sp.y - p.size.y - 6.0, 110.0, vs.y - p.size.y - 60.0))

func hide_all() -> void:
	for b in _bubbles:
		(b["panel"] as Control).visible = false
		b["t"] = 0.0

# ------------------------------------------------------------------ pairs
func _start_pair() -> void:
	if _pairs.is_empty():
		return
	var cand: Array = _pairs.duplicate()
	cand.shuffle()
	for pr in cand:
		var a: Dictionary = _npcs.get(str(pr["a"]), {})
		var b: Dictionary = _npcs.get(str(pr["b"]), {})
		if a.is_empty() or b.is_empty() or not _near_focus(b["node"]):
			continue
		if a["state"] != "idle" or b["state"] != "idle":
			continue
		var bp: Vector3 = (b["node"] as Node3D).position
		var side := 1.0 if bp.x < 14.0 else -1.0
		var meet := bp + Vector3(1.6 * side, 0, 0.5)
		meet.y = (a["node"] as Node3D).position.y
		_pair = {"a": a, "b": b, "lines": pr["lines"], "i": 0, "t": 0.0, "phase": "go", "home": (a["node"] as Node3D).position, "ids": [str(pr["a"]), str(pr["b"])]}
		walk_to(a, meet)
		return

func _tick_pair(delta: float) -> void:
	var a: Dictionary = _pair["a"]
	var b: Dictionary = _pair["b"]
	match _pair["phase"]:
		"go":
			if a["state"] == "idle":
				_pair["phase"] = "talk"
				_pair["t"] = 0.3
				_face(a, b)
				_face(b, a)
		"talk":
			_pair["t"] = float(_pair["t"]) - delta
			if float(_pair["t"]) <= 0.0:
				var ls: Array = _pair["lines"]
				var i: int = _pair["i"]
				if i >= ls.size():
					_pair["phase"] = "return"
					walk_to(a, _pair["home"])
					return
				say(str(ls[i][0]), str(ls[i][1]))
				_pair["i"] = i + 1
				_pair["t"] = clampf(1.6 + str(ls[i][1]).length() * 0.05, 2.6, 5.0)
		"return":
			if a["state"] == "idle":
				for k in ["a", "b"]:
					var nn: Dictionary = _pair[k]
					var bb: Node = nn["bb"]
					if bb and bb.has_method("set_facing"):
						bb.set_facing(nn["face"])
				_pair = {}

func _face(from: Dictionary, to: Dictionary) -> void:
	var bb: Node = from["bb"]
	if bb and bb.has_method("set_facing"):
		bb.set_facing((to["node"] as Node3D).position - (from["node"] as Node3D).position)
