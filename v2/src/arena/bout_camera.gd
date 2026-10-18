class_name BoutCamera extends Camera3D
## Third-person lock-on camera: sits behind and to the player's shoulder looking at the target, auto-frames both fighters
## (distance grows with their separation and the screen aspect), keeps a 3/4 angle so faces read, and adds hit punch,
## directional shake and intro / outro moves. Pure presentation: it never feeds anything back to the sim.

const SHOULDER_DEG := 38.0        # yaw offset of the camera from the player->target axis
const BASE_DIST := 12.5
const HEIGHT := 6.0
const LOOK_HEIGHT := 1.2
const FOV_V := 40.0
const FIT := 0.78                 # fighters must stay inside this fraction of the half-width

var yaw := 0.0                    # smoothed yaw of the player->target axis
var focus := Vector3(0, LOOK_HEIGHT, 0)
var dist := 8.0
var side := 1.0                   # +1 right shoulder
var intro := 0.0                  # 1 -> 0 during the intro sweep
const INTRO_LEN := 2.4            # seconds: stare-down on the opponent's face, then the sweep back to the fight
var face_target: Variant = null   # Vector3: world position of the opponent's head (set by BoutScene during the intro)
var outro_yaw := 0.0
var outro_focus: Variant = null   # Vector3 override (winner / fallen)
var outro_blend := 0.0
var _punch := 0.0
var _sh_amp := 0.0
var _sh_dir := Vector2.RIGHT
var _sh_t := 0.0
var _snap := true
var reach := 13.0                 # max horizontal distance of the camera from the arena centre (set by BoutScene)
var aspect_override := 0.0        # tests: pretend the viewport has this aspect

func _ready() -> void:
	fov = FOV_V
	near = 0.3
	far = 520.0
	keep_aspect = Camera3D.KEEP_HEIGHT

func snap() -> void:
	_snap = true

## Directional shake: dir is a world-space direction of the blow (any length), amp in meters.
func add_shake(dir: Vector3, amp: float) -> void:
	var local := global_transform.basis.inverse() * dir
	var d2 := Vector2(local.x, local.y)
	if d2.length() < 0.2:
		d2 = Vector2(1, 0.3)
	_sh_dir = d2.normalized()
	_sh_amp = maxf(_sh_amp, amp)
	_sh_t = 0.0

func add_punch(amount: float) -> void:
	_punch = maxf(_punch, amount)

func right2() -> Vector2:
	var r := global_transform.basis.x
	return Vector2(r.x, r.z).normalized()

func forward2() -> Vector2:
	var f := -global_transform.basis.z
	var v := Vector2(f.x, f.z)
	return v.normalized() if v.length() > 0.01 else Vector2(0, -1)

func update(dt: float, pa: Vector3, pb: Vector3) -> void:
	var axis := Vector3(pb.x - pa.x, 0, pb.z - pa.z)
	if axis.length() < 0.05:
		axis = Vector3.RIGHT
	var want_yaw := atan2(axis.x, axis.z)      # angle of the axis seen from +z
	var k := 1.0 if _snap else 1.0 - exp(-5.5 * dt)
	yaw = want_yaw if _snap else lerp_angle(yaw, want_yaw, k)
	var mid := pa.lerp(pb, 0.5)
	var want_focus := Vector3(mid.x, LOOK_HEIGHT, mid.z)
	if outro_focus != null and outro_blend > 0.0:
		var of: Vector3 = outro_focus
		want_focus = want_focus.lerp(Vector3(of.x, LOOK_HEIGHT + 0.2, of.z), outro_blend)
	focus = want_focus if _snap else focus.lerp(want_focus, 1.0 - exp(-10.0 * dt))
	var sep := axis.length()
	var want_dist := fit_distance(pa, pb, sep)
	if outro_blend > 0.0:
		want_dist = lerpf(want_dist, 5.2, outro_blend)
	dist = want_dist if _snap else lerpf(dist, want_dist, 1.0 - exp(-3.2 * dt))
	_snap = false
	intro = maxf(0.0, intro - dt / INTRO_LEN)
	var fb := 0.0
	if face_target != null and intro > 0.0:
		fb = smoothstep(0.52, 0.72, intro)                       # close-up on the face for the first moments of the intro
	var ease_i := intro * intro
	var cy := yaw + deg_to_rad(SHOULDER_DEG) * side + outro_yaw + ease_i * 1.4 * side
	var d := dist + ease_i * 7.0
	var dirv := Vector3(sin(cy), 0, cos(cy))
	var close := clampf(1.0 - sep / 7.0, 0.0, 1.0)          # fighters close: tip the camera up a little
	var h := HEIGHT + close * 1.6 + ease_i * 2.5 - outro_blend * 0.7
	var pos := focus - dirv * d + Vector3(0, h, 0)
	var flat := Vector2(pos.x, pos.z)
	if flat.length() > reach:                                  # never hang past the rim: pull in and rise instead
		var c2 := flat.normalized() * reach
		pos.x = c2.x
		pos.z = c2.y
		pos.y += (flat.length() - reach) * 0.45
	_sh_t += dt
	var off := Vector3.ZERO
	if _sh_amp > 0.001:
		var s := sin(_sh_t * 62.0) * _sh_amp
		off = global_transform.basis.x * (_sh_dir.x * s) + global_transform.basis.y * (_sh_dir.y * s)
		_sh_amp *= exp(-14.0 * dt)
	_punch = maxf(0.0, _punch - dt * 5.0)
	var look_at_pt := focus
	var fov_k := 0.0
	if fb > 0.0:
		var F: Vector3 = face_target
		var ad := Vector3(axis.x, 0, axis.z).normalized()
		pos = pos.lerp(F - ad * 2.8 + Vector3(0, 0.25, 0), fb)
		look_at_pt = focus.lerp(F, fb)
		fov_k = fb
	global_position = pos + off
	look_at(look_at_pt + off * 0.5, Vector3.UP)
	fov = FOV_V - _punch * 3.0 - fov_k * 14.0

## Smallest distance that keeps both fighters inside the frame for the current aspect.
func fit_distance(pa: Vector3, pb: Vector3, sep: float) -> float:
	var vp := get_viewport()
	var aspect := 16.0 / 9.0
	if aspect_override > 0.0:
		aspect = aspect_override
	elif vp != null:
		var sz := vp.get_visible_rect().size
		if sz.y > 0.0:
			aspect = sz.x / sz.y
	var tan_h := tan(deg_to_rad(FOV_V) * 0.5) * aspect * FIT
	var cy := yaw + deg_to_rad(SHOULDER_DEG) * side
	var dirv := Vector3(sin(cy), 0, cos(cy))
	var right := dirv.cross(Vector3.UP).normalized()
	var d := BASE_DIST + sep * 0.28
	var mid := pa.lerp(pb, 0.5)
	for _i in 8:
		var campos := Vector3(mid.x, 0, mid.z) - dirv * d
		var ok := true
		for p in [pa, pb]:
			var v: Vector3 = Vector3(p.x, 0, p.z) - campos
			var z := v.dot(dirv)
			var x := absf(v.dot(right)) + 1.1      # + body half width
			if x > tan_h * z:
				ok = false
		if ok:
			break
		d += 0.9
	return d
