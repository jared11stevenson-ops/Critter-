class_name UiStyle extends RefCounted
## "Cute-grim sticker" UI kit (ART_BIBLE section 5): thick ink outlines, cream paper panels with a hard drop shadow,
## gold / rust / teal accents, a heavy hand-lettered feel from an emboldened font (a real display font is a TODO, see arena/NEEDS.md).

const INK := Color(0.09, 0.07, 0.07)
const PAPER := Color(0.95, 0.88, 0.72)
const PAPER_DK := Color(0.78, 0.68, 0.52)
const GOLD := Color(0.96, 0.74, 0.28)
const RUST := Color(0.80, 0.32, 0.22)
const TEAL := Color(0.16, 0.45, 0.50)
const TEAL_LT := Color(0.40, 0.78, 0.76)
const GREEN := Color(0.52, 0.80, 0.34)
const NIGHT := Color(0.10, 0.11, 0.13)

static var _font: Font
static var _theme: Theme

static func font() -> Font:
	if _font == null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.55
		_font = fv
	return _font

static func box(fill: Color, border := INK, radius := 14, border_w := 4, shadow := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.55)
		s.shadow_size = 0
		s.shadow_offset = Vector2(4, 5)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 30
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 8)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := {"normal": GOLD, "hover": GOLD.lightened(0.15), "pressed": GOLD.darkened(0.2), "disabled": PAPER_DK.darkened(0.3), "focus": GOLD}[state] as Color
		var b := box(fill)
		if state == "pressed":
			b.shadow_offset = Vector2(1, 1)
			b.content_margin_top = 13
		if state == "focus":
			b.border_color = PAPER
		t.set_stylebox(state, "Button", b)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(0.3, 0.27, 0.25))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0))
	t.set_constant("outline_size", "Button", 0)
	t.set_font_size("font_size", "Button", 34)
	t.set_stylebox("panel", "PanelContainer", box(Color(0.17, 0.19, 0.21), INK, 18, 5))
	t.set_stylebox("panel", "Panel", box(Color(0.17, 0.19, 0.21), INK, 18, 5))
	t.set_color("font_color", "CheckButton", PAPER)
	_theme = t
	return t

static func label(text: String, size := 30, color := PAPER, outline := 8) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, size := 34, min_size := Vector2(260, 84), fill := GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	if fill != GOLD:
		for state in ["normal", "hover", "pressed", "focus"]:
			var sb := box(fill if state != "pressed" else fill.darkened(0.2))
			if state == "hover":
				sb.bg_color = fill.lightened(0.12)
			b.add_theme_stylebox_override(state, sb)
	b.focus_mode = Control.FOCUS_NONE
	return b

## Sticker panel drawn straight onto a CanvasItem (used by the HUD, which draws everything in one pass).
static func draw_sticker(ci: CanvasItem, r: Rect2, fill: Color, border := INK, width := 4.0, radius := 14.0, shadow := true) -> void:
	var sb := box(fill, border, int(radius), int(width), shadow)
	sb.draw(ci.get_canvas_item(), r)

static func draw_text(ci: CanvasItem, pos: Vector2, text: String, size: int, color := PAPER, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := font()
	ci.draw_string_outline(f, pos, text, align, width, size, 8, INK)
	ci.draw_string(f, pos, text, align, width, size, color)

## Safe-area margins in viewport units (left, top, right, bottom). Falls back to a 24 px gutter.
static func safe_margins(vp: Viewport) -> Vector4:
	var m := Vector4(24, 16, 24, 16)
	var win := DisplayServer.window_get_size()
	var rect := DisplayServer.get_display_safe_area()
	var scr := DisplayServer.screen_get_size()
	if win.x > 0 and win.y > 0 and rect.size.x > 0 and scr.x > 0 and rect.size != scr:
		var vs := vp.get_visible_rect().size
		var sx := vs.x / float(win.x)
		var sy := vs.y / float(win.y)
		m.x = maxf(m.x, float(rect.position.x) * sx)
		m.y = maxf(m.y, float(rect.position.y) * sy)
		m.z = maxf(m.z, float(scr.x - rect.end.x) * sx)
		m.w = maxf(m.w, float(scr.y - rect.end.y) * sy)
	return m

## Row of exclusive toggle buttons (label + options [[key, text], ...]); calls cb(key) when one is picked.
static func segment_row(label: String, opts: Array, current: String, cb: Callable, btn_w := 126.0, label_w := 86.0, stacked := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := UiStyle.label(label, 20, UiStyle.PAPER_DK, 5)
	l.custom_minimum_size = Vector2(label_w, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var out: Control = row
	if stacked:
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		vb.add_child(l)
		vb.add_child(row)
		out = vb
	else:
		row.add_child(l)
	var group := ButtonGroup.new()
	for o in opts:
		var b := Button.new()
		b.text = str(o[1])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = str(o[0]) == current
		b.custom_minimum_size = Vector2(btn_w, 62)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.PAPER.darkened(0.6), UiStyle.INK, 12, 3))
		b.add_theme_stylebox_override("hover", UiStyle.box(UiStyle.PAPER.darkened(0.5), UiStyle.INK, 12, 3))
		b.add_theme_stylebox_override("pressed", UiStyle.box(UiStyle.GOLD, UiStyle.INK, 12, 3))
		b.add_theme_stylebox_override("hover_pressed", UiStyle.box(UiStyle.GOLD, UiStyle.INK, 12, 3))
		b.add_theme_color_override("font_color", UiStyle.PAPER)
		b.add_theme_color_override("font_pressed_color", UiStyle.INK)
		b.add_theme_color_override("font_hover_pressed_color", UiStyle.INK)
		b.add_theme_color_override("font_hover_color", UiStyle.PAPER)
		var key := str(o[0])
		b.pressed.connect(func(): cb.call(key))
		row.add_child(b)
	return out
