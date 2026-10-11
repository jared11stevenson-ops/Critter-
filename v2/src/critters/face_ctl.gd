extends RefCounted
## Face controller: 6 expressions as smooth shader-uniform sets (dot eyes, brows, wobbly mouth), blink, glance, wobble.
## Per-critter design params (eye size, sleepy lids, one-eyebrow-raised ...) are baked into the face material once;
## expressions only drive the dynamic uniforms below, so every critter shares the same six readable states.

const NAMES := ["calm", "grin", "angry", "hurt", "scared", "dying"]
const EXPR := {
	"calm": {"open": 1.0, "brow_tilt": 0.0, "brow_lift": 0.0, "mouth_curve": 0.0, "mouth_open": 0.0, "mouth_wide": 1.0, "xeyes": 0.0, "sweat": 0.0, "wobble": 0.0},
	"grin": {"open": 0.9, "brow_tilt": -0.15, "brow_lift": 0.45, "mouth_curve": 1.0, "mouth_open": 0.85, "mouth_wide": 1.55, "xeyes": 0.0, "sweat": 0.0, "wobble": 0.0},
	"angry": {"open": 0.78, "brow_tilt": -1.0, "brow_lift": -0.25, "mouth_curve": -0.75, "mouth_open": 0.45, "mouth_wide": 1.2, "xeyes": 0.0, "sweat": 0.0, "wobble": 0.15},
	"hurt": {"open": 0.28, "brow_tilt": 1.0, "brow_lift": 0.2, "mouth_curve": -1.0, "mouth_open": 1.0, "mouth_wide": 1.0, "xeyes": 0.0, "sweat": 0.0, "wobble": 0.7},
	"scared": {"open": 1.25, "brow_tilt": 1.0, "brow_lift": 0.75, "mouth_curve": -0.5, "mouth_open": 0.5, "mouth_wide": 0.85, "xeyes": 0.0, "sweat": 1.0, "wobble": 1.0},
	"dying": {"open": 0.5, "brow_tilt": 0.9, "brow_lift": -0.1, "mouth_curve": -0.7, "mouth_open": 0.3, "mouth_wide": 0.9, "xeyes": 1.0, "sweat": 0.0, "wobble": 0.9},
}
## Presentation timings (seconds / blink gaps), not gameplay.
const BLEND_RATE := 18.0
const BLINK_GAP := Vector2(2.2, 5.0)
const BLINK_LEN := 0.12

var mat: ShaderMaterial = null
var base: String = "calm"
var override: String = ""
var override_t: float = 0.0
var cur := {}
var _blink_t := 2.0
var _blink_phase := -1.0
var _time := 0.0
var look := Vector2.ZERO
var _look_t := 3.0
var _look_goal := Vector2.ZERO
var blink_scale := 1.0   # critters with huge eyes blink slower/rounder

func _init(m: ShaderMaterial) -> void:
	mat = m
	cur = (EXPR["calm"] as Dictionary).duplicate()

func set_base(name: String) -> void:
	if EXPR.has(name):
		base = name

func flash_expression(name: String, seconds: float) -> void:
	if EXPR.has(name):
		override = name
		override_t = seconds

func active_name() -> String:
	return override if override_t > 0.0 else base

func update(dt: float) -> void:
	if mat == null:
		return
	_time += dt
	if override_t > 0.0:
		override_t -= dt
	var tgt: Dictionary = EXPR[active_name()]
	var k := 1.0 - exp(-BLEND_RATE * dt)
	for key in tgt:
		cur[key] = lerpf(cur[key], tgt[key], k)
	# blink
	var open_mul := 1.0
	_blink_t -= dt
	if _blink_t <= 0.0 and _blink_phase < 0.0 and active_name() in ["calm", "grin", "angry"]:
		_blink_phase = 0.0
	if _blink_phase >= 0.0:
		_blink_phase += dt
		var u := _blink_phase / (BLINK_LEN * blink_scale)
		open_mul = absf(u * 2.0 - 1.0)
		if u >= 1.0:
			_blink_phase = -1.0
			_blink_t = randf_range(BLINK_GAP.x, BLINK_GAP.y)
			open_mul = 1.0
	# glance around while calm
	_look_t -= dt
	if _look_t <= 0.0:
		_look_goal = Vector2(randf_range(-0.6, 0.6), randf_range(-0.3, 0.3)) if active_name() == "calm" else Vector2.ZERO
		_look_t = randf_range(1.5, 3.5)
	look = look.lerp(_look_goal, 1.0 - exp(-6.0 * dt))
	for key in cur:
		var v: float = cur[key]
		if key == "open":
			v *= open_mul
		mat.set_shader_parameter(key, v)
	mat.set_shader_parameter("look", look)
	mat.set_shader_parameter("time", _time)

func snap() -> void:
	cur = (EXPR[active_name()] as Dictionary).duplicate()
