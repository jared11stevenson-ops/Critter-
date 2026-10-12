class_name ShelfScreen
extends Control
## The Habitat Shelf: up to 60 jars, a detail card for the selected critter (record, Life Story with locked chapters shown as redactions),
## and the career actions. Signals carry what the player chose; boot.gd runs the flow.
signal expedition_pressed
signal tournament_pressed(uid: String)
signal training_pressed(uid: String)
signal wall_pressed
signal title_pressed

const COLS := 10
var roster: RosterState
var _slots: Array[JarSlot] = []
var _sel := -1
var _detail: VBoxContainer
var _top: Label
var _btn_tourney: Button
var _btn_heal: Button
var _btn_train: Button
var _popup: Control

func setup(r: RosterState, select_uid := "") -> void:
	roster = r
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := UiStyle.safe_margins(get_viewport())
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", int(m.x) + 20)
	root.add_theme_constant_override("margin_right", int(m.z) + 20)
	root.add_theme_constant_override("margin_top", int(m.y) + 10)
	root.add_theme_constant_override("margin_bottom", int(m.w) + 10)
	add_child(root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	root.add_child(col)
	_top = UiStyle.label("", 28, UiStyle.PAPER, 6)
	col.add_child(_top)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 14)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var gwrap := PanelContainer.new()
	gwrap.add_theme_stylebox_override("panel", UiStyle.box(Color(0.14, 0.12, 0.16), UiStyle.INK, 14, 3, false))
	gwrap.add_child(grid)
	mid.add_child(gwrap)
	for i in Rack.CAPACITY:
		var s := JarSlot.new()
		s.slot = i
		s.pressed.connect(_select)
		grid.add_child(s)
		_slots.append(s)
	var dp := PanelContainer.new()
	dp.custom_minimum_size = Vector2(380, 0)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp.clip_contents = true
	dp.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PAPER, UiStyle.INK, 16, 4))
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 3)
	_detail.custom_minimum_size = Vector2(360, 0)
	dp.add_child(_detail)
	mid.add_child(dp)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	col.add_child(bar)
	var b_exp := UiStyle.button("EXPEDITION", 24, Vector2(200, 64), UiStyle.GOLD)
	b_exp.pressed.connect(func(): expedition_pressed.emit())
	bar.add_child(b_exp)
	_btn_tourney = UiStyle.button("TOURNAMENT", 24, Vector2(200, 64), UiStyle.RUST)
	_btn_tourney.pressed.connect(func(): if _uid() != "": tournament_pressed.emit(_uid()))
	bar.add_child(_btn_tourney)
	_btn_train = UiStyle.button("TRAIN", 24, Vector2(110, 64), UiStyle.TEAL_LT)
	_btn_train.pressed.connect(func(): if _uid() != "": training_pressed.emit(_uid()))
	bar.add_child(_btn_train)
	var b_jar := UiStyle.button("JAR", 24, Vector2(100, 64), UiStyle.TEAL)
	b_jar.pressed.connect(func(): if _uid() != "": CareerPanels.jar(self, roster.get_critter(_uid())))
	bar.add_child(b_jar)
	_btn_heal = UiStyle.button("HEAL (%d)" % Career.HEAL_COST, 22, Vector2(150, 64), UiStyle.GREEN)
	_btn_heal.pressed.connect(_heal)
	bar.add_child(_btn_heal)
	var b_wall := UiStyle.button("WALL", 24, Vector2(100, 64), UiStyle.PAPER_DK)
	b_wall.pressed.connect(func(): wall_pressed.emit())
	bar.add_child(b_wall)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp)
	var b_t := UiStyle.button("TITLE", 22, Vector2(100, 64), UiStyle.PAPER_DK)
	b_t.pressed.connect(func(): title_pressed.emit())
	bar.add_child(b_t)
	refresh(select_uid)

func _uid() -> String:
	if _sel < 0:
		return ""
	var c: CritterInstance = roster.rack.slots[_sel]
	return c.uid if c != null else ""

