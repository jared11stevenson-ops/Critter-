extends RefCounted

func run() -> Array:
	var fails: Array = []
	var p := PerfStats.new()
	QaCheck.eq(fails, p.frame_stats()["n"], 0, "empty stats")
	for i in 100:
		p.record_frame(16.0, "Bout", "play")
	p.record_frame(60.0, "Bout", "play")
	p.record_frame(120.0, "Menu", "menu")
	p.record_frame(300.0, "Menu", "menu")
	var fs := p.frame_stats()
	QaCheck.eq(fails, fs["n"], 103, "frame count")
	QaCheck.near(fails, fs["worst"], 300.0, "worst frame")
	QaCheck.near(fails, fs["p50"], 16.0, "median", 0.01)
	QaCheck.eq(fails, p.hitch_counts, [3, 2, 1], "hitch counts")
	QaCheck.eq(fails, p.hitches.size(), 3, "hitch log")
	QaCheck.near(fails, fs["under30"], 300.0 / 103.0, "under30 pct", 0.01)
	var rf := p.recent_frames(3)
	QaCheck.near(fails, rf[2], 300.0, "recent newest last")
	QaCheck.near(fails, rf[0], 60.0, "recent oldest first")
	# ring wraps
	var q := PerfStats.new()
	for i in PerfStats.RING + 50:
		q.record_frame(10.0 if i < PerfStats.RING else 20.0)
	QaCheck.eq(fails, q.frame_stats()["n"], PerfStats.RING, "ring capped")
	QaCheck.near(fails, q.recent_frames(1)[0], 20.0, "ring newest")
	# hitch log capped at 60
	var h := PerfStats.new()
	for i in 80:
		h.record_frame(70.0)
	QaCheck.eq(fails, h.hitches.size(), 60, "hitch log cap")
	# render stats
	p.record_render(100, 50000, 40, 300)
	p.record_render(140, 60000, 45, 280)
	var r := p.core_report()
	QaCheck.eq(fails, r["render"]["draws_peak"], 140, "draw peak")
	QaCheck.eq(fails, r["render"]["draws_avg"], 120, "draw avg")
	QaCheck.eq(fails, r["render"]["nodes_peak"], 300, "node peak")
	QaCheck.eq(fails, r["by_scene"]["Menu"]["frames"], 2, "scene frames")
	QaCheck.eq(fails, r["by_context"]["menu"]["frames"], 2, "ctx frames")
	p.reset()
	QaCheck.eq(fails, p.frame_stats()["n"], 0, "reset")
	# report model formatting works on a full dict
	var full := r.duplicate(true)
	full["device"] = {"app_version": "0.1", "engine": "4.7", "os": "L", "model": "m", "cpu": "c", "ram_mb": 1, "gpu": "g",
		"gpu_api": "a", "renderer": "r", "screen": "s", "viewport": "v", "quality": "1", "fps_cap": 60}
	full["memory_mb"] = {"static": 1.0, "texture": 1.0, "buffer": 1.0, "video": 1.0}
	full["script_ms"] = 1.0
	full["physics_ms"] = 1.0
	full["time_utc"] = "now"
	QaCheck.is_true(fails, PerfReportModel.report_text(full).find("HITCH") >= 0, "report text has hitches")
	QaCheck.is_true(fails, PerfReportModel.left_lines(full).size() > 5, "left lines")
	QaCheck.is_true(fails, PerfReportModel.right_lines(full, 12.0)[0].find("RECORDING") >= 0, "recording tag")
	QaCheck.near(fails, PerfReportModel.bar_fraction(1000.0), 1.0, "bar clamp")
	return fails
