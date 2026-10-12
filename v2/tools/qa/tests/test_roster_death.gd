extends RefCounted
## Death, bout application, care/stress, economy, serialization.

var _t := 5000

func _state() -> RosterState:
	var s := RosterState.new()
	s.clock = func() -> int: return _t
	return s


func run() -> Array:
	var fails: Array = []
	var s := _state()
	var died_records: Array = []
	s.critter_died.connect(func(r): died_records.append(r))
	var c := s.seal("nyxaris", "Big K")
	c.add_moment("Won a Blood Bout against a stag", 50.0)
	# --- killed in Contest/Sparring is downgraded: only Blood Bouts kill ---
	var r := s.apply_bout(BoutOutcome.make(c.uid, StakesTier.CONTEST, "killed", "aruun", 0.2, 0.2))
	QaCheck.is_true(fails, not r["died"], "contest cannot kill")
	QaCheck.is_true(fails, c.alive and c.vitality > 0.0, "survivor has vitality")
	QaCheck.eq(fails, r["outcome"], "loss", "downgraded to loss")
	r = s.apply_bout(BoutOutcome.make(c.uid, StakesTier.SPARRING, "killed", "aruun", 0.2, 0.2))
	QaCheck.is_true(fails, not r["died"], "sparring cannot kill")
	# --- Blood Bout kill ---
	for i in 4:
		s.apply_bout(BoutOutcome.make(c.uid, StakesTier.CONTEST, "win", "toad"))
	var bo := BoutOutcome.make(c.uid, StakesTier.BLOOD, "killed", "aruun", 0.0, 0.0)
	bo.cause = "Haldor's Quarry Maul"
	var before_scrap := s.economy.scrap
	r = s.apply_bout(bo)
	QaCheck.is_true(fails, r["died"], "blood kills")
	QaCheck.eq(fails, died_records.size(), 1, "critter_died emitted once")
	QaCheck.is_true(fails, not c.alive, "marked dead")
	QaCheck.eq(fails, s.rack.count(), 0, "removed from rack")
	QaCheck.eq(fails, s.wall.size(), 1, "on the wall")
	QaCheck.is_true(fails, s.is_fallen(c.uid), "is_fallen")
	QaCheck.eq(fails, s.economy.scrap, before_scrap, "no reward for the dead")
	var rec: Dictionary = s.wall[0]
	QaCheck.eq(fails, rec["cause"], "Haldor's Quarry Maul", "cause recorded")
	QaCheck.eq(fails, rec["relic"], "relic_nyxaris", "relic granted")
	QaCheck.eq(fails, rec["last_move"], "lastmove_nyxaris", "last move granted")
	QaCheck.eq(fails, s.legacy["relics"].size(), 1, "legacy relic")
	QaCheck.eq(fails, s.legacy["moves"][0]["from_species"], "nyxaris", "legacy last move")
	QaCheck.eq(fails, rec["died_at"], 5000, "died timestamp")
	var ep: String = rec["epitaph"]
	QaCheck.is_true(fails, ep.find("Big K") >= 0, "epitaph names it")
	QaCheck.is_true(fails, ep.find("frost weaver") >= 0, "epitaph species")
	QaCheck.is_true(fails, ep.find("2 of 7") >= 0 or ep.find("chapters") >= 0, "epitaph chapters read")
	QaCheck.is_true(fails, ep.find("Won a Blood Bout") >= 0, "epitaph best moment")
	QaCheck.is_true(fails, ep.find("Quarry Maul") >= 0, "epitaph cause")
	# permanent: no further bouts, no second death, no resurrection through state APIs
	QaCheck.is_true(fails, s.apply_bout(BoutOutcome.make(c.uid, StakesTier.SPARRING, "win", "toad")).has("error"), "dead cannot fight")
	QaCheck.eq(fails, s.kill(c.uid, "again").get("cause"), "Haldor's Quarry Maul", "kill is idempotent")
	QaCheck.eq(fails, s.wall.size(), 1, "still one wall entry")
	QaCheck.is_true(fails, s.care(c.uid, "feed")["ok"] == false, "cannot feed the dead")
	# re-loading a dict that lists the critter both alive and fallen keeps it dead
	var d := s.to_dict()
	d["rack"][2] = c.to_dict()
	d["rack"][2]["alive"] = true
	var s_b := _state()
	s_b.load_dict(d)
	QaCheck.eq(fails, s_b.rack.count(), 0, "wall wins over a stale rack entry")
	# uid is never reused
	var nxt := s.seal("zephyr")
	QaCheck.is_true(fails, nxt.uid != c.uid, "uid not reused")
	# --- yield / injuries / rewards ---
	var s2 := _state()
	var y := s2.seal("cigarra")
	var rep := s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.BLOOD, "yield", "toad", 0.12, 0.12))
	QaCheck.eq(fails, rep["reward"], {}, "yield forfeits reward")
	QaCheck.eq(fails, y.bouts_survived, 1, "yield counts as survived")
	QaCheck.is_true(fails, y.stress >= 19.0, "yield stresses")
	rep = s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.CONTEST, "loss", "toad", 0.4, 0.4))
	QaCheck.is_true(fails, rep["scar"] != "", "contest loss leaves a scar")
	QaCheck.eq(fails, y.scars.size(), 1, "scar stored")
	s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.CONTEST, "win", "toad", 0.9, 0.9))
	QaCheck.eq(fails, y.scars.size(), 1, "clean contest win: no scar")
	s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.CONTEST, "win", "toad", 0.2, 0.16))
	QaCheck.eq(fails, y.scars.size(), 1, "16% low point: no scar (needs <15%)")
	s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.CONTEST, "win", "toad", 0.2, 0.12))
	QaCheck.eq(fails, y.scars.size(), 2, "12% low point scars")
	for i in 5:
		s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.CONTEST, "loss", "toad", 0.5, 0.5))
	QaCheck.eq(fails, y.scars.size(), BoutResolver.MAX_SCARS, "scars capped")
	var eco := s2.economy
	var sc0 := eco.scrap
	s2.apply_bout(BoutOutcome.make(y.uid, StakesTier.BLOOD, "win", "toad", 0.5, 0.5))
	QaCheck.eq(fails, eco.scrap - sc0, 25, "blood win scrap")
	QaCheck.eq(fails, eco.amber, 1, "blood win amber")
	QaCheck.is_true(fails, eco.reputation >= 4, "blood win reputation")
	# --- from_sim_result mapping ---
	QaCheck.eq(fails, BoutOutcome.from_sim_result({"winner": 0, "reason": "ko", "killed": true}, 0, "u", 2, "x", 1, 1).outcome, "win", "sim win")
	QaCheck.eq(fails, BoutOutcome.from_sim_result({"winner": 1, "reason": "ko", "killed": true}, 0, "u", 2, "x", 0, 0).outcome, "killed", "sim killed")
	QaCheck.eq(fails, BoutOutcome.from_sim_result({"winner": 1, "reason": "yield", "killed": false}, 0, "u", 2, "x", 0.1, 0.1).outcome, "yield", "sim yield")
	QaCheck.eq(fails, BoutOutcome.from_sim_result({"winner": 1, "reason": "ringout", "killed": false}, 0, "u", 2, "x", 0.5, 0.5).outcome, "loss", "sim loss")
	QaCheck.eq(fails, BoutOutcome.from_sim_result({"winner": -1, "reason": "timeout", "killed": false}, 0, "u", 2, "x", 0.5, 0.5).outcome, "loss", "sim draw")
	# --- serialization round trip ---
	var round := _state()
	round.load_dict(JSON.parse_string(JSON.stringify(s2.to_dict())))
	QaCheck.eq(fails, JSON.stringify(round.to_dict()), JSON.stringify(s2.to_dict()), "json round trip")
	return fails
