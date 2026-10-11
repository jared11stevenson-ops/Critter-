extends RefCounted
## Main flow: Title -> Select -> Opponent -> Bout -> Result, every critter can be previewed, settings panel builds, result screen builds for each tone.

func run() -> Array:
	var fails: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	var boot: Control = load("res://src/boot/boot.tscn").instantiate()
	tree.root.add_child(boot)
	QaCheck.is_true(fails, boot.screen is TitleScreen, "boots to the title")
	boot.go_select()
	QaCheck.is_true(fails, boot.screen is SelectScreen, "character select")
	var sel: SelectScreen = boot.screen
	for id in CombatData.critter_ids():
		sel._select(str(id))
		QaCheck.eq(fails, sel._preview.critter_id, str(id), "preview shows " + str(id))
		QaCheck.is_true(fails, sel._name.text.to_lower() == str(id), "name label for " + str(id))
	var chosen := [""]
	sel.chosen.connect(func(id): chosen[0] = id)
	sel._select("zephyr")
	sel._next.pressed.emit()
	QaCheck.eq(fails, boot.player_id, "zephyr", "boot remembers the player's critter")
	QaCheck.is_true(fails, boot.screen is SelectScreen and (boot.screen as SelectScreen).mode == "opponent", "opponent select follows")
	var opp: SelectScreen = boot.screen
	opp.profile = "expert"
	opp.arena_id = "hall"
	opp.training = true
	opp._select("bramvex")
	opp._next.pressed.emit()
	QaCheck.is_true(fails, boot.bout != null and boot.bout.cfg.b_id == "bramvex" and boot.bout.cfg.profile_b == "expert", "bout configured from the menus")
	QaCheck.is_true(fails, boot.bout.cfg.training and boot.bout.cfg.arena_id == "hall" and boot.bout.cfg.stakes() == 0, "training flag reaches the bout")
	for i in 30:
		boot.bout._process(1.0 / 60.0)
	QaCheck.is_true(fails, boot.bout.hud != null and boot.bout.player != null, "HUD and player input exist")
	# result screens: one per tone, buttons present
	for tone in ["win", "death", "defeat", "spare", "draw"]:
		var res := {"winner": 1 if tone in ["death", "defeat", "spare"] else (-1 if tone == "draw" else 0), "reason": "yield" if tone == "spare" else "ko",
			"killed": tone in ["win", "death"], "ticks": 3000, "vitality_ratio": [0.3, 0.0], "damage_dealt": [100.0, 200.0], "a_id": "zephyr", "b_id": "bramvex", "player_idx": 0, "training": tone == "defeat"}
		var r := ResultScreen.new()
		tree.root.add_child(r)
		r.show_result(res)
		var buttons := 0
		for n in r.find_children("*", "Button", true, false):
			buttons += 1
		QaCheck.eq(fails, buttons, 3, "result %s has rematch / change / title" % tone)
		r.free()
	boot.go_title()
	QaCheck.is_true(fails, boot.screen is TitleScreen and boot.bout == null, "back to the title frees the bout")
	var sp := SettingsPanel.new()
	tree.root.add_child(sp)
	QaCheck.is_true(fails, sp.get_child_count() > 0, "settings panel builds")
	sp.free()
	boot.free()
	return fails
