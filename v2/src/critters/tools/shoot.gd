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
var no_shadow := false

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
		"fx": await _fx(ids, out)
		"walk": await _walk(ids, out)
		"perf": await _perf(ids)
		"ortho": await _ortho(ids, out)
		"states": await _states(ids, out)
		"portrait": await _portrait(ids, out)
	quit()

func _spawn(id: String) -> Node3D:
	var rig = Rig.new()
	world.add_child(rig)
	rig.setup(id)
	rig.three_quarter = 0.0
	if not no_shadow:
		Stage.blob_shadow(rig, 0.9)
	return rig

func _frame_cam(h: float, yaw_deg: float, center_x: float = 0.0, fit: float = 1.18, tilt: float = 0.14) -> void:
	var cam: Camera3D = st["cam"]
	var d: float = (h * fit * 0.5) / tan(deg_to_rad(cam.fov * 0.5))
	var y := deg_to_rad(yaw_deg)
	var sun: DirectionalLight3D = st["sun"]
	sun.rotation_degrees = Vector3(-30, yaw_deg + 35.0, 0)   # key light follows the camera so every view is front-lit
	cam.look_at_from_position(Vector3(center_x, h * 0.5, 0) + Vector3(sin(y), tilt, cos(y)).normalized() * d, Vector3(center_x, h * 0.48, 0))

func _ext(rig: Node3D) -> float:
	# framing extent: tall or wide, whichever is bigger (weapons and wings count)
	var b: AABB = rig.bounds
	return maxf(b.end.y, maxf(b.size.x, b.size.z) * 0.8)

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
		var h: float = _ext(rig)
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
		var h: float = _ext(rig)
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
			_frame_cam(h * 1.1, 0.0, 0.25 * h / 2.0, 1.75)
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
		rig.position = Vector3(float(i) * 4.6 - (ids.size() - 1) * 2.3, 0, 0)
		_step(rig, "idle", 0, 4)
		rigs.append(rig)
		i += 1
	vp.size = Vector2i(size * 3, int(size * 0.62))
	var cam: Camera3D = st["cam"]
	cam.fov = 22.0
	cam.look_at_from_position(Vector3(0, 2.0, 27.0), Vector3(0, 1.6, 0))
	await _save("%s/lineup.png" % out)

func _sil(ids, out: String) -> void:
	no_shadow = true
	st["env"].background_mode = Environment.BG_COLOR
	st["env"].background_color = Color.WHITE
	st["ground"].visible = false
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 0.0
		rig.set_silhouette(true)
		_step(rig, "idle", 0, 3)
		_frame_cam(_ext(rig) * 1.05, 0.0, 0.0, 1.25)
		await _save("%s/%s_sil.png" % [out, id])
		rig.free()

func _film(ids, out: String, action: String) -> void:
	# 8 evenly spaced frames across startup/active/recovery of one action, played in order (so lag springs and blends run)
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = _ext(rig)
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
				_frame_cam(h * 1.1, 0.0, 0.25 * h / 2.0, 1.75)
				await _save("%s/%s_film_%d_%s_f%d.png" % [out, id, i, action, f])
				i += 1
			f += 1
		rig.free()

func _fx(ids, out: String) -> void:
	# swing smear, hit spark, impact-frame inversion
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = _ext(rig)
		var tim: Vector3i = rig.call("_timing_for", "strike_heavy")
		_step(rig, "idle", 0, 10)
		for f in range(0, tim.x + 3):
			_step(rig, "strike_heavy", f, 1)
		_frame_cam(h * 1.1, 0.0, 0.25 * h / 2.0, 1.75)
		await _save("%s/%s_fx_0_smear.png" % [out, id])
		_step(rig, "hit", 2, 1)
		rig.play_event({"type": "hit", "heavy": false})
		_step(rig, "hit", 3, 1)
		await _save("%s/%s_fx_1_spark.png" % [out, id])
		rig.play_event({"type": "hit", "heavy": true})
		_step(rig, "hit", 4, 1)
		await _save("%s/%s_fx_2_impact.png" % [out, id])
		rig.free()

