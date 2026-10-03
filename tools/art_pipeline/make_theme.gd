extends SceneTree
## Builds res://game/art/ui/critter_theme.tres (Agent 1). Run:
## godot --headless --path . --script res://tools/art_pipeline/make_theme.gd

const UI := "res://game/art/ui/"
const FONTS := "res://game/art/fonts/"
const INK := Color(0.13, 0.10, 0.10)
const PARCH := Color(0.93, 0.88, 0.80)
const GOLD := Color(0.86, 0.68, 0.36)


func _init() -> void:
	var t := Theme.new()
	var barlow: FontFile = load(FONTS + "barlow_condensed_medium.woff2")
	var barlow_b: FontFile = load(FONTS + "barlow_condensed_bold.woff2")
	var kalam: FontFile = load(FONTS + "kalam_regular.woff2")
	var kalam_b: FontFile = load(FONTS + "kalam_bold.woff2")
	var marker: FontFile = load(FONTS + "permanent_marker.woff2")
	var cinzel: FontFile = load(FONTS + "cinzel_bold.woff2")
	t.default_font = barlow
	t.default_font_size = 24

	var parch := _tex_box("panel_parchment.png", 32, Vector4(28, 24, 28, 24))
	var dark := _tex_box("panel_dark.png", 16, Vector4(16, 10, 16, 10))
	var dark_hover := dark.duplicate() as StyleBoxTexture
	dark_hover.modulate_color = Color(1.25, 1.2, 1.15)
	var dark_pressed := dark.duplicate() as StyleBoxTexture
	dark_pressed.modulate_color = Color(0.8, 0.75, 0.75)
	var dark_disabled := dark.duplicate() as StyleBoxTexture
	dark_disabled.modulate_color = Color(1, 1, 1, 0.5)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)

	for ty in ["Panel", "PanelContainer"]:
		t.set_stylebox("panel", ty, parch)
	# Dark card variation (ability cards, HUD)
	t.set_type_variation("DarkPanel", "PanelContainer")
	t.set_stylebox("panel", "DarkPanel", _tex_box("panel_dark.png", 16, Vector4(18, 14, 18, 14)))

	t.set_stylebox("normal", "Button", dark)
	t.set_stylebox("hover", "Button", dark_hover)
	t.set_stylebox("pressed", "Button", dark_pressed)
	t.set_stylebox("disabled", "Button", dark_disabled)
	t.set_stylebox("focus", "Button", focus)
	t.set_font("font", "Button", barlow_b)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Button", PARCH)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(PARCH, 0.4))
	t.set_color("font_focus_color", "Button", Color(1, 0.95, 0.85))

	# Parchment-style button variation (choices in dialogue)
	t.set_type_variation("ChoiceButton", "Button")
	var pb := _tex_box("panel_parchment.png", 32, Vector4(22, 12, 22, 12))
	var pbh := pb.duplicate() as StyleBoxTexture
	pbh.modulate_color = Color(1.06, 1.0, 0.9)
	var pbp := pb.duplicate() as StyleBoxTexture
	pbp.modulate_color = Color(0.85, 0.8, 0.72)
	t.set_stylebox("normal", "ChoiceButton", pb)
	t.set_stylebox("hover", "ChoiceButton", pbh)
	t.set_stylebox("pressed", "ChoiceButton", pbp)
	t.set_stylebox("focus", "ChoiceButton", focus)
	t.set_font("font", "ChoiceButton", kalam_b)
	t.set_color("font_color", "ChoiceButton", INK)
	t.set_color("font_hover_color", "ChoiceButton", Color(0.45, 0.12, 0.08))
	t.set_color("font_pressed_color", "ChoiceButton", INK)
	t.set_color("font_focus_color", "ChoiceButton", INK)

	t.set_color("font_color", "Label", INK)
	t.set_type_variation("HudLabel", "Label")
	t.set_font("font", "HudLabel", barlow_b)
	t.set_color("font_color", "HudLabel", PARCH)
	t.set_color("font_outline_color", "HudLabel", INK)
	t.set_constant("outline_size", "HudLabel", 6)
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", marker)
	t.set_font_size("font_size", "TitleLabel", 48)
	t.set_type_variation("SolemnLabel", "Label")
	t.set_font("font", "SolemnLabel", cinzel)
	t.set_font_size("font_size", "SolemnLabel", 36)
	t.set_type_variation("DialogueLabel", "Label")
	t.set_font("font", "DialogueLabel", kalam)
	t.set_font_size("font_size", "DialogueLabel", 26)
	t.set_type_variation("NameLabel", "Label")
	t.set_font("font", "NameLabel", marker)
	t.set_font_size("font_size", "NameLabel", 30)
	t.set_color("font_color", "NameLabel", Color(0.45, 0.12, 0.08))

	t.set_font("normal_font", "RichTextLabel", kalam)
	t.set_font("bold_font", "RichTextLabel", kalam_b)
	t.set_font_size("normal_font_size", "RichTextLabel", 26)
	t.set_font_size("bold_font_size", "RichTextLabel", 26)
	t.set_color("default_color", "RichTextLabel", INK)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.1, 0.85)
	bg.set_corner_radius_all(6)
	bg.border_color = INK
	bg.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.22, 0.14)
	fill.set_corner_radius_all(5)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", PARCH)
	t.set_type_variation("TrustBar", "ProgressBar")
	var tf := fill.duplicate() as StyleBoxFlat
	tf.bg_color = GOLD
	t.set_stylebox("fill", "TrustBar", tf)

	t.set_stylebox("panel", "TooltipPanel", dark)
	t.set_color("font_color", "TooltipLabel", PARCH)
	t.set_stylebox("separation", "HSeparator", _divider())

	var err := ResourceSaver.save(t, UI + "critter_theme.tres")
	print("[THEME] saved err=", err)
	quit()


func _tex_box(file: String, margin: int, content: Vector4) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(UI + file)
	s.texture_margin_left = margin
	s.texture_margin_top = margin
	s.texture_margin_right = margin
	s.texture_margin_bottom = margin
	s.content_margin_left = content.x
	s.content_margin_top = content.y
	s.content_margin_right = content.z
	s.content_margin_bottom = content.w
	return s


func _divider() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(UI + "divider_brush.png")
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
