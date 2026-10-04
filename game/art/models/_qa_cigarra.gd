extends Node3D
## QA stage: Cigarra 3D model in Red Reaches lighting. Timeline drives camera + clips for tools/shot.sh.
## Gameplay camera: yaw 0, pitch -40, dist 14, FOV 42.  tools/shot.sh res://game/art/models/_qa_models.tscn /tmp/x 1.5,3,4.3,5.6,7,8.5,9.9 10.5
const TIMELINE := [
	[0.0, "game", "idle", 0.0], [2.0, "game", "walk", 0.4], [3.6, "game", "idle", 0.0],
	[5.0, "close", "idle", 0.0], [6.4, "close34", "talk_idle", 0.0], [7.8, "game", "premonition", 0.0],
	[9.3, "close34", "talk_idle", 0.0],
]
var _t := 0.0
var _i := -1
@onready var cam: Camera3D = $Camera3D
@onready var model = $Cigarra

func _process(delta: float) -> void:
	_t += delta
	while _i + 1 < TIMELINE.size() and _t >= TIMELINE[_i + 1][0]:
		_i += 1
		var e = TIMELINE[_i]
		_set_cam(e[1])
		model.set_move_amount(e[3])
		if e[2] != "idle" and e[2] != "walk":
			model.play_anim(e[2])

func _set_cam(kind: String) -> void:
	var target := Vector3(0, 0.85, 0)
	var yaw := 0.0
	var pitch := -40.0
	var dist := 14.0
	cam.fov = 42.0
	if kind == "close":
		target = Vector3(0, 1.3, 0); pitch = -6.0; dist = 2.4; cam.fov = 40.0
	elif kind == "close34":
		target = Vector3(0, 1.0, 0); pitch = -10.0; dist = 3.8; yaw = 35.0; cam.fov = 40.0
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0))
	cam.global_transform = Transform3D(b, target + b * Vector3(0, 0, dist))
