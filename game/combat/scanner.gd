class_name Scanner
extends Node
## Handler Scan (GDD §6): 0.4 s slow-mo pulse; classification labels over every organism/object
## within 25 m: WILDLIFE · SAPIENT · SACRED · RESOURCE · DOMINION ASSET · STRUCTURE.
## First scan of a species unlocks its Codex entry and notifies the level (hints).
## Labels are drawn screen-space by ONE canvas item (few draw calls) and decluttered: same species
## within GROUP_RADIUS merge into "Name ×N", at most MAX_LABELS (nearest first), partners get one
## compact line, and overlapping labels are pushed apart vertically every frame.

const COLORS := {
	"WILDLIFE": Color("#8fd16a"), "SAPIENT": Color("#59d2e6"), "SACRED": Color("#f0c75a"),
	"RESOURCE": Color("#6fe0c0"), "DOMINION ASSET": Color("#ff5a45"), "STRUCTURE": Color("#e9dcc0"),
}
const POOL := 24
const MAX_LABELS := 8
const GROUP_RADIUS := 6.0
const FS_TAG := 15
const FS_NAME := 22
const FS_SUB := 16

var _entries: Array = []     # {target(Node3D|Vector3), off, tag, name, sub, compact, col, rect}
var _t := 0.0
var _cd := 0.0
var _highlighted: Array = []
var _layer: CanvasLayer
var _canvas: Control
var _font: Font
var _bg: StyleBoxFlat

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 15
	add_child(_layer)
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_labels)
	_layer.add_child(_canvas)
	_font = UiKit.font("bold")
	if _font == null:
		_font = ThemeDB.fallback_font
	_bg = UiKit.box(Color(0.06, 0.045, 0.04, 0.82), Color.WHITE, 8, 0, 6)
	_bg.border_width_left = 4

func scan(from: Node3D) -> void:
	if _cd > 0.0 or Field.current == null:
		return
	_cd = 0.8
	var f := Field.current
	var radius := Balance.f("global.scan_radius", 25.0)
	f.request_time_scale("scan", Balance.f("global.scan_slowmo_scale", 0.3), Balance.f("global.scan_slowmo_time", 0.4))
	f.vfx("scan_ping", from.global_position + Vector3(0, 0.3, 0), {"radius": radius})
	Audio.sfx("scan")
	Events.scan_started.emit()
	_clear()
	var origin := from.global_position
	var first_species: Array = []
	var cands: Array = []   # {target, off, tag, name, sub, compact, d, sp}
	for e in f.enemies:
		if not is_instance_valid(e) or not e.alive or e is VentWeakpoint:
			continue
		var d: float = e.global_position.distance_to(origin)
		if d > radius:
			continue
		var sp: String = e.species_id
		var info := Canon.species(sp)
		var tag: String = info.get("class", "DOMINION ASSET" if e.team == "enemy" and not e.wild else "WILDLIFE")
		if e is ResonancePylon:
			tag = "DOMINION ASSET"
		var line2 := ""
		if e is PlateBeetle:
			line2 = "agitated by pylons" if e.agitated else "calm"
		elif e is DustGrazer:
			line2 = "keystone · do not harm"
		elif e.wild:
			line2 = "containable <30%"
		elif tag == "DOMINION ASSET":
			line2 = "cannot be contained"
		cands.append({"target": e, "off": Vector3(0, e.height + 0.9, 0), "tag": tag, "name": str(e.display_name), "sub": line2, "compact": false, "d": d, "sp": sp + "|" + line2})
		e.vis("set_highlight", COLORS.get(tag, Color.WHITE), true)
		_highlighted.append(e)
		if sp != "" and Canon.species(sp).size() > 0:
			if GameState.unlock_codex("species_" + sp):
				first_species.append(sp)
	if f.level and f.level.has_method("get_scannables"):
		for sc in f.level.get_scannables():
			var p: Vector3 = sc["pos"]
			var d2 := p.distance_to(origin)
			if d2 > radius:
				continue
			cands.append({"target": p, "off": Vector3(0, float(sc.get("h", 2.5)), 0), "tag": sc["tag"], "name": sc["name"], "sub": sc.get("line2", ""), "compact": false, "d": d2, "sp": ""})
			if sc.has("codex"):
				GameState.unlock_codex(sc["codex"])
			if f.level.has_method("on_scanned_object"):
				f.level.on_scanned_object(sc.get("id", ""))
	# group same species (and same status) within GROUP_RADIUS into one label
	cands.sort_custom(func(x, y): return x["d"] < y["d"])
	var grouped: Array = []
	for c in cands:
		var merged := false
		if c["sp"] != "" and c["target"] is Node3D:
			for g in grouped:
				if g["sp"] == c["sp"] and g["target"] is Node3D and (g["target"] as Node3D).global_position.distance_to((c["target"] as Node3D).global_position) <= GROUP_RADIUS:
					g["count"] += 1
					merged = true
					break
		if not merged:
			c["count"] = 1
			grouped.append(c)
	for g in grouped:
		if _entries.size() >= MAX_LABELS:
			break
		if g["count"] > 1:
			g["name"] = "%s ×%d" % [g["name"], g["count"]]
		_add(g)
	# partners: always shown, one compact line
	for m in f.party_members:
		_add({"target": m, "off": Vector3(0, m.height + 0.6, 0), "tag": "SAPIENT", "name": "%s · partner · trust %d" % [m.display_name, GameState.get_trust(m.char_id)], "sub": "", "compact": true})
	_canvas.queue_redraw()
	_t = Balance.f("global.scan_label_time", 5.5)
	if f.level and f.level.has_method("on_scan"):
		f.level.on_scan(first_species)
	Events.scan_finished.emit()

