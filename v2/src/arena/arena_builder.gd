class_name ArenaBuilder extends RefCounted
## Builds the 3D arena for a bout from an ArenaDef (sim plane x,y -> world x,z): ring platform with an edge/pit for
## ring-outs, golden-hour sun + teal shade, fog, procedural sky and a colossal-ruin backdrop (ART_BIBLE 1, 3).
## Everything static is merged into three meshes (set, backdrop, glow) so the whole arena stays <= 12 draw calls.

const STONE := Color(0.50, 0.44, 0.38)
const STONE_DK := Color(0.36, 0.31, 0.28)
const STONE_LT := Color(0.62, 0.55, 0.46)
const BONE := Color(0.72, 0.66, 0.54)
const RUST := Color(0.55, 0.34, 0.24)
const TEAL_DK := Color(0.16, 0.26, 0.30)
const GOLD := Color(0.95, 0.72, 0.30)
const FOG := Color(0.74, 0.62, 0.42)

static func build(parent: Node3D, adef: ArenaDef, shadows := false) -> Dictionary:
	var out := {}
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.13, 0.26, 0.32)
	sm.sky_horizon_color = Color(0.86, 0.64, 0.40)
	sm.ground_horizon_color = Color(0.80, 0.62, 0.42)
	sm.ground_bottom_color = Color(0.30, 0.26, 0.22)
	sm.sky_curve = 0.2
	sky.sky_material = sm
	e.sky = sky
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.38, 0.62, 0.70)
	e.ambient_light_energy = 0.75
	e.fog_enabled = true
	e.fog_light_color = FOG
	e.fog_density = 0.0065
	e.fog_sky_affect = 0.4
	env.environment = e
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.84, 0.62)
	sun.light_energy = 0.95
	sun.rotation_degrees = Vector3(-26, 215, 0)     # low sun from the far side: rim light on the fighters, long shade
	sun.shadow_enabled = shadows
	sun.directional_shadow_max_distance = 28.0
	parent.add_child(sun)
	out["env"] = e
	out["sun"] = sun
	var mat := MeshKit.vertex_color_material()
	var set_kit := MeshKit.new()
	_platform(set_kit, adef)
	parent.add_child(set_kit.build(mat))
	out["set_tris"] = set_kit.tris
	var far_kit := MeshKit.new()
	_backdrop(far_kit)
	var far := far_kit.build(mat)
	parent.add_child(far)
	out["far_tris"] = far_kit.tris
	_sun_disc(parent, sun)
	parent.add_child(_motes())
	return out

# ------------------------------------------------------------------ platform
static func _platform(k: MeshKit, a: ArenaDef) -> void:
	if a.shape == "circle":
		var r := a.radius
		var bands := [0.30, 0.62, 0.86, 1.0]
		var cols := [STONE_LT, STONE, STONE_LT, STONE]
		var r0 := 0.0
		for i in bands.size():
			var r1: float = r * float(bands[i])
			k.ring_band(Vector3(0, 0.0, 0), r0, r1, 56, k.jitter(cols[i], 0.0))
			r0 = r1
		k.ring_band(Vector3(0, 0.01, 0), r * 0.30 - 0.12, r * 0.30, 56, GOLD)     # center sigil ring
		k.ring_band(Vector3(0, 0.01, 0), r * 0.62 - 0.07, r * 0.62, 56, STONE_DK)
		for i in 8:                                                               # spokes
			var ang := TAU * float(i) / 8.0
			k.box(Vector3(cos(ang) * r * 0.46, 0.012, sin(ang) * r * 0.46), Vector3(r * 0.32, 0.01, 0.14), STONE_DK, -rad_to_deg(ang))
		k.cyl(Vector3(0, -0.7, 0), r, r, 0.7, 56, STONE_DK, false)
		k.cyl(Vector3(0, -12.0, 0), r * 0.35, r, 11.3, 28, TEAL_DK, false)
		_circle_edges(k, a)
	else:
		var hx := a.half.x
		var hz := a.half.y
		var nx := maxi(2, int(round(hx * 2.0 / 4.0)))
		for i in nx:
			var x0 := -hx + 2.0 * hx * float(i) / float(nx)
			var x1 := -hx + 2.0 * hx * float(i + 1) / float(nx)
			var c := STONE_LT if i % 2 == 0 else STONE
			k.quad(Vector3(x0, 0, -hz), Vector3(x0, 0, hz), Vector3(x1, 0, hz), Vector3(x1, 0, -hz), c)
		k.box(Vector3(0, -0.35, 0), Vector3(hx * 2.0, 0.7, hz * 2.0), STONE_DK)
		k.box(Vector3(0, -6.5, 0), Vector3(hx * 1.4, 11.0, hz * 1.4), TEAL_DK)
		for side in ["n", "s", "e", "w"]:
			_rect_edge(k, a, side)
	for hz2 in a.hazards:
		_hazard(k, hz2)

