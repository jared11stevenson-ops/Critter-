extends RefCounted
## Neutral lookdev stage + the golden-hour / teal-shade lighting rig (ART_BIBLE section 1: low golden sun, cool teal shade,
## warm fog gradient). Used by the turnaround scene and the sheet tool; BoutScene may copy the numbers.

static func build(parent: Node, _bg: Color = Color.BLACK) -> Dictionary:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.14, 0.27, 0.33)          # deep teal
	sm.sky_horizon_color = Color(0.82, 0.62, 0.40)      # dusk gold
	sm.ground_horizon_color = Color(0.82, 0.62, 0.40)
	sm.ground_bottom_color = Color(0.24, 0.20, 0.18)
	sm.sky_curve = 0.18
	sky.sky_material = sm
	e.sky = sky
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.38, 0.62, 0.70)   # deep teal shade
	e.ambient_light_energy = 0.75
	e.fog_enabled = false
	e.fog_light_color = Color(0.74, 0.62, 0.42)       # warm grey-gold
	e.fog_density = 0.006
	env.environment = e
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.84, 0.62)          # golden hour
	sun.light_energy = 0.9
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-28, 50, 0)
	parent.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 28.0
	parent.add_child(cam)
	cam.current = true
	# ground: dusk-gold ash disc (calmer than the characters)
	var ground := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 40.0; cyl.bottom_radius = 40.0; cyl.height = 0.1; cyl.radial_segments = 48
	ground.mesh = cyl
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.46, 0.38, 0.30)
	gm.roughness = 1.0
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	ground.material_override = gm
	ground.position = Vector3(0, -0.05, 0)
	parent.add_child(ground)
	return {"cam": cam, "sun": sun, "env": e, "ground": ground}

## Lookdev-only contact shadow (a dark soft ellipse). Characters themselves stay shadow-free to keep the draw budget.
static func blob_shadow(rig: Node3D, radius: float = 0.9) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.0, radius * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, depth_draw_never, shadows_disabled;\nvoid fragment(){ float d = length(UV - 0.5) * 2.0; ALBEDO = vec3(0.05, 0.04, 0.06); ALPHA = smoothstep(1.0, 0.2, d) * 0.45; }\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = Vector3(0, 0.01, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.add_child(mi)
	return mi
