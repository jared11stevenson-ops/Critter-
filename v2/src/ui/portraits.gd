class_name Portraits
extends RefCounted
## Character icons (round head-and-shoulders portraits, v2/art/portraits/<id>.png, made by tools/gen/make_portraits.py).
## One place to get them so every screen shows the same face for the same critter.
static var _cache := {}

static func tex(id: String) -> Texture2D:
	if not _cache.has(id):
		var path := "res://art/portraits/%s.png" % id
		_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _cache[id]

## A ready TextureRect of the portrait at `px` size (empty Control-safe when the file is missing).
static func rect(id: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(id)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

## Puts the portrait on a Button as its icon (left of the text).
static func on_button(b: Button, id: String, px: float) -> void:
	var t := tex(id)
	if t != null:
		b.icon = t
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(px))
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
