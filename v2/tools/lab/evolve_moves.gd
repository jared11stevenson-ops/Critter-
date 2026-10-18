extends SceneTree
## LAB (never shipped, never writes data/): evolutionary move design (production/FRINGE_LAB.md F6).
## Evolves ONE move's frame data in memory against a panel of opponents using the deterministic sim as the fitness function.
##   godot --headless --path v2 -s res://tools/lab/evolve_moves.gd -- --critter=bramvex --move=bramvex_diplomacy1 --gens=6 --pop=8 --seed=1
## Genes are multipliers (0.75..1.30) on startup, active, recovery, damage, stamina cost, reach, hitstun. A POWER BUDGET stops it from just buffing:
## power = damage * reach / total frames must stay within +5% of the original, so evolution can only TRADE (faster but weaker, longer reach but slower...).
## Fitness = closeness to a 50% win rate + close fights + no stalling + sane bout length. Output: v2/tools/out/lab/evolve_<critter>_<move>.md.

const GENES := ["startup", "active", "recovery", "damage", "stamina_cost", "reach", "hitstun"]
const LO := 0.75
const HI := 1.30
const BUDGET := 1.05

var cid := "bramvex"
var mid := "bramvex_diplomacy1"
var gens := 6
var pop := 8
var seed_value := 1
var panel: Array = []
var base_raw: Dictionary = {}
var rng := RandomNumberGenerator.new()
var log_lines: Array = []

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var p: PackedStringArray = a.trim_prefix("--").split("=")
		if p.size() == 2:
			match p[0]:
				"critter": cid = p[1]
				"move": mid = p[1]
				"gens": gens = int(p[1])
				"pop": pop = int(p[1])
				"seed": seed_value = int(p[1])
	rng.seed = seed_value
	for id in CombatData.critter_ids():
		if id != cid:
			panel.append(id)
	base_raw = (CombatData.read_json("res://data/moves/%s.json" % cid)["moves"][mid] as Dictionary).duplicate(true)
	var parent := _ones()
	var best_fit := -1e9
	var best := parent
	var sigma := 0.10
	for g in gens:
		var cands: Array = [parent]
		for k in pop - 1:
			cands.append(_mutate(parent, sigma))
		var seeds := _seeds(seed_value * 1000 + g * 131, 2)
		var scored: Array = []
		for c in cands:
			var ev := _evaluate(c, seeds)
			scored.append([float(ev["fitness"]), c, ev])
		scored.sort_custom(func(x, y): return x[0] > y[0])
		# successive halving: the 3 best of the cheap pass are re-measured on fresh seeds with 3x the bouts (selection on noise was the failure of run 1)
		var seeds2 := _seeds(seed_value * 1000 + g * 131 + 555, 6)
		var finals: Array = []
		for k in mini(3, scored.size()):
			var ev2 := _evaluate(scored[k][1], seeds2)
			finals.append([float(ev2["fitness"]), scored[k][1], ev2])
		finals.sort_custom(func(x, y): return x[0] > y[0])
		scored = finals
		parent = scored[0][1]
		sigma = maxf(0.04, sigma * 0.9)
		if scored[0][0] > best_fit:
			best_fit = scored[0][0]
			best = parent
		_log("gen %d: best fitness %.3f  wr %.2f  closeness %.2f  stall %.2f  budget %.2f  genes %s" % [g, scored[0][0], scored[0][2]["wr"], scored[0][2]["close"], scored[0][2]["stall"], scored[0][2]["budget"], _fmt(scored[0][1])])
	# holdout: fresh seeds, original vs best
	var hold := _seeds(900000 + seed_value, 8)
	var e0 := _evaluate(_ones(), hold)
	var e1 := _evaluate(best, hold)
	_report(best, e0, e1)
	CombatData.reload()
	quit()

func _ones() -> Dictionary:
	var d := {}
	for k in GENES:
		d[k] = 1.0
	return d

func _mutate(p: Dictionary, sigma: float) -> Dictionary:
	var d := {}
	for k in GENES:
		d[k] = clampf(float(p[k]) * (1.0 + rng.randfn(0.0, sigma)), LO, HI)
	return d

func _fmt(g: Dictionary) -> String:
	var s: Array = []
	for k in GENES:
		s.append("%s x%.2f" % [k, g[k]])
	return ", ".join(s)

func _seeds(base: int, per_opp: int) -> Array:
	var out: Array = []
	for i in panel.size():
		for k in per_opp:
			out.append(base + i * 37 + k * 977)
	return out

