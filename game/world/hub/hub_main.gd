extends Node3D
## Terrarium One — The Common (hub). Agent 1's hub_visual.tscn (or the fallback diorama),
## a drag-to-pan camera that eases to hotspots, tappable floating hotspot labels, ambient NPC talk,
## the Gate, the Habitat Wing, the Codex and Mara's Lab. Drives the slice's hub beats.

const VISUAL := "res://game/world/hub/hub_visual.tscn"
const FALLBACK := "res://game/world/hub/hub_fallback_room.gd"
const RR := "res://game/world/red_reaches/red_reaches.tscn"
const TOP_SAFE := 120.0
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
var _returning := false
var _bonds_screen: Node = null
var _gate_layer: CanvasLayer = null
var _labels_hidden := false
var _place_tick := 0
var _force_place := true
var _last_placed_focus := Vector3(1e9, 0, 0)
var _pitch := -48.0
var _dist := 13.0
var life: HubLife = null
var _pulse_t := 0.0
var _touches: Dictionary = {}

func _ready() -> void:
	var _t0 := Time.get_ticks_msec()
	get_tree().paused = false
	Engine.time_scale = 1.0
	TouchInput.reset()
	_build_visual()
	var _t1 := Time.get_ticks_msec()
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
	_build_life()
	GameState.flags["_scene"] = "hub"
	GameState.chapter = "hub"
	GameState.unlock_codex("place_terrarium_one")
	GameState.unlock_codex("place_the_common")
	GameState.unlock_codex("char_mara")
	GameState.save_game()
	Events.toast.connect(_toast)
	Ledger.bond_changed.connect(_on_bond_changed)
	Ledger.promise_changed.connect(_on_promise_changed)
	Events.codex_unlocked.connect(func(id): _toast("Codex updated: %s" % CodexData.title(id), "codex"))
	Audio.music("hub")
	Events.scene_ready.emit("hub")
	_update_objective()
	_auto_beats.call_deferred()
	if OS.get_cmdline_user_args().has("qa"):
		print("[PERF] hub _ready ms total=%d visual=%d" % [Time.get_ticks_msec() - _t0, _t1 - _t0])

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
	_add_hub_props()

func _build_life() -> void:
	if visual.get_script() and visual.get("_idle_t") != null:
		visual.set_process(false)    # HubLife drives the cast now (glances + walks)
	life = HubLife.new()
	life.name = "HubLife"
	add_child(life)
	life.setup(self, visual, cam, ui_root, func(): return _focus, _label_rect)

func _label_rect(id: String) -> Rect2:
	for s in _spots:
		if s["id"] == id and (s["button"] as Button).visible:
			var b: Button = s["button"]
			return Rect2(b.position, b.size)
	return Rect2()

