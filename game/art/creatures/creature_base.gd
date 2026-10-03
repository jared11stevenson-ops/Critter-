class_name CritterCreature
extends Node3D
## Base for procedural low-poly toon creatures (Agent 1, CONTRACTS §5).
## Each species script overrides `_build_body(st, glow)` (adds geometry to the merged toon mesh and the
## optional glow mesh) and tunes the exported numbers. One merged mesh (+ ink outline pass) per creature,
## legs animated in the vertex shader (UV2 = leg phase / weight), so a swarm stays cheap.
## The model faces -Z (Godot forward); `set_facing` turns the Body.

@export var radius: float = 1.0
@export var hover_height: float = 0.0
@export var gait_speed: float = 2.2         # cycles per second at move_amount 1
@export var gait_stride: float = 0.25       # leg swing in meters at move_amount 1
@export var bob_amount: float = 0.04
@export var outline_width: float = 0.03
@export var turn_speed: float = 10.0

var body: Node3D          # yaw + attack offsets
var pose: Node3D          # bob / squash / tilt
var mesh: MeshInstance3D
var glow_mesh: MeshInstance3D
var shadow: MeshInstance3D
var mat: ShaderMaterial
var glow_mat: StandardMaterial3D
var ghost_mat: StandardMaterial3D

var _move := 0.0
var _phase := 0.0
var _yaw := 0.0
var _target_yaw := 0.0
var _flash := 0.0
var _telegraph := 0.0
var _telegraph_total := 0.0
var _dead := false
var _ghost := 0.0
var _t := 0.0
var _built := false
var _tw: Tween


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	pose = Node3D.new()
	pose.name = "Pose"
	pose.position.y = hover_height
	body.add_child(pose)
	mat = ToonKit.material({"outline": outline_width, "unique": true, "rim": 0.35, "grain": 0.14})
	mat.set_shader_parameter("occlude", 0.0)
	(mat.next_pass as ShaderMaterial).set_shader_parameter("occlude", 0.0)
	var st := ToonKit.begin()
	st.set_uv2(Vector2.ZERO)
	var gst := ToonKit.begin()
	var has_glow := _build_body(st, gst)
	mesh = ToonKit.mesh_instance(ToonKit.finish(st), mat, "Mesh")
	pose.add_child(mesh)
	if has_glow:
		glow_mat = ToonKit.glow(_glow_color(), 2.0)
		glow_mat = glow_mat.duplicate()
		glow_mesh = ToonKit.mesh_instance(gst.commit(), glow_mat, "Glow")
		glow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pose.add_child(glow_mesh)
	_add_shadow()
	_after_build()


## Override: add geometry. Return true if the glow surface tool was used.
func _build_body(_st: SurfaceTool, _gst: SurfaceTool) -> bool:
	return false


## Override for extra nodes (markers, rotors...).
func _after_build() -> void:
	pass


func _glow_color() -> Color:
	return Color(1.0, 0.3, 0.2)


func _add_shadow() -> void:
	shadow = MeshInstance3D.new()
	shadow.name = "BlobShadow"
	var p := PlaneMesh.new()
	p.size = Vector2(radius * 2.4, radius * 2.4)
	shadow.mesh = p
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = load("res://game/art/shaders/blob_shadow.gdshader")
	sm.set_shader_parameter("strength", 0.55)
	shadow.material_override = sm
	shadow.position = Vector3(0, 0.04, 0)
	add_child(shadow)


# ------------------------------------------------------------------ CONTRACTS §5 API

