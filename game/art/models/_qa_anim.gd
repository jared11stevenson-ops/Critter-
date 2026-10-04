extends Node3D
## Agent 4 animation QA stage (deterministic with --fixed-fps 30). Driven by user args:
##   qa_seq=loco|combo|abilities|react   qa_cam=game|close|side|close34|front   qa_char=aruun
## tools/animation/qa_frames.sh renders sequential frames + contact sheets from this stage.
var _t := 0.0
var _i := -1
var _seq: Array = []
var _cam_kind := "game"
var _move := 0.0
var _move_target := 0.0
var _pos := Vector3.ZERO
var model: Node3D
var _feet := false
var _skel: Skeleton3D
@onready var cam: Camera3D = $Camera3D

const SEQS := {
	"loco": [[0.0, "move", 0.0], [1.0, "move", 0.24], [4.0, "move", 0.62], [6.5, "move", 1.0], [9.5, "move", 0.0]],
	"combo": [[0.5, "attack", "light"], [0.78, "attack", "light"], [1.06, "attack", "heavy"], [3.0, "attack", "light"],
		[4.5, "anim", "attack_2"], [6.0, "anim", "attack_3"]],
	"abilities": [[0.5, "heavy_reach", ""], [2.0, "attack", "cast"], [5.0, "anim", "beetle_rage"], [7.0, "anim", "dash"],
		[8.0, "anim", "talk_idle"], [11.0, "anim", "idle"]],
	"react": [[0.5, "anim", "hit"], [1.3, "anim", "hit_back"], [2.1, "anim", "hit_left"], [2.9, "anim", "hit_right"],
		[3.7, "anim", "hit_heavy"], [5.0, "downed", true], [7.0, "downed", false], [9.0, "anim", "burden_hold"]],
	"cig_abilities": [[0.5, "attack", "cast"], [1.3, "anim", "premonition"], [2.8, "anim", "false_memory"],
		[4.2, "anim", "brain_skip"], [5.4, "attack", "cast"], [6.0, "anim", "talk_idle"], [8.0, "anim", "idle"]],
	"cig_move": [[0.3, "anim", "dash"], [1.2, "leap", ""], [3.4, "anim", "overwhelmed"], [5.4, "anim", "idle"]],
	"walkcombo": [[0.0, "move", 0.3], [1.0, "attack", "light"], [1.28, "attack", "light"], [1.56, "attack", "heavy"],
		[3.5, "move", 0.0]],
}


func _ready() -> void:
	var char_id := "aruun"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("qa_seq="):
			_seq = SEQS.get(a.substr(7), [])
		elif a.begins_with("qa_cam="):
			_cam_kind = a.substr(7)
		elif a == "qa_feet":
			_feet = true
		elif a.begins_with("qa_char="):
			char_id = a.substr(8)
	var path := "res://game/art/models/%s/%s_model.tscn" % [char_id, char_id]
	if not ResourceLoader.exists(path):
		path = "res://game/art/models/_standin/%s_standin.tscn" % char_id     # pre-model stand-in rig
	var ps: PackedScene = load(path)
	model = ps.instantiate()
	add_child(model)
	model.set_facing(Vector3(0, 0, 1))


func _process(delta: float) -> void:
	_t += delta
	while _i + 1 < _seq.size() and _t >= float(_seq[_i + 1][0]):
		_i += 1
		var e: Array = _seq[_i]
		match e[1]:
			"move":
				_move_target = float(e[2])
			"attack":
				model.play_attack(e[2])
			"anim":
				model.play_anim(e[2])
			"downed":
				model.set_downed(e[2])
			"leap":
				model.play_anim("leap", -1.0, 1.15)
			"heavy_reach":
				model.play_anim("reaching_strike", -1.0, 0.26)
	_move = move_toward(_move, _move_target, delta * 1.5)
	model.set_move_amount(_move)
	# travel along +Z at the commanded speed (the model reads set_move_amount * max_speed)
	_pos.z += _move * model.max_speed * delta
	model.position = _pos
	_set_cam()
	if _feet:
		if _skel == null:
			_skel = model.find_children("*", "Skeleton3D", true, false)[0]
		var o := "[FEET] %.3f %.3f" % [_t, _move * model.max_speed]
		for b in ["foot.L", "toe.L", "foot.R", "toe.R"]:
			var g: Vector3 = _skel.global_transform * _skel.get_bone_global_pose(_skel.find_bone(b)).origin
			o += " %.4f %.4f %.4f" % [g.x, g.y, g.z]
		print(o)


func _set_cam() -> void:
	var target := _pos + Vector3(0, 1.0, 0)
	var yaw := 0.0
	var pitch := -40.0
	var dist := 14.0
	cam.fov = 42.0
	match _cam_kind:
		"close":
			target = _pos + Vector3(0, 1.3, 0); pitch = -6.0; dist = 5.2; yaw = 0.0
		"close34":
			target = _pos + Vector3(0, 1.3, 0); pitch = -10.0; dist = 5.6; yaw = 35.0
		"side":
			target = _pos + Vector3(0, 1.2, 0); pitch = -4.0; dist = 7.0; yaw = 90.0
		"sidec":
			target = _pos + Vector3(0, 1.15, 0); pitch = -3.0; dist = 4.4; yaw = 90.0
		"front":
			target = _pos + Vector3(0, 1.2, 0); pitch = -8.0; dist = 7.0; yaw = 0.0
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0))
	cam.global_transform = Transform3D(b, target + b * Vector3(0, 0, dist))
