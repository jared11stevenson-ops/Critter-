extends Node3D
## QA for VFX one-shots + screen shaders (Agent 1). Grid of all presets on a ground plane.
## tools/shot.sh res://game/art/vfx/_qa_vfx.tscn <out> 1.12,1.3,1.6,2.2,3.3,4.6 5

const NAMES := ["hit_spark", "heavy_impact", "dust_puff", "mace_arc", "reach_line", "gravity_well", "rage_aura",
	"psychic_bolt", "psychic_burst", "false_memory_echo", "brain_skip_glitch", "capture_beam", "scan_ping",
	"pickup_glint", "drill_sparks", "coolant_vent", "thoughtstone_shards", "boss_explosion", "leap_trail",
	"rope_unroll", "heal_motes", "thoughtstone_align"]
var _done := false
var _t := 0.0
var rect: ColorRect


func _ready() -> void:
	var L: Node3D = load("res://game/world/common/world_lighting.gd").new()
	add_child(L)
	var g := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(80, 60)
	g.mesh = p
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.32, 0.2)
	g.material_override = m
	add_child(g)
	var cam := Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.position = Vector3(0, 22, 20)
	cam.look_at(Vector3(0, 0, -1), Vector3.UP)
	cam.current = true
	if OS.get_cmdline_user_args().has("qa_screen"):
		var cl := CanvasLayer.new()
		add_child(cl)
		rect = ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.color = Color(0, 0, 0, 0)
		var sm := ShaderMaterial.new()
		var which := "future_noise" if OS.get_cmdline_user_args().has("qa_noise") else "tilt_screen"
		sm.shader = load("res://game/art/shaders/%s.gdshader" % which)
		sm.set_shader_parameter("strength", 0.8)
		sm.set_shader_parameter("noise", 0.8)
		rect.material = sm
		cl.add_child(rect)


func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0 and not _done:
		_done = true
		for i in NAMES.size():
			var n: String = NAMES[i]
			var v: Node3D = load("res://game/art/vfx/%s.tscn" % n).instantiate()
			var pos := Vector3(-21 + (i % 6) * 8.4, 0, -14 + (i / 6) * 8.0)
			match n:
				"capture_beam":
					v.setup({"from": pos + Vector3(-3, 1, 0), "to": pos + Vector3(3, 1, -2)})
				"mace_arc":
					v.setup({"angle": 140.0, "radius": 3.0})
				"thoughtstone_align":
					v.setup({"target": Vector3(30, 2, -30)})
			add_child(v)
			v.position = pos if n != "capture_beam" else v.position
			if n == "psychic_bolt":
				v.position.y = 1.0
