class_name SessionZero
extends CanvasLayer
## Session Zero v1: four tone sliders (combat / story / exploration / puzzle), set once at the start of
## a new game (and reachable again from the pause menu). The Director reads them (game/narrative/director.gd).

signal done

var _sliders: Dictionary = {}
var _desc: Dictionary = {}
var _from_pause := false

func _init(from_pause: bool = false) -> void:
	_from_pause = from_pause

func _ready() -> void:
	layer = 75
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.04, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	root.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	var t := UiKit.label("SESSION ZERO", 48, UiKit.PARCHMENT, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := UiKit.label("Before the Gate opens: how should this survey feel? You can change it later from the pause menu.", 22, UiKit.PARCHMENT.darkened(0.2), "dialogue")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.96), UiKit.PARCHMENT_DARK.darkened(0.35), 18, 4, 20))
	vb.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	panel.add_child(pv)
	for k in Director.KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		pv.add_child(row)
		var nm := UiKit.label(str(Director.LABELS[k][0]).to_upper(), 28, UiKit.ACCENT, "bold")
		nm.custom_minimum_size = Vector2(190, 0)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(nm)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 4
		s.step = 1
		s.tick_count = 5
		s.ticks_on_borders = true
		s.value = Director.tone(k)
		s.custom_minimum_size = Vector2(420, 64)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.focus_mode = Control.FOCUS_ALL
		s.add_theme_icon_override("grabber", UiKit._circle_icon(44, UiKit.ACCENT))
		s.add_theme_icon_override("grabber_highlight", UiKit._circle_icon(48, UiKit.ACCENT_2))
		s.add_theme_icon_override("grabber_disabled", UiKit._circle_icon(44, UiKit.MUTED))
		for sn in [["slider", UiKit.INK.lightened(0.3)], ["grabber_area", UiKit.ACCENT.darkened(0.2)], ["grabber_area_highlight", UiKit.ACCENT_2]]:
			var sb := UiKit.box(sn[1], Color(0, 0, 0, 0), 6, 0, 0)
			sb.content_margin_top = 7
			sb.content_margin_bottom = 7
			s.add_theme_stylebox_override(sn[0], sb)
		s.name = "Slider_" + k
		s.value_changed.connect(_on_changed.bind(k))
		row.add_child(s)
		_sliders[k] = s
		var d := UiKit.label("", 24, UiKit.INK, "dialogue")
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(d)
		_desc[k] = d
		_on_changed(s.value, k)
	var rule := UiKit.label("One rule: when the Reaches are winning, the Director gives you ADVANTAGE; when you are cruising, DISADVANTAGE. It always says so.", 20, UiKit.MUTED, "ui")
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(rule)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 20)
	vb.add_child(btns)
	var bd := UiKit.button("Balanced", Vector2(260, 80), 26)
	bd.pressed.connect(_defaults)
	bd.name = "Defaults"
	btns.add_child(bd)
	var go := UiKit.button("Begin" if not _from_pause else "Done", Vector2(320, 80), 30)
	go.pressed.connect(_finish)
	go.name = "Begin"
	btns.add_child(go)
	go.grab_focus.call_deferred()

func _on_changed(v: float, k: String) -> void:
	(_desc[k] as Label).text = Director.describe(k, int(v))
	Audio.sfx("ui_tap", -8.0)

func _defaults() -> void:
	for k in Director.KEYS:
		(_sliders[k] as HSlider).value = int(Director.DEFAULTS[k])

func _finish() -> void:
	for k in Director.KEYS:
		Director.set_tone(k, int((_sliders[k] as HSlider).value))
	Audio.sfx("ui_confirm")
	GameState.save_game()
	done.emit()
	queue_free()

## QA: set a tone then finish.
func qa_set(k: String, v: int) -> void:
	if _sliders.has(k):
		(_sliders[k] as HSlider).value = v
