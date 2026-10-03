class_name CritterVFX
extends Node3D
## CRITTER VFX (Agent 1, CONTRACTS §7). One script, many presets: each `game/art/vfx/<name>.tscn` sets `preset`.
## One-shots free themselves; `rage_aura` persists until `stop()`, `psychic_bolt` never self-frees.
## Optional `setup(params)` — call before or right after adding to the tree:
##   mace_arc {angle (deg, default 120), radius (m, 2.5)}   reach_line {length (m, 6)}
##   gravity_well {radius (m, 4), duration (s, 2.5)}        capture_beam {from: Vector3, to: Vector3} (global)
##   thoughtstone_align {target: Vector3 (global point the fragment turns toward), duration (s, 4)}
##   any preset: {color: Color} tint override, {scale: float}
## All particles are CPUParticles3D (Compatibility renderer); materials are cached and shared.

const TEX_DOT := preload("res://game/art/vfx/tex/soft_dot.png")
const TEX_PUFF := preload("res://game/art/vfx/tex/puff.png")
const TEX_SPARK := preload("res://game/art/vfx/tex/spark.png")
const TEX_RING := preload("res://game/art/vfx/tex/ring.png")
const TEX_STAR := preload("res://game/art/vfx/tex/star.png")

const PSY := Color(0.66, 0.42, 1.0)
const THOUGHT := Color(0.55, 0.88, 1.0)
const EMBER := Color(1.0, 0.62, 0.25)
const DUST := Color(0.72, 0.48, 0.34)

@export var preset: String = "hit_spark"

var params: Dictionary = {}
var _started := false
var _life := 1.0
var _parts: Array = []
static var _mats: Dictionary = {}


func setup(p: Dictionary) -> void:
	params = p
	if _started:
		# re-run geometry-dependent presets
		for c in get_children():
			c.queue_free()
		_parts.clear()
		_started = false
		_start()


func _ready() -> void:
	_start()


func stop() -> void:
	for p in _parts:
		(p as CPUParticles3D).emitting = false
	var t := get_tree().create_timer(1.2)
	t.timeout.connect(queue_free)


# ------------------------------------------------------------------ helpers

static func mat(tex: Texture2D, add: bool, billboard: bool = true) -> StandardMaterial3D:
	var key := str(tex.resource_path) + str(add) + str(billboard)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_mats[key] = m
	return m


func _tint(c: Color) -> Color:
	if params.has("color"):
		var t: Color = params["color"]
		return Color(t.r, t.g, t.b, c.a)
	return c


func _sc() -> float:
	return float(params.get("scale", 1.0))


