extends CritterCreature
## Dust Grazer: passive long-legged lichen grazer (r ~0.9). Keystone of the valley.

const SAND := Color(0.86, 0.70, 0.50)
const SAND_DARK := Color(0.62, 0.44, 0.30)
const LICHEN := Color(0.52, 0.66, 0.46)
const STRIPE := Color(0.70, 0.32, 0.22)

var _neck_t := 0.0


func _init() -> void:
	radius = 0.9
	gait_speed = 1.3
	gait_stride = 0.45
	bob_amount = 0.06
	outline_width = 0.03


func _build_body(st: SurfaceTool, _g: SurfaceTool) -> bool:
	# body slung high between stilt legs
	blob(st, Vector3(0, 2.0, 0.3), Vector3(0.48, 0.38, 0.75), SAND, 61)
	blob(st, Vector3(0, 2.22, 0.45), Vector3(0.36, 0.16, 0.55), LICHEN, 62)           # lichen mantle
	for i in 3:
		blob(st, Vector3(0, 1.98, 0.85 - i * 0.32), Vector3(0.5, 0.06, 0.08), STRIPE, 63 + i, 0)
	blob(st, Vector3(0, 1.95, -0.45), Vector3(0.28, 0.26, 0.3), SAND_DARK, 66)
	# long neck down-forward to a grazing head
	ToonKit.cylinder(st, Vector3(0, 2.0, -0.6), Vector3(0, 1.45, -1.35), 0.13, 0.09, 6, SAND)
	blob(st, Vector3(0, 1.38, -1.5), Vector3(0.17, 0.15, 0.25), SAND_DARK, 67)
	for s: float in [-1.0, 1.0]:
		ToonKit.cylinder(st, Vector3(s * 0.06, 1.48, -1.6), Vector3(s * 0.35, 1.95, -1.9), 0.02, 0.01, 3, SAND_DARK, false)
		blob(st, Vector3(s * 0.12, 1.42, -1.58), Vector3(0.04, 0.04, 0.04), Color(0.08, 0.06, 0.06), 68, 0)
	# six stilt legs (wide stance)
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var z := -0.35 + i * 0.4
			var hip := Vector3(s * 0.3, 1.9, z)
			var knee := Vector3(s * 0.95, 2.5, z + (i - 1) * 0.3)
			var foot := Vector3(s * 1.15, 0.0, z + (i - 1) * 0.7)
			leg(st, hip, knee, foot, 0.075, SAND, float((i + (1 if s > 0.0 else 0)) % 2) * 0.5)
	return false


func _animate(delta: float) -> void:
	# idle grazing: dip the whole front a little when standing still
	_neck_t += delta
	if _move < 0.1 and not _dead and (_tw == null or not _tw.is_running()) and _telegraph <= 0.0:
		pose.rotation.x = lerpf(pose.rotation.x, deg_to_rad(4.0) * (0.5 + 0.5 * sin(_neck_t * 0.8)), delta * 3.0)
