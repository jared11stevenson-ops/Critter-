class_name RosterState
extends RefCounted
## The whole player roster model: Rack, Wall of the Fallen, economy, legacy, care sessions. Pure logic, serializable.
## Death is permanent and immediate: kill() moves the critter to the Wall, writes its Epitaph, grants relic + last move
## and emits critter_died so the SaveSystem can commit it to the deaths ledger before anything else happens.

signal critter_sealed(uid: String)
signal critter_died(record: Dictionary)
signal chapter_unlocked(uid: String, chapter: int)

var rack := Rack.new()
var wall: Array = []                       # Wall of the Fallen: fallen records (dictionaries)
var economy: Economy
var rules: StoryRules
var legacy := {"relics": [], "moves": []}  # relics: [{id, from_uid, from_name}], moves: [{move_id, from_species, from_name}]
var next_uid := 1
var pending: Dictionary = {}                # a committed career bout in progress {kind, uid, captive?}: abandoning it counts as a loss
var species_seen: Array = []                # every species ever sealed (the first of each is its founding monarch)
var habitats: Dictionary = {}                  # species -> Habitat (one jar per species)
var profile_id := ""
var session_count := 0
var care_points := CareModel.CARE_POINTS
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())


func _init(p_rules: StoryRules = null, p_economy: Economy = null) -> void:
	rules = p_rules if p_rules != null else StoryRules.load_default()
	economy = p_economy if p_economy != null else Economy.load_default()


func _now() -> int:
	return int(clock.call())


## Seals a captured critter in the first free jar. Returns null if the Rack is full.
func seal(species: String, name: String = "") -> CritterInstance:
	if rack.is_full():
		return null
	var c := CritterInstance.new()
	c.uid = "c%04d" % next_uid
	next_uid += 1
	c.species = species
	c.name = name if name != "" else species.capitalize()
	c.born_at = _now()
	c.sealed_at = c.born_at
	rack.add(c)
	if not species_seen.has(species):
		species_seen.append(species)
		c.founder = true
	var h := habitat(species)
	if c.founder:
		h.founder_name = c.name
	_unlock_new(c)
	critter_sealed.emit(c.uid)
	return c


## The species' jar (created on first sealing).
func habitat(species: String) -> Habitat:
	if not habitats.has(species):
		var h := Habitat.new()
		h.species = species
		h.last_real = _now()
		habitats[species] = h
	return habitats[species]


## One big Jar: every claimed species (a living critter of it on the shelf) is a district; neighbours trade through free passages.
func unify_town() -> Array:
	var claimed: Array = []
	for sp in Habitat.TOWN_ORDER:
		for c in rack.living():
			if c.species == sp:
				claimed.append(sp)
				break
	for sp in claimed:
		var h := habitat(sp)
		h.links.clear()
		var i := Habitat.TOWN_ORDER.find(sp)
		for j in [i - 1, i + 1]:
			if j >= 0 and j < Habitat.TOWN_ORDER.size() and claimed.has(Habitat.TOWN_ORDER[j]):
				h.links.append(Habitat.TOWN_ORDER[j])
	return claimed


func retired_adults(species: String) -> Array:
	var out: Array = []
	for c in rack.living():
		if c.species == species and c.retired:
			out.append(c)
	return out


## Opens a passage between two jars (both ways). Returns "" or a reason.
func link_jars(a: String, b: String) -> String:
	if not habitats.has(a) or not habitats.has(b):
		return "Both jars need a critter."
	var why: String = (habitats[a] as Habitat).add_link(b, economy)
	if why == "":
		var hb: Habitat = habitats[b]
		if not hb.links.has(a):
			hb.links.append(a)
	return why


## Linked jars even out their food a little each tick of habitat time.
func _share_food() -> void:
	for sp in habitats:
		var h: Habitat = habitats[sp]
		for o in h.links:
			if habitats.has(o):
				var ho: Habitat = habitats[o]
				if h.food > ho.food + 6:
					h.food -= 2
					ho.food += 2


