extends RefCounted
## A swarm of identical bodies drawn with ONE MultiMesh (2 draw calls with the outline pass): Cigarra's crown spheres. Each instance is
## individually driven: held (rest offset on the crown), orbit (Premonition), flick (Bad Thought: one sphere flies out and returns),
## volley (Crown Barrage: all fan out), recall. Positions live in the swarm node's local space (it is parented to the head, so orbits follow her).
## Individual psychic threads (one ribbon each) are drawn from the node origin to every sphere that is away from its rest.

const FLY_RATE := 12.0

var rig: Node3D
var node: MultiMeshInstance3D
var mm: MultiMesh
var n := 0
var rest: Array = []
var pos: Array = []
var goal: Array = []
var mode: Array = []      # "held" | "goto" | "orbit" | "recall"
var spin: Array = []
var phase: Array = []
var radius := 1.6
var hz := 1.0
var center := Vector3.ZERO
var _t := 0.0
var _flick_i := 0
var _scale: Array = []

func _init(r: Node3D, nd: MultiMeshInstance3D, rest_offsets: Array) -> void:
	rig = r
	node = nd
	mm = nd.multimesh
	n = rest_offsets.size()
	for i in range(n):
		rest.append(rest_offsets[i])
		pos.append(rest_offsets[i])
		goal.append(rest_offsets[i])
		mode.append("held")
		spin.append(0.0)
		phase.append(float(i) / n * TAU)
		_scale.append(1.0)
	_write()

func any_away() -> bool:
	for m in mode:
		if m != "held":
			return true
	return false

func orbit_all(c: Vector3, rad: float, hertz: float) -> void:
	center = c
	radius = rad
	hz = hertz
	for i in range(n):
		mode[i] = "orbit"

func flick(dir: Vector3, dist: float, idx: int = -1) -> void:
	var i := idx if idx >= 0 else _flick_i
	_flick_i = (_flick_i + 1) % n
	mode[i] = "goto"
	goal[i] = rest[i] + dir.normalized() * dist
	spin[i] = 720.0

func volley(dir: Vector3, dist: float, fan: float) -> void:
	for i in range(n):
		var a := (float(i) / maxf(n - 1, 1) - 0.5) * fan
		var d := Vector3(dir.x * cos(a) - dir.z * sin(a), dir.y + 0.15 * sin(i * 1.7), dir.x * sin(a) + dir.z * cos(a))
		mode[i] = "goto"
		goal[i] = rest[i] + d.normalized() * dist
		spin[i] = 540.0

func recall() -> void:
	for i in range(n):
		if mode[i] != "held":
			mode[i] = "recall"

func update(dt: float) -> void:
	_t += dt
	var k := 1.0 - exp(-FLY_RATE * maxf(dt, 1.0 / 120.0))
	for i in range(n):
		match mode[i]:
			"goto":
				pos[i] = (pos[i] as Vector3).lerp(goal[i], k)
			"orbit":
				var a: float = phase[i] + _t * TAU * hz
				var tgt := center + Vector3(cos(a) * radius, 0.25 * radius * sin(a * 1.0 + i), sin(a) * radius)
				pos[i] = (pos[i] as Vector3).lerp(tgt, k)
			"recall":
				pos[i] = (pos[i] as Vector3).lerp(rest[i], k)
				if (pos[i] as Vector3).distance_to(rest[i]) < 0.05:
					mode[i] = "held"
					pos[i] = rest[i]
	_write()

func _write() -> void:
	for i in range(n):
		var b := Basis.from_euler(Vector3(0, _t * deg_to_rad(spin[i]) * (1.0 if mode[i] != "held" else 0.0), 0))
		mm.set_instance_transform(i, Transform3D(b, pos[i]))

## Thread segments (world space pairs) from the swarm origin to each displaced sphere, for fx.thread_multi.
func thread_pairs() -> Array:
	var out: Array = []
	if not node.is_inside_tree():
		return out
	for i in range(n):
		if mode[i] != "held":
			out.append([node.global_position, node.to_global(pos[i])])
	return out
