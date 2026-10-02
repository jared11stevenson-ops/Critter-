class_name SettingsPanel
extends Control
## Settings: music/sfx volume, screen shake, damage numbers, left-handed layout, reduce flashing.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := UiKit.label("SETTINGS", 44, UiKit.INK, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_slider(vb, "Music volume", "music_volume")
	_slider(vb, "Sound effects", "sfx_volume")
	_slider(vb, "Screen shake", "screen_shake")
	_toggle(vb, "Damage numbers", "show_damage_numbers")
	_toggle(vb, "Left-handed layout", "left_handed")
	_toggle(vb, "Reduce flashing", "reduce_flashing")
	var back := UiKit.button("Back", Vector2(300, 88))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	vb.add_child(back)
	back.grab_focus.call_deferred()
	_center.call_deferred(panel)

func _center(panel: Control) -> void:
	var vs := get_viewport_rect().size
	panel.reset_size()
	panel.position = (vs - panel.size) * 0.5

func _row(vb: Node, text: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 88)
	var l := UiKit.label(text, 28, UiKit.INK, "ui")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	vb.add_child(hb)
	return hb

func _slider(vb: Node, text: String, key: String) -> void:
	var hb := _row(vb, text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(GameState.settings.get(key, 1.0))
	s.custom_minimum_size = Vector2(320, 88)
	s.value_changed.connect(func(v): _apply_setting(key, v))
	hb.add_child(s)

func _toggle(vb: Node, text: String, key: String) -> void:
	var hb := _row(vb, text)
	var b := UiKit.button("", Vector2(160, 80), 26)
	b.toggle_mode = true
	b.button_pressed = bool(GameState.settings.get(key, false))
	b.text = "ON" if b.button_pressed else "OFF"
	b.toggled.connect(_on_toggle.bind(b, key))
	hb.add_child(b)

func _on_toggle(on: bool, b: Button, key: String) -> void:
	b.text = "ON" if on else "OFF"
	_apply_setting(key, on)

func _apply_setting(key: String, v: Variant) -> void:
	GameState.settings[key] = v
	Audio.refresh_volumes()
	if key == "sfx_volume":
		Audio.sfx("ui_tap")
	# re-layout HUD for handedness
	for h in get_tree().get_nodes_in_group("hud"):
		h.set("_layout_dirty", true)

func _close() -> void:
	GameState.save_game()
	Audio.sfx("ui_back")
	queue_free()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
