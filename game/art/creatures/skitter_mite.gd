extends CritterCreature
## Skitter Mite: rust-red mineral-stripping mite, swarm animal (r ~0.5).

const RUST := Color(0.66, 0.24, 0.14)
const RUST_DARK := Color(0.40, 0.13, 0.09)
const CHITIN := Color(0.86, 0.52, 0.30)


func _init() -> void:
	model_path = "res://game/art/creatures/models/skitter_mite/skitter_mite.glb"
	radius = 0.5
	gait_speed = 4.5
	gait_stride = 0.14
	bob_amount = 0.025
	outline_width = 0.022


func _build_body(st: SurfaceTool, _g: SurfaceTool) -> bool:
	# abdomen (rear, +Z), thorax, head (front, -Z)
	blob(st, Vector3(0, 0.30, 0.16), Vector3(0.30, 0.22, 0.30), RUST, 1)
	blob(st, Vector3(0, 0.38, 0.18), Vector3(0.16, 0.10, 0.18), CHITIN, 2)          # dorsal sheen
	blob(st, Vector3(0, 0.28, -0.12), Vector3(0.17, 0.14, 0.15), RUST_DARK, 3)
	blob(st, Vector3(0, 0.27, -0.30), Vector3(0.13, 0.11, 0.12), RUST, 4)
	# mandibles
	for s: float in [-1.0, 1.0]:
		ToonKit.cylinder(st, Vector3(s * 0.06, 0.24, -0.38), Vector3(s * 0.02, 0.2, -0.5), 0.035, 0.012, 4, CHITIN)
		# antennae
		ToonKit.cylinder(st, Vector3(s * 0.05, 0.33, -0.36), Vector3(s * 0.22, 0.55, -0.6), 0.015, 0.008, 3, RUST_DARK, false)
		# eyes
		blob(st, Vector3(s * 0.08, 0.32, -0.36), Vector3(0.035, 0.035, 0.035), Color(0.1, 0.05, 0.05), 9, 0)
	# six legs
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var z := -0.16 + i * 0.14
			var hip := Vector3(s * 0.12, 0.28, z)
			var knee := Vector3(s * 0.36, 0.42, z + (i - 1) * 0.08)
			var foot := Vector3(s * 0.52, 0.0, z + (i - 1) * 0.2)
			leg(st, hip, knee, foot, 0.03, RUST_DARK, float((i + (1 if s > 0.0 else 0)) % 2) * 0.5)
	return false
