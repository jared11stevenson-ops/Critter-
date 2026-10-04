extends CritterCreature
## Plate Beetle: slow heavy lichen grazer, carapace like layered slate (r ~1.4).

const SLATE := Color(0.36, 0.38, 0.44)
const SLATE_LIGHT := Color(0.52, 0.54, 0.58)
const SLATE_DARK := Color(0.22, 0.22, 0.27)
const BELLY := Color(0.70, 0.46, 0.28)
const LICHEN := Color(0.56, 0.66, 0.42)


func _init() -> void:
	model_path = "res://game/art/creatures/models/plate_beetle/plate_beetle.glb"
	radius = 1.4
	gait_speed = 1.5
	gait_stride = 0.32
	bob_amount = 0.05
	outline_width = 0.04


func _glow_color() -> Color:
	return Color(1.0, 0.55, 0.18)


func _build_body(st: SurfaceTool, g: SurfaceTool) -> bool:
	# underbody
	blob(st, Vector3(0, 0.75, 0.15), Vector3(1.05, 0.5, 1.35), BELLY, 11)
	# layered slate plates, rear to front, each overlapping the next
	for i in 5:
		var z := 1.05 - i * 0.48
		var w := 1.12 - absf(i - 1.5) * 0.09
		var c := SLATE.lerp(SLATE_LIGHT, 0.15 * (i % 2))
		blob(st, Vector3(0, 1.08 + sin(i * 0.9) * 0.05, z), Vector3(w, 0.36, 0.42), c, 20 + i)
		blob(st, Vector3(0, 1.30, z - 0.05), Vector3(w * 0.55, 0.12, 0.3), SLATE_LIGHT, 30 + i, 0)   # plate ridge
	# lichen tufts on the back
	for i in 4:
		blob(st, Vector3((i - 1.5) * 0.35, 1.42, 0.5 - i * 0.3), Vector3(0.16, 0.08, 0.14), LICHEN, 40 + i, 0)
	# head + horned mandibles
	blob(st, Vector3(0, 0.80, -1.25), Vector3(0.55, 0.42, 0.45), SLATE_DARK, 50)
	blob(st, Vector3(0, 1.05, -1.2), Vector3(0.45, 0.16, 0.38), SLATE, 51, 0)
	for s: float in [-1.0, 1.0]:
		ToonKit.cylinder(st, Vector3(s * 0.28, 0.65, -1.55), Vector3(s * 0.12, 0.6, -2.1), 0.12, 0.03, 5, SLATE_LIGHT)
		ToonKit.cylinder(st, Vector3(s * 0.2, 1.05, -1.55), Vector3(s * 0.55, 1.5, -1.95), 0.03, 0.015, 3, SLATE_DARK, false)
		ToonKit.rock(g, Vector3(s * 0.32, 0.92, -1.6), Vector3(0.08, 0.07, 0.06), Color(1, 1, 1), 3, 0)
	# six stout legs
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var z := -0.7 + i * 0.7
			var hip := Vector3(s * 0.8, 0.7, z)
			var knee := Vector3(s * 1.45, 1.0, z + (i - 1) * 0.25)
			var foot := Vector3(s * 1.75, 0.0, z + (i - 1) * 0.5)
			leg(st, hip, knee, foot, 0.12, SLATE_DARK, float((i + (1 if s > 0.0 else 0)) % 2) * 0.5)
	return true
