class_name BoutOutcome
extends RefCounted
## What the roster needs to know about one finished bout, for ONE of the two critters.
## outcome: "win" | "loss" (survived, lost) | "yield" (player yielded, survives) | "killed".

var uid := ""
var stakes := StakesTier.SPARRING
var outcome := "win"
var opponent_species := ""
var final_vitality := 1.0     # ratio at the end of the bout
var min_vitality := 1.0       # lowest ratio reached during the bout (near-death check)
var moment := ""              # optional memorable moment text ("Perfect parry on the last tick")
var cause := ""               # for killed: what killed it ("Kragg's Pincer Chain")


static func make(p_uid: String, p_stakes: int, p_outcome: String, p_opponent: String, p_final := 1.0, p_min := 1.0) -> BoutOutcome:
	var o := BoutOutcome.new()
	o.uid = p_uid
	o.stakes = p_stakes
	o.outcome = p_outcome
	o.opponent_species = p_opponent
	o.final_vitality = p_final
	o.min_vitality = minf(p_min, p_final)
	return o


## Builds the outcome for fighter `my_index` from CombatSim.result() ({winner, reason, killed}).
## `killed` in the sim result means the LOSER died. winner -1 (timeout draw) counts as a survived loss.
static func from_sim_result(result: Dictionary, my_index: int, p_uid: String, p_stakes: int, p_opponent: String, p_final: float, p_min: float) -> BoutOutcome:
	var winner := int(result.get("winner", -1))
	var oc := "loss"
	if winner == my_index:
		oc = "win"
	elif bool(result.get("killed", false)) and winner >= 0:
		oc = "killed"
	elif str(result.get("reason", "")) == "yield" and winner >= 0:
		oc = "yield"
	return make(p_uid, p_stakes, oc, p_opponent, p_final, p_min)
