class_name LedgerCard
extends CanvasLayer
## A parchment card that shows what the Ledger remembers: used for the hub debrief ("what changed because of
## you" + opinion shifts + rival outcomes) and the end card. Build with LedgerCard.debrief().

signal closed

var title := "WHAT CHANGED BECAUSE OF YOU"
var subtitle := ""
var sections: Array = []          # [{heading, lines:[String], color:Color}]
var button_text := "Continue"
var _btn: Button

static func debrief(since: int = -1, btn: String = "Continue") -> LedgerCard:
	var c := LedgerCard.new()
	c.button_text = btn
	c.sections = debrief_sections(since)
	return c

static func debrief_sections(since: int = -1) -> Array:
	var out: Array = []
	var lines: Array = Ledger.debrief_lines(6, since)
	out.append({"heading": "The world remembers", "lines": lines if not lines.is_empty() else ["The land noticed you, but nothing you did has left a mark yet."], "color": UiKit.ACCENT})
	var shifts: Array = Ledger.opinion_shift_lines(since)
	if not shifts.is_empty():
		out.append({"heading": "How they see you", "lines": shifts, "color": Color("#3d5f9a")})
	var rl: Array = rival_lines(since)
	if not rl.is_empty():
		out.append({"heading": "Rivals", "lines": rl, "color": Color("#7a4a2a")})
	return out

## One line per rival met since `since` (-1 = this run): how it ended and what they will carry forward.
static func rival_lines(since: int = -1) -> Array:
	var out: Array = []
	var s := since
	if s < 0:
		s = int(Ledger._run_start_tick)
	var seen := {}
	for e in Ledger.events_where({"type": "rival_resolved", "since": s}):
		var id := str(e["target"]).substr(6)
		if seen.has(id):
			continue
		seen[id] = true
		var r: Dictionary = Rivals.get_rival(id)
		if r.is_empty():
			continue
		var oc := str(e["data"].get("outcome", ""))
		var line := "%s %s: %s." % [str(r["title"]), str(r["name"]), _outcome_phrase(oc)]
		if oc == "escaped" and not (r["adaptations"] as Array).is_empty():
			line += " " + Rivals.adapt_line(r)
		out.append(line)
	return out

static func _outcome_phrase(oc: String) -> String:
	match oc:
		"escaped": return "got away and will remember how you fight"
		"defeated": return "stopped and detained"
		"negotiated": return "reached terms with you"
		"exposed": return "exposed; the paper trail is out"
		"released": return "was let go and has not forgotten it"
		"bonded": return "accepted a Bond Contract"
	return oc

func _ready() -> void:
	layer = 72
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.98), UiKit.PARCHMENT_DARK.darkened(0.35), 20, 5, 26))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(900, 0)
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var t := UiKit.label(title, 38, UiKit.INK, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if subtitle != "":
		var st := UiKit.label(subtitle, 22, UiKit.MUTED, "ui")
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(st)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	scroll.add_child(inner)
	for sec in sections:
		var h := UiKit.label(str(sec["heading"]).to_upper(), 22, sec.get("color", UiKit.ACCENT), "bold")
		inner.add_child(h)
		for ln in sec["lines"]:
			var l := UiKit.label("•  " + str(ln), 24, UiKit.INK, "dialogue")
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(820, 0)
			inner.add_child(l)
	_btn = UiKit.button(button_text, Vector2(320, 80), 28)
	_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn.pressed.connect(close)
	_btn.name = "Continue"
	vb.add_child(_btn)
	_btn.grab_focus.call_deferred()
	Audio.sfx("codex", -4.0)

func close() -> void:
	Audio.sfx("ui_confirm")
	closed.emit()
	queue_free()
