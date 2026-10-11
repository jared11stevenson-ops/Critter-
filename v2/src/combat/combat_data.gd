class_name CombatData extends RefCounted
## Static loader / cache for combat data files. All reads use res:// paths.
const RULES_PATH := "res://src/combat/rules.json"
const ARENAS_PATH := "res://src/combat/arenas.json"
const CRITTER_DIR := "res://data/critters/"
const MOVE_DIR := "res://data/moves/"
static var _rules: Dictionary = {}
static var _critters: Dictionary = {}
static var _arenas: Dictionary = {}

static func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("CombatData: cannot open " + path)
		return null
	var txt := f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null:
		push_error("CombatData: JSON parse error in " + path)
	return parsed

static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = read_json(RULES_PATH)
		_rules["guard_cos_half"] = cos(deg_to_rad(float(_rules["guard_arc_deg"]) * 0.5))
	return _rules

static func critter_ids() -> Array:
	return rules()["roster"]

static func critter(id: String) -> CritterDef:
	if _critters.has(id):
		return _critters[id]
	var d: Variant = read_json(CRITTER_DIR + id + ".json")
	if d == null:
		return null
	var c := CritterDef.from_dict(d)
	var md: Variant = read_json(MOVE_DIR + id + ".json")
	if md != null:
		for mid in md["moves"].keys():
			c.moves[mid] = MoveDef.from_dict(mid, md["moves"][mid])
	_critters[id] = c
	return c

static func arena(id: String) -> ArenaDef:
	if _arenas.is_empty():
		var d: Dictionary = read_json(ARENAS_PATH)
		for k in d.keys():
			var ad: Dictionary = d[k]
			ad["id"] = k
			_arenas[k] = ArenaDef.from_dict(ad)
	return _arenas.get(id)

static func reload() -> void:
	_rules = {}
	_critters = {}
	_arenas = {}
