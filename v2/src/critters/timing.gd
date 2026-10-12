extends RefCounted
## Resolves (startup, active, recovery) frames for visuals so poses sync with frame data.
## (see _move below for the data/moves layout)
## Priority: 1) fs["phase"] / fs["startup","active","recovery"] supplied by the sim snapshot,
##           2) res://data/moves/<move_id>.json (INTERFACES.md section 1 schema: startup / active / recovery),
##           3) STUB table below.
##
## !!! STUB !!!  The numbers in STUB are PRESENTATION PLACEHOLDERS (60 Hz frames) used only until
## v2/data/moves is merged by the Combat Engineer. They are NOT gameplay data and must never drive the sim.
## All values are guesses by the Character Artist (old Haldor/Sessa-slot numbers carried to Aruun/Cigarra).

const STUB_DEFAULT := {
	"strike_light": [12, 3, 12], "strike_heavy": [24, 5, 18], "guard": [4, 1, 6], "parry": [2, 6, 10],
	"grab": [10, 3, 16], "dodge": [2, 10, 8], "ability1": [18, 6, 24], "ability2": [14, 6, 20],
	"laststand": [30, 40, 20], "hit": [1, 4, 12], "stagger": [2, 30, 10], "ko": [8, 40, 60], "knockdown": [6, 30, 24], "clash": [1, 4, 10],
}
const STUB := {
	"aruun": {"strike_light": [16, 4, 14], "strike_heavy": [36, 6, 24], "ability1": [30, 8, 26], "ability2": [20, 14, 22], "grab": [14, 3, 18]},
	"cigarra": {"strike_light": [10, 3, 8], "strike_heavy": [20, 4, 14], "ability1": [8, 24, 10], "ability2": [14, 8, 12], "parry": [2, 10, 10]},
	"bramvex": {"strike_light": [16, 4, 14], "strike_heavy": [30, 6, 20], "ability1": [20, 6, 22]},
	"scarlith": {"strike_light": [13, 3, 12], "strike_heavy": [24, 5, 20], "ability1": [20, 6, 24]},
	"mollusk": {"strike_light": [18, 4, 16], "strike_heavy": [38, 6, 26], "ability1": [24, 10, 24]},
	"zephyr": {"strike_light": [9, 3, 9], "strike_heavy": [18, 4, 14], "ability1": [14, 14, 14]},
	"nyxaris": {"strike_light": [14, 4, 14], "strike_heavy": [26, 5, 20], "grab": [12, 4, 18]},
	"pharilux": {"strike_light": [12, 3, 11], "strike_heavy": [32, 4, 26], "ability1": [18, 4, 22]},
}
static var _cache := {}

## Combat Engineer data layout (v2/data/moves/<critter>.json): {"critter": id, "moves": {move_id: {startup, active, recovery, tell_anim, kind, ...}}}.
static func _move(critter: String, move_id: String) -> Dictionary:
	var key := critter + "/" + move_id
	if not _cache.has(key):
		var d := {}
		var path := "res://data/moves/%s.json" % critter
		if FileAccess.file_exists(path):
			var j = JSON.parse_string(FileAccess.get_file_as_string(path))
			if j is Dictionary and j.has("moves") and (j["moves"] as Dictionary).has(move_id):
				d = j["moves"][move_id]
		_cache[key] = d
	return _cache[key]

## The move's swing style key (`tell_anim`): one of PoseLib.STYLES (chop overhead slash_up slash_back thrust punch hook charge spin stance roar leap grab).
static func tell_anim(critter: String, move_id: String, fs: Dictionary) -> String:
	if fs.has("tell_anim"):
		return str(fs["tell_anim"])
	return str(_move(critter, move_id).get("tell_anim", ""))

static func resolve(critter: String, action: String, move_id: String, fs: Dictionary) -> Vector3i:
	if fs.has("phase"):
		var ph = fs["phase"]
		if ph is Vector3i:
			return ph
		if ph is Dictionary:
			return Vector3i(int(ph.get("startup", 1)), int(ph.get("active", 1)), int(ph.get("recovery", 1)))
	if fs.has("startup"):
		return Vector3i(int(fs["startup"]), int(fs.get("active", 1)), int(fs.get("recovery", 1)))
	if move_id != "":
		var m := _move(critter, move_id)
		if m.has("startup"):
			return Vector3i(int(m["startup"]), int(m.get("active", 1)), int(m.get("recovery", 1)))
	var t: Array = STUB.get(critter, {}).get(action, STUB_DEFAULT.get(action, [1, 1, 1]))
	return Vector3i(t[0], t[1], t[2])
