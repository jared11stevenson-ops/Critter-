class_name Career
extends RefCounted
## Career rules (pure logic + data; no UI). Law: CREATOR_GDD.md. One life per critter; risk an existing critter to capture a new one;
## capture only counts after a successful extraction; tournaments risk death; the Champion Tournament leads to retire-or-defend.
## All state lives in GameSave.roster (RosterState); this class turns finished bouts into roster changes and reports for the UI.

const ROLE_OF := {"aruun": "Breaker", "cigarra": "Reader", "bramvex": "Warden", "scarlith": "Brewer", "mollusk": "Anchor", "zephyr": "Drifter", "nyxaris": "Binder", "pharilux": "Warden"}
const HEAL_PER_BOUT := 0.10
const HEAL_COST := 30
const ROLE_INFO := {
	"Breaker": ["Force: shatters guards and poise, punishes whiffs", "patient, evasive play that drains Rage"],
	"Reader": ["Information: sees attacks early, bends the enemy's choices", "restraint and unreadable pressure"],
	"Warden": ["Territory: traps and terrain funnel the enemy", "open fast fights with nothing to hold"],
	"Brewer": ["Time: damage and pressure ripen as the fight goes on", "short sudden fights, being kited early"],
	"Anchor": ["Tempo: delays and stores damage, picks when it lands", "burst that pays the debt all at once"],
	"Drifter": ["Initiative: chooses when and where the fight happens", "traps and territory that catch mobility"],
	"Binder": ["Restriction: removes your options with silk and cold", "fast pressure that drains her silk"]}
const HABITAT := {
	"aruun": "Red ochre soil, a tiny span of stone and rope, and one stubborn vine that keeps trying to climb the glass.",
	"cigarra": "A thin branch tower, hanging leaves and a hollow where the light moves around all day.",
	"bramvex": "Dry thorn scrub, a few elevated ruins and a patch of ground with no good hiding places. He rearranged it twice.",
	"scarlith": "Rotting log, damp moss, a fungal basin and a small hoard of things other people threw away.",
	"mollusk": "Warm wet loam, broad leaves and a puddle that never quite drains. Everything here is built to be repaired.",
	"zephyr": "A cluster of blooming vines that open in turn, and just enough draft to keep the petals moving.",
	"nyxaris": "Cold stone, a rime of frost and a thermal vent at the back that she hates, and uses.",
	"pharilux": "A strip of dark shoreline, a rusted anchor half sunk in the sand and one amber lamp that was already lit before anyone got here."}
static var _data: Dictionary = {}
static var _chapters: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/career/career.json"))
	return _data

static func _ch() -> Dictionary:
	if _chapters.is_empty():
		_chapters = JSON.parse_string(FileAccess.get_file_as_string("res://data/career/chapters.json"))
	return _chapters

static func chapters_for(species: String) -> Array:
	return _ch()["chapters"].get(species, [])

static func chapter_hints() -> Array:
	return _ch()["hints"]

static func regions() -> Array:
	return data()["regions"]

static func region(id: String) -> Dictionary:
	for r in regions():
		if r["id"] == id:
			return r
	return {}

static func ladder() -> Array:
	return data()["tournament"]

static func species_name(species: String) -> String:
	return species.capitalize()

static func role_of(species: String) -> String:
	return ROLE_OF.get(species, "Fighter")

## Scouting card for an expedition/tournament opponent: role, how it wins, what beats it, its three abilities.
static func scout_info(species: String) -> Dictionary:
	var role := role_of(species)
	var info: Array = ROLE_INFO.get(role, ["", ""])
	var d := CombatData.critter(species)
	var names: Array = []
	if d != null:
		for id in Hud.ability_ids(d):
			var m: MoveDef = d.move(str(id)) if str(id) != "" else null
			if m != null:
				names.append(m.name)
	return {"role": role, "wins": info[0], "weak": info[1], "abilities": names, "species": species_name(species)}

static func random_name(species: String, roster: RosterState) -> String:
	var pool: Array = data()["names"].get(species, [species.capitalize()])
	var taken := {}
	for c in roster.rack.living():
		taken[c.name] = true
	for rec in roster.wall:
		taken[rec["name"]] = true
	for n in pool:
		if not taken.has(n):
			return str(n)
	return "%s %d" % [pool[0], roster.next_uid]

