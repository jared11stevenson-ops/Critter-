class_name SaveMigrations
extends RefCounted
## Versioned save schema. Every released schema change adds one `_vN_to_vN+1` step and bumps CURRENT.
##  v1 (prototype): {version:1, profile, critters:[{.. bouts, hp ..}], fallen:[..], money:{scrap, amber, rep}, next_id}
##  v2 (current):   {version:2, saved_at, roster:{profile_id, next_uid, rack[7], wall[], economy, legacy, ...}}

const CURRENT := 2


## Returns {ok, data, error, from}. Never mutates `data`. Saves from a NEWER game are refused, never rewritten.
static func migrate(data: Dictionary) -> Dictionary:
	if not data.has("version") or not (typeof(data["version"]) in [TYPE_INT, TYPE_FLOAT]):
		return {"ok": false, "error": "missing schema version", "data": {}, "from": -1}
	var v := int(data["version"])
	if v > CURRENT:
		return {"ok": false, "error": "save is from a newer game version (%d > %d)" % [v, CURRENT], "data": {}, "from": v}
	if v < 1:
		return {"ok": false, "error": "invalid schema version %d" % v, "data": {}, "from": v}
	var d := data.duplicate(true)
	while int(d["version"]) < CURRENT:
		match int(d["version"]):
			1: d = _v1_to_v2(d)
			_: return {"ok": false, "error": "no migration from v%d" % int(d["version"]), "data": {}, "from": v}
	return {"ok": true, "data": d, "error": "", "from": v}


static func _v1_to_v2(d: Dictionary) -> Dictionary:
	var rack: Array = []
	for c in d.get("critters", []):
		var m: Dictionary = (c as Dictionary).duplicate(true)
		m["bouts_survived"] = int(m.get("bouts", m.get("bouts_survived", 0)))
		m.erase("bouts")
		m["vitality"] = float(m.get("hp", m.get("vitality", 1.0)))
		m.erase("hp")
		m["alive"] = true
		rack.append(m)
	rack.resize(maxi(rack.size(), Rack.CAPACITY))
	rack = rack.slice(0, Rack.CAPACITY)
	var money: Dictionary = d.get("money", {})
	return {
		"version": 2,
		"saved_at": int(d.get("saved_at", 0)),
		"roster": {
			"profile_id": str(d.get("profile", "")),
			"next_uid": int(d.get("next_id", 1)),
			"session_count": 0,
			"care_points": CareModel.CARE_POINTS,
			"rack": rack,
			"wall": d.get("fallen", []),
			"economy": {"scrap": int(money.get("scrap", 0)), "amber": int(money.get("amber", 0)), "reputation": int(money.get("rep", 0))},
			"legacy": {"relics": [], "moves": []},
		},
	}
