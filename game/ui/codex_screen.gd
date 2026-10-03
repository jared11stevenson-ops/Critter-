class_name CodexScreen
extends Control
## Field Codex: tabs (Species, Characters, Places, Lore, Mysteries), entry list, parchment page.
## Content from CodexData (codex.json when present). Locked entries show as "? ? ?".

var _tab := "Species"
var _list: VBoxContainer
var _page_title: Label
var _page_sub: Label
var _page_body: RichTextLabel
var _tabs: HBoxContainer
var _portrait_holder: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.04, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	margin.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := UiKit.label("FIELD CODEX", 44, UiKit.PARCHMENT, "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := UiKit.button("Close", Vector2(180, 88))
	close.pressed.connect(_close)
	top.add_child(close)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	vb.add_child(_tabs)
	for t in CodexData.TABS:
		var b := UiKit.button(t, Vector2(200, 88), 24)
		b.toggle_mode = true
		b.pressed.connect(_select_tab.bind(t))
		b.name = t
		_tabs.add_child(b)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	vb.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCHMENT, UiKit.PARCHMENT_DARK.darkened(0.4), 10, 5, 30))
	body.add_child(page)
	var pv := VBoxContainer.new()
	page.add_child(pv)
	var ph := HBoxContainer.new()
	pv.add_child(ph)
	_portrait_holder = Control.new()
	_portrait_holder.custom_minimum_size = Vector2(110, 110)
	ph.add_child(_portrait_holder)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_child(tv)
	_page_title = UiKit.label("", 40, UiKit.INK, "title")
	_page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_page_title)
	_page_sub = UiKit.label("", 22, UiKit.ACCENT.darkened(0.15), "bold")
	_page_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_page_sub)
	_page_body = RichTextLabel.new()
	_page_body.bbcode_enabled = true
	_page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_body.add_theme_color_override("default_color", UiKit.INK)
	_page_body.add_theme_font_size_override("normal_font_size", 26)
	_page_body.add_theme_font_size_override("bold_font_size", 26)
	_page_body.add_theme_font_size_override("italics_font_size", 26)
	var df := UiKit.font("dialogue")
	if df:
		_page_body.add_theme_font_override("normal_font", df)
		_page_body.add_theme_font_override("italics_font", df)
	var bf := UiKit.font("bold")
	if bf:
		_page_body.add_theme_font_override("bold_font", bf)
	pv.add_child(_page_body)
	_select_tab("Species")
	Audio.sfx("codex")

func _select_tab(t: String) -> void:
	_tab = t
	for b in _tabs.get_children():
		(b as Button).button_pressed = b.name == t
	for c in _list.get_children():
		c.queue_free()
	var first := ""
	var ids := CodexData.all_ids_for_tab(t)
	var unlocked_n := 0
	# unlocked first, then locked placeholders
	var ordered: Array = []
	for id in ids:
		if id in GameState.codex:
			ordered.append(id)
	for id in ids:
		if not (id in GameState.codex):
			ordered.append(id)
	ids = ordered
	for id in ids:
		var ok: bool = id in GameState.codex
		var b := UiKit.button(CodexData.title(id) if ok else "? ? ?", Vector2(360, 88), 26)
		b.disabled = not ok
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if ok:
			unlocked_n += 1
			b.pressed.connect(_show.bind(id))
			if first == "":
				first = id
		_list.add_child(b)
	var tb: Button = _tabs.get_node(t)
	tb.text = "%s %d/%d" % [t, unlocked_n, ids.size()] if ids.size() > 0 else t
	for ob in _tabs.get_children():
		if ob != tb:
			(ob as Button).text = ob.name
	if first != "":
		_show(first)
	else:
		_page_title.text = t
		_page_sub.text = ""
		_page_body.text = "No entries yet. Scan organisms and explore to fill these pages."
		for c in _portrait_holder.get_children():
			c.queue_free()

func _show(id: String) -> void:
	Audio.sfx("ui_tap", -4.0)
	_page_title.text = CodexData.title(id)
	_page_sub.text = CodexData.subtitle(id)
	_page_sub.visible = _page_sub.text != ""
	_page_body.text = CodexData.body(id)
	_page_body.scroll_to_line(0)
	for c in _portrait_holder.get_children():
		c.queue_free()
	var por := CodexData.portrait(id)
	if por.begins_with("res://"):
		var tex := UiKit.tex(por)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(100, 100)
			_portrait_holder.add_child(tr)
		else:
			por = ""
	elif por != "":
		_portrait_holder.add_child(UiKit.portrait_control(por, "default", 100))
	_portrait_holder.visible = por != ""

func _close() -> void:
	Audio.sfx("ui_back")
	queue_free()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
