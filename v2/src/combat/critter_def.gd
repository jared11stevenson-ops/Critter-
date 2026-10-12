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
var abilities: Array = []           # [ability1, ability2, ability3] move ids
var last_stand := ""
var difficulty := 1                 # 1..3 stars: how much thinking the kit asks for. NEVER a strength rating.
var role := ""                      # breaker reader warden brewer anchor drifter binder (design/v2/ROLES.md)
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
	c.role = str(d.get("role", ""))
	c.difficulty = clampi(int(d.get("difficulty", 1)), 1, 3)
	c.abilities = [str(c.move_ids.get("ability1", "")), str(c.move_ids.get("ability2", "")), str(c.move_ids.get("ability3", ""))]
	c.last_stand = str(c.move_ids.get("laststand", ""))
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
