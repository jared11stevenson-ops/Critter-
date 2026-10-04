extends Node3D
## Agent 4 QA: both hero models side by side on a coloured ground under a chosen lighting preset, to check the pop layer
## against non-red biomes.   qa_preset=hub|reaches|<mood key>  qa_ground=r,g,b  qa_cam=game|close
func _ready() -> void:
	var preset := "reaches"
	var ground := Color(0.55, 0.32, 0.24)
	var cam_kind := "close"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("qa_preset="):
			preset = a.substr(10)
		elif a.begins_with("qa_ground="):
			var p := a.substr(10).split(",")
			ground = Color(float(p[0]), float(p[1]), float(p[2]))
		elif a.begins_with("qa_cam="):
			cam_kind = a.substr(7)
	var wl := Node3D.new()
	wl.set_script(load("res://game/world/common/world_lighting.gd"))
	wl.set("preset", preset)
	add_child(wl)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ground
	mat.roughness = 0.95
	pm.material = mat
	g.mesh = pm
	add_child(g)
	for i in 2:
		var id: String = ["aruun", "cigarra"][i]
		var m: Node3D = load("res://game/art/models/%s/%s_model.tscn" % [id, id]).instantiate()
		m.position = Vector3(-1.1 if i == 0 else 1.0, 0, 0)
		m.rotation.y = 0.0
		add_child(m)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 40
	var target := Vector3(0, 1.1, 0)
	var dist := 6.0
	var pitch := -10.0
	if cam_kind == "game":
		target = Vector3(0, 0.85, 0); dist = 14.0; pitch = -40.0; cam.fov = 42
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), 0, 0))
	cam.global_transform = Transform3D(b, target + b * Vector3(0, 0, dist))
