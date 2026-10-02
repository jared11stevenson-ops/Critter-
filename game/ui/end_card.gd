class_name EndCard
extends CanvasLayer
## End-of-slice card: "CRITTER DOES NOT END. IT ACCUMULATES." + what this playthrough left behind.

var _root: Control

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	Audio.music("ending")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.05, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var tw := create_tween()
	tw.tween_property(bg, "color:a", 0.96, 1.2)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
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
		var l := UiKit.label(line, 26, UiKit.PARCHMENT.darkened(0.1), "dialogue")
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
	var st := str(GameState.get_flag("ochre_span", ""))
	if st == "braced":
		out.append("The Ochre Span is braced. It will carry people for another generation.")
	elif st == "failing":
		out.append("The Ochre Span is failing. The Dominion contract is satisfied.")
	out.append("The Dust Grazer herd was harmed." if bool(GameState.get_flag("grazers_harmed", false)) else "The Dust Grazer herd was left in peace.")
	if bool(GameState.get_flag("beetles_calmed", false)):
		out.append("The Plate Beetles walked away calm.")
	out.append("Specimens in your Terrarium: %d" % GameState.specimens.size())
	out.append("Trust — Aruun %d · Cigarra %d · Dominion standing %d" % [GameState.get_trust("aruun"), GameState.get_trust("cigarra"), GameState.dominion_standing])
	out.append("Codex entries: %d" % GameState.codex.size())
	return out

func close() -> void:
	Audio.sfx("ui_confirm")
	Audio.music("hub")
	GameState.save_game()
	queue_free()
