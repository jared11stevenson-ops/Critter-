extends RefCounted
## Rule-modifier flags (design/v2/ROLES.md): each must change the sim measurably; default is none.
const U = preload("res://src/combat/sim_test_util.gd")

func run() -> Array:
	var fails: Array = []
	var base := U.make("aruun", "mollusk")
	if not base.state()["modifiers"].is_empty() or base.fighters[0].max_vit != U.make("aruun", "mollusk").fighters[0].max_vit:
		fails.append("modifiers: default must be none")
	# sudden death: halved vitality
	var sd := U.make("aruun", "mollusk")
	sd.apply_modifiers(["sudden_death"])
	if absf(sd.fighters[0].max_vit - base.fighters[0].max_vit * 0.5) > 0.01 or absf(sd.fighters[0].vit - sd.fighters[0].max_vit) > 0.01:
		fails.append("modifiers: sudden_death should halve vitality")
	# endurance: more stamina and vitality, longer timeout
	var en := U.make("aruun", "mollusk")
	en.apply_modifiers(["endurance"])
	if en.fighters[0].max_sta <= base.fighters[0].max_sta or en.fighters[0].max_vit <= base.fighters[0].max_vit or en.timeout_frames <= base.timeout_frames:
		fails.append("modifiers: endurance should raise stamina, vitality and the timeout")
	var idle_a := U.make("mollusk", "mollusk")
	U.run(idle_a, int(CombatData.rules()["timeout_ticks"]) + 5)
	var idle_b := U.make("mollusk", "mollusk")
	idle_b.apply_modifiers(["endurance"])
	U.run(idle_b, int(CombatData.rules()["timeout_ticks"]) + 5)
	if not idle_a.is_over() or idle_b.is_over():
		fails.append("modifiers: endurance bout should outlast the normal timeout")
	# hazard: a default hazard hurts a fighter standing in the middle of a hazard-free ring
	var hz_off := U.make("mollusk", "mollusk")
	hz_off.fighters[0].pos = Vector2.ZERO
	U.run(hz_off, 90)
	var hz_on := U.make("mollusk", "mollusk")
	hz_on.apply_modifiers(["hazard"])
	hz_on.fighters[0].pos = Vector2.ZERO
	U.run(hz_on, 90)
	if hz_off.fighters[0].vit < hz_off.fighters[0].max_vit or hz_on.fighters[0].vit >= hz_on.fighters[0].max_vit:
		fails.append("modifiers: hazard should hurt only when enabled")
	# ringout: knock-back carries farther
	var d_off := _knock_distance([])
	var d_on := _knock_distance(["ringout"])
	if d_on <= d_off * 1.2:
		fails.append("modifiers: ringout should add edge knock-back (%f vs %f)" % [d_on, d_off])
	# gauntlet: flagged in the result with carry-over vitality for the caller
	var g := U.make("aruun", "mollusk")
	g.apply_modifiers(["gauntlet"])
	g.fighters[0].vit = g.fighters[0].max_vit * 0.4
	U.run(g, 3, {2: func(i: CombatInput) -> void: i.yield_pressed = true})
	var res := g.result()
	if not res.get("gauntlet", false) or absf(float(res["carry"][0]) - 0.4) > 0.05:
		fails.append("modifiers: gauntlet should flag the result and report carry-over vitality")
	# fog: no tell indicators
	var fog := U.make("aruun", "mollusk")
	fog.apply_modifiers(["fog"])
	U.face_off(fog, 2.0)
	var evs := U.run(fog, 5, {1: func(i: CombatInput) -> void: i.strike_tap = true})
	var tell := U.first(evs, "tell", 0)
	var plain := U.make("aruun", "mollusk")
	U.face_off(plain, 2.0)
	var tell2 := U.first(U.run(plain, 5, {1: func(i: CombatInput) -> void: i.strike_tap = true}), "tell", 0)
	if not tell.get("hidden", false) or tell2.get("hidden", false) or fog.state()["fighters"][0]["tell_anim"] != "":
		fails.append("modifiers: fog should hide tell indicators")
	return fails

func _knock_distance(mods: Array) -> float:
	var sim := U.make("aruun", "mollusk")
	sim.apply_modifiers(mods)
	U.face_off(sim, 1.8)
	var x0: float = sim.fighters[1].pos.x
	U.run(sim, 80, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	return sim.fighters[1].pos.x - x0
