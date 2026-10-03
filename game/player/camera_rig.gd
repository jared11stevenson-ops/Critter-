class_name CameraRig
extends Node3D
## 3/4 overhead follow camera: yaw 0 (looking -Z), pitch ≈ -40°, distance ≈ 14, FOV ≈ 42.
## Smoothed follow with look-ahead, boss framing (pull back + frame a point), trauma-based shake.

var cam: Camera3D
var target: Node3D = null
var pitch_deg := -40.0
var distance := 14.0
var fov := 42.0
var follow_sharpness := 6.0
var look_ahead := 2.4

var _focus := Vector3.ZERO
var _ahead := Vector3.ZERO
var _frame_point: Variant = null
var _frame_weight := 0.0
var _dist_mult := 1.0
var _dist_mult_target := 1.0
var trauma := 0.0
var _t := 0.0
var _last_us := 0
var _snap := true
var override_focus: Variant = null   # scripted focus (dialogue / cinematic)
var _pitch_cur := -40.0
var _occl_t := 0.0
var _pitch_want := -40.0
var _dist_occl := 1.0
var _dist_occl_want := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cam = Camera3D.new()
	cam.fov = fov
	cam.near = 0.3
	cam.far = 400.0
	cam.current = true
	add_child(cam)
	_last_us = Time.get_ticks_usec()
	_ensure_global_params()

## Agent 1's dithered occlusion fade reads these two globals (focus = player feet, cam = eye).
const GP_FOCUS := &"critter_focus_pos"
const GP_CAM := &"critter_cam_pos"

static func _ensure_global_params() -> void:
	var have := RenderingServer.global_shader_parameter_get_list()
	for n in [GP_FOCUS, GP_CAM]:
		if not have.has(n):
			RenderingServer.global_shader_parameter_add(n, RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)

func _push_global_params() -> void:
	var fp := _focus
	if target and is_instance_valid(target):
		fp = target.global_position
	RenderingServer.global_shader_parameter_set(GP_FOCUS, fp)
	RenderingServer.global_shader_parameter_set(GP_CAM, cam.global_position)

func set_target(t: Node3D, snap: bool = false) -> void:
	target = t
	if snap:
		_snap = true

## Boss framing: keep `point` in frame and pull back by `dist_mult`.
func set_framing(point: Variant, dist_mult: float = 1.35) -> void:
	_frame_point = point
	_dist_mult_target = dist_mult if point != null else 1.0

func add_shake(amount: float) -> void:
	var s := float(GameState.settings.get("screen_shake", 1.0))
	trauma = clampf(trauma + amount * s, 0.0, 1.0)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var rd := clampf(float(now - _last_us) / 1000000.0, 0.0, 0.1)
	_last_us = now
	_t += rd
	var want := _focus
	if override_focus is Vector3:
		want = override_focus
	elif target and is_instance_valid(target):
		var tp := target.global_position
		var v := Vector3.ZERO
		if target is CharacterBody3D:
			v = (target as CharacterBody3D).velocity
			v.y = 0
		var ahead_want := v.limit_length(6.0) / 6.0 * look_ahead
		_ahead = _ahead.lerp(ahead_want, 1.0 - exp(-3.0 * rd))
		want = tp + _ahead + Vector3(0, 0.8, 0)
		if _frame_point is Vector3:
			_frame_weight = move_toward(_frame_weight, 1.0, rd * 1.5)
		else:
			_frame_weight = move_toward(_frame_weight, 0.0, rd * 1.5)
		if _frame_weight > 0.0 and _frame_point is Vector3:
			want = want.lerp((tp + (_frame_point as Vector3)) * 0.5, _frame_weight * 0.75)
	_dist_mult = lerpf(_dist_mult, _dist_mult_target, 1.0 - exp(-2.0 * rd))
	if _snap:
		_focus = want
		_snap = false
		_solve_occlusion()
		_pitch_cur = _pitch_want
		_dist_occl = _dist_occl_want
	else:
		_focus = _focus.lerp(want, 1.0 - exp(-follow_sharpness * rd))
	# terrain occlusion: steepen pitch (and pull in) when a cliff would sit between camera and focus
	_occl_t -= rd
	if _occl_t <= 0.0:
		_occl_t = 0.1
		_solve_occlusion()
	_pitch_cur = lerpf(_pitch_cur, _pitch_want, 1.0 - exp(-4.0 * rd))
	_dist_occl = lerpf(_dist_occl, _dist_occl_want, 1.0 - exp(-4.0 * rd))
	var p := deg_to_rad(_pitch_cur)
	var d := distance * _dist_mult * _dist_occl
	var offset := Vector3(0, -sin(p) * d, cos(p) * d)
	global_position = _focus + offset
	rotation = Vector3(p, 0, 0)
	# shake
	trauma = maxf(0.0, trauma - rd * 1.8)
	var sh := trauma * trauma
	if sh > 0.0001:
		cam.position = Vector3(sin(_t * 47.0) + sin(_t * 23.0) * 0.5, cos(_t * 41.0) + sin(_t * 29.0) * 0.5, 0) * sh * 0.55
		cam.rotation.z = sin(_t * 37.0) * sh * 0.03
	else:
		cam.position = Vector3.ZERO
		cam.rotation.z = 0.0
	_push_global_params()

func _blocked(pitch: float, dist: float) -> bool:
	var f := Field.current
	if f == null:
		return false
	var p := deg_to_rad(pitch)
	var off := Vector3(0, -sin(p) * dist, cos(p) * dist)
	for k in [0.35, 0.55, 0.75, 0.9, 1.0]:
		var q: Vector3 = _focus + off * float(k)
		if f.height_at(q.x, q.z) + 0.8 > q.y:
			return true
	return false

func _solve_occlusion() -> void:
	var d := distance * _dist_mult
	for pd in [pitch_deg, pitch_deg - 8.0, pitch_deg - 16.0, pitch_deg - 24.0, pitch_deg - 32.0]:
		if not _blocked(pd, d):
			_pitch_want = pd
			_dist_occl_want = 1.0
			return
	for dm in [0.8, 0.65, 0.5]:
		if not _blocked(pitch_deg - 32.0, d * dm):
			_pitch_want = pitch_deg - 32.0
			_dist_occl_want = dm
			return
	_pitch_want = pitch_deg - 34.0
	_dist_occl_want = 0.5

## World → screen helper for UI anchoring.
func unproject(p: Vector3) -> Vector2:
	return cam.unproject_position(p)

func is_behind(p: Vector3) -> bool:
	return cam.is_position_behind(p)