## Three extra places with a purpose, built from plain boxes (a handful of draw calls): the Rumor Board points at optional
## side areas in the Reaches, the Supply Stores show what the Habitat can be built from, the Ledger Wall shows what the world
## remembers about you.
func _add_hub_props() -> void:
	var defs := [
		["Hotspot_Board", Vector3(3.0, 0, 7.0), Color(0.5, 0.33, 0.22), Color(0.92, 0.85, 0.66)],
		["Hotspot_Stores", Vector3(17.0, 0, -0.5), Color(0.42, 0.44, 0.48), Color(0.8, 0.55, 0.25)],
		["Hotspot_Ledger", Vector3(0.2, 0, -15.3), Color(0.66, 0.52, 0.34), Color(0.55, 1.0, 0.85)],
	]
	for d in defs:
		var m := Marker3D.new()
		m.name = d[0]
		visual.add_child(m)
		m.position = d[1]
		var base := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.8, 1.0, 0.9)
		base.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = d[2]
		mat.roughness = 0.9
		base.material_override = mat
		base.position = Vector3(0, 0.5, 0)
		m.add_child(base)
		var top := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(1.5, 1.1, 0.12)
		top.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = d[3]
		tmat.emission_enabled = true
		tmat.emission = Color(d[3]) * 0.35
		top.material_override = tmat
		top.position = Vector3(0, 1.6, 0.2)
		top.rotation_degrees = Vector3(-12, 0, 0)
		m.add_child(top)
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _marker(n: String) -> Node3D:
	if visual == null:
		return null
	return visual.find_child(n, true, false) as Node3D

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UiKit.theme()
	ui.add_child(ui_root)
	var title := UiKit.label("TERRARIUM ONE · THE COMMON", 24, UiKit.PARCHMENT, "solemn", 7, Color(0, 0, 0, 0.85))
	title.position = Vector2(24, 14)
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
	var bonds := UiKit.button("Bonds", Vector2(150, 88), 28)
	bonds.anchor_left = 1.0
	bonds.anchor_right = 1.0
	bonds.offset_left = -338
	bonds.offset_right = -188
	bonds.offset_top = 16
	bonds.offset_bottom = 104
	bonds.pressed.connect(_open_bonds)
	bonds.name = "BondsButton"
	ui_root.add_child(bonds)
	var gear := UiKit.button("Gear", Vector2(150, 88), 28)
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	gear.offset_left = -502
	gear.offset_right = -352
	gear.offset_top = 16
	gear.offset_bottom = 104
	gear.name = "GearButton"
	gear.pressed.connect(_open_gear)
	ui_root.add_child(gear)
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
		["board", "Rumor Board", "Hotspot_Board", "spot"],
		["stores", "Supply Stores", "Hotspot_Stores", "spot"],
		["ledger", "Ledger Wall", "Hotspot_Ledger", "spot"],
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
		b.pressed.connect(_on_label.bind(d[0]))
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
		elif d[0] in ["board", "stores", "ledger"]:
			h = 3.2
		var spot := {"id": d[0], "name": d[1], "node": n, "button": b, "kind": d[3], "h": h}
		_spots.append(spot)
		if d[3] == "npc":
			_set_npc_tag(spot, false)

## NPC labels: an invisible tap box over the person, and a small name tag above the head only for the nearest / focused NPC.
func _set_npc_tag(s: Dictionary, on: bool) -> void:
	if s.get("tag", null) == on:
		return
	s["tag"] = on
	var b: Button = s["button"]
	if on:
		var col := UiKit.char_color(str(s["id"]))
		b.text = str(s["name"])
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_stylebox_override("normal", UiKit.box(Color(UiKit.PARCHMENT, 0.92), col.darkened(0.2), 12, 2, 8))
		b.add_theme_stylebox_override("hover", UiKit.box(UiKit.PARCHMENT, col, 12, 2, 8))
		b.add_theme_stylebox_override("pressed", UiKit.box(col, UiKit.PARCHMENT, 12, 2, 8))
		b.custom_minimum_size = Vector2(0, 36)
	else:
		b.text = ""
		for k in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, StyleBoxEmpty.new())
		b.custom_minimum_size = Vector2(84, 150)
	b.reset_size()
	s["sz"] = b.size

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
	if modal:
		# Nothing to place while a dialogue/menu is up: hide the labels once and do no per-frame layout work.
		if not _labels_hidden:
			for s in _spots:
				(s["button"] as Button).visible = false
			_objective_panel.visible = false
			if life:
				life.hide_all()
			_labels_hidden = true
		return
	_labels_hidden = false
	# Hotspot labels only move when the camera does; re-place them when the focus moved, else every 8th frame.
	_place_tick += 1
	_pulse_t += delta
	var moved := _focus.distance_squared_to(_last_placed_focus) > 0.0001
	if moved or _place_tick % 8 == 0 or _force_place:
		_last_placed_focus = _focus
		_force_place = false
		_place_labels()
	_objective_panel.visible = true

func _objective_id() -> String:
	if not bool(GameState.get_flag("briefed", false)):
		return "table"
	if not bool(GameState.get_flag("rr_complete", false)):
		return "gate"
	if not bool(GameState.get_flag("debriefed", false)):
		return "table"
	if not bool(GameState.get_flag("habitat_built", false)):
		return "habitat"
	return ""

