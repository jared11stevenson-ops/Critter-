extends CritterCreature
## AUGUR-7 Deepcore Rig (boss, r ~6). Dominion gunmetal + red; tracked chassis, drill arm, three coolant
## vents, exposed Thoughtstone core. Markers: DrillTip, Vent1..3, Core. Extra API (CONTRACTS §5):
## set_phase(p), open_vents(on), play_drill_slam(), set_beam(on, angle).

const GUN := Color(0.30, 0.32, 0.36)
const GUN_DARK := Color(0.21, 0.21, 0.24)
const GUN_LIGHT := Color(0.48, 0.50, 0.54)
const RED := Color(0.72, 0.1, 0.09)
const HAZARD := Color(0.86, 0.66, 0.2)
const REST_ARM := deg_to_rad(-28.0)

var arm_pivot: Node3D
var bit: Node3D
var drill_tip: Marker3D
var core: Marker3D
var vents: Array = []        # Marker3D
var flaps: Array = []        # Node3D hinge
var vent_glow: MeshInstance3D
var beam: Node3D
var phase := 1
var vents_open := false
var _beam_on := false
var _drill_spin := 0.0
var _arm_tw: Tween


func _init() -> void:
	radius = 6.0
	gait_stride = 0.0
	bob_amount = 0.03
	outline_width = 0.06
	turn_speed = 2.0


func _glow_color() -> Color:
	return Color(0.55, 0.85, 1.0)


func _build_body(st: SurfaceTool, g: SurfaceTool) -> bool:
	# tracks
	for s: float in [-1.0, 1.0]:
		var x := s * 3.6
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 0.9, 0.5)), Vector3(1.8, 1.8, 9.0), GUN_DARK)
		for k in 5:
			ToonKit.cylinder(st, Vector3(x - s * 0.95, 0.85, -3.0 + k * 1.75), Vector3(x - s * 1.0, 0.85, -3.0 + k * 1.75), 0.7, 0.7, 8, GUN)
		for k in 12:
			ToonKit.box(st, Transform3D(Basis(), Vector3(x, 1.83, -3.6 + k * 0.75)), Vector3(1.85, 0.12, 0.35), GUN_LIGHT.darkened(0.2))
	# chassis tiers
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 2.4, 0.8)), Vector3(6.4, 1.6, 7.6), GUN)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 3.25, 0.8)), Vector3(6.5, 0.25, 7.7), RED)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 4.3, 1.4)), Vector3(5.2, 1.9, 5.4), GUN)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 5.35, 1.6)), Vector3(4.6, 0.25, 4.8), GUN_DARK)
	# hazard chevrons on the front skirt
	for k in 6:
		ToonKit.box(st, Transform3D(Basis(Vector3.BACK, 0.6), Vector3(-2.5 + k, 1.95, -3.02)), Vector3(0.25, 0.8, 0.05), HAZARD if k % 2 == 0 else GUN_DARK)
	# cab + antenna
	ToonKit.box(st, Transform3D(Basis(), Vector3(2.3, 6.0, 3.0)), Vector3(1.6, 1.3, 1.8), GUN_LIGHT)
	ToonKit.box(st, Transform3D(Basis(), Vector3(2.3, 6.1, 2.08)), Vector3(1.3, 0.5, 0.05), Color(0.15, 0.18, 0.22))
	ToonKit.cylinder(st, Vector3(-2.2, 5.4, 3.6), Vector3(-2.2, 9.0, 3.6), 0.08, 0.05, 4, GUN_DARK)
	# core housing (front): ring frame around the Thoughtstone core
	ToonKit.torus(st, Transform3D(Basis(), Vector3(0, 3.6, -1.35)), 1.05, 0.22, 14, 5, GUN_LIGHT)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		ToonKit.box(st, Transform3D(Basis(Vector3.BACK, a), Vector3(cos(a) * 1.05, 3.6 + sin(a) * 1.05, -1.4)), Vector3(0.5, 0.3, 0.5), RED)
	# vent housings on the back deck (three stacks)
	for i in 3:
		var p := _vent_pos(i)
		ToonKit.box(st, Transform3D(Basis(), p + Vector3(0, -0.45, 0)), Vector3(1.3, 0.9, 1.3), GUN_DARK)
	# exhaust pipes
	for s: float in [-1.0, 1.0]:
		ToonKit.cylinder(st, Vector3(s * 2.9, 3.0, 4.4), Vector3(s * 2.9, 6.8, 4.4), 0.28, 0.24, 7, GUN_DARK)
		ToonKit.cylinder(st, Vector3(s * 2.9, 6.8, 4.4), Vector3(s * 2.9, 7.0, 4.4), 0.34, 0.34, 7, RED)
	# glow: core crystal + exhaust tips + red beacons
	ToonKit.rock(g, Vector3(0, 3.6, -1.35), Vector3(0.78, 0.85, 0.5), Color(1, 1, 1), 7, 1)
	return true


func _vent_pos(i: int) -> Vector3:
	return [Vector3(-1.7, 5.9, 2.6), Vector3(0.0, 5.9, 3.2), Vector3(1.7, 5.9, 2.6)][i]


