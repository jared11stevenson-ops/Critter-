extends Node3D
## QA for habitat_visual + modules (Agent 1). Shots 1.5 (empty+highlights), 3.0 (beetle chain), 4.5 (alt modules)

var hv: Node3D
var beetle: Node3D


func _ready() -> void:
	hv = load("res://game/world/habitat/habitat_visual.tscn").instantiate()
	add_child(hv)
	var cam := Camera3D.new()
	cam.fov = 42
	add_child(cam)
	cam.position = Vector3(0, 7.5, 13)
	cam.look_at(Vector3(0, 1.6, 0), Vector3.UP)
	cam.current = true
	for s in ["Substrate", "Symbiont", "Climate", "Anchor"]:
		hv.set_slot_highlight(s, true)
	get_tree().create_timer(2.0).timeout.connect(_chain_a)
	get_tree().create_timer(3.5).timeout.connect(_chain_b)


func _chain_a() -> void:
	for s in ["Substrate", "Symbiont", "Climate", "Anchor"]:
		hv.set_slot_highlight(s, false)
	hv.set_module("Substrate", "reach_soil_bed")
	hv.set_module("Symbiont", "lichen_mat")
	hv.set_module("Climate", "heat_lamp")
	hv.set_module("Anchor", "scale_anchor")
	beetle = load("res://game/art/creatures/plate_beetle.tscn").instantiate()
	hv.get_node("SpecimenSpot").add_child(beetle)
	beetle.scale = Vector3.ONE * 0.8
	beetle.set_facing(Vector3(0.6, 0, 1))
	hv.set_thriving(1.0)


func _chain_b() -> void:
	hv.set_module("Substrate", "moss_bed")
	hv.set_module("Symbiont", "")
	hv.set_module("Climate", "humidity_mister")
	hv.set_module("Anchor", "thoughtstone_pedestal")
	var extra := ["lumen_lamp", "burden_bridge"]
	var b: Node3D = load("res://game/art/habitat/burden_bridge.tscn").instantiate()
	add_child(b)
	b.position = Vector3(-7.5, 0, 3)
	var l: Node3D = load("res://game/art/habitat/lumen_lamp.tscn").instantiate()
	add_child(l)
	l.position = Vector3(7.5, 4.0, 3)
	hv.set_stress(0.7)
