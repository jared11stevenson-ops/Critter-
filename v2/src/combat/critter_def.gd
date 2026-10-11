class_name CritterDef extends RefCounted
## A fighter's static definition: stats (36-point budget), move ids and tuning overrides.
## Loaded from v2/data/critters/<id>.json by CombatData.
var id := ""
var display_name := ""
var species := ""
var archetype := ""
var palette: Dictionary = {}
var stats: Dictionary = {}          # vit sta poi spd rch dmg (1..10)
var move_ids: Dictionary = {}       # light:[ids] heavy grab dodge ability1 ability2 laststand
var moves: Dictionary = {}          # id -> MoveDef (filled by CombatData)
var tuning: Dictionary = {}         # per-critter overrides of derived values
var ai_hints: Dictionary = {}       # ability usage hints for the AI
var raw: Dictionary = {}

static func from_dict(d: Dictionary) -> CritterDef:
	var c := CritterDef.new()
	c.raw = d
	c.id = str(d["id"])
	c.display_name = str(d.get("name", c.id))
	c.species = str(d.get("species", ""))
	c.archetype = str(d.get("archetype", ""))
	c.palette = d.get("palette", {})
	c.stats = d.get("stats", {})
	c.move_ids = d.get("moves", {})
	c.tuning = d.get("tuning", {})
	c.ai_hints = d.get("ai", {})
	return c

func stat_total() -> int:
	var t := 0
	for k in stats.keys():
		t += int(stats[k])
	return t

func move(mid: String) -> MoveDef:
	return moves.get(mid) as MoveDef

## Derived value: explicit tuning override, else computed from stats via rules["stats"].
func derived(key: String, rules: Dictionary) -> float:
	if tuning.has(key):
		return float(tuning[key])
	var f: Dictionary = rules["stat_formulas"]
	var fd: Dictionary = f[key]
	return float(fd["base"]) + float(fd["per"]) * float(stats[str(fd["stat"])])
