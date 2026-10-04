class_name UiKit
extends RefCounted
## Shared UI style: fonts, palette, theme (Agent 1's critter_theme.tres if present, else built in code),
## portraits / icons with fallbacks, and small widget factories. Reference resolution 1280x720.

const PARCHMENT := Color("#e9dcc0")
const PARCHMENT_DARK := Color("#cdb994")
const INK := Color("#2a211d")
const CARD := Color("#1c1716")
const CARD_EDGE := Color("#3a2e29")
const ACCENT := Color("#c8462b")
const ACCENT_2 := Color("#d9803a")
const PSI := Color("#b8c24a")
const SCAN := Color("#59d2e6")
const MUTED := Color("#8a7d6c")

const THEME_PATH := "res://game/art/ui/critter_theme.tres"
const CHAR_COLORS := {
	"aruun": Color("#c8462b"), "cigarra": Color("#8f8a52"), "mara": Color("#4f7a8c"), "dexter": Color("#5b5f6a"),
	"nerit": Color("#3d5f9a"), "mollusk": Color("#8a6d9a"), "zephyr": Color("#d9a43a"), "nyxaris": Color("#9ad0e6"),
	"pharilux": Color("#4e6b4a"), "solmara": Color("#3a8a8a"), "scarlith": Color("#b0302a"), "bramvex": Color("#6b5a3a"),
}

const RIVAL_COLORS := {
	"dominion": Color("#8a3a30"), "undermarket": Color("#8a6a2a"), "free_scale": Color("#3a6b4a"), "helix": Color("#2a8f9a"),
}

static var _fonts: Dictionary = {}
static var _theme: Theme = null
static var _tex_cache: Dictionary = {}

static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var files := {
		"title": "permanent_marker", "dialogue": "kalam_regular", "dialogue_bold": "kalam_bold",
		"ui": "barlow_condensed_medium", "bold": "barlow_condensed_bold", "solemn": "cinzel_bold",
	}
	var path := "res://game/art/fonts/%s.woff2" % files.get(kind, "barlow_condensed_medium")
	var fnt: Font = null
	if ResourceLoader.exists(path):
		fnt = load(path)
	_fonts[kind] = fnt
	return fnt

static func theme() -> Theme:
	if _theme:
		return _theme
	if ResourceLoader.exists(THEME_PATH):
		var t: Variant = load(THEME_PATH)
		if t is Theme:
			_theme = t
			return _theme
	_theme = _build_theme()
	return _theme

static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 14, border_w: int = 0, pad: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s

static func _build_theme() -> Theme:
	var t := Theme.new()
	var f := font("ui")
	if f:
		t.default_font = f
	t.default_font_size = 26
	t.set_stylebox("normal", "Button", box(CARD, ACCENT.darkened(0.3), 16, 3))
	t.set_stylebox("hover", "Button", box(CARD.lightened(0.08), ACCENT, 16, 3))
	t.set_stylebox("pressed", "Button", box(ACCENT.darkened(0.2), ACCENT.lightened(0.2), 16, 3))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), PARCHMENT, 16, 3))
	t.set_stylebox("disabled", "Button", box(CARD.darkened(0.2), CARD_EDGE, 16, 2))
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_font_size("font_size", "Button", 28)
	if font("bold"):
		t.set_font("font", "Button", font("bold"))
	t.set_stylebox("panel", "Panel", box(PARCHMENT, PARCHMENT_DARK.darkened(0.3), 18, 4))
	t.set_stylebox("panel", "PanelContainer", box(PARCHMENT, PARCHMENT_DARK.darkened(0.3), 18, 4, 22))
	t.set_color("font_color", "Label", INK)
	t.set_font_size("font_size", "Label", 26)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font_size("normal_font_size", "RichTextLabel", 26)
	if font("dialogue"):
		t.set_font("normal_font", "RichTextLabel", font("dialogue"))
	if font("dialogue_bold"):
		t.set_font("bold_font", "RichTextLabel", font("dialogue_bold"))
	var grab := box(ACCENT, Color(0, 0, 0, 0), 12, 0, 4)
	t.set_stylebox("slider", "HSlider", box(CARD_EDGE, Color(0, 0, 0, 0), 8, 0, 6))
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	var gi := _circle_icon(34, ACCENT)
	t.set_icon("grabber", "HSlider", gi)
	t.set_icon("grabber_highlight", "HSlider", gi)
	t.set_stylebox("tab_selected", "TabBar", box(PARCHMENT, ACCENT, 12, 3))
	t.set_stylebox("tab_unselected", "TabBar", box(CARD, CARD_EDGE, 12, 2))
	t.set_stylebox("tab_hovered", "TabBar", box(CARD.lightened(0.1), ACCENT, 12, 2))
	t.set_color("font_selected_color", "TabBar", INK)
	t.set_color("font_unselected_color", "TabBar", PARCHMENT)
	t.set_font_size("font_size", "TabBar", 28)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 12)
	return t

