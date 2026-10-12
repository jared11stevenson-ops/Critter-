extends Node3D
## VFX lab: fires every ability's cast recipe in turn on two real critter rigs and saves a screenshot of each.
## Run: xvfb-run -a godot --path v2 --rendering-driver opengl3 res://src/fx/vfx_lab.tscn -- --out=/tmp/vfx  (optional --only=move_id)

class FakeBout extends Node3D:
	signal fight_event(ev)
	var rigs: Array[CritterRig] = []
	var holders: Array[Node3D] = []
	var cfg := {"a_id": "aruun", "b_id": "cigarra"}
	var sim = null

var _out := "/tmp/vfx"

func _ready() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		if a.begins_with("--only="):
			only = a.substr(7)
	DirAccess.make_dir_recursive_absolute(_out)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.38, 0.3)
	env.environment.ambient_light_color = Color(1, 0.95, 0.85)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(60, 60)
	floor_mi.mesh = pl
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.5, 0.42, 0.33)
	floor_mi.material_override = fm
	add_child(floor_mi)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 8.0, 11.0)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.current = true
	var moves: Array = []
	for cid in ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/%s.json" % cid))
		for mid in d["moves"].keys():
			if AbilityVfx.cast(mid, _dummy_ctx(cid)) or d["moves"][mid].get("kind", "") in ["ability", "laststand"]:
				moves.append([cid, mid])
	await get_tree().process_frame
	var n := 0
	for pair in moves:
		var cid: String = pair[0]
		var mid: String = pair[1]
		if only != "" and mid != only:
			continue
		var fb := FakeBout.new()
		add_child(fb)
		fb.cfg = {"a_id": cid, "b_id": "mollusk" if cid != "mollusk" else "zephyr"}
		for i in 2:
			var h := Node3D.new()
			h.position = Vector3(-2.2 if i == 0 else 2.2, 0, 0)
			fb.add_child(h)
			fb.holders.append(h)
			var rig := CritterRig.new()
			h.add_child(rig)
			rig.setup(str(fb.cfg["a_id"] if i == 0 else fb.cfg["b_id"]))
			rig.rotation.y = PI * 0.5 if i == 0 else -PI * 0.5
			fb.rigs.append(rig)
		var vfx := BoutVfx.new()
		vfx.bind(fb)
		await get_tree().process_frame
		fb.fight_event.emit({"type": "tell", "fighter": 0, "move_id": mid, "kind": "ability", "pos": Vector2(-2.2, 0)})
		for k in 3:
			await get_tree().create_timer(0.11).timeout
			if k == 1:
				var img := get_viewport().get_texture().get_image()
				img.save_png("%s/%s.png" % [_out, mid])
				n += 1
		fb.fight_event.emit({"type": "hit", "fighter": 1, "attacker": 0, "move_id": mid, "damage": 18.0, "pos": Vector2(2.2, 0)})
		await get_tree().create_timer(0.1).timeout
		get_viewport().get_texture().get_image().save_png("%s/%s_hit.png" % [_out, mid])
		await get_tree().create_timer(0.9).timeout
		fb.queue_free()
		await get_tree().process_frame
	print("VFX_LAB shots=", n)
	get_tree().quit()

func _dummy_ctx(cid: String) -> Dictionary:
	var holder := Node3D.new()
	var ctx := {"parent": holder, "pos": Vector3.ZERO, "tpos": Vector3(4, 0, 0), "dir": Vector3.RIGHT, "col": Color.WHITE, "acc": Color.WHITE, "glow": Color.WHITE}
	var ok := AbilityVfx.cast("probe_" + cid, ctx)
	holder.queue_free()
	return ctx
