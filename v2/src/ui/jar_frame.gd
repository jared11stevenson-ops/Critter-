class_name JarFrame
extends Control
## A glass jar drawn around a live critter preview: soil, glass outline, lid, highlights.
const Pal := preload("res://src/critters/palettes.gd")
var preview: RigPreview
var hab: Habitat            # optional: draws what the critters have built, and the family standing in the soil
var adults := 0
var tint := Color(0.5, 0.7, 0.65)

func set_habitat(h: Habitat, adult_count: int, species: String) -> void:
	hab = h
	adults = adult_count
	tint = Pal.get_pal(species)["main"]
	queue_redraw()

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
	if hab != null:
		_draw_habitat(jar)
	draw_rect(jar, Color(0.95, 0.98, 1.0, 0.85), false, 5.0)                      # glass outline
	draw_rect(Rect2(jar.position.x + 12, jar.position.y + 14, 14, jar.size.y - 60), Color(1, 1, 1, 0.22), true)   # highlight
	draw_rect(Rect2(jar.position.x - 8, 16, jar.size.x + 16, 30), UiStyle.PAPER_DK, true)                        # lid
	draw_rect(Rect2(jar.position.x - 8, 16, jar.size.x + 16, 30), UiStyle.INK, false, 5.0)


## Built structures stand along the back wall (one slot per ladder step, in build order); the family stands in the soil.
func _draw_habitat(jar: Rect2) -> void:
	var ladder := Habitat.ladder(hab.species)
	var base_y := jar.end.y - 56.0
	var n := hab.structures.size()
	for k in range(n):
		var st: Dictionary = ladder[hab.structures[k]]
		var x := jar.position.x + 34.0 + (jar.size.x - 68.0) * (float([0, 4, 1, 3, 2][k]) + 0.5) / 5.0
		var col := Color(0.62, 0.42, 0.30).lerp(tint, 0.35).lightened(0.05 * k)
		match str(st["effect"]):
			"housing":
				var wd := 40.0 + 6.0 * k
				draw_rect(Rect2(x - wd * 0.5, base_y - 38, wd, 38), col, true)
				draw_rect(Rect2(x - wd * 0.5, base_y - 38, wd, 38), UiStyle.INK, false, 3.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x - wd * 0.6, base_y - 38), Vector2(x, base_y - 66), Vector2(x + wd * 0.6, base_y - 38)]), col.darkened(0.3))
				draw_rect(Rect2(x - 6, base_y - 22, 12, 22), UiStyle.INK, true)
			"food":
				for j in range(5):
					draw_line(Vector2(x - 20 + j * 10, base_y), Vector2(x - 20 + j * 10, base_y - 20 - (j % 2) * 8), Color(0.35, 0.62, 0.3), 4.0)
					draw_circle(Vector2(x - 20 + j * 10, base_y - 22 - (j % 2) * 8), 5.0, UiStyle.GOLD)
			"tribute":
				draw_rect(Rect2(x - 4, base_y - 54, 8, 54), UiStyle.INK.lightened(0.2), true)
				draw_circle(Vector2(x, base_y - 60), 12.0, Color(1.0, 0.8, 0.35, 0.35))
				draw_circle(Vector2(x, base_y - 60), 7.0, Color(1.0, 0.85, 0.4))
			_:
				draw_rect(Rect2(x - 12, base_y - 96, 24, 96), col.darkened(0.1), true)
				draw_rect(Rect2(x - 12, base_y - 96, 24, 96), UiStyle.INK, false, 3.0)
				draw_rect(Rect2(x - 18, base_y - 104, 36, 12), col.lightened(0.2), true)
				draw_circle(Vector2(x, base_y - 112), 8.0, Color(1.0, 0.85, 0.4))
	var folk := hab.descendants.size() + adults
	for i in range(mini(folk, 12)):
		var fx := jar.position.x + 24.0 + float(i) * ((jar.size.x - 48.0) / 12.0)
		var fy := jar.end.y - 24.0 + float(i % 3) * 5.0
		var big := i < adults
		draw_circle(Vector2(fx, fy), 6.0 if not big else 8.0, tint.lightened(0.1))
		draw_circle(Vector2(fx + 3, fy - 2), 1.6, UiStyle.INK)
		draw_circle(Vector2(fx - 1, fy - 2), 1.6, UiStyle.INK)
