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
var _title := ""
var _panel: PanelContainer
var _list: VBoxContainer
var _msg: Label
var _redraw_t := 0.0
var _was_paused := false
## The charted ground is baked once into one texture (2 px per metre) and drawn as a single rect: the minimap costs a
## handful of canvas draws no matter how much of the Reaches is charted.
const PX_M := 2.0
const BG := Color(0.10, 0.07, 0.06, 0.62)
const MAP_X0 := -90.0
const MAP_Z0 := -120.0
const MAP_W := 500.0                  # metres covered by the texture (padded so the view never leaves it)
const MAP_H := 240.0

var _chart: Image
var _chart_tex: ImageTexture
var _baked: Dictionary = {}           # floor id -> true
var _bake_q: Array = []               # floors still to rasterise (one per frame)
var _dot: Texture2D                   # tiny shared textures so every marker is the same draw state
var _dia: Texture2D

func setup(explore: RrExplore) -> void:
	ex = explore

func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	_chart = Image.create(int(MAP_W * PX_M), int(MAP_H * PX_M), false, Image.FORMAT_RGBA8)
	_chart.fill(BG)                       # the panel background lives in the texture: one draw for both
	_chart_tex = ImageTexture.create_from_image(_chart)
	_dot = _make_tex(false)
	_dia = _make_tex(true)
	_map = Control.new()
	_map.name = "Map"
	_map.custom_minimum_size = Vector2(SIZE, SIZE + 22.0)
	_map.size = Vector2(SIZE, SIZE + 22.0)
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_on_map_input)
	add_child(_map)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var lh := bool(GameState.settings.get("left_handed", false))
	var pos := Vector2(18.0, 150.0) if lh else Vector2(vs.x - 18.0 - SIZE, 128.0)
	_map.position = pos
	if _panel:
		_panel.position = (vs - _panel.size) * 0.5

func _process(delta: float) -> void:
	if ex == null or ex.level == null:
		return
	var party: Variant = ex.level.get("party")
	if party == null or party.get_leader() == null:
		return
	_bake_step()
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
		_title = "%d/%d places" % [ex.found_count(), ex.pois.size()]
		return
	var d := Vector2(g.x - lp.x, g.z - lp.z)
	_title = "Next: %d m %s  ·  %d/%d" % [int(d.length()), ExploreRules.compass_word(d.x, d.y), ex.found_count(), ex.pois.size()]

# ------------------------------------------------------------------ chart texture
static func _make_tex(diamond: bool) -> Texture2D:
	var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var dx := float(x) - 7.5
			var dy := float(y) - 7.5
			var inside := (absf(dx) + absf(dy) <= 7.5) if diamond else (dx * dx + dy * dy <= 56.0)
			im.set_pixel(x, y, Color.WHITE if inside else Color(1, 1, 1, 0))
	return ImageTexture.create_from_image(im)

## Queue every charted floor that is not on the texture yet; rasterise one per frame (no load-time hitch).
func _bake_step() -> void:
	if _bake_q.is_empty():
		for f in ex.floors:
			if ex.floor_seen(f) and not _baked.has(f["id"]):
				_baked[f["id"]] = true
				_bake_q.append(f)
		if _bake_q.is_empty():
			return
	_bake_floor(_bake_q.pop_front())
	_chart_tex.update(_chart)

func _bake_floor(f: Dictionary) -> void:
	var poly := ExploreRules.shape_poly(f, 24)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var col := Color(0.70, 0.43, 0.28, 0.78)
	var x0 := maxi(0, int((lo.x - MAP_X0) * PX_M))
	var x1 := mini(_chart.get_width() - 1, int((hi.x - MAP_X0) * PX_M))
	var y0 := maxi(0, int((lo.y - MAP_Z0) * PX_M))
	var y1 := mini(_chart.get_height() - 1, int((hi.y - MAP_Z0) * PX_M))
	for py in range(y0, y1 + 1):
		var wz := MAP_Z0 + (float(py) + 0.5) / PX_M
		for px in range(x0, x1 + 1):
			if ExploreRules.shape_dist(f, MAP_X0 + (float(px) + 0.5) / PX_M, wz) <= 0.0:
				_chart.set_pixel(px, py, col)

