class_name AbilityIcons
extends RefCounted
## Procedural vector ability icons: one bold silhouette per ability (readable at ~48 px on a phone), drawn with
## CanvasItem primitives in a unit square. They are baked ONCE into small ImageTextures (a SubViewport rendered a single
## time), so on the HUD each icon is a single textured quad exactly like the old PNGs: zero per-frame vector cost and no
## extra draw calls. If baking is unavailable (headless/dummy renderer) callers fall back to the PNG art.

signal baked(id: String)

const IDS := ["aruun_combo", "reaching_strike", "gravity_pull", "beetle_rage", "bad_thought", "premonition",
		"false_memory", "brain_skip", "dash", "scan", "grasshopper_thought", "probable_impact"]
const INK := Color(0.09, 0.05, 0.05, 0.95)
const LIGHT := Color(0.98, 0.94, 0.84)
const BAKE_PX := 160

static var _cache: Dictionary = {}     # id -> Texture2D
static var _pending: Dictionary = {}
static var events := AbilityIcons.new()

static func accent(id: String) -> Color:
	match id:
		"aruun_combo": return Color(1.0, 0.55, 0.15)
		"reaching_strike": return Color(1.0, 0.72, 0.25)
		"gravity_pull": return Color(0.74, 0.42, 1.0)
		"beetle_rage": return Color(1.0, 0.28, 0.12)
		"bad_thought": return Color(0.78, 0.86, 0.3)
		"premonition": return Color(0.45, 0.85, 1.0)
		"false_memory": return Color(0.95, 0.5, 0.85)
		"brain_skip": return Color(0.25, 1.0, 0.9)
		"dash": return Color(0.85, 0.9, 1.0)
		"scan": return Color(0.4, 0.9, 1.0)
		"grasshopper_thought": return Color(0.6, 0.95, 0.5)
		"probable_impact": return Color(0.85, 0.95, 0.4)
	return LIGHT

static func has_vector(id: String) -> bool:
	return id in IDS

## Cached baked texture or null (caller keeps its PNG fallback).
static func texture(id: String) -> Texture2D:
	return _cache.get(id, null)

## Kick off baking for every icon (idempotent). Safe to call from any _ready.
static func bake_all() -> void:
	for id in IDS:
		bake(id)

static func bake(id: String) -> void:
	if _cache.has(id) or _pending.has(id) or not has_vector(id):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null or DisplayServer.get_name() == "headless":
		return
	_pending[id] = true
	var vp := SubViewport.new()
	vp.size = Vector2i(BAKE_PX, BAKE_PX)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	var cv := _Canvas.new()
	cv.id = id
	cv.size = Vector2(BAKE_PX, BAKE_PX)
	vp.add_child(cv)
	tree.root.add_child.call_deferred(vp)
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	var img: Image = vp.get_texture().get_image() if is_instance_valid(vp) else null
	if img != null and not img.is_empty():
		img.generate_mipmaps()
		_cache[id] = ImageTexture.create_from_image(img)
		events.baked.emit(id)
	_pending.erase(id)
	if is_instance_valid(vp):
		vp.queue_free()

class _Canvas extends Control:
	var id := ""
	func _draw() -> void:
		AbilityIcons.draw(self, id, size * 0.5, minf(size.x, size.y) * 0.44)

# ---------------- drawing ----------------
static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w: float) -> void:
	ci.draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, INK, w, true)

static func _line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, INK, w + 5.0, true)
	ci.draw_line(a, b, col, w, true)

static func _arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float) -> void:
	ci.draw_arc(c, r, a0, a1, 24, INK, w + 5.0, true)
	ci.draw_arc(c, r, a0, a1, 24, col, w, true)

static func _disc(ci: CanvasItem, c: Vector2, r: float, fill: Color) -> void:
	ci.draw_circle(c, r + 2.5, INK)
	ci.draw_circle(c, r, fill)

