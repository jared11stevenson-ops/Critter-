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
	# free lock-on: an unlocked fighter faces where it moves, a locked one faces the opponent
	var sim := CombatSim.new(CombatData.critter("aruun"), CombatData.critter("zephyr"), CombatData.arena("ring"), 0, 5)
	var idle := CombatInput.new()
	var up := CombatInput.new()
	up.move = Vector2(0, 1)
	up.lock = false
	for i in 20:
		sim.step(up, idle)
	QaCheck.is_true(fails, sim.fighters[0].facing.dot(Vector2(0, 1)) > 0.9, "unlocked: facing follows the stick")
	var sim2 := CombatSim.new(CombatData.critter("aruun"), CombatData.critter("zephyr"), CombatData.arena("ring"), 0, 5)
	var up2 := CombatInput.new()
	up2.move = Vector2(0, 1)
	for i in 20:
		sim2.step(up2, idle)
	QaCheck.is_true(fails, sim2.fighters[0].facing.dot(Vector2(1, 0)) > 0.9, "locked: facing stays on the opponent")
	return fails
