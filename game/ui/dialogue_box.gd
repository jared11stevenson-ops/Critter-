class_name DialogueBox
extends Control
## Dialogue view: portrait (left for the party, right for others), speaker name in Permanent Marker,
## text in Kalam with typewriter (tap to complete, tap again to advance), big choice buttons,
## comms-styled variant for "comms:<id>", narration and handler styles.

const CPS := 52.0
const PARTY := ["aruun", "cigarra"]

var runner: DialogueRunner
var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _portrait_l: Control
var _portrait_r: Control
var _next: Label
var _choices_box: VBoxContainer
var _typing := false
var _shown := 0.0
var _total := 0
var _blink := 0.0
var _line: Dictionary = {}
var _comms_tag: Label
var _input_cool := 0.0
var _last_n := 0
var _pcache: Dictionary = {}   # holder id -> {portrait key -> Control}

func bind(r: DialogueRunner) -> void:
	runner = r
	r.line_shown.connect(_on_line)
	r.choices_shown.connect(_on_choices)
	r.finished.connect(_on_finished)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	visible = false
	# dim backdrop that also catches taps
	var catcher := Control.new()   # input catcher only: no full-screen blended quad to fill every frame
	catcher.name = "Catcher"
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_catcher_input)
	add_child(catcher)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 40
	_panel.offset_right = -40
	_panel.offset_top = -232
	_panel.offset_bottom = -22
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_catcher_input)
	add_child(_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hb)
	_portrait_l = Control.new()
	_portrait_l.custom_minimum_size = Vector2(170, 170)
	_portrait_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_portrait_l)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	hb.add_child(vb)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(name_row)
	_comms_tag = UiKit.label("COMMS", 20, UiKit.SCAN, "bold")
	name_row.add_child(_comms_tag)
	_name = UiKit.label("", 36, UiKit.ACCENT, "title")
	name_row.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.clip_contents = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 28)
	_text.add_theme_font_size_override("italics_font_size", 28)
	var df := UiKit.font("dialogue")
	if df:
		_text.add_theme_font_override("normal_font", df)
		_text.add_theme_font_override("italics_font", df)
	vb.add_child(_text)
	_portrait_r = Control.new()
	_portrait_r.custom_minimum_size = Vector2(170, 170)
	_portrait_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_portrait_r)
	_next = UiKit.label("▼", 30, UiKit.ACCENT, "bold")
	_next.anchor_left = 1.0
	_next.anchor_right = 1.0
	_next.anchor_top = 1.0
	_next.anchor_bottom = 1.0
	_next.offset_left = -96
	_next.offset_top = -70
	add_child(_next)
	_choices_box = VBoxContainer.new()
	_choices_box.anchor_left = 0.5
	_choices_box.anchor_right = 0.5
	_choices_box.anchor_top = 1.0
	_choices_box.anchor_bottom = 1.0
	_choices_box.offset_left = -380
	_choices_box.offset_right = 380
	_choices_box.offset_bottom = -250
	_choices_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices_box.add_theme_constant_override("separation", 14)
	add_child(_choices_box)

func _style(style: String, who: String) -> void:
	var dark := style == "comms"
	var sb: StyleBox
	if dark:
		sb = UiKit.box(UiKit.CARD.lerp(Color("#10232a"), 0.5), UiKit.SCAN.darkened(0.3), 16, 3, 22)
	else:
		sb = UiKit.box(UiKit.PARCHMENT, UiKit.PARCHMENT_DARK.darkened(0.35), 18, 4, 22)
	_panel.add_theme_stylebox_override("panel", sb)
	_text.add_theme_color_override("default_color", UiKit.PARCHMENT if dark else UiKit.INK)
	_comms_tag.visible = dark
	var nm := ""
	match style:
		"narration": nm = ""
		"handler": nm = "Handler"
		_: nm = UiKit.speaker_name(who)
	_name.text = nm
	_name.visible = nm != ""
	var col := UiKit.char_color(who)
	if style == "handler":
		col = UiKit.MUTED
	_name.label_settings.font_color = col.lightened(0.35) if dark else col.darkened(0.15)