func _after_build() -> void:
	shadow.scale = Vector3(1.1, 1, 1.3)
	core = Marker3D.new()
	core.name = "Core"
	core.position = Vector3(0, 3.6, -1.5)
	pose.add_child(core)
	core.owner = self
	# drill arm on a shoulder pivot above the core
	arm_pivot = Node3D.new()
	arm_pivot.name = "ArmPivot"
	arm_pivot.position = Vector3(0, 5.2, -1.0)
	arm_pivot.rotation.x = REST_ARM
	pose.add_child(arm_pivot)
	var st := ToonKit.begin()
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0, 0)), Vector3(1.6, 1.6, 1.6), GUN_DARK)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0, -3.0)), Vector3(1.1, 1.0, 5.4), GUN)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.55, -3.0)), Vector3(1.12, 0.15, 5.4), RED)
	ToonKit.cylinder(st, Vector3(0, -0.6, -0.8), Vector3(0, -0.4, -4.8), 0.18, 0.18, 6, GUN_LIGHT)   # piston
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, -0.2, -5.9)), Vector3(1.5, 1.5, 1.0), GUN_DARK)
	var arm_mesh := ToonKit.mesh_instance(ToonKit.finish(st), mat, "Arm")
	arm_pivot.add_child(arm_mesh)
	bit = Node3D.new()
	bit.name = "Bit"
	bit.position = Vector3(0, -0.2, -6.3)
	bit.rotation.x = deg_to_rad(-62.0)     # bit points down-forward
	arm_pivot.add_child(bit)
	var bs := ToonKit.begin()
	ToonKit.cylinder(bs, Vector3(0, 0, 0), Vector3(0, 0, -0.6), 0.75, 0.75, 8, GUN_LIGHT)
	for k in 4:
		var z0 := -0.6 - k * 0.6
		var r0 := 0.7 - k * 0.17
		ToonKit.cylinder(bs, Vector3(0, 0, z0), Vector3(0, 0, z0 - 0.6), r0, maxf(r0 - 0.17, 0.04), 6, HAZARD if k % 2 == 0 else GUN, true, 0.15, k)
	ToonKit.cylinder(bs, Vector3(0, 0, -3.0), Vector3(0, 0, -3.4), 0.12, 0.01, 6, GUN_LIGHT)
	var bit_mesh := ToonKit.mesh_instance(ToonKit.finish(bs), mat, "BitMesh")
	bit.add_child(bit_mesh)
	drill_tip = Marker3D.new()
	drill_tip.name = "DrillTip"
	drill_tip.position = Vector3(0, 0, -3.4)
	bit.add_child(drill_tip)
	drill_tip.owner = self
	# vents: markers + hinged flaps + coolant glow (shown when open)
	var gst := ToonKit.begin()
	for i in 3:
		var p := _vent_pos(i)
		var m := Marker3D.new()
		m.name = "Vent%d" % (i + 1)
		m.position = p + Vector3(0, 0.1, 0)
		pose.add_child(m)
		m.owner = self
		vents.append(m)
		var hinge := Node3D.new()
		hinge.name = "Flap%d" % (i + 1)
		hinge.position = p + Vector3(0, 0.02, 0.62)
		pose.add_child(hinge)
		var fs := ToonKit.begin()
		ToonKit.box(fs, Transform3D(Basis(), Vector3(0, 0.08, -0.62)), Vector3(1.35, 0.16, 1.3), HAZARD)
		for k in 3:
			ToonKit.box(fs, Transform3D(Basis(), Vector3(0, 0.17, -0.25 - k * 0.38)), Vector3(1.1, 0.04, 0.12), GUN_DARK)
		hinge.add_child(ToonKit.mesh_instance(ToonKit.finish(fs), mat, "FlapMesh"))
		flaps.append(hinge)
		ToonKit.cylinder(gst, p + Vector3(0, -0.1, 0), p + Vector3(0, 0.06, 0), 0.55, 0.55, 10, Color(1, 1, 1))
	vent_glow = ToonKit.mesh_instance(gst.commit(), ToonKit.glow(Color(0.7, 0.95, 1.0), 2.4), "VentGlow")
	vent_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vent_glow.visible = false
	pose.add_child(vent_glow)
	# beam (Thoughtstone resonance beam from the core), hidden by default
	beam = Node3D.new()
	beam.name = "Beam"
	beam.position = core.position
	pose.add_child(beam)
	var bm := ToonKit.begin()
	ToonKit.cylinder(bm, Vector3.ZERO, Vector3(0, 0, -34.0), 0.45, 0.7, 8, Color(1, 1, 1), false)
	var beam_mi := ToonKit.mesh_instance(bm.commit(), ToonKit.glow(Color(0.6, 0.9, 1.0, 0.75), 2.2), "BeamMesh")
	beam_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.add_child(beam_mi)
	var core_m := ToonKit.begin()
	ToonKit.cylinder(core_m, Vector3.ZERO, Vector3(0, 0, -34.0), 0.16, 0.25, 6, Color(1, 1, 1), false)
	var beam_core := ToonKit.mesh_instance(core_m.commit(), ToonKit.glow(Color(1, 1, 1), 2.5), "BeamCore")
	beam_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.add_child(beam_core)
	beam.visible = false


