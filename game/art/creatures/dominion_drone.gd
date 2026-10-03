extends CritterCreature
## Dominion survey drone: hovering gunmetal disc, four rotor rings, red Dominion visor (r ~0.6, hover 1.6 m).

const GUN := Color(0.30, 0.32, 0.36)
const GUN_DARK := Color(0.2, 0.2, 0.23)
const RED := Color(0.72, 0.1, 0.09)

var rotors: MeshInstance3D
var _spin := 0.0


func _init() -> void:
	radius = 0.6
	hover_height = 1.6
	gait_stride = 0.0
	bob_amount = 0.08
	outline_width = 0.025


func _build_body(st: SurfaceTool, g: SurfaceTool) -> bool:
	ToonKit.cylinder(st, Vector3(0, -0.12, 0), Vector3(0, 0.12, 0), 0.42, 0.36, 10, GUN)
	blob(st, Vector3(0, 0.16, 0), Vector3(0.3, 0.16, 0.3), GUN_DARK, 71)
	blob(st, Vector3(0, -0.15, 0), Vector3(0.28, 0.14, 0.28), GUN_DARK, 72)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.02, 0.0)), Vector3(0.9, 0.05, 0.08), RED)
	# rotor arms
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		ToonKit.cylinder(st, d * 0.3, d * 0.72 + Vector3(0, 0.06, 0), 0.04, 0.035, 4, GUN_DARK)
		ToonKit.torus(st, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), d * 0.72 + Vector3(0, 0.08, 0)), 0.24, 0.03, 10, 3, GUN)
	# sensor pod under the body
	ToonKit.cylinder(st, Vector3(0, -0.25, -0.1), Vector3(0, -0.4, -0.25), 0.07, 0.05, 5, GUN_DARK)
	# visor (glow)
	for k in 5:
		var a0 := -0.55 + k * 0.22
		var p0 := Vector3(sin(a0) * 0.43, 0.0, -cos(a0) * 0.43)
		var p1 := Vector3(sin(a0 + 0.22) * 0.43, 0.0, -cos(a0 + 0.22) * 0.43)
		ToonKit.quad(g, p0 + Vector3(0, -0.04, 0), p1 + Vector3(0, -0.04, 0), p1 + Vector3(0, 0.07, 0), p0 + Vector3(0, 0.07, 0), Color(1, 1, 1))
	ToonKit.rock(g, Vector3(0, -0.42, -0.27), Vector3(0.05, 0.05, 0.05), Color(1, 1, 1), 1, 0)
	return true


func _glow_color() -> Color:
	return Color(1.0, 0.16, 0.10)


func _after_build() -> void:
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# rotor blur discs (translucent, one mesh)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var c := Vector3(cos(a) * 0.72, 0.1, sin(a) * 0.72)
		for k in 12:
			var a0 := TAU * float(k) / 12.0
			var a1 := TAU * float(k + 1) / 12.0
			st.add_vertex(c)
			st.add_vertex(c + Vector3(cos(a1), 0, sin(a1)) * 0.23)
			st.add_vertex(c + Vector3(cos(a0), 0, sin(a0)) * 0.23)
	var m := ToonKit.glow(Color(0.85, 0.85, 0.9, 0.22), 1.0)
	rotors = ToonKit.mesh_instance(st.commit(), m, "RotorBlur")
	rotors.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pose.add_child(rotors)
	shadow.scale = Vector3(0.8, 1, 0.8)


func _animate(delta: float) -> void:
	_spin += delta
	rotors.visible = not _dead
	# lean into motion
	if not _dead and (_tw == null or not _tw.is_running()):
		pose.rotation.x = lerpf(pose.rotation.x, deg_to_rad(-12.0) * _move, delta * 5.0)


func _die_anim() -> float:
	_tw = create_tween()
	_tw.tween_property(pose, "rotation", Vector3(0.6, 2.0, 1.2), 0.6)
	_tw.parallel().tween_property(pose, "position:y", 0.25, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tw.tween_callback(func() -> void:
		if glow_mesh:
			glow_mesh.visible = false)
	_tw.tween_interval(0.4)
	_tw.tween_property(pose, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	_tw.parallel().tween_property(shadow, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	var au := get_node_or_null("/root/Audio")
	if au and au.has_method("sfx_at"):
		au.sfx_at("explosion", global_position)
	return 1.3
