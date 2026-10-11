extends RefCounted
## Material factory for characters. One toon material (+ outline next_pass) per rig; face and FX have their own.

const TOON := preload("res://src/critters/shaders/toon.gdshader")
const OUTLINE := preload("res://src/critters/shaders/outline.gdshader")
const FACE := preload("res://src/critters/shaders/face.gdshader")
const FX := preload("res://src/critters/shaders/fx.gdshader")
const GLASS := preload("res://src/critters/shaders/glass.gdshader")

## Presentation constant (not gameplay): outline thickness in screen pixels at 720p, scaled by viewport height.
const OUTLINE_PX := 3.2

static func character(rim: Color, ink: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("rim_color", rim)
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter("px_width", OUTLINE_PX)
	o.set_shader_parameter("ink", ink)
	m.next_pass = o
	return m

static func face(ink: Color, accent: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FACE
	m.render_priority = 2
	m.set_shader_parameter("ink", ink)
	m.set_shader_parameter("accent", accent)
	return m

static func glass(edge: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLASS
	m.render_priority = 1
	m.set_shader_parameter("edge_col", edge)
	return m

static func fx(color: Color, mode: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FX
	m.render_priority = 3
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("mode", mode)
	return m

## Set a parameter on both passes (toon + outline) for flash / impact frames.
static func set_both(m: ShaderMaterial, key: String, val: Variant) -> void:
	m.set_shader_parameter(key, val)
	if m.next_pass is ShaderMaterial:
		(m.next_pass as ShaderMaterial).set_shader_parameter(key, val)
