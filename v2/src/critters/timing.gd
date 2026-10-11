extends RefCounted
## Resolves (startup, active, recovery) frames for visuals so poses sync with frame data.
## Priority: 1) fs["phase"] / fs["startup","active","recovery"] supplied by the sim snapshot,
##           2) res://data/moves/<move_id>.json (INTERFACES.md section 1 schema: startup / active / recovery),
##           3) STUB table below.
##
## !!! STUB !!!  The numbers in STUB are PRESENTATION PLACEHOLDERS (60 Hz frames) used only until
## v2/data/moves is merged by the Combat Engineer. They are NOT gameplay data and must never drive the sim.
## Haldor light 16 / heavy 36 and Sessa light 10 follow ROSTER.md; the rest are guesses by the Character Artist.

const STUB_DEFAULT := {
	"strike_light": [12, 3, 12], "strike_heavy": [24, 5, 18], "guard": [4, 1, 6], "parry": [2, 6, 10],
	"grab": [10, 3, 16], "dodge": [2, 10, 8], "ability1": [18, 6, 24], "ability2": [14, 6, 20],
	"laststand": [30, 40, 20], "hit": [1, 4, 12], "stagger": [2, 30, 10], "ko": [8, 40, 60],
}
const STUB := {
	"haldor": {"strike_light": [16, 4, 14], "strike_heavy": [36, 6, 24], "ability1": [30, 8, 26], "ability2": [20, 14, 22], "grab": [14, 3, 18]},
	"sessa": {"strike_light": [10, 3, 8], "strike_heavy": [20, 4, 14], "ability1": [8, 24, 10], "ability2": [8, 10, 8], "parry": [2, 10, 10]},
	"weft": {"strike_light": [14, 4, 12], "strike_heavy": [26, 5, 18], "grab": [16, 4, 16]},
	"cinder": {"strike_light": [12, 3, 12], "strike_heavy": [24, 5, 20], "ability1": [20, 6, 24]},
	"marro": {"strike_light": [13, 4, 12], "strike_heavy": [24, 5, 18], "ability1": [10, 40, 16], "ability2": [24, 6, 24]},
	"zell": {"strike_light": [9, 3, 9], "strike_heavy": [18, 4, 14], "ability1": [14, 14, 14]},
	"kragg": {"strike_light": [14, 4, 14], "strike_heavy": [26, 5, 20], "grab": [12, 4, 18]},
}
static var _cache := {}

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
		if not _cache.has(move_id):
			var path := "res://data/moves/%s.json" % move_id
			var v = null
			if FileAccess.file_exists(path):
				var j = JSON.parse_string(FileAccess.get_file_as_string(path))
				if j is Dictionary and j.has("startup"):
					v = Vector3i(int(j["startup"]), int(j.get("active", 1)), int(j.get("recovery", 1)))
			_cache[move_id] = v
		if _cache[move_id] != null:
			return _cache[move_id]
	var t: Array = STUB.get(critter, {}).get(action, STUB_DEFAULT.get(action, [1, 1, 1]))
	return Vector3i(t[0], t[1], t[2])
