extends SceneTree
## CLI: godot --headless --path v2 -s res://tools/sim/spacing.gd -- [bouts_per_pair] [seed]
## Measures how bouts are spaced: share of time clinched (gap < 2.4), in breathing room (2.4-5), and far (> 5), plus mean gap,
## number of separate engagements and the longest uninterrupted clinch (seconds). Standard AI both sides.
func _init() -> void:
	var n := 3
	var seed_base := 11
	var pos := 0
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			if pos == 0:
				n = int(a)
			else:
				seed_base = int(a)
			pos += 1
	var ids: Array = CombatData.critter_ids()
	var tot := {"ticks": 0, "clinch": 0, "room": 0, "far": 0, "gap": 0.0, "engage": 0, "longest": 0, "bouts": 0, "sec": 0.0}
	var per := {}
	for a in ids:
		per[a] = {"ticks": 0, "clinch": 0, "gap": 0.0}
		for b in ids:
			for k in n:
				var s := seed_base + k * 101 + hash(a + b) % 997
				var sim := CombatSim.new(CombatData.critter(a), CombatData.critter(b), CombatData.arena("ring"), -1, s)
				var ai_a := CombatAI.new(0, "standard", s * 2 + 1, false)
				var ai_b := CombatAI.new(1, "standard", s * 2 + 2, false)
				var run := 0
				var was := false
				while not sim.is_over() and sim.tick < 7200:
					sim.step(ai_a.decide(sim), ai_b.decide(sim))
					sim.take_events()
					var g: float = sim.fighters[0].pos.distance_to(sim.fighters[1].pos)
					tot["ticks"] += 1
					tot["gap"] += g
					per[a]["ticks"] += 1
					per[a]["gap"] += g
					var clinched := g < 2.4
					if clinched:
						tot["clinch"] += 1
						per[a]["clinch"] += 1
						run += 1
						tot["longest"] = maxi(int(tot["longest"]), run)
						if not was:
							tot["engage"] += 1
					else:
						run = 0
					was = clinched
					if g >= 5.0:
						tot["far"] += 1
					elif not clinched:
						tot["room"] += 1
				tot["bouts"] += 1
				tot["sec"] += float(sim.tick) / 60.0
	var t: float = float(tot["ticks"])
	print("SPACING bouts=%d avg_len=%.1fs mean_gap=%.2f clinch=%.0f%% room=%.0f%% far=%.0f%% engagements/bout=%.1f longest_clinch=%.1fs" % [
		tot["bouts"], tot["sec"] / tot["bouts"], tot["gap"] / t, 100.0 * tot["clinch"] / t, 100.0 * tot["room"] / t, 100.0 * tot["far"] / t,
		float(tot["engage"]) / tot["bouts"], float(tot["longest"]) / 60.0])
	for a in ids:
		print("  %s mean_gap=%.2f clinch=%.0f%%" % [a, per[a]["gap"] / per[a]["ticks"], 100.0 * per[a]["clinch"] / per[a]["ticks"]])
	quit()
