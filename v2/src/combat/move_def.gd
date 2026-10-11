class_name MoveDef extends RefCounted
## Frame data for one move. Parsed from v2/data/moves/<critter>.json (see SCHEMA.md).
## Every move normalises into a list of `hits` (single-hit moves have exactly one).
var id := ""
var name := ""
var kind := "light"          # light | heavy | grab | dodge | ability | laststand
var tell_anim := ""
var startup := 0
var active := 0
var recovery := 0
var total := 0
var stamina_cost := 0.0
var cooldown := 0
var pressure_cost := 0.0
var pressure_gain := 0.0
var track := 0               # frames of facing-tracking from move start
var move_mult := 0.0         # walk speed multiplier during startup/recovery
var iframes_from := 0
var iframes_count := 0
var armor := 0.0             # 0..1 damage reduction + no flinch
var armor_from := 0
var armor_to := 0
var chain := ""              # next move id when chained
var cancel_from := -1        # frame from which the chain / cancel is accepted
var chain_on := "contact"    # contact | always
var feint := false           # startup may be cancelled into guard / grab
var require_pressure := 0.0
var lore_source := ""        # tag + quote key from design/v2/LORE_MOVES.md (mandatory, validator-enforced)
var pressure_on_use := 0.0   # resource gained when the move is used (Future-Noise)
var reserve_cost := 0.0      # silk reserve spent
var promise: Dictionary = {} # declared Promise attack {bonus, refund, penalty}
var charge_max := 0          # heavy that keeps growing while held (frames)
var charge_at := 0           # frame at which the charge holds
var self_damage_ratio := 0.0 # fraction of CURRENT vitality paid on use (cannot kill)
var motion: Array = []
var hits: Array = []
var spawns: Array = []
var stance: Dictionary = {}
var props: Dictionary = {}
var raw: Dictionary = {}

static func from_dict(move_id: String, d: Dictionary) -> MoveDef:
	var m := MoveDef.new()
	m.id = move_id
	m.raw = d
	m.name = str(d.get("name", move_id))
	m.kind = str(d.get("kind", "light"))
	m.tell_anim = str(d.get("tell_anim", ""))
	m.startup = int(d.get("startup", 0))
	m.active = int(d.get("active", 1))
	m.recovery = int(d.get("recovery", 0))
	m.stamina_cost = float(d.get("stamina_cost", 0.0))
	m.cooldown = int(d.get("cooldown", 0))
	m.pressure_cost = float(d.get("pressure_cost", 0.0))
	m.pressure_gain = float(d.get("pressure_gain", 0.0))
	m.track = int(d.get("track", 0))
	m.move_mult = float(d.get("move_mult", 0.0))
	var ifr: Array = d.get("iframes", [0, 0])
	m.iframes_from = int(ifr[0])
	m.iframes_count = int(ifr[1])
	m.armor = float(d.get("armor", 0.0))
	var arm: Array = d.get("armor_frames", [0, m.startup + m.active])
	m.armor_from = int(arm[0])
	m.armor_to = int(arm[1])
	m.chain = str(d.get("chain", ""))
	m.cancel_from = int(d.get("cancel_from", -1))
	m.chain_on = str(d.get("chain_on", "contact"))
	m.feint = bool(d.get("feint", false))
	m.require_pressure = float(d.get("require_pressure", 0.0))
	m.lore_source = str(d.get("lore_source", ""))
	m.pressure_on_use = float(d.get("pressure_on_use", 0.0))
	m.reserve_cost = float(d.get("reserve_cost", 0.0))
	m.promise = d.get("promise", {})
	m.charge_max = int(d.get("charge_max", 0))
	m.charge_at = int(d.get("charge_at", 0))
	m.self_damage_ratio = float(d.get("self_damage_ratio", 0.0))
	m.motion = d.get("motion", [])
	m.spawns = d.get("spawns", [])
	m.stance = d.get("stance", {})
	m.props = d.get("props", {})
	m.total = m.startup + m.active + m.recovery
	if d.has("total"):
		m.total = int(d["total"])
	m._build_hits(d)
	return m

func _build_hits(d: Dictionary) -> void:
	hits = []
	var base := _norm(d)
	if d.has("rehit"):
		var rh: Dictionary = d["rehit"]
		var every := int(rh.get("every", 5))
		var count := int(rh.get("count", 1))
		var from := int(rh.get("from", startup))
		for i in count:
			var h := _merge(base, _norm(rh.get("override", {})), from + i * every, int(rh.get("len", 1)))
			if rh.has("scale"):
				h["damage"] = float(h["damage"]) * pow(float(rh["scale"]), i)
			hits.append(h)
		var last := from + count * every
		if total < last + recovery:
			total = last + recovery
	elif d.has("hits"):
		for e in d["hits"]:
			hits.append(_merge(base, _norm(e), int(e.get("at", startup)), int(e.get("len", 1))))
	elif d.has("damage") or d.has("on_hit") or d.has("hitbox") or d.has("grab"):
		hits.append(_merge(base, {}, startup, active))

## Flatten a JSON hit description (top-level keys + hitbox{} + props{}) into internal hit keys.
static func _norm(src: Dictionary) -> Dictionary:
	var h := {}
	var rename := {"poise_damage": "poise", "knockback": "knock"}
	for k in src.keys():
		if k in ["hitbox", "props"]:
			for kk in src[k].keys():
				h[kk] = src[k][kk]
		elif k in ["startup", "active", "recovery", "name", "kind", "tell_anim", "iframes", "motion", "spawns", "stance", "hits", "rehit", "chain", "stamina_cost", "lore_source", "promise"]:
			continue
		else:
			h[rename.get(k, k)] = src[k]
	return h

static func _merge(base: Dictionary, over: Dictionary, at: int, len_: int) -> Dictionary:
	var h := {"damage": 0.0, "poise": 0.0, "hitstun": 0, "blockstun": 0, "knock": 0.0, "hitstop": 0,
		"reach": 1.0, "arc": 90.0, "offset": 0.0, "throw_dist": 0.0, "throw_stun": 0, "kd_frames": 0,
		"unblockable": false, "guard_crush": false, "grab": false, "knockdown": false, "unparryable": false,
		"ranged": false, "command": false, "no_clash": false, "on_hit": {}}
	for k in base.keys():
		h[k] = base[k]
	for k in over.keys():
		if k == "on_hit":
			var oh: Dictionary = h["on_hit"].duplicate()
			for kk in over[k].keys():
				oh[kk] = over[k][kk]
			h[k] = oh
		else:
			h[k] = over[k]
	h["at"] = at
	h["len"] = len_
	h["cos_half"] = cos(deg_to_rad(float(h["arc"]) * 0.5))
	return h
