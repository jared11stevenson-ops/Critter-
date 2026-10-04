extends Node3D
## Agent 3 QA: close-ups of every character billboard under the field lighting, fixed camera stops, so
## before/after texture passes can be compared shot-for-shot.
## tools/shot.sh res://tools/art_pipeline/qa_closeup.tscn /tmp/qa/cu 1.5,3.5,5.5,7.5 8
## Stops (2 s each): 0 aruun+cigarra, 1 mara+dexter+bramvex, 2 mollusk+nerit+zephyr+nyxaris, 3 pharilux+solmara+scarlith

const GROUPS := [["aruun", "cigarra"], ["mara", "dexter", "bramvex"], ["mollusk", "nerit", "zephyr", "nyxaris"],
	["pharilux", "solmara", "scarlith"]]
const CAM := [[Vector3(0, 1.3, 0), 5.2], [Vector3(20, 1.1, 0), 5.6], [Vector3(40, 1.1, 0), 8.5], [Vector3(60, 2.2, 0), 11.0]]
var _cam: Camera3D
var _stop := -1
var _t := 0.0


func _ready() -> void:
	var lighting := preload("res://game/world/common/world_lighting.gd").new()
	lighting.name = "Lighting"
	add_child(lighting)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 40)
	ground.mesh = pm
	ground.position = Vector3(30, 0, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.72, 0.42, 0.28)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	add_child(_cam)
	_cam.current = true
	for g in GROUPS.size():
		var ids: Array = GROUPS[g]
		var base: Vector3 = CAM[g][0]
		var spacing := 1.9 if g < 2 else 2.6
		if g == 3:
			spacing = 4.2
		for i in ids.size():
			var bb: CharacterBillboard = preload("res://game/art/characters/character_billboard.tscn").instantiate()
			bb.character_id = ids[i]
			var x := (float(i) - (ids.size() - 1) * 0.5) * spacing
			var y := 0.0
			if ids[i] == "scarlith":
				# 12 cm canon: shown at 8x so the texture can be judged (QA only)
				bb.height_override = 0.96
			bb.position = Vector3(base.x + x, y, 0)
			add_child(bb)
			bb.set_facing(Vector3(0, 0, 1))
	_set_stop(0)


func _set_stop(i: int) -> void:
	_stop = i
	var focus: Vector3 = CAM[i][0]
	var dist: float = CAM[i][1]
	var pitch := deg_to_rad(-18.0)
	_cam.position = focus + Vector3(0, -sin(pitch) * dist, cos(pitch) * dist)
	_cam.look_at(focus, Vector3.UP)


func _process(delta: float) -> void:
	_t += delta
	var s := mini(int(_t / 2.0), GROUPS.size() - 1)
	if s != _stop:
		_set_stop(s)
