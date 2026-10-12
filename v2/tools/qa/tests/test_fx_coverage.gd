extends RefCounted
## Every ability and Last Stand must have: an icon, a sound, and a VFX recipe (so none is silent or invisible).
## Abilities = the move ids listed under data/critters/<id>.json moves.ability1..3 + last_stand.

const CRITTERS := ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris"]

func run() -> Array:
	var fails: Array = []
	for cid in CRITTERS:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/critters/%s.json" % cid))
		var mv: Dictionary = d["moves"]
		var ids: Array = []
		for k in ["ability1", "ability2", "ability3", "last_stand", "laststand"]:
			if mv.has(k):
				ids.append(str(mv[k]))
		QaCheck.is_true(fails, ids.size() >= 4, "%s lists 3 abilities + last stand (got %d)" % [cid, ids.size()])
		for mid in ids:
			var base: String = AbilityVfx.base_id(mid) if mid != "bramvex_day_20" else mid
			QaCheck.is_true(fails, ResourceLoader.exists("res://art/icons/%s.png" % mid) or ResourceLoader.exists("res://art/icons/%s.png" % base), "icon for %s" % mid)
			QaCheck.is_true(fails, ResourceLoader.exists("res://audio/sfx/%s.ogg" % mid) or ResourceLoader.exists("res://audio/sfx/%s.ogg" % base), "sound for %s" % mid)
			var holder := Node3D.new()
			var ctx := {"parent": holder, "pos": Vector3.ZERO, "tpos": Vector3(4, 0, 0), "dir": Vector3.RIGHT, "col": Color.WHITE, "acc": Color.WHITE, "glow": Color.WHITE}
			QaCheck.is_true(fails, AbilityVfx.cast(mid, ctx), "vfx recipe for %s" % mid)
			holder.free()
	return fails
