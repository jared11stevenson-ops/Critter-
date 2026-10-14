class_name ResultScreen extends Control
## Result overlay shown over the frozen bout: WIN / DEATH / DEFEAT / YIELD with the critter's name, an epitaph or win line, a few
## numbers, and Rematch / Change fighters / Title. Death is shown honestly. NOTHING is persisted in this prototype (roster milestone).

signal rematch_requested
signal change_requested
signal title_requested

func show_result(res: Dictionary) -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var d := CritterLore.describe_result(res, func(id): return CombatData.critter(id).display_name)
	var tone := str(d["tone"])
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.01, 0.02, 0.55 if tone != "death" else 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var box := PanelContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)
	add_child(box)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var col := {"win": UiStyle.GOLD, "death": UiStyle.RUST, "defeat": UiStyle.PAPER_DK, "draw": UiStyle.TEAL_LT, "spare": UiStyle.TEAL_LT}[tone] as Color
	var title := UiStyle.label(str(d["title"]), 104, col, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var pi := int(res.get("player_idx", 0))
	if pi >= 0:
		var my := CombatData.critter(str(res["a_id"]) if pi == 0 else str(res["b_id"]))
		var nm := UiStyle.label(my.display_name.to_upper() + (" - " + my.species if my.species != "" else ""), 30, UiStyle.PAPER)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var nrow := HBoxContainer.new()
		nrow.alignment = BoxContainer.ALIGNMENT_CENTER
		nrow.add_theme_constant_override("separation", 12)
		nrow.add_child(Portraits.rect(str(res["a_id"]) if pi == 0 else str(res["b_id"]), 72))
		nrow.add_child(nm)
		v.add_child(nrow)
	var sub := UiStyle.label(str(d["sub"]), 28, UiStyle.PAPER, 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(820, 0)
	v.add_child(sub)
	var vr: Array = res.get("vitality_ratio", [0, 0])
	var dd: Array = res.get("damage_dealt", [0, 0])
	var secs := int(res.get("ticks", 0)) / 60
	var line := "%s  |  %d:%02d  |  damage dealt %d / %d  |  vitality left %d%% / %d%%" % [
		str(res.get("reason", "")).to_upper().replace("KO", "K.O.").replace("RINGOUT", "RING OUT"), secs / 60, secs % 60,
		int(dd[0]), int(dd[1]), int(round(float(vr[0]) * 100.0)), int(round(float(vr[1]) * 100.0))]
	var stats := UiStyle.label(line, 20, UiStyle.PAPER_DK, 5)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)
	if not bool(res.get("training", false)):
		var note := UiStyle.label("Blood Bout: the result is final and recorded in your Hall of Records." if tone != "spare" else "Yielded: your critter lives, the bout is lost.", 17, UiStyle.TEAL_LT, 4)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(note)
	var tip := coach_tip(res, tone)
	if tip != "":
		var tl := UiStyle.label("TIP: " + tip, 22, UiStyle.GOLD, 5)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(820, 0)
		v.add_child(tl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	var b1 := UiStyle.button("REMATCH", 34, Vector2(250, 92))
	b1.pressed.connect(func(): rematch_requested.emit())
	row.add_child(b1)
	var b2 := UiStyle.button("CHANGE FIGHTERS", 28, Vector2(300, 92), UiStyle.TEAL)
	b2.pressed.connect(func(): change_requested.emit())
	row.add_child(b2)
	var b3 := UiStyle.button("TITLE", 34, Vector2(200, 92), UiStyle.PAPER_DK)
	b3.pressed.connect(func(): title_requested.emit())
	row.add_child(b3)
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.35)
	for b in [b1, b2, b3]:                                             # a button-mashing finish must not skip the result
		b.disabled = true
	get_tree().create_timer(0.8).timeout.connect(func():
		for b in [b1, b2, b3]:
			if is_instance_valid(b):
				b.disabled = false)

## One piece of advice after a bout the human did not win, chosen from how it went. "" when there is nothing useful to say.
static func coach_tip(res: Dictionary, tone: String) -> String:
	var pi := int(res.get("player_idx", 0))
	if pi < 0 or tone == "win":
		return ""
	var dd: Array = res.get("damage_dealt", [0, 0])
	var mine := float(dd[pi])
	var theirs := float(dd[1 - pi])
	var reason := str(res.get("reason", ""))
	if reason == "ringout":
		return "Keep your back off the edge: sidestep along the ring and dodge out of the corners."
	if reason == "timeout":
		return "The clock favours whoever is ahead: land the first clean hit, then guard and make them come to you."
	if theirs > 0.0 and mine < theirs * 0.35:
		return "Hold GUARD just before their hit lands to PARRY: it staggers them and opens a riposte."
	if mine >= theirs * 0.8:
		return "Close fight. Save a dodge for the unblockable red tells and finish with your abilities."
	return "Watch the ! tell over their head: BLOCK on gold, DODGE on red."
