class_name Habitat
extends RefCounted
## One species' Habitat Jar (CREATOR_GDD s7-8, s11). Peaceful. The player only allocates scrap and supplies;
## the critters breed (retired adults) and build their own structures. Advances in whole habitat days, deterministic per species + day.

const PATH := "res://data/career/habitats.json"
static var _cfg: Dictionary = {}

var species := ""
var founder_name := ""
var day := 0
var last_real := 0                   # unix seconds of the last advance
var food := 10
var materials := 0
var expansions := 0
var tribute := 0                     # scrap the settlement has earned for the player, until collected
var structures: Array = []           # indexes into the species ladder, in build order
var descendants: Array = []          # [{name, gen, born}] peaceful family, not fighters
var log: Array = []                  # newest last, capped
var generations := 0
var starved_days := 0


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _cfg


static func ladder(sp: String) -> Array:
	return cfg()["species"].get(sp, [])


func capacity() -> int:
	var cap: int = int(cfg()["base_capacity"]) + expansions * int(cfg()["expand_gain"])
	for i in structures:
		var s: Dictionary = ladder(species)[i]
		if s["effect"] == "housing":
			cap += int(s["amount"])
	return mini(cap, int(cfg()["max_capacity"]))


func food_rate() -> int:
	var f := 2
	for i in structures:
		var s: Dictionary = ladder(species)[i]
		if s["effect"] == "food":
			f += int(s["amount"])
	return f


func next_structure() -> Dictionary:
	var l := ladder(species)
	return l[structures.size()] if structures.size() < l.size() else {}


func stage_name(adults: int) -> String:
	if structures.size() >= 5:
		return "Civilization"
	if structures.size() >= 3:
		return "Settlement"
	if adults > 0 or not descendants.is_empty():
		return "Family"
	return "Ecosystem"


func _note(t: String) -> void:
	log.append("Day %d: %s" % [day, t])
	if log.size() > 30:
		log.remove_at(0)


## Advance by real time. adults = living retired critters of this species (the only breeders). Returns days advanced.
func catch_up(now: int, adults: Array) -> int:
	if last_real == 0:
		last_real = now
		return 0
	var days := mini(int(cfg()["max_catchup_days"]), (now - last_real) / int(cfg()["day_seconds"]))
	if days <= 0:
		return 0
	last_real += days * int(cfg()["day_seconds"])
	for i in days:
		step_day(adults)
	return days


func step_day(adults: Array) -> void:
	day += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(species) * 7919 + day
	var n := adults.size() + descendants.size()
	food += food_rate()
	var need := n
	if food >= need:
		food -= need
		starved_days = 0
	else:
		food = 0
		starved_days += 1
		if starved_days >= 2 and not descendants.is_empty():
			var gone: Dictionary = descendants.pop_back()
			_note("%s left the jar's family circle; there was not enough food." % gone["name"])
			starved_days = 0
	# births: need one retired adult (or an existing pair of descendants), room, and a food surplus
	var can_breed := adults.size() >= 1 or descendants.size() >= 2
	if can_breed and n < capacity() and food >= n + 2 and rng.randf() < float(cfg()["birth_chance"]):
		var gen := 1
		if adults.is_empty():
			gen = 1 + int((descendants[0] as Dictionary)["gen"])
		generations = maxi(generations, gen)
		var nm := _name_for(rng, gen)
		descendants.append({"name": nm, "gen": gen, "born": day})
		food -= 1
		_note("%s was born (generation %d)." % [nm, gen])
	# autonomous construction
	var nx := next_structure()
	if not nx.is_empty() and materials >= int(nx["materials"]) and n >= int(nx["pop_req"]):
		materials -= int(nx["materials"])
		structures.append(structures.size())
		_note("The critters built the %s." % nx["name"])
	# tribute: a living settlement earns a little scrap
	var t := structures.size() + descendants.size() / 3
	for i in structures:
		var s: Dictionary = ladder(species)[i]
		if s["effect"] == "tribute":
			t += int(s["amount"])
	tribute = mini(int(cfg()["tribute_cap"]), tribute + t)


func _name_for(rng: RandomNumberGenerator, gen: int) -> String:
	var pool: Array = Career.data()["names"].get(species, ["Kin"])
	return ("%s %s" % [pool[rng.randi() % pool.size()], ["", "II", "III", "IV", "V", "VI"][mini(gen - 1, 5)]]).strip_edges()


# --- player allocation (spends scrap from `eco`); each returns "" on success or a reason ---
func feed(eco: Economy) -> String:
	if not eco.spend({"scrap": int(cfg()["feed_cost_scrap"])}):
		return "Not enough scrap."
	food += int(cfg()["feed_gain"])
	return ""


func supply(eco: Economy) -> String:
	if not eco.spend({"scrap": int(cfg()["supply_cost_scrap"])}):
		return "Not enough scrap."
	materials += int(cfg()["supply_gain"])
	return ""


func expand(eco: Economy) -> String:
	if capacity() >= int(cfg()["max_capacity"]):
		return "This jar cannot grow any larger."
	if not eco.spend({"scrap": int(cfg()["expand_cost_scrap"])}):
		return "Not enough scrap."
	expansions += 1
	_note("The jar was expanded.")
	return ""


func collect(eco: Economy) -> int:
	var n := tribute
	tribute = 0
	if n > 0:
		eco.add("scrap", n)
	return n


func to_dict() -> Dictionary:
	return {"species": species, "founder_name": founder_name, "day": day, "last_real": last_real, "food": food, "materials": materials,
		"expansions": expansions, "tribute": tribute, "structures": structures.duplicate(), "descendants": descendants.duplicate(true),
		"log": log.duplicate(), "generations": generations, "starved_days": starved_days}


static func from_dict(d: Dictionary) -> Habitat:
	var h := Habitat.new()
	h.species = str(d.get("species", ""))
	h.founder_name = str(d.get("founder_name", ""))
	h.day = int(d.get("day", 0))
	h.last_real = int(d.get("last_real", 0))
	h.food = int(d.get("food", 10))
	h.materials = int(d.get("materials", 0))
	h.expansions = int(d.get("expansions", 0))
	h.tribute = int(d.get("tribute", 0))
	for i in d.get("structures", []):
		h.structures.append(int(i))
	h.descendants = (d.get("descendants", []) as Array).duplicate(true)
	for l in d.get("log", []):
		h.log.append(str(l))
	h.generations = int(d.get("generations", 0))
	h.starved_days = int(d.get("starved_days", 0))
	return h
