class_name ExploreHud
extends CanvasLayer
## Minimap + landmark guidance + fast-travel (Gate Map stub) for the field. Sits under the main HUD (layer 19).
## The map fills in as ground is walked; places show once found, hidden things only as a faint pulse when you are close.
## Gold chevron = the story's next soft target (never forced). Pale chevron = a place sensed nearby you have not found.
## Tap / click the map (or press M) for the waypoint list. All drawing is one Control, redrawn at ~8 Hz.

const SIZE := 170.0
const RANGE_M := 52.0                 # half-width of the map in metres
const REDRAW_S := 0.12

var ex: RrExplore
var _map: Control
var _title: Label
var _panel: PanelContainer
var _list: VBoxContainer
var _msg: Label
var _redraw_t := 0.0
var _was_paused := false
var _polys: Array = []                # [{f, poly}]

func setup(explore: RrExplore) -> void:
	ex = explore

func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	for f in ex.floors:
		_polys.append({"f": f, "poly": ExploreRules.shape_poly(f)})
	_map = Control.new()
	_map.name = "Map"
	_map.custom_minimum_size = Vector2(SIZE, SIZE)
	_map.size = Vector2(SIZE, SIZE)
	_map.clip_contents = true
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	add_child(_map)
	_title = UiKit.label("", 18, UiKit.PARCHMENT, "bold", 6, Color(0, 0, 0, 0.9))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var lh := bool(GameState.settings.get("left_handed", false))
	var pos := Vector2(18.0, 150.0) if lh else Vector2(vs.x - 18.0 - SIZE, 118.0)
	_map.position = pos
	_title.position = pos + Vector2(0, SIZE + 2)
	_title.size = Vector2(SIZE, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _panel:
		_panel.position = (vs - _panel.size) * 0.5

func _process(delta: float) -> void:
	if ex == null or ex.level == null:
		return
	var party: Variant = ex.level.get("party")
	if party == null or party.get_leader() == null:
		return
	_redraw_t -= delta
	if _redraw_t <= 0.0:
		_redraw_t = REDRAW_S
		_map.queue_redraw()
		_update_title()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_M:
		toggle_panel()
		get_viewport().set_input_as_handled()

func _on_map_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		toggle_panel()
		_map.accept_event()

func _update_title() -> void:
	var lp: Vector3 = ex.level.get("party").get_leader().global_position
	var g := ex.guide_target()
	if g.x == INF:
		_title.text = "%d/%d places" % [ex.found_count(), ex.pois.size()]
		return
	var d := Vector2(g.x - lp.x, g.z - lp.z)
	_title.text = "Next: %d m %s  ·  %d/%d" % [int(d.length()), ExploreRules.compass_word(d.x, d.y), ex.found_count(), ex.pois.size()]

# ------------------------------------------------------------------ drawing
func _w2m(p: Vector3, c: Vector3) -> Vector2:
	return Vector2(SIZE, SIZE) * 0.5 + ExploreRules.to_map(p.x - c.x, p.z - c.z, SIZE * 0.5 / RANGE_M)

func _draw_map() -> void:
	var party: Variant = ex.level.get("party")
	if party == null or party.get_leader() == null:
		return
	var lead: PlayableCritter = party.get_leader()
	var c: Vector3 = lead.global_position
	var half := SIZE * 0.5
	_map.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Color(0.10, 0.07, 0.06, 0.62))
	for pl in _polys:
		if not ex.floor_seen(pl["f"]):
			continue
		var src: PackedVector2Array = pl["poly"]
		var out := PackedVector2Array()
		out.resize(src.size())
		for i in src.size():
			out[i] = _w2m(Vector3(src[i].x, 0.0, src[i].y), c)
		_map.draw_colored_polygon(out, Color(0.70, 0.43, 0.28, 0.55))
	# secrets: a quiet pulse, only when close
	var pulse := fmod(Time.get_ticks_msec() * 0.001, 1.6) / 1.6
	for h in ex.hot_secrets(c):
		_map.draw_arc(_w2m(h["pos"], c), 6.0 + 14.0 * pulse, 0.0, TAU, 20, Color(UiKit.SCAN, 1.0 - pulse), 2.0)
	# places
	var sense := float(ex.data.get("sense_r", 70.0))
	for p in ex.pois:
		var pp: Vector3 = p["pos"]
		var off := _w2m(pp, c)
		var d := Vector2(pp.x - c.x, pp.z - c.z).length()
		if ex.is_discovered(p):
			_diamond(off, 5.0, UiKit.PARCHMENT, p.has("wp"))
		elif d <= sense:
			var inside := absf(off.x - half) < half - 6.0 and absf(off.y - half) < half - 6.0
			if inside:
				_diamond(off, 3.5, Color(UiKit.PARCHMENT, 0.35), false)
			else:
				_chevron(Vector2(half, half) + ExploreRules.clamp_to_edge(off - Vector2(half, half), half - 7.0), (off - Vector2(half, half)).angle(), Color(UiKit.PARCHMENT, 0.4), 5.0)
	# hostiles awake near you
	var f: Variant = ex.level.get("field")
	if f != null:
		for e in f.enemies:
			if is_instance_valid(e) and e.get("team") == "enemy" and e.get("alive") != false:
				var eo := _w2m(e.global_position, c)
				if absf(eo.x - half) < half and absf(eo.y - half) < half:
					_map.draw_circle(eo, 2.6, Color(0.9, 0.25, 0.2, 0.9 if e.get("aggro") == true else 0.45))
	# partner
	var pt: PlayableCritter = party.get_partner()
	if pt:
		_map.draw_circle(_w2m(pt.global_position, c), 3.0, Color(UiKit.PSI, 0.9))
	# story guide
	var g := ex.guide_target()
	if g.x != INF:
		var go := _w2m(g, c)
		var gp := Vector2(half, half) + ExploreRules.clamp_to_edge(go - Vector2(half, half), half - 8.0)
		var a := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.006)
		_chevron(gp, (go - Vector2(half, half)).angle(), Color(1.0, 0.82, 0.30, a), 7.0)
	# player (north up: -z is up; facing from the actor)
	var fa := Vector2(lead.facing.x, lead.facing.z).angle() if "facing" in lead else -PI * 0.5
	_chevron(Vector2(half, half), fa, UiKit.PARCHMENT, 6.0, true)
	_map.draw_string(UiKit.font("bold"), Vector2(half - 5, 15), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(UiKit.PARCHMENT, 0.8))
	_map.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Color(UiKit.PARCHMENT_DARK, 0.9), false, 2.0)

