extends RefCounted
## Ability / event / status / zone VFX recipes. `build(id, ctx)` returns {phase: [layer dicts]} with phases:
##   tell (ability pressed / startup), go (active frame), end (recovery start), zone / status (persistent, driven by REAL sim state: radius + remaining ticks).
## ctx: {reach, radius, dur (seconds), pal (palette dict), facing, scale}. Sizes come from the real MoveDef hitbox / zone radius when the sim supplies them;
## the numbers below are only fallbacks. Layer keys: k (shader kind 0-25), pl (g ground | v vertical | m beam | b billboard), sz Vector2 meters, off Vector3 (+x = facing),
## t0, life (s), c1, c2 (colors), g0/g1 (scale over life), rot (deg/s), persist (loops until the sim says the effect ended), seed.
## Colors per critter: m main, a accent, g glow, b belly, s signature; w white; k ink.

static func L(k: int, pl: String, w: float, h: float, c1: Color, c2: Color, life: float = 0.5, t0: float = 0.0, off: Vector3 = Vector3.ZERO, extra: Dictionary = {}) -> Dictionary:
	var d := {"k": k, "pl": pl, "sz": Vector2(w, h), "c1": c1, "c2": c2, "life": life, "t0": t0, "off": off}
	d.merge(extra, true)
	return d

static func col(pal: Dictionary, key: String) -> Color:
	match key:
		"m": return pal["main"].lightened(0.15)
		"a": return pal["accent"]
		"g": return pal["glow"]
		"b": return pal["belly"]
		"s": return pal["sig"]
		"w": return Color(1.0, 0.97, 0.9)
		"k": return Color(0.1, 0.07, 0.12)
	return Color.html(key)

static func canon(move_id: String) -> String:
	# "aruun_reaching_strike" -> "reaching_strike"; "everything_arrives_at_once" -> "everything_arrives"
	var s := move_id
	for c in ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris"]:
		if s.begins_with(c + "_"):
			s = s.substr(c.length() + 1)
	if s.begins_with("a_future_touched"): s = "future_touched"
	if s.begins_with("everything_arrives"): s = "everything_arrives"
	if s.begins_with("a_promise_kept"): s = "a_promise_kept"
	return s

