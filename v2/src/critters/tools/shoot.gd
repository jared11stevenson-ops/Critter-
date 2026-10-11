extends SceneTree
## Lookdev screenshot tool. Run (software GL):
##   xvfb-run -a godot --path v2 --rendering-driver opengl3 --script res://src/critters/tools/shoot.gd -- --mode=turn --ids=haldor,sessa --out=/tmp/shots
## Modes: turn (front, 3/4, side, back), actions (pose strip), expr (6 face closeups), lineup (all ids, one frame), sil (flat black 64px gate image)
## Writes PNG tiles; tools/make_sheets.py composes and downsizes them into design/v2/sheets/.
const Stage := preload("res://src/critters/stage.gd")
const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")

var vp: SubViewport
var world: Node3D
var st: Dictionary

func _init() -> void:
	var ids: PackedStringArray = Pal.IDS
	var mode := "turn"
	var out := "/tmp/shots"
	var size := 512
	var action_arg := "strike_heavy"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--mode="): mode = a.substr(7)
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--size="): size = int(a.substr(7))
		if a.begins_with("--action="): action_arg = a.substr(9)
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(size, size)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	st = Stage.build(world)
	await process_frame
	match mode:
		"turn": await _turn(ids, out)
		"actions": await _actions(ids, out)
		"expr": await _expr(ids, out)
		"lineup": await _lineup(ids, out, size)
		"sil": await _sil(ids, out)
		"film": await _film(ids, out, action_arg)
	quit()

func _spawn(id: String) -> Node3D:
	var rig = Rig.new()
	world.add_child(rig)
	rig.setup(id)
	rig.three_quarter = 0.0
	return rig

func _frame_cam(h: float, yaw_deg: float, center_x: float = 0.0, fit: float = 1.32, tilt: float = 0.14) -> void:
	var cam: Camera3D = st["cam"]
	var d: float = (h * fit * 0.5) / tan(deg_to_rad(cam.fov * 0.5))
	var y := deg_to_rad(yaw_deg)
	var sun: DirectionalLight3D = st["sun"]
	sun.rotation_degrees = Vector3(-30, yaw_deg + 35.0, 0)   # key light follows the camera so every view is front-lit
	cam.look_at_from_position(Vector3(center_x, h * 0.5, 0) + Vector3(sin(y), tilt, cos(y)).normalized() * d, Vector3(center_x, h * 0.48, 0))

func _step(rig: Node3D, action: String, frame: int, n: int = 3, extra: Dictionary = {}) -> void:
	for i in range(n):
		var fs := {"action": action, "action_frame": frame, "facing": 1.0}
		fs.merge(extra)
		rig.apply_fighter_state(fs, 1.0 / 60.0)

func _save(path: String) -> void:
	await process_frame
	await process_frame
	vp.get_texture().get_image().save_png(path)

func _turn(ids, out: String) -> void:
	# camera orbit; rig faces +X. front = camera on +X, side = +Z, back = -X
	var views := {"front": 90.0, "three_quarter": 52.0, "side": 0.0, "back": -90.0}
	for id in ids:
		var rig := _spawn(id)
		var h: float = rig.nominal_height()
		_step(rig, "idle", 0, 4)
		for v in views:
			_frame_cam(h, views[v])
			await _save("%s/%s_turn_%s.png" % [out, id, v])
		rig.free()

func _actions(ids, out: String) -> void:
	# 6 pose frames: idle, strike_light (strike), strike_heavy (anticipation), strike_heavy (strike), guard, hit
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = rig.nominal_height()
		var shots := [["idle", 0], ["strike_light", -1], ["strike_heavy", -2], ["strike_heavy", -3], ["guard", 8], ["hit", 3], ["ability1", -3], ["ko", 60]]
		var i := 0
		for sh in shots:
			var act: String = sh[0]
			var fr: int = sh[1]
			var tim: Vector3i = rig.call("_timing_for", act)
			var f: int = fr
			if fr == -1: f = tim.x + 1
			elif fr == -2: f = tim.x - 2
			elif fr == -3: f = tim.x + 2
			rig.call("_begin_action", "idle", "", {})
			_step(rig, "idle", 0, 2)
			for k in range(1):
				_step(rig, act, f, 6)
			var cam: Camera3D = st["cam"]
			_frame_cam(h * 1.2, 0.0, 0.3, 1.7)
			await _save("%s/%s_act_%d_%s.png" % [out, id, i, act])
			i += 1
		rig.free()

func _expr(ids, out: String) -> void:
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 0.0
		var hp: Vector3 = rig.socket("head").global_position
		var i := 0
		for e in ["calm", "grin", "angry", "hurt", "scared", "dying"]:
			rig.set_expression(e)
			rig.face.snap()
			_step(rig, "idle", 0, 3)
			rig.face._blink_t = 99.0
			rig.face.look = Vector2.ZERO
			rig.face._look_goal = Vector2.ZERO
			rig.face._look_t = 99.0
			var cam: Camera3D = st["cam"]
			cam.look_at_from_position(hp + Vector3(2.4, 0.05, 0.0) + Vector3(0, 0, 0), hp)
			await _save("%s/%s_expr_%d_%s.png" % [out, id, i, e])
			i += 1
		rig.free()

func _lineup(ids, out: String, size: int) -> void:
	var rigs := []
	var i := 0
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		rig.position = Vector3(float(i) * 2.6 - (ids.size() - 1) * 1.3, 0, 0)
		_step(rig, "idle", 0, 4)
		rigs.append(rig)
		i += 1
	vp.size = Vector2i(size * 3, int(size * 0.9))
	var cam: Camera3D = st["cam"]
	cam.fov = 24.0
	cam.look_at_from_position(Vector3(0, 1.5, 17.5), Vector3(0, 1.05, 0))
	await _save("%s/lineup.png" % out)

func _sil(ids, out: String) -> void:
	st["env"].background_color = Color.WHITE
	st["ground"].visible = false
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 0.0
		rig.set_silhouette(true)
		_step(rig, "idle", 0, 3)
		_frame_cam(2.4, 0.0)
		await _save("%s/%s_sil.png" % [out, id])
		rig.free()

func _film(ids, out: String, action: String) -> void:
	# 8 evenly spaced frames across startup/active/recovery of one action, played in order (so lag springs and blends run)
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = rig.nominal_height()
		var tim: Vector3i = rig.call("_timing_for", action)
		var total := tim.x + tim.y + tim.z
		_step(rig, "idle", 0, 20)
		var marks := []
		for i in range(8):
			marks.append(int(float(i) / 7.0 * float(total - 1)))
		var f := 0
		var i := 0
		while f < total and i < 8:
			_step(rig, action, f, 1)
			if f >= marks[i]:
				_frame_cam(h * 1.2, 0.0, 0.3, 1.7)
				await _save("%s/%s_film_%d_%s_f%d.png" % [out, id, i, action, f])
				i += 1
			f += 1
		rig.free()
