class_name StoryRules
extends RefCounted
## Data-driven Life Story chapter rules (res://data/story/chapter_rules.json, GDD 7). Pure logic.

const RULES_PATH := "res://data/story/chapter_rules.json"
const REWARDS_PATH := "res://data/story/rewards.json"

var chapter_count := 7
var default_rules: Dictionary = {}
var overrides: Dictionary = {}
var species: Dictionary = {}
var bond_thresholds: Array = [5, 15, 30, 60, 100]


static func load_default() -> StoryRules:
	return from_dict(read_json(RULES_PATH), read_json(REWARDS_PATH))


static func read_json(path: String) -> Dictionary:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) == OK and j.data is Dictionary:
		return j.data
	push_error("StoryRules: cannot read " + path)
	return {}


static func from_dict(rules: Dictionary, rewards: Dictionary = {}) -> StoryRules:
	var s := StoryRules.new()
	s.chapter_count = int(rules.get("chapters", 7))
	s.default_rules = rules.get("default", {})
	s.overrides = rules.get("overrides", {})
	s.species = rules.get("species", {})
	var th = rewards.get("bond", {}).get("thresholds", null)
	if th is Array:
		s.bond_thresholds = th
	return s


## Conditions for one chapter of one species (override if present, else default).
func conditions(species_id: String, chapter: int) -> Array:
	var ov: Dictionary = overrides.get(species_id, {})
	var key := str(chapter)
	if ov.has(key):
		return ov[key]
	return default_rules.get(key, [])


func rival_of(species_id: String) -> String:
	return str(species.get(species_id, {}).get("rival", ""))


func species_title(species_id: String) -> String:
	return str(species.get(species_id, {}).get("title", species_id))


func is_rival(species_id: String, opponent: String) -> bool:
	var r := rival_of(species_id)
	return r != "" and r == opponent


func _holds(c: CritterInstance, cond: Dictionary) -> bool:
	var need := int(cond.get("min", 1))
	match str(cond.get("type", "")):
		"sealed": return c.uid != ""   # every critter in the roster has been sealed in a jar
		"bouts_survived": return c.bouts_survived >= need
		"bond": return c.bond_level(bond_thresholds) >= need
		"near_death": return c.near_death_count >= need
		"wins_vs_rival": return c.wins_vs_rival >= need
		"trial_complete": return c.trial_complete
	push_warning("StoryRules: unknown condition " + str(cond))
	return false


func chapter_met(c: CritterInstance, chapter: int) -> bool:
	var conds := conditions(c.species, chapter)
	if conds.is_empty():
		return false
	for cond in conds:
		if not _holds(c, cond):
			return false
	return true


## Unlocks every newly satisfied chapter on a living critter. Returns the newly unlocked chapter numbers (ascending).
func evaluate(c: CritterInstance) -> Array:
	var gained: Array = []
	if not c.alive:
		return gained
	for ch in range(1, chapter_count + 1):
		if not c.chapters_unlocked.has(ch) and chapter_met(c, ch):
			c.chapters_unlocked.append(ch)
			gained.append(ch)
	c.chapters_unlocked.sort()
	return gained
