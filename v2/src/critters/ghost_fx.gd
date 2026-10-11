extends RefCounted
## Future ghosts: a translucent copy of a rig posed to a (predicted) action frame. Generic; Cigarra uses it for Premonition.
## Costs one extra rig worth of draw calls (no outlines) only while alive; the base rig's budget is unaffected.

const GHOST := preload("res://src/critters/shaders/ghost.gdshader")
const LIFE := 0.9

static func spawn(rig: Node3D, action: String, frame: int, offset: Vector3, life: float = LIFE, tint: Color = Color(0.45, 0.6, 1.0), move_id: String = "") -> Node3D:
	var host := rig.get_parent()
	if host == null or not rig.is_inside_tree():
		return null
	var g = load(rig.get_script().resource_path).new()
	host.add_child(g)
	g.setup(rig.critter_id)
	g.three_quarter = rig.three_quarter
	g.position = rig.position + Vector3(offset.x * rig._facing, offset.y, offset.z)
	var m := ShaderMaterial.new()
	m.shader = GHOST
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("alpha", 0.55)
	_skin(g, m)
	for i in range(3):
		g.apply_fighter_state({"action": action, "action_frame": frame, "move_id": move_id, "facing": rig._facing, "vitality_ratio": 1.0}, 1.0 / 60.0)
	_skin(g, m)
	var tw: Tween = g.create_tween()
	tw.tween_method(func(v: float): m.set_shader_parameter("alpha", v), 0.55, 0.0, life)
	tw.tween_callback(g.queue_free)
	return g

static func _skin(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.name in ["spark", "smear", "thread"]:
			mi.visible = false
		else:
			mi.material_override = m
	for c in n.get_children():
		_skin(c, m)
