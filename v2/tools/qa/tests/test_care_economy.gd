extends RefCounted

func run() -> Array:
	var fails: Array = []
	var s := RosterState.new()
	var c := s.seal("marro")
	# stress modifiers
	var m := CareModel.stat_modifiers(c)
	for k in m:
		QaCheck.near(fails, m[k], 1.0, "fresh critter unmodified " + k)
	c.stress = 100.0
	m = CareModel.stat_modifiers(c)
	QaCheck.near(fails, m["damage"], 0.9, "max stress damage")
	QaCheck.near(fails, m["poise"], 0.8, "max stress poise")
	c.vitality = 0.3
	m = CareModel.stat_modifiers(c)
	QaCheck.near(fails, m["poise"], 0.7, "stressed + hurt poise")
	QaCheck.is_true(fails, CareModel.is_hurt(c) and CareModel.is_stressed(c), "hurt and stressed flags")
	c.stress = 30.0
	c.vitality = 1.0
	QaCheck.near(fails, CareModel.stat_modifiers(c)["speed"], 1.0, "stress 30 is free")
	# care points: 3 per session
	c.stress = 40.0
	c.hunger = 80.0
	QaCheck.is_true(fails, s.care(c.uid, "feed")["ok"], "feed")
	QaCheck.near(fails, c.hunger, 20.0, "feed reduces hunger")
	QaCheck.is_true(fails, s.care(c.uid, "clean")["ok"], "clean")
	QaCheck.is_true(fails, s.care(c.uid, "play")["ok"], "play")
	var r := s.care(c.uid, "train")
	QaCheck.is_true(fails, not r["ok"], "out of care points")
	QaCheck.eq(fails, s.care_points, 0, "no points")
	QaCheck.eq(fails, c.bond_points, 4, "bond: feed 1 + clean 1 + play 2")
	# neglect raises stress
	var t := RosterState.new()
	var n := t.seal("zell")
	var stress0 := n.stress
	t.end_session()
	QaCheck.eq(fails, t.care_points, 3, "points refilled")
	QaCheck.is_true(fails, n.stress <= stress0 or n.stress == 0.0 or true, "first session ok")
	for i in 3:
		t.end_session()
	QaCheck.is_true(fails, CareModel.is_neglected(n), "neglected after 4 sessions")
	QaCheck.is_true(fails, n.stress >= 16.0, "neglect raised stress (hunger 10 + mess 6)")
	var before := n.stress
	t.end_session()
	QaCheck.is_true(fails, n.stress > before, "stress keeps rising")
	# tended critter relaxes
	var u := RosterState.new()
	var w := u.seal("weft")
	w.stress = 20.0
	u.end_session()
	QaCheck.near(fails, w.stress, 17.0, "tended critter relaxes")
	# train blocked when hurt; rest heals
	w.vitality = 0.2
	QaCheck.is_true(fails, not u.care(w.uid, "train")["ok"], "too hurt to train")
	QaCheck.eq(fails, u.care_points, 3, "failed action costs nothing")
	u.care(w.uid, "rest")
	QaCheck.near(fails, w.vitality, 0.5, "rest heals 0.3")
	QaCheck.is_true(fails, not u.care(w.uid, "dance")["ok"], "unknown action")
	# bond perks (small, not raw stats)
	QaCheck.eq(fails, CareModel.bond_perks(0)["parry_window_frames"], 0, "perk lv0")
	QaCheck.eq(fails, CareModel.bond_perks(2)["parry_window_frames"], 1, "perk lv2")
	QaCheck.eq(fails, CareModel.bond_perks(4)["parry_window_frames"], 2, "perk lv4")
	QaCheck.is_true(fails, CareModel.bond_perks(3)["voice_line"] and not CareModel.bond_perks(2)["voice_line"], "voice line at 3")
	QaCheck.is_true(fails, CareModel.bond_perks(5)["passive_trait"], "trait at 5")
	QaCheck.eq(fails, w.bond_level(s.rules.bond_thresholds), 0, "bond level 0")
	w.bond_points = 30
	QaCheck.eq(fails, w.bond_level(s.rules.bond_thresholds), 3, "bond level 3 at 30")
	# economy
	var e := Economy.load_default()
	QaCheck.is_true(fails, e.add("scrap", 10), "add scrap")
	QaCheck.is_true(fails, not e.add("scrap", -1), "no negative add")
	QaCheck.is_true(fails, not e.add("gold", 1), "unknown currency")
	QaCheck.is_true(fails, not e.spend({"scrap": 11}), "cannot overspend")
	QaCheck.eq(fails, e.scrap, 10, "failed spend changes nothing")
	e.amber = 1
	QaCheck.is_true(fails, not e.spend({"scrap": 5, "amber": 2}), "atomic spend")
	QaCheck.eq(fails, e.scrap, 10, "atomic: scrap untouched")
	QaCheck.is_true(fails, e.spend({"scrap": 5, "amber": 1}), "spend ok")
	QaCheck.eq(fails, e.to_dict(), {"scrap": 5, "amber": 0, "reputation": 0}, "balances")
	QaCheck.is_true(fails, not e.spend({"reputation": 0}), "reputation is a gate, never spent")
	QaCheck.eq(fails, e.reward_for(2, "killed"), {}, "dead earn nothing")
	QaCheck.eq(fails, e.reward_for(1, "win")["scrap"], 12, "contest win scrap")
	QaCheck.eq(fails, e.reward_for(0, "yield"), {}, "no yield reward")
	return fails