func _on_line(line: Dictionary) -> void:
	_line = line
	visible = true
	_clear_choices()
	var style: String = line["style"]
	var who: String = line["who"]
	_style(style, who)
	_portrait_l.visible = false
	_portrait_r.visible = false
	if style == "normal" or style == "comms":
		var left := PARTY.has(who)
		var holder := _portrait_l if left else _portrait_r
		holder.visible = true
		var key := "%s|%s|%s" % [who, str(line["expr"]), style]
		if holder.get_meta("pkey", "") != key:
			# Portrait controls are cached and toggled (no node churn or texture rebuild when speakers alternate).
			var cur: Variant = holder.get_meta("pcur") if holder.has_meta("pcur") else null
			if cur is Control and is_instance_valid(cur):
				(cur as Control).visible = false
			var cache: Dictionary = _pcache.get(holder.get_instance_id(), {})
			var p: Control = cache.get(key, null)
			if p == null:
				p = UiKit.portrait_control(who, line["expr"], 170)
				p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				if style == "comms":
					p.modulate = Color(0.75, 1.0, 1.0)
				holder.add_child(p)
				cache[key] = p
				_pcache[holder.get_instance_id()] = cache
			p.visible = true
			holder.set_meta("pcur", p)
			holder.set_meta("pkey", key)
		# small pop (cheap: one tween on the holder)
		holder.pivot_offset = Vector2(85, 85)
		holder.scale = Vector2(0.94, 0.94)
		create_tween().tween_property(holder, "scale", Vector2.ONE, 0.1)
	var txt: String = line["text"]
	if style == "narration" or style == "handler":
		_text.text = "[i]%s[/i]" % txt
	else:
		_text.text = txt
	_total = _text.get_total_character_count()
	_shown = 0.0
	_text.visible_characters = 0
	_last_n = 0
	_typing = true
	_next.visible = false
	_input_cool = 0.12

func _on_choices(choices: Array) -> void:
	visible = true
	_clear_choices()
	_typing = false
	_text.visible_characters = -1
	_next.visible = false
	var i := 0
	for o in choices:
		var b := UiKit.button(str(o.get("text", "...")), Vector2(760, 88), 28)
		b.process_mode = Node.PROCESS_MODE_ALWAYS
		b.pressed.connect(_pick.bind(i))
		b.name = "Choice%d" % i
		_choices_box.add_child(b)
		i += 1
	if _choices_box.get_child_count() > 0:
		(_choices_box.get_child(0) as Button).grab_focus.call_deferred()

func _pick(i: int) -> void:
	_clear_choices()
	runner.choose(i)

func _clear_choices() -> void:
	for c in _choices_box.get_children():
		c.queue_free()

func _on_finished(_id: String) -> void:
	visible = false
	_clear_choices()

func _process(delta: float) -> void:
	if not visible:
		return
	_input_cool = maxf(0.0, _input_cool - delta)
	if _typing:
		_shown += CPS * delta
		var n := int(_shown)
		if n != _last_n and (n - _last_n >= 2 or n >= _total):
			_last_n = n
			_text.visible_characters = n
		if n >= _total:
			_typing = false
			_text.visible_characters = -1
	_blink += delta
	_next.visible = not _typing and _choices_box.get_child_count() == 0 and runner.active and fmod(_blink, 0.8) < 0.55

func _tap() -> void:
	if _input_cool > 0.0 or _choices_box.get_child_count() > 0:
		return
	if _typing:
		_typing = false
		_text.visible_characters = -1
		_input_cool = 0.1
		return
	Audio.sfx("ui_tap", -6.0)
	_input_cool = 0.1
	runner.advance()

func _on_catcher_input(ev: InputEvent) -> void:
	if not visible:
		return
	# Touch arrives here as emulated mouse (emulate_mouse_from_touch), so handle mouse only.
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if not visible or not runner or not runner.active:
		return
	if ev.is_action_pressed("interact") or ev.is_action_pressed("attack"):
		if _choices_box.get_child_count() > 0:
			return
		_tap()
		get_viewport().set_input_as_handled()
	elif ev is InputEventKey and ev.pressed and _choices_box.get_child_count() > 0:
		var k: int = (ev as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			_pick(k - KEY_1)
			get_viewport().set_input_as_handled()
