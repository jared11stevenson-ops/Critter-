class_name GateMap
extends Control
## The Gate Map (master plan #1): Stage -1 drawn the way the bible says Critter is mapped, as a mosaic of
## separate surveys with enormous blank spaces. A homeland is BLANK until you have a reason to know it,
## RUMORED once someone from there has talked to you, and CHARTED (with a route that fills in) only where
## you have actually walked. Only the Red Reaches can be descended to in this slice.
## Everything shown here is derived from flags / the Ledger / the codex; the map stores nothing.

signal descend(region_id: String)
signal closed

const REGIONS := [
	{"id": "canopy_fold", "name": "The Canopy Fold", "from": "cigarra", "pos": Vector2(0.20, 0.24), "r": 0.085,
		"style": "Routes are drawn as odds of safe passage, the way Cigarra's people tell them.", "rumor": "Cigarra's homeland. No survey on file; her people chart by probability, not distance."},
	{"id": "red_reaches", "name": "The Red Reaches", "from": "aruun", "pos": Vector2(0.52, 0.54), "r": 0.2,
		"style": "Plateaus and fracture valleys. Settlements survive because generations maintain bridges, wells and roads.", "rumor": ""},
	{"id": "lumen_depths", "name": "The Lumen Depths", "from": "nerit", "pos": Vector2(0.80, 0.80), "r": 0.075,
		"style": "", "rumor": "Nerit's homeland. Too far from any road to chart from here."},
	{"id": "rainward", "name": "Rainward", "from": "mollusk", "pos": Vector2(0.84, 0.26), "r": 0.075,
		"style": "", "rumor": "Mollusk's homeland. Nobody at the Common can say how far it is."},
	{"id": "briarwild", "name": "The Briarwild", "from": "zephyr", "pos": Vector2(0.10, 0.72), "r": 0.075,
		"style": "", "rumor": "Zephyr's homeland. Zephyr's directions are mostly rules about who owes whom."},
	{"id": "frostbloom", "name": "Frostbloom", "from": "nyxaris", "pos": Vector2(0.58, 0.09), "r": 0.07,
		"style": "", "rumor": "Nyxaris's homeland. Cold enough that the maps freeze to the table."},
	{"id": "velvet_warrens", "name": "The Velvet Warrens", "from": "scarlith", "pos": Vector2(0.33, 0.88), "r": 0.065,
		"style": "", "rumor": "Scarlith's homeland. Entrances are not shown on any chart he will admit to."},
	{"id": "pelagic_expanse", "name": "The Pelagic Expanse", "from": "solmara", "pos": Vector2(0.93, 0.55), "r": 0.06,
		"style": "", "rumor": "Solmara's homeland. Her people encode geography as tidal and gravitational rhythm."},
	{"id": "thornmarch", "name": "Thornmarch", "from": "bramvex", "pos": Vector2(0.06, 0.45), "r": 0.06,
		"style": "", "rumor": "Bramvex's homeland. He marks the exits; he does not mark the way in."},
]
const RR_SITES := [
	["arrived_rr", "Gate landing", Vector2(-0.80, 0.30)], ["valley_clear", "Valley", Vector2(-0.53, 0.05)],
	["rope_dropped", "The Gap", Vector2(-0.26, -0.20)], ["boulder_broken", "Waystation", Vector2(0.0, 0.12)],
	["drill_clear", "Drill Site", Vector2(0.27, 0.30)], ["burden_done", "Ochre Span", Vector2(0.54, 0.02)],
	["boss_defeated", "Foundation", Vector2(0.80, -0.22)],
]

var _sel := "red_reaches"
var _map: Control
var _info_title: Label
var _info_body: Label
var _info_state: Label
var _go: Button
var _list: VBoxContainer
var _polys: Dictionary = {}     # id -> PackedVector2Array (local to the map control)
var _centers: Dictionary = {}

