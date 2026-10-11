extends SceneTree
## CLI: godot --headless --path v2 -s res://tools/sim/tournament.gd -- 200 [seed] [shard=K/N] [merge]
## N = bouts per ordered matchup (split over novice/standard/expert). Writes v2/tools/out/matrix.md.
const OUT_DIR := "res://tools/out/"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := 200
	var base_seed := 1
	var shard_i := 0
	var shard_n := 1
	var merge_only := false
	var arena_id := "ring"
	var positional := 0
	for a in args:
		if a.begins_with("shard="):
			var parts := a.substr(6).split("/")
			shard_i = int(parts[0])
			shard_n = int(parts[1])
		elif a == "merge":
			merge_only = true
		elif a.begins_with("arena="):
			arena_id = a.substr(6)
		elif a.is_valid_int():
			if positional == 0:
				n = int(a)
			else:
				base_seed = int(a)
			positional += 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if merge_only:
		var parts: Array = []
		for f in DirAccess.get_files_at(OUT_DIR):
			if f.begins_with("part_") and f.ends_with(".json"):
				parts.append(JSON.parse_string(FileAccess.get_file_as_string(OUT_DIR + f)))
		_write(Tournament.merge(parts), base_seed, n)
		quit()
		return
	var t0 := Time.get_ticks_msec()
	var data := Tournament.run_shard(n, base_seed, shard_i, shard_n, arena_id)
	print("tournament shard %d/%d: %d bouts in %.1fs" % [shard_i, shard_n, int(data["bouts"]), (Time.get_ticks_msec() - t0) / 1000.0])
	if shard_n > 1:
		var f := FileAccess.open(OUT_DIR + "part_%d.json" % shard_i, FileAccess.WRITE)
		f.store_string(JSON.stringify(data))
		f.close()
	else:
		_write(data, base_seed, n)
	quit()

func _write(data: Dictionary, base_seed: int, n: int) -> void:
	var md := Tournament.to_markdown(data, base_seed, n)
	var f := FileAccess.open(OUT_DIR + "matrix.md", FileAccess.WRITE)
	f.store_string(md)
	f.close()
	var raw := FileAccess.open(OUT_DIR + "matrix_raw.json", FileAccess.WRITE)
	raw.store_string(JSON.stringify(data))
	raw.close()
	print(md)
