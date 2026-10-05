extends Node
## QA harness (inert unless launched with user args after "--").
## Example:
##   godot --path . -- qa qa_scene=res://game/world/red_reaches/red_reaches.tscn \
##         qa_shots=1,3,5 qa_out=/tmp/shots/rr qa_quit=6 qa_script=res://tools/qa/scripts/walk.json
## qa_script JSON: [{"t":0.5,"action":"move_right","dur":2.0}, {"t":3,"call":"GameState.set_flag","args":["x",true]},
##                  {"t":4,"tap":[640,360]}]
## Also: qa_flags=a,b (set flags true before loading), qa_items=thoughtstone_dust:3
var active := false
var _t := 0.0
var _shots: Array = []
var _out := "/tmp/qa"
var _quit := -1.0
var _script: Array = []
var _held: Dictionary = {}   # action -> release time
var _shot_i := 0
var _log_fps: Array = []
var _max_draw := 0
var _max_prims := 0
var _max_objs := 0
# bench: [[t0, t1, frames_ms[], proc_ms[], draws[], prims[]], ...]
var _bench: Array = []
var _toggles: PackedStringArray = []
var _toggle_t := 0.0
var _last_frame_us := 0
var _proc_start_us := 0
var _late: Node = null
var _last_proc_us := 0
var _cpu_start: Dictionary = {}
var _cpu_frames: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if not args.has("qa"):
		set_process(false)
		return
	active = true
	for a in args:
		if not "=" in a:
			continue
		var k: String = a.split("=")[0]
		var v: String = a.substr(k.length() + 1)
		match k:
			"qa_shots":
				for s in v.split(","):
					_shots.append(float(s))
			"qa_out": _out = v
			"qa_quit": _quit = float(v)
			"qa_script":
				var f := FileAccess.open(v, FileAccess.READ)
				if f:
					_script = JSON.parse_string(f.get_as_text())
			"qa_flags":
				for fl in v.split(","):
					GameState.set_flag(fl, true)
			"qa_items":
				for it in v.split(","):
					var p := it.split(":")
					GameState.add_item(p[0], int(p[1]) if p.size() > 1 else 1)
			"qa_bench":
				for w in v.split(","):
					var ab := w.split("-")
					_bench.append([float(ab[0]), float(ab[1]), [], [], [], []])
			"qa_quality":
				GameState.settings["gfx_quality"] = v
			"qa_fps":
				GameState.settings["fps_cap"] = int(v)
			"qa_toggle":
				_toggles = v.split("+")
			"qa_scene":
				get_tree().change_scene_to_file.call_deferred(v)
	var qn := get_node_or_null("/root/Quality")
	if qn and (GameState.settings.has("gfx_quality") or GameState.settings.has("fps_cap")):
		qn.call("apply_settings")
	if not _bench.is_empty():
		process_priority = -100000
		_late = _QALate.new()
		_late.qa = self
		add_child(_late)
	if args.has("qa_3d"):
		GameState.settings["use_3d_models"] = true
	print("[QA] active, shots=", _shots, " quit=", _quit)

## What is alive when the draw budget is blown: emitting particle systems, lights, visible 3D meshes by class of owner, 2D nodes.
func _draw_census() -> String:
	var root := get_tree().root
	var gp := 0
	var cp := 0
	var li := 0
	var mi := 0
	var l3 := 0
	var tops: Dictionary = {}
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		if g is GPUParticles3D:
			if (g as GPUParticles3D).emitting:
				gp += 1
				tops[g.get_parent().name] = int(tops.get(g.get_parent().name, 0)) + 1
		elif g is CPUParticles3D:
			if (g as CPUParticles3D).emitting:
				cp += 1
				tops[g.get_parent().name] = int(tops.get(g.get_parent().name, 0)) + 1
		elif g is Label3D:
			l3 += 1
		else:
			mi += 1
	for n in root.find_children("*", "Light3D", true, false):
		if (n as Light3D).is_visible_in_tree():
			li += 1
	var cv := 0
	for n in root.find_children("*", "CanvasItem", true, false):
		if (n as CanvasItem).is_visible_in_tree() and not (n is Container):
			cv += 1
	return "[gpu_part=%d cpu_part=%d lights=%d mesh3d=%d label3d=%d canvasitems=%d emit_parents=%s]" % [gp, cp, li, mi, l3, cv, str(tops)]


