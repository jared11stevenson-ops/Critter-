class_name EndCard
extends CanvasLayer
## End-of-slice card: "CRITTER DOES NOT END. IT ACCUMULATES." + what this playthrough left behind.

var _root: Control

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	Audio.music("ending")
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.05, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var tw := create_tween()
	tw.tween_property(bg, "color:a", 0.96, 1.2)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	vb.modulate.a = 0.0
	_root.add_child(vb)
	var t1 := UiKit.label("CRITTER DOES NOT END.", 56, UiKit.PARCHMENT, "solemn")
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	var t2 := UiKit.label("IT ACCUMULATES.", 56, UiKit.ACCENT_2, "solemn")
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	vb.add_child(gap)
	for line in _summary():
		var l := UiKit.label(line, 22, UiKit.PARCHMENT.darkened(0.1), "dialogue")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(1000, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 18)
	vb.add_child(gap2)
	var b := UiKit.button("Return to the Common", Vector2(380, 88), 28)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(close)
	vb.add_child(b)
	tw.tween_property(vb, "modulate:a", 1.0, 1.0)
	b.grab_focus.call_deferred()

func _summary() -> Array:
	var out: Array = []
	# Everything the Ledger remembers about this playthrough (same facts as the hub debrief card).
	var lines: Array = Ledger.debrief_lines(5, 0)
	if lines.is_empty():
		var st := str(GameState.get_flag("ochre_span", ""))
		if st == "braced":
			lines.append("The Ochre Span is braced. It will carry people for another generation.")
		elif st == "failing":
			lines.append("The Ochre Span is failing. The Dominion contract is satisfied.")
		lines.append("The Dust Grazer herd was harmed." if bool(GameState.get_flag("grazers_harmed", false)) else "The Dust Grazer herd was left in peace.")
	out.append_array(lines)
	var shifts: Array = Ledger.opinion_shift_lines(0)
	for l in shifts.slice(0, 2):
		out.append(l)
	var rl: Array = LedgerCard.rival_lines(0)
	for l in rl.slice(0, 2):
		out.append(l)
	out.append("Specimens %d · Trust Aruun %d, Cigarra %d · Codex %d" % [GameState.specimens.size(), GameState.get_trust("aruun"), GameState.get_trust("cigarra"), GameState.codex.size()])
	return out

func close() -> void:
	Audio.sfx("ui_confirm")
	Audio.music("hub")
	GameState.save_game()
	queue_free()
