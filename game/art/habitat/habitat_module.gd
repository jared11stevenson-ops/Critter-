class_name HabitatModule
extends Node3D
## Habitat module visual (Agent 1, CONTRACTS §6). One script, `module_id` picks the build.
## Origin = the slot marker it is placed on (ground level / ceiling mount for climate modules).
## API: set_active(on) (idle animation + glow), set_stress(v 0..1) (flicker / wilt tint).

@export var module_id: String = "reach_soil_bed"

const SOIL := Color(0.62, 0.28, 0.18)
const SOIL_LIGHT := Color(0.78, 0.42, 0.26)
const LICHEN := Color(0.74, 0.78, 0.42)
const LICHEN_DARK := Color(0.46, 0.56, 0.32)
const MOSS := Color(0.36, 0.56, 0.30)
const BRASS := Color(0.72, 0.56, 0.32)
const METAL := Color(0.40, 0.42, 0.46)
const STONE := Color(0.66, 0.50, 0.40)

var glow: MeshInstance3D
var glow_mat: StandardMaterial3D
var mat: ShaderMaterial
var particles: CPUParticles3D
var _active := true
var _stress := 0.0
var _t := 0.0
var _base_glow := Color(1, 1, 1)


func _ready() -> void:
	mat = ToonKit.material({"outline": 0.03, "unique": true})
	var st := ToonKit.begin()
	var gst := ToonKit.begin()
	var has_glow := false
	match module_id:
		"reach_soil_bed":
			_soil(st, SOIL, SOIL_LIGHT, 1)
		"moss_bed":
			_soil(st, Color(0.42, 0.30, 0.22), Color(0.5, 0.36, 0.26), 2)
			for i in 14:
				var a := float(i) * 2.4
				var r := 0.4 + fmod(float(i) * 0.37, 1.0) * 1.3
				ToonKit.rock(st, Vector3(cos(a) * r * 1.3, 0.32, sin(a) * r * 0.8), Vector3(0.38, 0.18, 0.34), MOSS.lightened(0.08 * float(i % 3)), i, 1)
		"lichen_mat":
			for i in 16:
				var a := float(i) * 2.1
				var r := 0.3 + fmod(float(i) * 0.53, 1.0) * 1.2
				var c := LICHEN if i % 3 else LICHEN_DARK
				ToonKit.rock(st, Vector3(cos(a) * r, 0.04, sin(a) * r * 0.8), Vector3(0.32, 0.06, 0.28), c, i + 20, 1)
				if i % 4 == 0:
					ToonKit.cylinder(st, Vector3(cos(a) * r, 0.05, sin(a) * r * 0.8), Vector3(cos(a) * r, 0.22, sin(a) * r * 0.8), 0.03, 0.06, 5, Color(0.9, 0.82, 0.5))
		"heat_lamp":
			has_glow = true
			_hanger(st)
			ToonKit.cylinder(st, Vector3(0, -0.6, 0), Vector3(0, -1.1, 0), 0.18, 0.55, 10, METAL, false)
			ToonKit.torus(st, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, -1.1, 0)), 0.55, 0.04, 14, 4, BRASS)
			ToonKit.rock(gst, Vector3(0, -0.95, 0), Vector3(0.24, 0.2, 0.24), Color(1, 1, 1), 1, 1)
			_cone(gst, Vector3(0, -1.1, 0), 0.5, 2.6, 2.4)
			_base_glow = Color(1.0, 0.55, 0.22)
		"lumen_lamp":
			has_glow = true
			_hanger(st)
			for k in 3:
				var a := TAU * k / 3.0
				ToonKit.cylinder(st, Vector3(0, -0.6, 0), Vector3(cos(a) * 0.35, -1.25, sin(a) * 0.35), 0.03, 0.03, 4, BRASS, false)
			ToonKit.rock(gst, Vector3(0, -1.0, 0), Vector3(0.3, 0.32, 0.3), Color(1, 1, 1), 2, 1)
			_cone(gst, Vector3(0, -1.0, 0), 0.3, 3.0, 2.8)
			_base_glow = Color(0.65, 0.85, 1.0)
		"humidity_mister":
			_hanger(st)
			ToonKit.cylinder(st, Vector3(-1.2, -0.6, 0), Vector3(1.2, -0.6, 0), 0.07, 0.07, 6, METAL)
			for k in 3:
				var x := -0.9 + k * 0.9
				ToonKit.cylinder(st, Vector3(x, -0.6, 0), Vector3(x, -0.85, 0), 0.06, 0.1, 6, BRASS)
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, -0.45, 0)), Vector3(0.6, 0.3, 0.4), METAL.darkened(0.2))
			particles = _mist()
		"scale_anchor":
			ToonKit.cylinder(st, Vector3(0, 0, 0), Vector3(0, 0.25, 0), 0.6, 0.55, 10, METAL.darkened(0.2))
			ToonKit.cylinder(st, Vector3(0, 0.25, 0), Vector3(0, 1.5, 0), 0.1, 0.08, 6, BRASS)
			for s: float in [-1.0, 1.0]:
				ToonKit.cylinder(st, Vector3(0, 1.5, 0), Vector3(s * 0.35, 1.8, 0), 0.07, 0.07, 5, BRASS)
				ToonKit.cylinder(st, Vector3(s * 0.35, 1.8, 0), Vector3(s * 0.35, 2.6, 0), 0.07, 0.05, 5, BRASS)
			for k in 3:
				ToonKit.torus(st, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.5 + k * 0.32, 0)), 0.22 - k * 0.03, 0.035, 12, 4, BRASS.lightened(0.15))
			has_glow = true
			ToonKit.rock(gst, Vector3(0, 2.2, 0), Vector3(0.09, 0.09, 0.09), Color(1, 1, 1), 3, 1)
			_base_glow = Color(1.0, 0.85, 0.5)
		"thoughtstone_pedestal":
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.15, 0)), Vector3(1.1, 0.3, 1.1), STONE.darkened(0.1))
			ToonKit.cylinder(st, Vector3(0, 0.3, 0), Vector3(0, 1.0, 0), 0.32, 0.26, 8, STONE)
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, 1.05, 0)), Vector3(0.8, 0.12, 0.8), STONE.lightened(0.1))
			has_glow = true
			ToonKit.cylinder(gst, Vector3(0, 1.1, 0), Vector3(0.05, 1.75, 0.02), 0.16, 0.0, 5, Color(1, 1, 1))
			ToonKit.cylinder(gst, Vector3(0.18, 1.1, 0.05), Vector3(0.3, 1.45, 0.08), 0.08, 0.0, 4, Color(1, 1, 1))
			ToonKit.cylinder(gst, Vector3(-0.15, 1.1, -0.06), Vector3(-0.28, 1.4, -0.1), 0.07, 0.0, 4, Color(1, 1, 1))
			_base_glow = Color(0.55, 0.88, 1.0)
		"burden_bridge":
			# miniature Spanwright arch, braced (the Ochre Span lesson, kept in the habitat)
			var n := 10
			for i in n:
				var t0 := float(i) / n
				var t1 := float(i + 1) / n
				var p0 := Vector3(-1.4 + 2.8 * t0, 0.3 + sin(t0 * PI) * 0.6, 0)
				var p1 := Vector3(-1.4 + 2.8 * t1, 0.3 + sin(t1 * PI) * 0.6, 0)
				ToonKit.box(st, Transform3D(Basis(Vector3.BACK, atan2(p1.y - p0.y, p1.x - p0.x)), (p0 + p1) * 0.5), Vector3(0.3, 0.16, 0.8), STONE.lerp(Color(0.84, 0.58, 0.32), float(i % 2) * 0.4))
			for s: float in [-1.0, 1.0]:
				ToonKit.box(st, Transform3D(Basis(), Vector3(s * 1.45, 0.2, 0)), Vector3(0.45, 0.4, 1.0), STONE.darkened(0.1))
				ToonKit.cylinder(st, Vector3(s * 1.2, 0.4, 0.45), Vector3(s * 0.3, 0.85, 0.45), 0.04, 0.04, 4, Color(0.5, 0.34, 0.22))
				ToonKit.cylinder(st, Vector3(s * 1.2, 0.4, -0.45), Vector3(s * 0.3, 0.85, -0.45), 0.04, 0.04, 4, Color(0.5, 0.34, 0.22))
			has_glow = true
			ToonKit.box(gst, Transform3D(Basis(), Vector3(0, 0.98, 0.42)), Vector3(0.6, 0.04, 0.02), Color(1, 1, 1))
			_base_glow = Color(1.0, 0.75, 0.4)
		_:
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(0.5, 0.5, 0.5), Color(1, 0, 1))
	var mi := ToonKit.mesh_instance(ToonKit.finish(st), mat, "Mesh")
	add_child(mi)
	if has_glow:
		glow_mat = StandardMaterial3D.new()
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.vertex_color_use_as_albedo = true
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		glow_mat.albedo_color = _base_glow * 1.6
		glow = ToonKit.mesh_instance(gst.commit(), glow_mat, "Glow")
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(glow)


