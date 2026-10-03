class_name VentWeakpoint
extends CritterActor
## A coolant vent on AUGUR-7. Targetable only while vents are open; forwards damage to the rig.

var rig: Node = null
var marker: Node3D = null
var open := false

func _ready() -> void:
	team = "enemy"
	display_name = "Coolant Vent"
	species_id = "augur_rig"
	body_radius = Balance.f("enemies.augur_rig.vent_radius", 3.6) * 0.5
	height = 1.2
	max_hp = 1.0
	hp = 1.0
	collision_layer = 0
	collision_mask = 0
	if Field.current:
		Field.current.register_enemy(self)

func _exit_tree() -> void:
	if Field.current:
		Field.current.unregister_enemy(self)

func is_targetable() -> bool:
	return open and rig != null and is_instance_valid(rig) and rig.alive and is_inside_tree()

func hostile_now() -> bool:
	return is_targetable()

func _process(_d: float) -> void:
	if marker and is_instance_valid(marker):
		var p := marker.global_position
		var gy := Field.current.height_at(p.x, p.z) if Field.current else p.y
		global_position = Vector3(p.x, gy, p.z)

func receive_hit(hit: Dictionary) -> float:
	if not is_targetable():
		return 0.0
	var h := hit.duplicate()
	h["amount"] = float(hit.get("amount", 0.0)) * Balance.f("enemies.augur_rig.vent_mult", 1.5)
	h["via_vent"] = true
	return rig.receive_hit(h)

func make_ghost_visual() -> Node3D:
	return null
