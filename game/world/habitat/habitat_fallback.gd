extends Node3D
## Fallback Habitat enclosure (until Agent 1's habitat_visual.tscn exists).
## Markers: Slot_Substrate, Slot_Symbiont, Slot_Climate, Slot_Anchor, SpecimenSpot.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1c1716")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9a8a7a")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 25, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	if ToonKit.quality():
		ToonKit.quality().call("setup_sun", sun, 30.0)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 4, 0)
	lamp.light_color = Color(0.8, 1.0, 0.85)
	lamp.light_energy = 1.0
	lamp.omni_range = 9.0
	add_child(lamp)
	# enclosure floor + glass walls
	var floor_mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 5.5
	cm.bottom_radius = 5.8
	cm.height = 0.5
	cm.radial_segments = 40
	floor_mi.mesh = cm
	floor_mi.position.y = -0.25
	floor_mi.material_override = _mat(Color("#6b5a4a"))
	add_child(floor_mi)
	var wall := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 5.6
	wm.bottom_radius = 5.6
	wm.height = 3.0
	wm.radial_segments = 40
	wm.cap_top = false
	wm.cap_bottom = false
	wall.mesh = wm
	wall.position.y = 1.5
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.75, 0.95, 0.9, 0.18)
	glass.cull_mode = BaseMaterial3D.CULL_FRONT
	wall.material_override = glass
	add_child(wall)
	var slots := {"Slot_Substrate": Vector3(-3.0, 0, 1.8), "Slot_Symbiont": Vector3(-1.0, 0, 2.8), "Slot_Climate": Vector3(1.2, 0, 2.8), "Slot_Anchor": Vector3(3.1, 0, 1.8), "SpecimenSpot": Vector3(0, 0, -0.4)}
	for n in slots:
		var m := Marker3D.new()
		m.name = n
		m.position = slots[n]
		add_child(m)
		if n.begins_with("Slot_"):
			var pad := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.9
			pm.bottom_radius = 0.9
			pm.height = 0.06
			pad.mesh = pm
			pad.position = slots[n] + Vector3(0, 0.03, 0)
			pad.material_override = _mat(Color("#3a2e29"))
			add_child(pad)
			var l := Label3D.new()
			l.text = n.substr(5).to_upper()
			l.font_size = 40
			l.pixel_size = 0.006
			l.position = slots[n] + Vector3(0, 0.08, 1.05)
			l.rotation_degrees.x = -90
			l.modulate = Color("#e9dcc0")
			add_child(l)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return m
