extends Node
## Autoload `Settings`: player options, persisted as JSON in user://v2_settings.json.
## Pure data + validation; the only engine side effect is apply() (fps cap). Safe to instantiate in tests:
## `load("res://src/core/settings.gd").new()` then set `path` to a temp file.

const VERSION := 1
const QUALITY_NAMES := ["Low", "Medium", "High"]
const FPS_CAPS := [30, 60, 90, 120]

const DEFAULTS := {
	"quality": 2,               # 0 Low, 1 Medium, 2 High
	"fps_cap": 60,              # one of FPS_CAPS
	"left_handed": false,       # mirrors touch layout
	"assist_wide_parry": false, # wider parry window (non-Blood tiers only)
	"assist_slow_tells": false, # slower tells (non-Blood tiers only)
	"reduce_flashing": false,   # no screen flashes / impact-frame strobes
	"perf_overlay": false,
	"master_volume": 1.0,
}

var path := "user://v2_settings.json"
var values: Dictionary = DEFAULTS.duplicate()


func _ready() -> void:
	load_settings()
	apply()


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


## Validates and stores a value. Returns false (and keeps the old value) for unknown keys / wrong types.
func set_value(key: String, v: Variant) -> bool:
	if not DEFAULTS.has(key):
		return false
	var clean: Variant = _sanitize(key, v)
	if clean == null:
		return false
	values[key] = clean
	var bus := _bus()
	if bus:
		bus.settings_changed.emit(key, clean)
	return true


func _sanitize(key: String, v: Variant) -> Variant:
	var def: Variant = DEFAULTS[key]
	match key:
		"quality":
			if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
				return clampi(int(v), 0, QUALITY_NAMES.size() - 1)
			return null
		"fps_cap":
			if typeof(v) in [TYPE_INT, TYPE_FLOAT] and int(v) in FPS_CAPS:
				return int(v)
			return null
		"master_volume":
			if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
				return clampf(float(v), 0.0, 1.0)
			return null
	return v if typeof(v) == typeof(def) else null


func quality_name() -> String:
	return QUALITY_NAMES[int(get_value("quality"))]


## Assist options only apply outside Blood Bouts (GDD 5.4). stakes: StakesTier value.
func assist_allowed(stakes: int) -> bool:
	return stakes != StakesTier.BLOOD


func parry_window_bonus_frames(stakes: int) -> int:
	return 4 if (get_value("assist_wide_parry") and assist_allowed(stakes)) else 0


func tell_slow_factor(stakes: int) -> float:
	return 1.5 if (get_value("assist_slow_tells") and assist_allowed(stakes)) else 1.0


## 3D render scale / shadows suggestions for the quality level (consumed by arena code).
func render_scale() -> float:
	return [0.6, 0.8, 1.0][int(get_value("quality"))]


func shadows_enabled() -> bool:
	return int(get_value("quality")) >= 2


func apply() -> void:
	Engine.max_fps = int(get_value("fps_cap"))


func to_dict() -> Dictionary:
	return {"version": VERSION, "values": values.duplicate()}


## Merges a loaded dict over defaults; unknown/invalid entries are ignored.
func from_dict(d: Dictionary) -> void:
	values = DEFAULTS.duplicate()
	var src: Variant = d.get("values", {})
	if src is Dictionary:
		for k in src:
			var clean: Variant = _sanitize(str(k), src[k]) if DEFAULTS.has(str(k)) else null
			if clean != null:
				values[str(k)] = clean


func save() -> bool:
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


func load_settings() -> bool:
	if not FileAccess.file_exists(path):
		values = DEFAULTS.duplicate()
		return false
	var j := JSON.new()
	var parsed: Variant = j.data if j.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not (parsed is Dictionary):
		values = DEFAULTS.duplicate()
		return false
	from_dict(parsed)
	return true


func _bus() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/Events")