## opts: amount, life, tex, add, c0, c1, size (Vector2 min/max), vel (Vector2), dir, spread, gravity (Vector3),
## expl, box/sphere (emission), damping, radial, tangential, one_shot, local, delay
func _emit(o: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	p.mesh = q
	p.material_override = mat(o.get("tex", TEX_DOT), bool(o.get("add", true)))
	p.amount = int(o.get("amount", 12))
	p.lifetime = float(o.get("life", 0.6))
	p.one_shot = bool(o.get("one_shot", true))
	p.explosiveness = float(o.get("expl", 0.9))
	p.randomness = 0.4
	p.local_coords = bool(o.get("local", false))
	p.direction = o.get("dir", Vector3.UP)
	p.spread = float(o.get("spread", 180.0))
	var vel: Vector2 = o.get("vel", Vector2(2, 5))
	p.initial_velocity_min = vel.x * _sc()
	p.initial_velocity_max = vel.y * _sc()
	p.gravity = o.get("gravity", Vector3(0, -6, 0))
	p.damping_min = float(o.get("damping", 0.0))
	p.damping_max = float(o.get("damping", 0.0)) * 1.3
	p.radial_accel_min = float(o.get("radial", 0.0))
	p.radial_accel_max = float(o.get("radial", 0.0))
	p.tangential_accel_min = float(o.get("tangential", 0.0))
	p.tangential_accel_max = float(o.get("tangential", 0.0))
	var sz: Vector2 = o.get("size", Vector2(0.15, 0.3))
	p.scale_amount_min = sz.x * _sc()
	p.scale_amount_max = sz.y * _sc()
	var curve := Curve.new()
	if o.get("grow", false):
		curve.add_point(Vector2(0, 0.4))
		curve.add_point(Vector2(1, 1.0))
	else:
		curve.add_point(Vector2(0, 1.0))
		curve.add_point(Vector2(0.6, 0.8))
		curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var g := Gradient.new()
	var c0: Color = _tint(o.get("c0", Color(1, 1, 1, 1)))
	var c1: Color = _tint(o.get("c1", Color(1, 0.6, 0.3, 0)))
	g.set_color(0, c0)
	g.set_color(1, c1)
	p.color_ramp = g
	if o.has("sphere"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = float(o["sphere"]) * _sc()
	elif o.has("ring"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		p.emission_ring_axis = Vector3.UP
		p.emission_ring_radius = float(o["ring"]) * _sc()
		p.emission_ring_inner_radius = float(o["ring"]) * 0.85 * _sc()
		p.emission_ring_height = 0.1
	elif o.has("box"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = o["box"]
	p.position = o.get("pos", Vector3.ZERO)
	add_child(p)
	if o.has("delay"):
		p.emitting = false
		var dt := create_tween()
		dt.tween_interval(float(o["delay"]))
		dt.tween_property(p, "emitting", true, 0.0)
	else:
		p.emitting = true
	_parts.append(p)
	return p


## Flat ground ring that expands and fades.
func _ring(color: Color, r0: float, r1: float, dur: float, y: float = 0.06) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := mat(TEX_RING, true, false).duplicate() as StandardMaterial3D
	m.albedo_color = _tint(color)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = y
	mi.scale = Vector3.ONE * r0 * _sc()
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * r1 * _sc(), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	return mi


## Camera-facing flash sprite.
func _flash(color: Color, size: float, dur: float, tex: Texture2D = TEX_DOT) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	mi.mesh = q
	var m := mat(tex, true, false).duplicate() as StandardMaterial3D
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = _tint(color)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3.ONE * size * 0.4 * _sc()
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size * _sc(), dur * 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	return mi


func _glow_mat(c: Color, energy: float = 1.6) -> StandardMaterial3D:
	return ToonKit.glow(_tint(c), energy)


func _free_after(t: float) -> void:
	_life = t
	get_tree().create_timer(t).timeout.connect(queue_free)


var _align_tw: Tween


func _exit_tree() -> void:
	if _align_tw and _align_tw.is_valid():
		_align_tw.kill()


## params.target may be a Vector3 or a Node3D (re-read every step; looks at its chest height).
func _align_target() -> Vector3:
	var t: Variant = params.get("target", null)
	if t is Node3D and is_instance_valid(t):
		return (t as Node3D).global_position + Vector3(0, 1.4, 0)
	if t is Vector3:
		return t
	return global_position + Vector3(0, 1.4, -10)


func _align_step(k: float, frag: Variant) -> void:
	if not is_instance_valid(frag) or not (frag as Node3D).is_inside_tree():
		return
	var f3 := frag as Node3D
	var target := _align_target()
	if f3.global_position.distance_to(target) < 0.01:
		return
	var dir := (target - f3.global_position).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.97 else Vector3.FORWARD
	var want := f3.global_transform.looking_at(target, up).basis.get_rotation_quaternion()
	var cur := f3.global_transform.basis.get_rotation_quaternion()
	f3.global_transform.basis = Basis(cur.slerp(want, k * 0.15))


# ------------------------------------------------------------------ presets

func _start() -> void:
	if _started or not is_inside_tree():
		return
	_started = true
	var fn := "_p_" + preset
	if has_method(fn):
		call(fn)
	else:
		push_warning("CritterVFX: unknown preset " + preset)
		_free_after(0.1)


func _p_hit_spark() -> void:
	_flash(Color(1, 0.9, 0.7, 0.9), 1.1, 0.16, TEX_STAR)
	_emit({"amount": 14, "life": 0.32, "tex": TEX_SPARK, "c0": Color(1, 0.95, 0.75), "c1": Color(1, 0.45, 0.15, 0), "size": Vector2(0.1, 0.22), "vel": Vector2(4, 9), "gravity": Vector3(0, -12, 0), "expl": 1.0})
	_free_after(0.6)


func _p_heavy_impact() -> void:
	_flash(Color(1, 0.85, 0.6, 0.9), 2.6, 0.25, TEX_STAR)
	_ring(Color(1, 0.8, 0.55, 0.9), 0.4, 3.4, 0.45)
	_emit({"amount": 22, "life": 0.9, "tex": TEX_PUFF, "add": false, "c0": Color(0.78, 0.55, 0.40, 0.85), "c1": Color(0.6, 0.42, 0.34, 0), "size": Vector2(0.6, 1.1), "vel": Vector2(3, 6), "dir": Vector3(0, 0.15, 0), "spread": 90.0, "gravity": Vector3(0, 0.5, 0), "damping": 5.0, "ring": 0.5, "grow": true})
	_emit({"amount": 16, "life": 0.5, "tex": TEX_SPARK, "c0": Color(1, 0.9, 0.6), "c1": Color(1, 0.4, 0.1, 0), "size": Vector2(0.12, 0.25), "vel": Vector2(5, 10), "spread": 70.0, "gravity": Vector3(0, -14, 0)})
	_free_after(1.1)


func _p_dust_puff() -> void:
	_emit({"amount": 8, "life": 0.7, "tex": TEX_PUFF, "add": false, "c0": Color(0.80, 0.58, 0.42, 0.7), "c1": Color(0.66, 0.46, 0.36, 0), "size": Vector2(0.35, 0.7), "vel": Vector2(0.6, 1.6), "spread": 80.0, "gravity": Vector3(0, 0.4, 0), "damping": 2.0, "sphere": 0.3, "grow": true})
	_free_after(0.9)


func _p_mace_arc() -> void:
	var ang := deg_to_rad(float(params.get("angle", 120.0)))
	var r := float(params.get("radius", 2.5)) * _sc()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for i in n:
		var a0 := -ang * 0.5 + ang * float(i) / n
		var a1 := -ang * 0.5 + ang * float(i + 1) / n
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var o0 := Vector3(sin(a0), 0, -cos(a0))
		var o1 := Vector3(sin(a1), 0, -cos(a1))
		var ci := Color(1, 0.85, 0.55, 0.0)
		var co0 := Color(1, 0.9, 0.6, k0 * 0.9)
		var co1 := Color(1, 0.9, 0.6, k1 * 0.9)
		st.set_color(ci)
		st.add_vertex(o0 * r * 0.55)
		st.set_color(co0)
		st.add_vertex(o0 * r)
		st.set_color(co1)
		st.add_vertex(o1 * r)
		st.set_color(ci)
		st.add_vertex(o0 * r * 0.55)
		st.set_color(co1)
		st.add_vertex(o1 * r)
		st.set_color(ci)
		st.add_vertex(o1 * r * 0.55)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = _tint(Color(1, 0.75, 0.4, 1))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.9
	add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "rotation:y", -ang * 0.35, 0.22).from(ang * 0.35)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.28).set_ease(Tween.EASE_IN)
	_free_after(0.35)


func _p_reach_line() -> void:
	var L := float(params.get("length", 6.0))
	var st := ToonKit.begin()
	ToonKit.cylinder(st, Vector3(0, 1.0, 0), Vector3(0, 1.0, -L), 0.12, 0.05, 6, Color(1, 1, 1), false)
	var m := _glow_mat(Color(1.0, 0.72, 0.35, 0.9), 2.0)
	var mi := ToonKit.mesh_instance(st.commit(), m, "Line")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.scale = Vector3(1, 1, 0.05)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.08)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
	_emit({"amount": 10, "life": 0.4, "c0": Color(1, 0.8, 0.5), "c1": Color(1, 0.5, 0.2, 0), "size": Vector2(0.1, 0.2), "vel": Vector2(0.5, 1.5), "box": Vector3(0.1, 0.1, L * 0.5), "pos": Vector3(0, 1.0, -L * 0.5), "gravity": Vector3.ZERO})
	_free_after(0.6)


func _p_gravity_well() -> void:
	var r := float(params.get("radius", 4.0))
	var d := float(params.get("duration", 2.5))
	var ring := _ring(Color(0.62, 0.45, 1.0, 0.9), r, r * 0.92, d)
	ring.scale = Vector3.ONE * r * _sc()
	var core := _flash(Color(0.5, 0.3, 0.9, 0.8), 2.0, d)
	core.position.y = 0.8
	var p := _emit({"amount": 40, "life": 0.9, "one_shot": false, "expl": 0.0, "c0": Color(0.8, 0.65, 1.0, 0.0), "c1": Color(0.55, 0.35, 1.0, 0.9), "size": Vector2(0.12, 0.25), "vel": Vector2(0.0, 0.3), "gravity": Vector3.ZERO, "radial": -r * 2.2, "tangential": 5.0, "ring": r, "pos": Vector3(0, 0.3, 0)})
	var et := create_tween()
	et.tween_interval(d)
	et.tween_property(p, "emitting", false, 0.0)
	_free_after(d + 1.0)


func _p_rage_aura() -> void:
	_emit({"amount": 26, "life": 0.9, "one_shot": false, "expl": 0.0, "local": true, "c0": Color(1, 0.35, 0.15, 0.9), "c1": Color(0.8, 0.1, 0.05, 0), "size": Vector2(0.2, 0.45), "vel": Vector2(1.0, 2.2), "spread": 15.0, "gravity": Vector3(0, 1.5, 0), "ring": 0.9, "pos": Vector3(0, 0.2, 0)})
	_emit({"amount": 10, "life": 0.6, "one_shot": false, "expl": 0.0, "local": true, "tex": TEX_SPARK, "c0": Color(1, 0.8, 0.4), "c1": Color(1, 0.3, 0.1, 0), "size": Vector2(0.08, 0.15), "vel": Vector2(2.0, 3.5), "spread": 20.0, "gravity": Vector3.ZERO, "sphere": 0.8, "pos": Vector3(0, 1.2, 0)})


func _p_psychic_bolt() -> void:
	var orb := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.22
	s.height = 0.44
	s.radial_segments = 10
	s.rings = 5
	orb.mesh = s
	orb.material_override = _glow_mat(Color(0.8, 0.6, 1.0), 2.6)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(orb)
	var halo := _flash(Color(0.6, 0.35, 1.0, 0.7), 1.3, 9999.0)
	halo.scale = Vector3.ONE * 1.3 * _sc()
	_emit({"amount": 24, "life": 0.35, "one_shot": false, "expl": 0.0, "c0": Color(0.75, 0.55, 1.0, 0.9), "c1": Color(0.4, 0.2, 0.9, 0), "size": Vector2(0.12, 0.26), "vel": Vector2(0.0, 0.4), "gravity": Vector3.ZERO, "sphere": 0.15})


func _p_psychic_burst() -> void:
	_flash(Color(0.75, 0.55, 1.0, 0.9), 2.2, 0.3, TEX_STAR)
	_flash(Color(0.66, 0.42, 1.0, 1.0), 3.2, 0.4, TEX_RING)
	_emit({"amount": 20, "life": 0.5, "c0": Color(0.85, 0.7, 1.0), "c1": Color(0.5, 0.25, 1.0, 0), "size": Vector2(0.12, 0.25), "vel": Vector2(3, 6), "gravity": Vector3.ZERO, "damping": 6.0})
	_free_after(0.7)


func _p_false_memory_echo() -> void:
	_ring(Color(0.66, 0.42, 1.0, 0.8), 0.5, 2.2, 0.8)
	_emit({"amount": 18, "life": 0.9, "c0": Color(0.75, 0.6, 1.0, 0.9), "c1": Color(0.45, 0.3, 1.0, 0), "size": Vector2(0.12, 0.25), "vel": Vector2(0.4, 1.2), "gravity": Vector3(0, 1.0, 0), "box": Vector3(0.5, 1.0, 0.5), "pos": Vector3(0, 1.0, 0)})
	_free_after(1.1)


func _p_brain_skip_glitch() -> void:
	var st := ToonKit.begin()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 14:
		var p := Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(0.2, 2.2), rng.randf_range(-0.4, 0.4))
		ToonKit.box(st, Transform3D(Basis(), p), Vector3(rng.randf_range(0.2, 0.9), rng.randf_range(0.04, 0.14), 0.02), Color(1, 1, 1))
	var m := _glow_mat(Color(0.5, 0.95, 1.0, 0.85), 1.8)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var mi := ToonKit.mesh_instance(st.commit(), m, "Glitch")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var tw := create_tween()
	for k in 6:
		tw.tween_callback(func() -> void:
			mi.position.x = randf_range(-0.25, 0.25)
			m.albedo_color = (_tint(Color(0.5, 0.95, 1.0)) if k % 2 == 0 else _tint(Color(0.85, 0.4, 1.0))) * 1.8)
		tw.tween_interval(0.05)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.1)
	_free_after(0.45)


