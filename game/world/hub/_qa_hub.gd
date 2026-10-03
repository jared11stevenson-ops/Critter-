extends Node3D
## QA for hub_visual (Agent 1): overview + each hotspot. Shots at 1.5, 3.0, 4.5, 6.0, 7.5, 9.0.

const VIEWS := [["CamFocus_Default", -34.0, 30.0], ["Hotspot_Table", -30.0, 11.0], ["Hotspot_Gate", -28.0, 14.0],
	["Hotspot_Habitat", -28.0, 14.0], ["Hotspot_Codex", -28.0, 12.0], ["Hotspot_Lab", -28.0, 12.0]]
var hub: Node3D
var cam: Camera3D
var _i := -1
var _t := 0.0


func _ready() -> void:
	hub = load("res://game/world/hub/hub_visual.tscn").instantiate()
	add_child(hub)
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.far = 300.0
	add_child(cam)
	cam.current = true
	_go(0)


func _go(i: int) -> void:
	_i = i
	var v: Array = VIEWS[i]
	var f: Vector3 = (hub.get_node(v[0]) as Node3D).global_position
	var p := deg_to_rad(float(v[1]))
	var d := float(v[2])
	cam.position = f + Vector3(0, 1, 0) + Vector3(0, -sin(p) * d, cos(p) * d)
	cam.look_at(f + Vector3(0, 1, 0), Vector3.UP)
	RenderingServer.global_shader_parameter_set("critter_focus_pos", f)
	RenderingServer.global_shader_parameter_set("critter_cam_pos", cam.position)


func _process(delta: float) -> void:
	_t += delta
	var want := int(floor((_t - 0.5) / 1.5))
	if want > _i and want < VIEWS.size():
		_go(want)
