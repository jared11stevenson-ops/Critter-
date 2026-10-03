extends Node3D
## Habitat Wing builder (GDD §9, Bible §5/§13/§55). Pick a contained specimen, place one module per slot
## (Substrate → Symbiont → Climate → Anchor) paid with field materials. Wrong pieces stress the
## specimen (with feedback); a correct chain makes it thrive and sets `habitat_built`.
## If the Ochre Span was braced, a free Burden Bridge appears — "A bridge exists because Aruun helped design it."

signal closed

const VISUAL := "res://game/world/habitat/habitat_visual.tscn"
const SLOTS := ["Substrate", "Symbiont", "Climate", "Anchor"]

const MODULES := {
	"reach_soil_bed": {"name": "Red Reach Soil Bed", "slot": "Substrate", "cost": {"reach_soil": 2}, "col": "#a8553a"},
	"thoughtstone_pedestal": {"name": "Thoughtstone Pedestal", "slot": "Substrate", "cost": {"thoughtstone_dust": 2}, "col": "#8fd0ef"},
	"lichen_mat": {"name": "Lichen Mat", "slot": "Symbiont", "cost": {"lichen_culture": 2}, "col": "#9ccf5a"},
	"moss_bed": {"name": "Moss Bed", "slot": "Symbiont", "cost": {"lichen_culture": 1, "reach_soil": 1}, "col": "#5f8a3a"},
	"heat_lamp": {"name": "Heat Lamp", "slot": "Climate", "cost": {"salvage": 2}, "col": "#ff9a4a"},
	"humidity_mister": {"name": "Humidity Mister", "slot": "Climate", "cost": {"salvage": 2}, "col": "#7fc8ff"},
	"lumen_lamp": {"name": "Lumen Lamp", "slot": "Climate", "cost": {"salvage": 1, "thoughtstone_dust": 1}, "col": "#e6f07a"},
	"scale_anchor": {"name": "Scale Anchor (tuned)", "slot": "Anchor", "cost": {"thoughtstone_dust": 1, "salvage": 1}, "col": "#c8c2b0"},
}

const CHAINS := {
	"plate_beetle": {"Substrate": "reach_soil_bed", "Symbiont": "lichen_mat", "Climate": "heat_lamp", "Anchor": "scale_anchor"},
	"skitter_mite": {"Substrate": "reach_soil_bed", "Symbiont": "moss_bed", "Climate": "heat_lamp", "Anchor": "scale_anchor"},
	"dust_grazer": {"Substrate": "reach_soil_bed", "Symbiont": "lichen_mat", "Climate": "humidity_mister", "Anchor": "scale_anchor"},
}

const HINTS := {
	"plate_beetle": {"Substrate": "It digs for mineral crust — it needs real Reach soil.", "Symbiont": "It grazes mineral lichen, not moss.", "Climate": "Slate carapace: it wants dry radiant heat.", "Anchor": "Without a tuned Scale Anchor it can't settle its Scale State."},
	"skitter_mite": {"Substrate": "Mites strip crust from Reach rock — give them Reach soil.", "Symbiont": "They shelter in damp moss, not lichen mats.", "Climate": "Rust-red mites bask; they need heat.", "Anchor": "Every specimen needs a tuned Scale Anchor."},
	"dust_grazer": {"Substrate": "Grazers walk on Reach soil — their droppings seed it.", "Symbiont": "They graze lichen. The lichen holds the soil together.", "Climate": "Lichen dies in dry heat; the herd needs moisture.", "Anchor": "Every specimen needs a tuned Scale Anchor."},
}

var specimen_i := 0
var _env_root: Node3D
var _visual: Node3D
var _cam: Camera3D
var _ui: CanvasLayer
var _root: Control
var _slot_buttons: Dictionary = {}
var _health_bar: ProgressBar
var _status: Label
var _feedback: Label
var _materials: Label
var _picker: Control = null
var _spec_label: Label
var _module_nodes: Dictionary = {}
var _creature: Node3D = null
var _bridge: Node3D = null
var _t := 0.0
var _done_btn: Button