func _place_labels() -> void:
	var vs := ui_root.get_viewport_rect().size
	# Place hotspot labels: big places first, then people; nudge overlapping labels apart and keep
	# them clear of the top bar (title/objective/menu) and the screen edges.
	var placed: Array = []
	var obj := _objective_id()
	var order: Array = []
	for s in _spots:
		if s["kind"] == "spot":
			order.append(s)
	for s in _spots:
		if s["kind"] != "spot":
			order.append(s)
	var near_id := ""
	var near_d := 300.0
	for s in _spots:
		if s["kind"] != "npc":
			continue
		var hp: Vector3 = s["node"].global_position + Vector3(0, s["h"], 0)
		if cam.is_position_behind(hp):
			continue
		var dd := cam.unproject_position(hp).distance_to(vs * 0.5 + Vector2(0, -60))
		if dd < near_d:
			near_d = dd
			near_id = str(s["id"])
	for s in order:
		var b: Button = s["button"]
		var wp: Vector3 = s["node"].global_position + Vector3(0, s["h"], 0)
		if cam.is_position_behind(wp):
			b.visible = false
			continue
		var sp := cam.unproject_position(wp)
		if s["kind"] == "npc":
			_set_npc_tag(s, str(s["id"]) == near_id)
			var tagged: bool = str(s["id"]) == near_id
			var nsz: Vector2 = s["sz"]
			b.visible = sp.x > -40.0 and sp.x < vs.x + 40.0 and sp.y > 0.0 and sp.y < vs.y + 60.0
			b.position = (sp - Vector2(nsz.x * 0.5, nsz.y + 4.0)) if tagged else (sp - Vector2(nsz.x * 0.5, 36.0))
			continue
		if not s.has("sz") or b.size.x < 2.0:
			b.reset_size()
			s["sz"] = b.size
		var bsz: Vector2 = s["sz"]
		var r := Rect2(sp - Vector2(bsz.x * 0.5, bsz.y), bsz)
		for _attempt in 6:
			var hit := false
			for pr in placed:
				if r.grow(3.0).intersects(pr):
					var up: float = pr.position.y - r.size.y - 4.0
					var down: float = pr.end.y + 4.0
					r.position.y = up if absf(up - r.position.y) <= absf(down - r.position.y) and up > TOP_SAFE else down
					hit = true
					break
			if not hit:
				break
		r.position.x = clampf(r.position.x, 8.0, vs.x - r.size.x - 8.0)
		r.position.y = clampf(r.position.y, TOP_SAFE, vs.y - r.size.y - 52.0)
		var onscreen := sp.x > -40.0 and sp.x < vs.x + 40.0 and sp.y > 0.0 and sp.y < vs.y + 60.0
		var is_obj: bool = s["id"] == obj
		if not onscreen and s["kind"] == "spot":
			# Signpost: a chip on the screen edge pointing toward the place; tapping it pans the camera there.
			var dir := (sp - vs * 0.5)
			if cam.is_position_behind(wp):
				dir = -dir
			var arrow := "◀ " if dir.x < -absf(dir.y) * 0.6 else ("▶ " if dir.x > absf(dir.y) * 0.6 else ("▲ " if dir.y < 0 else "▼ "))
			var label_txt: String = arrow + ("★ " if is_obj else "") + str(s["name"])
			if b.text != label_txt:
				b.text = label_txt
				b.reset_size()
				s["sz"] = b.size
			s["off"] = true
			bsz = s["sz"]
			var edge := Vector2(clampf(vs.x * 0.5 + dir.x * 4.0, 8.0 + bsz.x * 0.5, vs.x - 8.0 - bsz.x * 0.5), clampf(vs.y * 0.5 + dir.y * 4.0, TOP_SAFE + 8.0, vs.y - 60.0 - bsz.y))
			var er := Rect2(edge - Vector2(bsz.x * 0.5, 0), bsz)
			for _a in 4:
				var hit2 := false
				for pr in placed:
					if er.grow(3.0).intersects(pr):
						er.position.y += pr.size.y + 6.0 if er.position.y < vs.y * 0.5 else -(pr.size.y + 6.0)
						hit2 = true
						break
				if not hit2:
					break
			b.visible = true
			b.position = er.position
			placed.append(er)
			b.modulate = Color(1, 1, 1, 0.9 if is_obj else 0.6)
			continue
		var want: String = ("★ " if is_obj else "") + str(s["name"])
		if s.get("off", false) or b.text != want:
			s["off"] = false
			b.text = want
			b.reset_size()
			s["sz"] = b.size
			r.size = b.size
		b.visible = onscreen
		if not onscreen:
			continue
		b.position = r.position
		placed.append(r)
		var locked: bool = s["id"] == "gate" and not bool(GameState.get_flag("briefed", false))
		var cd := sp.distance_to(vs * 0.5)
		var fade := clampf(0.35 + (cd - 140.0) / 360.0, 0.35, 1.0)    # places fade as they get close to the focus
		b.modulate = Color(1, 1, 1, minf(fade, 0.55 if locked else 1.0))
	_objective_panel.reset_size()
	_objective_panel.position = Vector2(20, 50)
	# Toasts sit bottom-centre above the hint line, clear of the top bar and the hotspot labels' band.
	_toast_box.reset_size()
	_toast_box.position = Vector2(vs.x * 0.5 - 260, vs.y - 56.0 - _toast_box.size.y)


