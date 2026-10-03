class_name CritterLighting
extends Node3D
## Field / hub lighting rig: WorldEnvironment (painted sky, fog, glow, tonemap) + mobile-tuned sun.
## Compatibility renderer safe. Add as a child; call `apply_preset("reaches" | "hub" | "dusk")`.

@export var preset: String = "reaches"

var env: Environment
var sun: DirectionalLight3D
var world_env: WorldEnvironment
var sky_mat: ShaderMaterial


func _ready() -> void:
	if world_env == null:
		_build()
		apply_preset(preset)


func _build() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://game/art/shaders/sky_reaches.gdshader")
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_REALTIME if false else Sky.PROCESS_MODE_QUALITY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.adjustment_enabled = true
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	sun.directional_shadow_split_1 = 0.25
	sun.directional_shadow_blend_splits = false
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.4
	sun.shadow_blur = 1.5
	sun.light_angular_distance = 0.6
	add_child(sun)


func apply_preset(p: String) -> void:
	preset = p
	if env == null:
		_build()
	match p:
		"hub":
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.12, 0.10, 0.10)
			env.ambient_light_color = Color(0.85, 0.72, 0.62)
			env.ambient_light_energy = 0.55
			env.fog_light_color = Color(0.42, 0.33, 0.30)
			env.fog_density = 0.012
			env.fog_sky_affect = 0.0
			env.adjustment_saturation = 1.08
			env.adjustment_contrast = 1.05
			sun.light_color = Color(1.0, 0.88, 0.70)
			sun.light_energy = 0.75
			sun.rotation_degrees = Vector3(-62, -28, 0)
		"dusk":
			env.ambient_light_color = Color(0.70, 0.55, 0.70)
			env.ambient_light_energy = 0.6
			env.fog_light_color = Color(0.85, 0.55, 0.50)
			env.fog_density = 0.006
			sun.light_color = Color(1.0, 0.68, 0.45)
			sun.light_energy = 1.1
			sun.rotation_degrees = Vector3(-24, -55, 0)
			sky_mat.set_shader_parameter("horizon_color", Color(1.0, 0.62, 0.48))
			sky_mat.set_shader_parameter("mid_color", Color(0.72, 0.52, 0.72))
			sky_mat.set_shader_parameter("zenith_color", Color(0.25, 0.2, 0.45))
		_:
			# Red Reaches midday: warm sun from the upper left/back, cool sky fill
			env.ambient_light_color = Color(0.58, 0.48, 0.74)
			env.ambient_light_energy = 0.62
			env.fog_light_color = Color(0.86, 0.60, 0.52)
			env.fog_light_energy = 1.0
			env.fog_density = 0.0045
			env.fog_sky_affect = 0.15
			env.fog_height = -8.0
			env.fog_height_density = 0.09
			env.adjustment_saturation = 1.18
			env.adjustment_contrast = 1.1
			sun.light_color = Color(1.0, 0.89, 0.74)
			sun.light_energy = 1.2
			sun.rotation_degrees = Vector3(-52, -38, 0)
