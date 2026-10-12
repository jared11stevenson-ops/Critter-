class_name JarFrame
extends Control
## A glass jar drawn around a live critter preview: soil, glass outline, lid, highlights.
var preview: RigPreview

func show_critter(id: String) -> void:
	preview = RigPreview.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.offset_left = 50
	preview.offset_right = -50
	preview.offset_top = 50
	preview.offset_bottom = -40
	add_child(preview)
	preview.show_critter(id)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var jar := Rect2(34, 40, w - 68, h - 56)
	draw_rect(jar, Color(0.62, 0.78, 0.82, 0.30), true)                          # glass body tint
	draw_rect(Rect2(jar.position.x, jar.end.y - 56, jar.size.x, 56), Color(0.36, 0.25, 0.18, 0.95), true)   # soil
	draw_rect(Rect2(jar.position.x, jar.end.y - 56, jar.size.x, 8), Color(0.45, 0.34, 0.22, 1.0), true)
	draw_rect(jar, Color(0.95, 0.98, 1.0, 0.85), false, 5.0)                      # glass outline
	draw_rect(Rect2(jar.position.x + 12, jar.position.y + 14, 14, jar.size.y - 60), Color(1, 1, 1, 0.22), true)   # highlight
	draw_rect(Rect2(jar.position.x - 8, 16, jar.size.x + 16, 30), UiStyle.PAPER_DK, true)                        # lid
	draw_rect(Rect2(jar.position.x - 8, 16, jar.size.x + 16, 30), UiStyle.INK, false, 5.0)
