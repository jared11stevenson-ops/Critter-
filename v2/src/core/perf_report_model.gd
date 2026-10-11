class_name PerfReportModel
extends RefCounted
## UI-less logic of the performance report screen: turns a Perf.report_dict() into text columns / plain text and saves it.
## The Control that shows it is perf_report_view.gd.

const GRAPH_FRAMES := 240
const GRAPH_TOP_MS := 66.0


## Left column lines (device + render + memory).
static func left_lines(r: Dictionary) -> PackedStringArray:
	var d: Dictionary = r["device"]
	var rr: Dictionary = r["render"]
	var m: Dictionary = r["memory_mb"]
	var L := PackedStringArray()
	L.append("CRITTER v%s  |  Godot %s" % [d["app_version"], d["engine"]])
	L.append("%s | %s" % [d["model"], d["os"]])
	L.append("CPU %s | RAM %d MB" % [d["cpu"], d["ram_mb"]])
	L.append("GPU %s" % d["gpu"])
	L.append("API %s | %s" % [d["gpu_api"], d["renderer"]])
	L.append("Screen %s" % d["screen"])
	L.append("Viewport %s" % d["viewport"])
	L.append("Quality %s | cap %d fps" % [d["quality"], d["fps_cap"]])
	L.append("")
	L.append("RENDER  draws %d (avg %d, peak %d)" % [rr["draws_now"], rr["draws_avg"], rr["draws_peak"]])
	L.append("  tris %dk (peak %dk) | objects peak %d" % [rr["primitives_now"] / 1000, rr["primitives_peak"] / 1000, rr["objects_peak"]])
	L.append("  nodes %d (peak %d) | orphans %d" % [rr.get("nodes_now", 0), rr["nodes_peak"], rr.get("orphan_nodes", 0)])
	L.append("  script %.1f ms | physics %.1f ms" % [r["script_ms"], r["physics_ms"]])
	L.append("MEMORY MB  static %.0f | tex %.0f | buf %.0f | video %.0f" % [m["static"], m["texture"], m["buffer"], m["video"]])
	return L


## Right column lines (frames, hitches, contexts, busiest scenes). `recording_left` < 0 when not capturing.
static func right_lines(r: Dictionary, recording_left: float = -1.0) -> PackedStringArray:
	var f: Dictionary = r["frames"]
	var h: Dictionary = r["hitch_counts"]
	var R := PackedStringArray()
	R.append("FRAMES  last %d (~%d s)%s" % [f["n"], int(r["session_seconds"]),
		"  [RECORDING %ds]" % int(ceil(recording_left)) if recording_left >= 0.0 else ""])
	R.append("  %.1f fps avg | %.1f ms" % [f["fps"], f["avg"]])
	R.append("  p50 %.1f | p95 %.1f | p99 %.1f | worst %.0f ms" % [f["p50"], f["p95"], f["p99"], f["worst"]])
	R.append("  below 30 fps %.1f%% | below 60 fps %.1f%%" % [f["under30"], f["under60"]])
	R.append("  hitches >50ms %d | >100ms %d | >250ms %d" % [h["over_50ms"], h["over_100ms"], h["over_250ms"]])
	for k in r["by_context"]:
		var e: Dictionary = r["by_context"][k]
		if e["frames"] > 0:
			R.append("%s: avg %.1f ms | worst %.0f | slow %.1f%%" % [k, e["avg_ms"], e["worst_ms"], e["slow_pct"]])
	var sc: Array = r["by_scene"].keys()
	sc.sort_custom(func(a, b): return r["by_scene"][a]["frames"] > r["by_scene"][b]["frames"])
	for k in sc.slice(0, 5):
		var e: Dictionary = r["by_scene"][k]
		R.append("%s: avg %.1f ms | worst %.0f | slow %.1f%%" % [k, e["avg_ms"], e["worst_ms"], e["slow_pct"]])
	var hs: Array = r["hitches_recent"]
	for hi in hs.slice(maxi(0, hs.size() - 5)):
		R.append("hitch t=%.0fs %.0f ms %s (%s)" % [hi["t"], hi["ms"], hi["scene"], hi["ctx"]])
	return R


## Graph bar colour for a frame time.
static func bar_color(ms: float) -> Color:
	if ms <= 17.5:
		return Color(0.4, 0.9, 0.5)
	return Color(0.95, 0.8, 0.3) if ms <= 34.0 else Color(0.95, 0.35, 0.3)


## Bar height 0..1 of the graph for a frame time.
static func bar_fraction(ms: float) -> float:
	return clampf(ms / GRAPH_TOP_MS, 0.0, 1.0)


## Plain-text report (what "Copy report" puts on the clipboard).
static func report_text(r: Dictionary) -> String:
	var d: Dictionary = r["device"]
	var f: Dictionary = r["frames"]
	var rr: Dictionary = r["render"]
	var m: Dictionary = r["memory_mb"]
	var h: Dictionary = r["hitch_counts"]
	var L := PackedStringArray()
	L.append("CRITTER 2 performance report  v%s  %s UTC" % [d["app_version"], r["time_utc"]])
	L.append("DEVICE %s | %s | %s | RAM %d MB" % [d["model"], d["os"], d["cpu"], d["ram_mb"]])
	L.append("GPU %s | %s | %s" % [d["gpu"], d["gpu_api"], d["renderer"]])
	L.append("SCREEN %s | viewport %s" % [d["screen"], d["viewport"]])
	L.append("SETTINGS quality %s | cap %d fps" % [d["quality"], d["fps_cap"]])
	L.append("FRAMES (%d, last ~%ds) avg %.1f fps %.1f ms | p50 %.1f p95 %.1f p99 %.1f worst %.1f ms" % [f["n"], int(r["session_seconds"]), f["fps"], f["avg"], f["p50"], f["p95"], f["p99"], f["worst"]])
	L.append("SLOW below 30 fps %.1f%% | below 60 fps %.1f%% | hitches >50ms %d, >100ms %d, >250ms %d" % [f["under30"], f["under60"], h["over_50ms"], h["over_100ms"], h["over_250ms"]])
	L.append("RENDER draws now %d avg %d peak %d | tris now %dk peak %dk | objects peak %d" % [rr["draws_now"], rr["draws_avg"], rr["draws_peak"], rr["primitives_now"] / 1000, rr["primitives_peak"] / 1000, rr["objects_peak"]])
	L.append("NODES now %d peak %d orphans %d | script %.1f ms physics %.1f ms" % [rr.get("nodes_now", 0), rr["nodes_peak"], rr.get("orphan_nodes", 0), r["script_ms"], r["physics_ms"]])
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


## Writes the JSON report to user:// and (if `downloads_dir` is non-empty) there too. Returns a status string.
static func save_json(r: Dictionary, stamp: String, downloads_dir: String = "") -> String:
	var json := JSON.stringify(r, "\t")
	var ok := PackedStringArray()
	var paths: Array = ["user://perf_report_%s.json" % stamp]
	if downloads_dir != "":
		paths.append(downloads_dir.path_join("critter2_perf_%s.json" % stamp))
	for p: String in paths:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(json)
			f.close()
			ok.append(ProjectSettings.globalize_path(p) if p.begins_with("user://") else p)
	return ("Saved: " + ", ".join(ok)) if not ok.is_empty() else "Could not save a file (use Copy report)"
