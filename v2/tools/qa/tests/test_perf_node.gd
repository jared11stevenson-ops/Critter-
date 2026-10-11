extends RefCounted
## Runtime smoke of the Perf autoload and the report view (no autoload registration needed).

const PerfScript := preload("res://src/core/perf.gd")

func run() -> Array:
	var fails: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	var perf := PerfScript.new()
	perf.name = "Perf"
	tree.root.add_child(perf)
	for i in 8:
		perf._process(0.016)
	var r: Dictionary = perf.report_dict()
	for k in ["device", "frames", "render", "memory_mb", "by_scene", "by_context", "time_utc", "script_ms"]:
		QaCheck.is_true(fails, r.has(k), "report has " + k)
	QaCheck.is_true(fails, perf.report_text().begins_with("CRITTER 2 performance report"), "report text")
	perf.set_overlay(true)
	QaCheck.is_true(fails, perf.overlay_enabled(), "overlay forced without Settings")
	perf.start_capture(1.0)
	QaCheck.is_true(fails, perf.capture_left > 0.0, "capture running")
	perf.reset_stats()
	var view := PerfReportView.new()
	tree.root.add_child(view)
	QaCheck.is_true(fails, view.get_child_count() > 0, "view built")
	view._refresh()
	QaCheck.is_true(fails, view._left.text.find("CRITTER v") >= 0, "view shows the report")
	view.free()
	perf.free()
	return fails
