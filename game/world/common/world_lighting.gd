class_name CritterLighting
extends Node3D
## Field / hub lighting rig (Agent 1, v0.7 painterly realism): WorldEnvironment (painted sky, ACES tonemap,
## aerial depth fog + height fog, soft glow), a warm low key sun with soft PCF shadows, and a shadowless
## character rim/back light that only affects VisualInstance layer 11 (`RIM_LAYER`) — put 3D character meshes
## on that layer (layers |= CritterLighting.RIM_LAYER) so they separate from the ground.
## Compatibility renderer safe.
##
## Presets: "reaches" (static, default), "hub", "dusk", or the Red Reaches mood keys below. With `zone_blend`
## the rig follows the active camera and blends the Red Reaches moods by the camera focus' X position along
## the level (gate pad -> fracture valley -> waystation -> drill site -> Ochre Span -> boss foundation).

const RIM_LAYER := 1 << 10

@export var preset: String = "reaches"
## Blend moods along the Red Reaches path (set by RedReachesTerrain).
@export var zone_blend: bool = false
## Global multipliers for the mood table (sun, ambient).
@export var sun_scale: float = 0.36
@export var amb_scale: float = 0.6

var env: Environment
var sun: DirectionalLight3D
var rim: DirectionalLight3D
var world_env: WorldEnvironment
var sky_mat: ShaderMaterial
var current_zone := ""

## Mood table. sun_rot = Vector2(pitch, yaw) degrees. All colours are linear-ish artist values.
const MOODS := {
	"gate": {
		"sun_col": Color(1.0, 0.86, 0.68), "sun_e": 2.1, "sun_rot": Vector2(-38, -118),
		"amb_col": Color(0.56, 0.58, 0.72), "amb_e": 0.62, "sky_e": 0.35,
		"fog_col": Color(0.92, 0.70, 0.58), "fog_d": 0.0021, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.18,
		"exposure": 1.10, "sat": 1.06, "contrast": 1.06, "glow": 0.42,
		"rim_col": Color(0.82, 0.88, 1.0), "rim_e": 0.9,
		"horizon": Color(0.98, 0.80, 0.66), "zenith": Color(0.28, 0.44, 0.74),
	},
	"valley": {
		"sun_col": Color(1.0, 0.80, 0.58), "sun_e": 2.0, "sun_rot": Vector2(-34, -124),
		"amb_col": Color(0.62, 0.52, 0.62), "amb_e": 0.56, "sky_e": 0.3,
		"fog_col": Color(0.95, 0.66, 0.48), "fog_d": 0.0037, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.28,
		"exposure": 1.10, "sat": 1.04, "contrast": 1.08, "glow": 0.5,
		"rim_col": Color(1.0, 0.86, 0.70), "rim_e": 1.0,
		"horizon": Color(1.0, 0.76, 0.58), "zenith": Color(0.34, 0.46, 0.72),
	},
	"waystation": {
		"sun_col": Color(1.0, 0.84, 0.62), "sun_e": 1.95, "sun_rot": Vector2(-36, -112),
		"amb_col": Color(0.60, 0.56, 0.66), "amb_e": 0.62, "sky_e": 0.35,
		"fog_col": Color(0.94, 0.74, 0.58), "fog_d": 0.0027, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.22,
		"exposure": 1.12, "sat": 1.06, "contrast": 1.05, "glow": 0.45,
		"rim_col": Color(0.85, 0.9, 1.0), "rim_e": 0.85,
		"horizon": Color(0.99, 0.80, 0.64), "zenith": Color(0.30, 0.45, 0.74),
	},
	"drill": {
		"sun_col": Color(1.0, 0.72, 0.52), "sun_e": 1.6, "sun_rot": Vector2(-30, -128),
		"amb_col": Color(0.58, 0.42, 0.46), "amb_e": 0.5, "sky_e": 0.25,
		"fog_col": Color(0.78, 0.44, 0.34), "fog_d": 0.0055, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.3,
		"exposure": 1.07, "sat": 1.02, "contrast": 1.12, "glow": 0.62,
		"rim_col": Color(1.0, 0.45, 0.38), "rim_e": 1.1,
		"horizon": Color(0.92, 0.58, 0.44), "zenith": Color(0.36, 0.36, 0.56),
	},
	"span": {
		"sun_col": Color(1.0, 0.70, 0.40), "sun_e": 2.2, "sun_rot": Vector2(-17, -100),
		"amb_col": Color(0.64, 0.50, 0.60), "amb_e": 0.55, "sky_e": 0.3,
		"fog_col": Color(1.0, 0.68, 0.42), "fog_d": 0.0032, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.45,
		"exposure": 1.12, "sat": 1.1, "contrast": 1.06, "glow": 0.6,
		"rim_col": Color(1.0, 0.78, 0.5), "rim_e": 1.2,
		"horizon": Color(1.0, 0.66, 0.42), "zenith": Color(0.36, 0.38, 0.66),
	},
	"boss": {
		"sun_col": Color(1.0, 0.62, 0.40), "sun_e": 1.9, "sun_rot": Vector2(-22, -165),
		"amb_col": Color(0.46, 0.38, 0.52), "amb_e": 0.5, "sky_e": 0.25,
		"fog_col": Color(0.82, 0.48, 0.40), "fog_d": 0.0045, "fog_h": -12.0, "fog_hd": 0.035, "fog_sun": 0.5,
		"exposure": 1.10, "sat": 1.04, "contrast": 1.14, "glow": 0.7,
		"rim_col": Color(1.0, 0.70, 0.52), "rim_e": 1.0,
		"horizon": Color(0.98, 0.56, 0.40), "zenith": Color(0.24, 0.24, 0.46),
	},
}
## Mood keyframes along the level X axis (Red Reaches layout).
const ZONE_KEYS := [[-30.0, "gate"], [14.0, "gate"], [40.0, "valley"], [86.0, "valley"], [108.0, "waystation"],
	[140.0, "waystation"], [172.0, "drill"], [224.0, "drill"], [244.0, "span"], [290.0, "span"], [306.0, "boss"],
	[400.0, "boss"]]

