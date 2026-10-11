extends RefCounted
## Every script under src/core must compile (catches parse errors in files no other test touches, e.g. UI views).

func _scan(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(d), out)


func run() -> Array:
	var fails: Array = []
	var files: Array = []
	_scan("res://src/core", files)
	QaCheck.is_true(fails, files.size() >= 20, "found core scripts (%d)" % files.size())
	for p: String in files:
		var s = load(p)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			fails.append("does not compile: " + p)
	for p in ["res://data/story/chapter_rules.json", "res://data/story/rewards.json"]:
		var j := JSON.new()
		QaCheck.is_true(fails, j.parse(FileAccess.get_file_as_string(p)) == OK, "valid json: " + p)
	return fails
