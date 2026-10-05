extends Node
## Always-on, near-zero-cost performance recorder (autoload `Perf`).
## Keeps the last ~60 s of real frame times, hitch events, per-scene and dialogue-vs-play stats and render peaks.
## The Settings > "Performance report" screen (game/ui/perf_report.gd) shows everything on one screen so it can be
## screenshotted, copied to the clipboard as text or saved as JSON, and a 60 s "capture" mode records a play session.

const RING := 3600
const HITCH_MS := [50.0, 100.0, 250.0]

var _ft := PackedFloat32Array()
var _ft_i := 0
var _ft_n := 0
var _last_us := 0
var _session_t := 0.0
var _frames := 0
var _hitches: Array = []                 # newest last: {t, ms, scene, ctx}
var _hitch_counts := [0, 0, 0]
var _peak := {"draws": 0, "prims": 0, "objs": 0, "nodes": 0}
var _draw_sum := 0.0
var _draw_n := 0
var _scene_stats: Dictionary = {}        # scene -> {n, sum, worst, slow}
var _ctx_stats := {"play": {"n": 0, "sum": 0.0, "worst": 0.0, "slow": 0}, "dialogue/menu": {"n": 0, "sum": 0.0, "worst": 0.0, "slow": 0}}
var _scene := "-"
var _sample_tick := 0
var _live_draws := 0
var _live_prims := 0
var _live_objs := 0

# live overlay + capture
var _layer: CanvasLayer
var _label: Label
var _overlay_t := 0.0
var capture_left := -1.0
var capture_total := 0.0
signal capture_finished


var _dialogues := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100000
	Events.dialogue_started.connect(func(_i): _dialogues += 1)
	Events.dialogue_finished.connect(func(_i): _dialogues = maxi(0, _dialogues - 1))
	_ft.resize(RING)
	_last_us = Time.get_ticks_usec()
	_layer = CanvasLayer.new()
	_layer.layer = 125
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(10, 6)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.8))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_label)
	_layer.visible = overlay_enabled()


func overlay_enabled() -> bool:
	return bool(GameState.settings.get("perf_overlay", false)) or capture_left >= 0.0


func set_overlay(on: bool) -> void:
	GameState.settings["perf_overlay"] = on
	_layer.visible = overlay_enabled()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var ms := float(now - _last_us) / 1000.0
	_last_us = now
	_session_t += ms / 1000.0
	_frames += 1
	if _frames < 3:
		return    # ignore the first frames (scene boot)
	_ft[_ft_i] = ms
	_ft_i = (_ft_i + 1) % RING
	_ft_n = mini(_ft_n + 1, RING)
	var ctx := "dialogue/menu" if (_dialogues > 0 or int(Quality.get("_covers")) > 0) else "play"
	var cs: Dictionary = _ctx_stats[ctx]
	cs["n"] += 1
	cs["sum"] += ms
	cs["worst"] = maxf(cs["worst"], ms)
	if ms > 33.4:
		cs["slow"] += 1
	var ss: Dictionary = _scene_stats.get(_scene, {"n": 0, "sum": 0.0, "worst": 0.0, "slow": 0})
	if _scene == "-":
		_sample_tick = 14    # scene not known yet: sample next frame
	ss["n"] += 1
	ss["sum"] += ms
	ss["worst"] = maxf(ss["worst"], ms)
	if ms > 33.4:
		ss["slow"] += 1
	_scene_stats[_scene] = ss
	for i in 3:
		if ms >= HITCH_MS[i]:
			_hitch_counts[i] += 1
	if ms >= HITCH_MS[0]:
		_hitches.append({"t": snappedf(_session_t, 0.1), "ms": snappedf(ms, 0.1), "scene": _scene, "ctx": ctx})
		if _hitches.size() > 60:
			_hitches.pop_front()
	_sample_tick += 1
	if _sample_tick >= 15:
		_sample_tick = 0
		_sample_render()
	if _layer.visible:
		_overlay_t -= ms / 1000.0
		if _overlay_t <= 0.0:
			_overlay_t = 0.4
			_update_overlay()
	if capture_left >= 0.0:
		capture_left -= ms / 1000.0
		if capture_left < 0.0:
			capture_left = -1.0
			_layer.visible = overlay_enabled()
			capture_finished.emit()


func _sample_render() -> void:
	var cs = get_tree().current_scene
	_scene = String(cs.name) if cs else "-"
	_live_draws = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_live_prims = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_live_objs = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_peak["draws"] = maxi(_peak["draws"], _live_draws)
	_peak["prims"] = maxi(_peak["prims"], _live_prims)
	_peak["objs"] = maxi(_peak["objs"], _live_objs)
	_peak["nodes"] = maxi(_peak["nodes"], int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	_draw_sum += _live_draws
	_draw_n += 1


func _update_overlay() -> void:
	var s := frame_stats(120)
	var txt := "%d FPS  %.1f ms  (p95 %.0f)\ndraws %d  tris %dk  nodes %d\n%s %s  %s" % [
		int(s["fps"]), s["avg"], s["p95"], _live_draws, _live_prims / 1000,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), Quality.level_name(), "%d fps cap" % Quality.fps_cap(), _scene]
	if capture_left >= 0.0:
		txt = "● RECORDING  %d s left - play normally\n%s" % [int(ceil(capture_left)), txt]
	_label.text = txt


