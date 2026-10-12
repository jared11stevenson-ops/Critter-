class_name CritterCard extends Button
## A selectable roster card: palette disc with the critter's initial, name underneath. Drawn by hand so seven fit one row on a phone.
var critter_id := ""
var pal_main := Color.GRAY
var pal_glow := Color.WHITE
var disp_name := ""

func setup(id: String, main_col: Color, glow_col: Color) -> void:
	critter_id = id
	pal_main = main_col
	pal_glow = glow_col
	disp_name = CombatData.critter(id).display_name
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(112, 112)
	add_theme_stylebox_override("normal", UiStyle.box(UiStyle.PAPER.darkened(0.6), UiStyle.INK, 16, 4))
	add_theme_stylebox_override("hover", UiStyle.box(UiStyle.PAPER.darkened(0.5), UiStyle.INK, 16, 4))
	add_theme_stylebox_override("pressed", UiStyle.box(UiStyle.PAPER.darkened(0.35), UiStyle.GOLD, 16, 6))
	add_theme_stylebox_override("hover_pressed", UiStyle.box(UiStyle.PAPER.darkened(0.35), UiStyle.GOLD, 16, 6))

func _draw() -> void:
	var c := Vector2(size.x * 0.5, 44)
	var pt := Portraits.tex(critter_id)
	if pt != null:
		draw_texture_rect(pt, Rect2(c - Vector2(46, 46), Vector2(92, 92)), false)
	else:
		draw_circle(c, 38, UiStyle.INK)
		draw_circle(c, 34, pal_main)
		draw_arc(c, 34, 0, TAU, 28, pal_glow, 4.0, true)
		UiStyle.draw_text(self, c + Vector2(-30, 14), disp_name.substr(0, 1).to_upper(), 40, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, 60)
	UiStyle.draw_text(self, Vector2(0, size.y - 12), disp_name.to_upper(), 19, UiStyle.GOLD if button_pressed else UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, size.x)
