class_name UiPrefs extends RefCounted
## UI-side preferences kept in user://v2_ui_prefs.json (touch layout A/B, on-screen controls, last picks, AI profile).
## Separate from core Settings on purpose (core is the Platform Engineer's); see arena/NEEDS.md to fold these in later.

const PATH := "user://v2_ui_prefs.json"
const DEFAULTS := {"layout": "A", "touch": "auto", "profile": "standard", "player": "aruun", "opponent": "cigarra", "arena": "ring", "training": false}
static var data: Dictionary = {}
static var path_override := ""
static var _loaded := false

static func _path() -> String:
	return path_override if path_override != "" else PATH

static func load_prefs() -> void:
	_loaded = true
	data = DEFAULTS.duplicate()
	if FileAccess.file_exists(_path()):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path()))
		if parsed is Dictionary:
			for k in DEFAULTS:
				if parsed.has(k) and typeof(parsed[k]) == typeof(DEFAULTS[k]):
					data[k] = parsed[k]

static func get_pref(key: String) -> Variant:
	if not _loaded:
		load_prefs()
	return data.get(key, DEFAULTS.get(key))

static func set_pref(key: String, value: Variant, save := true) -> void:
	if not _loaded:
		load_prefs()
	data[key] = value
	if save:
		var f := FileAccess.open(_path(), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(data))

## Touch controls show on devices with a touchscreen, when forced on in Settings, or with CRITTER_TOUCH=1 (screenshots / desktop trials).
static func touch_enabled() -> bool:
	var mode := str(get_pref("touch"))
	if mode == "on" or OS.get_environment("CRITTER_TOUCH") == "1":
		return true
	if mode == "off":
		return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
