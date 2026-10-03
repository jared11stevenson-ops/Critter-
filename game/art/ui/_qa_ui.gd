extends Control
## QA board for the CRITTER theme + UI textures (Agent 1).


func _ready() -> void:
	theme = load("res://game/art/ui/critter_theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.3, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 40)
	panel.custom_minimum_size = Vector2(620, 300)
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var fr := TextureRect.new()
	fr.texture = load("res://game/art/portraits/cigarra/default.png")
	fr.custom_minimum_size = Vector2(120, 120)
	fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	h.add_child(fr)
	var frame := TextureRect.new()
	frame.texture = load("res://game/art/ui/frame_portrait.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	fr.add_child(frame)
	var tv := VBoxContainer.new()
	h.add_child(tv)
	var name_l := Label.new()
	name_l.theme_type_variation = "NameLabel"
	name_l.text = "Cigarra"
	tv.add_child(name_l)
	var dl := RichTextLabel.new()
	dl.bbcode_enabled = true
	dl.text = "Reality is just someone else's [b]memory[/b]. Shall we go borrow one?"
	dl.custom_minimum_size = Vector2(440, 90)
	tv.add_child(dl)
	v.add_child(HSeparator.new())
	for t in ["Follow her lead", "Hold the line"]:
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.text = t
		v.add_child(b)
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = "CRITTER"
	title.position = Vector2(720, 40)
	add_child(title)
	var sol := Label.new()
	sol.theme_type_variation = "SolemnLabel"
	sol.text = "The Ochre Span"
	sol.position = Vector2(720, 110)
	add_child(sol)
	var hud := Label.new()
	hud.theme_type_variation = "HudLabel"
	hud.text = "THOUGHTSTONE DUST x3"
	hud.position = Vector2(720, 170)
	add_child(hud)
	var dp := PanelContainer.new()
	dp.theme_type_variation = "DarkPanel"
	dp.position = Vector2(720, 220)
	add_child(dp)
	var bb := Button.new()
	bb.text = "Descend"
	dp.add_child(bb)
	var pb := ProgressBar.new()
	pb.value = 64
	pb.position = Vector2(720, 300)
	pb.custom_minimum_size = Vector2(300, 26)
	add_child(pb)
	var x := 60.0
	for f in ["joystick_base", "joystick_knob", "button_round", "button_round_pressed", "cooldown_mask"]:
		var tr := TextureRect.new()
		tr.texture = load("res://game/art/ui/%s.png" % f)
		tr.position = Vector2(x, 420)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(150, 150)
		tr.size = Vector2(150, 150)
		add_child(tr)
		x += 170.0
	var icon := TextureRect.new()
	icon.texture = load("res://game/art/icons/bad_thought.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.position = Vector2(60 + 2 * 170 + 25, 445)
	icon.size = Vector2(100, 100)
	add_child(icon)
	move_child(icon, get_child_count() - 3)
