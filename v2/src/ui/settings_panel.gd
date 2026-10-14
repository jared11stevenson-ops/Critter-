class_name SettingsPanel extends Control
## Settings overlay (from the title / pause): touch layout A buttons vs B gestures (so the creator can compare on the phone),
## on-screen controls, left-handed mirroring, quality, fps cap, flashing, perf overlay and the Performance report.
## Core options go through the Settings autoload; UI-only options (layout, touch mode) through UiPrefs.

signal closed

func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.02, 0.03, 0.8)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()                                       # more options than a 720p screen holds: scroll instead of clipping
	sc.custom_minimum_size = Vector2(800, minf(get_viewport_rect().size.y - 40.0, 800.0))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	sc.add_child(v)
	var t := UiStyle.label("SETTINGS", 46, UiStyle.GOLD, 12)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UiStyle.segment_row("CONTROLS", [["A", "A: Buttons"], ["B", "B: Gestures"]], str(UiPrefs.get_pref("layout")), func(k): UiPrefs.set_pref("layout", k), 190, 190))
	v.add_child(UiStyle.segment_row("TOUCH UI", [["auto", "Auto"], ["on", "Always on"], ["off", "Off"]], str(UiPrefs.get_pref("touch")), func(k): UiPrefs.set_pref("touch", k), 190, 190))
	v.add_child(UiStyle.segment_row("HANDED", [["r", "Right"], ["l", "Left"]], "l" if Settings.get_value("left_handed") else "r", func(k): Settings.set_value("left_handed", k == "l"); Settings.save(), 190, 190))
	v.add_child(UiStyle.segment_row("QUALITY", [["0", "Low"], ["1", "Medium"], ["2", "High"]], str(Settings.get_value("quality")), func(k): Settings.set_value("quality", int(k)); Settings.save(), 190, 190))
	var mv := float(Settings.get_value("music_volume"))
	var mk := "0" if mv < 0.05 else ("1" if mv < 0.4 else ("2" if mv < 0.65 else "3"))
	v.add_child(UiStyle.segment_row("MUSIC", [["0", "Off"], ["1", "Low"], ["2", "Medium"], ["3", "High"]], mk, func(k): Settings.set_value("music_volume", [0.0, 0.25, 0.5, 0.8][int(k)]); Settings.save(); Music.refresh(), 130, 190))
	v.add_child(UiStyle.segment_row("SOUND", [["h", "Half"], ["f", "Full"]], "f" if float(Settings.get_value("master_volume")) > 0.75 else "h", func(k): Settings.set_value("master_volume", 1.0 if k == "f" else 0.5); Settings.save(); Music.refresh(), 190, 190))
	v.add_child(UiStyle.segment_row("HAPTICS", [["on", "On"], ["off", "Off"]], "on" if Settings.get_value("haptics") else "off", func(k): Settings.set_value("haptics", k == "on"); Settings.save(), 190, 190))
	v.add_child(UiStyle.segment_row("PARRY ASSIST", [["off", "Off"], ["on", "Wider (Practice)"]], "on" if Settings.get_value("assist_wide_parry") else "off", func(k): Settings.set_value("assist_wide_parry", k == "on"); Settings.save(), 190, 270))
	v.add_child(UiStyle.segment_row("FPS CAP", [["30", "30"], ["60", "60"], ["90", "90"], ["120", "120"]], str(Settings.get_value("fps_cap")), func(k): Settings.set_value("fps_cap", int(k)); Settings.apply(); Settings.save(), 130, 190))
	v.add_child(UiStyle.segment_row("FLASHING", [["f", "Normal"], ["r", "Reduced"]], "r" if Settings.get_value("reduce_flashing") else "f", func(k): Settings.set_value("reduce_flashing", k == "r"); Settings.save(), 190, 190))
	v.add_child(UiStyle.segment_row("PERF HUD", [["off", "Off"], ["on", "On"]], "on" if Settings.get_value("perf_overlay") else "off", func(k): Perf.set_overlay(k == "on"); Settings.save(), 190, 190))
	var kb := UiStyle.label("Keyboard: WASD move  J strike (hold = heavy)  K guard  Space dodge  L grab  U / I abilities  U+I last stand  Y yield  P pause", 16, UiStyle.PAPER_DK, 4)
	kb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kb.custom_minimum_size = Vector2(760, 0)
	v.add_child(kb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var pr := UiStyle.button("Performance report", 28, Vector2(380, 84), UiStyle.TEAL)
	pr.pressed.connect(func(): Perf.open_report())
	row.add_child(pr)
	var cl := UiStyle.button("Done", 34, Vector2(240, 84))
	cl.pressed.connect(func(): closed.emit(); queue_free())
	row.add_child(cl)

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		closed.emit()
		queue_free()
		get_viewport().set_input_as_handled()
