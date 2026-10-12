class_name CareerPanels
extends RefCounted
## Modal panels for the career flow (built as plain Controls; each returns the panel, signals via Callables).

static func _panel(parent: Control, w := 820.0) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(shade)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 0)
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PAPER, UiStyle.INK, 18, 5))
	shade.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	shade.set_meta("panel", p)
	v.set_meta("shade", shade)
	p.resized.connect(func(): p.position = (shade.size - p.size) * 0.5)
	return v

static func _close(v: VBoxContainer) -> void:
	(v.get_meta("shade") as Node).queue_free()

static func _txt(v: Control, s: String, size := 22, col := UiStyle.INK) -> Label:
	var l := Label.new()
	l.text = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.custom_minimum_size = Vector2(760, 0)
	v.add_child(l)
	return l

## Expedition setup: pick a region, then the critter you will RISK. on_go(region_id, uid)
static func expedition(parent: Control, r: RosterState, on_go: Callable) -> void:
	var v := _panel(parent)
	v.add_child(UiStyle.label("EXPEDITION", 38, UiStyle.INK, 0))
	_txt(v, "You must risk one of your critters to capture a new one. It can die. A capture only counts if you get it home alive.", 20, UiStyle.RUST)
	var chosen := {"region": "", "uid": ""}
	var go := UiStyle.button("DESCEND", 28, Vector2(260, 70), UiStyle.GOLD)
	go.disabled = true
	var upd := func():
		go.disabled = chosen["region"] == "" or chosen["uid"] == ""
	v.add_child(UiStyle.label("Region", 22, UiStyle.INK, 0))
	var rg := HFlowContainer.new()
	rg.add_theme_constant_override("h_separation", 6)
	rg.add_theme_constant_override("v_separation", 6)
	v.add_child(rg)
	for reg in Career.regions():
		var b := Button.new()
		b.toggle_mode = true
		b.text = "%s  (%s)" % [reg["name"], Career.species_name(str(reg["species"]))]
		b.add_theme_font_size_override("font_size", 19)
		var rid: String = reg["id"]
		b.pressed.connect(func():
			chosen["region"] = rid
			for o in rg.get_children():
				(o as Button).button_pressed = (o == b)
			upd.call())
		rg.add_child(b)
	v.add_child(UiStyle.label("Critter to risk", 22, UiStyle.INK, 0))
	var cg := HFlowContainer.new()
	cg.add_theme_constant_override("h_separation", 6)
	cg.add_theme_constant_override("v_separation", 6)
	v.add_child(cg)
	for c in Career.fighters(r):
		var b := Button.new()
		b.toggle_mode = true
		b.text = "%s  %d%%" % [c.name, int(round(c.vitality * 100.0))]
		b.add_theme_font_size_override("font_size", 19)
		var cu: String = c.uid
		b.pressed.connect(func():
			chosen["uid"] = cu
			for o in cg.get_children():
				(o as Button).button_pressed = (o == b)
			upd.call())
		cg.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	go.pressed.connect(func():
		_close(v)
		on_go.call(chosen["region"], chosen["uid"]))
	row.add_child(go)
	var cancel := UiStyle.button("CANCEL", 24, Vector2(180, 70), UiStyle.PAPER_DK)
	cancel.pressed.connect(func(): _close(v))
	row.add_child(cancel)

## Tournament: shows the next rung. on_enter(uid) / on_retire(uid) / on_defend(uid)
static func tournament(parent: Control, r: RosterState, uid: String, on_enter: Callable, on_retire: Callable) -> void:
	var c := r.get_critter(uid)
	if c == null:
		return
	var v := _panel(parent, 760)
	v.add_child(UiStyle.label("TOURNAMENT", 38, UiStyle.INK, 0))
	var rung := Career.next_rung(c)
	if c.champion:
		_txt(v, "%s is the Champion. Defend the title (every fight risks death), or retire to a peaceful life and a family." % c.name, 22)
	else:
		_txt(v, "%s enters: %s. Win to climb the ladder. Every fight is to the death for both of you." % [c.name, rung["rank"]], 22)
	var opp := Career.opponent_for_rung(rung, c)
	_txt(v, "Opponent: %s (%s)   Difficulty: %s   Prize: %d scrap" % [Career.species_name(opp), Career.role_of(opp), str(rung["profile"]), int(rung["scrap"])], 20, UiStyle.TEAL)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var go := UiStyle.button("DEFEND TITLE" if c.champion else "ENTER", 26, Vector2(240, 66), UiStyle.RUST)
	go.pressed.connect(func(): _close(v); on_enter.call(uid))
	row.add_child(go)
	if c.champion:
		var rt := UiStyle.button("RETIRE", 26, Vector2(200, 66), UiStyle.GREEN)
		rt.pressed.connect(func(): _close(v); on_retire.call(uid))
		row.add_child(rt)
	var cancel := UiStyle.button("BACK", 24, Vector2(150, 66), UiStyle.PAPER_DK)
	cancel.pressed.connect(func(): _close(v))
	row.add_child(cancel)

