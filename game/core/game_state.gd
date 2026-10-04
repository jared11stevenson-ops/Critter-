extends Node
## Persistent world state + save/load + input map + settings.
## Bible Book XXXII: "A completed mission is not erased; it becomes part of the next world state."

var SAVE_PATH := "user://critter_save.json"
const SAVE_VERSION := 1

# World flags (see GDD §10). Values are bool / String / int.
var flags: Dictionary = {}
# Relationship trust per sapient partner (0..100). Relationship-driven recruitment, never ownership.
var trust: Dictionary = {"aruun": 40, "cigarra": 35}
# Materials / items: id -> count
var items: Dictionary = {}
# Contained specimens (Wild Containment). Array of {species, id, habitat:{...}}
var specimens: Array = []
# Unlocked codex entry ids
var codex: Array = []
var dominion_standing: int = 0
var chapter: String = "prologue"
var settings: Dictionary = {
	"music_volume": 0.8, "sfx_volume": 0.9, "screen_shake": 1.0,
	"show_damage_numbers": true, "left_handed": false, "reduce_flashing": false, "use_3d_models": true,
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	# QA runs use an isolated save and start fresh unless "qa_keep_save" is passed.
	var args := OS.get_cmdline_user_args()
	if args.has("qa"):
		SAVE_PATH = "user://qa_save.json"
		if not args.has("qa_keep_save"):
			if FileAccess.file_exists(SAVE_PATH):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
			return
	load_game()

# ---------------- Flags ----------------
func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

func set_flag(flag: String, value: Variant = true) -> void:
	if flags.get(flag) == value:
		return
	flags[flag] = value
	Events.world_flag_changed.emit(flag, value)

# ---------------- Trust ----------------
func add_trust(character_id: String, delta: int) -> void:
	var v: int = clampi(int(trust.get(character_id, 0)) + delta, 0, 100)
	trust[character_id] = v
	Events.trust_changed.emit(character_id, v)
	if delta != 0:
		var who := Canon.display_name(character_id)
		Events.toast.emit("%s %s" % [who, "trusts you more" if delta > 0 else "trusts you less"], "trust")

func get_trust(character_id: String) -> int:
	return int(trust.get(character_id, 0))

# ---------------- Items ----------------
func add_item(item_id: String, count: int = 1) -> void:
	items[item_id] = int(items.get(item_id, 0)) + count
	if items[item_id] <= 0:
		items.erase(item_id)
	Events.item_changed.emit(item_id, int(items.get(item_id, 0)))

func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func spend_item(item_id: String, count: int) -> bool:
	if item_count(item_id) < count:
		return false
	add_item(item_id, -count)
	return true

# ---------------- Codex ----------------
func unlock_codex(entry_id: String) -> bool:
	if entry_id in codex:
		return false
	codex.append(entry_id)
	Events.codex_unlocked.emit(entry_id)
	return true

# ---------------- Specimens ----------------
func add_specimen(species_id: String) -> void:
	specimens.append({"species": species_id, "id": "%s_%d" % [species_id, Time.get_ticks_msec()], "habitat": {}})
	Events.enemy_captured.emit(species_id)

# ---------------- Save / load ----------------
func new_game() -> void:
	flags = {}
	trust = {"aruun": 40, "cigarra": 35}
	items = {}
	specimens = []
	codex = []
	dominion_standing = 0
	chapter = "prologue"
	for n in ["Ledger", "Rivals"]:
		var sys := get_node_or_null("/root/" + n)
		if sys:
			sys.reset()
	save_now()
	Gear.refresh()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Debounced save: many call sites ask for a save (dialogue end, flag changes, level exits). Writing the
## whole save + Ledger synchronously on a phone costs a visible hitch, so requests coalesce into one
## write ~0.7 s later (and always flush when the app is paused, loses focus or closes).
var _save_wait := -1.0

func save_game() -> void:
	if _save_wait < 0.0:
		_save_wait = 0.7

func save_now() -> void:
	_save_wait = -1.0
	var data := {
		"version": SAVE_VERSION, "flags": flags, "trust": trust, "items": items,
		"specimens": specimens, "codex": codex, "dominion_standing": dominion_standing,
		"chapter": chapter, "settings": settings,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
	for n in ["Ledger", "Rivals"]:
		var sys := get_node_or_null("/root/" + n)
		if sys:
			sys.save()

func _process(delta: float) -> void:
	if _save_wait >= 0.0:
		_save_wait -= delta
		if _save_wait < 0.0:
			save_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _save_wait >= 0.0:
			save_now()

func load_game() -> void:
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return
	flags = d.get("flags", {})
	trust = d.get("trust", trust)
	items = d.get("items", {})
	specimens = d.get("specimens", [])
	codex = d.get("codex", [])
	dominion_standing = int(d.get("dominion_standing", 0))
	chapter = d.get("chapter", "prologue")
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]

# ---------------- Input ----------------
## Touch is primary. Keyboard/gamepad bindings exist for desktop testing and controller players.
	Gear.refresh()

func _setup_input_map() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_SPACE], "ability_1": [KEY_K], "ability_2": [KEY_L], "ability_3": [KEY_I],
		"swap": [KEY_Q, KEY_TAB], "scan": [KEY_E], "interact": [KEY_F, KEY_ENTER],
		"pause": [KEY_ESCAPE, KEY_P], "capture": [KEY_C], "dash": [KEY_SHIFT],
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var pad := {
		"attack": JOY_BUTTON_X, "ability_1": JOY_BUTTON_Y, "ability_2": JOY_BUTTON_B,
		"ability_3": JOY_BUTTON_RIGHT_SHOULDER, "swap": JOY_BUTTON_LEFT_SHOULDER,
		"scan": JOY_BUTTON_BACK, "interact": JOY_BUTTON_A, "pause": JOY_BUTTON_START,
		"dash": JOY_BUTTON_RIGHT_STICK,
	}
	for action in pad:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pad[action]
		InputMap.action_add_event(action, jb)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)