func _walk(ids, out: String) -> void:
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = _ext(rig)
		_step(rig, "idle", 0, 10)
		for i in range(8):
			_step(rig, "walk", i, 5, {"speed": 1.0})
			_frame_cam(h * 1.05, 0.0, 0.0, 1.6)
			await _save("%s/%s_film_%d_walk.png" % [out, id, i])
		rig.free()

func _info(what: int) -> int:
	return int(RenderingServer.get_rendering_info(what))

## Measured draw calls / primitives in a real frame (baseline = empty stage with ground, subtracted). Software GL counts match hardware counts.
func _perf(ids) -> void:
	no_shadow = true
	st["ground"].visible = false
	await process_frame
	await process_frame
	var base_d := _info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var base_p := _info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("PERF baseline draws=%d prims=%d" % [base_d, base_p])
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 30.0
		_step(rig, "idle", 0, 3)
		_frame_cam(_ext(rig), 0.0)
		await process_frame
		await process_frame
		var d := _info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) - base_d
		var p := _info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) - base_p
		# worst case: heavy strike active (smear visible) + spark
		var tim: Vector3i = rig.call("_timing_for", "strike_heavy")
		for f in range(0, tim.x + 3):
			_step(rig, "strike_heavy", f, 1)
		rig.play_event({"type": "hit", "heavy": false})
		_step(rig, "strike_heavy", tim.x + 3, 1)
		await process_frame
		await process_frame
		var dw := _info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) - base_d
		var pw := _info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) - base_p
		print("PERF %s idle draws=%d tris=%d | worst(strike+smear+spark) draws=%d tris=%d" % [id, d, p, dw, pw])
		rig.free()

## Orthographic model-sheet views (front = camera on +X, side = +Z, back = -X, top = +Y) in A-pose, plus part pivot positions in screen space
## (JSON) for the label overlay. Output: <id>_ortho_<view>.png and <id>_ortho.json {view: {px_per_m, center, parts: {name: [x, y]}}}.
func _ortho(ids, out: String) -> void:
	no_shadow = true
	st["ground"].visible = false
	st["env"].background_mode = Environment.BG_COLOR
	st["env"].background_color = Color(0.82, 0.83, 0.85)
	st["env"].ambient_light_color = Color(0.7, 0.72, 0.78)
	var res := 640
	vp.size = Vector2i(res, res)
	var cam: Camera3D = st["cam"]
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	for id in ids:
		var rig = _spawn(id)
		rig.apose_deg = 35.0
		rig.three_quarter = 0.0
		_step(rig, "idle", 0, 3)
		rig.fx.smear.visible = false
		var b: AABB = rig.bounds
		var ext := maxf(b.end.y, maxf(b.size.x, b.size.z)) * 1.12
		var center := Vector3(b.position.x + b.size.x * 0.5, b.end.y * 0.5, b.position.z + b.size.z * 0.5)
		cam.size = ext
		var js := {}
		for v in [["front", Vector3(1, 0, 0)], ["side", Vector3(0, 0, 1)], ["back", Vector3(-1, 0, 0)], ["top", Vector3(0, 1, 0)]]:
			var dirv: Vector3 = v[1]
			var up := Vector3.UP if v[0] != "top" else Vector3(-1, 0, 0)
			var cpos := center + dirv * 30.0
			if v[0] != "top":
				cpos.y = center.y
			cam.look_at_from_position(cpos, center if v[0] == "top" else Vector3(center.x, center.y, center.z), up)
			st["sun"].rotation_degrees = Vector3(-35, 35.0 + (0 if v[0] == "front" else (90 if v[0] == "side" else (180 if v[0] == "back" else 0))), 0)
			await _save("%s/%s_ortho_%s.png" % [out, id, v[0]])
			var parts := {}
			for pn in ["head", "torso", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]:
				var nd: Node3D = rig.part(pn)
				if nd:
					var sp := cam.unproject_position(nd.global_position)
					parts[pn] = [sp.x / res, sp.y / res]
			for sn in ["weapon_tip", "hand", "head", "weapon_base"]:
				var sk: Node3D = rig.socket(sn)
				var sp2 := cam.unproject_position(sk.global_position)
				parts["@" + sn] = [sp2.x / res, sp2.y / res]
			var gp := cam.unproject_position(Vector3(center.x, 0, center.z))
			js[v[0]] = {"px_per_m": res / ext, "ground": [gp.x / res, gp.y / res], "parts": parts, "center": [center.x, center.y, center.z]}
		var f := FileAccess.open("%s/%s_ortho.json" % [out, id], FileAccess.WRITE)
		f.store_string(JSON.stringify(js))
		f.close()
		rig.free()