# ------------------------------------------------------------------ session
static func _autosave(reason: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var gs: Node = (loop as SceneTree).root.get_node_or_null("GameSave")
		if gs != null:
			gs.call("autosave", reason)

static func roster() -> RosterState:
	return GameSave.roster

static func has_save() -> bool:
	return GameSave.system.slot_exists(GameSave.slot)

## New career: the tutorial critter is Aruun (creator ruling); he is the founding monarch of giraffe beetles.
static func start_new() -> RosterState:
	var r := GameSave.start_new()
	r.seal("aruun", "Aruun")
	_autosave("new career")
	return r

static func fighters(r: RosterState) -> Array:
	var out: Array = []
	for c in r.rack.living():
		if not c.retired:
			out.append(c)
	return out

# ------------------------------------------------------------------ bouts
## Builds the BoutConfig for a career fight. `training` bouts never kill and never count.
static func make_config(c: CritterInstance, opp_species: String, profile: String, opp_vit := 1.0, training := false, arena := "ring") -> BoutConfig:
	var cfg := BoutConfig.new()
	cfg.a_id = c.species
	cfg.b_id = opp_species
	cfg.a_name = c.name
	cfg.a_vit = c.vitality
	cfg.b_vit = opp_vit
	cfg.human_a = true
	cfg.profile_b = profile
	cfg.arena_id = arena
	cfg.training = training
	cfg.seed_value = int(Time.get_ticks_usec() & 0xffffff)
	return cfg

## kinds: "tutorial" | "expedition" | "extraction" | "tournament"
## ctx: {kind, uid, opp_species, region?, rank?} ; res: the BoutScene result dictionary.
## Returns a report for the UI: {headline, tone, lines:[], died, record, capture_offer, chapters:[{n,title}], continue_to}
## Commits a real (lethal) career bout: if the app is closed mid-fight the bout counts as abandoned (see settle_abandoned).
static func commit(r: RosterState, ctx: Dictionary) -> void:
	r.pending = {"kind": str(ctx["kind"]), "uid": str(ctx["uid"]), "captive": str(ctx.get("captive", ""))}
	_autosave("commit")

## On load: an unfinished committed bout is a loss: the critter limps home at 20% Vitality (it cannot be used to dodge death).
static func settle_abandoned(r: RosterState) -> String:
	if r.pending.is_empty():
		return ""
	var p := r.pending
	r.pending = {}
	var c := r.get_critter(str(p.get("uid", "")))
	var msg := "You left a fight unfinished."
	if c != null:
		c.vitality = minf(c.vitality, 0.2)
		c.stress = clampf(c.stress + 15.0, 0.0, 100.0)
		if str(p.get("kind", "")) == "tournament":
			c.tourney_wins = 0
		msg = "%s limped home from an abandoned %s at 20%% Vitality." % [c.name, str(p.get("kind", "fight"))]
	if str(p.get("kind", "")) == "extraction":
		msg += " The captive escaped."
	_autosave("abandoned")
	return msg

static func resolve(r: RosterState, ctx: Dictionary, res: Dictionary) -> Dictionary:
	var kind := str(ctx["kind"])
	var uid := str(ctx["uid"])
	var c := r.get_critter(uid)
	var rep := {"headline": "", "tone": "neutral", "lines": [], "died": false, "record": {}, "capture_offer": false, "chapters": [], "kind": kind, "won": false}
	if c == null:
		rep["headline"] = "That critter is gone."
		return rep
	r.pending = {}
	var winner := int(res.get("winner", -1))
	var won := winner == 0
	rep["won"] = won
	var vr: Array = res.get("vitality_ratio", [1.0, 1.0])
	var mr: Array = res.get("min_ratio", vr)
	var training := bool(res.get("training", false)) or kind == "tutorial"
	var stakes := StakesTier.SPARRING if training else StakesTier.BLOOD
	var o := BoutOutcome.from_sim_result(res, 0, uid, stakes, str(ctx["opp_species"]), float(vr[0]), float(mr[0]))
	# an expedition win ends in a KO: the wild critter is Broken, not yet dead (the player chooses to seal or finish it)
	var rp := r.apply_bout(o)
	if bool(rp.get("died", false)):
		rep["died"] = true
		rep["record"] = rp["record"]
		rep["tone"] = "death"
		rep["headline"] = "%s has fallen." % c.name
		rep["lines"].append(str(rp["record"].get("epitaph", "")))
		rep["lines"].append("A death is permanent. %s joins the Wall of the Fallen." % c.name)
		_pass_time(r, uid)
		_autosave("death")
		return rep
	for n in rp.get("chapters", []):
		var ch: Array = chapters_for(c.species)
		var t := str(ch[int(n) - 1]["title"]) if int(n) - 1 < ch.size() else "Chapter %d" % int(n)
		rep["chapters"].append({"n": int(n), "title": t})
	if won:
		rep["tone"] = "win"
		rep["headline"] = "%s wins." % c.name
		if kind == "tournament":
			_tournament_win(r, c, ctx, rep)
		elif kind == "expedition":
			rep["capture_offer"] = true
			rep["lines"].append("The wild %s is broken. Seal it in a jar, or finish it?" % species_name(str(ctx["opp_species"])))
		elif kind == "extraction":
			rep["lines"].append("You break through and reach the Gate.")
			var species := str(ctx.get("captive", ""))
			var nc := finish_capture(r, species)
			if nc == null:
				rep["lines"].append("But the Shelf is full (%d). Someone has to be released first." % Rack.CAPACITY)
			else:
				rep["captured"] = {"uid": nc.uid, "name": nc.name, "species": nc.species, "founder": nc.founder}
				rep["lines"].append("%s is sealed in a jar and brought home alive." % nc.name)
				if nc.founder:
					rep["lines"].append("First of its kind on Earth: %s is the founding monarch of the %s jar." % [nc.name, species_name(nc.species)])
	else:
		rep["tone"] = "loss"
		rep["headline"] = "%s survives, but loses." % c.name
		if kind == "expedition":
			rep["lines"].append("You return to Earth empty-handed.")
		elif kind == "extraction":
			rep["lines"].append("The captive escapes in the chaos. The expedition fails.")
		elif kind == "tournament":
			rep["lines"].append("Eliminated. The ladder resets for %s." % c.name)
			c.tourney_wins = 0
	rep["lines"].append("Vitality %d%%   Bond +%d" % [int(round(c.vitality * 100.0)), int(rp.get("bond_gained", 0))])
	if bool(rp.get("near_death", false)):
		rep["lines"].append("Near death. It remembers.")
	if rep["chapters"].size() > 0:
		rep["lines"].append("Life Story unlocked: " + ", ".join(rep["chapters"].map(func(x): return str(x["title"]))))
	_pass_time(r, uid)
	_autosave("bout")
	return rep

## Time passes between bouts: everyone else recovers a little.
static func _pass_time(r: RosterState, except_uid: String) -> void:
	for c in r.rack.living():
		if c.uid != except_uid:
			c.vitality = minf(1.0, c.vitality + HEAL_PER_BOUT)

static func heal(r: RosterState, uid: String) -> bool:
	var c := r.get_critter(uid)
	if c == null or c.vitality >= 0.999 or not r.economy.can_afford({"scrap": HEAL_COST}):
		return false
	r.economy.spend({"scrap": HEAL_COST})
	c.vitality = 1.0
	_autosave("heal")
	return true

# ------------------------------------------------------------------ capture / extraction
## Player chose to seal the broken wild critter: the expedition now needs a successful extraction.
static func begin_extraction(c: CritterInstance, species: String, region_id: String) -> Dictionary:
	return {"kind": "extraction", "uid": c.uid, "opp_species": _pursuer_for(species), "region": region_id, "captive": species}

static func _pursuer_for(species: String) -> String:
	var order := ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]
	return order[(order.find(species) + 3) % order.size()]