## Wall of the Fallen
static func wall(parent: Control, r: RosterState) -> void:
	var v := _panel(parent, 900)
	v.add_child(UiStyle.label("WALL OF THE FALLEN", 38, UiStyle.INK, 0))
	if r.wall.is_empty():
		_txt(v, "Nobody has fallen yet. Every critter you lose will be remembered here, with the chapters you read and the ones you never will.", 22)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(860, 340)
	var inner := VBoxContainer.new()
	sc.add_child(inner)
	v.add_child(sc)
	for i in range(r.wall.size() - 1, -1, -1):
		var rec: Dictionary = r.wall[i]
		var n := (rec.get("chapters_unlocked", []) as Array).size()
		_txt(inner, "%s the %s  -  %d bouts survived, %d/7 chapters read.  %s" % [rec["name"], Career.species_name(str(rec["species"])), int(rec["bouts_survived"]), n, str(rec.get("cause", ""))], 21)
		_txt(inner, "  \"%s\"" % str(rec.get("epitaph", "")), 18, UiStyle.RUST)
		for k in range(n + 1, 8):
			_txt(inner, "    chapter %d: [redacted]  - never read" % k, 16, Color(0.4, 0.35, 0.35))
	var close := UiStyle.button("CLOSE", 24, Vector2(180, 60), UiStyle.GOLD)
	close.pressed.connect(func(): _close(v))
	v.add_child(close)

## Result panel for a career bout. choices: Array of [id, label, color]; on_choice(id)
static func result(parent: Control, rep: Dictionary, choices: Array, on_choice: Callable) -> void:
	var v := _panel(parent, 820)
	var tone := str(rep["tone"])
	var col := UiStyle.GREEN if tone == "win" else (UiStyle.RUST if tone in ["death", "loss"] else UiStyle.INK)
	var head := UiStyle.label(str(rep["headline"]).to_upper(), 40, col, 0)
	v.add_child(head)
	for ln in rep["lines"]:
		_txt(v, str(ln), 22, UiStyle.RUST if tone == "death" else UiStyle.INK)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for ch in choices:
		var b := UiStyle.button(str(ch[1]), 26, Vector2(240, 70), ch[2])
		var id := str(ch[0])
		b.pressed.connect(func(): _close(v); on_choice.call(id))
		row.add_child(b)

## Scouting card before a fight. on_fight(), RETREAT closes (no cost).
static func scout(parent: Control, species: String, profile: String, place: String, on_fight: Callable) -> void:
	var info := Career.scout_info(species)
	var v := _panel(parent, 780)
	v.add_child(UiStyle.label("SCOUTING: %s" % place.to_upper(), 30, UiStyle.RUST, 0))
	v.add_child(UiStyle.label("A wild %s  (%s)" % [info["species"], info["role"]], 38, UiStyle.INK, 0))
	_txt(v, "Wins by: %s" % info["wins"], 22)
	_txt(v, "Struggles against: %s" % info["weak"], 22)
	_txt(v, "Abilities: %s" % ", ".join(info["abilities"]), 22, UiStyle.TEAL)
	_txt(v, "Wild individuals fight to survive. Skill: %s. Your critter can die here." % profile, 20, UiStyle.RUST)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var go := UiStyle.button("FIGHT", 28, Vector2(220, 70), UiStyle.RUST)
	go.pressed.connect(func(): _close(v); on_fight.call())
	row.add_child(go)
	var back := UiStyle.button("RETREAT", 26, Vector2(220, 70), UiStyle.PAPER_DK)
	back.pressed.connect(func(): _close(v))
	row.add_child(back)

static func confirm(parent: Control, head: String, text: String, yes_label: String, on_yes: Callable) -> void:
	var v := _panel(parent, 700)
	v.add_child(UiStyle.label(head, 34, UiStyle.RUST, 0))
	_txt(v, text, 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var y := UiStyle.button(yes_label, 26, Vector2(260, 66), UiStyle.RUST)
	y.pressed.connect(func(): _close(v); on_yes.call())
	row.add_child(y)
	var n := UiStyle.button("CANCEL", 26, Vector2(200, 66), UiStyle.PAPER_DK)
	n.pressed.connect(func(): _close(v))
	row.add_child(n)

static func notice(parent: Control, head: String, text: String) -> void:
	var v := _panel(parent, 700)
	v.add_child(UiStyle.label(head, 34, UiStyle.RUST, 0))
	_txt(v, text, 22)
	var ok := UiStyle.button("OK", 26, Vector2(200, 66), UiStyle.GOLD)
	ok.pressed.connect(func(): _close(v))
	v.add_child(ok)

## The Habitat Jar: the critter living in its glass jar with its species' habitat. Peaceful: no fighting happens here.
static func jar(parent: Control, c: CritterInstance) -> void:
	var v := _panel(parent, 940)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	var frame := JarFrame.new()
	frame.custom_minimum_size = Vector2(380, 420)
	row.add_child(frame)
	frame.show_critter(c.species)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	right.add_child(UiStyle.label(c.name, 40, UiStyle.INK, 0))
	_txt(right, "%s  |  %s%s" % [Career.species_name(c.species), Career.role_of(c.species), "  |  FOUNDER (first of its kind on Earth)" if c.founder else ""], 20, UiStyle.RUST).custom_minimum_size = Vector2(440, 0)
	_txt(right, str(Career.HABITAT.get(c.species, "")), 20).custom_minimum_size = Vector2(440, 0)
	_txt(right, "Habitat: peaceful. Nothing fights or dies inside a jar.", 18, UiStyle.TEAL).custom_minimum_size = Vector2(440, 0)
	_txt(right, "Vitality %d%%  |  Bouts survived %d  |  Scars %d" % [int(round(c.vitality * 100.0)), c.bouts_survived, c.scars.size()], 20).custom_minimum_size = Vector2(440, 0)
	_txt(right, "Retired critters will one day raise families here and build their own settlement from the resources you provide.", 18, Color(0.35, 0.3, 0.3)).custom_minimum_size = Vector2(440, 0)
	var close := UiStyle.button("CLOSE", 26, Vector2(200, 66), UiStyle.GOLD)
	close.pressed.connect(func(): _close(v))
	right.add_child(close)
