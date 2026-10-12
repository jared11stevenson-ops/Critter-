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
var next_id := 1
var monarch_fallen := false          # the founder died: the record stays; a regent keeps the jar (PROVISIONAL rule, the creator has not decided succession)
var links: Array = []                # species of jars this jar is connected to (resource passage on the shelf)
var festivals := 0


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


const ROLES := ["builder", "forager", "storyteller"]
const ROLE_TEXT := {"builder": "builds faster (cheaper structures)", "forager": "finds extra food", "storyteller": "keeps the festival and the tribute"}

func role_count(role: String) -> int:
	var n := 0
	for d in descendants:
		if str((d as Dictionary).get("role", "")) == role:
			n += 1
	return n


func age_of(d: Dictionary) -> int:
	return day - int(d.get("born", 0))


func life_stage(d: Dictionary) -> String:
	var a := age_of(d)
	return "child" if a < 8 else ("elder" if a > 80 else "adult")


## Builders make structures up to 30% cheaper.
func build_discount() -> float:
	return minf(0.3, 0.05 * float(role_count("builder")))


## The regent is the eldest living descendant (shown when the founder has fallen). Provisional rule.
func regent() -> Dictionary:
	var best: Dictionary = {}
	for d in descendants:
		if best.is_empty() or int((d as Dictionary)["born"]) < int(best["born"]):
			best = d
	return best


func lineage_lines() -> Array:
	var out: Array = []
	if founder_name != "":
		out.append("%s%s: founding %s" % [founder_name, " (fallen)" if monarch_fallen else "", "monarch"])
	var gens := {}
	for d in descendants:
		var g := int((d as Dictionary)["gen"])
		if not gens.has(g):
			gens[g] = []
		gens[g].append(d)
	var keys := gens.keys()
	keys.sort()
	for g in keys:
		var names: Array = []
		for d in gens[g]:
			names.append("%s (%s)" % [d["name"], str(d.get("role", ""))])
		out.append("Generation %d: %s" % [g, ", ".join(names)])
	return out


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
	food += food_rate() + role_count("forager") / 2
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
		var role: String = ROLES[rng.randi() % ROLES.size()]
		descendants.append({"id": next_id, "name": nm, "gen": gen, "born": day, "role": role})
		next_id += 1
		food -= 1
		_note("%s was born (generation %d), a %s." % [nm, gen, role])
	# autonomous construction
	var nx := next_structure()
	var cost: int = int(round(float(nx.get("materials", 0)) * (1.0 - build_discount()))) if not nx.is_empty() else 0
	if not nx.is_empty() and materials >= cost and n >= int(nx["pop_req"]):
		materials -= cost
		structures.append(structures.size())
		_note("The critters built the %s." % nx["name"])
	# tribute: a living settlement earns a little scrap
	var t := structures.size() + descendants.size() / 3
	for i in structures:
		var s: Dictionary = ladder(species)[i]
		if s["effect"] == "tribute":
			t += int(s["amount"])
	t += links.size()                          # every open passage trades a little
	if day % 30 == 0 and food >= n + 6 and not descendants.is_empty():
		festivals += 1
		t += 8 + 4 * role_count("storyteller")
		_note("Festival %d: the family feasted and told the old stories." % festivals)
	tribute = mini(int(cfg()["tribute_cap"]), tribute + t)


func _name_for(rng: RandomNumberGenerator, gen: int) -> String:
	var pool: Array = Career.data()["names"].get(species, ["Kin"])
	var taken := {founder_name: true}
	for d in descendants:
		taken[str((d as Dictionary)["name"]).split(" ")[0]] = true
	var free: Array = pool.filter(func(n): return not taken.has(str(n)))
	var base: String = str(free[rng.randi() % free.size()]) if not free.is_empty() else str(pool[rng.randi() % pool.size()])
	return ("%s %s" % [base, ["", "II", "III", "IV", "V", "VI"][mini(gen - 1, 5)]]).strip_edges()


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


func link_cost() -> int:
	return 60 * (links.size() + 1)


## Opens a passage to another species' jar (max 3). Both jars must exist on the shelf; the other jar is linked back by RosterState.
func add_link(other: String, eco: Economy) -> String:
	if other == species or links.has(other):
		return "Already connected."
	if links.size() >= 3:
		return "A jar can have at most 3 passages."
	if not eco.spend({"scrap": link_cost()}):
		return "Not enough scrap."
	links.append(other)
	_note("A passage opened to the %s jar." % other.capitalize())
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
		"log": log.duplicate(), "generations": generations, "starved_days": starved_days, "next_id": next_id, "monarch_fallen": monarch_fallen, "links": links.duplicate(), "festivals": festivals}


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
	h.next_id = int(d.get("next_id", 1))
	h.monarch_fallen = bool(d.get("monarch_fallen", false))
	for l in d.get("links", []):
		h.links.append(str(l))
	h.festivals = int(d.get("festivals", 0))
	return h
