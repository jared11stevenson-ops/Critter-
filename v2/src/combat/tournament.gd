class_name Tournament extends RefCounted
## Bot tournament: every ordered matchup of the roster, N bouts, three AI skill profiles.
## Produces the win-rate matrix used as the balance gate (GDD 5.5).
const MAX_TICKS_GUARD := 20000

## Plays one AI-vs-AI bout. Returns the sim result plus per-fighter stats.
static func run_bout(a_id: String, b_id: String, profile_a: String, profile_b: String, seed_value: int, arena_id: String = "ring", stakes: int = 1) -> Dictionary:
	var sim := CombatSim.new(CombatData.critter(a_id), CombatData.critter(b_id), CombatData.arena(arena_id), stakes, seed_value)
	var ai_a := CombatAI.new(0, profile_a, seed_value * 2 + 1, false)
	var ai_b := CombatAI.new(1, profile_b, seed_value * 2 + 2, false)
	var abilities := [0, 0]
	var guard_rate := 0
	while not sim.is_over() and sim.tick < MAX_TICKS_GUARD:
		sim.step(ai_a.decide(sim), ai_b.decide(sim))
		for e in sim.take_events():
			if e["type"] == "tell":
				var mv: MoveDef = sim.fighters[e["fighter"]].def.move(e["move_id"])
				if mv != null and (mv.kind == "ability" or mv.kind == "laststand"):
					abilities[e["fighter"]] += 1
	var r: Dictionary = sim.result().duplicate()
	r["abilities"] = abilities
	return r

static func _empty_cell() -> Dictionary:
	return {"w": 0.0, "n": 0, "ticks": 0, "ko": 0, "ringout": 0, "timeout": 0, "dmg": 0.0, "ls": 0, "abil": 0}

## Runs the shard `shard_index` of `shard_count` (ordered matchups are dealt round robin). Returns raw counts:
## {"cells": {"a>b": {profile: cell}}, "bouts": n}
static func run_shard(n_per_matchup: int, base_seed: int, shard_index: int, shard_count: int, arena_id: String = "ring", stakes: int = 1, only_profiles: Array = []) -> Dictionary:
	var ids: Array = CombatData.critter_ids()
	var profiles: Array = only_profiles if not only_profiles.is_empty() else CombatAI.profile_names()
	var per_profile := maxi(1, int(ceil(float(n_per_matchup) / float(profiles.size()))))
	var cells := {}
	var pair_i := 0
	var bouts := 0
	for a in ids:
		for b in ids:
			pair_i += 1
			if (pair_i - 1) % shard_count != shard_index:
				continue
			var key: String = a + ">" + b
			cells[key] = {}
			for p in profiles:
				var c := _empty_cell()
				for k in per_profile:
					var s: int = base_seed + (hash(key + p) & 0xFFFFFF) + k * 7919
					var r := run_bout(a, b, p, p, s, arena_id, stakes)
					bouts += 1
					c["n"] += 1
					c["ticks"] += int(r["ticks"])
					var w := int(r["winner"])
					c["w"] += 1.0 if w == 0 else (0.5 if w < 0 else 0.0)
					c[r["reason"]] = c.get(r["reason"], 0) + 1
					c["dmg"] += float(r["damage_dealt"][0])
					c["ls"] += 1 if r["last_stand_used"][0] else 0
					c["abil"] += int(r["abilities"][0])
				cells[key][p] = c
	return {"cells": cells, "bouts": bouts}

static func merge(parts: Array) -> Dictionary:
	var cells := {}
	var bouts := 0
	for part in parts:
		bouts += int(part["bouts"])
		for k in part["cells"].keys():
			cells[k] = part["cells"][k]
	return {"cells": cells, "bouts": bouts}

## Win rate of `a` against `b` (both seating orders, all profiles), optionally one profile.
static func rate(cells: Dictionary, a: String, b: String, profile: String = "") -> float:
	var w := 0.0
	var n := 0.0
	for p in CombatAI.profile_names():
		if profile != "" and p != profile:
			continue
		var c1: Dictionary = cells.get(a + ">" + b, {}).get(p, {})
		var c2: Dictionary = cells.get(b + ">" + a, {}).get(p, {})
		if c1.has("n"):
			w += c1["w"]
			n += c1["n"]
		if c2.has("n") and a != b:
			w += float(c2["n"]) - float(c2["w"])
			n += c2["n"]
	return w / n if n > 0.0 else 0.5