static func _circle_edges(k: MeshKit, a: ArenaDef) -> void:
	var r := a.radius
	var segs := 48
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var mid := rad_to_deg((a0 + a1) * 0.5)
		var wall := a.edge_type(Vector2(cos(deg_to_rad(mid)), sin(deg_to_rad(mid))) * r) == "wall"
		if wall:
			var am := (a0 + a1) * 0.5
			var len := r * (a1 - a0) * 1.02
			k.box(Vector3(cos(am) * (r + 0.1), 0.45, sin(am) * (r + 0.1)), Vector3(len, 0.9 + (0.25 if i % 3 == 0 else 0.0), 0.55), k.jitter(STONE_LT, 0.04), -rad_to_deg(am) + 90.0)
		else:
			k.ring_band(Vector3(0, 0.012, 0), r - 0.34, r - 0.18, 2, GOLD, a0, a1)
			if i % 4 == 0:                                                         # rubble chips at the lip
				var am2 := (a0 + a1) * 0.5
				k.box(Vector3(cos(am2) * (r - 0.05), -0.12, sin(am2) * (r - 0.05)), Vector3(0.5, 0.3, 0.4), STONE_DK, -rad_to_deg(am2), 0, 12)

static func _rect_edge(k: MeshKit, a: ArenaDef, side: String) -> void:
	var hx := a.half.x
	var hz := a.half.y
	var horiz := side == "n" or side == "s"
	var sgn := 1.0 if (side == "s" or side == "e") else -1.0
	var wall: bool = str(a.sides[side]) == "wall"
	var length := hx * 2.0 if horiz else hz * 2.0
	var centre := Vector3(0, 0, sgn * hz) if horiz else Vector3(sgn * hx, 0, 0)
	var size := Vector3(length, 0.95, 0.55) if horiz else Vector3(0.55, 0.95, length)
	if wall:
		k.box(centre + Vector3(0, 0.47, 0) + (Vector3(0, 0, sgn * 0.1) if horiz else Vector3(sgn * 0.1, 0, 0)), size, STONE_LT)
		for i in int(length / 3.0):                                               # crenellations
			var t := -length * 0.5 + 1.5 + 3.0 * float(i)
			var p := centre + (Vector3(t, 1.15, 0) if horiz else Vector3(0, 1.15, t))
			k.box(p, Vector3(0.7, 0.5, 0.7), STONE)
	else:
		var s2 := Vector3(length, 0.012, 0.18) if horiz else Vector3(0.18, 0.012, length)
		k.box(centre - (Vector3(0, 0, sgn * 0.3) if horiz else Vector3(sgn * 0.3, 0, 0)) + Vector3(0, 0.01, 0), s2, GOLD)

static func _hazard(k: MeshKit, hz: Dictionary) -> void:
	var c := Vector3(float(hz["pos"][0]), 0.03, float(hz["pos"][1]))
	var col := Color(0.55, 0.95, 0.35) if str(hz.get("kind", "dps")) != "pulse" else Color(0.9, 0.4, 0.8)
	if str(hz.get("shape", "circle")) == "circle":
		k.ring_band(c, 0.0, float(hz.get("radius", 1.0)), 28, col.darkened(0.25))
		k.ring_band(c + Vector3(0, 0.01, 0), float(hz.get("radius", 1.0)) - 0.15, float(hz.get("radius", 1.0)), 28, col)
	else:
		var h: Array = hz.get("half", [1.0, 1.0])
		k.box(c, Vector3(float(h[0]) * 2.0, 0.02, float(h[1]) * 2.0), col.darkened(0.25))

# ------------------------------------------------------------------ backdrop: colossal ruins
static func _far(c: Color, d: float) -> Color:
	return c.darkened(0.12).lerp(TEAL_DK, 0.25).lerp(FOG, clampf(d / 420.0, 0.0, 0.3))