static func build(id: String, ctx: Dictionary) -> Dictionary:
	var P: Dictionary = ctx["pal"]
	var R: float = ctx.get("reach", 5.0)
	var Z: float = ctx.get("radius", 3.0)
	var D: float = ctx.get("dur", 1.2)
	var m := col(P, "m"); var a := col(P, "a"); var g := col(P, "g"); var b := col(P, "b"); var w := col(P, "w"); var k := col(P, "k")
	var red := Color.html("e8402a"); var hot := Color.html("ff8a3a")
	match canon(id):
		# ---------------------------------------------------------------- ARUUN
		"reaching_strike":    # Morrow extended through the psionic link: red link beam + shock cracks along the path
			return {"tell": [L(11, "g", 2.4, 2.4, red, w, 0.5, 0.0, Vector3(0.8, 0, 0))],
				"go": [L(21, "m", R, 1.5, red, w, 0.4, 0.0, Vector3(0.6, 1.3, 0)), L(2, "g", R, 3.4, hot, w, 0.9, 0.05, Vector3(R * 0.5, 0, 0))],
				"end": [L(0, "b", 3.2, 3.2, hot, w, 0.35, 0.0, Vector3(R, 1.0, 0)), L(12, "b", 4.0, 4.0, w, red, 0.3, 0.0, Vector3(R, 1.0, 0))]}
		"gravity_pull":       # Morrow floats ahead; inward vortex drags, then slams: crack burst
			return {"tell": [L(15, "g", Z * 0.8, Z * 0.8, red, w, 0.4, 0.0, Vector3(R * 0.5, 0, 0))],
				"go": [L(15, "g", Z * 2.0, Z * 2.0, red, hot, D, 0.0, Vector3(R * 0.5, 0, 0), {"persist": true}), L(20, "b", 1.6, 1.6, red, k, 0.9, 0.0, Vector3(R * 0.5, 1.6, 0))],
				"end": [L(2, "g", Z * 2.0, Z * 2.0, hot, w, 0.8, 0.0, Vector3(R * 0.5, 0, 0)), L(3, "g", Z * 2.2, Z * 2.2, red, w, 0.5, 0.0, Vector3(R * 0.5, 0, 0))]}
		"beetle_rage":        # overdrive: flame tongues up the body, steam, hot ground ring
			return {"tell": [L(3, "g", 4.0, 4.0, hot, w, 0.6)],
				"go": [L(18, "v", 3.0, 4.4, red, hot, 1.2, 0.0, Vector3(0, 0, 0.3), {"persist": true}), L(9, "v", 3.2, 4.0, Color(0.7, 0.68, 0.66), w, 1.4, 0.0, Vector3(0, 0, 0.4), {"persist": true}), L(2, "g", 3.6, 3.6, red, hot, 1.0)],
				"end": []}
		"carry_the_bridge":   # plant Morrow; a truss-arch bridge builds over him, then releases one huge blow
			return {"tell": [L(22, "v", 6.0, 4.2, a, w, 1.8, 0.0, Vector3(0, 0, -0.2)), L(2, "g", 3.0, 3.0, a, w, 1.6)],
				"go": [L(3, "g", R * 2.2, R * 2.2, hot, w, 0.6), L(12, "b", 6.0, 6.0, w, red, 0.4, 0.0, Vector3(1.5, 1.2, 0)), L(2, "g", R * 2.0, R * 2.0, hot, w, 1.0)],
				"end": []}
		# ---------------------------------------------------------------- CIGARRA
		"premonition":        # sigil under her, soft future threads; ghosts are spawned by the rig
			return {"tell": [L(11, "g", 3.4, 3.4, Color.html("7a6cff"), w, 0.6)],
				"go": [L(11, "g", Z * 1.4, Z * 1.4, Color.html("7a6cff"), Color.html("b9c8ff"), D, 0.0, Vector3.ZERO, {"persist": true}), L(10, "v", 3.2, 3.0, Color.html("9aa4ff"), w, D, 0.0, Vector3(1.0, 0, 0.2), {"persist": true})],
				"end": []}
		"false_memory":       # a believable mirage: doubled striped phantom + sparkle where the enemy "sees" it
			var at := Vector3(R * 0.6, 0, 0)
			return {"tell": [L(20, "b", 1.3, 1.3, Color.html("c06aff"), k, 0.5, 0.0, Vector3(0.6, 2.8, 0))],
				"go": [L(25, "b", 2.2, 1.2, Color.html("e9a0ff"), Color.html("6a3aa8"), 1.2, 0.0, at + Vector3(0, 2.2, 0)), L(9, "v", 3.0, 3.4, Color.html("c06aff"), w, 1.2, 0.0, at), L(13, "g", 3.0, 3.0, Color.html("c06aff"), Color.html("4a2a80"), 1.2, 0.0, at)],
				"end": []}
		"puppet_thought":     # crown threads run to the target; spiral compel mark above their head
			return {"tell": [L(10, "m", R, 1.6, Color.html("c9e04a"), w, 0.5, 0.0, Vector3(0.4, 2.8, 0))],
				"go": [L(10, "m", R, 2.2, Color.html("c9e04a"), w, 0.9, 0.0, Vector3(0.4, 2.2, 0)), L(20, "b", 1.5, 1.5, Color.html("c9e04a"), k, 1.0, 0.0, Vector3(R, 3.4, 0)), L(11, "g", 2.4, 2.4, Color.html("c9e04a"), w, 0.9, 0.0, Vector3(R, 0, 0))],
				"end": []}
		"future_touched":     # every attack ghosted early: big sigil + ripple + rising eyes
			return {"tell": [L(3, "g", 6.0, 6.0, Color.html("7a6cff"), w, 0.8)],
				"go": [L(11, "g", Z * 1.8, Z * 1.8, Color.html("7a6cff"), Color.html("b9c8ff"), D, 0.0, Vector3.ZERO, {"persist": true}), L(25, "b", 1.4, 0.8, Color.html("b9c8ff"), Color.html("4a3aa0"), D, 0.0, Vector3(0, 4.4, 0), {"persist": true}), L(7, "g", Z * 2.2, Z * 2.2, Color.html("7a6cff"), w, D, 0.0, Vector3.ZERO, {"persist": true})],
				"end": []}
		# ---------------------------------------------------------------- BRAMVEX
		"ghost":              # camouflage: leaf-blotch ring + drifting leaves; the rig dissolves into the terrain
			return {"tell": [L(13, "g", 4.0, 4.0, Color.html("6b7a3a"), Color.html("a9b07a"), 0.6)],
				"go": [L(13, "g", Z * 1.6, Z * 1.6, Color.html("6b7a3a"), Color.html("a9b07a"), D, 0.0, Vector3.ZERO, {"persist": true}), L(9, "v", 3.0, 3.6, Color.html("8a9a4a"), Color.html("d8c88a"), D, 0.0, Vector3.ZERO, {"persist": true})],
				"end": []}
		"ground_prep":        # thorn lines erupt from the ground along the real chokepoint
			return {"tell": [L(8, "v", 2.0, 1.2, Color.html("7a5a30"), Color.html("c9a24a"), 0.4, 0.0, Vector3(R * 0.5, 0, 0.1))],
				"go": [L(8, "v", R, 2.6, Color.html("7a5a30"), Color.html("d84a2a"), 1.0, 0.0, Vector3(R * 0.5, 0, 0.2), {"persist": true}), L(8, "v", R, 2.0, Color.html("5a4126"), Color.html("c9a24a"), 1.0, 0.1, Vector3(R * 0.5, 0, -0.2), {"persist": true}), L(2, "g", R, 2.0, Color.html("5a4126"), w, 0.8, 0.0, Vector3(R * 0.5, 0, 0))],
				"end": []}
		"detain":             # thorn cage closes on the target
			var tg := Vector3(R * 0.7, 0, 0)
			return {"tell": [L(12, "b", 3.0, 3.0, a, w, 0.4, 0.0, tg + Vector3(0, 1.6, 0))],
				"go": [L(8, "v", 2.6, 2.4, Color.html("7a5a30"), Color.html("d84a2a"), 1.0, 0.0, tg + Vector3(0, 0, 0.3)), L(8, "v", 2.6, 2.4, Color.html("5a4126"), Color.html("d84a2a"), 1.0, 0.05, tg + Vector3(0, 0, -0.3)), L(3, "g", 3.0, 3.0, Color.html("7a5a30"), w, 0.6, 0.0, tg)],
				"end": []}
		"day_20":             # the escape: banner chevrons surge up, camo ring bursts, thorn nova
			return {"tell": [L(16, "v", 3.0, 4.6, red, w, 0.8)],
				"go": [L(3, "g", Z * 2.4, Z * 2.4, red, w, 0.7), L(8, "v", 4.0, 3.0, Color.html("7a5a30"), red, 0.9, 0.0, Vector3(0, 0, 0.3)), L(13, "g", Z * 2.0, Z * 2.0, Color.html("6b7a3a"), Color.html("a9b07a"), 1.0), L(12, "b", 6.0, 6.0, w, red, 0.4, 0.0, Vector3(0, 1.6, 0))],
				"end": []}
		# ---------------------------------------------------------------- SCARLITH
		"ferment":            # culture zone: bubbling gold/red cultures on the real radius
			return {"tell": [L(5, "g", 2.0, 2.0, a, b, 0.5, 0.0, Vector3(R * 0.5, 0, 0))],
				"go": [L(5, "g", Z * 2.0, Z * 2.0, Color.html("d9a040"), Color.html("fff0b0"), D, 0.0, Vector3(R * 0.5, 0, 0), {"persist": true}), L(9, "v", Z * 1.6, 3.4, Color.html("c8383a"), Color.html("ffd890"), D, 0.0, Vector3(R * 0.5, 0, 0), {"persist": true})],
				"end": [L(0, "b", 3.0, 3.0, Color.html("ffd890"), a, 0.35, 0.0, Vector3(R * 0.5, 1.2, 0))]}
		"decompose":          # rot spreads on the target: mold blotches + flies of spores + drip
			var t2 := Vector3(R * 0.6, 0, 0)
			return {"tell": [L(9, "v", 2.4, 3.0, Color.html("6a8a3a"), Color.html("c8d890"), 0.5, 0.0, t2)],
				"go": [L(19, "g", Z * 1.8, Z * 1.8, Color.html("5a7a2a"), Color.html("b8c868"), D, 0.0, t2, {"persist": true}), L(9, "v", 2.8, 3.6, Color.html("6a8a3a"), Color.html("c8d890"), D, 0.0, t2, {"persist": true}), L(5, "v", 2.0, 2.0, Color.html("7a6a2a"), Color.html("d8c870"), D, 0.0, t2 + Vector3(0, 0.4, 0), {"persist": true})],
				"end": []}
		"cultivate":          # fungus patch growth that feeds him
			return {"tell": [L(19, "g", 2.0, 2.0, Color.html("5a8a3a"), Color.html("e8d870"), 0.5)],
				"go": [L(19, "g", Z * 2.0, Z * 2.0, Color.html("5a8a3a"), Color.html("e8d870"), D, 0.0, Vector3.ZERO, {"persist": true}), L(5, "g", Z * 1.4, Z * 1.4, Color.html("c8383a"), Color.html("ffd890"), D, 0.0, Vector3.ZERO, {"persist": true})],
				"end": []}
		"aged_to_perfection": # every culture ripens at once: golden ring + cheese-spore burst + shards
			return {"tell": [L(5, "g", 5.0, 5.0, Color.html("d9a040"), Color.html("fff0b0"), 0.7)],
				"go": [L(3, "g", Z * 2.6, Z * 2.6, Color.html("ffd24a"), w, 0.7), L(5, "g", Z * 2.0, Z * 2.0, Color.html("d9a040"), Color.html("fff0b0"), 1.0), L(23, "b", 6.0, 6.0, Color.html("ffd24a"), Color.html("e08a3a"), 0.8, 0.0, Vector3(0, 1.5, 0))],
				"end": []}
		# ---------------------------------------------------------------- MOLLUSK
		"inertia_field":      # time-ripple dome: a hit freezes mid-air, then lands
			return {"tell": [L(7, "g", 3.0, 3.0, Color.html("e2a25a"), w, 0.5)],
				"go": [L(7, "g", Z * 2.0, Z * 2.0, Color.html("e2a25a"), Color.html("fff0c0"), D, 0.0, Vector3(R * 0.3, 0, 0), {"persist": true}), L(23, "b", Z * 1.2, Z * 1.2, Color.html("fff0c0"), Color.html("e2a25a"), D, 0.0, Vector3(R * 0.3, 1.6, 0), {"persist": true})],
				"end": []}
		"borrowed_seconds":   # clock sigil + ticking ripple while the debt runs
			return {"tell": [L(11, "g", 3.2, 3.2, Color.html("e8c060"), w, 0.5)],
				"go": [L(11, "g", 3.6, 3.6, Color.html("e8c060"), Color.html("fff0c0"), D, 0.0, Vector3.ZERO, {"persist": true}), L(7, "g", 4.6, 4.6, Color.html("d89a40"), w, D, 0.0, Vector3.ZERO, {"persist": true})],
				"end": []}
		"lift":               # chevrons hoist the target; ground ring
			var t3 := Vector3(R * 0.5, 0, 0)
			return {"tell": [L(3, "g", 2.4, 2.4, Color.html("e8a040"), w, 0.4, 0.0, t3)],
				"go": [L(16, "v", 2.6, 5.0, Color.html("e8a040"), w, 0.9, 0.0, t3 + Vector3(0, 0, 0.2)), L(3, "g", 3.4, 3.4, Color.html("e8a040"), w, 0.7, 0.0, t3)],
				"end": [L(2, "g", 3.0, 3.0, Color.html("e8a040"), w, 0.7, 0.0, t3)]}
		"everything_arrives": # every delayed impact lands at once: collapsing ripples, then a shard blast
			return {"tell": [L(7, "g", 7.0, 7.0, Color.html("e2a25a"), w, 1.4), L(11, "g", 4.0, 4.0, Color.html("e8c060"), w, 1.4)],
				"go": [L(23, "b", R * 1.6, R * 1.6, Color.html("fff0c0"), Color.html("e2a25a"), 0.7, 0.0, Vector3(1.0, 1.4, 0)), L(2, "g", R * 2.0, R * 2.0, Color.html("e2a25a"), w, 1.0), L(3, "g", R * 2.4, R * 2.4, Color.html("fff0c0"), w, 0.6)],
				"end": []}
		# ---------------------------------------------------------------- ZEPHYR
		"gust":               # swirling wind cone with leaves
			return {"tell": [L(4, "g", 2.4, 2.4, Color.html("9ad4a0"), w, 0.4, 0.0, Vector3(0.8, 0, 0))],
				"go": [L(4, "g", R * 0.9, R * 0.9, Color.html("9ad4a0"), w, 0.7, 0.0, Vector3(R * 0.45, 0, 0)), L(4, "v", R * 0.9, 2.6, Color.html("c8f0c8"), w, 0.7, 0.05, Vector3(R * 0.5, 0, 0.2)), L(9, "v", R, 2.6, Color.html("8ab04a"), Color.html("f0e090"), 0.9, 0.0, Vector3(R * 0.5, 0.2, 0.3))],
				"end": []}
		"pollen":             # drifting pollen cloud on the real radius (slows / confuses)
			return {"tell": [L(9, "v", 2.0, 2.0, g, a, 0.4, 0.0, Vector3(1.0, 0, 0.2))],
				"go": [L(9, "v", Z * 2.0, 3.6, Color.html("ffd24a"), Color.html("ff7ac0"), D, 0.0, Vector3(R * 0.5, 0, 0.2), {"persist": true}), L(9, "g", Z * 2.0, Z * 2.0, Color.html("ffd24a"), Color.html("ff7ac0"), D, 0.0, Vector3(R * 0.5, 0, 0), {"persist": true}), L(3, "g", Z * 2.0, Z * 2.0, Color.html("ff7ac0"), w, D, 0.0, Vector3(R * 0.5, 0, 0), {"persist": true})],
				"end": []}
		"promise":            # a binding sigil + glowing link line
			return {"tell": [L(11, "g", 3.0, 3.0, Color.html("ffd24a"), w, 0.5)],
				"go": [L(11, "g", Z * 1.6, Z * 1.6, Color.html("ffd24a"), Color.html("ff7ac0"), D, 0.0, Vector3.ZERO, {"persist": true}), L(10, "m", R, 1.2, Color.html("ffd24a"), w, D, 0.0, Vector3(0.5, 1.6, 0), {"persist": true})],
				"end": []}
		"a_promise_kept":     # the promise pays out: huge golden sigil, petals, and impact lines
			return {"tell": [L(11, "g", 5.0, 5.0, Color.html("ffd24a"), w, 0.9)],
				"go": [L(24, "g", Z * 2.4, Z * 2.4, Color.html("ff7ac0"), Color.html("ffd24a"), 1.2, 0.0, Vector3.ZERO, {"rot": 40.0}), L(12, "b", 7.0, 7.0, Color.html("ffd24a"), w, 0.5, 0.0, Vector3(1.0, 1.5, 0)), L(9, "v", 5.0, 4.4, Color.html("ff7ac0"), Color.html("ffd24a"), 1.4)],
				"end": []}
		# ---------------------------------------------------------------- NYXARIS
		"boundary":           # frost web ring: crossing it hurts / roots
			return {"tell": [L(6, "g", 3.0, 3.0, Color.html("9fe0f8"), w, 0.4, 0.0, Vector3(R * 0.4, 0, 0))],
				"go": [L(6, "g", Z * 2.0, Z * 2.0, Color.html("9fe0f8"), Color.html("ee4fa8"), D, 0.0, Vector3(R * 0.4, 0, 0), {"persist": true}), L(10, "v", Z * 1.8, 2.4, Color.html("e8eaf2"), w, D, 0.0, Vector3(R * 0.4, 0, 0.2), {"persist": true})],
				"end": []}
		"venom_fang":         # fangs bite where the spike lands; venom beam and drops
			return {"tell": [L(21, "m", R * 0.6, 0.8, Color.html("ee4fa8"), w, 0.35, 0.0, Vector3(0.6, 1.4, 0))],
				"go": [L(21, "m", R, 1.0, Color.html("ee4fa8"), Color.html("9fe0f8"), 0.4, 0.0, Vector3(0.6, 1.5, 0)), L(17, "v", 2.2, 3.2, Color.html("9fe0f8"), Color.html("ee4fa8"), 0.7, 0.1, Vector3(R, 0.2, 0.2)), L(9, "v", 2.4, 2.6, Color.html("ee4fa8"), Color.html("e0f8ff"), 0.9, 0.1, Vector3(R, 0.2, 0.3))],
				"end": []}
		"cocoon":             # silk binds the target in a frosted cocoon
			var t4 := Vector3(R * 0.7, 0, 0)
			return {"tell": [L(10, "m", R * 0.7, 2.0, Color.html("e8eaf2"), Color.html("ee4fa8"), 0.5, 0.0, Vector3(0.5, 2.0, 0))],
				"go": [L(14, "v", 2.6, 4.0, Color.html("e8eaf2"), Color.html("9fe0f8"), D, 0.0, t4 + Vector3(0, 0, 0.3), {"persist": true}), L(6, "g", 3.2, 3.2, Color.html("9fe0f8"), w, D, 0.0, t4, {"persist": true})],
				"end": []}
		"permission":         # "who gave you permission?": sigil + stop-line
			return {"tell": [L(11, "g", 3.0, 3.0, Color.html("9fe0f8"), w, 0.4)],
				"go": [L(11, "g", 4.0, 4.0, Color.html("9fe0f8"), Color.html("ee4fa8"), 0.7), L(6, "g", 4.6, 4.6, Color.html("e8eaf2"), w, 0.7)], "end": []}
		"cold_archive":       # a frost-bloom opens: petal rosette, web, snow
			return {"tell": [L(24, "g", 4.0, 4.0, Color.html("9fe0f8"), Color.html("ee4fa8"), 0.9)],
				"go": [L(24, "g", Z * 2.6, Z * 2.6, Color.html("9fe0f8"), Color.html("ee4fa8"), 1.4, 0.0, Vector3.ZERO, {"rot": 25.0}), L(6, "g", Z * 2.4, Z * 2.4, Color.html("e8eaf2"), w, 1.4), L(9, "v", Z * 2.0, 4.4, Color.html("e8f4ff"), Color.html("9fe0f8"), 1.6)],
				"end": []}
	return {}

