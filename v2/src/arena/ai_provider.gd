class_name AIProvider extends InputProvider
## Opponent driver: wraps the Combat Engineer's CombatAI (profiles novice / standard / expert).
var ai: CombatAI

func _init(idx: int, profile: String, seed_value: int, allow_yield := true) -> void:
	ai = CombatAI.new(idx, profile if profile in CombatAI.profile_names() else "standard", seed_value, allow_yield)

func tick(sim: CombatSim, _idx: int) -> CombatInput:
	return ai.decide(sim)