class _QALate extends Node:
	var qa: Node
	func _ready() -> void:
		process_priority = 100000
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _process(_d: float) -> void:
		qa._last_proc_us = Time.get_ticks_usec() - qa._proc_start_us


func _process(delta: float) -> void:
	_t += delta
	_log_fps.append(Engine.get_frames_per_second())
	if _t > 1.0:
		var _dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if _dc > 150 and _dc > _max_draw:
			print("[QA] DRAWS %d at t=%.1f scene=%s %s" % [_dc, _t, str(get_tree().current_scene.name) if get_tree().current_scene else "-", _draw_census()])
		_max_draw = max(_max_draw, _dc)
		_max_prims = max(_max_prims, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		_max_objs = max(_max_objs, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	_bench_tick(delta)
	if not _toggles.is_empty() and _t >= _toggle_t:
		_toggle_t = _t + 1.0
		_apply_toggles()
	# timed shots
	while _shot_i < _shots.size() and _t >= float(_shots[_shot_i]):
		var img := get_viewport().get_texture().get_image()
		var path := "%s_%02d.png" % [_out, _shot_i]
		img.save_png(path)
		print("[QA] shot ", path, " t=", snapped(_t, 0.01))
		_shot_i += 1
	# script
	for step in _script:
		if step.get("_done", false):
			continue
		if _t < float(step.get("t", 0.0)):
			continue
		step["_done"] = true
		if step.has("action"):
			Input.action_press(step["action"], float(step.get("strength", 1.0)))
			_held[step["action"]] = _t + float(step.get("dur", 0.1))
		elif step.has("call"):
			_do_call(step["call"], step.get("args", []))
		elif step.has("tap"):
			_tap(Vector2(step["tap"][0], step["tap"][1]))
		elif step.has("print"):
			print("[QA] ", step["print"])
	for action in _held.keys():
		if _t >= _held[action]:
			Input.action_release(action)
			_held.erase(action)
	if _quit > 0 and _t >= _quit:
		var avg := 0.0
		for v in _log_fps:
			avg += v
		print("[QA] quit t=", snapped(_t, 0.01), " avg_fps=", snapped(avg / max(1, _log_fps.size()), 0.1),
			" | PERF peak draw_calls=", _max_draw, " primitives=", _max_prims, " objects=", _max_objs,
			" nodes=", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			" static_mem_mb=", snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1))
		get_tree().quit()

func _bench_tick(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_ms := (now - _last_frame_us) / 1000.0 if _last_frame_us > 0 else 0.0
	_last_frame_us = now
	var proc_ms := _last_proc_us / 1000.0
	if real_ms > 250.0 and _t > 0.5:
		print("[QA] HITCH t=%.2f frame_ms=%.0f scripts_ms=%.1f" % [_t, real_ms, proc_ms])
	_proc_start_us = now
	for b in _bench:
		if _t < float(b[0]) or _t > float(b[1]):
			if _t > float(b[1]) and not b.has("_printed") and b.size() == 6:
				b.append("_printed")
				_bench_print(b)
			continue
		if (b[2] as Array).is_empty():
			b[1] = float(b[1])
			_cpu_start[b[0]] = _proc_cpu_ms()
			_cpu_frames[b[0]] = 0
		_cpu_frames[b[0]] = int(_cpu_frames[b[0]]) + 1
		(b[2] as Array).append(real_ms)
		(b[3] as Array).append(proc_ms)
		(b[4] as Array).append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		(b[5] as Array).append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))


## Process CPU time (all threads, incl. llvmpipe rasteriser threads) in ms, from /proc/self/stat. Robust against
## other processes competing for the CPU, unlike wall-clock frame time.
func _proc_cpu_ms() -> float:
	var fa := FileAccess.open("/proc/self/stat", FileAccess.READ)
	if fa == null:
		return 0.0
	var st := fa.get_line()
	if st == "":
		return 0.0
	var parts := st.substr(st.rfind(")") + 2).split(" ")
	return (float(parts[11]) + float(parts[12])) * 10.0


