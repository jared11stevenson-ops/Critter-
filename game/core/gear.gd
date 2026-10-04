class_name Gear
extends RefCounted
## Gear runtime (design/DATA_REQUESTS.md 7.2). Data: game/canon/gear.json. State lives in GameState.flags so it saves with
## everything else: "_gear_owned" (Array of item ids) and "_gear_loadout" ({character: {slot: item id}}).
## Stats are applied centrally: Balance.v/f call Gear.modify(path, base), so every consumer of a balance path (actors, kits,
## pickups, burden) sees the equipped gear without per-actor code. Apply order: base, all adds, then all multipliers.

const PATH := "res://game/canon/gear.json"
static var _data: Dictionary = {}
static var _items: Dictionary = {}
static var _loaded := false
static var _active: Dictionary = {}     # stat path -> {add, mul}

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if d is Dictionary:
		_data = d
		for it in d.get("items", []):
			_items[str(it["id"])] = it
	refresh()

static func item(id: String) -> Dictionary:
	_load()
	return _items.get(id, {})

static func slots() -> Array:
	_load()
	return _data.get("slots", ["weapon", "charm", "garment"])

static func owned() -> Array:
	var o: Variant = GameState.flags.get("_gear_owned", [])
	return o if o is Array else []

static func loadout() -> Dictionary:
	var l: Variant = GameState.flags.get("_gear_loadout", {})
	return l if l is Dictionary else {}

static func owned_for(character: String) -> Array:
	_load()
	var out: Array = []
	for id in owned():
		var it: Dictionary = _items.get(str(id), {})
		if not it.is_empty() and str(it.get("character", "")) == character:
			out.append(it)
	return out

static func characters_with_gear() -> Array:
	_load()
	var out: Array = []
	for id in owned():
		var c := str(_items.get(str(id), {}).get("character", ""))
		if c != "" and not out.has(c):
			out.append(c)
	return out

static func equipped(character: String, slot: String) -> String:
	return str(loadout().get(character, {}).get(slot, ""))

## Grants an item once. Returns true when it was new.
static func grant(id: String, announce: bool = true) -> bool:
	_load()
	if not _items.has(id) or owned().has(id):
		return false
	var o: Array = owned().duplicate()
	o.append(id)
	GameState.flags["_gear_owned"] = o
	var it: Dictionary = _items[id]
	# auto-equip into an empty slot so new gear is felt immediately
	if equipped(str(it.get("character", "")), str(it.get("slot", ""))) == "":
		equip(id, false)
	if announce:
		Events.toast.emit("Gear found: %s" % str(it.get("name", id)), "item")
	GameState.save_game()
	return true

static func equip(id: String, announce: bool = true) -> void:
	_load()
	var it: Dictionary = _items.get(id, {})
	if it.is_empty() or not owned().has(id):
		return
	var ch := str(it.get("character", ""))
	var l: Dictionary = loadout().duplicate(true)
	if not l.has(ch):
		l[ch] = {}
	var was := str(l[ch].get(str(it["slot"]), ""))
	l[ch][str(it["slot"])] = id
	GameState.flags["_gear_loadout"] = l
	for h in it.get("hooks", []):
		if str(h) == "ledger_blank_page_unsellable" and was != id:
			Ledger.record("chose", "player", "not_for_sale_ledger", ["not_for_sale"], {}, 1)
	refresh()
	if announce:
		GameState.save_game()

static func unequip(character: String, slot: String) -> void:
	var l: Dictionary = loadout().duplicate(true)
	if l.has(character):
		l[character].erase(slot)
	GameState.flags["_gear_loadout"] = l
	refresh()
	GameState.save_game()

## Rebuilds the stat table from the loadout. Call after anything that changes equipment or loads a save.
static func refresh() -> void:
	if not _loaded:
		_load()      # _load() ends by calling refresh() again
		return
	_active.clear()
	for ch in loadout():
		for slot in loadout()[ch]:
			var it: Dictionary = _items.get(str(loadout()[ch][slot]), {})
			for st in it.get("stats", []):
				var p := str(st["stat"])
				var e: Dictionary = _active.get(p, {"add": 0.0, "mul": 1.0})
				if str(st.get("op", "add")) == "mult":
					e["mul"] = float(e["mul"]) * float(st["value"])
				else:
					e["add"] = float(e["add"]) + float(st["value"])
				_active[p] = e

static func modify(path: String, base: Variant) -> Variant:
	if not _loaded:
		_load()
	if _active.is_empty() or not _active.has(path) or not (base is float or base is int):
		return base
	var e: Dictionary = _active[path]
	return (float(base) + float(e["add"])) * float(e["mul"])

static func touches(prefix: String) -> bool:
	if not _loaded:
		_load()
	if _active.is_empty():
		return false
	for k in _active:
		if str(k).begins_with(prefix + "."):
			return true
	return false

static func describe(it: Dictionary) -> String:
	var parts: Array = []
	for st in it.get("stats", []):
		var v := float(st["value"])
		var nm := str(st["stat"]).replace(".", " ").replace("_", " ")
		if str(st.get("op", "add")) == "mult":
			parts.append("%s x%.2f" % [nm, v])
		else:
			parts.append("%s %s%s" % [nm, "+" if v >= 0 else "", str(snappedf(v, 0.01))])
	return ", ".join(parts)
