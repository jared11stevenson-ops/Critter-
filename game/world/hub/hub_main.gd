extends Node3D
## Terrarium One — The Common (hub). Agent 1's hub_visual.tscn (or the fallback diorama),
## a drag-to-pan camera that eases to hotspots, tappable floating hotspot labels, ambient NPC talk,
## the Gate, the Habitat Wing, the Codex and Mara's Lab. Drives the slice's hub beats.

const VISUAL := "res://game/world/hub/hub_visual.tscn"
const FALLBACK := "res://game/world/hub/hub_fallback_room.gd"
const RR := "res://game/world/red_reaches/red_reaches.tscn"
const NPC_IDS := ["mollusk", "bramvex", "nerit", "zephyr", "nyxaris", "pharilux", "solmara", "scarlith"]

var visual: Node3D
var cam: Camera3D
var runner: DialogueRunner
var ui: CanvasLayer
var ui_root: Control
var _spots: Array = []          # {id, label, node(Node3D), button, kind}
var _focus := Vector3.ZERO
var _focus_target := Vector3.ZERO
var _bounds := Rect2(-18, -14, 36, 28)
var _drag_id := -1
var _drag_last := Vector2.ZERO
var _drag_moved := 0.0
var _objective_label: Label
var _objective_panel: PanelContainer
var _toast_box: VBoxContainer
var habitat: Node = null
var _end_card: Node = null
var _pitch := -48.0
var _dist := 24.0

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	TouchInput.reset()
	_build_visual()
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.current = true
	add_child(cam)
	var cf := _marker("CamFocus_Default")
	_focus = cf.global_position if cf else Vector3.ZERO
	_focus_target = _focus
	runner = DialogueRunner.new()
	runner.name = "Dialogue"
	add_child(runner)
	runner.event_emitted.connect(_on_event)
	runner.finished.connect(_on_dialogue_finished)
	_build_ui()
	_build_spots()
	_compute_bounds()
	GameState.flags["_scene"] = "hub"
	GameState.chapter = "hub"
	GameState.unlock_codex("place_terrarium_one")
	GameState.unlock_codex("place_the_common")
	GameState.unlock_codex("char_mara")
	GameState.save_game()
	Events.toast.connect(_toast)
	Events.codex_unlocked.connect(func(id): _toast("Codex updated: %s" % CodexData.title(id), "codex"))
	Audio.music("hub")
	Events.scene_ready.emit("hub")
	_update_objective()
	_auto_beats.call_deferred()

# ---------------- build ----------------
func _build_visual() -> void:
	if ResourceLoader.exists(VISUAL):
		var ps: Variant = load(VISUAL)
		if ps is PackedScene:
			visual = (ps as PackedScene).instantiate()
	if visual == null:
		visual = load(FALLBACK).new()
	visual.name = "HubVisual"
	add_child(visual)

func _marker(n: String) -> Node3D:
	if visual == null:
		return null
	return visual.find_child(n, true, false) as Node3D

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UiKit.theme()
	ui.add_child(ui_root)
	var title := UiKit.label("TERRARIUM ONE · THE COMMON", 30, UiKit.PARCHMENT, "solemn", 8, Color(0, 0, 0, 0.85))
	title.position = Vector2(24, 18)
	ui_root.add_child(title)
	_objective_panel = PanelContainer.new()
	_objective_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.94), UiKit.ACCENT.darkened(0.2), 22, 3, 18))
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_objective_panel)
	var hb := HBoxContainer.new()
	_objective_panel.add_child(hb)
	hb.add_child(UiKit.label("NEXT", 20, UiKit.ACCENT, "bold"))
	_objective_label = UiKit.label("", 26, UiKit.INK, "ui")
	hb.add_child(_objective_label)
	_toast_box = VBoxContainer.new()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_toast_box)
	var menu := UiKit.button("Menu", Vector2(150, 88), 28)
	menu.anchor_left = 1.0
	menu.anchor_right = 1.0
	menu.offset_left = -174
	menu.offset_right = -24
	menu.offset_top = 16
	menu.offset_bottom = 104
	menu.pressed.connect(_open_menu)
	ui_root.add_child(menu)
	var hint := UiKit.label("Drag to look around · tap a place or a person", 22, UiKit.PARCHMENT.darkened(0.15), "ui", 6, Color(0, 0, 0, 0.8))
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -44
	hint.position.x = 24
	ui_root.add_child(hint)

