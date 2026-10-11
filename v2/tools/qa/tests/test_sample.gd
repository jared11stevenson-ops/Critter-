extends RefCounted
## Sample test: copy this file to start a new one.

func run() -> Array:
	var fails: Array = []
	QaCheck.eq(fails, 1 + 1, 2, "arithmetic")
	QaCheck.is_true(fails, "critter".begins_with("cr"), "string prefix")
	QaCheck.near(fails, 0.1 + 0.2, 0.3, "float")
	return fails
