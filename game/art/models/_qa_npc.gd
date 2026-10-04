extends Node3D
## QA stage for one NPC 3D model: tools/shot.sh res://game/art/models/_qa_npc.tscn /tmp/x 1,2.5,4,5.5,7 8 - npc=mara
## Shots: 1 front close, 2.5 3/4, 4 back, 5.5 game camera idle, 7 game camera walking. Optional "preset=hub|reaches".
const ID_DEFAULT := "mara"
var _t := 0.0
var _i := -1
var cam: Camera3D
var model: Node3D
var h := 1.7
var _walk_dir := 0.0
var _id := ID_DEFAULT

func _ready() -> void:
	var preset := "hub"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("npc="):
			_id = a.substr(4)
		if a.begins_with("preset="):
			preset = a.substr(7)
	var wl := Node3D.new()
	wl.set_script(load("res://game/world/common/world_lighting.gd"))
	wl.set("preset", preset)
	add_child(wl)
	var g := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(80, 80)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.27, 0.22) if preset == "reaches" else Color(0.30, 0.27, 0.26)
	m.roughness = 0.95
	p.material = m
	g.mesh = p
	add_child(g)
	model = VisualFactory.character(_id)
	add_child(model)
	h = model.get_height()
	cam = Camera3D.new()
	cam.current = true
	cam.fov = 42.0
	add_child(cam)

func _process(delta: float) -> void:
	_t += delta
	var tl := [[0.0, "close"], [1.7, "close34"], [3.0, "back"], [4.4, "game"], [6.0, "gamewalk"], [8.0, "talk"]]
	while _i + 1 < tl.size() and _t >= tl[_i + 1][0]:
		_i += 1
		_set_cam(tl[_i][1])
	if _i >= 4 and _i < 5:
		model.set_move_amount(0.8)
		model.set_facing(Vector3(1, 0, 0.3))
	elif _i >= 5:
		model.set_move_amount(0.0)
		model.set_facing(Vector3(0, 0, 1))
		if model.has_method("play_anim") and not model.get("_act_name"):
			model.play_anim("talk_idle")

func _set_cam(kind: String) -> void:
	var target := Vector3(0, h * 0.5, 0)
	var yaw := 0.0
	var pitch := -8.0
	var dist := maxf(h * 1.9, 0.6)
	cam.fov = 40.0
	match kind:
		"close34":
			yaw = 40.0
		"back":
			yaw = 180.0
		"game":
			pitch = -40.0
			dist = maxf(h * 3.5, 4.0)
			yaw = 0.0
			target = Vector3(0, h * 0.35, 0)
			model.set_facing(Vector3(0, 0, 1))
		"gamewalk":
			pitch = -35.0
			dist = maxf(h * 3.5, 4.0)
			target = Vector3(0, h * 0.35, 0)
		"talk":
			target = Vector3(0, h * 0.62, 0)
			dist = maxf(h * 1.5, 0.5)
			yaw = 20.0
			pitch = -4.0
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0))
	cam.global_transform = Transform3D(b, target + b * Vector3(0, 0, dist))
