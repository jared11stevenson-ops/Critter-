extends RefCounted
## Mutable per-fighter simulation state. Created and owned by CombatSim (no class_name).
var idx := 0
var def: CritterDef
var T: Dictionary = {}              # derived tuning values (walk_speed, block_chip, ...)
var radius := 0.5
var pos := Vector2.ZERO
var facing := Vector2.RIGHT
var forced := Vector2.ZERO          # decaying forced movement (knockback / throw), m per tick
var mvec := Vector2.ZERO            # direction latched for the current motion segment
var moving := false
var vit := 0.0
var max_vit := 1.0
var sta := 0.0
var max_sta := 1.0
var poise := 0.0
var max_poise := 1.0
var pressure := 0.0
var action := "idle"                # idle guard strike_light strike_heavy grab dodge ability1 ability2 laststand parry hit stagger knockdown clash ko
var stun_kind := ""                 # hit | block | guardbreak | parried | thrown | clash | stagger | knockdown
var af := 0                         # frames since the action started
var move: MoveDef = null
var hits_done := PackedByteArray()  # per hit entry: 0 pending, 1 resolved, 2 dodged (noted)
var contact := false                # current move hit or was blocked (enables chain)
var chain_idx := 0
var stun := 0
var iframes := 0                    # extra invulnerability frames (wake-up etc.)
var guard_press_frame := -1000
var guard_lag := 0
var prev_guard := false
var sta_delay := 0
var poise_delay := 0
var winded := false
var st: Dictionary = {}             # status name -> frames remaining
var slow_mult := 1.0
var haste_mult := 1.0
var dmg_mult := 1.0                 # temporary outgoing damage multiplier (riposte, buffs)
var take_mult := 1.0
var cooldowns: Dictionary = {}      # move id -> frames
var buf_kind := ""
var buf_age := 0
var prev := {}                      # previous-tick button levels for edge detection
var last_stand_used := false
var last_stand_active := false
var combo_hits := 0
var combo_timer := 0
var riposte_boost := false
var dodge_chain_left := 0
var alive := true
var burst := 0.0            # Pressure spent by the current move (scales damage)
var want_guard := false
var move_in := Vector2.ZERO
var idle_frames := 0
var guard_rise := false     # guard went up this tick

func ratio() -> float:
	return vit / max_vit

func has(s: String) -> bool:
	return st.get(s, 0) > 0

func add_status(s: String, frames: int) -> void:
	if frames > st.get(s, 0):
		st[s] = frames

func in_startup() -> bool:
	return move != null and af < move.startup

func is_attacking() -> bool:
	return move != null and stun == 0 and action in ["strike_light", "strike_heavy", "grab", "ability1", "ability2", "laststand"]

func invulnerable() -> bool:
	if iframes > 0:
		return true
	if move != null and move.iframes_count > 0 and af >= move.iframes_from and af < move.iframes_from + move.iframes_count:
		return true
	return false

func armor_now() -> float:
	if move != null and move.armor > 0.0 and af >= move.armor_from and af < move.armor_to:
		return move.armor
	return 0.0

func actionable() -> bool:
	return stun == 0 and (action == "idle" or action == "guard")

## Outgoing damage multiplier: temporary (riposte, buffs) times the critter's tuned damage_mult.
func out_mult() -> float:
	return dmg_mult * float(T["damage_mult"])
