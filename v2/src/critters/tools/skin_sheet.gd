extends Node3D
## QA only: a row of a skinned critter in different animation states for a contact-sheet screenshot (--screen=skinsheet --id=bramvex).
## Each figure is posed with apply_fighter_state at a fixed frame so the key poses (anticipation / impact / recovery) can be reviewed at once.

const STATES := [
	["idle", "idle", 0, ""], ["walk", "walk", 0, ""], ["guard", "guard", 6, ""],
	["light ant", "strike_light", 14, "m"], ["light hit", "strike_light", 17, "m"], ["light rec", "strike_light", 24, "m"],
	["heavy ant", "strike_heavy", 28, "h"], ["heavy hit", "strike_heavy", 33, "h"], ["heavy rec", "strike_heavy", 48, "h"],
	["dodge", "dodge", 6, ""], ["hit", "hit", 3, ""], ["stagger", "stagger", 10, ""]]

func _ready() -> void:
	var id := "bramvex"
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 38.0
	cam.position = Vector3(0, 3.3, 15.5)
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.64, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment = e
	add_child(env)
	var only := -1
	var rest_only := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = int(a.substr(7))
		if a == "--rest":
			rest_only = true
	if only >= 0 or rest_only:
		cam.fov = 24.0
		cam.position = Vector3(0, 1.8, 11)
	for i in STATES.size():
		if only >= 0 and i != only:
			continue
		if rest_only and i != 0:
			continue
		var st: Array = STATES[i]
		var rig := SkinnedRig.new()
		add_child(rig)
		rig.setup(id)
		rig.three_quarter = 0.0
		rig.position = Vector3(-6.6 + float(i % 6) * 2.6, 3.6 if i < 6 else 0.0, 0)
		if only >= 0 or rest_only:
			rig.position = Vector3.ZERO
		rig.rotation_degrees.y = 0.0 if OS.get_cmdline_user_args().has("--side") else 90.0     # --side: profile view facing right (+x); default: facing the camera
		var fs := {"action": st[1], "action_frame": st[2], "move_id": "", "facing": 1.0, "speed": 1.0, "vitality_ratio": 1.0}
		if st[3] == "m":
			fs["phase"] = Vector3i(16, 4, 14)
		elif st[3] == "h":
			fs["phase"] = Vector3i(30, 6, 20)
		for k in 6:
			rig.apply_fighter_state(fs, 1.0 / 60.0)
			if st[1] == "walk":
				fs["action_frame"] = k
		rig.set_meta("label", st[0])
		if rest_only:
			rig._apply_bones({})
