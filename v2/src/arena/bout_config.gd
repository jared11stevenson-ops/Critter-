class_name BoutConfig extends RefCounted
## Everything a BoutScene needs to start a bout. Plain data so menus, tests and the smoke script can all build one.
var a_id := "aruun"
var b_id := "cigarra"
var human_a := true               # fighter 0 is driven by the player's InputProvider
var human_b := false
var profile_a := "standard"       # AI profile when fighter 0 is not human (novice | standard | expert)
var profile_b := "standard"
var arena_id := "ring"
var training := false             # Training: stakes 0, nobody dies, nothing counts (GDD 14.8 applies to real bouts only)
var seed_value := 1
var intro := true                 # camera sweep + READY/FIGHT before the first tick
var layout := "A"                 # touch layout A (buttons) or B (gestures)
var a_vit := 1.0                  # starting Vitality ratio (career: carried over between bouts)
var b_vit := 1.0
var a_name := ""                  # display names (career individuals); "" = species name
var b_name := ""
var stakes_override := -1         # -1 = default (training 0, otherwise Blood 2)
var mods: Array = []              # rule modifiers for this bout (CombatSim.apply_modifiers): sudden_death | endurance | hazard | ringout | gauntlet | fog
var timeout_ticks := 0            # 0 = rules default; the smoke test lowers it

func stakes() -> int:
	if stakes_override >= 0:
		return stakes_override
	return 0 if training else 2   # 2 = Blood Bout: every real fight risks permanent death (CREATOR_GDD section 1, 14.8)

func describe() -> String:
	return "%s%s vs %s%s on %s%s" % [a_id, "" if human_a else "(" + profile_a + ")", b_id, "" if human_b else "(" + profile_b + ")", arena_id, " [training]" if training else ""]

## Display names and one-line rules for the modifiers (shown on the tournament panel and as a chip in the bout).
const RULES := {
	"sudden_death": ["SUDDEN DEATH", "Both fighters start at half Vitality."],
	"endurance": ["ENDURANCE", "More Vitality and Stamina, and a longer clock."],
	"hazard": ["HAZARD RING", "A damaging zone burns the centre of the ring."],
	"ringout": ["RING-OUT", "Knockback is stronger: the edge is deadly."],
	"gauntlet": ["GAUNTLET", "Dangerous ground sweeps the ring."],
	"fog": ["FOG", "You cannot see the far side of the ring."],
}

static func rule_name(m: String) -> String:
	return str((RULES.get(m, [m.to_upper(), ""]) as Array)[0])

static func rule_line(m: String) -> String:
	return str((RULES.get(m, [m.to_upper(), ""]) as Array)[1])

func rule_chip() -> String:
	var parts: Array = []
	for m in mods:
		parts.append(rule_name(str(m)))
	return "RULE: " + " + ".join(parts) if not parts.is_empty() else ""
