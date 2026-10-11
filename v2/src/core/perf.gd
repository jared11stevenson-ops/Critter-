extends Node
## Autoload `Perf`: always-on, near-zero-cost performance recorder (ported from v1, v1 dependencies removed).
## Statistics live in PerfStats (pure, tested). This node feeds it, samples render monitors, draws the optional
## live overlay and supports a timed capture. The report screen is perf_report_view.gd; text lives in perf_report_model.gd.
## Set `context` ("play" / "menu") from the bout / menu code so stats split by where the player is.

signal capture_finished

var stats := PerfStats.new()
var context := "play"
var capture_left := -1.0
var capture_total := 0.0
var overlay_forced := false

var _last_us := 0
var _frames := 0
var _scene := "-"
var _sample_tick := 0
var _layer: CanvasLayer
var _label: Label
var _overlay_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100000
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


func _setting(key: String, fallback: Variant) -> Variant:
	var s := get_node_or_null("/root/Settings")
	return s.get_value(key) if s else fallback


func overlay_enabled() -> bool:
	return bool(_setting("perf_overlay", false)) or capture_left >= 0.0 or overlay_forced


func set_overlay(on: bool) -> void:
	var s := get_node_or_null("/root/Settings")
	if s:
		s.set_value("perf_overlay", on)
	else:
		overlay_forced = on
	if _layer:
		_layer.visible = overlay_enabled()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var ms := float(now - _last_us) / 1000.0
	_last_us = now
	_frames += 1
	if _frames < 3:
		return    # ignore the first frames (scene boot)
	if _scene == "-":
		_sample_tick = 14    # scene not known yet: sample next frame
	stats.record_frame(ms, _scene, context)
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
	var cs := get_tree().current_scene
	_scene = String(cs.name) if cs else "-"
	stats.record_render(
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))


func _update_overlay() -> void:
	var s := stats.frame_stats(120)
	var txt := "%d FPS  %.1f ms  (p95 %.0f)\ndraws %d  tris %dk  nodes %d\n%s %d fps cap  %s" % [
		int(s["fps"]), s["avg"], s["p95"], stats.live["draws"], stats.live["prims"] / 1000,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), str(_setting("quality", 1)), int(_setting("fps_cap", 60)), _scene]
	if capture_left >= 0.0:
		txt = "RECORDING  %d s left - play normally\n%s" % [int(ceil(capture_left)), txt]
	_label.text = txt


func frame_stats(n: int = PerfStats.RING) -> Dictionary:
	return stats.frame_stats(n)


func recent_frames(n: int) -> PackedFloat32Array:
	return stats.recent_frames(n)


func reset_stats() -> void:
	stats.reset()


## Record a play session: clears the stats, shows the overlay with a countdown, then emits capture_finished.
func start_capture(seconds: float = 60.0) -> void:
	reset_stats()
	capture_total = seconds
	capture_left = seconds
	_layer.visible = true


func device_info() -> Dictionary:
	var mem := OS.get_memory_info()
	var vp := get_tree().root
	var hz := DisplayServer.screen_get_refresh_rate()
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
		"screen": "%dx%d @%sHz dpi %d" % [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y,
			("%.0f" % hz) if (hz > 0.0 and not is_nan(hz)) else "?", DisplayServer.screen_get_dpi()],
		"viewport": "%dx%d 3Dscale %.2f" % [vp.size.x, vp.size.y, vp.scaling_3d_scale],
		"quality": str(_setting("quality", 1)),
		"fps_cap": int(_setting("fps_cap", 60)),
	}


func report_dict() -> Dictionary:
	var r := stats.core_report()
	r["device"] = device_info()
	r["render"]["nodes_now"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	r["render"]["orphan_nodes"] = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	r["memory_mb"] = {
		"static": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"texture": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"buffer": snappedf(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.1),
		"video": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
	}
	r["script_ms"] = snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.2)
	r["physics_ms"] = snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.2)
	r["time_utc"] = Time.get_datetime_string_from_system(true)
	return r


func report_text() -> String:
	return PerfReportModel.report_text(report_dict())


## Writes the JSON report to user:// and, if the OS allows, to Downloads. Returns a status string.
func save_report() -> String:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	return PerfReportModel.save_json(report_dict(), stamp, OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS))


## Opens the report screen on its own canvas layer (also used by QA scripts).
func open_report() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 130
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var p := PerfReportView.new()
	layer.add_child(p)
	get_tree().root.add_child(layer)
	p.tree_exited.connect(layer.queue_free)