func _p_capture_beam() -> void:
	var a: Vector3 = params.get("from", global_position + Vector3(0, 1, 0))
	var b: Vector3 = params.get("to", global_position + Vector3(0, 1, -5))
	global_position = a
	var st := ToonKit.begin()
	ToonKit.cylinder(st, Vector3.ZERO, b - a, 0.1, 0.35, 8, Color(1, 1, 1), false)
	var m := _glow_mat(Color(0.45, 0.95, 1.0, 0.75), 1.8)
	var mi := ToonKit.mesh_instance(st.commit(), m, "Beam")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
	var tgt := _flash(Color(0.5, 1.0, 1.0, 0.9), 2.0, 0.8, TEX_STAR)
	tgt.position = b - a
	_emit({"amount": 24, "life": 0.6, "c0": Color(0.6, 1.0, 1.0), "c1": Color(0.3, 0.8, 1.0, 0), "size": Vector2(0.1, 0.22), "vel": Vector2(1, 3), "gravity": Vector3.ZERO, "radial": -6.0, "sphere": 1.0, "pos": b - a})
	_free_after(1.0)


func _p_scan_ping() -> void:
	_ring(Color(0.45, 0.95, 1.0, 1.0), 0.3, 6.0, 0.9)
	_ring(Color(0.45, 0.95, 1.0, 0.6), 0.2, 3.5, 0.7)
	_free_after(1.0)