func _ready() -> void:
	_build_world()
	_build_ui()
	_refresh()

# ---------------- world ----------------
func _build_world() -> void:
	_env_root = Node3D.new()
	add_child(_env_root)
	if ResourceLoader.exists(VISUAL):
		var ps: Variant = load(VISUAL)
		if ps is PackedScene:
			_visual = (ps as PackedScene).instantiate()
	if _visual == null:
		_visual = load("res://game/world/habitat/habitat_fallback.gd").new()
	_env_root.add_child(_visual)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	_env_root.add_child(_cam)
	var focus := _marker_pos("SpecimenSpot", Vector3.ZERO)
	_cam.global_position = focus + Vector3(0, 7.5, 9.5)
	_cam.look_at(focus + Vector3(0, 0.6, 0), Vector3.UP)
	_cam.current = true

func _marker(n: String) -> Node3D:
	return _visual.find_child(n, true, false) as Node3D

func _marker_pos(n: String, fb: Vector3) -> Vector3:
	var m := _marker(n)
	return m.global_position if m else fb

func _spec() -> Dictionary:
	if GameState.specimens.is_empty():
		return {}
	specimen_i = clampi(specimen_i, 0, GameState.specimens.size() - 1)
	var s: Variant = GameState.specimens[specimen_i]
	if not (s is Dictionary):
		return {}
	if not (s as Dictionary).has("habitat") or not (s["habitat"] is Dictionary):
		s["habitat"] = {}
	return s

func _species() -> String:
	return str(_spec().get("species", "dust_grazer"))

# ---------------- UI ----------------
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 30
	add_child(_ui)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.theme()
	_ui.add_child(_root)
	# header
	var head := PanelContainer.new()
	head.position = Vector2(20, 16)
	head.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.95), UiKit.ACCENT.darkened(0.2), 18, 3, 18))
	_root.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	head.add_child(hv)
	hv.add_child(UiKit.label("HABITAT WING", 30, UiKit.ACCENT, "title"))
	var sp_row := HBoxContainer.new()
	hv.add_child(sp_row)
	var prev := UiKit.button("<", Vector2(88, 88), 30)
	prev.pressed.connect(_cycle.bind(-1))
	sp_row.add_child(prev)
	_spec_label = UiKit.label("", 28, UiKit.INK, "bold")
	_spec_label.custom_minimum_size = Vector2(300, 0)
	_spec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spec_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp_row.add_child(_spec_label)
	var nxt := UiKit.button(">", Vector2(88, 88), 30)
	nxt.pressed.connect(_cycle.bind(1))
	sp_row.add_child(nxt)
	hv.add_child(UiKit.label("HABITAT HEALTH", 20, UiKit.MUTED, "bold"))
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(476, 22)
	_health_bar.show_percentage = false
	_health_bar.max_value = 1.0
	_health_bar.step = 0.0
	_health_bar.add_theme_stylebox_override("background", UiKit.box(Color(0.1, 0.07, 0.06, 0.8), Color(0, 0, 0, 0), 8, 0, 0))
	_health_bar.add_theme_stylebox_override("fill", UiKit.box(Color("#5fbf5a"), Color(0, 0, 0, 0), 8, 0, 0))
	hv.add_child(_health_bar)
	_status = UiKit.label("", 24, UiKit.INK, "ui")
	hv.add_child(_status)
	_feedback = UiKit.label("", 22, UiKit.ACCENT.darkened(0.2), "dialogue")
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size = Vector2(476, 0)
	hv.add_child(_feedback)
	_materials = UiKit.label("", 22, UiKit.INK, "ui")
	_materials.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_materials.custom_minimum_size = Vector2(476, 0)
	hv.add_child(_materials)
	# slot cards on the right
	var col := VBoxContainer.new()
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.offset_left = -370
	col.offset_right = -20
	col.offset_top = 16
	col.add_theme_constant_override("separation", 12)
	_root.add_child(col)
	for s in SLOTS:
		var b := UiKit.button(s, Vector2(350, 104), 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_open_picker.bind(s))
		b.name = "Slot_" + s
		col.add_child(b)
		_slot_buttons[s] = b
	_done_btn = UiKit.button("Return to the Common", Vector2(350, 88), 26)
	_done_btn.pressed.connect(close)
	col.add_child(_done_btn)