# ------------------------------------------------------------------ drawing
func _w2m(p: Vector3, c: Vector3) -> Vector2:
	return Vector2(SIZE, SIZE) * 0.5 + ExploreRules.to_map(p.x - c.x, p.z - c.z, SIZE * 0.5 / RANGE_M)

func _mark(tex: Texture2D, p: Vector2, r: float, col: Color) -> void:
	_map.draw_texture_rect(tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)

func _draw_map() -> void:
	var party: Variant = ex.level.get("party")
	if party == null or party.get_leader() == null:
		return
	var lead: PlayableCritter = party.get_leader()
	var c: Vector3 = lead.global_position
	var half := SIZE * 0.5
	var inner := half - 6.0
	# charted ground: one textured rect cut out of the baked chart around the player
	var src_c := Vector2((c.x - MAP_X0) * PX_M, (c.z - MAP_Z0) * PX_M)
	var src_h := RANGE_M * PX_M
	_map.draw_texture_rect_region(_chart_tex, Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Rect2(src_c - Vector2(src_h, src_h), Vector2(src_h, src_h) * 2.0))
	# secrets: a quiet pulse, only when close
	var pulse := fmod(Time.get_ticks_msec() * 0.001, 1.6) / 1.6
	for h in ex.hot_secrets(c):
		_map.draw_arc(_w2m(h["pos"], c), 6.0 + 14.0 * pulse, 0.0, TAU, 16, Color(UiKit.SCAN, 1.0 - pulse), 2.0)
	# places (only those inside the view are drawn; undiscovered ones nearby as an edge chevron)
	var sense := float(ex.data.get("sense_r", 70.0))
	for p in ex.pois:
		var pp: Vector3 = p["pos"]
		var off := _w2m(pp, c)
		var d := Vector2(pp.x - c.x, pp.z - c.z).length()
		var inside := absf(off.x - half) < inner and absf(off.y - half) < inner
		if ex.is_discovered(p):
			if inside:
				_mark(_dia, off, 5.0, UiKit.SCAN if p.has("wp") else UiKit.PARCHMENT)
		elif d <= sense:
			if inside:
				_mark(_dia, off, 3.5, Color(UiKit.PARCHMENT, 0.35))
			else:
				_mark(_dia, Vector2(half, half) + ExploreRules.clamp_to_edge(off - Vector2(half, half), inner), 3.0, Color(UiKit.PARCHMENT, 0.4))
	# hostiles near you (red = awake, dim = asleep)
	var f: Variant = ex.level.get("field")
	if f != null:
		for e in f.enemies:
			if is_instance_valid(e) and e.get("team") == "enemy" and e.get("alive") != false and (e.get("aggro") == true or e.global_position.distance_squared_to(c) < 900.0):
				var eo := _w2m(e.global_position, c)
				if absf(eo.x - half) < inner and absf(eo.y - half) < inner:
					_mark(_dot, eo, 2.6, Color(0.9, 0.25, 0.2, 0.95 if e.get("aggro") == true else 0.45))
	var pt: PlayableCritter = party.get_partner()
	if pt:
		_mark(_dot, _w2m(pt.global_position, c), 3.0, Color(UiKit.PSI, 0.9))
	# story guide: gold marker, on the edge when it is off the map
	var g := ex.guide_target()
	if g.x != INF:
		var go := _w2m(g, c)
		var gp := Vector2(half, half) + ExploreRules.clamp_to_edge(go - Vector2(half, half), inner)
		_mark(_dia, gp, 6.5, Color(1.0, 0.82, 0.30, 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.006)))
	# player
	_mark(_dia, Vector2(half, half), 5.0, Color.WHITE)
	_map.draw_rect(Rect2(0.0, SIZE, SIZE, 22.0), Color(0.10, 0.07, 0.06, 0.8))
	_map.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE + 22.0)), Color(UiKit.PARCHMENT_DARK, 0.9), false, 2.0)
	_map.draw_string(UiKit.font("bold"), Vector2(4.0, SIZE + 16.0), _title, HORIZONTAL_ALIGNMENT_CENTER, SIZE - 8.0, 15, UiKit.PARCHMENT)

# ------------------------------------------------------------------ waypoint panel (fast travel)
func toggle_panel() -> void:
	if _panel != null and _panel.visible:
		_close_panel()
		return
	if get_tree().paused:
		return                        # pause menu / dialogue / another overlay owns the screen
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
