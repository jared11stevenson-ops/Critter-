class_name PerfReport
extends Control
## Performance report screen (Settings > "Performance report"): everything about how the game is running on this
## device on ONE screen, so a single screenshot (or the "Copy report" text) is enough to send to the developers.
## Buttons: Record 60 s (play normally, results appear after), Copy report, Save file, Reset, Back.

const GRAPH_FRAMES := 240
var _graph: Control
var _left: Label
var _right: Label
var _status: Label
var _blocked_3d := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.06, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Quality.set_covered(true)
	_blocked_3d = true
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_right = -18
	root.offset_top = 8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	var title := UiKit.label("PERFORMANCE REPORT  (screenshot this and send it)", 28, UiKit.PARCHMENT, "bold")
	root.add_child(title)
	_graph = Control.new()
	_graph.custom_minimum_size = Vector2(0, 92)
	_graph.draw.connect(_draw_graph)
	root.add_child(_graph)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 22)
	root.add_child(cols)
	_left = _col()
	_right = _col()
	cols.add_child(_left)
	cols.add_child(_right)
	_status = UiKit.label("", 20, UiKit.SCAN, "ui")
	root.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var live := UiKit.button("Live overlay: " + ("ON" if Perf.overlay_enabled() else "OFF"), Vector2(250, 60), 22)
	live.pressed.connect(func():
		Perf.set_overlay(not bool(GameState.settings.get("perf_overlay", false)))
		live.text = "Live overlay: " + ("ON" if bool(GameState.settings.get("perf_overlay", false)) else "OFF"))
	row.add_child(live)
	_btn(row, "Record 60 s", _on_record)
	_btn(row, "Copy report", _on_copy)
	_btn(row, "Save file", _on_save)
	_btn(row, "Reset", func(): Perf.reset_stats(); _refresh())
	_btn(row, "Back", _close)
	_refresh()
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	t.timeout.connect(_refresh)
	add_child(t)

func _btn(row: Node, text: String, cb: Callable) -> void:
	var b := UiKit.button(text, Vector2(190, 60), 22)
	b.pressed.connect(cb)
	row.add_child(b)

func _col() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", UiKit.PARCHMENT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _refresh() -> void:
	var r := Perf.report_dict()
	var d: Dictionary = r["device"]
	var f: Dictionary = r["frames"]
	var rr: Dictionary = r["render"]
	var m: Dictionary = r["memory_mb"]
	var h: Dictionary = r["hitch_counts"]
	var L: PackedStringArray = []
	L.append("CRITTER v%s  |  Godot %s" % [d["app_version"], d["engine"]])
	L.append("%s | %s" % [d["model"], d["os"]])
	L.append("CPU %s | RAM %d MB" % [d["cpu"], d["ram_mb"]])
	L.append("GPU %s" % d["gpu"])
	L.append("API %s | %s" % [d["gpu_api"], d["renderer"]])
	L.append("Screen %s" % d["screen"])
	L.append("Viewport %s" % d["viewport"])
	L.append("Quality %s | cap %d fps | 3D models %s" % [d["quality"], d["fps_cap"], str(d["models_3d"])])
	L.append("")
	L.append("RENDER  draws %d (avg %d, peak %d)" % [rr["draws_now"], rr["draws_avg"], rr["draws_peak"]])
	L.append("  tris %dk (peak %dk) | objects peak %d" % [rr["primitives_now"] / 1000, rr["primitives_peak"] / 1000, rr["objects_peak"]])
	L.append("  nodes %d (peak %d) | orphans %d" % [rr["nodes_now"], rr["nodes_peak"], rr["orphan_nodes"]])
	L.append("  script %.1f ms | physics %.1f ms" % [r["script_ms"], r["physics_ms"]])
	L.append("MEMORY MB  static %.0f | tex %.0f | buf %.0f | video %.0f" % [m["static"], m["texture"], m["buffer"], m["video"]])
	_left.text = "\n".join(L)
	var R: PackedStringArray = []
	R.append("FRAMES  last %d (~%d s)%s" % [f["n"], int(r["session_seconds"]), "  [RECORDING %ds]" % int(ceil(Perf.capture_left)) if Perf.capture_left >= 0.0 else ""])
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
	_right.text = "\n".join(R)
	_graph.queue_redraw()

func _draw_graph() -> void:
	var sz := _graph.size
	_graph.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.1, 0.1))
	var frames := Perf.recent_frames(GRAPH_FRAMES)
	if frames.is_empty():
		return
	var top := 66.0    # ms at the top of the graph
	for ms: float in [16.7, 33.3, 50.0]:
		var y: float = sz.y - (float(ms) / top) * sz.y
		_graph.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(1, 1, 1, 0.18), 1.0)
		_graph.draw_string(ThemeDB.fallback_font, Vector2(4, y - 2), "%d ms" % int(ms), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.5))
	var step := sz.x / float(GRAPH_FRAMES)
	for i in frames.size():
		var ms: float = frames[i]
		var hgt: float = clampf(ms / top, 0.0, 1.0) * sz.y
		var col := Color(0.4, 0.9, 0.5) if ms <= 17.5 else (Color(0.95, 0.8, 0.3) if ms <= 34.0 else Color(0.95, 0.35, 0.3))
		_graph.draw_rect(Rect2(i * step, sz.y - hgt, maxf(step - 0.5, 1.0), hgt), col)

func _on_copy() -> void:
	DisplayServer.clipboard_set(Perf.report_text())
	_status.text = "Report copied to the clipboard: paste it into the chat."

func _on_save() -> void:
	_status.text = Perf.save_report()

func _on_record() -> void:
	_status.text = "Recording 60 s: go back to the game, play normally (fight, talk, walk around). This screen returns when done."
	Perf.start_capture(60.0)
	if not Perf.capture_finished.is_connected(_reopen):
		Perf.capture_finished.connect(_reopen, CONNECT_ONE_SHOT)
	_close()

func _reopen() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var p := PerfReport.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 130
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(p)
	tree.root.add_child(layer)
	p.tree_exited.connect(layer.queue_free)

func _close() -> void:
	if _blocked_3d:
		Quality.set_covered(false)
		_blocked_3d = false
	queue_free()

func _exit_tree() -> void:
	if _blocked_3d:
		Quality.set_covered(false)
		_blocked_3d = false

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