func _unhandled_input(ev: InputEvent) -> void:
	if runner.active or habitat != null or _end_card != null or _returning:
		return
	if (_gate_layer and is_instance_valid(_gate_layer)) or (_bonds_screen and is_instance_valid(_bonds_screen)):
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		if t.pressed and _drag_id == -1:
			_drag_id = t.index
			_drag_last = t.position
			_drag_moved = 0.0
		elif not t.pressed and t.index == _drag_id:
			_drag_id = -1
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if _touches.size() == 2 and _touches.has(d.index):
			var ks: Array = _touches.keys()
			var before: float = (_touches[ks[0]] as Vector2).distance_to(_touches[ks[1]])
			_touches[d.index] = d.position
			var after: float = (_touches[ks[0]] as Vector2).distance_to(_touches[ks[1]])
			_zoom_by((before - after) * 0.03)
			_drag_last = d.position
		elif d.index == _drag_id:
			_touches[d.index] = d.position
			var delta := d.position - _drag_last
			_drag_last = d.position
			_drag_moved += delta.length()
			var k := _dist / 520.0
			_focus_target -= Vector3(delta.x, 0, delta.y) * k
	elif ev is InputEventMouseButton and ev.pressed and (ev.button_index == MOUSE_BUTTON_WHEEL_UP or ev.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_zoom_by(-2.0 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0)
	elif ev is InputEventMagnifyGesture:
		_zoom_by((1.0 - (ev as InputEventMagnifyGesture).factor) * 12.0)
	elif ev.is_action_pressed("pause"):
		_open_menu()
	elif ev is InputEventKey and ev.pressed:
		var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if mv != Vector2.ZERO:
			_focus_target += Vector3(mv.x, 0, mv.y) * 2.0

func _zoom_by(d: float) -> void:
	_dist = clampf(_dist + d, 8.0, 34.0)
	_force_place = true

# ---------------- hotspots ----------------
func _on_spot(id: String) -> void:
	if runner.active or habitat != null or _returning:
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
		"board": _read_board()
		"stores": _read_stores()
		"ledger": _open_ledger()
		_:
			GameState.unlock_codex("char_" + id)
			if not runner.play("hub_npc_" + id):
				_toast("%s nods at you." % Canon.display_name(id), "info")

func _on_label(id: String) -> void:
	# an off-screen place only pans the camera to it (the edge chip is a signpost); on-screen labels act
	for sp in _spots:
		if sp["id"] == id and bool(sp.get("off", false)):
			Audio.sfx("ui_tap")
			_focus_target = sp["node"].global_position
			return
	_on_spot(id)

## The Rumor Board: what people are saying about the Reaches' optional places you have not seen yet.
func _read_board() -> void:
	var rr := RegionRunner.load_recipe("red_reaches")
	var lines: Array = []
	for sp in rr.get("spokes", []):
		if not bool(GameState.flags.get("_spoke_" + str(sp["id"]), false)):
			lines.append({"who": "narration", "text": "%s: %s" % [str(sp["name"]), str(sp.get("fresh", sp.get("blurb", "")))]})
	var seen := 0
	for sp in rr.get("spokes", []):
		if bool(GameState.flags.get("_spoke_" + str(sp["id"]), false)):
			seen += 1
	if lines.is_empty():
		lines.append({"who": "narration", "text": "Every notice on the board is stamped DONE. Someone has drawn a small, smug cairn in the corner."})
	else:
		lines.push_front({"who": "narration", "text": "Rumor Board. Pinned notices about the Red Reaches (%d of %d side areas found):" % [seen, rr.get("spokes", []).size()]})
	runner.play_data("hub_board", {"lines": lines})

func _read_stores() -> void:
	var parts: Array = []
	for k in GameState.items:
		if int(GameState.items[k]) > 0:
			parts.append("%s x%d" % [UiKit.item_name(str(k)), int(GameState.items[k])])
	var t := "The stores are empty. Gather materials in the field." if parts.is_empty() else "Stores: " + ", ".join(parts) + "."
	runner.play_data("hub_stores", {"lines": [{"who": "narration", "text": t}]})

func _open_ledger() -> void:
	var card := LedgerCard.debrief(-1, "Close")
	card.title = "WHAT THE WORLD REMEMBERS"
	card.subtitle = "The Ledger Wall"
	add_child(card)

func _talk_table() -> void:
	if _returning:
		return
	if bool(GameState.get_flag("_returned_pending", false)):
		_return_sequence()
		return
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
	open_gate_map()

## The Gate Map replaces the old confirm dialogue: pick a homeland, then Descend / Return Descent.
func open_gate_map() -> void:
	if _gate_layer and is_instance_valid(_gate_layer):
		return
	_gate_layer = CanvasLayer.new()
	_gate_layer.layer = 70
	add_child(_gate_layer)
	var m := GateMap.new()
	_gate_layer.add_child(m)
	m.descend.connect(_on_gate_descend)
	m.closed.connect(func(): _gate_layer.queue_free())
	if _qa_auto:
		get_tree().create_timer(0.8, true, false, true).timeout.connect(m.qa_descend)

func _on_gate_descend(region: String) -> void:
	if region != "red_reaches":
		return
	if _gate_layer and is_instance_valid(_gate_layer):
		_gate_layer.queue_free()
	_descend.call_deferred()

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

func _open_gear() -> void:
	if runner.active or habitat != null or _returning:
		return
	Audio.sfx("ui_tap")
	var cl := CanvasLayer.new()
	cl.layer = 70
	add_child(cl)
	var g := GearScreen.new()
	cl.add_child(g)
	g.tree_exited.connect(cl.queue_free)

func _open_bonds() -> void:
	if runner.active or habitat != null or _returning or (_bonds_screen and is_instance_valid(_bonds_screen)):
		return
	Audio.sfx("ui_tap")
	var cl := CanvasLayer.new()
	cl.layer = 70
	add_child(cl)
	var b := BondScreen.new()
	cl.add_child(b)
	_bonds_screen = cl
	b.tree_exited.connect(cl.queue_free)

func _on_bond_changed(character_id: String, stage: String) -> void:
	if character_id in ["aruun", "cigarra"] and stage == "bonded":
		return
	_toast("Bond Contract: %s is now %s" % [Canon.display_name(character_id), stage.to_upper()], "trust")

func _on_promise_changed(_promise_id: String, status: String) -> void:
	match status:
		"open": _toast("Promise made. It is judged when you return (see Bonds).", "info")
		"kept": _toast("Promise KEPT, letter and spirit.", "trust")
		"loophole": _toast("Promise kept to the LETTER only.", "warning")
		"bent": _toast("Promise kept in spirit, not in wording.", "warning")
		"broken": _toast("Promise BROKEN.", "warning")

func _open_menu() -> void:
	if runner.active or habitat != null or _returning:
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
	if runner.active or habitat != null or _returning:
		return
	await get_tree().create_timer(0.5).timeout
	if runner.active or habitat != null or _returning:
		return
	if bool(GameState.get_flag("_returned_pending", false)):
		_return_sequence()
		return
	if not bool(GameState.get_flag("briefed", false)):
		runner.play("hub_intro")
	elif bool(GameState.get_flag("rr_complete", false)) and not bool(GameState.get_flag("debriefed", false)):
		runner.play("hub_debrief")
	elif bool(GameState.get_flag("habitat_built", false)) and not bool(GameState.get_flag("slice_complete", false)) and not DialogueRunner.seen("hub_hook"):
		runner.play("hub_hook")

## After a descent: the Ledger card ("what changed because of you"), then the Reaction Matrix barks
## (Ledger.take_reaction(char, "return") through the dialogue box), then the story debrief the first time.
func _return_sequence() -> void:
	_returning = true
	GameState.flags["_returned_pending"] = false
	GameState.save_game()
	var card := LedgerCard.debrief(-1, "Continue")
	card.subtitle = "Back at the Common. The Ledger remembers."
	add_child(card)
	if _qa_auto:
		get_tree().create_timer(1.2, true, false, true).timeout.connect(card.close)
	await card.closed
	var barks := _collect_return_barks()
	if not barks.is_empty():
		runner.play_data("hub_return_barks", {"lines": barks})
		while runner.active:
			await get_tree().process_frame
	_returning = false
	if bool(GameState.get_flag("rr_complete", false)) and not bool(GameState.get_flag("debriefed", false)):
		runner.play("hub_debrief")
	_update_objective()

## Up to N return barks (N from the Story tone), best priority first, one per character.
func _collect_return_barks() -> Array:
	var n: int = [0, 1, 2, 3, 4][Director.story_level()]
	if n <= 0:
		return []
	var cands: Array = []
	var chars: Array = ["aruun", "cigarra", "zephyr", "bramvex", "mara", "dexter"]
	for c in Ledger.reaction_defs:
		if not (c in chars) and not str(c).begins_with("_"):
			chars.append(c)
	for c in chars:
		var rs: Array = Ledger.reactions_for(c, "return")
		if not rs.is_empty():
			cands.append([int(rs[0].get("priority", 0)), c])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var lines: Array = []
	for i in mini(n, cands.size()):
		var r: Dictionary = Ledger.take_reaction(str(cands[i][1]), "return")
		if not r.is_empty():
			lines.append({"who": str(cands[i][1]), "expr": str(r.get("expr", "default")), "text": str(r.get("text", ""))})
	return lines

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
	if on:
		get_tree().create_timer(1.2, true, false, true).timeout.connect(qa_card_close)
		if _gate_layer and is_instance_valid(_gate_layer) and _gate_layer.get_child_count() > 0:
			(_gate_layer.get_child(0) as GateMap).qa_descend()
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

## QA: open the pause menu / codex / a dialogue without auto-advance (for screenshots).
func qa_open(what: String) -> void:
	var _t := Time.get_ticks_usec()
	_qa_open(what)
	print("[PERF] open %s ms=%.1f" % [what, (Time.get_ticks_usec() - _t) / 1000.0])

func _qa_open(what: String) -> void:
	match what:
		"menu": add_child(PauseMenu.new())
		"codex": _open_codex()
		"habitat": open_habitat()
		"end_card": _show_end_card()
		"bonds": _open_bonds()
		"gear": _open_gear()
		"gate": open_gate_map()

func qa_close_all() -> void:
	for c in get_children():
		if c is PauseMenu:
			c.queue_free()
		elif c is CanvasLayer and c.get_child_count() > 0 and (c.get_child(0) is CodexScreen or c.get_child(0) is BondScreen or c.get_child(0) is GateMap):
			c.queue_free()
	get_tree().paused = false

func qa_return() -> void:
	GameState.flags["_returned_pending"] = true
	_return_sequence()

func qa_card_close() -> void:
	for c in get_children():
		if c is LedgerCard:
			c.close()
