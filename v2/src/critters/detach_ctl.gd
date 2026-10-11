extends RefCounted
## A part that can leave the body: Aruun's Morrow (throw / hover / recall, moves on its own on counters), Cigarra's crown spheres
## (orbit during Premonition, flick out as Bad Thought, recall). While detached the part is reparented under the rig's facing pivot and
## driven here; the pose system skips it. Offsets are in the facing pivot space (+X = forward).
## Modes: held | goto (fly to `goal`, optional spin) | orbit (revolve around `goal`, scaled by `radius`) | recall (fly home, then reattach).

const FLY_RATE := 14.0      # presentation: chase speed toward the goal
const HOME_DIST := 0.12

var rig: Node3D
var part: Node3D
var name := ""
var mode := "held"
var goal := Vector3.ZERO
var spin := 0.0
var radius := 1.0
var hz := 1.0
var _home_parent: Node3D
var _home_local: Transform3D
var _t := 0.0

func _init(r: Node3D, n: String, p: Node3D) -> void:
	rig = r
	name = n
	part = p
	_home_parent = p.get_parent()
	_home_local = p.transform

func is_free() -> bool:
	return mode != "held"

func _release() -> void:
	if mode == "held" and part.is_inside_tree():
		part.reparent(rig._pivot, true)

func goto(g: Vector3, spin_dps: float = 0.0) -> void:
	_release()
	mode = "goto"
	goal = g
	spin = spin_dps

func orbit(center: Vector3, rad: float, hertz: float) -> void:
	_release()
	mode = "orbit"
	goal = center
	radius = rad
	hz = hertz

func recall() -> void:
	if mode == "held":
		return
	mode = "recall"

func _home_pos() -> Vector3:
	var gt: Transform3D = _home_parent.global_transform * _home_local
	return rig._pivot.to_local(gt.origin)

func update(dt: float) -> void:
	if mode == "held" or not part.is_inside_tree():
		return
	_t += dt
	var k := 1.0 - exp(-FLY_RATE * maxf(dt, 1.0 / 120.0))
	match mode:
		"goto":
			part.position = part.position.lerp(goal, k)
			part.rotation.z += deg_to_rad(spin) * dt
			part.scale = part.scale.lerp(Vector3.ONE, k)
		"orbit":
			part.position = part.position.lerp(goal, k)
			part.rotation.y += TAU * hz * dt
			part.scale = part.scale.lerp(Vector3.ONE * radius, k)
		"recall":
			var hp := _home_pos()
			part.position = part.position.lerp(hp, k)
			part.scale = part.scale.lerp(Vector3.ONE, k)
			part.rotation = part.rotation.lerp(Vector3.ZERO, k * 0.5)
			if part.position.distance_to(hp) < HOME_DIST:
				part.reparent(_home_parent, false)
				part.transform = _home_local
				mode = "held"