func _ready() -> void:
	Quality.set_covered(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.04, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := UiKit.label("THE GATE MAP", 40, UiKit.PARCHMENT, "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var sub := UiKit.label("A mosaic of surveys. The blank parts are honest.", 22, UiKit.PARCHMENT.darkened(0.3), "dialogue")
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sub)
	var close := UiKit.button("Close", Vector2(160, 64), 26)
	close.pressed.connect(_close)
	close.name = "Close"
	top.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	vb.add_child(body)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(250, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	sc.add_child(_list)
	for r in REGIONS:
		var b := UiKit.button(_region_label(r), Vector2(0, 54), 22)
		b.name = "Region_" + str(r["id"])
		b.pressed.connect(select.bind(str(r["id"])))
		_list.add_child(b)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	_map = Control.new()
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.custom_minimum_size = Vector2(600, 300)
	_map.clip_contents = true
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	_map.resized.connect(_rebuild_polys)
	right.add_child(_map)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.98), UiKit.PARCHMENT_DARK.darkened(0.35), 16, 4, 14))
	right.add_child(info)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 14)
	info.add_child(ih)
	var iv := VBoxContainer.new()
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iv.add_theme_constant_override("separation", 2)
	ih.add_child(iv)
	_info_title = UiKit.label("", 30, UiKit.INK, "title")
	iv.add_child(_info_title)
	_info_state = UiKit.label("", 20, UiKit.ACCENT, "bold")
	iv.add_child(_info_state)
	_info_body = UiKit.label("", 22, UiKit.INK, "dialogue")
	_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_body.custom_minimum_size = Vector2(520, 0)
	iv.add_child(_info_body)
	_go = UiKit.button("Descend", Vector2(230, 80), 28)
	_go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_go.pressed.connect(_on_go)
	_go.name = "Descend"
	ih.add_child(_go)
	select(_sel)
	_go.grab_focus.call_deferred()

# ---------------- state (derived, never stored) ----------------
## "charted" | "rumored" | "blank"
func region_state(id: String) -> String:
	if id == "red_reaches":
		return "charted"
	for r in REGIONS:
		if r["id"] == id:
			var who := str(r["from"])
			if who == "cigarra" or who in Ledger.bonded_characters():
				return "rumored"
			if Ledger.exists({"type": "talked", "target": who}) or ("char_" + who) in GameState.codex:
				return "rumored"
	return "blank"

## 0..1 of the Reaches walked so far.
func rr_progress() -> float:
	var n := 0
	for s in RR_SITES:
		if bool(GameState.get_flag(str(s[0]), false)):
			n += 1
	return float(n) / float(RR_SITES.size())

func _region_label(r: Dictionary) -> String:
	var st := region_state(str(r["id"]))
	return str(r["name"]) if st != "blank" else "Uncharted"

func _find(id: String) -> Dictionary:
	for r in REGIONS:
		if r["id"] == id:
			return r
	return {}

# ---------------- selection / info ----------------
func select(id: String) -> void:
	_sel = id
	Audio.sfx("ui_tap", -6.0)
	var r := _find(id)
	var st := region_state(id)
	_info_title.text = str(r["name"]) if st != "blank" else "Uncharted"
	_go.visible = false
	match st:
		"charted":
			var pr := int(round(rr_progress() * 100.0))
			_info_state.text = "CHARTED  ·  %d%% walked" % pr
			_info_body.text = str(r["style"]) + "\n" + _mara_line()
			_go.visible = true
			_go.text = "Descend" if not bool(GameState.get_flag("rr_complete", false)) else "Return Descent"
		"rumored":
			_info_state.text = "RUMORED  ·  no survey on file"
			_info_body.text = str(r["rumor"])
		_:
			_info_state.text = "BLANK  ·  nobody here has been there"
			_info_body.text = "A blank is not an error. Different peoples map different things, and some of them have never been asked."
	_map.queue_redraw()

func _mara_line() -> String:
	if bool(GameState.get_flag("rr_complete", false)):
		var open := 0
		for r in Rivals.active_in("red_reaches"):
			open += 1
		if open > 0:
			return "Mara: \"The Reaches remember you, and so do %d people out there.\"" % open
		return "Mara: \"The Reaches remember what you did there.\""
	return "Mara: \"Gate is calibrated for the Red Reaches.\""

func _on_go() -> void:
	Audio.sfx("ui_confirm")
	descend.emit(_sel)

func _close() -> void:
	Audio.sfx("ui_back")
	closed.emit()
	queue_free()

func qa_descend() -> void:
	select("red_reaches")
	_on_go()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

# ---------------- map drawing ----------------
func _rebuild_polys() -> void:
	var sz := _map.size
	_polys.clear()
	_centers.clear()
	for r in REGIONS:
		var c: Vector2 = (r["pos"] as Vector2) * sz
		var rad: float = float(r["r"]) * minf(sz.x, sz.y * 1.6)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(r["id"]))
		var pts := PackedVector2Array()
		var n := 16
		for i in n:
			var a := TAU * float(i) / float(n)
			var jr := rad * rng.randf_range(0.72, 1.18)
			pts.append(c + Vector2(cos(a) * jr * 1.25, sin(a) * jr * 0.9))
		_polys[r["id"]] = pts
		_centers[r["id"]] = c
	_map.queue_redraw()