## Let every jar's critters live on while the player was away (call on load / opening the shelf).
func tick_habitats() -> Dictionary:
	var report := {}
	for sp in habitats:
		var h: Habitat = habitats[sp]
		var before := h.descendants.size()
		var built := h.structures.size()
		var days := h.catch_up(_now(), retired_adults(sp))
		for _i in days:
			_share_food()
		if days > 0:
			report[sp] = {"days": days, "born": maxi(0, h.descendants.size() - before), "built": h.structures.size() - built}
	return report


func get_critter(uid: String) -> CritterInstance:
	return rack.get_by_uid(uid)


func _unlock_new(c: CritterInstance) -> Array:
	var gained := rules.evaluate(c)
	for ch in gained:
		chapter_unlocked.emit(c.uid, ch)
	return gained


## Applies a finished bout. Killed outcomes (Blood Bouts only) are committed immediately and irreversibly.
func apply_bout(o: BoutOutcome) -> Dictionary:
	var c := rack.get_by_uid(o.uid)
	if c == null:
		return {"error": "unknown or dead critter " + o.uid}
	if BoutResolver.effective_outcome(o) == "killed":
		return {"outcome": "killed", "died": true, "record": kill(o.uid, o.cause if o.cause != "" else "a Blood Bout")}
	var before := c.chapters_unlocked.duplicate()
	var rep := BoutResolver.apply(c, o, rules, economy)
	rep["died"] = false
	for ch in c.chapters_unlocked:
		if not before.has(ch):
			chapter_unlocked.emit(c.uid, ch)
	return rep


## Permanent death. Idempotent (a second call returns the existing record).
func kill(uid: String, cause: String) -> Dictionary:
	for rec in wall:
		if rec["uid"] == uid:
			return rec
	var c := rack.remove(uid)
	if c == null:
		return {}
	c.alive = false
	c.vitality = 0.0
	c.died_at = _now()
	c.cause_of_death = cause
	c.relic = "relic_" + c.species
	c.last_move = "lastmove_" + c.species
	c.epitaph = Epitaph.generate(c, rules.species_title(c.species))
	if c.founder and habitats.has(c.species):
		var fh: Habitat = habitats[c.species]
		fh.monarch_fallen = true
		fh._note("The founding monarch %s has fallen. The record remains." % c.name)
	var rec := _fallen_record(c)
	_add_to_wall(rec)
	critter_died.emit(rec)
	return rec


static func _fallen_record(c: CritterInstance) -> Dictionary:
	return {
		"uid": c.uid, "species": c.species, "name": c.name, "sealed_at": c.sealed_at, "died_at": c.died_at,
		"cause": c.cause_of_death, "epitaph": c.epitaph, "chapters_unlocked": c.chapters_unlocked.duplicate(),
		"bouts_survived": c.bouts_survived, "best_moment": c.best_moment(), "relic": c.relic, "last_move": c.last_move,
		"scars": c.scars.size(),
	}


## JSON turns ints into floats; restore the integer fields of a fallen record.
static func _norm_record(rec: Dictionary) -> Dictionary:
	var r := rec.duplicate(true)
	for k in ["sealed_at", "died_at", "bouts_survived", "scars"]:
		r[k] = int(r.get(k, 0))
	var ch: Array = []
	for n in r.get("chapters_unlocked", []):
		ch.append(int(n))
	r["chapters_unlocked"] = ch
	return r


func _add_to_wall(rec: Dictionary) -> void:
	wall.append(rec)
	legacy["relics"].append({"id": rec["relic"], "from_uid": rec["uid"], "from_name": rec["name"]})
	legacy["moves"].append({"move_id": rec["last_move"], "from_species": rec["species"], "from_name": rec["name"]})


func is_fallen(uid: String) -> bool:
	for rec in wall:
		if rec["uid"] == uid:
			return true
	return false


