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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cam = Camera3D.new()
	cam.fov = fov
	cam.near = 0.3
	cam.far = 400.0
	cam.current = true
	add_child(cam)
	_last_us = Time.get_ticks_usec()

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
	if get_tree().paused:
		return
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
			want = want.lerp((tp + (_frame_point as Vector3)) * 0.5, _frame_weight * 0.6)
	_dist_mult = lerpf(_dist_mult, _dist_mult_target, 1.0 - exp(-2.0 * rd))
	if _snap:
		_focus = want
		_snap = false
	else:
		_focus = _focus.lerp(want, 1.0 - exp(-follow_sharpness * rd))
	var p := deg_to_rad(pitch_deg)
	var d := distance * _dist_mult
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

## World → screen helper for UI anchoring.
func unproject(p: Vector3) -> Vector2:
	return cam.unproject_position(p)

func is_behind(p: Vector3) -> bool:
	return cam.is_position_behind(p)
