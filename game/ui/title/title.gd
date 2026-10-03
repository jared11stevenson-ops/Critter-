extends Control
## Title screen: key art (if Agent 1 delivered it), CRITTER wordmark, New Game / Continue / Settings / Credits.

const HUB := "res://game/world/hub/hub.tscn"
const RR := "res://game/world/red_reaches/red_reaches.tscn"

var _menu: VBoxContainer
var _confirm: Control = null
var _sub: Control = null
var _t := 0.0
var _motes: Array = []
var _bg: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	TouchInput.reset()
	get_tree().paused = false
	Engine.time_scale = 1.0
	_build_background()
	var shade := TextureRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	var g := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.07, 0.04, 0.03, 0.85))
	grad.set_color(1, Color(0.07, 0.04, 0.03, 0.0))
	g.gradient = grad
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0.62, 0)
	shade.texture = g
	add_child(shade)
	var left := VBoxContainer.new()
	left.position = Vector2(72, 150)
	left.add_theme_constant_override("separation", 6)
	add_child(left)
	var title := UiKit.label("CRITTER", 128, UiKit.PARCHMENT, "title", 18, Color(0.1, 0.05, 0.04, 0.95))
	left.add_child(title)
	var sub := UiKit.label("THE RED SPAN SURVEY", 34, UiKit.ACCENT_2, "solemn", 8, Color(0.1, 0.05, 0.04, 0.9))
	left.add_child(sub)
	var tag := UiKit.label("A Handler's first descent into the Red Reaches", 26, UiKit.PARCHMENT.darkened(0.1), "dialogue", 6, Color(0.1, 0.05, 0.04, 0.8))
	left.add_child(tag)
	# Menu column on the right, vertically centred: four 88 px targets never run off a 720p screen.
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_menu.anchor_left = 1.0
	_menu.anchor_right = 1.0
	_menu.anchor_top = 0.5
	_menu.anchor_bottom = 0.5
	_menu.offset_left = -460
	_menu.offset_right = -80
	_menu.offset_top = -200
	_menu.offset_bottom = 200
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_menu)
	var has_progress := GameState.has_save() and (GameState.flags.size() > 0)
	var cont := UiKit.button("Continue", Vector2(380, 88), 32)
	cont.disabled = not has_progress
	cont.pressed.connect(_continue)
	cont.name = "Continue"
	_menu.add_child(cont)
	var ng := UiKit.button("New Game", Vector2(380, 88), 32)
	ng.pressed.connect(_new_game)
	ng.name = "NewGame"
	_menu.add_child(ng)
	var st := UiKit.button("Settings", Vector2(380, 88), 32)
	st.pressed.connect(_settings)
	st.name = "Settings"
	_menu.add_child(st)
	var cr := UiKit.button("Credits", Vector2(380, 88), 32)
	cr.pressed.connect(_credits)
	cr.name = "Credits"
	_menu.add_child(cr)
	(cont if has_progress else ng).grab_focus.call_deferred()
	var ver := UiKit.label("v%s · vertical slice" % str(ProjectSettings.get_setting("application/config/version", "0.0.0")), 22, UiKit.PARCHMENT.darkened(0.3), "ui")
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.position = Vector2(72, -48)
	ver.offset_top = -48
	add_child(ver)
	Audio.music("title")

func _build_background() -> void:
	_bg = Control.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	var art := _find_key_art()
	if art:
		var tr := TextureRect.new()
		tr.texture = art
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg.add_child(tr)
		return
	# Painted-sky fallback: Red Reaches dusk gradient + mesa silhouettes + ringed planet + drifting motes
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	var g := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color("#3b2a44"), Color("#c8462b"), Color("#e9b46a")])
	g.gradient = grad
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0, 1)
	sky.texture = g
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(sky)
	_bg.draw.connect(_draw_bg)
	for i in 40:
		_motes.append(Vector3(randf(), randf(), randf_range(0.3, 1.0)))

func _find_key_art() -> Texture2D:
	var d := DirAccess.open("res://game/art/ui")
	if d == null:
		return null
	for f in d.get_files():
		var fn := f.trim_suffix(".import").trim_suffix(".remap")
		if fn.begins_with("key_art") and fn.ends_with(".png"):
			var t := UiKit.tex("res://game/art/ui/" + fn)
			if t:
				return t
	return null

