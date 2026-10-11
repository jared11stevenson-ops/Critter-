class_name QaCheck
extends RefCounted
## Tiny assertion helpers for tests. Each helper appends a message to `fails` when the check does not hold.

static func is_true(fails: Array, cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)


static func eq(fails: Array, got, want, msg: String) -> void:
	if typeof(got) != typeof(want) or got != want:
		fails.append("%s: got %s, want %s" % [msg, str(got), str(want)])


static func near(fails: Array, got: float, want: float, msg: String, eps: float = 0.0001) -> void:
	if absf(got - want) > eps:
		fails.append("%s: got %f, want %f" % [msg, got, want])
