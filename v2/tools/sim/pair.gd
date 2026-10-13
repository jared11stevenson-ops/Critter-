extends SceneTree
## CLI: godot --headless --path v2 -s res://tools/sim/pair.gd -- aruun pharilux [bouts per profile=40] [seed=1]
## Prints the win rate of A vs B (both seats, novice/standard/expert), ring-out / timeout rates and average length.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var a: String = args[0]
	var b: String = args[1]
	var n := int(args[2]) if args.size() > 2 else 40
	var base := int(args[3]) if args.size() > 3 else 1
	var tot := {"w": 0.0, "n": 0, "ro": 0, "to": 0, "ticks": 0}
	var per := {}
	for prof in ["novice", "standard", "expert"]:
		var w := 0.0
		for i in n:
			var seat_a_first := i % 2 == 0
			var s := base * 1000 + i
			var r: Dictionary = Tournament.run_bout(a if seat_a_first else b, b if seat_a_first else a, prof, prof, s)
			var win_idx: int = int(r["winner"])
			var a_idx := 0 if seat_a_first else 1
			if win_idx == a_idx:
				w += 1.0
			elif win_idx < 0:
				w += 0.5
			tot["n"] += 1
			tot["ticks"] += int(r.get("ticks", 0))
			if str(r.get("reason", "")) == "ringout":
				tot["ro"] += 1
			if str(r.get("reason", "")) in ["timeout", ""]:
				tot["to"] += 1
		per[prof] = w / float(n)
		tot["w"] += w
	print("PAIR %s vs %s: %.1f%%  (novice %.0f%% standard %.0f%% expert %.0f%%)  ringout %.0f%%  timeout %.0f%%  avg %.0fs" % [a, b, 100.0 * tot["w"] / float(tot["n"]), 100.0 * per["novice"], 100.0 * per["standard"], 100.0 * per["expert"], 100.0 * tot["ro"] / float(tot["n"]), 100.0 * tot["to"] / float(tot["n"]), float(tot["ticks"]) / float(tot["n"]) / 60.0])
	quit()
