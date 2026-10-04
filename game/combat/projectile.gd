class_name Projectile
extends Node3D
## Pooled projectile (Bad Thought bolt, drone shot). Distance-checked against the actor registry —
## no physics bodies, no per-frame allocation.

var active := false
var _dir := Vector3.FORWARD
var _speed := 20.0
var _left := 10.0
var _hit: Dictionary = {}
var _team := "party"
var _homing: Node = null
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _visual: Node3D = null
var _style := ""

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	sm.radial_segments = 10
	sm.rings = 5
	_mesh.mesh = sm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.emission_enabled = true
	_mesh.material_override = _mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	visible = false
	set_physics_process(false)

func launch(from: Vector3, dir: Vector3, speed: float, max_dist: float, hit: Dictionary, team: String, homing: Node, style: String) -> void:
	active = true
	visible = true
	global_position = from
	_dir = dir.normalized()
	_speed = speed
	_left = max_dist
	_hit = hit
	_team = team
	_homing = homing
	if style != _style:
		_style = style
		if _visual:
			_visual.queue_free()
			_visual = null
		if style == "psychic":
			_mat.albedo_color = Color(0.82, 0.88, 0.35)
			_mat.emission = Color(0.6, 0.75, 0.2)
			_mesh.scale = Vector3.ONE * 1.1
			if ResourceLoader.exists("res://game/art/vfx/psychic_bolt.tscn"):
				_visual = load("res://game/art/vfx/psychic_bolt.tscn").instantiate()
				add_child(_visual)
		else:
			_mat.albedo_color = Color(1.0, 0.25, 0.18)
			_mat.emission = Color(1.0, 0.2, 0.1)
			_mesh.scale = Vector3.ONE * 0.8
	_mesh.visible = _visual == null
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not active:
		return
	if _homing and is_instance_valid(_homing) and _homing.is_targetable():
		var to: Vector3 = (_homing.global_position + Vector3(0, _homing.aim_height(), 0)) - global_position
		_dir = _dir.slerp(to.normalized(), clampf(delta * 8.0, 0.0, 1.0)).normalized()
	var step := _speed * delta
	global_position += _dir * step
	_left -= step
	var f := Field.current
	if f == null:
		_finish()
		return
	if _team == "party":
		for e in f.enemies:
			if is_instance_valid(e) and e.is_targetable() and _touches(e):
				_impact(e)
				return
	else:
		for d in f.decoys:
			if is_instance_valid(d) and d.alive and d.global_position.distance_to(global_position) < 1.0:
				d.receive_hit(_hit.duplicate())
				_finish()
				return
		for p in f.party_members:
			if is_instance_valid(p) and p.is_targetable() and _touches(p):
				_impact(p)
				return
	if _left <= 0.0:
		_finish()

func _touches(a: Node) -> bool:
	var ap: Vector3 = a.global_position
	var dx := ap.x - global_position.x
	var dz := ap.z - global_position.z
	var r: float = a.body_radius + 0.35
	if dx * dx + dz * dz > r * r:
		return false
	var dy := global_position.y - ap.y
	return dy > -0.6 and dy < a.aim_height() * 2.0 + 0.8

func _impact(target: Node) -> void:
	var h := _hit.duplicate()
	h["dir"] = _dir
	target.receive_hit(h)
	if Field.current and (_style != "psychic" or not (target is CritterActor)):
		Field.current.vfx("psychic_burst" if _style == "psychic" else "hit_spark", global_position)
	_finish()

func _finish() -> void:
	active = false
	visible = false
	_homing = null
	set_physics_process(false)