## Used by the save layer: makes this state agree with a deaths-ledger record (silent; no signal).
## Removes the critter from the Rack if an older save still has it alive and adds it to the Wall if missing.
func merge_fallen(rec: Dictionary) -> bool:
	var uid := str(rec.get("uid", ""))
	if uid == "":
		return false
	rack.remove(uid)
	var n := int(uid.trim_prefix("c")) if uid.begins_with("c") and uid.trim_prefix("c").is_valid_int() else 0
	next_uid = maxi(next_uid, n + 1)
	if is_fallen(uid):
		return false
	_add_to_wall(_norm_record(rec))
	return true


func complete_trial(uid: String) -> Array:
	var c := rack.get_by_uid(uid)
	if c == null:
		return []
	c.trial_complete = true
	return _unlock_new(c)


## Care action on a living critter: "feed" | "clean" | "play" | "train" | "rest". Costs 1 care point per session.
func care(uid: String, kind: String) -> Dictionary:
	var c := rack.get_by_uid(uid)
	if c == null:
		return {"ok": false, "reason": "unknown critter"}
	if care_points <= 0:
		return {"ok": false, "reason": "no care points left this session"}
	var res: Dictionary
	match kind:
		"feed": res = CareModel.feed(c)
		"clean": res = CareModel.clean(c)
		"play": res = CareModel.play(c)
		"train": res = CareModel.train(c)
		"rest": res = CareModel.rest(c)
		_: return {"ok": false, "reason": "unknown care action"}
	if res["ok"]:
		care_points -= 1
		c.bond_points += int(res["bond"])
		_unlock_new(c)
	return res


## A play session ends: untended needs drift and neglect raises stress; care points refill.
func end_session() -> void:
	session_count += 1
	care_points = CareModel.CARE_POINTS
	for c in rack.living():
		CareModel.end_session(c)


func stat_modifiers(uid: String) -> Dictionary:
	var c := rack.get_by_uid(uid)
	return CareModel.stat_modifiers(c) if c != null else {}


func to_dict() -> Dictionary:
	return {
		"profile_id": profile_id, "next_uid": next_uid, "session_count": session_count, "care_points": care_points,
		"species_seen": species_seen.duplicate(), "pending": pending.duplicate(true), "rack": rack.to_array(), "wall": wall.duplicate(true), "economy": economy.to_dict(), "habitats": _habitats_array(), "legacy": legacy.duplicate(true),
	}


func _habitats_array() -> Array:
	var a: Array = []
	for sp in habitats:
		a.append((habitats[sp] as Habitat).to_dict())
	return a


func load_dict(d: Dictionary) -> void:
	habitats = {}
	for hd in d.get("habitats", []):
		var hh := Habitat.from_dict(hd)
		habitats[hh.species] = hh
	profile_id = str(d.get("profile_id", ""))
	next_uid = maxi(1, int(d.get("next_uid", 1)))
	session_count = int(d.get("session_count", 0))
	care_points = clampi(int(d.get("care_points", CareModel.CARE_POINTS)), 0, CareModel.CARE_POINTS)
	rack = Rack.from_array(d.get("rack", []))
	pending = (d.get("pending", {}) as Dictionary).duplicate(true)
	species_seen = []
	for sp in d.get("species_seen", []):
		species_seen.append(str(sp))
	for c in rack.living():
		if not species_seen.has(c.species):
			species_seen.append(c.species)
	wall = []
	for rec in d.get("wall", []):
		wall.append(_norm_record(rec))
	economy.load_dict(d.get("economy", {}))
	var lg: Dictionary = d.get("legacy", {})
	legacy = {"relics": (lg.get("relics", []) as Array).duplicate(true), "moves": (lg.get("moves", []) as Array).duplicate(true)}
	for c in rack.living():
		habitat(c.species)   # older saves: every species on the shelf has a jar
	# a living critter can never also be on the Wall
	for rec in wall:
		rack.remove(str(rec.get("uid", "")))
