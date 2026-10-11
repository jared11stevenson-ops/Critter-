extends RefCounted
## Life Story chapter unlock rules (GDD 7), rack, and overrides.

var _t := 1000

func _state() -> RosterState:
	var s := RosterState.new()
	s.clock = func() -> int: return _t
	return s


func _bout(s: RosterState, c: CritterInstance, stakes: int, oc: String, opp: String, fin := 0.8, mn := 0.6) -> Dictionary:
	return s.apply_bout(BoutOutcome.make(c.uid, stakes, oc, opp, fin, mn))


func run() -> Array:
	var fails: Array = []
	var s := _state()
	# --- rack ---
	var cs: Array = []
	for sp in ["haldor", "sessa", "weft", "cinder", "marro", "zell", "kragg"]:
		cs.append(s.seal(sp))
	QaCheck.eq(fails, s.rack.count(), 7, "seven jars")
	QaCheck.is_true(fails, s.rack.is_full(), "rack full")
	QaCheck.is_true(fails, s.seal("haldor") == null, "8th seal refused")
	QaCheck.eq(fails, s.rack.slot_of(cs[3].uid), 3, "stable slots")
	for c in cs:
		QaCheck.eq(fails, c.chapters_unlocked, [1], "chapter 1 on seal: " + c.species)
		QaCheck.eq(fails, c.sealed_at, 1000, "sealed timestamp")
	# --- ch2: survive 3 bouts (Contest) ---
	var h: CritterInstance = cs[0]
	_bout(s, h, StakesTier.CONTEST, "win", "toad")
	_bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.is_true(fails, not h.has_chapter(2), "no ch2 after 2")
	var rep := _bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.is_true(fails, h.has_chapter(2), "ch2 after 3")
	QaCheck.eq(fails, rep["chapters"], [2], "report lists new chapter")
	# --- ch3: 8 bouts and bond 3 ---
	for i in 5:
		_bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.eq(fails, h.bouts_survived, 8, "8 bouts")
	QaCheck.is_true(fails, h.bond_level(s.rules.bond_thresholds) >= 3, "bond >= 3 from bouts")
	QaCheck.is_true(fails, h.has_chapter(3), "ch3 at 8 bouts + bond 3")
	# ch3 needs the bond: a critter at 8 bouts but bond < 3 must not unlock
	var lone := CritterInstance.new()
	lone.uid = "x"
	lone.species = "haldor"
	lone.bouts_survived = 8
	lone.bond_points = 10
	QaCheck.is_true(fails, not s.rules.chapter_met(lone, 3), "ch3 blocked at bond 2")
	lone.bond_points = 30
	QaCheck.is_true(fails, s.rules.chapter_met(lone, 3), "ch3 at bond 3")
	# --- ch4: near death ---
	QaCheck.is_true(fails, not h.has_chapter(4), "no ch4 yet")
	rep = _bout(s, h, StakesTier.BLOOD, "win", "toad", 0.07, 0.04)
	QaCheck.is_true(fails, rep["near_death"], "near death flagged")
	QaCheck.eq(fails, h.near_death_count, 1, "near death count")
	QaCheck.is_true(fails, h.has_chapter(4), "ch4 on near death")
	# not near death at exactly 10%
	var z: CritterInstance = cs[5]
	_bout(s, z, StakesTier.BLOOD, "win", "toad", 0.2, 0.10)
	QaCheck.eq(fails, z.near_death_count, 0, "10% is not below 10%")
	# --- ch5: 20 bouts ---
	while h.bouts_survived < 19:
		_bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.is_true(fails, not h.has_chapter(5), "no ch5 at 19")
	_bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.is_true(fails, h.has_chapter(5), "ch5 at 20")
	# --- ch6: win vs rival species (Haldor <-> Kragg) ---
	QaCheck.is_true(fails, not h.has_chapter(6), "no ch6 yet")
	_bout(s, h, StakesTier.CONTEST, "loss", "kragg")
	QaCheck.is_true(fails, not h.has_chapter(6), "losing to rival does not unlock")
	_bout(s, h, StakesTier.SPARRING, "win", "kragg")
	QaCheck.is_true(fails, not h.has_chapter(6), "sparring win vs rival does not unlock")
	_bout(s, h, StakesTier.CONTEST, "win", "kragg")
	QaCheck.eq(fails, h.wins_vs_rival, 1, "rival win counted")
	QaCheck.is_true(fails, h.has_chapter(6), "ch6 on rival win")
	# --- ch7: 40 bouts + personal trial ---
	while h.bouts_survived < 40:
		_bout(s, h, StakesTier.CONTEST, "win", "toad")
	QaCheck.is_true(fails, not h.has_chapter(7), "no ch7 without trial")
	var gained := s.complete_trial(h.uid)
	QaCheck.eq(fails, gained, [7], "ch7 after trial")
	QaCheck.eq(fails, h.chapters_unlocked, [1, 2, 3, 4, 5, 6, 7], "all seven read")
	# trial first, then bouts
	var k: CritterInstance = cs[6]
	s.complete_trial(k.uid)
	QaCheck.is_true(fails, not k.has_chapter(7), "trial alone is not enough")
	# --- rivals table: every pairing ---
	var pairs := {"haldor": "kragg", "sessa": "zell", "weft": "marro", "cinder": "mudge", "marro": "weft", "zell": "sessa", "kragg": "haldor"}
	for sp in pairs:
		QaCheck.eq(fails, s.rules.rival_of(sp), pairs[sp], "rival of " + sp)
	# --- per-critter override replaces a chapter's rule ---
	var rules := StoryRules.from_dict({
		"chapters": 7, "default": {"1": [{"type": "sealed"}], "2": [{"type": "bouts_survived", "min": 3}]},
		"overrides": {"sessa": {"2": [{"type": "bouts_survived", "min": 1}]}}, "species": {}})
	var a := CritterInstance.new()
	a.uid = "a"
	a.species = "sessa"
	a.bouts_survived = 1
	var b := CritterInstance.new()
	b.uid = "b"
	b.species = "haldor"
	b.bouts_survived = 1
	QaCheck.eq(fails, rules.evaluate(a), [1, 2], "override unlocks earlier")
	QaCheck.eq(fails, rules.evaluate(b), [1], "default unaffected")
	# chapters never relock and evaluate is idempotent
	QaCheck.eq(fails, rules.evaluate(a), [], "idempotent")
	# --- sparring gives no progression, only bond ---
	var s2 := _state()
	var sp1 := s2.seal("weft")
	for i in 5:
		_bout(s2, sp1, StakesTier.SPARRING, "win", "toad")
	QaCheck.eq(fails, sp1.bouts_survived, 0, "sparring does not count")
	QaCheck.eq(fails, sp1.bond_points, 5, "sparring gives +1 bond each")
	return fails