## Completes a capture after a successful extraction. Returns the new critter (null if the Shelf is full).
static func finish_capture(r: RosterState, species: String) -> CritterInstance:
	var c := r.seal(species, random_name(species, r))
	if c != null:
		c.vitality = 0.6
		_autosave("capture")
	return c

## Player chose to finish the broken wild critter instead (no capture; some scrap).
static func finish_wild(r: RosterState) -> void:
	r.economy.add("scrap", 20)
	_autosave("finish")

# ------------------------------------------------------------------ tournaments
static func next_rung(c: CritterInstance) -> Dictionary:
	var l := ladder()
	return l[clampi(c.tourney_wins, 0, l.size() - 1)]

static func opponent_for_rung(rung: Dictionary, c: CritterInstance) -> String:
	var order := ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]
	var i := (order.find(c.species) + 1 + c.tourney_wins * 2 + c.titles_defended) % order.size()
	return order[i]

static func _tournament_win(r: RosterState, c: CritterInstance, ctx: Dictionary, rep: Dictionary) -> void:
	var l := ladder()
	var rung: Dictionary = l[clampi(int(ctx.get("rung", c.tourney_wins)), 0, l.size() - 1)]
	r.economy.add("scrap", int(rung.get("scrap", 0)))
	if int(rung.get("amber", 0)) > 0:
		r.economy.add("amber", int(rung["amber"]))
	r.economy.add("reputation", 1)
	rep["lines"].append("%s cleared: +%d scrap" % [rung["rank"], int(rung.get("scrap", 0))])
	if c.champion:
		c.titles_defended += 1
		rep["lines"].append("Title defended (%d)." % c.titles_defended)
		return
	c.tourney_wins += 1
	if c.tourney_wins >= l.size():
		c.champion = true
		c.tourney_wins = l.size()
		rep["champion"] = true
		rep["headline"] = "%s is the CHAMPION." % c.name
		rep["lines"].append("Choose: retire in peace, or defend the title.")

static func retire(r: RosterState, uid: String) -> bool:
	var c := r.get_critter(uid)
	if c == null or not c.champion:
		return false
	c.retired = true
	c.vitality = 1.0
	_autosave("retire")
	return true


## Player allocation to a species' jar: kind collect|feed|supply|expand. Returns "" or a short reason / result line.
static func habitat_action(species: String, kind: String) -> String:
	var r := roster()
	var h := r.habitat(species)
	var res := ""
	match kind:
		"collect": h.collect(r.economy)
		"feed": res = h.feed(r.economy)
		"supply": res = h.supply(r.economy)
		"expand": res = h.expand(r.economy)
	_autosave("habitat")
	return res
