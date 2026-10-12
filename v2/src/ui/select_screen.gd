class_name SelectScreen extends Control
## Character select (mode "player") and opponent select (mode "opponent": adds AI profile, arena and the Training switch).
## All seven critters in one row; the selected one plays its real poses in a live preview with its one-line identity,
## six stats, abilities and signature resource. Pure UI: reports choices through signals, owns no game state.

signal chosen(id: String)
signal back_pressed

const STATS := [["vit", "Vitality"], ["sta", "Stamina"], ["poi", "Poise"], ["spd", "Speed"], ["rch", "Reach"], ["dmg", "Damage"]]
const ARENAS := [["ring", "Ring"], ["hall", "Hall"], ["pit", "Pit"], ["bridge", "Bridge"]]

var mode := "player"
var selected := ""
var profile := "standard"
var arena_id := "ring"
var training := false
var owned: Array = []                # when set, only these critters can be picked (Practice uses the critters you have)
var _cards: Dictionary = {}
var _preview: RigPreview
var _name: Label
var _species: Label
var _line: Label
var _stats_box: VBoxContainer
var _abil: Label
var _next: Button
var _opts_box: VBoxContainer

func setup(screen_mode: String, initial: String) -> void:
	mode = screen_mode
	selected = initial if owned.is_empty() or owned.has(initial) else str(owned[0])
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.12, 0.14)
	add_child(bg)
	var m := UiStyle.safe_margins(get_viewport())
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", int(maxf(m.x, 28)))
	mc.add_theme_constant_override("margin_right", int(maxf(m.z, 28)))
	mc.add_theme_constant_override("margin_top", int(maxf(m.y, 16)))
	mc.add_theme_constant_override("margin_bottom", int(maxf(m.w, 16)))
	add_child(mc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	mc.add_child(col)
	# header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	col.add_child(head)
	var back := UiStyle.button("< BACK", 26, Vector2(170, 64), UiStyle.PAPER_DK)
	back.pressed.connect(func(): back_pressed.emit())
	head.add_child(back)
	var title := UiStyle.label("CHOOSE YOUR CRITTER" if mode == "player" else "CHOOSE YOUR OPPONENT", 44, UiStyle.GOLD, 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(170, 1)
	head.add_child(spacer)
	# main: preview | info
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 22)
	col.add_child(main)
	var pv_panel := PanelContainer.new()
	pv_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv_panel.size_flags_stretch_ratio = 1.0
	pv_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(pv_panel)
	_preview = RigPreview.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv_panel.add_child(_preview)
	var info := PanelContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.25
	main.add_child(info)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	info.add_child(iv)
	_name = UiStyle.label("", 50, UiStyle.PAPER, 12)
	iv.add_child(_name)
	_species = UiStyle.label("", 22, UiStyle.TEAL_LT, 5)
	iv.add_child(_species)
	_line = UiStyle.label("", 22, UiStyle.PAPER, 5)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(300, 0)
	iv.add_child(_line)
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 0)
	iv.add_child(_stats_box)
	_abil = UiStyle.label("", 17, UiStyle.PAPER_DK, 4)
	_abil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abil.custom_minimum_size = Vector2(300, 0)
	iv.add_child(_abil)
	if mode == "opponent":
		var op := PanelContainer.new()
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		op.size_flags_stretch_ratio = 0.9
		main.add_child(op)
		_opts_box = VBoxContainer.new()
		_opts_box.add_theme_constant_override("separation", 10)
		op.add_child(_opts_box)
		var ol := UiStyle.label("BOUT SETUP", 30, UiStyle.GOLD, 8)
		_opts_box.add_child(ol)
		_opts_box.add_child(UiStyle.segment_row("AI OPPONENT", [["novice", "Novice"], ["standard", "Standard"], ["expert", "Expert"]], profile, func(v): profile = v, 118, 0, true))
		_opts_box.add_child(UiStyle.segment_row("ARENA", ARENAS, arena_id, func(v): arena_id = v, 96, 0, true))
		_opts_box.add_child(UiStyle.segment_row("STAKES", [["real", "Blood bout"], ["train", "Practice"]], "train" if training else "real", func(v): training = v == "train", 176, 0, true))
		var hint := UiStyle.label("Blood bout: a finishing blow is permanent death. Practice: nobody dies.", 17, UiStyle.PAPER_DK, 4)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(300, 0)
		_opts_box.add_child(hint)
	# cards + next
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(cards)
	for id in (owned if not owned.is_empty() else CombatData.critter_ids()):
		var pal: Dictionary = RigPalette.of(str(id))
		var c := CritterCard.new()
		c.setup(str(id), pal["main"], pal["glow"])
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.pressed.connect(func(): _select(str(id)))
		cards.add_child(c)
		_cards[str(id)] = c
	_next = UiStyle.button("NEXT >" if mode == "player" else "FIGHT!", 38, Vector2(190, 112), UiStyle.GOLD)
	_next.pressed.connect(func(): chosen.emit(selected))
	foot.add_child(_next)
	_select(selected)

func _select(id: String) -> void:
	selected = id
	for k in _cards:
		(_cards[k] as CritterCard).button_pressed = (k == id)
	var d := CombatData.critter(id)
	_name.text = d.display_name.to_upper()
	_species.text = "%s  -  %s     %s" % [d.species, d.archetype, Career.stars_text(id)]
	_line.text = CritterLore.line(id)
	for c in _stats_box.get_children():
		c.queue_free()
	for s in STATS:
		_stats_box.add_child(_stat_row(str(s[1]), int(d.stats.get(s[0], 0))))
	var ab := PackedStringArray()
	for k in [["ability1", "A1"], ["ability2", "A2"], ["laststand", "Last Stand"]]:
		var mv: MoveDef = d.move(str(d.move_ids.get(k[0], "")))
		if mv != null:
			ab.append("%s: %s" % [k[1], mv.name])
	var rs: Dictionary = HudDraw.RESOURCES.get(id, {})
	_abil.text = "  |  ".join(ab) + (("\nSignature resource: " + str(rs["label"]).capitalize()) if not rs.is_empty() else "")
	_preview.show_critter(id)

func _stat_row(label: String, value: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := UiStyle.label(label, 20, UiStyle.PAPER, 5)
	l.custom_minimum_size = Vector2(100, 0)
	row.add_child(l)
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(250, 22)
	pips.draw.connect(func():
		for i in 10:
			var r := Rect2(i * 25.0, 2, 21, 18)
			pips.draw_rect(r.grow(2), UiStyle.INK)
			pips.draw_rect(r, UiStyle.GOLD if i < value else Color(0.25, 0.22, 0.22)))
	row.add_child(pips)
	return row