var _cur: Dictionary = {}


func _ready() -> void:
	if world_env == null:
		_build()
		apply_preset(preset)
	set_process(zone_blend)


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
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = sky
	# ambient = flat colour mixed with a little sky so shadowed faces pick up the cool sky tint
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.2
	env.glow_hdr_scale = 1.6
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.5)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.adjustment_enabled = true
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 46.0
	sun.directional_shadow_split_1 = 0.32
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.85
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.1
	sun.shadow_blur = 1.6
	sun.shadow_opacity = 0.92
	sun.light_angular_distance = 1.2
	sun.light_specular = 0.6
	add_child(sun)
	rim = DirectionalLight3D.new()
	rim.name = "CharacterRim"
	rim.shadow_enabled = false
	rim.light_cull_mask = RIM_LAYER
	rim.light_specular = 1.0
	rim.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(rim)
	_tune_shadow_quality()


func _tune_shadow_quality() -> void:
	# softer, cleaner sun shadows (Compatibility honours the atlas size + soft filter quality)
	RenderingServer.directional_shadow_atlas_set_size(2048, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)


func apply_preset(p: String) -> void:
	preset = p
	if env == null:
		_build()
	match p:
		"hub":
			# interior: warm lamps do the work; dim cool fill, little fog
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.10, 0.08, 0.08)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
			env.ambient_light_color = Color(0.62, 0.54, 0.56)
			env.ambient_light_energy = 0.42
			env.fog_light_color = Color(0.34, 0.26, 0.24)
			env.fog_density = 0.01
			env.fog_sky_affect = 0.0
			env.fog_height_density = 0.0
			env.tonemap_exposure = 1.05
			env.adjustment_saturation = 1.05
			env.adjustment_contrast = 1.06
			env.glow_intensity = 0.6
			sun.light_color = Color(1.0, 0.86, 0.66)
			sun.light_energy = 1.0
			sun.rotation_degrees = Vector3(-62, -28, 0)
			rim.light_color = Color(0.70, 0.82, 1.0)
			rim.light_energy = 0.7
			rim.rotation_degrees = Vector3(-20, 160, 0)
		"dusk":
			_apply_mood(_mix(MOODS["span"], MOODS["boss"], 0.4))
		"reaches":
			_apply_mood(MOODS["gate"])
		_:
			if MOODS.has(p):
				_apply_mood(MOODS[p])
			else:
				_apply_mood(MOODS["gate"])