## Frame statistics over the last `n` recorded frames (n <= RING).
func frame_stats(n: int = RING) -> Dictionary:
	n = mini(n, _ft_n)
	var out := {"n": n, "fps": 0.0, "avg": 0.0, "p50": 0.0, "p95": 0.0, "p99": 0.0, "worst": 0.0, "under30": 0.0, "under60": 0.0}
	if n <= 0:
		return out
	var a := PackedFloat32Array()
	a.resize(n)
	var sum := 0.0
	var slow30 := 0
	var slow60 := 0
	for k in n:
		var v := _ft[(_ft_i - 1 - k + RING * 2) % RING]
		a[k] = v
		sum += v
		if v > 33.4:
			slow30 += 1
		if v > 16.8:
			slow60 += 1
	a.sort()
	out["avg"] = sum / n
	out["fps"] = 1000.0 / maxf(out["avg"], 0.001)
	out["p50"] = a[n / 2]
	out["p95"] = a[mini(n - 1, int(n * 0.95))]
	out["p99"] = a[mini(n - 1, int(n * 0.99))]
	out["worst"] = a[n - 1]
	out["under30"] = 100.0 * slow30 / n
	out["under60"] = 100.0 * slow60 / n
	return out


## Last `n` frame times (ms), oldest first, for the on-screen graph.
func recent_frames(n: int) -> PackedFloat32Array:
	n = mini(n, _ft_n)
	var a := PackedFloat32Array()
	a.resize(n)
	for k in n:
		a[k] = _ft[(_ft_i - n + k + RING * 2) % RING]
	return a


func reset_stats() -> void:
	_ft_i = 0
	_ft_n = 0
	_hitches.clear()
	_hitch_counts = [0, 0, 0]
	_peak = {"draws": 0, "prims": 0, "objs": 0, "nodes": 0}
	_draw_sum = 0.0
	_draw_n = 0
	_scene_stats.clear()
	for k in _ctx_stats:
		_ctx_stats[k] = {"n": 0, "sum": 0.0, "worst": 0.0, "slow": 0}
	_session_t = 0.0


## Record a play session: clears the stats, shows the live overlay with a countdown, then emits capture_finished.
func start_capture(seconds: float = 60.0) -> void:
	reset_stats()
	capture_total = seconds
	capture_left = seconds
	_layer.visible = true


func device_info() -> Dictionary:
	var mem := OS.get_memory_info()
	var vp := get_tree().root
	return {
		"app_version": str(ProjectSettings.get_setting("application/config/version", "?")),
		"engine": str(Engine.get_version_info().get("string", "?")),
		"os": "%s %s" % [OS.get_name(), OS.get_version()],
		"model": OS.get_model_name(),
		"cpu": "%s x%d" % [OS.get_processor_name(), OS.get_processor_count()],
		"ram_mb": int(mem.get("physical", 0)) / 1048576,
		"gpu": "%s | %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()],
		"gpu_api": RenderingServer.get_video_adapter_api_version(),
		"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		"screen": "%dx%d @%sHz dpi %d" % [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y, _hz(), DisplayServer.screen_get_dpi()],
		"viewport": "%dx%d 3Dscale %.2f" % [vp.size.x, vp.size.y, vp.scaling_3d_scale],
		"quality": "%s (setting %s) shadows %s" % [Quality.level_name(), Quality.setting(), str(Quality.shadows_enabled())],
		"fps_cap": Quality.fps_cap(),
		"models_3d": bool(GameState.settings.get("use_3d_models", true)),
	}


func _hz() -> String:
	var hz := DisplayServer.screen_get_refresh_rate()
	return "%.0f" % hz if (hz > 0.0 and not is_nan(hz)) else "?"