func refresh(select_uid := "") -> void:
	for i in _slots.size():
		_slots[i].set_critter(roster.rack.slots[i])
	var e := roster.economy
	_top.text = "THE SHELF   %d / %d   |   Scrap %d   Amber %d   Rep %d   |   Fallen %d" % [roster.rack.count(), Rack.CAPACITY, e.scrap, e.amber, e.reputation, roster.wall.size()]
	var want := -1
	if select_uid != "":
		want = roster.rack.slot_of(select_uid)
	elif _sel >= 0 and roster.rack.slots[_sel] != null:
		want = _sel
	else:
		for i in roster.rack.slots.size():
			if roster.rack.slots[i] != null:
				want = i
				break
	_select(want)

func _select(i: int) -> void:
	_sel = i
	for k in _slots.size():
		_slots[k].set_selected(k == i)
	_build_detail()

func _heal() -> void:
	if _uid() != "" and Career.heal(roster, _uid()):
		refresh(_uid())

func _build_detail() -> void:
	for ch in _detail.get_children():
		ch.queue_free()
	var c: CritterInstance = roster.rack.slots[_sel] if _sel >= 0 else null
	_btn_tourney.disabled = c == null or c.retired
	_btn_train.disabled = c == null or c.retired
	_btn_heal.disabled = c == null or c.vitality > 0.999 or roster.economy.scrap < Career.HEAL_COST
	if c == null:
		var l := UiStyle.label("Empty jar", 30, UiStyle.INK, 0)
		_detail.add_child(l)
		_detail.add_child(UiStyle.label("Capture critters on expeditions to fill the Shelf.", 20, UiStyle.INK, 0))
		return
	var title := UiStyle.label(c.name, 38, UiStyle.INK, 0)
	_detail.add_child(title)
	var tag := "%s  |  %s" % [Career.species_name(c.species), Career.role_of(c.species)]
	if c.founder:
		tag += "  |  FOUNDER"
	if c.champion:
		tag += "  |  CHAMPION"
	if c.retired:
		tag += "  |  RETIRED"
	_detail.add_child(UiStyle.label(tag, 20, UiStyle.RUST, 0))
	var th: Array = roster.rules.bond_thresholds if "bond_thresholds" in roster.rules else [5, 15, 30, 60, 100]
	_detail.add_child(UiStyle.label("Vitality %d%%  Bouts %d  Bond %d  Scars %d" % [int(round(c.vitality * 100.0)), c.bouts_survived, c.bond_level(th), c.scars.size()], 20, UiStyle.INK, 0))
	var rung := ""
	if not c.retired:
		rung = "Ladder: %s" % (str(Career.next_rung(c)["rank"]) if not c.champion else "defending the title (%d)" % c.titles_defended)
	_detail.add_child(UiStyle.label(rung, 18, UiStyle.TEAL, 0))
	_detail.add_child(UiStyle.label("LIFE STORY  (%d / 7)" % c.chapters_unlocked.size(), 22, UiStyle.INK, 0))
	var chs := Career.chapters_for(c.species)
	var hints := Career.chapter_hints()
	for n in 7:
		var unlocked := c.has_chapter(n + 1)
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 36)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 17)
		if unlocked:
			b.text = "%d. %s" % [n + 1, chs[n]["title"]]
			var ci := n
			b.pressed.connect(func(): _read(c, ci))
		else:
			b.text = "%d. ?????  %s" % [n + 1, hints[n]]
			b.disabled = true
		_detail.add_child(b)

func _read(c: CritterInstance, n: int) -> void:
	var chs := Career.chapters_for(c.species)
	_popup_text("%s  -  Chapter %d" % [c.name, n + 1], str(chs[n]["title"]), str(chs[n]["text"]))

func _popup_text(head: String, title: String, text: String) -> void:
	if _popup != null:
		_popup.queue_free()
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(760, 0)
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PAPER, UiStyle.INK, 18, 5))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(UiStyle.label(head, 20, UiStyle.RUST, 0))
	v.add_child(UiStyle.label(title, 36, UiStyle.INK, 0))
	var t := Label.new()
	t.text = text
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(720, 0)
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", UiStyle.INK)
	t.add_theme_constant_override("outline_size", 0)
	v.add_child(t)
	var close := UiStyle.button("CLOSE", 24, Vector2(180, 60), UiStyle.GOLD)
	close.pressed.connect(func(): p.queue_free(); _popup = null)
	v.add_child(close)
	add_child(p)
	p.position = (size - p.get_combined_minimum_size()) * 0.5
	_popup = p