## Mood for a level X position (keyframed, smooth).
static func mood_at_x(x: float) -> Dictionary:
	for i in ZONE_KEYS.size() - 1:
		var k0: Array = ZONE_KEYS[i]
		var k1: Array = ZONE_KEYS[i + 1]
		if x <= float(k1[0]) or i == ZONE_KEYS.size() - 2:
			var t := clampf((x - float(k0[0])) / maxf(float(k1[0]) - float(k0[0]), 0.001), 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			var m := _mix(MOODS[k0[1]], MOODS[k1[1]], t)
			m["zone"] = k0[1] if t < 0.5 else k1[1]
			return m
	return MOODS["gate"]


static func _mix(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var r := {}
	for k in a:
		var va: Variant = a[k]
		var vb: Variant = b.get(k, va)
		if va is Color:
			r[k] = (va as Color).lerp(vb, t)
		elif va is Vector2:
			# yaw may wrap: interpolate the short way
			var pa: Vector2 = va
			var pb: Vector2 = vb
			var dy := wrapf(pb.y - pa.y, -180.0, 180.0)
			r[k] = Vector2(lerpf(pa.x, pb.x, t), pa.y + dy * t)
		elif va is float:
			r[k] = lerpf(va, float(vb), t)
		else:
			r[k] = vb if t > 0.5 else va
	return r


func _apply_mood(m: Dictionary) -> void:
	_cur = m
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = m["amb_col"]
	env.ambient_light_energy = float(m["amb_e"]) * amb_scale
	env.ambient_light_sky_contribution = m["sky_e"]
	env.fog_light_color = m["fog_col"]
	env.fog_light_energy = 1.0
	env.fog_density = m["fog_d"]
	env.fog_sky_affect = 0.12
	env.fog_height = m["fog_h"]
	env.fog_height_density = m["fog_hd"]
	env.fog_sun_scatter = m["fog_sun"]
	env.fog_aerial_perspective = 0.25
	env.tonemap_exposure = m["exposure"]
	env.adjustment_saturation = m["sat"]
	env.adjustment_contrast = m["contrast"]
	env.glow_intensity = m["glow"]
	sun.light_color = m["sun_col"]
	sun.light_energy = float(m["sun_e"]) * sun_scale
	var sr: Vector2 = m["sun_rot"]
	sun.rotation_degrees = Vector3(sr.x, sr.y, 0)
	# rim: from behind the subject relative to the gameplay camera (camera looks -Z): light travels +Z/down,
	# skewed opposite the sun so the lit edge sits on the shadow side.
	rim.light_color = m["rim_col"]
	rim.light_energy = m["rim_e"]
	rim.rotation_degrees = Vector3(-18, sr.y + 180.0 + 35.0, 0)
	if sky_mat:
		sky_mat.set_shader_parameter("horizon_color", m["horizon"])
		sky_mat.set_shader_parameter("zenith_color", m["zenith"])
		sky_mat.set_shader_parameter("mid_color", (m["horizon"] as Color).lerp(m["zenith"], 0.55))
		sky_mat.set_shader_parameter("sun_tint", m["sun_col"])


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# focus ≈ where the camera looks at ground level (gameplay rig ~14 m away)
	var fx := cam.global_position.x - cam.global_transform.basis.z.x * 12.0
	var m := mood_at_x(fx)
	if not _cur.is_empty() and absf(float(_cur.get("sun_e", 0.0)) - float(m["sun_e"])) < 0.0005 \
			and (_cur.get("fog_col", Color()) as Color).is_equal_approx(m["fog_col"]):
		return
	current_zone = m.get("zone", "")
	_apply_mood(m)
