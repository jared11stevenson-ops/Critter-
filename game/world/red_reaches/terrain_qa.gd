extends Node3D
## QA for the Red Reaches terrain (Agent 1). Flies the gameplay camera (yaw 0, pitch -40, 14 m, FOV 42)
## through every area with Aruun + Cigarra standing at the focus point for scale.
## tools/shot.sh res://game/world/red_reaches/terrain_qa.tscn /tmp/qa/rr <shots> <quit>
## Shots: one per stop, 1.2 s apart starting at 1.0 (see STOPS). Extra args: qa_cam=wide for a cinematic angle.

const STOPS := [
	["gate_pad", Vector3(2, 0, 4)],
	["ramp", Vector3(24, -2, 1)],
	["valley", Vector3(58, -4, 0)],
	["gap", Vector3(83, -4, -1)],
	["waystation", Vector3(116, -3, 0)],
	["boulder", Vector3(146, -3.2, 2)],
	["drill", Vector3(196, -6, 8)],
	["drill_camp", Vector3(206, -6, 22)],
	["span_approach", Vector3(240, -3, 0)],
	["span_mid", Vector3(268, -2, 0)],
	["foundation", Vector3(314, -2, 0)],
	["wide_gate", Vector3(10, 0, 0)],
]
var terrain: RedReachesTerrain
var cam: Camera3D
var _t := 0.0
var _i := -1
var _bb: Array = []
var _wide := false


func _ready() -> void:
	_wide = OS.get_cmdline_user_args().has("qa_cam=wide")
	terrain = RedReachesTerrain.new()
	add_child(terrain)
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.far = 600.0
	add_child(cam)
	cam.current = true
	for id in ["aruun", "cigarra"]:
		var bb: Node3D = load("res://game/art/characters/character_billboard.tscn").instantiate()
		bb.set("character_id", id)
		add_child(bb)
		_bb.append(bb)
	_goto(0)


func _goto(i: int) -> void:
	_i = i
	var stop: Array = STOPS[i % STOPS.size()]
	var f: Vector3 = stop[1]
	f.y = terrain.height_at(f.x, f.z)
	_bb[0].position = f + Vector3(-1.2, 0, 0)
	_bb[0].position.y = terrain.height_at(f.x - 1.2, f.z)
	_bb[1].position = f + Vector3(1.4, 0, 0.6)
	_bb[1].position.y = terrain.height_at(f.x + 1.4, f.z + 0.6)
	var pitch := deg_to_rad(-40.0)
	var dist := 14.0
	if _wide or stop[0].begins_with("wide"):
		pitch = deg_to_rad(-14.0)
		dist = 34.0
	cam.position = f + Vector3(0, 1.0, 0) + Vector3(0, -sin(pitch) * dist, cos(pitch) * dist)
	cam.look_at(f + Vector3(0, 1.0, 0), Vector3.UP)
	RenderingServer.global_shader_parameter_set("critter_focus_pos", f)
	RenderingServer.global_shader_parameter_set("critter_cam_pos", cam.global_position)
	print("[QA] stop ", stop[0], " focus ", f)
	# exercise the scripted structure API (qa_alt = broken boulder + failing span; default = braced span)
	var alt := OS.get_cmdline_user_args().has("qa_alt")
	if stop[0] == "valley":
		terrain.set_rope_span_visible(true)
	if stop[0] == "boulder" and alt:
		terrain.break_boulder()
	if stop[0] == "span_approach":
		terrain.set_span_state("failing" if alt else "braced")
	if stop[0] == "span_mid" and alt:
		terrain.shake_span(1.0)


func _process(delta: float) -> void:
	_t += delta
	var want := int(floor((_t - 0.4) / 1.2))
	if want > _i and want < STOPS.size():
		_goto(want)
