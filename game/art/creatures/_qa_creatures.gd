extends Node3D
## QA gallery for creatures (Agent 1). Lineup in the Drill Basin, then the AUGUR-7 rig.
## tools/shot.sh res://game/art/creatures/_qa_creatures.tscn <out> 1.6,2.8,3.7,4.75,5.6,6.6,7.9,9.6,10.8,11.8,12.85,13.8,15.6 17

const SPECIES := ["skitter_mite", "skitter_mite", "plate_beetle", "dust_grazer", "dominion_drone"]
var terrain: RedReachesTerrain
var cam: Camera3D
var crits: Array = []
var rig: Node3D
var _t := 0.0
var _step := -1


func _ready() -> void:
	terrain = RedReachesTerrain.new()
	terrain.with_scatter = false
	add_child(terrain)
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.far = 500.0
	add_child(cam)
	cam.current = true
	var x := 186.0
	for id in SPECIES:
		var c: Node3D = load("res://game/art/creatures/%s.tscn" % id).instantiate()
		add_child(c)
		var r: float = c.get_radius()
		x += r + 0.8
		c.position = Vector3(x, terrain.height_at(x, 12.0), 12.0)
		x += r + 0.8
		c.set_facing(Vector3(0, 0, 1))
		crits.append(c)
	rig = load("res://game/art/creatures/augur_rig.tscn").instantiate()
	add_child(rig)
	rig.position = Vector3(196, terrain.height_at(196, -6), -6)
	rig.set_facing(Vector3(0.3, 0, 1))
	_cam_line()


func _cam_line() -> void:
	var f := Vector3(193.5, terrain.height_at(193.5, 12), 12)
	_cam_at(f, -40.0, 17.0)


func _cam_at(f: Vector3, pitch_deg: float, dist: float) -> void:
	var p := deg_to_rad(pitch_deg)
	cam.position = f + Vector3(0, 1, 0) + Vector3(0, -sin(p) * dist, cos(p) * dist)
	cam.look_at(f + Vector3(0, 1, 0), Vector3.UP)
	RenderingServer.global_shader_parameter_set("critter_focus_pos", f)
	RenderingServer.global_shader_parameter_set("critter_cam_pos", cam.position)


func _process(delta: float) -> void:
	_t += delta
	var s := int(floor(_t - 1.0))
	if s <= _step:
		return
	_step = s
	match s:
		1:
			for c in crits:
				c.set_move_amount(1.0)
			crits[0].set_facing(Vector3(1, 0, 0))
			crits[2].set_facing(Vector3(-1, 0, 0.4))
		2:
			for c in crits:
				c.set_move_amount(0.0)
				c.play_telegraph(1.0)
		3:
			for c in crits:
				c.play_attack("heavy")
		4:
			for c in crits:
				c.flash_hit()
			crits[2].set_highlight(Color(0.4, 0.9, 1.0), true)
			crits[3].set_highlight(Color(1.0, 0.85, 0.3), true)
		5:
			crits[2].set_highlight(Color(0.4, 0.9, 1.0), false)
			crits[3].set_highlight(Color(1.0, 0.85, 0.3), false)
			crits[1].set_ghost(0.6)
			crits[3].set_ghost(0.5)
		6:
			crits[1].set_ghost(0.0)
			crits[3].set_ghost(0.0)
			for c in crits:
				c.play_die()
		8:
			_cam_at(rig.position + Vector3(0, 0, 4), -32.0, 30.0)
		9:
			rig.set_phase(2)
			rig.open_vents(true)
		10:
			rig.set_beam(true, 0.25)
		11:
			rig.set_beam(false, 0.0)
			rig.play_drill_slam()
		12:
			rig.set_phase(3)
			rig.play_telegraph(1.0)
		14:
			print("[QA] rig die ", rig.play_die())
