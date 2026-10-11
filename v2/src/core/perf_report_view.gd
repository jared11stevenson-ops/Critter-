class_name PerfReportView
extends Control
## Performance report screen (view only). All formatting lives in PerfReportModel; data comes from the Perf autoload.
## Buttons: live overlay toggle, Record 60 s, Copy report, Save file, Reset, Back. Open with Perf.open_report().

var _graph: Control
var _left: Label
var _right: Label
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.06, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_right = -18
	root.offset_top = 8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	var title := Label.new()
	title.text = "PERFORMANCE REPORT  (screenshot this and send it)"
	title.add_theme_font_size_override("font_size", 28)
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
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 20)
	root.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var live := _btn(row, "Live overlay: " + ("ON" if Perf.overlay_enabled() else "OFF"), Callable())
	live.pressed.connect(func():
		Perf.set_overlay(not Perf.overlay_enabled())
		live.text = "Live overlay: " + ("ON" if Perf.overlay_enabled() else "OFF"))
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


func _btn(row: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(190, 60)
	b.add_theme_font_size_override("font_size", 22)
	if cb.is_valid():
		b.pressed.connect(cb)
	row.add_child(b)
	return b


func _col() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 17)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _refresh() -> void:
	var r := Perf.report_dict()
	_left.text = "\n".join(PerfReportModel.left_lines(r))
	_right.text = "\n".join(PerfReportModel.right_lines(r, Perf.capture_left))
	_graph.queue_redraw()


func _draw_graph() -> void:
	var sz := _graph.size
	_graph.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.1, 0.1))
	var frames := Perf.recent_frames(PerfReportModel.GRAPH_FRAMES)
	if frames.is_empty():
		return
	for ms: float in [16.7, 33.3, 50.0]:
		var y: float = sz.y - PerfReportModel.bar_fraction(ms) * sz.y
		_graph.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(1, 1, 1, 0.18), 1.0)
		_graph.draw_string(ThemeDB.fallback_font, Vector2(4, y - 2), "%d ms" % int(ms), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.5))
	var step := sz.x / float(PerfReportModel.GRAPH_FRAMES)
	for i in frames.size():
		var hgt: float = PerfReportModel.bar_fraction(frames[i]) * sz.y
		_graph.draw_rect(Rect2(i * step, sz.y - hgt, maxf(step - 0.5, 1.0), hgt), PerfReportModel.bar_color(frames[i]))


func _on_copy() -> void:
	DisplayServer.clipboard_set(Perf.report_text())
	_status.text = "Report copied to the clipboard."


func _on_save() -> void:
	_status.text = Perf.save_report()


func _on_record() -> void:
	_status.text = "Recording 60 s: go back to the game and play normally. This screen returns when done."
	Perf.start_capture(60.0)
	if not Perf.capture_finished.is_connected(_reopen):
		Perf.capture_finished.connect(_reopen, CONNECT_ONE_SHOT)
	_close()


func _reopen() -> void:
	Perf.open_report()


func _close() -> void:
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
