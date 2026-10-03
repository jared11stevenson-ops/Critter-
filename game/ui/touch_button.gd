class_name TouchButton
extends Control
## Multitouch-safe round button (each finger tracked by index). Presses an InputMap action so
## gameplay code reads one input path for touch, keyboard, gamepad and QA scripts.
## Draws: disc, icon or glyph, cooldown sweep, cost tint, caption.

signal tapped

var always_active := false   # receive input while the tree is paused
var action := ""
var glyph := ""
var caption := ""
var icon: Texture2D = null
var base_col := UiKit.CARD
var ring_col := UiKit.ACCENT
var cd_frac := 0.0
var cost_tint := Color(0, 0, 0, 0)
var enabled := true
var pill := false           # rounded rectangle instead of disc
var glyph_size := 26
var _touch := -1
var _pressed := false
var _pulse := 0.0
var _font: Font
var _tex_up: Texture2D
var _tex_down: Texture2D

func _init(act: String = "", diameter: float = 100.0, g: String = "") -> void:
	action = act
	glyph = g
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_font = UiKit.font("bold")
	_tex_up = UiKit.tex("res://game/art/ui/button_round.png")
	_tex_down = UiKit.tex("res://game/art/ui/button_round_pressed.png")

func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree() or (get_tree().paused and not always_active):
		if _pressed:
			_release()
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed and _touch == -1 and _hit(t.position):
			_touch = t.index
			_press()
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _touch:
			_release()
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _touch and not _hit(d.position, 40.0):
			_release()

func _hit(p: Vector2, slack: float = 8.0) -> bool:
	var r := get_global_rect().grow(slack)
	if not r.has_point(p):
		return false
	if pill:
		return true
	var c := r.get_center()
	return c.distance_to(p) <= size.x * 0.5 + slack

func _press() -> void:
	_pressed = true
	_pulse = 1.0
	if action != "" and enabled:
		Input.action_press(action)
	tapped.emit()
	queue_redraw()

func _release() -> void:
	_touch = -1
	if _pressed and action != "":
		Input.action_release(action)
	_pressed = false
	queue_redraw()

func is_held() -> bool:
	return _pressed

func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 5.0)
		queue_redraw()

func set_state(cd: float, tint: Color, en: bool) -> void:
	if absf(cd - cd_frac) > 0.004 or tint != cost_tint or en != enabled:
		cd_frac = cd
		cost_tint = tint
		enabled = en
		queue_redraw()

func _draw() -> void:
	var s := size
	var c := s * 0.5
	var r := minf(s.x, s.y) * 0.5
	var scale_k := 0.94 if _pressed else 1.0
	var col := base_col
	if not enabled:
		col = col.darkened(0.4)
	if pill:
		var sb := UiKit.box(col.lerp(UiKit.ACCENT, 0.25 if _pressed else 0.0), ring_col, int(s.y * 0.5), 4)
		draw_style_box(sb, Rect2(Vector2.ZERO, s))
	else:
		var tex := _tex_down if _pressed and _tex_down else _tex_up
		if tex:
			draw_texture_rect(tex, Rect2(c - Vector2(r, r) * scale_k, Vector2(r, r) * 2.0 * scale_k), false, col.lightened(0.6))
		else:
			draw_circle(c, r * scale_k, Color(0, 0, 0, 0.35))
			draw_circle(c, (r - 3.0) * scale_k, col.lerp(UiKit.ACCENT, 0.3 if _pressed else 0.0))
			draw_arc(c, (r - 3.0) * scale_k, 0, TAU, 48, ring_col if enabled else UiKit.MUTED, 4.0, true)
		if cost_tint.a > 0.0:
			draw_arc(c, (r - 9.0) * scale_k, 0, TAU, 48, cost_tint, 5.0, true)
	if icon:
		var isz := r * 1.25 * scale_k
		draw_texture_rect(icon, Rect2(c - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false, Color(1, 1, 1, 1 if enabled else 0.5))
	elif glyph != "" and _font:
		var fs := glyph_size
		var w := _font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string_outline(_font, Vector2(c.x - w * 0.5, c.y + fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.7))
		draw_string(_font, Vector2(c.x - w * 0.5, c.y + fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.PARCHMENT if enabled else UiKit.MUTED)
	if cd_frac > 0.001 and not pill:
		var pts := PackedVector2Array()
		pts.append(c)
		var seg := 32
		var start := -PI * 0.5
		for i in seg + 1:
			var a := start + TAU * cd_frac * float(i) / float(seg)
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 4.0) * scale_k)
		draw_colored_polygon(pts, Color(0.05, 0.03, 0.03, 0.62))
	if caption != "" and _font:
		var fs2 := 22
		var w2 := _font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x
		var y := s.y + 22.0
		if pill:
			y = c.y + fs2 * 0.36
		draw_string_outline(_font, Vector2(c.x - w2 * 0.5, y), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, 6, Color(0, 0, 0, 0.75))
		draw_string(_font, Vector2(c.x - w2 * 0.5, y), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, UiKit.PARCHMENT)
	if _pulse > 0.0 and not bool(GameState.settings.get("reduce_flashing", false)):
		draw_arc(c, r + (1.0 - _pulse) * 16.0, 0, TAU, 40, Color(1, 0.9, 0.7, _pulse * 0.8), 3.0, true)
