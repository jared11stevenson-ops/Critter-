extends RefCounted
## ART GATE: VFX registry. Every one of the 21 main abilities + 7 Last Stands (+ nyxaris permission) has its own recipe (distinct layer signature),
## recipes stay within the draw budget, every critter has its own hit / block / parry / dodge flavor, status visuals exist for the sim's statuses,
## and the stage never exceeds its draw cap (15 / 12 / 8 by quality).
const Stage := preload("res://src/critters/vfx/vfx_stage.gd")
const Rec := preload("res://src/critters/vfx/vfx_recipes.gd")
const Pal := preload("res://src/critters/palettes.gd")
const ABILITIES := {
	"aruun": ["reaching_strike", "gravity_pull", "beetle_rage", "carry_the_bridge"],
	"cigarra": ["premonition", "false_memory", "puppet_thought", "future_touched"],
	"bramvex": ["ghost", "ground_prep", "detain", "day_20"],
	"scarlith": ["ferment", "decompose", "cultivate", "aged_to_perfection"],
	"mollusk": ["inertia_field", "borrowed_seconds", "lift", "everything_arrives"],
	"zephyr": ["gust", "pollen", "promise", "a_promise_kept"],
	"nyxaris": ["boundary", "venom_fang", "cocoon", "cold_archive"]}
const STATUSES := ["camo", "premonition", "touched", "borrowed", "permission", "root", "slow", "poison", "rot", "marked", "stun", "strain"]

func run() -> Array:
	var fails: Array = []
	var sigs := {}
	for c in ABILITIES:
		var ctx := {"pal": Pal.get_pal(c), "facing": 1.0, "reach": 5.0, "radius": 3.0, "dur": 1.2}
		for ab in ABILITIES[c]:
			var rec: Dictionary = Rec.build(ab, ctx)
			if rec.is_empty():
				fails.append("%s/%s: no VFX recipe" % [c, ab])
				continue
			var sig := ""
			var persist_draws := 0
			for ph in ["tell", "go", "end"]:
				var ls: Array = rec.get(ph, [])
				if ls.size() > 5:
					fails.append("%s/%s: phase %s has %d layers (> 5)" % [c, ab, ph, ls.size()])
				for L in ls:
					sig += "%d%s" % [L["k"], L["pl"]]
					if int(L["k"]) < 0 or int(L["k"]) > 25:
						fails.append("%s/%s: bad shader kind %d" % [c, ab, L["k"]])
					if L.get("persist", false):
						persist_draws += 1
			if persist_draws > 3:
				fails.append("%s/%s: %d persistent layers (> 3 draws)" % [c, ab, persist_draws])
			if sigs.has(sig):
				fails.append("%s/%s: VFX identical to %s" % [c, ab, sigs[sig]])
			sigs[sig] = "%s/%s" % [c, ab]
		for t in ["hit", "block", "parry", "dodge", "ko", "teleport", "summon"]:
			if Rec.event_fx(t, c, ctx).is_empty():
				fails.append("%s: no %s VFX" % [c, t])
		if Rec.projectile_fx(c, ctx).is_empty():
			fails.append("%s: no projectile VFX" % c)
	var hits := {}
	for c in ABILITIES:
		var ctx2 := {"pal": Pal.get_pal(c), "facing": 1.0, "heavy": false}
		var s := ""
		for L in Rec.event_fx("hit", c, ctx2):
			s += "%d%s" % [L["k"], L["pl"]]
		if hits.has(s):
			fails.append("hit spark of %s identical in shape to %s" % [c, hits[s]])
		hits[s] = c
	for st in STATUSES:
		if Rec.status_fx(st, "aruun", {"pal": Pal.get_pal("aruun")}).is_empty():
			fails.append("no status VFX for '%s'" % st)
	# budget: spam everything, the stage must hold its cap
	for q in [0, 1, 2]:
		var stage = Stage.new()
		stage.quality = q
		stage.manual_tick = true
		for c in ABILITIES:
			var ctx3 := {"pal": Pal.get_pal(c), "facing": 1.0, "reach": 5.0, "radius": 3.0, "dur": 1.2}
			for ab in ABILITIES[c]:
				var rec2: Dictionary = Rec.build(ab, ctx3)
				stage._make(rec2.get("go", []) + rec2.get("tell", []), Vector3.ZERO, 1.0)
				if stage.draws_alive() > stage.max_draws():
					fails.append("quality %d: %d draws alive > cap %d" % [q, stage.draws_alive(), stage.max_draws()])
		stage.free()
	return fails