func _build_spots() -> void:
	var defs := [
		["table", "Common Table", "Hotspot_Table", "spot"],
		["gate", "The Gate", "Hotspot_Gate", "spot"],
		["habitat", "Habitat Wing", "Hotspot_Habitat", "spot"],
		["codex", "Field Codex", "Hotspot_Codex", "spot"],
		["lab", "Mara's Lab", "Hotspot_Lab", "spot"],
	]
	for id in NPC_IDS:
		defs.append([id, Canon.display_name(id), "NPC_" + id, "npc"])
	for d in defs:
		var n := _marker(d[2])
		if n == null:
			continue
		var b := Button.new()
		b.text = d[1]
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(0, 88) if d[3] == "spot" else Vector2(0, 72)
		b.add_theme_font_size_override("font_size", 28 if d[3] == "spot" else 24)
		if d[3] == "spot":
			b.add_theme_stylebox_override("normal", UiKit.box(Color(UiKit.CARD, 0.92), UiKit.ACCENT, 24, 3, 22))
			b.add_theme_stylebox_override("hover", UiKit.box(UiKit.CARD.lightened(0.1), UiKit.ACCENT_2, 24, 3, 22))
			b.add_theme_stylebox_override("pressed", UiKit.box(UiKit.ACCENT.darkened(0.2), UiKit.PARCHMENT, 24, 3, 22))
		else:
			var col := UiKit.char_color(d[0])
			b.add_theme_stylebox_override("normal", UiKit.box(Color(UiKit.PARCHMENT, 0.9), col.darkened(0.2), 20, 3, 16))
			b.add_theme_stylebox_override("hover", UiKit.box(UiKit.PARCHMENT, col, 20, 3, 16))
			b.add_theme_stylebox_override("pressed", UiKit.box(col, UiKit.PARCHMENT, 20, 3, 16))
			b.add_theme_color_override("font_color", UiKit.INK)
			b.add_theme_color_override("font_hover_color", UiKit.INK)
		b.pressed.connect(_on_spot.bind(d[0]))
		b.name = "Spot_" + d[0]
		ui_root.add_child(b)
		var h := 2.6
		if d[3] == "npc":
			h = float(Canon.character(d[0]).get("height_m", 2.0)) + 0.6
			h = clampf(h, 1.0, 6.5)
		elif d[0] == "gate":
			h = 8.4
		elif d[0] == "habitat":
			h = 4.8
		_spots.append({"id": d[0], "node": n, "button": b, "kind": d[3], "h": h})

func _compute_bounds() -> void:
	var r := Rect2()
	var first := true
	for s in _spots:
		var p: Vector3 = s["node"].global_position
		if first:
			r = Rect2(p.x, p.z, 0, 0)
			first = false
		else:
			r = r.expand(Vector2(p.x, p.z))
	if not first:
		_bounds = r.grow(4.0)

# ---------------- per frame ----------------
func _process(delta: float) -> void:
	_focus_target.x = clampf(_focus_target.x, _bounds.position.x, _bounds.end.x)
	_focus_target.z = clampf(_focus_target.z, _bounds.position.y, _bounds.end.y)
	_focus = _focus.lerp(_focus_target, 1.0 - exp(-6.0 * delta))
	var p := deg_to_rad(_pitch)
	cam.global_position = _focus + Vector3(0, -sin(p) * _dist, cos(p) * _dist)
	cam.rotation = Vector3(p, 0, 0)
	var modal := runner.active or habitat != null or _end_card != null or get_tree().paused
	for s in _spots:
		var b: Button = s["button"]
		var wp: Vector3 = s["node"].global_position + Vector3(0, s["h"], 0)
		if modal or cam.is_position_behind(wp):
			b.visible = false
			continue
		var sp := cam.unproject_position(wp)
		b.visible = true
		b.reset_size()
		b.position = sp - Vector2(b.size.x * 0.5, b.size.y)
		var locked: bool = s["id"] == "gate" and not bool(GameState.get_flag("briefed", false))
		b.modulate = Color(1, 1, 1, 0.55) if locked else Color.WHITE
	_objective_panel.visible = not modal
	_objective_panel.reset_size()
	var vs := ui_root.get_viewport_rect().size
	_objective_panel.position = Vector2((vs.x - _objective_panel.size.x) * 0.5, 16)
	_toast_box.position = Vector2(vs.x * 0.5 - 260, 92)

