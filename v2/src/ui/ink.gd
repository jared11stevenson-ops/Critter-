class_name Ink extends RefCounted
## Draw-call-friendly 2D drawing for the HUD and touch controls. In the Compatibility renderer every draw_circle / draw_arc /
## StyleBoxFlat is its own draw call; the HUD used ~130 of the 150-call bout budget that way. Ink draws discs, rings, rectangles and
## 9-slice stickers as textured rects from ONE generated atlas (so they batch into a handful of calls) and queues all text so the
## outline glyphs and the fill glyphs are issued back to back. Polygons (partial arcs, ink wash) stay as a few real draws.
## Usage: var ink := Ink.new(self); ink.disc(...); ink.text(...); ink.flush()  (flush last, inside _draw).

const CELL := 128
const R_DISC := Rect2(0, 0, 128, 128)
const R_RING := Rect2(128, 0, 128, 128)
const R_RING_THICK := Rect2(256, 0, 128, 128)
const R_PANEL := Rect2(384, 0, 128, 128)
const R_WHITE := Rect2(8, 136, 8, 8)

static var atlas: ImageTexture
static var _panel_sb: StyleBoxTexture

var ci: CanvasItem
var _texts: Array = []

func _init(item: CanvasItem) -> void:
	ci = item
	ensure_atlas()

static func ensure_atlas() -> void:
	if atlas != null:
		return
	var img := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in CELL:
		for x in CELL:
			var d := Vector2(x + 0.5 - 64.0, y + 0.5 - 64.0).length()
			var a_out := clampf(63.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a_out))
			img.set_pixel(128 + x, y, Color(1, 1, 1, a_out * clampf(d - (63.0 - 7.0), 0.0, 1.0)))
			img.set_pixel(256 + x, y, Color(1, 1, 1, a_out * clampf(d - (63.0 - 16.0), 0.0, 1.0)))
			# rounded rect for the 9-slice sticker: corner radius 30, 1 px transparent padding
			var qx := absf(x + 0.5 - 64.0) - (64.0 - 1.0 - 30.0)
			var qy := absf(y + 0.5 - 64.0) - (64.0 - 1.0 - 30.0)
			var rd := Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - 30.0
			img.set_pixel(384 + x, y, Color(1, 1, 1, clampf(0.5 - rd, 0.0, 1.0)))
	for y in 16:
		for x in 16:
			img.set_pixel(x, 128 + y, Color.WHITE)
	atlas = ImageTexture.create_from_image(img)
	_panel_sb = StyleBoxTexture.new()
	_panel_sb.texture = atlas
	_panel_sb.region_rect = R_PANEL
	_panel_sb.texture_margin_left = 34
	_panel_sb.texture_margin_right = 34
	_panel_sb.texture_margin_top = 34
	_panel_sb.texture_margin_bottom = 34

func rect(r: Rect2, color: Color) -> void:
	ci.draw_texture_rect_region(atlas, r, R_WHITE, color)

func disc(c: Vector2, r: float, color: Color) -> void:
	ci.draw_texture_rect_region(atlas, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), R_DISC, color)

func ring(c: Vector2, r: float, color: Color, thick := false) -> void:
	ci.draw_texture_rect_region(atlas, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), R_RING_THICK if thick else R_RING, color)

## Sticker panel: hard drop shadow, ink border, flat fill (three 9-slice draws from the same atlas = one batch).
func panel(r: Rect2, fill: Color, border := UiStyle.INK, bw := 4.0, shadow := true) -> void:
	if shadow:
		_panel_sb.modulate_color = Color(0, 0, 0, 0.5)
		_panel_sb.draw(ci.get_canvas_item(), Rect2(r.position + Vector2(4, 5), r.size))
	_panel_sb.modulate_color = border
	_panel_sb.draw(ci.get_canvas_item(), r.grow(bw * 0.5))
	_panel_sb.modulate_color = fill
	_panel_sb.draw(ci.get_canvas_item(), r.grow(-bw * 0.5))

## Flat bar with an ink border.
func bar(r: Rect2, bg: Color, border := UiStyle.INK, bw := 3.0) -> void:
	rect(r.grow(bw), border)
	rect(r, bg)

## Outline width is derived from the size on purpose: every distinct (size, outline) pair is its own glyph atlas = its own draw call.
func text(pos: Vector2, s: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, _outline := 0) -> void:
	_texts.append([pos, s, size, color, align, width, 5 if size <= 20 else (7 if size <= 36 else (10 if size <= 60 else 16))])

## Issues the queued text: all outlines, then all fills.
static var debug_no_text := false

func flush() -> void:
	if debug_no_text:
		_texts.clear()
		return
	var f := UiStyle.font()
	_texts.sort_custom(func(a, b): return a[2] < b[2])
	for t in _texts:
		ci.draw_string_outline(f, t[0], t[1], t[4], t[5], t[2], t[6], UiStyle.INK)
	for t in _texts:
		ci.draw_string(f, t[0], t[1], t[4], t[5], t[2], t[3])
	_texts.clear()
