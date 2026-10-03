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
			"qa_scene":
				get_tree().change_scene_to_file.call_deferred(v)
	print("[QA] active, shots=", _shots, " quit=", _quit)

func _process(delta: float) -> void:
	_t += delta
	_log_fps.append(Engine.get_frames_per_second())
	if _t > 1.0:
		_max_draw = max(_max_draw, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		_max_prims = max(_max_prims, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		_max_objs = max(_max_objs, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
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
