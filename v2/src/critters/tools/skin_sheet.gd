extends Node3D
## QA only: a row of a skinned critter in different animation states for a contact-sheet screenshot (--screen=skinsheet --id=bramvex).
## Each figure is posed with apply_fighter_state at a fixed frame so the key poses (anticipation / impact / recovery) can be reviewed at once.

const STATES := [
	["idle", "idle", 0, ""], ["walk", "walk", 0, ""], ["guard", "guard", 6, ""],
	["light ant", "strike_light", 14, "m"], ["light hit", "strike_light", 17, "m"], ["light rec", "strike_light", 24, "m"],
	["heavy ant", "strike_heavy", 28, "h"], ["heavy hit", "strike_heavy", 33, "h"], ["heavy rec", "strike_heavy", 48, "h"],
	["dodge", "dodge", 6, ""], ["hit", "hit", 3, ""], ["stagger", "stagger", 10, ""],
	["ghost ant", "ability1", 4, "m"], ["ghost hold", "ability1", 8, "m"], ["ghost rec", "ability1", 20, "m"],
	["prep ant", "ability2", 10, "h"], ["prep hit", "ability2", 32, "h"], ["prep rec", "ability2", 46, "h"],
	["parry 1", "parry", 1, ""], ["parry 5", "parry", 5, ""], ["parry 16", "parry", 16, ""],
	["strafe L", "walk", 0, "", {"speed": 1.0, "fwd": 0.0, "side": 1.0}], ["strafe R", "walk", 0, "", {"speed": 1.0, "fwd": 0.0, "side": -1.0}],
	["dodge fwd", "dodge", 6, "", {"speed": 1.0, "fwd": 1.0, "side": 0.0}], ["dodge L", "dodge", 6, "", {"speed": 1.0, "fwd": 0.0, "side": 1.0}],
	["dodge R", "dodge", 6, "", {"speed": 1.0, "fwd": 0.0, "side": -1.0}], ["win", "idle", 0, "", {"won": true}],
	["stand ant", "laststand", 6, "h"], ["stand hit", "laststand", 40, "h"], ["stand rec", "laststand", 64, "h"],
	["down", "knockdown", 14, "k"], ["up 1", "knockdown", 44, "k"], ["up 2", "knockdown", 58, "k"],
	["look +40", "idle", 0, "", {"look": 40.0}], ["look -40", "idle", 0, "", {"look": -40.0}],
	["detain ant", "ability3", 8, "m"], ["detain hit", "ability3", 18, "m"], ["detain rec", "ability3", 34, "m"]]

var _live: SkinnedRig
var _live_action := ""
var _live_frame := 0

func _process(_dt: float) -> void:        # --live=<action>: plays the action in real time so spring bones (cloth, wings) really move
	if _live == null:
		return
	_live_frame += 1
	var span := 60
	var f := _live_frame % span
	var fs := {"action": _live_action if f < 40 else "idle", "action_frame": f, "move_id": "", "facing": 1.0, "speed": 1.0, "vitality_ratio": 1.0, "phase": Vector3i(16, 4, 14)}
	if _live_action == "strike_heavy":
		fs["phase"] = Vector3i(30, 6, 20)
	_live.apply_fighter_state(fs, 1.0 / 60.0)

func _ready() -> void:
	var id := "bramvex"
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 38.0
	cam.position = Vector3(0, 1.0, 26.0)
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
	if OS.get_cmdline_user_args().has("--gait"):
		_gait_sheet(cam)
		return
	var only := -1
	var rest_only := false
	var from_i := -1
	var count_i := 18
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from_i = int(a.substr(7))
		if a.begins_with("--count="):
			count_i = int(a.substr(8))
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
		if from_i >= 0 and (i < from_i or i >= from_i + count_i):
			continue
		var st: Array = STATES[i]
		var rig := SkinnedRig.new()
		add_child(rig)
		rig.setup(id)
		rig.three_quarter = 0.0
		rig.position = Vector3(-6.6 + float(i % 6) * 2.6, 7.2 - 3.4 * float(i / 6), 0)
		if from_i >= 0:
			var j := i - from_i
			rig.position = Vector3(-9.0 + float(j % 4) * 6.0, 4.6 - 4.6 * float(j / 4), 0)
		if only >= 0 or rest_only:
			rig.position = Vector3.ZERO
		rig.rotation_degrees.y = 0.0 if OS.get_cmdline_user_args().has("--side") else 90.0     # --side: profile view facing right (+x); default: facing the camera
		var fs := {"action": st[1], "action_frame": st[2], "move_id": "", "facing": 1.0, "speed": 1.0, "vitality_ratio": 1.0}
		if st.size() > 4:
			fs.merge(st[4], true)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--live="):
				_live = rig
				_live_action = a.substr(7)
		if st[3] == "m":
			fs["phase"] = Vector3i(16, 4, 14)
		elif st[3] == "h":
			fs["phase"] = Vector3i(30, 6, 20)
		elif st[3] == "k":
			fs["phase"] = Vector3i(6, 30, 24)
		for k in 6:
			rig.apply_fighter_state(fs, 1.0 / 60.0)
			if st[1] == "walk":
				fs["action_frame"] = k
		rig.set_meta("label", st[0])
		if rest_only:
			rig._apply_bones({})

## --gait: walk / run / backpedal at three phases each (side view), to review the gait cycle.
func _gait_sheet(cam: Camera3D) -> void:
	cam.fov = 34.0
	cam.position = Vector3(0, 2.2, 19.0)
	var rows := [["walk", 0.8, 1.0], ["run", 1.2, 1.0], ["back", 0.6, -1.0]]
	for r in rows.size():
		for k in 4:
			var rig := SkinnedRig.new()
			add_child(rig)
			rig.setup("bramvex")
			rig.three_quarter = 0.0
			rig.position = Vector3(-5.6 + float(k) * 3.7, 5.2 - float(r) * 3.3, 0)
			rig.rotation_degrees.y = 0.0
			var fs := {"action": "walk", "action_frame": 0, "move_id": "", "facing": 1.0, "speed": rows[r][1], "fwd": rows[r][2], "vitality_ratio": 1.0}
			for n in 8:
				rig._t_walk = float(k) * PI / 2.0
				rig.apply_fighter_state(fs, 0.0)