func _p_pickup_glint() -> void:
	var f := _flash(Color(1.0, 0.9, 0.5, 1.0), 1.4, 0.5, TEX_STAR)
	f.position.y = 0.6
	_emit({"amount": 10, "life": 0.6, "tex": TEX_STAR, "c0": Color(1, 0.95, 0.6), "c1": Color(1, 0.8, 0.3, 0), "size": Vector2(0.15, 0.3), "vel": Vector2(0.8, 2.0), "gravity": Vector3(0, 1.0, 0), "sphere": 0.3, "pos": Vector3(0, 0.5, 0)})
	_free_after(0.8)


func _p_drill_sparks() -> void:
	_emit({"amount": 30, "life": 0.6, "tex": TEX_SPARK, "c0": Color(1, 0.95, 0.7), "c1": Color(1, 0.35, 0.05, 0), "size": Vector2(0.12, 0.3), "vel": Vector2(5, 11), "spread": 60.0, "gravity": Vector3(0, -15, 0)})
	_flash(Color(1, 0.7, 0.3, 0.9), 1.8, 0.2, TEX_STAR)
	_free_after(0.8)


func _p_coolant_vent() -> void:
	_emit({"amount": 30, "life": 1.3, "expl": 0.2, "tex": TEX_PUFF, "add": false, "c0": Color(0.92, 0.97, 1.0, 0.85), "c1": Color(0.75, 0.85, 0.95, 0), "size": Vector2(0.6, 1.2), "vel": Vector2(5, 8), "spread": 12.0, "gravity": Vector3(0, -1, 0), "damping": 2.5, "sphere": 0.3, "grow": true})
	_emit({"amount": 14, "life": 0.6, "c0": Color(0.7, 0.95, 1.0), "c1": Color(0.5, 0.8, 1.0, 0), "size": Vector2(0.1, 0.2), "vel": Vector2(6, 10), "spread": 20.0, "gravity": Vector3(0, -8, 0)})
	_free_after(1.7)


