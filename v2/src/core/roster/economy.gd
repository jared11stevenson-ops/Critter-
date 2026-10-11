class_name Economy
extends RefCounted
## Currencies (GDD 8): Scrap (bouts; jar upgrades), Amber (rare, Blood Bouts; tier-ups), Reputation (unlocks).
## Reward table is data: res://data/story/rewards.json.

const KINDS := ["scrap", "amber", "reputation"]

var scrap := 0
var amber := 0
var reputation := 0
var _table: Dictionary = {}


func _init(table: Dictionary = {}) -> void:
	_table = table.get("rewards", {})


static func load_default() -> Economy:
	return Economy.new(StoryRules.read_json(StoryRules.REWARDS_PATH))


func get_amount(kind: String) -> int:
	match kind:
		"scrap": return scrap
		"amber": return amber
		"reputation": return reputation
	return 0


func add(kind: String, n: int) -> bool:
	if n < 0 or not KINDS.has(kind):
		return false
	set(kind, get_amount(kind) + n)
	return true


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if not KINDS.has(k) or get_amount(k) < int(cost[k]):
			return false
	return true


## Spends atomically (all or nothing). Reputation is a gate, not a cost, so it is never spent by this call.
func spend(cost: Dictionary) -> bool:
	if cost.has("reputation") or not can_afford(cost):
		return false
	for k in cost:
		set(k, get_amount(k) - int(cost[k]))
	return true


## Reward for a bout. outcome: "win" | "loss" | "yield" | "killed". Returns {} when nothing is earned.
func reward_for(stakes: int, outcome: String) -> Dictionary:
	if outcome == "killed":
		return {}
	var tier: Dictionary = _table.get(str(stakes), {})
	var out := {}
	for k in tier.get(outcome, {}):
		out[k] = int(tier[outcome][k])    # JSON numbers are floats
	return out


func grant(reward: Dictionary) -> void:
	for k in reward:
		add(k, int(reward[k]))


func to_dict() -> Dictionary:
	return {"scrap": scrap, "amber": amber, "reputation": reputation}


func load_dict(d: Dictionary) -> void:
	scrap = maxi(0, int(d.get("scrap", 0)))
	amber = maxi(0, int(d.get("amber", 0)))
	reputation = maxi(0, int(d.get("reputation", 0)))
