extends Node3D
## QA: lineup of NPC models under a lighting preset. tools/shot.sh res://game/art/models/_qa_cast.tscn /tmp/x 2.5,5 6 - ids=mara,dexter preset=reaches
var _t := 0.0
func _ready() -> void:
	var preset := "reaches"
	var ids: PackedStringArray = []
	var cols := 6
	var dist := 17.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ids="):
			ids = a.substr(4).split(",")
		if a.begins_with("preset="):
			preset = a.substr(7)
		if a.begins_with("cols="):
			cols = int(a.substr(5))
		if a.begins_with("dist="):
			dist = float(a.substr(5))
	var wl := Node3D.new()
	wl.set_script(load("res://game/world/common/world_lighting.gd"))
	wl.set("preset", preset)
	add_child(wl)
	wl.call("apply_preset", preset)
	var g := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(120, 120)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.30, 0.22) if preset == "reaches" else Color(0.40, 0.33, 0.30)
	m.roughness = 0.95
	p.material = m
	g.mesh = p
	add_child(g)
	var rows := int(ceil(float(ids.size()) / cols))
	for i in ids.size():
		var v := VisualFactory.character(ids[i])
		v.position = Vector3((i % cols - (cols - 1) * 0.5) * 2.6, 0, (i / cols) * 2.8 - (rows - 1) * 1.4)
		add_child(v)
		v.call_deferred("set_facing", Vector3(0, 0, 1))
	var cam := Camera3D.new()
	cam.fov = 38.0
	add_child(cam)
	cam.current = true
	var b := Basis.from_euler(Vector3(deg_to_rad(-32), 0, 0))
	cam.global_transform = Transform3D(b, Vector3(0, 1.0, 0) + b * Vector3(0, 0, dist))