func _p_thoughtstone_shards() -> void:
	var st := ToonKit.begin()
	ToonKit.cylinder(st, Vector3(0, -0.5, 0), Vector3(0, 0.5, 0), 0.25, 0.0, 4, Color(0.7, 0.92, 1.0))
	ToonKit.cylinder(st, Vector3(0, -0.5, 0), Vector3(0, -0.8, 0), 0.25, 0.0, 4, Color(0.5, 0.8, 1.0))
	var p := CPUParticles3D.new()
	p.mesh = ToonKit.finish(st)
	p.material_override = _glow_mat(Color(0.55, 0.88, 1.0), 1.5)
	p.amount = 14
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 40.0
	p.initial_velocity_min = 5.0 * _sc()
	p.initial_velocity_max = 9.0 * _sc()
	p.gravity = Vector3(0, -16, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.4 * _sc()
	p.scale_amount_max = 0.9 * _sc()
	add_child(p)
	p.emitting = true
	_flash(Color(0.6, 0.9, 1.0, 1.0), 3.0, 0.35, TEX_STAR)
	_emit({"amount": 20, "life": 0.8, "tex": TEX_PUFF, "add": false, "c0": Color(0.72, 0.5, 0.42, 0.8), "c1": Color(0.6, 0.45, 0.4, 0), "size": Vector2(0.6, 1.2), "vel": Vector2(1.5, 4), "gravity": Vector3(0, 0.5, 0), "damping": 3.0, "sphere": 1.2, "grow": true})
	_free_after(1.4)


func _p_boss_explosion() -> void:
	_flash(Color(1, 0.85, 0.55, 1.0), 14.0, 0.6, TEX_STAR)
	_ring(Color(1, 0.7, 0.4, 1.0), 1.0, 16.0, 0.9)
	_emit({"amount": 36, "life": 1.4, "tex": TEX_PUFF, "c0": Color(1, 0.75, 0.35, 1.0), "c1": Color(0.7, 0.2, 0.08, 0), "size": Vector2(2.0, 4.0), "vel": Vector2(4, 10), "gravity": Vector3(0, 2, 0), "damping": 3.0, "sphere": 2.5, "pos": Vector3(0, 3, 0), "grow": true})
	_emit({"amount": 30, "life": 2.4, "expl": 0.6, "tex": TEX_PUFF, "add": false, "c0": Color(0.32, 0.26, 0.26, 0.85), "c1": Color(0.25, 0.2, 0.2, 0), "size": Vector2(2.5, 5.0), "vel": Vector2(2, 6), "gravity": Vector3(0, 2.5, 0), "damping": 1.5, "sphere": 3.0, "pos": Vector3(0, 4, 0), "grow": true, "delay": 0.2})
	_emit({"amount": 40, "life": 1.2, "tex": TEX_SPARK, "c0": Color(1, 0.95, 0.7), "c1": Color(1, 0.4, 0.1, 0), "size": Vector2(0.3, 0.6), "vel": Vector2(10, 20), "gravity": Vector3(0, -14, 0), "pos": Vector3(0, 3, 0)})
	_free_after(3.0)


func _p_leap_trail() -> void:
	_emit({"amount": 18, "life": 0.5, "expl": 0.3, "c0": Color(0.75, 0.95, 0.55, 0.9), "c1": Color(0.4, 0.8, 0.5, 0), "size": Vector2(0.15, 0.3), "vel": Vector2(0.2, 0.8), "gravity": Vector3.ZERO, "sphere": 0.5, "pos": Vector3(0, 1.0, 0)})
	_free_after(0.8)


func _p_rope_unroll() -> void:
	_emit({"amount": 16, "life": 0.9, "tex": TEX_PUFF, "add": false, "c0": Color(0.82, 0.62, 0.45, 0.7), "c1": Color(0.7, 0.5, 0.38, 0), "size": Vector2(0.4, 0.8), "vel": Vector2(0.5, 1.5), "gravity": Vector3(0, 0.3, 0), "damping": 2.0, "box": Vector3(1.4, 0.1, 0.4), "grow": true})
	_emit({"amount": 12, "life": 0.8, "tex": TEX_SPARK, "add": false, "c0": Color(0.86, 0.72, 0.46, 1.0), "c1": Color(0.7, 0.55, 0.35, 0), "size": Vector2(0.08, 0.16), "vel": Vector2(1.0, 3.0), "gravity": Vector3(0, -6, 0), "box": Vector3(1.2, 0.1, 0.3)})
	_free_after(1.1)


func _p_heal_motes() -> void:
	_emit({"amount": 20, "life": 1.1, "expl": 0.3, "tex": TEX_STAR, "c0": Color(0.7, 1.0, 0.6, 1.0), "c1": Color(0.4, 0.9, 0.5, 0), "size": Vector2(0.14, 0.28), "vel": Vector2(0.5, 1.4), "spread": 25.0, "gravity": Vector3(0, 0.8, 0), "ring": 0.7, "pos": Vector3(0, 0.3, 0)})
	_free_after(1.5)


## The ending hook: a Thoughtstone fragment rises, glows, and slowly turns to point at `target`.
func _p_thoughtstone_align() -> void:
	var dur := float(params.get("duration", 4.0))
	var frag := Node3D.new()
	frag.name = "Fragment"
	add_child(frag)
	var st := ToonKit.begin()
	ToonKit.cylinder(st, Vector3(0, 0, 0.0), Vector3(0, 0, -0.55), 0.18, 0.0, 5, Color(1, 1, 1))
	ToonKit.cylinder(st, Vector3(0, 0, 0.0), Vector3(0, 0, 0.3), 0.18, 0.0, 5, Color(1, 1, 1))
	var m := _glow_mat(Color(0.55, 0.88, 1.0), 1.8)
	var mi := ToonKit.mesh_instance(st.commit(), m, "Crystal")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frag.add_child(mi)
	var halo := _flash(Color(0.5, 0.85, 1.0, 0.6), 1.6, dur)
	halo.reparent(frag, false)
	frag.position = Vector3(0, 0.6, 0)
	frag.rotation = Vector3(0.4, randf() * TAU, 0.3)
	_align_tw = create_tween()
	var tw := _align_tw
	tw.tween_property(frag, "position:y", 1.4, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_align_step.bind(frag), 0.0, 1.0, dur * 0.6)
	tw.tween_property(m, "albedo_color", _tint(Color(0.7, 0.95, 1.0)) * 3.0, 0.3)
	tw.tween_property(m, "albedo_color", _tint(Color(0.55, 0.88, 1.0)) * 1.8, 0.6)
	_emit({"amount": 16, "life": 1.2, "one_shot": false, "expl": 0.0, "tex": TEX_STAR, "c0": Color(0.7, 0.95, 1.0, 0.9), "c1": Color(0.5, 0.8, 1.0, 0), "size": Vector2(0.06, 0.14), "vel": Vector2(0.1, 0.4), "gravity": Vector3(0, 0.3, 0), "sphere": 0.6, "pos": Vector3(0, 1.4, 0)})
	if not params.get("persist", false):
		_free_after(dur + 0.6)
