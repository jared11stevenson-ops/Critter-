extends SceneTree
## CRITTER v2 test runner.
##   godot --headless --path v2 -s res://tools/qa/run_tests.gd [-- filter_substring]
## Discovers res://tools/qa/tests/**/test_*.gd. Each file is `extends RefCounted` with `func run() -> Array`
## returning failure strings (empty = pass). Exit code 0 only if every file passes. See tools/qa/README.md.

const TEST_DIR := "res://tools/qa/tests"


func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files := discover(TEST_DIR)
	var failed_files := 0
	var total_failures := 0
	var ran := 0
	var t0 := Time.get_ticks_msec()
	for path in files:
		if filter != "" and path.find(filter) < 0:
			continue
		ran += 1
		var fails := run_file(path)
		var short := path.trim_prefix(TEST_DIR + "/")
		if fails.is_empty():
			print("PASS  ", short)
		else:
			failed_files += 1
			total_failures += fails.size()
			print("FAIL  ", short)
			for f in fails:
				print("      - ", f)
	print("---- %d test files, %d passed, %d failed (%d failures) in %d ms" % [
		ran, ran - failed_files, failed_files, total_failures, Time.get_ticks_msec() - t0])
	if ran == 0:
		print("ERROR: no tests found")
		quit(2)
		return
	quit(1 if failed_files > 0 else 0)


## Returns sorted paths of every test_*.gd under `dir` (recursive).
static func discover(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	var names := Array(d.get_files())
	names.sort()
	for n: String in names:
		if n.begins_with("test_") and n.ends_with(".gd"):
			out.append(dir.path_join(n))
	var subs := Array(d.get_directories())
	subs.sort()
	for s: String in subs:
		out.append_array(discover(dir.path_join(s)))
	return out


## Loads and runs one test file; any load problem or non-Array result is reported as a failure.
static func run_file(path: String) -> Array:
	var scr = load(path)
	if scr == null or not (scr is GDScript) or not scr.can_instantiate():
		return ["could not load/compile " + path]
	var inst = scr.new()
	if not inst.has_method("run"):
		return ["no run() method"]
	var res = inst.run()
	if not (res is Array):
		return ["run() did not return an Array (script error inside run()? see log above)"]
	var out: Array = []
	for r in res:
		out.append(str(r))
	return out
