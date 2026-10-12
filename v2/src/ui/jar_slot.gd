class_name JarSlot
extends Control
## One jar on the Shelf: empty, living critter (species disc, Vitality ring, founder crown, champion/retired mark) or selected.
signal pressed(slot: int)
var slot := 0
var critter: CritterInstance
var selected := false
var _col := Color(0.4, 0.4, 0.4)

func _init() -> void:
	custom_minimum_size = Vector2(68, 68)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_critter(c: CritterInstance) -> void:
	critter = c
	_col = (RigPalette.of(c.species).get("glow", Color(0.5, 0.5, 0.5)) as Color) if c != null else Color(0.3, 0.3, 0.3)
	queue_redraw()

func set_selected(v: bool) -> void:
	selected = v
	queue_redraw()

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(slot)
		accept_event()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(c, r, Color(0.07, 0.06, 0.08))
	if critter == null:
		draw_arc(c, r - 3.0, 0, TAU, 28, Color(1, 1, 1, 0.14), 2.0, true)
		draw_string(UiStyle.font(), Vector2(0, c.y + 6.0), str(slot + 1), HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(1, 1, 1, 0.2))
	else:
		draw_circle(c, r - 6.0, _col.darkened(0.45) if critter.retired else _col.darkened(0.15))
		draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.28, Color(1, 1, 1, 0.18))
		draw_string(UiStyle.font(), c + Vector2(-r, 10.0), critter.species.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 30, Color(0.1, 0.07, 0.07))
		var vcol := UiStyle.GREEN if critter.vitality > 0.5 else (UiStyle.GOLD if critter.vitality > 0.25 else UiStyle.RUST)
		draw_arc(c, r - 1.0, -PI * 0.5, -PI * 0.5 + TAU * critter.vitality, 28, vcol, 5.0, true)
		if critter.founder:
			draw_string(UiStyle.font(), Vector2(c.x - 9, 17), "♛", HORIZONTAL_ALIGNMENT_CENTER, 18, 16, UiStyle.GOLD)
		if critter.champion:
			draw_circle(c + Vector2(r * 0.7, -r * 0.7), 8.0, UiStyle.GOLD)
		if critter.retired:
			draw_string(UiStyle.font(), c + Vector2(-r, r - 2), "retired", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 11, Color(1, 1, 1, 0.7))
	if selected:
		draw_arc(c, r + 1.0, 0, TAU, 32, UiStyle.PAPER, 4.0, true)
