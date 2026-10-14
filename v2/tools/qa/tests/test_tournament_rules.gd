extends RefCounted
## Tournament v2: every ladder rung carries a rule modifier, defending Champions cycle harder rules, rules reach the sim, the Hazard Ring is visible to the arena, tips are one-time.

func run() -> Array:
	var fails: Array = []
	var ladder := Career.ladder()
	if (ladder[0]["mods"] as Array).size() != 0:
		fails.append("rules: the Qualifier rung must be plain")
	for i in range(1, ladder.size()):
		var m: Array = ladder[i].get("mods", [])
		if m.is_empty():
			fails.append("rules: rung %d has no rule modifier" % i)
		for k in m:
			if not BoutConfig.RULES.has(str(k)):
				fails.append("rules: unknown modifier %s on rung %d" % [k, i])
	var c := CritterInstance.new()
	c.champion = true
	c.titles_defended = 0
	var a: Array = Career.rung_mods(ladder[ladder.size() - 1], c)
	c.titles_defended = 1
	var b: Array = Career.rung_mods(ladder[ladder.size() - 1], c)
	if a == b or a.is_empty():
		fails.append("rules: defences must cycle through different rule sets")
	var cfg := BoutConfig.new()
	cfg.mods = ["hazard", "sudden_death"]
	if cfg.rule_chip() != "RULE: HAZARD RING + SUDDEN DEATH":
		fails.append("rules: chip text is '%s'" % cfg.rule_chip())
	var arena := CombatData.arena("ring")
	var hz := arena.with_hazards([CombatData.rules()["hazard_default"]])
	if hz.hazards.size() != 1 or not arena.hazards.is_empty():
		fails.append("rules: with_hazards must copy, not mutate the shared arena")
	var sim := CombatSim.new(CombatData.critter("aruun"), CombatData.critter("mollusk"), hz, 2, 5)
	sim.apply_modifiers(["hazard"])
	if not sim.hazards_on:
		fails.append("rules: hazard modifier did not switch hazards on")
	UiPrefs.data["tips_seen"] = ""
	if Tips.seen("shelf"):
		fails.append("tips: should start unseen")
	UiPrefs.data["tips_seen"] = "shelf,rules"
	if not Tips.seen("rules") or Tips.seen("controls"):
		fails.append("tips: seen-list parsing broken")
	UiPrefs.data["tips_seen"] = ""
	# v0.28 polish: named opponents are stable and non-empty for every species; music tracks exist; music volume is a real setting
	for sp in ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]:
		var n1 := Career.opponent_name(sp, 3)
		if n1 == "" or n1 != Career.opponent_name(sp, 3):
			fails.append("names: %s needs a stable, non-empty opponent name" % sp)
	for tr in ["res://audio/music/menu.wav", "res://audio/music/bout.wav"]:
		if not ResourceLoader.exists(tr):
			fails.append("music: missing %s" % tr)
	if not Settings.DEFAULTS.has("music_volume"):
		fails.append("settings: music_volume missing")
	# v0.29 gameplay pass
	if ResultScreen.coach_tip({"player_idx": 0, "damage_dealt": [10, 80], "reason": "ko"}, "death") == "":
		fails.append("coach: a lopsided loss must get a tip")
	if ResultScreen.coach_tip({"player_idx": 0, "damage_dealt": [80, 10], "reason": "ko"}, "win") != "":
		fails.append("coach: no tip after a win")
	if "edge" not in ResultScreen.coach_tip({"player_idx": 0, "damage_dealt": [10, 10], "reason": "ringout"}, "defeat"):
		fails.append("coach: ring-out tip")
	if not bool(Settings.DEFAULTS["haptics"]):
		fails.append("settings: haptics default on")
	return fails