static func _circle_icon(size: int, col: Color) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c).length()
			var a := clampf(c - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)

## Label factory with font kind + size + colour + outline.
static func label(text: String, size: int = 26, col: Color = INK, kind: String = "ui", outline: int = 0, outline_col: Color = Color(0, 0, 0, 0.8)) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	var f := font(kind)
	if f:
		ls.font = f
	ls.font_size = size
	ls.font_color = col
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = outline_col
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, min_size: Vector2 = Vector2(260, 88), size: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_ALL
	return b

static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_tex_cache[path] = t
	return t

static func portrait(id: String, expr: String = "default") -> Texture2D:
	var t := tex("res://game/art/portraits/%s/%s.png" % [id, expr])
	if t == null and expr != "default":
		t = tex("res://game/art/portraits/%s/default.png" % id)
	return t

static func char_color(id: String) -> Color:
	if id.begins_with("rival:"):
		var r: Dictionary = Rivals.get_rival(id.substr(6))
		return RIVAL_COLORS.get(str(r.get("faction", "")), Color("#6b5a4a"))
	return CHAR_COLORS.get(id, Color("#6b5a4a"))

## Display name for a speaker id; "rival:<id>" resolves through the Ledger Rivals roster.
static func speaker_name(id: String) -> String:
	if id.begins_with("rival:"):
		var r: Dictionary = Rivals.get_rival(id.substr(6))
		return str(r.get("name", "Stranger"))
	return Canon.display_name(id)

## Portrait control: real portrait if present, else a coloured badge with the initial.
static func portrait_control(id: String, expr: String, size: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_portrait(holder, id, expr, size)
	return holder

static func _fill_portrait(holder: Control, id: String, expr: String, size: float) -> void:
	for c in holder.get_children():
		c.queue_free()
	var t := portrait(id, expr)
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := char_color(id)
	frame.add_theme_stylebox_override("panel", box(col.darkened(0.45), PARCHMENT, int(size * 0.5), 4))
	holder.add_child(frame)
	if t:
		var tr := TextureRect.new()
		tr.texture = t
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 4
		tr.offset_top = 4
		tr.offset_right = -4
		tr.offset_bottom = -4
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
	else:
		var inner := Panel.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 6
		inner.offset_top = 6
		inner.offset_right = -6
		inner.offset_bottom = -6
		inner.add_theme_stylebox_override("panel", box(col, Color(0, 0, 0, 0), int(size * 0.5), 0))
		holder.add_child(inner)
		var nm := speaker_name(id) if id != "" else "?"
		var l := label(nm.substr(0, 1).to_upper(), int(size * 0.5), PARCHMENT, "title", 6, INK)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(l)

## Ability icon or fallback glyph.
static func ability_glyph(ability_id: String) -> String:
	var glyphs := {
		"reaching_strike": "REACH", "gravity_pull": "PULL", "beetle_rage": "RAGE", "aruun_combo": "MACE",
		"bad_thought": "BOLT", "premonition": "SEE", "false_memory": "ECHO", "brain_skip": "SKIP",
		"grasshopper_thought": "LEAP",
	}
	return glyphs.get(ability_id, ability_id.substr(0, 4).to_upper())

static func ability_icon(ability_id: String) -> Texture2D:
	return tex("res://game/art/icons/%s.png" % ability_id)

## Row of ability icons (+ names) for every canon ability owned by `owner_id` (character id). Null if none.
static func ability_row(owner_id: String, icon_px: float = 64.0, with_names: bool = true) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var abilities: Dictionary = Canon.data.get("abilities", {})
	for aid in abilities:
		var ab: Dictionary = abilities[aid]
		if str(ab.get("owner", "")) != owner_id:
			continue
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var tr := TextureRect.new()
		tr.texture = ability_icon(aid)
		tr.custom_minimum_size = Vector2(icon_px, icon_px)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.tooltip_text = str(ab.get("desc", ""))
		cell.add_child(tr)
		if with_names:
			var l := label(str(ab.get("name", aid)), 16, INK, "bold")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(l)
		row.add_child(cell)
	return row if row.get_child_count() > 0 else null

static func item_name(item_id: String) -> String:
	var names := {
		"reach_soil": "Reach Soil", "lichen_culture": "Lichen Culture", "thoughtstone_dust": "Thoughtstone Dust",
		"salvage": "Salvage", "thoughtstone_cache": "Thoughtstone Cache",
	}
	return names.get(item_id, item_id.capitalize())