static func _arrow_head(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var n := Vector2(-dir.y, dir.x)
	_poly(ci, PackedVector2Array([tip, tip - dir * size + n * size * 0.62, tip - dir * size - n * size * 0.62]), col, 3.0)

static func draw(ci: CanvasItem, id: String, c: Vector2, r: float) -> void:
	var ac := accent(id)
	var w := maxf(4.0, r * 0.16)
	match id:
		"aruun_combo":
			# mace swung through a crescent
			_arc(ci, c + Vector2(-r * 0.1, r * 0.1), r * 0.85, deg_to_rad(200), deg_to_rad(330), ac, w)
			_line(ci, c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.25, -r * 0.25), LIGHT, w * 1.2)
			_disc(ci, c + Vector2(r * 0.4, -r * 0.4), r * 0.36, ac)
			for k in 6:
				var a := TAU * float(k) / 6.0 + 0.4
				var d := Vector2(cos(a), sin(a))
				_line(ci, c + Vector2(r * 0.4, -r * 0.4) + d * r * 0.34, c + Vector2(r * 0.4, -r * 0.4) + d * r * 0.56, LIGHT, w * 0.6)
		"reaching_strike":
			_line(ci, c + Vector2(-r * 0.95, 0), c + Vector2(r * 0.5, 0), LIGHT, w * 1.3)
			_disc(ci, c + Vector2(r * 0.62, 0), r * 0.34, ac)
			for sgn in [-1.0, 1.0]:
				_line(ci, c + Vector2(-r * 0.9, sgn * r * 0.38), c + Vector2(-r * 0.3, sgn * r * 0.38), ac, w * 0.7)
			_arrow_head(ci, c + Vector2(r * 1.02, 0), Vector2.RIGHT, r * 0.42, LIGHT)
		"gravity_pull":
			for k in 3:
				var a0 := TAU * float(k) / 3.0
				_arc(ci, c, r * 0.9, a0, a0 + 1.5, ac, w)
				var tip := c + Vector2(cos(a0 + 1.5), sin(a0 + 1.5)) * r * 0.9
				var tdir := Vector2(-sin(a0 + 1.5), cos(a0 + 1.5)).rotated(0.5)
				_arrow_head(ci, tip.lerp(c, 0.28), -(tip - c).normalized() * 0.8 + tdir * 0.2, r * 0.3, LIGHT)
			_disc(ci, c, r * 0.3, LIGHT)
			_disc(ci, c, r * 0.14, INK)
		"beetle_rage":
			# horned head + flame crown
			var flame := PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.1), c + Vector2(-r * 0.55, -r * 0.85), c + Vector2(-r * 0.2, -r * 0.4),
					c + Vector2(0, -r * 1.05), c + Vector2(r * 0.2, -r * 0.4), c + Vector2(r * 0.55, -r * 0.85), c + Vector2(r * 0.6, -r * 0.1)])
			_poly(ci, flame, ac, 3.0)
			_disc(ci, c + Vector2(0, r * 0.28), r * 0.55, LIGHT)
			_line(ci, c + Vector2(-r * 0.4, r * 0.05), c + Vector2(-r * 0.12, r * 0.22), INK, w * 0.7)
			_line(ci, c + Vector2(r * 0.4, r * 0.05), c + Vector2(r * 0.12, r * 0.22), INK, w * 0.7)
			_arc(ci, c + Vector2(0, r * 0.36), r * 0.62, deg_to_rad(20), deg_to_rad(160), ac, w * 0.9)
		"bad_thought":
			_disc(ci, c + Vector2(-r * 0.7, r * 0.8), r * 0.1, LIGHT)
			_disc(ci, c + Vector2(-r * 0.5, r * 0.55), r * 0.17, LIGHT)
			_disc(ci, c + Vector2(r * 0.05, -r * 0.05), r * 0.62, LIGHT)
			var bolt := PackedVector2Array([c + Vector2(r * 0.22, -r * 0.5), c + Vector2(-r * 0.2, r * 0.02), c + Vector2(r * 0.02, r * 0.02),
					c + Vector2(-r * 0.12, r * 0.52), c + Vector2(r * 0.34, -r * 0.1), c + Vector2(r * 0.1, -r * 0.1)])
			_poly(ci, bolt, ac, 2.5)
		"premonition":
			var eye := PackedVector2Array()
			for k in 13:
				var x := lerpf(-1.0, 1.0, float(k) / 12.0)
				eye.append(c + Vector2(x * r, -sqrt(maxf(0.0, 1.0 - x * x)) * r * 0.55))
			for k in 13:
				var x2 := lerpf(1.0, -1.0, float(k) / 12.0)
				eye.append(c + Vector2(x2 * r, sqrt(maxf(0.0, 1.0 - x2 * x2)) * r * 0.55))
			_poly(ci, eye, LIGHT, 3.0)
			_disc(ci, c, r * 0.34, ac)
			_disc(ci, c, r * 0.14, INK)
			_arc(ci, c, r * 0.9, deg_to_rad(-60), deg_to_rad(-10), ac, w * 0.8)
			_arc(ci, c, r * 0.9, deg_to_rad(120), deg_to_rad(170), ac, w * 0.8)
		"false_memory":
			var d1 := PackedVector2Array([c + Vector2(-r * 0.75, -r * 0.1), c + Vector2(-r * 0.25, -r * 0.7), c + Vector2(r * 0.25, -r * 0.1), c + Vector2(-r * 0.25, r * 0.5)])
			_poly(ci, d1, ac.darkened(0.15), 3.0)
			var d2 := PackedVector2Array([c + Vector2(-r * 0.2, r * 0.1), c + Vector2(r * 0.3, -r * 0.5), c + Vector2(r * 0.8, r * 0.1), c + Vector2(r * 0.3, r * 0.7)])
			_poly(ci, d2, LIGHT, 3.0)
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.9, -r * 0.62 + float(k) * r * 0.12), c + Vector2(-r * 0.45, -r * 0.62 + float(k) * r * 0.12), ac, 3.0)
		"brain_skip":
			for k in 2:
				var o := Vector2(float(k) * r * 0.55 - r * 0.4, 0)
				_line(ci, c + o + Vector2(-r * 0.2, -r * 0.6), c + o + Vector2(r * 0.25, 0), ac if k == 0 else LIGHT, w * 1.3)
				_line(ci, c + o + Vector2(r * 0.25, 0), c + o + Vector2(-r * 0.2, r * 0.6), ac if k == 0 else LIGHT, w * 1.3)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.95, -r * 0.35), Vector2(r * 0.45, w * 0.7)), ac)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.95, r * 0.22), Vector2(r * 0.3, w * 0.7)), ac)
		"dash":
			for k in 3:
				var y := (float(k) - 1.0) * r * 0.42
				_line(ci, c + Vector2(-r * 0.95 + absf(y) * 0.4, y), c + Vector2(r * 0.1, y), ac, w * (1.0 if k == 1 else 0.7))
			_arrow_head(ci, c + Vector2(r * 0.98, 0), Vector2.RIGHT, r * 0.62, LIGHT)
		"scan":
			_arc(ci, c, r * 0.9, 0, TAU, ac, w * 0.8)
			_arc(ci, c, r * 0.5, 0, TAU, ac, w * 0.7)
			var sweep := PackedVector2Array([c, c + Vector2(r * 0.9, 0), c + Vector2(cos(-0.9), sin(-0.9)) * r * 0.9])
			ci.draw_colored_polygon(sweep, Color(LIGHT, 0.85))
			_line(ci, c, c + Vector2(r * 0.9, 0), LIGHT, w * 0.8)
			_disc(ci, c + Vector2(-r * 0.35, -r * 0.3), r * 0.12, LIGHT)
		"grasshopper_thought":
			for k in 3:
				var y2 := r * (0.55 - float(k) * 0.5)
				var s := 1.0 - float(k) * 0.12
				_line(ci, c + Vector2(-r * 0.55 * s, y2), c + Vector2(0, y2 - r * 0.38 * s), ac if k == 0 else LIGHT, w * 1.1)
				_line(ci, c + Vector2(0, y2 - r * 0.38 * s), c + Vector2(r * 0.55 * s, y2), ac if k == 0 else LIGHT, w * 1.1)
		"probable_impact":
			var burst := PackedVector2Array()
			for k in 16:
				var rr := r if k % 2 == 0 else r * 0.55
				var a := TAU * float(k) / 16.0
				burst.append(c + Vector2(cos(a), sin(a)) * rr)
			_poly(ci, burst, ac, 3.0)
			_disc(ci, c, r * 0.3, LIGHT)
			_disc(ci, c, r * 0.12, INK)
