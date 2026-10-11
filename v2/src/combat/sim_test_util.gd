class_name CombatTestUtil extends RefCounted
## Helpers for scripted sims in tests and tools (no gameplay constants here).

static func make(a: String, b: String, arena_id: String = "ring", stakes: int = 1, seed_value: int = 1) -> CombatSim:
	return CombatSim.new(CombatData.critter(a), CombatData.critter(b), CombatData.arena(arena_id), stakes, seed_value)

static func face_off(sim: CombatSim, dist: float, y: float = 0.0) -> void:
	sim.fighters[0].pos = Vector2(-dist * 0.5, y)
	sim.fighters[1].pos = Vector2(dist * 0.5, y)

## Run `ticks` steps. script: Dictionary {tick:int -> [Callable(CombatInput)|null, Callable|null]} applies button
## presses on that tick; `hold_a` / `hold_b` Callables set level inputs (guard, move) on every tick.
static func run(sim: CombatSim, ticks: int, script_a: Dictionary = {}, script_b: Dictionary = {}, hold_a: Callable = Callable(), hold_b: Callable = Callable()) -> Array[Dictionary]:
	var evs: Array[Dictionary] = []
	for _i in ticks:
		var t := sim.tick + 1
		var ia := CombatInput.new()
		var ib := CombatInput.new()
		if hold_a.is_valid():
			hold_a.call(ia, t)
		if hold_b.is_valid():
			hold_b.call(ib, t)
		if script_a.has(t):
			script_a[t].call(ia)
		if script_b.has(t):
			script_b[t].call(ib)
		sim.step(ia, ib)
		evs.append_array(sim.take_events())
		if sim.is_over():
			break
	return evs

static func count(evs: Array, type: String, fighter: int = -1) -> int:
	var n := 0
	for e in evs:
		if e["type"] == type and (fighter < 0 or e["fighter"] == fighter):
			n += 1
	return n

static func first(evs: Array, type: String, fighter: int = -1) -> Dictionary:
	for e in evs:
		if e["type"] == type and (fighter < 0 or e["fighter"] == fighter):
			return e
	return {}
