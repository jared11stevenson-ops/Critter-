extends SceneTree
## Runs v2/tools/qa/tests/test_art_*.gd (each: extends RefCounted, func run() -> Array of failure strings).
##   godot --path v2 --script res://src/critters/tools/run_art_tests.gd            (headless ok; the silhouette gate skips w/o a renderer)
##   xvfb-run -a godot --path v2 --rendering-driver opengl3 --script res://src/critters/tools/run_art_tests.gd   (full, with renderer)
func _initialize() -> void:
	await process_frame
	await process_frame
	var dir := DirAccess.open("res://tools/qa/tests")
	var total := 0
	var names: Array = []
	for f in dir.get_files():
		if f.begins_with("test_art_") and f.ends_with(".gd"):
			names.append(f)
	names.sort()
	for f in names:
		var scr = load("res://tools/qa/tests/" + f)
		if scr == null:
			print("[FAIL] %s did not load" % f)
			total += 1
			continue
		var t = scr.new()
		var fails: Array = t.run()
		print("[%s] %s" % ["PASS" if fails.is_empty() else "FAIL", f])
		for x in fails:
			print("    - ", x)
		total += fails.size()
		if "report" in t:
			for r in t.report:
				print("    ", r)
	print("ART TESTS: %d failure(s)" % total)
	quit(1 if total > 0 else 0)