## Fallback by swing style when an ability has no bespoke recipe (new moves still look like something).
static func by_style(style: String, ctx: Dictionary) -> Dictionary:
	var P: Dictionary = ctx["pal"]
	var g := col(P, "g"); var w := col(P, "w"); var a := col(P, "a")
	var R: float = ctx.get("reach", 4.0)
	match style:
		"thrust", "punch": return {"go": [L(21, "m", R, 1.0, g, w, 0.3, 0.0, Vector3(0.6, 1.4, 0))]}
		"hook", "slash_back", "slash_up", "chop", "overhead": return {"go": [L(1, "v", R * 0.8, R * 0.8, g, w, 0.25, 0.0, Vector3(R * 0.4, 0.6, 0))]}
		"roar", "stance": return {"go": [L(3, "g", 4.0, 4.0, g, w, 0.6)]}
		"leap": return {"go": [L(12, "b", 3.0, 3.0, w, a, 0.3, 0.0, Vector3(0, 1.2, 0))]}
		"spin": return {"go": [L(3, "g", 5.0, 5.0, g, w, 0.5), L(1, "v", 4.0, 4.0, g, w, 0.4, 0.0, Vector3(0, 0.5, 0))]}
	return {}

## Per-critter flavor of the common one-shots so hit sparks / dodge trails / guard + parry flashes are never generic.
static func event_fx(type: String, critter: String, ctx: Dictionary) -> Array:
	var P: Dictionary = ctx["pal"]
	var g := col(P, "g"); var a := col(P, "a"); var m := col(P, "m"); var w := col(P, "w"); var s := col(P, "s")
	var heavy: bool = ctx.get("heavy", false)
	var sc := 1.4 if heavy else 1.0
	match type:
		"hit":
			var base := [L(0, "b", 2.2 * sc, 2.2 * sc, g, w, 0.25, 0.0, Vector3(0, 1.4, 0.5)), L(12, "b", 3.0 * sc, 3.0 * sc, w, g, 0.22, 0.0, Vector3(0, 1.4, 0.5))]
			match critter:
				"aruun": base.append(L(2, "g", 2.4 * sc, 2.4 * sc, Color.html("e8502a"), w, 0.5))
				"cigarra": base.append(L(10, "m", 2.2, 1.2, Color.html("c9e04a"), w, 0.35, 0.0, Vector3(-1.0, 1.4, 0.5)))
				"bramvex": base.append(L(8, "v", 1.6, 1.4, Color.html("7a5a30"), Color.html("d84a2a"), 0.4, 0.0, Vector3(0, 0, 0.5)))
				"scarlith": base.append(L(5, "b", 2.0, 2.0, Color.html("c8383a"), Color.html("ffd890"), 0.45, 0.0, Vector3(0, 1.3, 0.5)))
				"mollusk": base.append(L(3, "g", 2.2, 2.2, Color.html("e2a25a"), w, 0.4))
				"zephyr": base.append(L(24, "b", 1.8, 1.8, Color.html("ff7ac0"), Color.html("ffd24a"), 0.4, 0.0, Vector3(0, 1.4, 0.5)))
				"nyxaris": base.append(L(23, "b", 2.2, 2.2, Color.html("9fe0f8"), Color.html("ee4fa8"), 0.4, 0.0, Vector3(0, 1.4, 0.5)))
			return base
		"block": return [L(11, "b", 2.4, 2.4, s, w, 0.3, 0.0, Vector3(0.5, 1.5, 0.5)), L(12, "b", 2.0, 2.0, w, s, 0.2, 0.0, Vector3(0.5, 1.5, 0.5))]
		"parry": return [L(0, "b", 4.0, 4.0, w, g, 0.3, 0.0, Vector3(0.5, 1.5, 0.5)), L(3, "g", 3.4, 3.4, w, s, 0.4), L(12, "b", 5.0, 5.0, w, g, 0.25, 0.0, Vector3(0.5, 1.5, 0.5))]
		"dodge": return [L(21, "m", 3.2, 1.0, g, w, 0.3, 0.0, Vector3(-3.0, 1.2, 0.4)), L(21, "m", 2.4, 0.7, w, g, 0.3, 0.05, Vector3(-2.4, 2.0, 0.4))]
		"ko": return [L(0, "b", 7.0, 7.0, w, g, 0.4, 0.0, Vector3(0, 1.4, 0.5)), L(12, "b", 8.0, 8.0, w, g, 0.4, 0.0, Vector3(0, 1.4, 0.5)), L(3, "g", 5.0, 5.0, g, w, 0.8)]
		"teleport": return [L(12, "b", 3.4, 3.4, w, g, 0.35, 0.0, Vector3(0, 1.4, 0.4)), L(3, "g", 3.0, 3.0, g, w, 0.4)]
		"summon": return [L(5, "g", 4.0, 4.0, g, a, 0.7), L(0, "b", 2.0, 2.0, w, g, 0.3, 0.0, Vector3(0, 1.2, 0.4))]
	return []

