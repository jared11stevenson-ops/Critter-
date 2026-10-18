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
		Portraits.on_button(b, c.species, 40)
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
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 10)
	orow.add_child(Portraits.rect(opp, 64))
	var oname := Career.opponent_name(opp, int(c.tourney_wins) + c.titles_defended * 7)
	var otxt := _txt(orow, "Opponent: %s the %s (%s)   AI skill: %s   Prize: %d scrap" % [oname if oname != "" else "A", Career.species_name(opp), Career.role_of(opp), str(rung["profile"]), int(rung["scrap"])], 20, UiStyle.TEAL)
	otxt.custom_minimum_size = Vector2(640, 0)
	v.add_child(orow)
	var rmods: Array = Career.rung_mods(rung, c)
	if not rmods.is_empty():
		var rl := PackedStringArray()
		for m in rmods:
			rl.append("%s: %s" % [BoutConfig.rule_name(str(m)), BoutConfig.rule_line(str(m))])
		_txt(v, "Rule of this bout (same for both fighters): " + "  ".join(rl), 20, UiStyle.RUST)
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

## Hall of Records: champions and retirees, titles, discoveries and losses at a glance (the other side of the Wall of the Fallen).
static func hall(parent: Control, r: RosterState) -> void:
	var v := _panel(parent, 900)
	v.add_child(UiStyle.label("HALL OF RECORDS", 38, UiStyle.INK, 0))
	var living: Array = r.rack.living()
	var titles := 0
	var bouts := 0
	for c in living:
		titles += (c as CritterInstance).titles_defended
		bouts += (c as CritterInstance).bouts_survived
	_txt(v, "Species discovered %d / 8   |   On your shelf %d   |   Fallen %d   |   Bouts survived %d   |   Titles defended %d" % [r.species_seen.size(), living.size(), r.wall.size(), bouts, titles], 20, UiStyle.RUST)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(860, 300)
	var inner := VBoxContainer.new()
	sc.add_child(inner)
	v.add_child(sc)
	var any := false
	for c in living:
		var ci := c as CritterInstance
		if not (ci.champion or ci.retired):
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(Portraits.rect(ci.species, 46))
		var tag := "Champion (reigning)" if ci.champion else "Retired Champion"
		_txt(row, "%s the %s  -  %s, %d titles defended, %d bouts survived%s" % [ci.name, Career.species_name(ci.species), tag, ci.titles_defended, ci.bouts_survived, ", founder of its kind" if ci.founder else ""], 21).custom_minimum_size = Vector2(780, 0)
		inner.add_child(row)
	if not any:
		_txt(inner, "No champions yet. Climb the ladder (Qualifier, Bronze, Silver, Gold) and win the Champion Tournament.", 20, Color(0.35, 0.3, 0.3))
	var missing: Array = []
	for sp in ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]:
		if not r.species_seen.has(sp):
			missing.append(Career.species_name(sp))
	if not missing.is_empty():
		_txt(v, "Not yet discovered: " + ", ".join(missing), 18, UiStyle.TEAL)
	var close := UiStyle.button("CLOSE", 24, Vector2(180, 60), UiStyle.GOLD)
	close.pressed.connect(func(): _close(v))
	v.add_child(close)

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
		var wr := HBoxContainer.new()
		wr.add_theme_constant_override("separation", 10)
		var wp := Portraits.rect(str(rec["species"]), 46)
		wp.modulate = Color(0.7, 0.7, 0.7)
		wr.add_child(wp)
		inner.add_child(wr)
		var wl := _txt(wr, "%s the %s  -  %d bouts survived, %d/7 chapters read.  %s" % [rec["name"], Career.species_name(str(rec["species"])), int(rec["bouts_survived"]), n, str(rec.get("cause", ""))], 21)
		wl.custom_minimum_size = Vector2(780, 0)
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
	var v := _panel(parent, 900)
	v.add_child(UiStyle.label("SCOUTING: %s" % place.to_upper(), 30, UiStyle.RUST, 0))
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 12)
	srow.add_child(Portraits.rect(species, 84))
	srow.add_child(UiStyle.label("A wild %s  (%s)  %s" % [info["species"], info["role"], Career.stars_text(species)], 36, UiStyle.INK, 0))
	v.add_child(srow)
	_txt(v, "Wins by: %s" % info["wins"], 22).custom_minimum_size = Vector2(840, 0)
	_txt(v, "Habit to watch for: %s" % info["weak"], 22).custom_minimum_size = Vector2(840, 0)
	_txt(v, "Abilities: %s" % ", ".join(info["abilities"]), 22, UiStyle.TEAL).custom_minimum_size = Vector2(840, 0)
	_txt(v, "Wild individuals fight to survive. Skill: %s. Your critter can die here. Choose how to approach:" % profile, 20, UiStyle.RUST).custom_minimum_size = Vector2(840, 0)
	var msg := _txt(v, " ", 20, UiStyle.RUST)
	msg.custom_minimum_size = Vector2(840, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for id in ["stalk", "direct", "provoke"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)
		var b := UiStyle.button(str(Career.APPROACHES[id]["name"]), 26, Vector2(260, 66), UiStyle.RUST if id == "direct" else UiStyle.GOLD)
		var ap: String = id
		b.pressed.connect(func():
			var why: String = on_fight.call(ap)
			if why == "":
				_close(v)
			else:
				msg.text = why)
		col.add_child(b)
		_txt(col, str(Career.APPROACHES[id]["blurb"]), 17, Color(0.3, 0.25, 0.25)).custom_minimum_size = Vector2(260, 0)
	var back := UiStyle.button("RETREAT", 24, Vector2(200, 60), UiStyle.PAPER_DK)
	back.pressed.connect(func(): _close(v))
	v.add_child(back)

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

## Move list of a species: its role, how it tends to win, what beats it (as a skill answer, never a stat), and its three abilities.
static func move_card(parent: Control, species: String) -> void:
	var info := Career.scout_info(species)
	var v := _panel(parent, 700)
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 10)
	hr.add_child(Portraits.rect(species, 56))
	hr.add_child(UiStyle.label("%s  MOVES" % str(info["species"]).to_upper(), 34, UiStyle.INK, 0))
	v.add_child(hr)
	_txt(v, "%s  |  %s" % [str(info["role"]), Career.stars_text(species)], 22, UiStyle.RUST)
	_txt(v, "Wins by: %s" % str(info["wins"]), 20)
	_txt(v, "Troubled by: %s" % str(info["weak"]), 20)
	var ab: Array = info["abilities"]
	for i in ab.size():
		_txt(v, "%d.  %s" % [i + 1, str(ab[i])], 24, UiStyle.TEAL)
	_txt(v, "Every critter also has Strike, Heavy, Guard (parry), Dodge, Grab and a Last Stand.", 18, Color(0.35, 0.3, 0.3))
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
	var hb := Career.roster().habitat(c.species)
	frame.set_habitat(hb, Career.roster().retired_adults(c.species).size(), c.species)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 10)
	nrow.add_child(Portraits.rect(c.species, 64))
	nrow.add_child(UiStyle.label(c.name, 40, UiStyle.INK, 0))
	right.add_child(nrow)
	_txt(right, "%s  |  %s  |  %s%s" % [Career.species_name(c.species), Career.role_of(c.species), Career.stars_text(c.species), "  |  FOUNDER (first of its kind on Earth)" if c.founder else ""], 20, UiStyle.RUST).custom_minimum_size = Vector2(440, 0)
	_txt(right, str(Career.HABITAT.get(c.species, "")), 20).custom_minimum_size = Vector2(440, 0)
	_txt(right, "Habitat: peaceful. Nothing fights or dies inside a jar.", 18, UiStyle.TEAL).custom_minimum_size = Vector2(440, 0)
	_txt(right, "Vitality %d%%  |  Bouts survived %d  |  Scars %d" % [int(round(c.vitality * 100.0)), c.bouts_survived, c.scars.size()], 20).custom_minimum_size = Vector2(440, 0)
	var moves := UiStyle.button("MOVES", 24, Vector2(200, 60), UiStyle.TEAL_LT)
	moves.pressed.connect(func(): move_card(v.get_meta("shade") as Control, c.species))
	right.add_child(moves)
	var close := UiStyle.button("CLOSE", 26, Vector2(200, 66), UiStyle.GOLD)
	close.pressed.connect(func(): _close(v))
	right.add_child(close)
	var hab := VBoxContainer.new()
	hab.add_theme_constant_override("separation", 6)
	v.add_child(hab)
	_habitat_block(hab, c.species)


