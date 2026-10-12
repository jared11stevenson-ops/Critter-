extends RefCounted
## Career rules: tutorial critter, expedition (risk -> win -> seal -> extraction -> capture), permadeath on the Wall, tournament ladder to Champion, retire, 60-critter Shelf, founders.

func _res(winner: int, killed := false, vr := [0.5, 0.0], mr := [0.4, 0.0]) -> Dictionary:
	return {"winner": winner, "reason": "ko", "killed": killed, "loser": 1 - winner, "vitality_ratio": vr, "min_ratio": mr, "training": false}

func run() -> Array:
	var fails: Array = []
	var r := RosterState.new()
	var aruun := r.seal("aruun", "Aruun")
	QaCheck.is_true(fails, aruun != null and aruun.founder, "the first critter of a species is its founder")
	var second := r.seal("aruun", "Tamsin")
	QaCheck.is_true(fails, second != null and not second.founder, "a second of the species is not a founder")
	QaCheck.eq(fails, Rack.CAPACITY, 60, "the Shelf holds 60")
	# expedition win -> capture offer, no death
	var rep := Career.resolve(r, {"kind": "expedition", "uid": aruun.uid, "opp_species": "cigarra", "region": "canopy_fold"}, _res(0))
	QaCheck.is_true(fails, bool(rep["capture_offer"]) and not bool(rep["died"]), "expedition win offers sealing")
	QaCheck.is_true(fails, aruun.bouts_survived == 1, "a survived real bout counts")
	# extraction win -> captured, first cigarra is a founder
	var before := r.rack.count()
	rep = Career.resolve(r, {"kind": "extraction", "uid": aruun.uid, "opp_species": "zephyr", "captive": "cigarra"}, _res(0))
	QaCheck.is_true(fails, rep.has("captured") and r.rack.count() == before + 1, "extraction success adds the capture")
	QaCheck.is_true(fails, bool(rep["captured"]["founder"]), "first cigarra is the founding monarch")
	# extraction loss -> nothing captured
	before = r.rack.count()
	rep = Career.resolve(r, {"kind": "extraction", "uid": aruun.uid, "opp_species": "zephyr", "captive": "nyxaris"}, _res(1, false, [0.3, 0.9], [0.1, 0.9]))
	QaCheck.is_true(fails, not rep.has("captured") and r.rack.count() == before, "failed extraction loses the captive")
	# permadeath
	var doomed := r.seal("scarlith", "Rind")
	rep = Career.resolve(r, {"kind": "tournament", "uid": doomed.uid, "rung": 0, "opp_species": "mollusk"}, _res(1, true, [0.0, 0.8], [0.0, 0.8]))
	QaCheck.is_true(fails, bool(rep["died"]) and r.get_critter(doomed.uid) == null, "a killed critter is removed")
	QaCheck.is_true(fails, r.is_fallen(doomed.uid) and r.wall.size() == 1, "and recorded on the Wall")
	QaCheck.is_true(fails, str(rep["lines"][0]) != "", "death has an epitaph")
	# tournament ladder to champion, then retire
	var champ := r.seal("mollusk", "Pebble")
	var wins := 0
	for i in 5:
		rep = Career.resolve(r, {"kind": "tournament", "uid": champ.uid, "rung": champ.tourney_wins, "opp_species": "zephyr"}, _res(0))
		wins += 1
	QaCheck.is_true(fails, champ.champion, "five ladder wins make a Champion")
	QaCheck.is_true(fails, Career.retire(r, champ.uid) and champ.retired, "a champion can retire")
	QaCheck.is_true(fails, not Career.fighters(r).has(champ), "retired critters no longer fight")
	QaCheck.is_true(fails, not Career.retire(r, aruun.uid), "a non-champion cannot retire")
	# tournament loss resets the ladder
	var t := r.seal("zephyr", "Whisk")
	Career.resolve(r, {"kind": "tournament", "uid": t.uid, "rung": 0, "opp_species": "aruun"}, _res(0))
	QaCheck.eq(fails, t.tourney_wins, 1, "ladder step")
	Career.resolve(r, {"kind": "tournament", "uid": t.uid, "rung": 1, "opp_species": "aruun"}, _res(1, false, [0.2, 0.9], [0.2, 0.9]))
	QaCheck.eq(fails, t.tourney_wins, 0, "a tournament loss resets the ladder")
	# save round trip keeps the new fields
	var d := r.to_dict()
	var r2 := RosterState.new()
	r2.load_dict(JSON.parse_string(JSON.stringify(d)))
	var back := r2.get_critter(champ.uid)
	QaCheck.is_true(fails, back != null and back.retired and back.champion and back.founder, "retired/champion/founder survive a save")
	QaCheck.is_true(fails, r2.species_seen.has("scarlith") and r2.wall.size() == r.wall.size(), "species seen and the Wall survive a save")
	# 60-critter cap
	var big := RosterState.new()
	var made := 0
	for i in 70:
		if big.seal("aruun", "A%d" % i) != null:
			made += 1
	QaCheck.eq(fails, made, 60, "the Shelf stops at 60")
	# chapter content: 7 per species, hints, regions
	for sp in ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris"]:
		QaCheck.eq(fails, Career.chapters_for(sp).size(), 7, "%s has 7 chapters" % sp)
		QaCheck.is_true(fails, Career.role_of(sp) != "Fighter", "%s has a role" % sp)
	QaCheck.eq(fails, Career.regions().size(), 8, "eight expedition regions")
	# expedition approaches
	var ar := RosterState.new()
	var drifter := ar.seal("zephyr", "Whisk")
	var ctx := {"kind": "expedition", "uid": drifter.uid, "region": "frostbloom", "opp_species": "nyxaris", "profile": "standard"}
	QaCheck.is_true(fails, Career.apply_approach(ar, ctx, "stalk") != "", "stalking costs bait the player may not have")
	ar.economy.add("scrap", 20)
	QaCheck.eq(fails, Career.apply_approach(ar, ctx, "stalk"), "", "stalk with scrap works")
	QaCheck.is_true(fails, absf(float(ctx["opp_vit"]) - 0.8) < 0.001 and ar.economy.scrap == 15, "stalking: prey at 80%, bait spent (same for every role)")
	ctx["profile"] = "standard"
	Career.apply_approach(ar, ctx, "provoke")
	QaCheck.is_true(fails, ctx["profile"] == "expert" and float(ctx["haul"]) > 1.5, "provoke raises the AI and the haul")
	var sc0 := ar.economy.scrap
	var rr := Career.resolve(ar, {"kind": "expedition", "uid": drifter.uid, "opp_species": "nyxaris", "region": "frostbloom", "haul": 1.7}, _res(0))
	QaCheck.is_true(fails, ar.economy.scrap > sc0 and ar.habitat("zephyr").materials > 0 and bool(rr["capture_offer"]), "an expedition win pays scrap and jar materials")
	# exploration
	var er := RosterState.new()
	var ex := er.seal("aruun", "Aruun")
	var rg := RandomNumberGenerator.new()
	rg.seed = 5
	var nodes := Career.explore_nodes("frostbloom", rg)
	QaCheck.eq(fails, nodes.size(), 3, "three stops per trip")
	QaCheck.is_true(fails, nodes[0]["id"] != nodes[1]["id"] and nodes[1]["id"] != nodes[2]["id"], "stops are distinct")
	var ectx := {"uid": ex.uid}
	var sc_before := er.economy.scrap
	Career.explore_resolve(er, ectx, "study", rg)
	Career.explore_resolve(er, ectx, "study", rg)
	QaCheck.is_true(fails, absf(Career.studied_vit(ectx) - 0.86) < 0.001, "two studies: wild critter at 86%")
	Career.explore_resolve(er, ectx, "forage", rg)
	QaCheck.is_true(fails, er.economy.scrap > sc_before and er.habitat("aruun").materials > 0, "foraging pays scrap and jar materials")
	ex.vitality = 0.5
	Career.explore_resolve(er, ectx, "rest", rg)
	QaCheck.is_true(fails, ex.vitality > 0.6, "rest heals")
	ectx["kind"] = "expedition"
	ectx["region"] = "velvet_warrens"
	QaCheck.eq(fails, Career.arena_for(ectx), "pit", "regions pick their arena")
	return fails