## Persistent status visuals on the victim / owner for their REAL duration (sim.state().fighters[i].status).
static func status_fx(name: String, critter: String, ctx: Dictionary) -> Array:
	var P: Dictionary = ctx["pal"]
	var g := col(P, "g"); var w := col(P, "w")
	match name:
		"camo": return [L(13, "g", 3.4, 3.4, Color.html("6b7a3a"), Color.html("a9b07a"), 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"premonition", "touched": return [L(11, "g", 3.6, 3.6, Color.html("7a6cff"), Color.html("b9c8ff"), 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"borrowed": return [L(7, "g", 4.0, 4.0, Color.html("e2a25a"), w, 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"permission": return [L(11, "g", 3.4, 3.4, Color.html("9fe0f8"), Color.html("ee4fa8"), 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"root", "rooted", "tethered": return [L(14, "v", 2.4, 3.8, Color.html("e8eaf2"), Color.html("ee4fa8"), 1.0, 0.0, Vector3(0, 0, 0.3), {"persist": true})]
		"slow", "slowed": return [L(7, "g", 3.2, 3.2, Color.html("e2a25a"), w, 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"poison", "venom", "bleed": return [L(9, "v", 2.4, 3.0, Color.html("ee4fa8"), w, 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"rot", "decay", "culture": return [L(19, "g", 2.6, 2.6, Color.html("5a7a2a"), Color.html("b8c868"), 1.0, 0.0, Vector3.ZERO, {"persist": true}), L(9, "v", 2.2, 3.2, Color.html("6a8a3a"), Color.html("c8d890"), 1.0, 0.0, Vector3.ZERO, {"persist": true})]
		"marked", "mark": return [L(11, "b", 1.6, 1.6, Color.html("e8402a"), w, 1.0, 0.0, Vector3(0, 4.2, 0), {"persist": true})]
		"stun", "stunned", "compelled", "confused": return [L(20, "b", 1.5, 1.5, g, Color.html("1a1020"), 1.0, 0.0, Vector3(0, 4.0, 0), {"persist": true})]
		"strain", "rage": return [L(18, "v", 2.6, 3.6, Color.html("e8402a"), Color.html("ff8a3a"), 1.0, 0.0, Vector3(0, 0, 0.3), {"persist": true})]
	return []

## Projectile body: a jagged colored bolt that turns toward its travel angle (VfxStage rotates the node; the sim supplies position every frame).
static func projectile_fx(critter: String, ctx: Dictionary) -> Array:
	var P: Dictionary = ctx["pal"]
	var g := col(P, "g"); var w := col(P, "w"); var a := col(P, "a")
	match critter:
		"cigarra": return [L(21, "m", 1.6, 1.0, Color.html("c9e04a"), w, 1.0, 0.0, Vector3(-0.8, 1.4, 0), {"persist": true}), L(0, "b", 0.9, 0.9, Color.html("15111a"), Color.html("c9e04a"), 1.0, 0.0, Vector3(0.4, 1.4, 0), {"persist": true})]
		"nyxaris": return [L(21, "m", 2.0, 0.9, Color.html("ee4fa8"), Color.html("9fe0f8"), 1.0, 0.0, Vector3(-1.0, 1.2, 0), {"persist": true})]
		"bramvex": return [L(21, "m", 1.8, 0.7, Color.html("7a5a30"), Color.html("d84a2a"), 1.0, 0.0, Vector3(-0.9, 1.2, 0), {"persist": true})]
		"zephyr": return [L(4, "g", 1.8, 1.8, Color.html("9ad4a0"), w, 1.0, 0.0, Vector3.ZERO, {"persist": true}), L(24, "b", 0.9, 0.9, Color.html("ff7ac0"), Color.html("ffd24a"), 1.0, 0.0, Vector3(0, 1.2, 0), {"persist": true})]
		"aruun": return [L(21, "m", 2.2, 1.2, Color.html("e8402a"), w, 1.0, 0.0, Vector3(-1.1, 1.3, 0), {"persist": true})]
		"scarlith": return [L(5, "b", 1.2, 1.2, Color.html("c8383a"), Color.html("ffd890"), 1.0, 0.0, Vector3(0, 1.2, 0), {"persist": true})]
		"mollusk": return [L(7, "g", 1.6, 1.6, Color.html("e2a25a"), w, 1.0, 0.0, Vector3.ZERO, {"persist": true})]
	return [L(21, "m", 1.6, 0.8, g, w, 1.0, 0.0, Vector3(-0.8, 1.2, 0), {"persist": true})]

## A zone/trap with no bespoke recipe still shows what it really is (kind + critter flavor) on its real radius.
static func zone_fallback(critter: String, kind: String, ctx: Dictionary) -> Array:
	var P: Dictionary = ctx["pal"]
	var g := col(P, "g"); var w := col(P, "w"); var Z: float = ctx.get("radius", 2.0)
	var base := {"aruun": 2, "cigarra": 11, "bramvex": 13, "scarlith": 5, "mollusk": 7, "zephyr": 9, "nyxaris": 6}.get(critter, 3) as int
	var layers: Array = [L(base, "g", Z * 2.0, Z * 2.0, g, w, 1.0, 0.0, Vector3.ZERO, {"persist": true})]
	if kind == "trap":
		layers.append(L(12, "b", 1.6, 1.6, w, g, 1.0, 0.0, Vector3(0, 0.8, 0), {"persist": true}))
	return layers