func _raw_for(g: Dictionary) -> Dictionary:
	var r := base_raw.duplicate(true)
	var su := maxi(1, int(round(float(base_raw["startup"]) * g["startup"])))
	r["startup"] = su
	r["active"] = maxi(1, int(round(float(base_raw["active"]) * g["active"])))
	r["recovery"] = maxi(1, int(round(float(base_raw["recovery"]) * g["recovery"])))
	r["damage"] = float(base_raw["damage"]) * g["damage"]
	r["stamina_cost"] = float(base_raw.get("stamina_cost", 0.0)) * g["stamina_cost"]
	if base_raw.has("hitbox"):
		(r["hitbox"] as Dictionary)["reach"] = float(base_raw["hitbox"]["reach"]) * g["reach"]
	r["hitstun"] = maxi(1, int(round(float(base_raw.get("hitstun", 10)) * g["hitstun"])))
	if base_raw.has("cancel_from"):
		r["cancel_from"] = maxi(0, int(base_raw["cancel_from"]) + su - int(base_raw["startup"]))
	return r

func _power(r: Dictionary) -> float:
	var reach: float = float(r["hitbox"]["reach"]) if r.has("hitbox") else 1.0
	return float(r["damage"]) * reach / float(int(r["startup"]) + int(r["active"]) + int(r["recovery"]))

func _install(g: Dictionary) -> float:
	var r := _raw_for(g)
	CombatData.critter(cid).moves[mid] = MoveDef.from_dict(mid, r)
	return _power(r) / _power(base_raw)

func _evaluate(g: Dictionary, seeds: Array) -> Dictionary:
	var budget := _install(g)
	var wins := 0.0
	var n := 0
	var close := 0.0
	var stall := 0.0
	var ticks := 0.0
	for i in seeds.size():
		var opp: String = panel[i / (seeds.size() / panel.size())]
		for seat in 2:
			var a: String = cid if seat == 0 else opp
			var b: String = opp if seat == 0 else cid
			var r: Dictionary = Tournament.run_bout(a, b, "standard", "standard", int(seeds[i]) + seat * 5)
			var w := int(r["winner"])
			var mine := seat
			wins += 1.0 if w == mine else (0.5 if w < 0 else 0.0)
			var vr: Array = r["vitality_ratio"]
			close += 1.0 - absf(float(vr[0]) - float(vr[1]))
			stall += 1.0 if str(r["reason"]) == "timeout" else 0.0
			ticks += float(r["ticks"])
			n += 1
	var wr := wins / float(n)
	var avg_t := ticks / float(n)
	var len_pen := clampf(absf(avg_t - 3300.0) / 3000.0, 0.0, 1.0)         # target 40-70 s bouts (3300 ticks centre)
	var over := maxf(0.0, budget - BUDGET)
	var fit := -2.0 * absf(wr - 0.5) + 0.5 * (close / float(n)) - 1.0 * (stall / float(n)) - 0.3 * len_pen - 6.0 * over
	return {"fitness": fit, "wr": wr, "close": close / float(n), "stall": stall / float(n), "ticks": avg_t, "budget": budget, "bouts": n}

func _log(s: String) -> void:
	print(s)
	log_lines.append(s)

func _report(best: Dictionary, e0: Dictionary, e1: Dictionary) -> void:
	var r0 := _raw_for(_ones())
	var r1 := _raw_for(best)
	var md := "# Evolutionary move design: %s / %s (LAB, nothing here changes the game)\n\n" % [cid, mid]
	md += "Panel: %s. %d generations x population %d, standard AI, power budget +%d%%.\n\n" % [", ".join(panel), gens, pop, int(round((BUDGET - 1.0) * 100.0))]
	md += "| field | original | evolved |\n|---|---|---|\n"
	for k in ["startup", "active", "recovery", "damage", "stamina_cost", "hitstun"]:
		md += "| %s | %s | %s |\n" % [k, str(snappedf(float(r0[k]), 0.01)), str(snappedf(float(r1[k]), 0.01))]
	if r0.has("hitbox"):
		md += "| reach | %.2f | %.2f |\n" % [float(r0["hitbox"]["reach"]), float(r1["hitbox"]["reach"])]
	md += "\nHoldout (fresh seeds, %d bouts each):\n\n| | win rate | closeness | stall rate | avg ticks | power vs original |\n|---|---|---|---|---|---|\n" % int(e0["bouts"])
	md += "| original | %.1f%% | %.2f | %.1f%% | %d | 1.00 |\n" % [100.0 * float(e0["wr"]), float(e0["close"]), 100.0 * float(e0["stall"]), int(e0["ticks"])]
	md += "| evolved | %.1f%% | %.2f | %.1f%% | %d | %.2f |\n\n" % [100.0 * float(e1["wr"]), float(e1["close"]), 100.0 * float(e1["stall"]), int(e1["ticks"]), float(e1["budget"])]
	md += "Evolution log:\n\n```\n" + "\n".join(log_lines) + "\n```\n"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/out/lab"))
	var f := FileAccess.open("res://tools/out/lab/evolve_%s_%s_s%d.md" % [cid, mid, seed_value], FileAccess.WRITE)
	f.store_string(md)
	f.close()
	print(md)
