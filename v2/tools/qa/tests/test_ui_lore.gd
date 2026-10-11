extends RefCounted
## Result headlines, epitaphs and the one-line identities; UiPrefs round trip.

func run() -> Array:
	var fails: Array = []
	for id in CombatData.critter_ids():
		QaCheck.is_true(fails, CritterLore.line(str(id)).length() > 20, "identity line for " + str(id))
		QaCheck.is_true(fails, CritterLore.epitaph(str(id)).length() > 20, "epitaph for " + str(id))
		QaCheck.is_true(fails, CritterLore.win_line(str(id)).length() > 10, "win line for " + str(id))
	var nm := func(id): return CombatData.critter(id).display_name
	var base := {"a_id": "aruun", "b_id": "cigarra", "player_idx": 0, "reason": "ko", "killed": true, "training": false}
	var r := base.duplicate()
	r["winner"] = 0
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["tone"], "win", "player wins")
	r = base.duplicate()
	r["winner"] = 1
	var d := CritterLore.describe_result(r, nm)
	QaCheck.eq(fails, d["tone"], "death", "player killed = DEATH")
	QaCheck.eq(fails, d["title"], "DEATH", "death title")
	QaCheck.eq(fails, d["sub"], CritterLore.epitaph("aruun"), "death shows the epitaph of the player's critter")
	r["training"] = true
	r["killed"] = false
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["tone"], "defeat", "training loss is not death")
	r = base.duplicate()
	r["winner"] = 1
	r["reason"] = "yield"
	r["killed"] = false
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["tone"], "spare", "yield spares the critter")
	r = base.duplicate()
	r["winner"] = -1
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["tone"], "draw", "draw")
	r = base.duplicate()
	r["player_idx"] = 1
	r["winner"] = 1
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["tone"], "win", "player as fighter 1 wins")
	r["winner"] = 0
	QaCheck.eq(fails, CritterLore.describe_result(r, nm)["sub"], CritterLore.epitaph("cigarra"), "player as fighter 1 dies: own epitaph")
	# prefs
	UiPrefs.path_override = "user://v2_ui_prefs_test.json"
	UiPrefs.load_prefs()
	UiPrefs.set_pref("layout", "B")
	UiPrefs.set_pref("profile", "expert")
	UiPrefs.load_prefs()
	QaCheck.eq(fails, UiPrefs.get_pref("layout"), "B", "prefs persist layout")
	QaCheck.eq(fails, UiPrefs.get_pref("profile"), "expert", "prefs persist profile")
	DirAccess.remove_absolute(UiPrefs.path_override)
	UiPrefs.path_override = ""
	UiPrefs.data = {}
	UiPrefs._loaded = false
	return fails
