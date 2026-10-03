class_name Balance
extends RefCounted
## Tuning data access. All numbers live in res://game/combat/balance.json.
## Usage: Balance.v("aruun.combo.damage", [22,22,40]) / Balance.f("aruun.hp", 420)

const PATH := "res://game/combat/balance.json"
static var _data: Dictionary = {}
static var _loaded := false

static func reload() -> void:
	_loaded = true
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("Balance: balance.json missing, using code defaults")
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_data = d

static func v(path: String, default: Variant = null) -> Variant:
	if not _loaded:
		reload()
	var cur: Variant = _data
	for part in path.split("."):
		if cur is Dictionary and (cur as Dictionary).has(part):
			cur = (cur as Dictionary)[part]
		else:
			return default
	return cur

static func f(path: String, default: float = 0.0) -> float:
	return float(v(path, default))

static func arr(path: String, idx: int, default: float = 0.0) -> float:
	var a: Variant = v(path, null)
	if a is Array and idx < (a as Array).size():
		return float(a[idx])
	return default

static func section(path: String) -> Dictionary:
	var d: Variant = v(path, {})
	return d if d is Dictionary else {}