func _bench_print(b: Array) -> void:
	var f: Array = b[2]
	if f.is_empty():
		return
	var cpu_per_frame := (_proc_cpu_ms() - float(_cpu_start.get(b[0], 0.0))) / maxf(1.0, float(_cpu_frames.get(b[0], 1)))
	var s := f.duplicate()
	s.sort()
	var mean := func(a: Array) -> float:
		var t := 0.0
		for x in a:
			t += float(x)
		return t / maxf(1.0, a.size())
	print("[QA] BENCH %s-%s frames=%d CPU_ms/frame=%.0f | wall frame_ms avg=%.1f med=%.1f p90=%.1f max=%.1f | scripts_ms=%.2f physics_mon=%.2f | draw=%d prims=%d | q=%s toggles=%s" % [
		b[0], b[1], f.size(), cpu_per_frame, mean.call(f), s[s.size() / 2], s[int(s.size() * 0.9)], s[-1], mean.call(b[3]), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(mean.call(b[4])), int(mean.call(b[5])), GameState.settings.get("gfx_quality", "-"), "+".join(_toggles)])


## Profiling switches (qa_toggle=a+b+...): disable one rendering feature at a time to measure its cost.
func _apply_toggles() -> void:
	var root := get_tree().root
	var vp := get_viewport()
	for t in _toggles:
		match t:
			"noshadow":
				for l in root.find_children("*", "Light3D", true, false):
					(l as Light3D).shadow_enabled = false
			"nomsaa":
				vp.msaa_3d = Viewport.MSAA_DISABLED
			"noglow", "nofog", "noadj", "nosky":
				for we in root.find_children("*", "WorldEnvironment", true, false):
					var env: Environment = (we as WorldEnvironment).environment
					if env == null:
						continue
					if t == "noglow":
						env.glow_enabled = false
					elif t == "nofog":
						env.fog_enabled = false
					elif t == "noadj":
						env.adjustment_enabled = false
					else:
						env.background_mode = Environment.BG_COLOR
						env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
						env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
			"noparticles":
				for p in root.find_children("*", "GPUParticles3D", true, false):
					(p as Node3D).visible = false
				for p in root.find_children("*", "CPUParticles3D", true, false):
					(p as Node3D).visible = false
			"nomotes":
				for p in root.find_children("DustMotes", "", true, false):
					(p as Node3D).visible = false
			"noscatter":
				for p in root.find_children("Scatter", "", true, false):
					(p as Node3D).visible = false
			"nostructures":
				for p in root.find_children("Structures", "", true, false):
					(p as Node3D).visible = false
			"noterrain":
				for p in root.find_children("TerrainMesh", "", true, false):
					(p as Node3D).visible = false
			"nobackdrop":
				for p in root.find_children("Backdrop", "", true, false):
					(p as Node3D).visible = false
			"terrainflat":
				var sm := StandardMaterial3D.new()
				sm.vertex_color_use_as_albedo = false
				sm.albedo_color = Color(0.7, 0.4, 0.3)
				for p in root.find_children("Chunk_*", "MeshInstance3D", true, false):
					(p as MeshInstance3D).material_override = sm
			"nohud":
				for p in root.find_children("HUD", "", true, false):
					if p is CanvasLayer:
						(p as CanvasLayer).visible = false
			_:
				if t.begins_with("scale"):
					vp.scaling_3d_scale = float(t.substr(5))
				elif t.begins_with("aniso"):
					vp.anisotropic_filtering_level = int(t.substr(5)) as Viewport.AnisotropicFiltering


func _do_call(path: String, args: Array) -> void:
	var parts := path.split(".")
	var target: Object = null
	if get_tree().root.has_node(parts[0]):
		target = get_tree().root.get_node(parts[0])
	elif get_tree().current_scene and get_tree().current_scene.has_node(parts[0]):
		target = get_tree().current_scene.get_node(parts[0])
	elif parts[0] == "scene":
		target = get_tree().current_scene
	if target == null:
		push_warning("[QA] no target " + parts[0])
		return
	if target.has_method(parts[1]):
		target.callv(parts[1], args)
	else:
		push_warning("[QA] no method " + path)

func _tap(pos: Vector2) -> void:
	var d := InputEventScreenTouch.new()
	d.position = pos
	d.pressed = true
	Input.parse_input_event(d)
	var u := InputEventScreenTouch.new()
	u.position = pos
	u.pressed = false
	Input.parse_input_event.call_deferred(u)
