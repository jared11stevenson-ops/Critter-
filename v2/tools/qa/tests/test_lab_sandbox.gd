extends RefCounted
## Lab safety: an in-memory move override changes the sim for that run only; reloading data restores the shipped values, and the lab tool cannot persist anything.

func run() -> Array:
	var fails: Array = []
	var shipped: Dictionary = CombatData.read_json("res://data/moves/bramvex.json")["moves"]["bramvex_diplomacy1"]
	var raw: Dictionary = (shipped as Dictionary).duplicate(true)
	raw["startup"] = int(shipped["startup"]) + 9
	CombatData.critter("bramvex").moves["bramvex_diplomacy1"] = MoveDef.from_dict("bramvex_diplomacy1", raw)
	if CombatData.critter("bramvex").move("bramvex_diplomacy1").startup != int(shipped["startup"]) + 9:
		fails.append("lab: the in-memory override did not apply")
	var r: Dictionary = Tournament.run_bout("bramvex", "aruun", "standard", "standard", 3)
	if not r.has("winner"):
		fails.append("lab: a bout with an overridden move must still finish")
	CombatData.reload()
	if CombatData.critter("bramvex").move("bramvex_diplomacy1").startup != int(shipped["startup"]):
		fails.append("lab: reload must restore the shipped frame data")
	var src := FileAccess.get_file_as_string("res://tools/lab/evolve_moves.gd")
	if "FileAccess.WRITE" in src and not ("res://tools/out/lab/" in src):
		fails.append("lab: the evolve tool may only write under tools/out/lab")
	if "data/moves" in src and "WRITE" in src.substr(src.find("data/moves"), 200):
		fails.append("lab: the evolve tool must never write data/moves")
	return fails