func report_dict() -> Dictionary:
	var fs := frame_stats()
	var scenes := {}
	for k in _scene_stats:
		var e: Dictionary = _scene_stats[k]
		scenes[k] = {"frames": e["n"], "avg_ms": snappedf(e["sum"] / maxf(1.0, e["n"]), 0.1), "worst_ms": snappedf(e["worst"], 0.1), "slow_pct": snappedf(100.0 * e["slow"] / maxf(1.0, e["n"]), 0.1)}
	var ctx := {}
	for k in _ctx_stats:
		var e: Dictionary = _ctx_stats[k]
		ctx[k] = {"frames": e["n"], "avg_ms": snappedf(e["sum"] / maxf(1.0, e["n"]), 0.1), "worst_ms": snappedf(e["worst"], 0.1), "slow_pct": snappedf(100.0 * e["slow"] / maxf(1.0, e["n"]), 0.1)}
	var fr := {}
	for k in fs:
		fr[k] = snappedf(fs[k], 0.1) if fs[k] is float else fs[k]
	return {
		"device": device_info(),
		"session_seconds": snappedf(_session_t, 0.1),
		"frames": fr,
		"hitch_counts": {"over_50ms": _hitch_counts[0], "over_100ms": _hitch_counts[1], "over_250ms": _hitch_counts[2]},
		"hitches_recent": _hitches.slice(maxi(0, _hitches.size() - 12)),
		"render": {
			"draws_now": _live_draws, "draws_avg": int(_draw_sum / maxf(1.0, _draw_n)), "draws_peak": _peak["draws"],
			"primitives_now": _live_prims, "primitives_peak": _peak["prims"], "objects_peak": _peak["objs"],
			"nodes_now": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "nodes_peak": _peak["nodes"],
			"orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		},
		"memory_mb": {
			"static": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
			"texture": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
			"buffer": snappedf(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.1),
			"video": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		},
		"script_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.2),
		"physics_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.2),
		"by_scene": scenes,
		"by_context": ctx,
		"time_utc": Time.get_datetime_string_from_system(true),
	}


## Plain-text report (what the "Copy report" button puts on the clipboard).
func report_text() -> String:
	var r := report_dict()
	var d: Dictionary = r["device"]
	var f: Dictionary = r["frames"]
	var rr: Dictionary = r["render"]
	var m: Dictionary = r["memory_mb"]
	var h: Dictionary = r["hitch_counts"]
	var L: PackedStringArray = []
	L.append("CRITTER performance report  v%s  %s UTC" % [d["app_version"], r["time_utc"]])
	L.append("DEVICE %s | %s | %s | RAM %d MB" % [d["model"], d["os"], d["cpu"], d["ram_mb"]])
	L.append("GPU %s | %s | %s" % [d["gpu"], d["gpu_api"], d["renderer"]])
	L.append("SCREEN %s | viewport %s" % [d["screen"], d["viewport"]])
	L.append("SETTINGS quality %s | cap %d fps | 3D models %s" % [d["quality"], d["fps_cap"], str(d["models_3d"])])
	L.append("FRAMES (%d, last ~%ds) avg %.1f fps %.1f ms | p50 %.1f p95 %.1f p99 %.1f worst %.1f ms" % [f["n"], int(r["session_seconds"]), f["fps"], f["avg"], f["p50"], f["p95"], f["p99"], f["worst"]])
	L.append("SLOW below 30 fps %.1f%% | below 60 fps %.1f%% | hitches >50ms %d, >100ms %d, >250ms %d" % [f["under30"], f["under60"], h["over_50ms"], h["over_100ms"], h["over_250ms"]])
	L.append("RENDER draws now %d avg %d peak %d | tris now %dk peak %dk | objects peak %d" % [rr["draws_now"], rr["draws_avg"], rr["draws_peak"], rr["primitives_now"] / 1000, rr["primitives_peak"] / 1000, rr["objects_peak"]])
	L.append("NODES now %d peak %d orphans %d | script %.1f ms physics %.1f ms" % [rr["nodes_now"], rr["nodes_peak"], rr["orphan_nodes"], r["script_ms"], r["physics_ms"]])
	L.append("MEMORY MB static %.0f texture %.0f buffer %.0f video %.0f" % [m["static"], m["texture"], m["buffer"], m["video"]])
	for k in r["by_context"]:
		var e: Dictionary = r["by_context"][k]
		if e["frames"] > 0:
			L.append("CONTEXT %s: %d frames avg %.1f ms worst %.0f ms slow %.1f%%" % [k, e["frames"], e["avg_ms"], e["worst_ms"], e["slow_pct"]])
	for k in r["by_scene"]:
		var e: Dictionary = r["by_scene"][k]
		L.append("SCENE %s: %d frames avg %.1f ms worst %.0f ms slow %.1f%%" % [k, e["frames"], e["avg_ms"], e["worst_ms"], e["slow_pct"]])
	for hi in r["hitches_recent"]:
		L.append("HITCH t=%.1fs %.0f ms in %s (%s)" % [hi["t"], hi["ms"], hi["scene"], hi["ctx"]])
	return "\n".join(L)


## Writes the JSON report to user:// and, if the OS lets us, to the Downloads folder. Returns a status string.
func save_report() -> String:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	var json := JSON.stringify(report_dict(), "\t")
	var ok_paths: PackedStringArray = []
	var p := "user://perf_report_%s.json" % stamp
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.close()
		ok_paths.append(ProjectSettings.globalize_path(p))
	var dl := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if dl != "":
		var p2 := dl.path_join("critter_perf_%s.json" % stamp)
		var f2 := FileAccess.open(p2, FileAccess.WRITE)
		if f2:
			f2.store_string(json)
			f2.close()
			ok_paths.append(p2)
	return "Saved: " + ", ".join(ok_paths) if not ok_paths.is_empty() else "Could not save a file (use Copy report)"


## Opens the report screen on its own canvas layer (also used by QA scripts).
func open_report() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 130
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var p := PerfReport.new()
	layer.add_child(p)
	get_tree().root.add_child(layer)
	p.tree_exited.connect(layer.queue_free)