static func overall(cells: Dictionary, a: String, profile: String = "") -> float:
	var s := 0.0
	var k := 0
	for b in CombatData.critter_ids():
		if b == a:
			continue
		s += rate(cells, a, b, profile)
		k += 1
	return s / float(k)

static func to_markdown(data: Dictionary, base_seed: int, n: int) -> String:
	var cells: Dictionary = data["cells"]
	var ids: Array = CombatData.critter_ids()
	var out := PackedStringArray()
	out.append("# CRITTER v2 balance matrix")
	out.append("")
	out.append("Bouts: %d (about %d per ordered matchup, split over profiles novice/standard/expert, both seats), seed base %d, stakes 1, arena ring." % [int(data["bouts"]), n, base_seed])
	out.append("Cell = win rate of ROW critter against COLUMN critter. Targets: overall 45-55%, no matchup beyond 40/60.")
	out.append("")
	var head := "| row \\ col |"
	var sep := "|---|"
	for b in ids:
		head += " %s |" % b
		sep += "---|"
	head += " **overall** |"
	sep += "---|"
	out.append(head)
	out.append(sep)
	var worst := 0.0
	var bad_matchups: Array = []
	for a in ids:
		var row := "| **%s** |" % a
		for b in ids:
			if a == b:
				row += " - |"
				continue
			var r := rate(cells, a, b)
			var flag := ""
			if r < 0.40 or r > 0.60:
				flag = " !"
				if r < 0.40:
					bad_matchups.append("%s vs %s = %d%%" % [a, b, roundi(r * 100.0)])
			row += " %d%%%s |" % [roundi(r * 100.0), flag]
		var ov := overall(cells, a)
		row += " **%.1f%%**%s |" % [ov * 100.0, "" if ov >= 0.45 and ov <= 0.55 else " !"]
		out.append(row)
	out.append("")
	out.append("## Overall by AI profile")
	out.append("")
	out.append("| critter | novice | standard | expert |")
	out.append("|---|---|---|---|")
	for a in ids:
		out.append("| %s | %.1f%% | %.1f%% | %.1f%% |" % [a, overall(cells, a, "novice") * 100.0, overall(cells, a, "standard") * 100.0, overall(cells, a, "expert") * 100.0])
	out.append("")
	out.append("## Bout stats (row critter seated first)")
	out.append("")
	out.append("| critter | avg seconds | KO % | ring-out % | timeout % | ability uses/bout | Last Stand % |")
	out.append("|---|---|---|---|---|---|---|")
	for a in ids:
		var n_b := 0.0
		var t := 0.0
		var ko := 0.0
		var ro := 0.0
		var to := 0.0
		var ab := 0.0
		var ls := 0.0
		for b in ids:
			for p in cells.get(a + ">" + b, {}).keys():
				var c: Dictionary = cells[a + ">" + b][p]
				n_b += c["n"]
				t += c["ticks"]
				ko += c.get("ko", 0)
				ro += c.get("ringout", 0)
				to += c.get("timeout", 0)
				ab += c["abil"]
				ls += c["ls"]
		if n_b > 0.0:
			out.append("| %s | %.0f | %.0f | %.0f | %.0f | %.1f | %.0f |" % [a, t / n_b / 60.0, ko / n_b * 100.0, ro / n_b * 100.0, to / n_b * 100.0, ab / n_b, ls / n_b * 100.0])
	out.append("")
	var seat := 0.0
	var seat_n := 0.0
	for k in cells.keys():
		for p in cells[k].keys():
			seat += cells[k][p]["w"]
			seat_n += cells[k][p]["n"]
	out.append("Seat bias: first seat wins %.1f%% of bouts." % [(seat / seat_n * 100.0) if seat_n > 0.0 else 50.0])
	out.append("")
	out.append("Matchups beyond 40/60: %s" % (", ".join(bad_matchups) if not bad_matchups.is_empty() else "none"))
	return "\n".join(out) + "\n"