func _draw_bg() -> void:
	var s := _bg.size
	# ringed planet
	var pc := Vector2(s.x * 0.74, s.y * 0.26)
	_bg.draw_circle(pc, 92, Color("#e9dcc0").darkened(0.15))
	_bg.draw_circle(pc + Vector2(-18, -12), 86, Color("#f3e6c8"))
	_bg.draw_arc(pc, 150, deg_to_rad(-12), deg_to_rad(192), 64, Color(0.95, 0.85, 0.7, 0.75), 6.0, true)
	# far mesas
	var far := PackedVector2Array([Vector2(0, s.y * 0.68), Vector2(s.x * 0.12, s.y * 0.6), Vector2(s.x * 0.2, s.y * 0.6), Vector2(s.x * 0.26, s.y * 0.66), Vector2(s.x * 0.48, s.y * 0.64), Vector2(s.x * 0.55, s.y * 0.55), Vector2(s.x * 0.7, s.y * 0.55), Vector2(s.x * 0.76, s.y * 0.63), Vector2(s.x, s.y * 0.6), Vector2(s.x, s.y), Vector2(0, s.y)])
	_bg.draw_colored_polygon(far, Color("#9c3f25"))
	var near := PackedVector2Array([Vector2(0, s.y * 0.82), Vector2(s.x * 0.3, s.y * 0.8), Vector2(s.x * 0.36, s.y * 0.72), Vector2(s.x * 0.62, s.y * 0.72), Vector2(s.x * 0.68, s.y * 0.8), Vector2(s.x, s.y * 0.78), Vector2(s.x, s.y), Vector2(0, s.y)])
	_bg.draw_colored_polygon(near, Color("#5a2416"))
	# the Ochre Span across the gap
	_bg.draw_rect(Rect2(s.x * 0.36, s.y * 0.715, s.x * 0.26, 10), Color("#d9a06a"))
	for k in 4:
		_bg.draw_rect(Rect2(s.x * (0.38 + k * 0.065), s.y * 0.725, 8, s.y * 0.2), Color("#b07a4a"))
	for m in _motes:
		var p := Vector2(fmod(m.x * s.x + _t * 14.0 * m.z, s.x), fmod(m.y * s.y - _t * 9.0 * m.z + s.y, s.y))
		_bg.draw_circle(p, 2.0 * m.z, Color(1, 0.9, 0.7, 0.35 * m.z))

func _process(delta: float) -> void:
	_t += delta
	if _bg:
		_bg.queue_redraw()

func _new_game() -> void:
	Audio.sfx("ui_confirm")
	if GameState.has_save() and GameState.flags.size() > 0 and _confirm == null:
		_confirm = _dialog("Start a new survey? Your current progress will be overwritten.", "Start New", _really_new)
		return
	_really_new()

func _really_new() -> void:
	GameState.new_game()
	Router.goto(HUB, "fade")

func _continue() -> void:
	Audio.sfx("ui_confirm")
	var sc := str(GameState.get_flag("_scene", "hub"))
	if sc == "red_reaches" and not bool(GameState.get_flag("rr_complete", false)):
		Router.goto(RR, "gate")
	else:
		Router.goto(HUB, "fade")

func _settings() -> void:
	Audio.sfx("ui_confirm")
	_sub = SettingsPanel.new()
	add_child(_sub)

func _credits() -> void:
	Audio.sfx("ui_confirm")
	var txt := "CRITTER — The Red Span Survey\n\nWorld, lore bible, characters and concept art: the CRITTER creator.\n\nEngine: Godot Engine 4 (MIT).\nFonts (SIL OFL 1.1): Permanent Marker — Font Diner · Kalam — Indian Type Foundry · Barlow Condensed — Jeremy Tribby · Cinzel — Natanael Gama."
	_confirm = _dialog(txt, "", Callable())

func _dialog(text: String, ok_text: String, ok: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(720, 0)
	root.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	pc.add_child(vb)
	var l := UiKit.label(text, 26, UiKit.INK, "dialogue")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(660, 0)
	vb.add_child(l)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	if ok_text != "":
		var b := UiKit.button(ok_text, Vector2(260, 88))
		b.pressed.connect(_on_ok.bind(ok))
		hb.add_child(b)
	var c := UiKit.button("Back" if ok_text == "" else "Cancel", Vector2(220, 88))
	c.pressed.connect(_close_dialog)
	hb.add_child(c)
	c.grab_focus.call_deferred()
	_center_panel.call_deferred(pc)
	return root

func _center_panel(pc: Control) -> void:
	pc.reset_size()
	pc.position = (get_viewport_rect().size - pc.size) * 0.5

func _on_ok(ok: Callable) -> void:
	_close_dialog()
	if ok.is_valid():
		ok.call()

func _close_dialog() -> void:
	Audio.sfx("ui_back")
	if _confirm:
		_confirm.queue_free()
		_confirm = null

# ---------------- QA ----------------
func qa_press(button_name: String) -> void:
	var b := find_child(button_name, true, false) as Button
	if b and not b.disabled:
		b.pressed.emit()
	else:
		push_warning("[QA] title button %s missing/disabled" % button_name)

func qa_close_overlays() -> void:
	if _sub and is_instance_valid(_sub):
		_sub.queue_free()
		_sub = null
	if _confirm:
		_confirm.queue_free()
		_confirm = null