func _cycle(d: int) -> void:
	if GameState.specimens.size() <= 1:
		return
	specimen_i = (specimen_i + d + GameState.specimens.size()) % GameState.specimens.size()
	Audio.sfx("ui_tap")
	_feedback.text = ""
	_refresh()

func _cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), UiKit.item_name(k)])
	return ", ".join(parts) if parts.size() > 0 else "free"

func _can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if GameState.item_count(k) < int(cost[k]):
			return false
	return true

func _open_picker(slot: String) -> void:
	Audio.sfx("ui_tap")
	_close_picker()
	_picker = PanelContainer.new()
	_picker.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.CARD, 0.97), UiKit.ACCENT, 18, 3, 20))
	_root.add_child(_picker)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_picker.add_child(vb)
	vb.add_child(UiKit.label("%s — choose a module" % slot.to_upper(), 28, UiKit.PARCHMENT, "bold"))
	var hab: Dictionary = _spec().get("habitat", {})
	var current: String = str(hab.get(slot, ""))
	for id in MODULES:
		var m: Dictionary = MODULES[id]
		if m["slot"] != slot:
			continue
		var afford := _can_afford(m["cost"])
		var b := UiKit.button("%s   ·   %s" % [m["name"], _cost_text(m["cost"])], Vector2(640, 88), 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if id == current:
			b.text += "   (placed)"
			b.disabled = true
		elif not afford:
			b.text += "   — need more"
		b.pressed.connect(_place.bind(slot, id))
		vb.add_child(b)
	var row := HBoxContainer.new()
	vb.add_child(row)
	if current != "":
		var rm := UiKit.button("Remove (refund)", Vector2(300, 88), 24)
		rm.pressed.connect(_remove.bind(slot))
		row.add_child(rm)
	var cancel := UiKit.button("Cancel", Vector2(200, 88), 24)
	cancel.pressed.connect(_close_picker)
	row.add_child(cancel)
	_picker.reset_size()
	var vs := _root.get_viewport_rect().size
	_picker.position = (vs - _picker.size) * 0.5

func _close_picker() -> void:
	if _picker:
		_picker.queue_free()
		_picker = null

func _place(slot: String, id: String) -> void:
	var m: Dictionary = MODULES[id]
	var cost: Dictionary = m["cost"]
	if not _can_afford(cost):
		if id != str(CHAINS.get(_species(), {}).get(slot, "")):
			_feedback.text = "Not enough materials for %s." % m["name"]
			Audio.sfx("ui_back")
			return
		# Zero dead ends: for the right piece, Mara requisitions the shortfall from Terrarium stores.
		for k in cost:
			var short := int(cost[k]) - GameState.item_count(k)
			if short > 0:
				GameState.add_item(k, short)
		Events.toast.emit("Mara requisitions the missing materials from Terrarium stores", "info")
	var spec := _spec()
	var hab: Dictionary = spec["habitat"]
	if hab.has(slot):
		_refund(str(hab[slot]))
	for k in cost:
		GameState.spend_item(k, int(cost[k]))
	hab[slot] = id
	Audio.sfx("ui_confirm")
	_close_picker()
	var correct: String = CHAINS.get(_species(), {}).get(slot, "")
	if id == correct:
		_feedback.text = "%s fits. The specimen settles a little." % m["name"]
		_feedback.label_settings.font_color = Color("#3c7a2c")
	else:
		_feedback.text = "Stress! " + str(HINTS.get(_species(), {}).get(slot, "This piece doesn't fit its chain."))
		_feedback.label_settings.font_color = UiKit.ACCENT.darkened(0.2)
		Audio.sfx("ui_back")
	GameState.save_game()
	_refresh()

func _refund(id: String) -> void:
	if not MODULES.has(id):
		return
	var cost: Dictionary = MODULES[id]["cost"]
	for k in cost:
		GameState.add_item(k, int(cost[k]))

func _remove(slot: String) -> void:
	var hab: Dictionary = _spec()["habitat"]
	if hab.has(slot):
		_refund(str(hab[slot]))
		hab.erase(slot)
	Audio.sfx("ui_back")
	_close_picker()
	_feedback.text = ""
	_refresh()

func health() -> float:
	var hab: Dictionary = _spec().get("habitat", {})
	var chain: Dictionary = CHAINS.get(_species(), {})
	var h := 0.0
	for s in SLOTS:
		if hab.has(s):
			h += 0.25 if hab[s] == chain.get(s, "") else -0.1
	return clampf(h, 0.0, 1.0)

func _complete() -> bool:
	var hab: Dictionary = _spec().get("habitat", {})
	var chain: Dictionary = CHAINS.get(_species(), {})
	for s in SLOTS:
		if hab.get(s, "") != chain.get(s, "x"):
			return false
	return true

func _refresh() -> void:
	var spec := _spec()
	if spec.is_empty():
		_spec_label.text = "No specimens"
		return
	var sp := _species()
	var n := GameState.specimens.size()
	_spec_label.text = "%s  (%d/%d)" % [Canon.species(sp).get("name", sp), specimen_i + 1, n]
	var hab: Dictionary = spec["habitat"]
	var chain: Dictionary = CHAINS.get(sp, {})
	for s in SLOTS:
		var b: Button = _slot_buttons[s]
		var id: String = str(hab.get(s, ""))
		if id == "":
			b.text = "%s\n+ choose module" % s.to_upper()
		else:
			var ok: bool = id == chain.get(s, "")
			b.text = "%s\n%s %s" % [s.to_upper(), "✓" if ok else "✗", MODULES[id]["name"]]
	var h := health()
	var tw := create_tween()
	tw.tween_property(_health_bar, "value", h, 0.35)
	var fill := Color("#5fbf5a") if h >= 0.99 else (Color("#d9a43a") if h >= 0.4 else Color("#c8462b"))
	_health_bar.add_theme_stylebox_override("fill", UiKit.box(fill, Color(0, 0, 0, 0), 8, 0, 0))
	var mats: Array = []
	for k in ["reach_soil", "lichen_culture", "thoughtstone_dust", "salvage"]:
		mats.append("%s %d" % [UiKit.item_name(k), GameState.item_count(k)])
	_materials.text = "Materials: " + " · ".join(mats)
	if _complete():
		_status.text = "THRIVING — the chain is complete."
		if not bool(GameState.get_flag("habitat_built", false)):
			GameState.set_flag("habitat_built", true)
			Events.toast.emit("Habitat complete: %s is thriving" % Canon.species(sp).get("name", sp), "item")
			Audio.sfx("trust_up")
			GameState.save_game()
	else:
		var placed := hab.size()
		_status.text = "Stressed — %d/4 slots" % placed if h < 0.99 else ""
	_update_world_modules()

# ---------------- 3D modules + creature ----------------
func _update_world_modules() -> void:
	var hab: Dictionary = _spec().get("habitat", {})
	for s in SLOTS:
		var id: String = str(hab.get(s, ""))
		var cur: Node3D = _module_nodes.get(s, null)
		if cur and cur.get_meta("module", "") == id:
			continue
		if cur:
			cur.queue_free()
			_module_nodes.erase(s)
		if id == "":
			continue
		var n := _make_module(id)
		n.set_meta("module", id)
		_env_root.add_child(n)
		n.global_position = _marker_pos("Slot_" + s, Vector3((SLOTS.find(s) - 1.5) * 2.2, 0, 1.5))
		n.scale = Vector3.ONE * 0.2
		var tw := n.create_tween()
		tw.tween_property(n, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_module_nodes[s] = n
	if _creature == null:
		_creature = VisualFactory.creature(_species())
		_env_root.add_child(_creature)
		_creature.global_position = _marker_pos("SpecimenSpot", Vector3.ZERO)
		_creature.set_meta("species", _species())
	elif _creature.get_meta("species", "") != _species():
		_creature.queue_free()
		_creature = null
		_update_world_modules()
		return
	if bool(GameState.get_flag("ochre_span_braced", false)) and _bridge == null:
		_bridge = _make_module("burden_bridge")
		_env_root.add_child(_bridge)
		_bridge.global_position = _marker_pos("SpecimenSpot", Vector3.ZERO) + Vector3(0, 0, -2.4)
		Events.toast.emit("A Burden Bridge stands in the Habitat. A bridge exists because Aruun helped design it.", "info")

func _make_module(id: String) -> Node3D:
	var path := "res://game/art/habitat/%s.tscn" % id
	if ResourceLoader.exists(path):
		var ps: Variant = load(path)
		if ps is PackedScene:
			return (ps as PackedScene).instantiate()
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var col := Color(MODULES.get(id, {}).get("col", "#d9a06a"))
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	if id in ["heat_lamp", "lumen_lamp", "humidity_mister"]:
		m.emission_enabled = true
		m.emission = col * 0.8
		var cm := CylinderMesh.new()
		cm.top_radius = 0.35
		cm.bottom_radius = 0.1
		cm.height = 1.6
		mi.mesh = cm
		mi.position.y = 0.8
	elif id == "scale_anchor":
		var pm := PrismMesh.new()
		pm.size = Vector3(0.7, 1.2, 0.7)
		mi.mesh = pm
		mi.position.y = 0.6
	elif id == "burden_bridge":
		var bm := BoxMesh.new()
		bm.size = Vector3(3.2, 0.25, 0.9)
		mi.mesh = bm
		mi.position.y = 0.7
		col = Color("#c49a62")
		m.albedo_color = col
		for sx in [-1.4, 1.4]:
			var leg := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.3, 0.7, 0.9)
			leg.mesh = lb
			leg.position = Vector3(sx, 0.35, 0)
			leg.material_override = m
			n.add_child(leg)
	else:
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(1.6, 0.25, 1.2)
		mi.mesh = bm2
		mi.position.y = 0.12
	mi.material_override = m
	n.add_child(mi)
	return n

func _process(delta: float) -> void:
	_t += delta
	if _creature and is_instance_valid(_creature):
		var h := health()
		var center := _marker_pos("SpecimenSpot", Vector3.ZERO)
		if _complete():
			var p := center + Vector3(cos(_t * 0.6) * 1.4, 0, sin(_t * 0.9) * 0.9)
			var d := p - _creature.global_position
			_creature.global_position = p
			VisualFactory.call_v(_creature, "set_facing", [d])
			VisualFactory.call_v(_creature, "set_move_amount", [0.6])
		else:
			# stressed: jittery pacing
			var j := (1.0 - h) * 0.15
			_creature.global_position = center + Vector3(sin(_t * 9.0) * j, 0, cos(_t * 7.0) * j)
			VisualFactory.call_v(_creature, "set_move_amount", [0.2 + (1.0 - h) * 0.5])

func close() -> void:
	Audio.sfx("ui_back")
	GameState.save_game()
	closed.emit()
	queue_free()

func qa_solve() -> void:
	var chain: Dictionary = CHAINS.get(_species(), {})
	for s in SLOTS:
		_place(s, chain[s])
