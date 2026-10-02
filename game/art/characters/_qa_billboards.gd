extends Node3D
## QA: every character billboard on a ground plane under the field lighting, gameplay camera angle.
## tools/shot.sh res://game/art/characters/_qa_billboards.tscn /tmp/qa/bb 1.5,3.5,5.5,6.5 7

const IDS := ["aruun", "cigarra", "mara", "dexter", "mollusk", "bramvex", "nerit", "zephyr", "nyxaris",
	"pharilux", "solmara", "scarlith"]
var _bbs: Array = []
var _t := 0.0
var _cam: Camera3D


func _ready() -> void:
	var lighting := preload("res://game/world/common/world_lighting.gd").new()
	lighting.name = "Lighting"
	add_child(lighting)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 60)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.72, 0.42, 0.28)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 42.0
	add_child(_cam)
	_set_cam(Vector3(0, 0.8, -1.0))
	_cam.current = true
	for i in IDS.size():
		var bb: CharacterBillboard = preload("res://game/art/characters/character_billboard.tscn").instantiate()
		bb.character_id = IDS[i]
		var row := 0 if i < 6 else 1
		var col := i % 6
		bb.position = Vector3(-8.5 + col * 3.4, 0, -2.5 + row * 5.0)
		add_child(bb)
		_bbs.append(bb)
	# solmara is huge: push back
	_bbs[10].position = Vector3(5.5, 0, -4.0)


func _set_cam(focus: Vector3) -> void:
	var pitch := deg_to_rad(-40.0)
	var dist := 14.0
	_cam.position = focus + Vector3(0, -sin(pitch) * dist, cos(pitch) * dist)
	_cam.look_at(focus, Vector3.UP)


func _process(delta: float) -> void:
	_t += delta
	if _t > 6.0 and _t - delta <= 6.0:
		# close-up of the two partners
		var pitch := deg_to_rad(-25.0)
		var focus := Vector3(-6.8, 1.0, -2.5)
		_cam.position = focus + Vector3(0, -sin(pitch) * 6.0, cos(pitch) * 6.0)
		_cam.look_at(focus, Vector3.UP)
	# phase A (0-2s): idle front; B (2-4s): walking right/left/away; C (4-6s): attacks, hits, ghost, downed
	for i in _bbs.size():
		var bb: CharacterBillboard = _bbs[i]
		if _t < 2.0:
			bb.set_facing(Vector3(0, 0, 1))
			bb.set_move_amount(0.0)
		elif _t < 4.0:
			var dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3(0, 0, -1), Vector3(1, 0, 1)]
			bb.set_facing(dirs[i % 4])
			bb.set_move_amount(1.0)
		else:
			bb.set_move_amount(0.0)
			bb.set_facing(Vector3(0.3, 0, 1))
			if i == 0 and not bb.has_meta("did"):
				bb.set_meta("did", true)
				bb.play_attack("heavy")
			if i == 1:
				bb.set_highlight(Color(0.75, 0.4, 1.0), true)
			if i == 2:
				bb.set_ghost(0.55)
			if i == 3:
				bb.set_downed(true)
			if i == 4 and int(_t * 3.0) % 2 == 0:
				bb.flash_hit()
