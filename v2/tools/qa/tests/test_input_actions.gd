extends RefCounted

const InputActions := preload("res://src/core/input_actions.gd")

func run() -> Array:
	var fails: Array = []
	InputActions.register()
	InputActions.register()  # idempotent
	for a: String in InputActions.ACTIONS:
		QaCheck.is_true(fails, InputMap.has_action(a), "action registered: " + a)
		var evs := InputMap.action_get_events(a)
		var has_key := false
		var has_pad := false
		for e in evs:
			has_key = has_key or e is InputEventKey
			has_pad = has_pad or e is InputEventJoypadButton or e is InputEventJoypadMotion
		QaCheck.is_true(fails, has_key, a + " has keyboard binding")
		QaCheck.is_true(fails, has_pad, a + " has gamepad binding")
	QaCheck.eq(fails, InputMap.action_get_events("strike").size(), 2, "no duplicate events after re-register")
	return fails