static func _backdrop(k: MeshKit) -> void:
	# hero landmark: a broken colossal arch behind the +x side
	k.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(78, -6, -6))
	var ar := 30.0
	k.cyl(Vector3(-ar, 0, 0), 8.0, 7.0, 34.0, 10, _far(RUST, 78))
	k.cyl(Vector3(ar, 0, 0), 8.0, 6.0, 18.0, 10, _far(RUST, 78))                  # right pillar snapped off
	k.arch(Vector3(0, 34, 0), ar, 6.0, 10.0, 90.0, 180.0, 9, _far(STONE, 78))
	k.arch(Vector3(0, 34, 0), ar, 6.0, 10.0, 20.0, 52.0, 4, _far(STONE, 78))      # the right half is broken away
	k.box(Vector3(ar + 10, 2, 8), Vector3(10, 5, 8), _far(STONE_DK, 78), 20, 0, 8)
	k.box(Vector3(ar + 20, 1, -10), Vector3(7, 3, 6), _far(STONE_DK, 78), -30, 8, 0)
	k.xf = Transform3D.IDENTITY
	# hollow robed statue, west-north
	k.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(-20.0)), Vector3(-70, -8, 52))
	k.cyl(Vector3(0, 0, 0), 15.0, 6.0, 52.0, 10, _far(BONE.darkened(0.2), 120))
	k.box(Vector3(0, 46, 0), Vector3(30, 7, 12), _far(BONE.darkened(0.2), 120))
	k.blob(Vector3(0, 62, 0), Vector3(7.5, 9, 7.5), _far(BONE.darkened(0.1), 120), 8, 6)
	k.box(Vector3(-18, 36, 3), Vector3(6, 24, 6), _far(BONE.darkened(0.25), 120), 0, 0, 14)
	k.xf = Transform3D.IDENTITY
	# broken bridge on the far left
	k.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(35.0)), Vector3(-24, 0, -84))
	for i in 3:
		k.cyl(Vector3(-40 + 26 * i, -12, 0), 5.0, 4.0, 52.0 - 4.0 * i, 8, _far(STONE_DK, 115))
	k.box(Vector3(-22, 36, 0), Vector3(60, 3.0, 10), _far(STONE, 115))
	k.box(Vector3(36, 33, 0), Vector3(26, 3.0, 10), _far(STONE, 115), 0, 0, -6)
	k.xf = Transform3D.IDENTITY
	# cathedral-sized spiral shell, south-east
	k.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(200.0)), Vector3(52, -4, 74))
	for i in 5:
		var s := 22.0 - 3.6 * float(i)
		k.blob(Vector3(0, 14 + 6 * i, 0) + Vector3(cos(i * 1.2), 0, sin(i * 1.2)) * 2.0, Vector3(s, s * 0.8, s), _far(BONE.lerp(RUST, 0.25), 125), 10, 6)
	k.xf = Transform3D.IDENTITY
	# distant spires + floating islands ring
	for i in 22:
		var ang := TAU * float(i) / 22.0 + 0.2
		var dist := 150.0 + 40.0 * sin(float(i) * 2.3)
		var h := 40.0 + 55.0 * absf(sin(float(i) * 1.7))
		k.cyl(Vector3(cos(ang) * dist, -10, sin(ang) * dist), 14.0 + 6.0 * sin(float(i)), 2.0, h, 7, _far(STONE_DK.lerp(TEAL_DK, 0.4), dist))
	for i in 14:
		var ang2 := TAU * float(i) / 14.0 + 0.5
		var d2 := 55.0 + 30.0 * absf(sin(float(i) * 3.1))
		var p := Vector3(cos(ang2) * d2, 14.0 + 22.0 * absf(sin(float(i) * 1.3)), sin(ang2) * d2)
		k.blob(p, Vector3(5.0, 2.2, 5.0), _far(STONE, d2), 7, 4)
		k.cyl(p + Vector3(0, -6.0, 0), 0.5, 3.8, 6.0, 6, _far(STONE_DK, d2), false)
	# the mist floor far below the platform
	k.cyl(Vector3(0, -14, 0), 260.0, 260.0, 0.1, 24, Color(0.50, 0.50, 0.46), true, false)

static func _sun_disc(parent: Node3D, sun: DirectionalLight3D) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(120, 120)
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, fog_disabled, blend_add, depth_draw_never, cull_disabled;\nvoid fragment(){ float d = length(UV - 0.5) * 2.0; float core = smoothstep(0.22, 0.12, d); float halo = smoothstep(1.0, 0.0, d); ALBEDO = vec3(1.0, 0.82, 0.55) * (core * 1.4 + halo * halo * 0.55); ALPHA = 1.0; }\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dir := sun.transform.basis.z.normalized()              # toward the sun
	mi.position = dir * 300.0 + Vector3(0, 10, 0)
	mi.look_at_from_position(mi.position, Vector3(0, 5, 0), Vector3.UP)
	parent.add_child(mi)

static func _motes() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 36
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(14, 4, 14)
	p.position = Vector3(0, 3.5, 0)
	p.direction = Vector3(0.4, 0.2, 0.1)
	p.spread = 40.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.5
	p.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.86, 0.55, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	p.mesh = q
	return p
