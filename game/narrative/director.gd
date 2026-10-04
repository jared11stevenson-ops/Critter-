class_name Director
extends RefCounted
## Session Zero tone + the adaptive Director (v1).
## Session Zero: the player sets four tone sliders (0..4, default 2) once at the start of a game:
##   combat (how often and how hard fights are), story (how much the world talks), exploration (how much
##   the land hands out), puzzle (how long environmental challenges ask you to hold on).
## The Director reads those and the player's recent struggle, and applies ONE readable rule:
## ADVANTAGE (the field eases off after wipes/downs) or DISADVANTAGE (a confident run gets more resistance).
## It never hides the rule: it toasts when it changes the stance. Pure static state, no autoload needed.

const KEYS := ["combat", "story", "explore", "puzzle"]
const DEFAULTS := {"combat": 2, "story": 2, "explore": 2, "puzzle": 2}
const LABELS := {
	"combat": ["Combat", "Rare and gentle", "Fewer fights, softer hits", "Balanced", "Frequent and sharper", "Relentless"],
	"story": ["Story", "Quiet", "Sparse", "Balanced", "Talkative", "Everything gets said"],
	"explore": ["Exploration", "Guided", "Lightly guided", "Balanced", "Generous land", "Overflowing land"],
	"puzzle": ["Puzzle", "Forgiving", "Relaxed", "Balanced", "Demanding", "Exacting"],
}

static var struggle := 0.0          # rises when the party goes down, decays with time and clean kills
static var confidence := 0.0        # rises with clean play
static var stance := "even"         # "advantage" | "even" | "disadvantage"
static var wipes := 0
static var _stamp := 0
static var _connected := false
static var _last_toast := 0

# ---------------- tone ----------------
static func has_tone() -> bool:
	return GameState.settings.has("session_zero")

static func tone(key: String) -> int:
	var d: Variant = GameState.settings.get("session_zero", null)
	if d is Dictionary and d.has(key):
		return clampi(int(d[key]), 0, 4)
	return int(DEFAULTS.get(key, 2))

static func set_tone(key: String, v: int) -> void:
	var d: Dictionary = GameState.settings.get("session_zero", DEFAULTS.duplicate())
	d[key] = clampi(v, 0, 4)
	GameState.settings["session_zero"] = d

static func describe(key: String, v: int) -> String:
	var l: Array = LABELS[key]
	return str(l[clampi(v, 0, 4) + 1])

## Linear map of a 0..4 tone to [lo, hi].
static func _lerp_tone(key: String, lo: float, hi: float) -> float:
	return lerpf(lo, hi, float(tone(key)) / 4.0)

# ---------------- multipliers (read by gameplay) ----------------
static func enemy_hp_mult() -> float:
	var m := _lerp_tone("combat", 0.8, 1.25)
	if stance == "advantage":
		m *= 0.9
	elif stance == "disadvantage":
		m *= 1.1
	return m

static func enemy_damage_mult() -> float:
	var m := _lerp_tone("combat", 0.8, 1.2)
	if stance == "advantage":
		m *= 0.8
	elif stance == "disadvantage":
		m *= 1.1
	return m

static func pickup_mult() -> float:
	return _lerp_tone("explore", 0.7, 1.6)

static func scan_radius_mult() -> float:
	return _lerp_tone("explore", 0.9, 1.25)

static func hold_time_mult() -> float:
	return _lerp_tone("puzzle", 0.7, 1.3)

## Story tone: low = barks and optional lines off, high = everything.
static func story_level() -> int:
	return tone("story")

## Combat 0 ("Rare and gentle") makes rivals open with talk before any shot is fired.
static func rivals_talk_first() -> bool:
	return tone("combat") == 0

# ---------------- adaptive stance ----------------
static func attach() -> void:
	if _connected:
		return
	_connected = true
	Events.actor_died.connect(_on_died)

static func _decay() -> void:
	var now := Time.get_ticks_msec()
	if _stamp > 0:
		var dt := float(now - _stamp) / 1000.0
		struggle = maxf(0.0, struggle - dt * 0.03)
		confidence = maxf(0.0, confidence - dt * 0.02)
	_stamp = now

static func _on_died(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	_decay()
	if str(actor.get("team")) == "party":
		struggle += 1.0
	elif str(actor.get("team")) == "enemy":
		confidence += 0.25
	_update()

static func on_wipe() -> void:
	_decay()
	wipes += 1
	struggle += 2.0
	confidence = 0.0
	_update()

static func reset_run() -> void:
	struggle = 0.0
	confidence = 0.0
	stance = "even"
	_stamp = 0

static func _update() -> void:
	var s := "even"
	if struggle >= 3.0:
		s = "advantage"
	elif confidence >= 4.0 and struggle < 0.5 and tone("combat") >= 2:
		s = "disadvantage"
	if s != stance:
		stance = s
		var now := Time.get_ticks_msec()
		if now - _last_toast > 4000:
			_last_toast = now
			match s:
				"advantage": Events.toast.emit("Director: ADVANTAGE — the Reaches ease off for a while", "info")
				"disadvantage": Events.toast.emit("Director: DISADVANTAGE — you are on a roll; the field pushes back", "warning")
				_: pass