func set_facing(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	_target_yaw = atan2(-dir.x, -dir.z)


func set_move_amount(v: float) -> void:
	_move = clampf(v, 0.0, 1.0)


func play_attack(kind: String = "light") -> void:
	_build()
	if _dead:
		return
	if _tw:
		_tw.kill()
	var fwd := Vector3(0, 0, -1)
	var lunge := radius * (0.9 if kind == "heavy" else 0.55)
	var wind := 0.28 if kind == "heavy" else 0.14
	_tw = create_tween()
	_tw.tween_property(pose, "position", Vector3(0, hover_height + 0.05, radius * 0.25), wind).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(pose, "rotation:x", deg_to_rad(14.0), wind)
	_tw.tween_property(pose, "position", Vector3(0, hover_height, 0) + fwd * lunge, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw.parallel().tween_property(pose, "rotation:x", deg_to_rad(-10.0), 0.09)
	_tw.tween_property(pose, "position", Vector3(0, hover_height, 0), 0.25).set_trans(Tween.TRANS_SINE)
	_tw.parallel().tween_property(pose, "rotation:x", 0.0, 0.25)
	_on_attack(kind)


func _on_attack(_kind: String) -> void:
	pass


func play_telegraph(duration: float) -> void:
	_build()
	_telegraph = maxf(duration, 0.05)
	_telegraph_total = _telegraph


func flash_hit() -> void:
	_build()
	_flash = 1.0
	if _dead:
		return
	var tw := create_tween()
	tw.tween_property(pose, "rotation:z", deg_to_rad(9.0), 0.05)
	tw.tween_property(pose, "rotation:z", deg_to_rad(-5.0), 0.08)
	tw.tween_property(pose, "rotation:z", 0.0, 0.1)


func play_die() -> float:
	_build()
	if _dead:
		return 0.0
	_dead = true
	_move = 0.0
	if _tw:
		_tw.kill()
	var d := _die_anim()
	return d


## Default death: flip onto the back, legs curl (gait stops), sink and shrink away.
func _die_anim() -> float:
	_tw = create_tween()
	_tw.tween_property(pose, "position:y", hover_height + radius * 0.5, 0.18).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(pose, "rotation:z", PI, 0.4).set_trans(Tween.TRANS_BACK)
	_tw.tween_property(pose, "position:y", radius * 0.35, 0.2).set_ease(Tween.EASE_IN)
	_tw.tween_interval(0.5)
	_tw.tween_property(pose, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_ease(Tween.EASE_IN)
	_tw.parallel().tween_property(shadow, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
	return 1.25


func set_highlight(color: Color, on: bool) -> void:
	_build()
	mat.set_shader_parameter("highlight_color", color)
	mat.set_shader_parameter("highlight", 1.0 if on else 0.0)
	(mat.next_pass as ShaderMaterial).set_shader_parameter("ink_color", color if on else Color(0.12, 0.06, 0.06))


func set_ghost(alpha: float) -> void:
	_build()
	_ghost = clampf(alpha, 0.0, 1.0)
	if _ghost <= 0.001:
		mesh.material_override = mat
		if glow_mesh:
			glow_mesh.visible = true
		shadow.visible = true
		return
	if ghost_mat == null:
		ghost_mat = StandardMaterial3D.new()
		ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		ghost_mat.vertex_color_use_as_albedo = true
		ghost_mat.disable_receive_shadows = true
	ghost_mat.albedo_color = Color(0.62, 0.45, 1.0, 1.0) * (0.35 + _ghost * 0.65)
	mesh.material_override = ghost_mat
	if glow_mesh:
		glow_mesh.visible = false
	shadow.visible = false


func get_radius() -> float:
	return radius


# ------------------------------------------------------------------ per-frame animation

func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta
	# turning
	_yaw = lerp_angle(_yaw, _target_yaw, 1.0 - exp(-turn_speed * delta))
	body.rotation.y = _yaw
	# gait
	var amt := 0.0 if _dead else _move
	_phase = fmod(_phase + delta * gait_speed * (0.25 + amt), 1000.0)
	mat.set_shader_parameter("gait_phase", _phase)
	mat.set_shader_parameter("gait_amp", gait_stride * amt)
	var op := mat.next_pass as ShaderMaterial
	op.set_shader_parameter("gait_phase", _phase)
	op.set_shader_parameter("gait_amp", gait_stride * amt)
	if not _dead and (_tw == null or not _tw.is_running()):
		var bob := sin(_phase * TAU * 2.0) * bob_amount * amt
		var idle := sin(_t * 2.1) * bob_amount * 0.35
		pose.position.y = hover_height + bob + idle
	# flash
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		mat.set_shader_parameter("flash", _flash)
	# telegraph: rear up + pulsing red emission
	if _telegraph > 0.0:
		_telegraph = maxf(0.0, _telegraph - delta)
		var k := 1.0 - _telegraph / maxf(_telegraph_total, 0.001)
		var pulse := 0.5 + 0.5 * sin(_t * (10.0 + k * 20.0))
		mat.set_shader_parameter("emission_color", Color(1.0, 0.25, 0.12))
		mat.set_shader_parameter("emission_energy", (0.25 + 0.55 * pulse) * (0.4 + k))
		if not _dead and (_tw == null or not _tw.is_running()):
			pose.rotation.x = deg_to_rad(16.0) * smoothstep(0.0, 0.3, k)
		if _telegraph <= 0.0:
			mat.set_shader_parameter("emission_energy", 0.0)
			if not _dead and (_tw == null or not _tw.is_running()):
				pose.rotation.x = 0.0
	_animate(delta)


## Override for species-specific motion (antennae, rotors, drills).
func _animate(_delta: float) -> void:
	pass


# ------------------------------------------------------------------ geometry helpers

## Tapered tube with per-end UV2 (leg phase, weight a -> weight b) so the vertex shader can swing it.
static func tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, segs: int, col: Color, phase: float, wa: float, wb: float) -> void:
	var axis := b - a
	if axis.length() < 0.0001:
		return
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var ua := Vector2(phase, wa)
	var ub := Vector2(phase, wb)
	for i in segs:
		var a0 := TAU * float(i) / segs
		var a1 := TAU * float(i + 1) / segs
		var d0 := x * cos(a0) + z * sin(a0)
		var d1 := x * cos(a1) + z * sin(a1)
		var p0 := a + d0 * ra
		var p1 := a + d1 * ra
		var q0 := b + d0 * rb
		var q1 := b + d1 * rb
		st.set_color(col)
		# (CCW authored; emitted clockwise like ToonKit.tri)
		_v(st, p0, ua); _v(st, q1, ub); _v(st, p1, ua)
		_v(st, p0, ua); _v(st, q0, ub); _v(st, q1, ub)
	# foot cap
	for i in segs:
		var a0 := TAU * float(i) / segs
		var a1 := TAU * float(i + 1) / segs
		_v(st, b, ub); _v(st, b + (x * cos(a1) + z * sin(a1)) * rb, ub); _v(st, b + (x * cos(a0) + z * sin(a0)) * rb, ub)


static func _v(st: SurfaceTool, p: Vector3, uv2: Vector2) -> void:
	st.set_uv2(uv2)
	st.add_vertex(p)


## Jointed insect leg: hip -> knee -> foot, swinging with `phase` (0..1).
static func leg(st: SurfaceTool, hip: Vector3, knee: Vector3, foot: Vector3, r: float, col: Color, phase: float) -> void:
	tube(st, hip, knee, r, r * 0.8, 5, col, phase, 0.0, 0.55)
	tube(st, knee, foot, r * 0.8, r * 0.35, 5, col.darkened(0.12), phase, 0.55, 1.0)
	st.set_uv2(Vector2.ZERO)


## Ellipsoid-ish segment (rock() with low jitter) for bodies.
static func blob(st: SurfaceTool, c: Vector3, r: Vector3, col: Color, seed_v: int, detail: int = 1) -> void:
	st.set_uv2(Vector2.ZERO)
	var verts: Array = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var faces: Array = [[0, 4, 3], [0, 3, 5], [0, 5, 2], [0, 2, 4], [1, 3, 4], [1, 5, 3], [1, 2, 5], [1, 4, 2]]
	for _d in detail:
		var nf: Array = []
		var mid := {}
		for f in faces:
			var m: Array = []
			for e in 3:
				var i0: int = f[e]
				var i1: int = f[(e + 1) % 3]
				var k := str(mini(i0, i1)) + "_" + str(maxi(i0, i1))
				if not mid.has(k):
					verts.append(((verts[i0] + verts[i1]) * 0.5).normalized())
					mid[k] = verts.size() - 1
				m.append(mid[k])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var pts: Array = []
	for v in verts:
		var vv: Vector3 = v
		pts.append(c + Vector3(vv.x * r.x, vv.y * r.y, vv.z * r.z) * (1.0 + rng.randf_range(-0.04, 0.04)))
	for f in faces:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var cc: Vector3 = pts[f[2]]
		var n := (b - a).cross(cc - a).normalized()
		var shade := col.lightened(0.06 * n.y) if n.y > 0.0 else col.darkened(-0.1 * n.y)
		ToonKit.tri(st, a, cc, b, shade)