func _diamond(p: Vector2, r: float, col: Color, ring: bool) -> void:
	_map.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), col)
	if ring:
		_map.draw_arc(p, r + 3.0, 0.0, TAU, 14, Color(UiKit.SCAN, 0.9), 1.5)

func _chevron(p: Vector2, ang: float, col: Color, r: float, filled: bool = true) -> void:
	var tip := p + Vector2.from_angle(ang) * r
	var l := p + Vector2.from_angle(ang + 2.5) * r
	var rr := p + Vector2.from_angle(ang - 2.5) * r
	_map.draw_colored_polygon(PackedVector2Array([tip, l, p + Vector2.from_angle(ang + PI) * r * 0.2, rr]), col)

# ------------------------------------------------------------------ waypoint panel (fast travel)
func toggle_panel() -> void:
	if _panel != null and _panel.visible:
		_close_panel()
		return
	var party: Variant = ex.level.get("party")
	if party == null or not bool(party.input_enabled) or bool(ex.level.get("burden_active")):
		return
	var rn: Variant = ex.level.get("runner")
	if rn != null and bool(rn.active):
		return
	_open_panel()

func _open_panel() -> void:
	if _panel == null:
		_panel = PanelContainer.new()
		_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.97), UiKit.PARCHMENT_DARK.darkened(0.35), 18, 4, 16))
		add_child(_panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		_panel.add_child(vb)
		vb.add_child(UiKit.label("WAYPOINTS", 30, UiKit.INK, "title"))
		vb.add_child(UiKit.label("Places you have found. Travel needs a quiet road.", 20, UiKit.MUTED, "dialogue"))
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(520, 300)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vb.add_child(sc)
		_list = VBoxContainer.new()
		_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_theme_constant_override("separation", 6)
		sc.add_child(_list)
		_msg = UiKit.label("", 20, UiKit.ACCENT, "bold")
		vb.add_child(_msg)
		var close := UiKit.button("Close", Vector2(160, 60), 26)
		close.pressed.connect(_close_panel)
		vb.add_child(close)
	for c in _list.get_children():
		c.queue_free()
	_msg.text = ""
	var lp: Vector3 = ex.level.get("party").get_leader().global_position
	for w in ex.waypoints():
		var why := ex.travel_reason(str(w["id"])) if bool(w["unlocked"]) else "Not found yet"
		var wp: Vector3 = w["pos"]
		var dist := int(Vector2(lp.x - wp.x, lp.z - wp.z).length())
		var b := UiKit.button("%s   %d m%s" % [w["name"], dist, ("" if why == "" else "  (%s)" % why)], Vector2(500, 56), 22)
		b.disabled = why != ""
		b.pressed.connect(_go.bind(str(w["id"])))
		_list.add_child(b)
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.visible = true
	_panel.reset_size()
	_layout()

func _go(id: String) -> void:
	_close_panel()
	var why := ex.travel(id)
	if why != "":
		Events.toast.emit(why, "warning")

func _close_panel() -> void:
	if _panel:
		_panel.visible = false
	get_tree().paused = _was_paused