func _soil(st: SurfaceTool, a: Color, b: Color, seed_v: int) -> void:
	ToonKit.rock(st, Vector3(0, 0.1, 0), Vector3(2.2, 0.4, 1.6), a, seed_v, 2)
	for i in 6:
		var ang := float(i) * 1.1 + seed_v
		ToonKit.rock(st, Vector3(cos(ang) * 1.5, 0.05, sin(ang) * 1.0), Vector3(0.3, 0.18, 0.26), b, seed_v * 10 + i, 0)


func _hanger(st: SurfaceTool) -> void:
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, -0.05, 0)), Vector3(0.5, 0.1, 0.5), METAL.darkened(0.2))
	ToonKit.cylinder(st, Vector3(0, -0.05, 0), Vector3(0, -0.6, 0), 0.04, 0.04, 5, METAL, false)


## Soft additive light cone (vertex alpha fades to the floor).
func _cone(gst: SurfaceTool, top: Vector3, r0: float, r1: float, h: float) -> void:
	var n := 16
	for i in n:
		var a0 := TAU * float(i) / n
		var a1 := TAU * float(i + 1) / n
		var p0 := top + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p1 := top + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var q0 := top + Vector3(cos(a0) * r1, -h, sin(a0) * r1)
		var q1 := top + Vector3(cos(a1) * r1, -h, sin(a1) * r1)
		var ct := Color(0.35, 0.35, 0.35, 0.35)
		var cb := Color(0.0, 0.0, 0.0, 0.0)
		gst.set_color(ct)
		gst.add_vertex(p0)
		gst.add_vertex(p1)
		gst.set_color(cb)
		gst.add_vertex(q1)
		gst.set_color(ct)
		gst.add_vertex(p0)
		gst.set_color(cb)
		gst.add_vertex(q1)
		gst.add_vertex(q0)