func _add(c: Dictionary) -> void:
	c["col"] = COLORS.get(c["tag"], Color.WHITE)
	c["born"] = Time.get_ticks_msec()
	_entries.append(c)

func _anchor(c: Dictionary) -> Variant:
	var t: Variant = c["target"]
	if typeof(t) == TYPE_OBJECT:
		if not is_instance_valid(t) or ("alive" in t and not t.alive and not (t is PlayableCritter)):
			return null
		return (t as Node3D).global_position + c["off"]
	return (t as Vector3) + c["off"]

func _size(c: Dictionary) -> Vector2:
	if c["compact"]:
		return Vector2(_font.get_string_size(c["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SUB).x + 22, FS_SUB + 14)
	var w := _font.get_string_size(c["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_NAME).x
	w = maxf(w, _font.get_string_size(c["tag"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_TAG).x)
	var h := FS_TAG + FS_NAME + 16.0
	if c["sub"] != "":
		w = maxf(w, _font.get_string_size(c["sub"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SUB).x)
		h += FS_SUB + 2.0
	return Vector2(w + 22, h)

## Project, then resolve overlaps: walk labels top-to-bottom and push each one above anything it hits.
func _layout() -> Array:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return []
	var vs := _canvas.get_viewport_rect().size
	var vis: Array = []
	for c in _entries:
		var a: Variant = _anchor(c)
		if a == null or cam.is_position_behind(a):
			continue
		var sp := cam.unproject_position(a)
		if sp.x < -80 or sp.x > vs.x + 80 or sp.y < -40 or sp.y > vs.y + 80:
			continue
		var sz := _size(c)
		c["rect"] = Rect2(sp - Vector2(sz.x * 0.5, sz.y), sz)
		vis.append(c)
	vis.sort_custom(func(x, y): return x["rect"].position.y > y["rect"].position.y)
	var placed: Array = []
	for c in vis:
		var r: Rect2 = c["rect"]
		for _k in 8:
			var hit := false
			for pr in placed:
				if r.grow(2.0).intersects(pr):
					r.position.y = pr.position.y - r.size.y - 4.0
					hit = true
			if not hit:
				break
		r.position.x = clampf(r.position.x, 6.0, vs.x - r.size.x - 6.0)
		r.position.y = clampf(r.position.y, 96.0, vs.y - r.size.y - 6.0)
		c["rect"] = r
		placed.append(r)
	return vis

func _draw_labels() -> void:
	if _t <= 0.0 or _entries.is_empty():
		return
	var vis := _layout()
	var now := Time.get_ticks_msec()
	var fade := clampf(_t / 0.6, 0.0, 1.0)
	# pass 1: all panels (untextured → one batch); pass 2..4: text grouped by size (one atlas each)
	for c in vis:
		var pop := clampf(float(now - int(c["born"])) / 160.0, 0.0, 1.0)
		var r: Rect2 = c["rect"]
		_bg.border_color = c["col"]
		_bg.bg_color.a = 0.82 * fade
		_canvas.draw_style_box(_bg, r.grow(-3.0 * (1.0 - pop)))
	for c in vis:
		var r: Rect2 = c["rect"]
		if not c["compact"]:
			_canvas.draw_string(_font, r.position + Vector2(12, 6 + FS_TAG), c["tag"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_TAG, Color(c["col"], fade))
	for c in vis:
		var r: Rect2 = c["rect"]
		if not c["compact"]:
			_canvas.draw_string(_font, r.position + Vector2(12, 8 + FS_TAG + FS_NAME), c["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_NAME, Color(UiKit.PARCHMENT, fade))
	for c in vis:
		var r: Rect2 = c["rect"]
		if c["compact"]:
			_canvas.draw_string(_font, r.position + Vector2(12, 4 + FS_SUB), c["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SUB, Color(c["col"], fade))
		elif c["sub"] != "":
			_canvas.draw_string(_font, r.position + Vector2(12, 10 + FS_TAG + FS_NAME + FS_SUB), c["sub"], HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SUB, Color(UiKit.PARCHMENT.darkened(0.25), fade))

func _process(delta: float) -> void:
	_cd = maxf(0.0, _cd - delta)
	if _t <= 0.0:
		return
	_t -= delta
	_canvas.queue_redraw()
	if _t <= 0.0:
		_clear()

func _clear() -> void:
	_entries.clear()
	_t = 0.0
	if _canvas:
		_canvas.queue_redraw()
	for e in _highlighted:
		if is_instance_valid(e) and e.alive:
			e.vis("set_highlight", Color.WHITE, false)
	_highlighted.clear()

## QA / tests: how many labels are currently shown.
func label_count() -> int:
	return _entries.size()
