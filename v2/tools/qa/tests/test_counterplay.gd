extends RefCounted
## Counterplay rules (creator): status-heavy kits are rewarded but never chain-lock; a perfect parry cleanses; skill stars are data, not strength.

func run() -> Array:
	var fails: Array = []
	var f = preload("res://src/combat/fighter.gd").new()
	f.add_status("rooted", 60)
	QaCheck.eq(fails, int(f.st["rooted"]), 60, "first root lands in full")
	f.st.erase("rooted")
	f.add_status("rooted", 60)
	QaCheck.eq(fails, int(f.st["rooted"]), 30, "a second root inside the tenacity window is half length")
	f.st.erase("slowed")
	f.add_status("slowed", 2)
	QaCheck.eq(fails, int(f.st["slowed"]), 2, "zone refreshes (2 frames) are not diminished")
	var stars := {}
	for id in CombatData.critter_ids():
		var d := CombatData.critter(id)
		QaCheck.is_true(fails, d.difficulty >= 1 and d.difficulty <= 3, "%s has a 1-3 skill rating" % id)
		stars[d.difficulty] = true
	QaCheck.is_true(fails, stars.size() == 3, "all three skill levels are used")
	QaCheck.eq(fails, CombatData.critter("aruun").difficulty, 1, "Aruun is the simple one")
	QaCheck.eq(fails, CombatData.critter("bramvex").difficulty, 3, "Bramvex demands planning")
	return fails
