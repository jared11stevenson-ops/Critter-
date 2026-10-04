extends Node3D
## Fallback Terrarium One / The Common diorama (used until Agent 1's hub_visual.tscn is merged).
## Provides the same named markers: Hotspot_Table/Gate/Habitat/Codex/Lab, CamFocus_Default, NPC_<id>.

const NPCS := {
	"mollusk": Vector3(-5.5, 0, -2.5), "bramvex": Vector3(4.5, 0, -3.5), "nerit": Vector3(-7.5, 0, 3.0),
	"zephyr": Vector3(6.5, 0, 2.5), "nyxaris": Vector3(-2.5, 0, 6.5), "pharilux": Vector3(1.5, 0, -9.0),
	"solmara": Vector3(15.0, 0, 3.5), "scarlith": Vector3(-1.4, 0.95, 0.6),
}

func _ready() -> void:
	_env()
	_ground()
	_mk("CamFocus_Default", Vector3(0, 0, 0))
	_mk("Hotspot_Table", Vector3(0, 0, 0))
	_mk("Hotspot_Gate", Vector3(-13, 0, -7))
	_mk("Hotspot_Habitat", Vector3(13, 0, -7))
	_mk("Hotspot_Codex", Vector3(-9, 0, 8))
	_mk("Hotspot_Lab", Vector3(10, 0, 8))
	# Common Table (built from discarded Habitat material)
	_box(Vector3(5.0, 0.25, 2.2), Vector3(0, 0.95, 0), Color("#8a6a4a"))
	for sx in [-2.1, 2.1]:
		for sz in [-0.8, 0.8]:
			_box(Vector3(0.25, 0.9, 0.25), Vector3(sx, 0.45, sz), Color("#5a4632"))
	_box(Vector3(1.6, 0.05, 1.0), Vector3(0.6, 1.1, 0.1), Color("#e9dcc0"))
	# Gate ring
	var tm := TorusMesh.new()
	tm.inner_radius = 3.0
	tm.outer_radius = 3.7
	var gate := MeshInstance3D.new()
	gate.mesh = tm
	gate.rotation_degrees = Vector3(90, 25, 0)
	gate.position = Vector3(-13, 3.8, -8.5)
	var gm := _mat(Color("#5a6470"))
	gm.emission_enabled = true
	gm.emission = Color(0.3, 0.75, 0.95) * 0.8
	gate.material_override = gm
	add_child(gate)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.0
	cm.bottom_radius = 3.0
	cm.height = 0.05
	disc.mesh = cm
	disc.rotation_degrees = Vector3(90, 25, 0)
	disc.position = gate.position
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.4, 0.85, 1.0, 0.35)
	disc.material_override = dm
	add_child(disc)
	# Habitat Wing (glass dome)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 4.0
	sm.height = 4.0
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.position = Vector3(13, 0, -8.5)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.7, 0.95, 0.85, 0.35)
	glass.roughness = 0.1
	dome.material_override = glass
	add_child(dome)
	_box(Vector3(3.0, 0.4, 3.0), Vector3(13, 0.2, -8.5), Color("#6b8a4a"))
	# Codex / translation boards
	_box(Vector3(3.2, 2.2, 0.2), Vector3(-9, 1.6, 9.5), Color("#3a2e29"))
	_box(Vector3(2.8, 1.8, 0.05), Vector3(-9, 1.6, 9.38), Color("#e9dcc0"))
	# Mara's lab
	_box(Vector3(4.0, 3.0, 3.0), Vector3(10, 1.5, 10), Color("#4f7a8c"))
	_box(Vector3(1.2, 2.0, 0.1), Vector3(10, 1.0, 8.45), Color("#2a3a44"))
	# market stalls / living lights
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.4
		var p := Vector3(cos(a) * 18.0, 0, sin(a) * 12.0)
		_box(Vector3(2.2, 1.6, 1.6), p + Vector3(0, 0.8, 0), Color("#b07a4a").lerp(Color("#6b8a4a"), float(i % 2)))
		var lamp := OmniLight3D.new()
		lamp.position = p + Vector3(0, 3.0, 0)
		lamp.light_color = Color(0.5, 0.8, 1.0) if i % 2 == 0 else Color(1.0, 0.8, 0.5)
		lamp.light_energy = 1.4
		lamp.omni_range = 7.0
		add_child(lamp)
	# ambient cast
	for id in NPCS:
		var pos: Vector3 = NPCS[id]
		_mk("NPC_" + id, pos)
		var v := VisualFactory.character(id)
		add_child(v)
		v.position = pos
		VisualFactory.call_v(v, "set_facing", [Vector3(-pos.x, 0, -pos.z).normalized() + Vector3(0, 0, 0.6)])
	# Mara at the lab door, the partners by the table
	var mara := VisualFactory.character("mara")
	add_child(mara)
	mara.position = Vector3(10, 0, 7.6)
	VisualFactory.call_v(mara, "set_facing", [Vector3(0, 0, 1)])
	var aru := VisualFactory.character("aruun")
	add_child(aru)
	aru.position = Vector3(-2.6, 0, 2.2)
	VisualFactory.call_v(aru, "set_facing", [Vector3(0.3, 0, 1)])
	var cig := VisualFactory.character("cigarra")
	add_child(cig)
	cig.position = Vector3(2.8, 0, 2.0)
	VisualFactory.call_v(cig, "set_facing", [Vector3(-0.3, 0, 1)])

func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1c1716")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a7a70")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.8
	sun.light_color = Color("#ffe8cc")
	sun.shadow_enabled = true
	add_child(sun)
	if ToonKit.quality():
		ToonKit.quality().call("setup_sun", sun, 40.0)

func _ground() -> void:
	var g := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 24.0
	cm.bottom_radius = 25.0
	cm.height = 1.0
	cm.radial_segments = 48
	g.mesh = cm
	g.position.y = -0.5
	g.material_override = _mat(Color("#7d8a5a"))
	add_child(g)
	var path := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 9.0
	pm.bottom_radius = 9.0
	pm.height = 0.04
	pm.radial_segments = 40
	path.mesh = pm
	path.position.y = 0.02
	path.material_override = _mat(Color("#b09a74"))
	add_child(path)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.roughness = 0.9
	return m

func _box(size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(c)
	add_child(mi)
	return mi

func _mk(n: String, p: Vector3) -> void:
	var m := Marker3D.new()
	m.name = n
	m.position = p
	add_child(m)