func _on_map_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = (ev as InputEventMouseButton).position
		var best := ""
		var bd := 1.0e9
		for id in _polys:
			if Geometry2D.is_point_in_polygon(p, _polys[id]):
				best = str(id)
				break
			var d := p.distance_to(_centers[id])
			if d < 70.0 and d < bd:
				bd = d
				best = str(id)
		if best != "":
			select(best)
			var b := _list.get_node_or_null("Region_" + best) as Button
			if b:
				b.grab_focus()

func _draw_map() -> void:
	var sz := _map.size
	if _polys.is_empty():
		_rebuild_polys()
	var paper := UiKit.PARCHMENT
	_map.draw_rect(Rect2(Vector2.ZERO, sz), paper.darkened(0.04))
	# faint survey grid (the "mosaic" seams): different surveys do not share one grid
	var gcol := Color(UiKit.INK, 0.06)
	var x := 0.0
	while x < sz.x:
		_map.draw_line(Vector2(x, 0), Vector2(x, sz.y), gcol, 1.0)
		x += 64.0
	var y := 0.0
	while y < sz.y:
		_map.draw_line(Vector2(0, y), Vector2(sz.x, y), gcol, 1.0)
		y += 64.0
	var font: Font = UiKit.font("title")
	if font == null:
		font = ThemeDB.fallback_font
	var small: Font = UiKit.font("bold")
	if small == null:
		small = ThemeDB.fallback_font
	for r in REGIONS:
		var id := str(r["id"])
		var pts: PackedVector2Array = _polys[id]
		var c: Vector2 = _centers[id]
		var st := region_state(id)
		var sel := id == _sel
		match st:
			"charted":
				_map.draw_colored_polygon(pts, Color("#c98b5a", 0.55))
				_draw_contours(pts, c)
				_map.draw_polyline(_closed(pts), UiKit.ACCENT.darkened(0.2), 3.0 if sel else 2.0)
				_draw_route(c, float(r["r"]) * minf(sz.x, sz.y * 1.6), small)
			"rumored":
				_map.draw_colored_polygon(pts, Color(UiKit.PARCHMENT_DARK, 0.45))
				_dashed_outline(pts, UiKit.MUTED, 2.0 if not sel else 3.5)
			_:
				_dashed_outline(pts, Color(UiKit.MUTED, 0.45), 1.5 if not sel else 3.0)
		var label := str(r["name"]) if st != "blank" else "?"
		var fs := 22 if st == "charted" else (18 if st == "rumored" else 28)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := UiKit.INK if st != "blank" else Color(UiKit.MUTED, 0.8)
		_map.draw_string(font, c + Vector2(-tw * 0.5, -float(r["r"]) * sz.y * 0.9 - 8.0 if st == "charted" else 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	# the unplaced one: Pharilux's homeland is unknown even to the bible; leave a deliberate blank mark
	var q := Vector2(0.36, 0.50) * sz
	_map.draw_string(font, q, "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(UiKit.MUTED, 0.5))

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var o := pts.duplicate()
	o.append(pts[0])
	return o

func _dashed_outline(pts: PackedVector2Array, col: Color, w: float) -> void:
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		if i % 2 == 0:
			_map.draw_line(a, b, col, w)

func _draw_contours(pts: PackedVector2Array, c: Vector2) -> void:
	for k in [0.72, 0.46, 0.22]:
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * k)
		inner.append(inner[0])
		_map.draw_polyline(inner, Color(UiKit.ACCENT.darkened(0.3), 0.35), 1.5)

## The route through the Reaches fills in as the player walks it; unwalked stretches are simply not drawn.
func _draw_route(c: Vector2, rad: float, small: Font) -> void:
	var prev := Vector2.ZERO
	var have_prev := false
	var idx := 0
	for s in RR_SITES:
		idx += 1
		var done := bool(GameState.get_flag(str(s[0]), false))
		var p: Vector2 = c + (s[2] as Vector2) * rad * 1.9
		if done:
			if have_prev:
				_map.draw_line(prev, p, UiKit.INK, 3.0)
			_map.draw_circle(p, 7.0, UiKit.ACCENT)
			_map.draw_arc(p, 9.0, 0.0, TAU, 20, UiKit.INK, 2.0)
			var lo := Vector2(10, -10) if idx % 2 == 1 else Vector2(10, 22)
			_map.draw_string(small, p + lo, str(s[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.INK)
			prev = p
			have_prev = true
		else:
			break

func _exit_tree() -> void:
	Quality.set_covered(false)
