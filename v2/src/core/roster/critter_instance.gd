class_name CritterInstance
extends RefCounted
## One owned critter (data only, serializable). Created sealed in a jar; mutated by RosterState / BoutResolver / CareModel.
## `vitality` is a 0..1 ratio of the species' max Vitality (the sim scales it), so it carries between bouts.

var uid := ""
var species := ""
var name := ""
var vitality := 1.0
var stress := 0.0          # 0..100
var hunger := 0.0          # 0 fed .. 100 starving
var mess := 0.0            # 0 clean .. 100 filthy habitat
var bond_points := 0
var bouts_survived := 0
var near_death_count := 0
var wins_vs_rival := 0
var trial_complete := false
var scars: Array = []              # [{id, tier, at_bout}]
var chapters_unlocked: Array = []  # sorted ints 1..7
var moments: Array = []            # best moments: [{text, score}], kept top 5
var alive := true
var born_at := 0                   # unix seconds
var sealed_at := 0
var died_at := 0
var cause_of_death := ""
var epitaph := ""
var last_move := ""                # granted on death
var relic := ""                    # granted on death


func bond_level(thresholds: Array) -> int:
	var lv := 0
	for t in thresholds:
		if bond_points >= int(t):
			lv += 1
	return lv


func has_chapter(n: int) -> bool:
	return chapters_unlocked.has(n)


func add_moment(text: String, score: float) -> void:
	moments.append({"text": text, "score": score})
	moments.sort_custom(func(a, b): return a["score"] > b["score"])
	if moments.size() > 5:
		moments.resize(5)


func best_moment() -> String:
	return moments[0]["text"] if not moments.is_empty() else ""


func to_dict() -> Dictionary:
	return {
		"uid": uid, "species": species, "name": name, "vitality": vitality, "stress": stress, "hunger": hunger, "mess": mess,
		"bond_points": bond_points, "bouts_survived": bouts_survived, "near_death_count": near_death_count,
		"wins_vs_rival": wins_vs_rival, "trial_complete": trial_complete, "scars": scars.duplicate(true),
		"chapters_unlocked": chapters_unlocked.duplicate(), "moments": moments.duplicate(true), "alive": alive,
		"born_at": born_at, "sealed_at": sealed_at, "died_at": died_at, "cause_of_death": cause_of_death,
		"epitaph": epitaph, "last_move": last_move, "relic": relic,
	}


static func from_dict(d: Dictionary) -> CritterInstance:
	var c := CritterInstance.new()
	c.uid = str(d.get("uid", ""))
	c.species = str(d.get("species", ""))
	c.name = str(d.get("name", c.species))
	c.vitality = clampf(float(d.get("vitality", 1.0)), 0.0, 1.0)
	c.stress = clampf(float(d.get("stress", 0.0)), 0.0, 100.0)
	c.hunger = clampf(float(d.get("hunger", 0.0)), 0.0, 100.0)
	c.mess = clampf(float(d.get("mess", 0.0)), 0.0, 100.0)
	c.bond_points = maxi(0, int(d.get("bond_points", 0)))
	c.bouts_survived = maxi(0, int(d.get("bouts_survived", 0)))
	c.near_death_count = maxi(0, int(d.get("near_death_count", 0)))
	c.wins_vs_rival = maxi(0, int(d.get("wins_vs_rival", 0)))
	c.trial_complete = bool(d.get("trial_complete", false))
	for sc in d.get("scars", []):
		c.scars.append({"id": str(sc.get("id", "")), "tier": int(sc.get("tier", 0)), "at_bout": int(sc.get("at_bout", 0))})
	for n in d.get("chapters_unlocked", []):
		c.chapters_unlocked.append(int(n))
	c.chapters_unlocked.sort()
	c.moments = (d.get("moments", []) as Array).duplicate(true)
	c.alive = bool(d.get("alive", true))
	c.born_at = int(d.get("born_at", 0))
	c.sealed_at = int(d.get("sealed_at", 0))
	c.died_at = int(d.get("died_at", 0))
	c.cause_of_death = str(d.get("cause_of_death", ""))
	c.epitaph = str(d.get("epitaph", ""))
	c.last_move = str(d.get("last_move", ""))
	c.relic = str(d.get("relic", ""))
	return c