func _mist() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	p.mesh = q
	p.material_override = CritterVFX.mat(load("res://game/art/vfx/tex/puff.png"), false)
	p.amount = 24
	p.lifetime = 1.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.0, 0.05, 0.1)
	p.position = Vector3(0, -0.9, 0)
	p.direction = Vector3.DOWN
	p.spread = 25.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.8
	p.gravity = Vector3(0, -0.2, 0)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 0.97, 1.0, 0.45))
	g.set_color(1, Color(0.85, 0.95, 1.0, 0.0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	return p


func set_active(on: bool) -> void:
	_active = on
	if particles:
		particles.emitting = on
	if glow:
		glow.visible = on


func set_stress(v: float) -> void:
	_stress = clampf(v, 0.0, 1.0)
	if mat:
		mat.set_shader_parameter("albedo", Color(1, 1, 1).lerp(Color(0.75, 0.68, 0.62), _stress))


func _process(delta: float) -> void:
	_t += delta
	if glow and _active:
		var k := 1.5 + 0.2 * sin(_t * 2.0)
		if _stress > 0.3 and fmod(_t * 7.3, 1.0) < _stress * 0.4:
			k *= 0.3
		glow_mat.albedo_color = Color(_base_glow.r * k, _base_glow.g * k, _base_glow.b * k, 1.0)
