class_name StakesTier
extends RefCounted
## Stakes tiers. Player-facing there are only TWO fights: Blood Bout (BLOOD, lethal) and Practice (SPARRING, nobody dies). CONTEST is legacy (old saves/tests) and unreachable from the UI.
const SPARRING := 0
const CONTEST := 1
const BLOOD := 2

static func name_of(t: int) -> String:
	return ["Sparring", "Contest", "Blood Bout"][clampi(t, 0, 2)]

static func can_kill(t: int) -> bool:
	return t == BLOOD