## Gameplay-state frames: rage + cracked plates (low vitality), mid-throw (detached part), orbiting crown, future ghosts, compel.
func _states(ids, out: String) -> void:
	for id in ids:
		var rig := _spawn(id)
		rig.three_quarter = 35.0
		var h: float = _ext(rig)
		var i := 0
		for st_def in [["rage_cracked", "idle", 0, {"rage": 1.0, "vitality_ratio": 0.2}], ["detached", "ability1", -1, {"vitality_ratio": 0.8}], ["ghosts", "ability1", -2, {"vitality_ratio": 0.8}]]:
			var tim: Vector3i = rig.call("_timing_for", st_def[1])
			var fr: int = st_def[2]
			if fr == -1: fr = tim.x + 6
			if fr == -2: fr = tim.x + 3
			for f in range(0, fr + 1):
				_step(rig, st_def[1], f, 1, st_def[3])
			await process_frame
			_frame_cam(h * 1.1, 0.0, 0.25 * h / 2.0, 1.9)
			await _save("%s/%s_state_%d_%s.png" % [out, id, i, st_def[0]])
			i += 1
			_step(rig, "idle", 0, 90)
		rig.free()


## Character icons: a head-and-shoulders bust on a flat tinted backdrop (the sheet tool crops it round and rings it).
const PORTRAIT_DIST := {"aruun": 3.4, "cigarra": 2.7, "bramvex": 3.0, "scarlith": 4.2, "mollusk": 3.9, "zephyr": 3.2, "nyxaris": 4.4, "pharilux": 5.2}
const PORTRAIT_LIFT := {"aruun": 0.2, "cigarra": 0.1, "bramvex": 0.0, "scarlith": 0.3, "mollusk": 0.05, "zephyr": 0.1, "nyxaris": 0.3, "pharilux": 0.6}
func _portrait(ids, out: String) -> void:
	vp.size = Vector2i(256, 256)
	no_shadow = true
	st["ground"].visible = false
	for id in ids:
		var pal: Dictionary = Pal.get_pal(id)
		var bg: Color = (pal["main"] as Color).darkened(0.55).lerp(Color(0.1, 0.1, 0.12), 0.35)
		st["env"].background_mode = Environment.BG_COLOR
		st["env"].background_color = bg
		var rig := _spawn(id)
		rig.three_quarter = 32.0
		_step(rig, "idle", 0, 4)
		var hp: Vector3 = rig.socket("head").global_position + Vector3(0, float(PORTRAIT_LIFT.get(id, 0.2)), 0)
		var cam: Camera3D = st["cam"]
		cam.fov = 28.0
		var d: float = float(PORTRAIT_DIST.get(id, 4.0))
		var zf: float = 0.95 if id == "aruun" else 0.38
		cam.look_at_from_position(hp + Vector3(d * 0.92 * (0.75 if id == "aruun" else 1.0), 0.12 * d, d * zf), hp)
		var sun: DirectionalLight3D = st["sun"]
		sun.rotation_degrees = Vector3(-22, 67, 0)
		await _save("%s/%s_portrait.png" % [out, id])
		rig.free()
