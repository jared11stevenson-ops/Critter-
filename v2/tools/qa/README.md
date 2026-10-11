# CRITTER v2 QA tooling

## Run the tests
```
godot --headless --path v2 --import          # once (and after adding any class_name): builds the global class cache
godot --headless --path v2 -s res://tools/qa/run_tests.gd
godot --headless --path v2 -s res://tools/qa/run_tests.gd -- roster   # only files whose path contains "roster"
```
Exit code is 0 only when every test file passes (2 if none were found).

## Convention (everyone relies on this)
- Put tests in `v2/tools/qa/tests/test_<topic>.gd` (subfolders are fine). You own your own test files.
- Each file is `extends RefCounted` and has `func run() -> Array` returning failure strings. Empty array = pass.
- No autoloads or scene tree are guaranteed: test pure logic (`RefCounted`) and instantiate nodes yourself if needed.
- Tests must not touch `user://` real saves; pass temp paths such as `user://test_tmp/...` and delete them afterwards.
- A runtime script error inside `run()` aborts it and is reported as a failure.
- Helpers: `QaCheck.eq(fails, got, want, msg)`, `QaCheck.is_true(fails, cond, msg)`, `QaCheck.near(fails, got, want, msg)`.

```gdscript
extends RefCounted
func run() -> Array:
	var fails: Array = []
	QaCheck.eq(fails, 1 + 1, 2, "arithmetic")
	return fails
```

## Other tools
- `v2/tools/smoke.sh [seconds]` boots the main scene headless and fails on any SCRIPT ERROR.
- `tools/lint_filesize.sh` (repo root): soft 400 / hard 700 lines for `v2/**/*.gd`.
- `tools/check_ownership.sh [--agent NAME] [base]`: fails if a branch edits folders it does not own.