func _unhandled_input(ev: InputEvent) -> void:
	if runner.active or habitat != null or _end_card != null:
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed and _drag_id == -1:
			_drag_id = t.index
			_drag_last = t.position
			_drag_moved = 0.0
		elif not t.pressed and t.index == _drag_id:
			_drag_id = -1
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _drag_id:
			var delta := d.position - _drag_last
			_drag_last = d.position
			_drag_moved += delta.length()
			var k := _dist / 520.0
			_focus_target -= Vector3(delta.x, 0, delta.y) * k
	elif ev.is_action_pressed("pause"):
		_open_menu()
	elif ev is InputEventKey and ev.pressed:
		var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if mv != Vector2.ZERO:
			_focus_target += Vector3(mv.x, 0, mv.y) * 2.0

# ---------------- hotspots ----------------
func _on_spot(id: String) -> void:
	if runner.active or habitat != null:
		return
	Audio.sfx("ui_tap")
	for s in _spots:
		if s["id"] == id:
			_focus_target = s["node"].global_position
	match id:
		"table": _talk_table()
		"gate": _gate()
		"habitat": open_habitat()
		"codex": _open_codex()
		"lab": runner.play("hub_lab_mara")
		_:
			GameState.unlock_codex("char_" + id)
			if not runner.play("hub_npc_" + id):
				_toast("%s nods at you." % Canon.display_name(id), "info")

func _talk_table() -> void:
	if not bool(GameState.get_flag("briefed", false)):
		runner.play("hub_intro")
	elif bool(GameState.get_flag("rr_complete", false)) and not bool(GameState.get_flag("debriefed", false)):
		runner.play("hub_debrief")
	elif bool(GameState.get_flag("habitat_built", false)) and not bool(GameState.get_flag("slice_complete", false)):
		runner.play("hub_hook")
	elif not bool(GameState.get_flag("rr_complete", false)):
		runner.play_data("hub_table_wait", {"lines": [{"who": "aruun", "expr": "calm", "text": "The Gate is open, Handler. The Span will not wait for us."}]})
	else:
		runner.play_data("hub_table_after", {"lines": [{"who": "cigarra", "expr": "happy", "text": "The Common is louder since you got back. Good loud."}]})

func _gate() -> void:
	if not bool(GameState.get_flag("briefed", false)):
		_toast("Mara is waiting at the Common Table — get your briefing first.", "warning")
		for s in _spots:
			if s["id"] == "table":
				_focus_target = s["node"].global_position
		return
	runner.play_data("hub_gate_confirm", {"lines": [
		{"who": "comms:mara", "expr": "focused", "text": "Gate is calibrated for the Red Reaches. Descend?" if not bool(GameState.get_flag("rr_complete", false)) else "The Reaches remember what you did there. Descend again?"},
		{"choice": [{"text": "Descend", "event": "descend"}, {"text": "Not yet"}]},
	]})

func _descend() -> void:
	GameState.flags["_scene"] = "red_reaches"
	if bool(GameState.get_flag("rr_complete", false)):
		GameState.flags["_checkpoint"] = ""
	GameState.save_game()
	Audio.sfx("gate_whoosh")
	Router.goto(RR, "gate")

func _open_codex() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 70
	add_child(cl)
	var c := CodexScreen.new()
	cl.add_child(c)
	c.tree_exited.connect(cl.queue_free)

func _open_menu() -> void:
	if runner.active or habitat != null:
		return
	add_child(PauseMenu.new())

# ---------------- habitat ----------------
func open_habitat() -> void:
	if habitat != null:
		return
	if GameState.specimens.is_empty():
		if bool(GameState.get_flag("debriefed", false)) or bool(GameState.get_flag("rescued_grazer", false)):
			GameState.add_specimen("dust_grazer")
			GameState.set_flag("rescued_grazer", true)
			_toast("A rescued Dust Grazer arrives under Protective Extraction", "item")
		else:
			_toast("No specimens yet — contain wildlife in the field (below 30% HP).", "info")
			return
	var scr: Script = load("res://game/world/habitat/habitat_builder.gd")
	habitat = scr.new()
	add_child(habitat)
	visual.visible = false
	ui.visible = false
	habitat.closed.connect(_on_habitat_closed)
	if not DialogueRunner.seen("hub_habitat_intro"):
		runner.play("hub_habitat_intro")

func _on_habitat_closed() -> void:
	habitat = null
	visual.visible = true
	ui.visible = true
	cam.current = true
	GameState.save_game()
	_update_objective()
	_auto_beats.call_deferred()

# ---------------- beats ----------------
func _auto_beats() -> void:
	if runner.active or habitat != null:
		return
	await get_tree().create_timer(0.5).timeout
	if runner.active or habitat != null:
		return
	if not bool(GameState.get_flag("briefed", false)):
		runner.play("hub_intro")
	elif bool(GameState.get_flag("rr_complete", false)) and not bool(GameState.get_flag("debriefed", false)):
		runner.play("hub_debrief")
	elif bool(GameState.get_flag("habitat_built", false)) and not bool(GameState.get_flag("slice_complete", false)) and not DialogueRunner.seen("hub_hook"):
		runner.play("hub_hook")