## Habitat Jar status + allocation: the player only feeds, supplies and expands; the critters breed and build.
static func _habitat_block(box: VBoxContainer, species: String) -> void:
	for ch in box.get_children():
		ch.queue_free()
	var r := Career.roster()
	var h := r.habitat(species)
	var adults := r.retired_adults(species).size()
	var sep := HSeparator.new()
	box.add_child(sep)
	_txt(box, "HABITAT  |  %s  |  Day %d  |  Family %d / %d  |  Generations %d" % [h.stage_name(adults), h.day, h.descendants.size() + adults, h.capacity(), h.generations], 22, UiStyle.RUST).custom_minimum_size = Vector2(900, 0)
	var nx := h.next_structure()
	var built := ", ".join(h.structures.map(func(i): return Habitat.ladder(species)[i]["name"])) if not h.structures.is_empty() else "nothing yet"
	_txt(box, "Food %d (+%d/day)  |  Materials %d  |  Built: %s" % [h.food, h.food_rate(), h.materials, built], 20).custom_minimum_size = Vector2(900, 0)
	if not nx.is_empty():
		var why := "" if adults + h.descendants.size() >= int(nx["pop_req"]) else "  (needs a family of %d)" % int(nx["pop_req"])
		_txt(box, "They will build next: %s (%d materials)%s" % [nx["name"], int(nx["materials"]), why], 20, UiStyle.TEAL).custom_minimum_size = Vector2(900, 0)
	if adults == 0 and h.descendants.is_empty():
		_txt(box, "No family yet: only a retired critter of this species can start one. Win the Champion Tournament and retire.", 18, Color(0.35, 0.3, 0.3)).custom_minimum_size = Vector2(900, 0)
	if not h.log.is_empty():
		_txt(box, h.log[h.log.size() - 1], 18, Color(0.35, 0.3, 0.3)).custom_minimum_size = Vector2(900, 0)
	var msg := _txt(box, "Scrap %d  |  Settlement tribute waiting: %d" % [r.economy.scrap, h.tribute], 20)
	msg.custom_minimum_size = Vector2(900, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for spec in [["COLLECT", "collect", UiStyle.GOLD], ["FEED (%d)" % int(Habitat.cfg()["feed_cost_scrap"]), "feed", UiStyle.GREEN],
			["SUPPLY (%d)" % int(Habitat.cfg()["supply_cost_scrap"]), "supply", UiStyle.TEAL], ["EXPAND (%d)" % int(Habitat.cfg()["expand_cost_scrap"]), "expand", UiStyle.TEAL],
			["WATCH", "watch", UiStyle.PAPER_DK], ["LINK (%d)" % h.link_cost(), "link", UiStyle.PAPER_DK]]:
		var b := UiStyle.button(spec[0], 20, Vector2(140, 56), spec[2])
		var kind: String = spec[1]
		b.pressed.connect(func():
			if kind == "watch":
				watch(box.get_parent().get_parent() as Control, species)
				return
			if kind == "link":
				link_panel(box.get_parent().get_parent() as Control, species, func(): _habitat_block(box, species))
				return
			var res := Career.habitat_action(species, kind)
			_habitat_block(box, species)
			if res != "":
				_txt(box, res, 18, UiStyle.RUST))
		row.add_child(b)


## Practice: nobody dies, nothing counts. Pick any sparring partner and how hard it plays.
static func practice(parent: Control, owned: Array, on_go: Callable) -> void:
	var v := _panel(parent, 760)
	v.add_child(UiStyle.label("PRACTICE", 38, UiStyle.INK, 0))
	_txt(v, "Nobody dies and nothing counts. Spar against any critter in the game.", 20, UiStyle.TEAL)
	var chosen := {"opp": str(owned[0]), "profile": "standard"}
	var og := HFlowContainer.new()
	og.add_theme_constant_override("h_separation", 6)
	og.add_theme_constant_override("v_separation", 6)
	v.add_child(og)
	for sp in owned:
		var b := Button.new()
		b.toggle_mode = true
		b.text = "%s  %s" % [Career.species_name(str(sp)), "★".repeat(Career.stars_of(str(sp)))]
		b.add_theme_font_size_override("font_size", 20)
		Portraits.on_button(b, str(sp), 40)
		b.button_pressed = (sp == chosen["opp"])
		var spid: String = str(sp)
		b.pressed.connect(func():
			chosen["opp"] = spid
			for o in og.get_children():
				(o as Button).button_pressed = (o == b))
		og.add_child(b)
	var pg := HBoxContainer.new()
	pg.add_theme_constant_override("separation", 6)
	v.add_child(pg)
	for pid in ["novice", "standard", "expert"]:
		var pb := Button.new()
		pb.toggle_mode = true
		pb.text = pid.capitalize()
		pb.add_theme_font_size_override("font_size", 20)
		pb.button_pressed = (pid == "standard")
		var pp: String = pid
		pb.pressed.connect(func():
			chosen["profile"] = pp
			for o in pg.get_children():
				(o as Button).button_pressed = (o == pb))
		pg.add_child(pb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var go := UiStyle.button("SPAR", 28, Vector2(220, 68), UiStyle.TEAL_LT)
	go.pressed.connect(func(): _close(v); on_go.call(chosen["opp"], chosen["profile"]))
	row.add_child(go)
	var back := UiStyle.button("CANCEL", 24, Vector2(200, 68), UiStyle.PAPER_DK)
	back.pressed.connect(func(): _close(v))
	row.add_child(back)


## Observe a jar: the monarch, the family by generation with roles and ages, and what happened lately.
static func watch(parent: Control, species: String) -> void:
	var r := Career.roster()
	var h := r.habitat(species)
	var v := _panel(parent, 940)
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 12)
	wrow.add_child(Portraits.rect(species, 64))
	wrow.add_child(UiStyle.label("WATCHING THE %s JAR" % Career.species_name(species).to_upper(), 32, UiStyle.INK, 0))
	v.add_child(wrow)
	var adults := r.retired_adults(species)
	var crown := h.founder_name if h.founder_name != "" else "no founder yet"
	var head := "Founding monarch: %s%s" % [crown, "  (fallen; the record remains)" if h.monarch_fallen else ""]
	_txt(v, head, 22, UiStyle.RUST).custom_minimum_size = Vector2(880, 0)
	if h.monarch_fallen and not h.regent().is_empty():
		_txt(v, "Regent (the eldest keeps the jar for now): %s" % h.regent()["name"], 20, UiStyle.TEAL).custom_minimum_size = Vector2(880, 0)
	for a in adults:
		_txt(v, "Retired: %s%s" % [a.name, "  (champion)" if a.champion else ""], 20).custom_minimum_size = Vector2(880, 0)
	if h.descendants.is_empty():
		_txt(v, "No family yet.", 20, Color(0.35, 0.3, 0.3)).custom_minimum_size = Vector2(880, 0)
	for line in h.lineage_lines():
		_txt(v, str(line), 19).custom_minimum_size = Vector2(880, 0)
	var roles := "Builders %d (-%d%% structure cost)  |  Foragers %d (+%d food/day)  |  Storytellers %d  |  Festivals held %d" % [
		h.role_count("builder"), int(h.build_discount() * 100.0), h.role_count("forager"), h.role_count("forager") / 2, h.role_count("storyteller"), h.festivals]
	_txt(v, roles, 18, UiStyle.TEAL).custom_minimum_size = Vector2(880, 0)
	if not h.links.is_empty():
		_txt(v, "Passages to: %s" % ", ".join(h.links.map(func(s): return Career.species_name(str(s)))), 18, UiStyle.TEAL).custom_minimum_size = Vector2(880, 0)
	var recent := h.log.slice(maxi(0, h.log.size() - 5))
	for l in recent:
		_txt(v, str(l), 17, Color(0.35, 0.3, 0.3)).custom_minimum_size = Vector2(880, 0)
	var close := UiStyle.button("CLOSE", 24, Vector2(200, 60), UiStyle.GOLD)
	close.pressed.connect(func(): _close(v))
	v.add_child(close)


## Open a passage to another jar on the shelf (resource exchange; the jars stay peaceful).
static func link_panel(parent: Control, species: String, on_done: Callable) -> void:
	var r := Career.roster()
	var h := r.habitat(species)
	var v := _panel(parent, 760)
	v.add_child(UiStyle.label("OPEN A PASSAGE", 34, UiStyle.INK, 0))
	_txt(v, "Linked jars share surplus food and every passage earns a little tribute. Cost %d scrap. Up to 3 passages." % h.link_cost(), 20, UiStyle.TEAL)
	var msg := _txt(v, " ", 20, UiStyle.RUST)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	v.add_child(fl)
	for sp in r.habitats:
		if sp == species:
			continue
		var b := UiStyle.button("%s%s" % [Career.species_name(str(sp)), " (linked)" if h.links.has(sp) else ""], 20, Vector2(220, 56), UiStyle.TEAL_LT)
		var other: String = str(sp)
		b.disabled = h.links.has(sp)
		b.pressed.connect(func():
			var why := r.link_jars(species, other)
			Career._autosave("link")
			if why == "":
				_close(v)
				on_done.call()
			else:
				msg.text = why)
		fl.add_child(b)
	var close := UiStyle.button("CLOSE", 24, Vector2(200, 60), UiStyle.PAPER_DK)
	close.pressed.connect(func(): _close(v))
	v.add_child(close)


## Exploration: three stops on the way to the wild critter. Same odds for every critter.
static func explore(parent: Control, place: String, nodes: Array, ctx: Dictionary, rng: RandomNumberGenerator, on_done: Callable, index := 0) -> void:
	if index >= nodes.size():
		on_done.call()
		return
	var node: Dictionary = nodes[index]
	var v := _panel(parent, 860)
	v.add_child(UiStyle.label("%s: STOP %d OF %d" % [place.to_upper(), index + 1, nodes.size()], 28, UiStyle.RUST, 0))
	v.add_child(UiStyle.label(str(node["title"]), 38, UiStyle.INK, 0))
	_txt(v, str(node["text"]), 22).custom_minimum_size = Vector2(800, 0)
	var res := _txt(v, " ", 20, UiStyle.TEAL)
	res.custom_minimum_size = Vector2(800, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var next_btn := UiStyle.button("CONTINUE", 26, Vector2(240, 66), UiStyle.GOLD)
	next_btn.visible = false
	for ch in node["choices"]:
		var col := VBoxContainer.new()
		row.add_child(col)
		var b := UiStyle.button(str(ch["label"]), 22, Vector2(250, 66), UiStyle.TEAL_LT)
		var cid: String = str(ch["id"])
		b.pressed.connect(func():
			res.text = Career.explore_resolve(Career.roster(), ctx, cid, rng)
			for o in row.get_children():
				for bb in o.get_children():
					if bb is Button:
						(bb as Button).disabled = true
			next_btn.visible = true)
		col.add_child(b)
		_txt(col, str(ch["hint"]), 17, Color(0.3, 0.25, 0.25)).custom_minimum_size = Vector2(250, 0)
	v.add_child(next_btn)
	next_btn.pressed.connect(func():
		_close(v)
		var skip := int(ctx.get("skip", 0)) > 0
		if skip:
			ctx["skip"] = int(ctx["skip"]) - 1
		explore(parent, place, nodes, ctx, rng, on_done, index + (2 if skip else 1)))
	var back := UiStyle.button("TURN BACK", 22, Vector2(200, 56), UiStyle.PAPER_DK)
	back.pressed.connect(func(): _close(v))
	v.add_child(back)