# ------------------------------------------------------------------ boss API

## Marker access (also findable with find_child("DrillTip") / "Vent1".."Vent3" / "Core").
func get_drill_tip() -> Marker3D:
	_build()
	return drill_tip


func get_core() -> Marker3D:
	_build()
	return core


func get_vent(i: int) -> Marker3D:
	_build()
	return vents[clampi(i - 1, 0, 2)]


func set_phase(p: int) -> void:
	_build()
	phase = clampi(p, 1, 3)
	var k := Color(0.55, 0.85, 1.0) if phase == 1 else (Color(0.9, 0.8, 0.5) if phase == 2 else Color(1.0, 0.35, 0.25))
	glow_mat.albedo_color = k * (2.0 + phase * 0.4)


func open_vents(on: bool) -> void:
	_build()
	vents_open = on
	vent_glow.visible = on
	for i in flaps.size():
		var h: Node3D = flaps[i]
		var tw := create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(h, "rotation:x", deg_to_rad(105.0) if on else 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var au := get_node_or_null("/root/Audio")
	if on and au and au.has_method("sfx_at"):
		au.sfx_at("vent", global_position)


func play_drill_slam() -> void:
	_build()
	if _dead:
		return
	if _arm_tw:
		_arm_tw.kill()
	_arm_tw = create_tween()
	_arm_tw.tween_property(arm_pivot, "rotation:x", deg_to_rad(-55.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_arm_tw.tween_property(arm_pivot, "rotation:x", deg_to_rad(8.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_arm_tw.tween_callback(_on_slam_impact)
	_arm_tw.tween_interval(0.45)
	_arm_tw.tween_property(arm_pivot, "rotation:x", REST_ARM, 0.7).set_trans(Tween.TRANS_SINE)


func _on_slam_impact() -> void:
	var au := get_node_or_null("/root/Audio")
	if au and au.has_method("sfx_at"):
		au.sfx_at("slam", drill_tip.global_position)
	var tw := create_tween()
	tw.tween_property(pose, "position:y", hover_height - 0.15, 0.05)
	tw.tween_property(pose, "position:y", hover_height, 0.2)
	if ResourceLoader.exists("res://game/art/vfx/heavy_impact.tscn"):
		var v: Node3D = load("res://game/art/vfx/heavy_impact.tscn").instantiate()
		get_parent().add_child(v)
		v.global_position = Vector3(drill_tip.global_position.x, global_position.y, drill_tip.global_position.z)


## angle: radians of yaw relative to the rig's facing (0 = straight ahead).
func set_beam(on: bool, angle: float) -> void:
	_build()
	beam.rotation.y = angle
	if on == _beam_on:
		return
	_beam_on = on
	beam.visible = true
	var tw := create_tween()
	if on:
		beam.scale = Vector3(0.1, 0.1, 1.0)
		tw.tween_property(beam, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(beam, "scale", Vector3(0.05, 0.05, 1.0), 0.15)
		tw.tween_callback(func() -> void: beam.visible = false)


func play_attack(kind: String = "light") -> void:
	if kind == "heavy" or kind == "slam":
		play_drill_slam()
	else:
		super.play_attack(kind)


func _animate(delta: float) -> void:
	_drill_spin += delta * (6.0 + phase * 5.0) * (0.0 if _dead else 1.0)
	bit.rotation.z = _drill_spin
	if _beam_on:
		var s := 1.0 + 0.12 * sin(_t * 40.0)
		beam.scale = Vector3(s, s, 1.0)
	if phase == 3 and not _dead and _telegraph <= 0.0:
		mat.set_shader_parameter("emission_color", Color(1.0, 0.2, 0.1))
		mat.set_shader_parameter("emission_energy", 0.12 + 0.12 * sin(_t * 6.0))


func _die_anim() -> float:
	set_beam(false, 0.0)
	_tw = create_tween()
	for i in 8:
		_tw.tween_property(pose, "position", Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.1), randf_range(-0.2, 0.2)), 0.06)
	_tw.tween_callback(func() -> void:
		glow_mat.albedo_color = Color(1.0, 0.6, 0.3) * 4.0
		var au := get_node_or_null("/root/Audio")
		if au and au.has_method("sfx_at"):
			au.sfx_at("explosion", global_position))
	_tw.tween_property(arm_pivot, "rotation:x", deg_to_rad(15.0), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(pose, "rotation", Vector3(deg_to_rad(-6.0), 0, deg_to_rad(8.0)), 0.8).set_trans(Tween.TRANS_QUAD)
	_tw.parallel().tween_property(pose, "position", Vector3(0, -0.6, 0), 0.8)
	_tw.tween_callback(func() -> void:
		glow_mat.albedo_color = Color(0.2, 0.2, 0.25)
		vent_glow.visible = false)
	return 2.2
