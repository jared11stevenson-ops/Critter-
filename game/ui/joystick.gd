class_name FloatingJoystick
extends Control
## Floating left-thumb joystick: appears where the thumb lands inside its zone, writes TouchInput.move.

var radius := 96.0
var _touch := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _idle_pos := Vector2(190, 560)
var zone := Rect2(0, 160, 600, 560)   # set by HUD (mirrored for left-handed)
var _base_tex: Texture2D
var _knob_tex: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_base_tex = UiKit.tex("res://game/art/ui/joystick_base.png")
	_knob_tex = UiKit.tex("res://game/art/ui/joystick_knob.png")

func set_idle(p: Vector2) -> void:
	_idle_pos = p
	queue_redraw()

func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		if _touch != -1:
			_end()
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed and _touch == -1 and zone.has_point(t.position):
			_touch = t.index
			_origin = t.position
			_knob = Vector2.ZERO
			TouchInput.active = true
			queue_redraw()
		elif not t.pressed and t.index == _touch:
			_end()
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _touch:
			var v := d.position - _origin
			if v.length() > radius * 1.6:
				_origin = d.position - v.normalized() * radius * 1.6
				v = d.position - _origin
			_knob = v.limit_length(radius)
			var m := _knob / radius
			if m.length() < 0.12:
				m = Vector2.ZERO
			TouchInput.move = m
			queue_redraw()

func _end() -> void:
	_touch = -1
	_knob = Vector2.ZERO
	TouchInput.move = Vector2.ZERO
	TouchInput.active = false
	queue_redraw()

func _draw() -> void:
	var c := _origin if _touch != -1 else _idle_pos
	var a := 0.9 if _touch != -1 else 0.35
	if _base_tex:
		draw_texture_rect(_base_tex, Rect2(c - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(1, 1, 1, a))
	else:
		draw_circle(c, radius, Color(0.1, 0.07, 0.06, 0.35 * a))
		draw_arc(c, radius, 0, TAU, 48, Color(0.91, 0.86, 0.75, 0.7 * a), 4.0, true)
	var k := c + _knob
	if _knob_tex:
		draw_texture_rect(_knob_tex, Rect2(k - Vector2(44, 44), Vector2(88, 88)), false, Color(1, 1, 1, a + 0.1))
	else:
		draw_circle(k, 44, Color(0.78, 0.27, 0.17, 0.85 * a + 0.1))
		draw_arc(k, 44, 0, TAU, 32, Color(0.91, 0.86, 0.75, a), 3.0, true)