func _on_event(ev: String) -> void:
	match ev:
		"descend": _descend.call_deferred()
		"open_habitat":
			GameState.set_flag("debriefed", true)
			open_habitat.call_deferred()
		"slice_end":
			GameState.set_flag("slice_complete", true)
			_show_end_card.call_deferred()
	_update_objective()

func _on_dialogue_finished(id: String) -> void:
	match id:
		"hub_intro":
			if not bool(GameState.get_flag("briefed", false)):
				GameState.set_flag("briefed", true)
			for s in _spots:
				if s["id"] == "gate":
					_focus_target = s["node"].global_position
		"hub_debrief":
			if not bool(GameState.get_flag("debriefed", false)):
				GameState.set_flag("debriefed", true)
			if habitat == null and not bool(GameState.get_flag("habitat_built", false)):
				open_habitat.call_deferred()
		"hub_hook":
			if not bool(GameState.get_flag("slice_complete", false)):
				GameState.set_flag("slice_complete", true)
				_show_end_card.call_deferred()
	GameState.save_game()
	_update_objective()

func _show_end_card() -> void:
	if _end_card != null:
		return
	_end_card = EndCard.new()
	add_child(_end_card)
	_end_card.tree_exited.connect(func(): _end_card = null)
	GameState.save_game()

func _update_objective() -> void:
	var t := ""
	if not bool(GameState.get_flag("briefed", false)):
		t = "Meet Mara at the Common Table"
	elif not bool(GameState.get_flag("rr_complete", false)):
		t = "Descend through the Gate to the Red Reaches"
	elif not bool(GameState.get_flag("debriefed", false)):
		t = "Debrief at the Common Table"
	elif not bool(GameState.get_flag("habitat_built", false)):
		t = "Build a Habitat in the Habitat Wing"
	elif not bool(GameState.get_flag("slice_complete", false)):
		t = "Talk at the Common Table"
	else:
		t = "Free roam — the Terrarium remembers"
	_objective_label.text = t

func _toast(text: String, kind: String = "info") -> void:
	var edge := UiKit.PARCHMENT
	match kind:
		"codex": edge = UiKit.SCAN
		"item": edge = UiKit.PSI
		"warning": edge = UiKit.ACCENT
		"trust": edge = UiKit.ACCENT_2
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.CARD, 0.88), edge, 12, 2, 10))
	var l := UiKit.label(text, 22, UiKit.PARCHMENT, "ui")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(500, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(l)
	_toast_box.add_child(pc)
	while _toast_box.get_child_count() > 2:
		_toast_box.get_child(0).free()
	var tw := pc.create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(pc, "modulate:a", 0.0, 0.4)
	tw.tween_callback(pc.queue_free)

# ---------------- QA ----------------
var _qa_auto := false
var _qa_choice := 0

func qa_auto_dialogue(on: bool, choice: int = 0, delay: float = 0.6) -> void:
	_qa_auto = on
	_qa_choice = choice
	if on and not runner.started.is_connected(_qa_on_started):
		runner.started.connect(_qa_on_started.bind(delay))
	if on and runner.active:
		_qa_on_started(runner.dialogue_id, delay)

func _qa_on_started(_id: String, delay: float) -> void:
	await get_tree().create_timer(delay, true, false, true).timeout
	var guard := 0
	while runner.active and guard < 200:
		guard += 1
		if runner._waiting == "choice":
			runner.choose(mini(_qa_choice, runner._choices.size() - 1))
		elif runner._waiting == "advance":
			runner.advance()
		else:
			break

func qa_spot(id: String) -> void:
	_on_spot(id)

func qa_habitat_solve() -> void:
	if habitat and habitat.has_method("qa_solve"):
		habitat.qa_solve()

func qa_habitat_close() -> void:
	if habitat and habitat.has_method("close"):
		habitat.close()

func qa_end_card_close() -> void:
	if _end_card and _end_card.has_method("close"):
		_end_card.close()

func qa_log_flags() -> void:
	var keys := ["briefed", "rr_complete", "debriefed", "rescued_grazer", "habitat_built", "slice_complete", "ochre_span"]
	var out := []
	for k in keys:
		out.append("%s=%s" % [k, str(GameState.get_flag(k, false))])
	print("[QA] HUB FLAGS ", ", ".join(out), " specimens=", GameState.specimens.size(), " items=", GameState.items)
