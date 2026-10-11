class_name StakesTier
extends RefCounted
## Stakes tiers (GDD 5.3). The int values are what CombatSim receives as `stakes`.
const SPARRING := 0
const CONTEST := 1
const BLOOD := 2

static func name_of(t: int) -> String:
	return ["Sparring", "Contest", "Blood Bout"][clampi(t, 0, 2)]

static func can_kill(t: int) -> bool:
	return t == BLOOD
