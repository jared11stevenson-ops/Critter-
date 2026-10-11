extends RefCounted
## Neutral lookdev stage + the golden-hour / teal-shade lighting rig (ART_BIBLE section 1: low golden sun, cool teal shade,
## warm fog gradient). Used by the turnaround scene and the sheet tool; BoutScene may copy the numbers.

static func build(parent: Node, bg: Color = Color(0.36, 0.40, 0.42)) -> Dictionary:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
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
	cyl.top_radius = 9.0; cyl.bottom_radius = 9.0; cyl.height = 0.1; cyl.radial_segments = 48
	ground.mesh = cyl
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.50, 0.44, 0.36)
	gm.roughness = 1.0
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	ground.material_override = gm
	ground.position = Vector3(0, -0.05, 0)
	parent.add_child(ground)
	return {"cam": cam, "sun": sun, "env": e, "ground": ground}
