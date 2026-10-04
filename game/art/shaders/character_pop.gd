class_name CharacterPop
extends RefCounted
## Character "pop" layer (Agent 4): swaps a model's imported StandardMaterial3Ds for character_pop.gdshader materials
## (value/saturation lift + tinted fresnel rim + emissive accents) and chains an inverted-hull outline.
## Per-character palette lives in PALETTES (documented in design/model_sheets/<id>/palette.json "game_palette").
## Cost: 1 extra draw per surface (outline), the old rim overlay pass is folded into the main shader (net 0 vs before).

const SHADER := preload("res://game/art/shaders/character_pop.gdshader")
const SHADER_2S := preload("res://game/art/shaders/character_pop_2s.gdshader")
const OUTLINE := preload("res://game/art/shaders/character_pop_outline.gdshader")

const PALETTES := {
	# Aruun: sheet is oxblood/ochre/black/bone. Against warm desert he gets the deep saturated end of his reds, near-white bone,
	# and COOL ice-teal rim + emissive accents (complement of the red/orange world).
	"aruun": {
		"sat_lift": 1.32, "val_lift": 1.06, "contrast": 1.08, "shadow_floor": 0.12,
		"rim_color": Color(0.42, 0.95, 1.0), "rim_power": 2.4, "rim_strength": 0.7,
		"accent_color": Color(0.30, 0.95, 1.0), "accent_strength": 1.5, "accent_mix": 0.0,
		"outline_color": Color(0.03, 0.02, 0.06), "outline_width": 0.022,
	},
	# Cigarra: sheet is violet-black / white-blonde / olive-gold. Pop = acid yellow-green wings + gold + violet glow.
	"cigarra": {
		"sat_lift": 1.22, "val_lift": 1.14, "contrast": 1.12, "shadow_floor": 0.16,
		"rim_color": Color(0.80, 1.0, 0.25), "rim_power": 2.2, "rim_strength": 0.75,
		"accent_color": Color(0.78, 0.35, 1.0), "accent_strength": 1.6,
		"outline_color": Color(0.06, 0.02, 0.12), "outline_width": 0.011,
	},
}


## Returns the pop materials created (so the caller can drive flash/highlight on them).
static func apply(root: Node, id: String) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var pal: Dictionary = PALETTES.get(id, {})
	if pal.is_empty():
		return out
	var cache := {}
	_walk(root, pal, out, cache)
	return out


static func _walk(n: Node, pal: Dictionary, out: Array[ShaderMaterial], cache: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var src := mi.mesh.surface_get_material(s)
				var key := src
				if not cache.has(key):
					var pm := _convert(src, pal)
					cache[key] = pm
					if pm:
						out.append(pm)
				if cache[key]:
					mi.set_surface_override_material(s, cache[key])
	for c in n.get_children():
		_walk(c, pal, out, cache)


static func _convert(src: Material, pal: Dictionary) -> ShaderMaterial:
	if not (src is BaseMaterial3D):
		return null
	var b := src as BaseMaterial3D
	var m := ShaderMaterial.new()
	var scissor := b.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR or b.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shader = SHADER_2S if (scissor or b.cull_mode == BaseMaterial3D.CULL_DISABLED) else SHADER
	if scissor:
		m.set_shader_parameter("alpha_cut", maxf(b.alpha_scissor_threshold, 0.5))
	m.set_shader_parameter("albedo_tint", b.albedo_color)
	if b.albedo_texture:
		m.set_shader_parameter("albedo_tex", b.albedo_texture)
	if b.normal_texture:
		m.set_shader_parameter("normal_tex", b.normal_texture)
		m.set_shader_parameter("use_normal", 1.0)
	if b.roughness_texture:
		m.set_shader_parameter("orm_tex", b.roughness_texture)
		m.set_shader_parameter("use_orm", 1.0)
	m.set_shader_parameter("rough_base", b.roughness)
	m.set_shader_parameter("metal_base", b.metallic)
	if b.emission_enabled and b.emission_texture:
		m.set_shader_parameter("emis_tex", b.emission_texture)
		m.set_shader_parameter("use_emis", 1.0)
	for k in ["sat_lift", "val_lift", "contrast", "shadow_floor", "rim_color", "rim_power", "rim_strength", "accent_color", "accent_strength", "accent_mix"]:
		if pal.has(k):
			m.set_shader_parameter(k, pal[k])
	if not scissor:   # hull on single-sided leaf membranes looks wrong; the wings get a stronger rim instead
		var om := ShaderMaterial.new()
		om.shader = OUTLINE
		om.set_shader_parameter("outline_color", pal.get("outline_color", Color(0.05, 0.02, 0.08)))
		om.set_shader_parameter("width", pal.get("outline_width", 0.02))
		m.next_pass = om
	return m
