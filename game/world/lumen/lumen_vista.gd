extends Node3D
## The Lumen Depths -- vault layer art slice (greybox -> art pass, no gameplay). Proves a second region reads as a different
## world: cool dark palette, living-constellation vault sky, crystal / basalt / glow-colony shape language, hanging
## silk walkways, a dark pool that mirrors the sky, plankton motes. Reuses the Red Reaches terrain builder with a Lumen
## layout + palette, the world kit (ReachesKit) and the same landmark merger.
## QA: set_cam(px,py,pz, tx,ty,tz, fov).

var terrain: Node3D
var cam: Camera3D
var lighting: Node3D


func _ready() -> void:
	terrain = RedReachesTerrain.new()
	terrain.name = "Terrain"
	terrain.set("layout_path", "res://game/world/lumen/lumen_layout.json")
	terrain.set("with_lighting", false)
	terrain.set("with_scatter", false)
	terrain.set("with_structures", false)
	terrain.set("cache_to_res", false)
	terrain.set("shader_params", {
		"ground_tint": Color(0.62, 0.80, 1.05), "dust_color": Color(0.16, 0.26, 0.36), "deep_color": Color(0.02, 0.04, 0.08),
		"strata_0": Color(0.14, 0.20, 0.32), "strata_1": Color(0.24, 0.34, 0.48), "strata_2": Color(0.40, 0.55, 0.70),
		"strata_3": Color(0.06, 0.08, 0.16), "strata_4": Color(0.12, 0.2, 0.3), "strata_mix": 0.8,
		"ripple_amp": 0.08, "deep_fade_y": -10.0, "cliff_scale": 0.07})
	add_child(terrain)
	lighting = load("res://game/world/common/world_lighting.gd").new()
	lighting.name = "Lighting"
	lighting.set("sky_kind", "lumen")
	lighting.set("preset", "lumen_vault")
	add_child(lighting)
	var env: Environment = lighting.get("env")
	if env:
		env.glow_intensity = 1.2
		env.glow_hdr_threshold = 0.9
		env.fog_sky_affect = 0.0
	var lm := ReachesLandmarks.new()
	lm.name = "Landmarks"
	lm.art_path = "res://game/world/lumen/lumen_art.json"
	add_child(lm)
	lm.populate(terrain)
	_build_pool()
	cam = Camera3D.new()
	cam.name = "Cam"
	cam.far = 900.0
	cam.fov = 60.0
	add_child(cam)
	set_cam(-12, 7, 18, 40, 0, -2, 62)


func _build_pool() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "DarkPool"
	var pm := PlaneMesh.new()
	pm.size = Vector2(25, 25)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/shaders/dark_pool.gdshader")
	mi.material_override = m
	mi.position = Vector3(64, -6.6, -36)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func set_cam(px: float, py: float, pz: float, tx: float, ty: float, tz: float, fov: float = 60.0) -> void:
	cam.fov = fov
	cam.global_position = Vector3(px, py, pz)
	cam.look_at(Vector3(tx, ty, tz), Vector3.UP)
	cam.make_current()
