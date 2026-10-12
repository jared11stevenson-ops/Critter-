class_name AbilityVfx
extends RefCounted
## One distinct visual recipe per ability (cast moment) and per-critter hit styles. Keys are move ids with trailing digits stripped.
## ctx: {parent, pos (caster, ground), tpos (target, ground), dir (unit XZ toward the target), col, acc, glow, tex (ability icon)}

static func base_id(mid: String) -> String:
	var b := mid
	while b.length() > 0 and b[b.length() - 1].is_valid_int():
		b = b.substr(0, b.length() - 1)
	return b

static func _y(v: Vector3, y: float) -> Vector3:
	return Vector3(v.x, y, v.z)

## Returns true when a recipe exists for this move (so BoutVfx can spawn the cast glyph only for real abilities)
static func cast(mid: String, c: Dictionary) -> bool:
	var P: Node3D = c["parent"]
	var pos: Vector3 = c["pos"]
	var tp: Vector3 = c["tpos"]
	var dir: Vector3 = c["dir"]
	var glow: Color = c["glow"]
	var acc: Color = c["acc"]
	var col: Color = c["col"]
	var hi := _y(pos, 1.2)
	var key := mid if mid == "bramvex_day_20" else base_id(mid)
	match key:
		# ---------------- Aruun: psionic mace, rage
		"aruun_reaching_strike":
			var end := _y(pos, 1.1) + dir * 7.0
			FxPrims.streak(P, hi, end, Color(glow, 0.8), 0.32, 0.42)
			FxPrims.streak(P, hi, end, Color(1, 1, 1, 0.9), 0.22, 0.12)
			FxPrims.ring(P, _y(end, 0.05), 0.4, 2.2, glow, 0.4, 0.12)
			FxPrims.sparks(P, end, acc, 12, 5.0, -8.0, 0.5, 0.14)
		"aruun_gravity_pull":
			FxPrims.spiral(P, _y(tp, 0.1), Color(0.75, 0.35, 1.0, 0.9), 2.2, 1.8, 2.5, 0.7, true)
			FxPrims.ring(P, _y(tp, 0.05), 3.2, 0.5, Color(0.6, 0.3, 1.0, 0.9), 0.6, 0.1)
			FxPrims.ring(P, _y(tp, 0.05), 2.2, 0.3, glow, 0.55, 0.08)
		"aruun_beetle_rage":
			FxPrims.ring(P, _y(pos, 0.05), 0.6, 3.4, Color(1, 0.25, 0.1, 0.9), 0.5, 0.14)
			FxPrims.column(P, _y(pos, 0.0), Color(1, 0.35, 0.1), 5.0, 0.9, 0.6)
			FxPrims.sparks(P, hi, Color(1, 0.55, 0.2), 26, 6.0, 2.0, 0.8, 0.16, 60.0)
			FxPrims.burst(P, hi, Color(1, 0.8, 0.3), 12, 2.0, 0.3, 0.12)
		"aruun_carry_the_bridge":
			FxPrims.ring(P, _y(pos, 1.8), 1.7, 1.9, Color(1, 0.85, 0.3, 0.9), 1.2, 0.1, true)
			FxPrims.dome(P, hi, 1.0, Color(1, 0.8, 0.3), 1.0)
			FxPrims.sparks(P, _y(pos, 2.5), Color(0.8, 0.7, 0.5), 22, 2.0, -4.0, 1.0, 0.18, 120.0, Vector3.DOWN)
		# ---------------- Cigarra: premonition, mind control
		"cigarra_premonition":
			FxPrims.ring(P, _y(pos, 0.05), 0.5, 4.0, Color(0.5, 1.0, 0.9, 0.9), 0.7, 0.08)
			FxPrims.ring(P, _y(pos, 2.4), 0.6, 1.0, Color(1, 0.95, 0.5, 0.9), 0.9, 0.1, true)
			FxPrims.sparks(P, hi, Color(1, 0.95, 0.5), 18, 3.0, 1.0, 0.9, 0.1, 180.0)
		"cigarra_false_memory":
			FxPrims.ring(P, _y(pos, 0.05), 0.5, 3.0, Color(1, 0.4, 0.9, 0.85), 0.5, 0.1)
			FxPrims.sparks(P, hi, Color(1, 0.5, 0.95), 22, 3.5, -1.0, 0.8, 0.1, 180.0)
		"cigarra_puppet_thought":
			for k in 5:
				var off := Vector3(randf_range(-0.5, 0.5), randf_range(1.8, 2.3), randf_range(-0.5, 0.5))
				FxPrims.streak(P, pos + off, _y(tp, 1.3) + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), 0), Color(0.85, 1.0, 0.3, 0.9), 0.5, 0.05)
			FxPrims.ring(P, _y(tp, 0.05), 2.4, 0.6, Color(0.85, 1.0, 0.3, 0.9), 0.55, 0.08)
			FxPrims.ring(P, _y(tp, 2.2), 0.8, 0.8, Color(0.85, 1.0, 0.3, 0.9), 0.7, 0.14)
		"cigarra_future_touched":
			FxPrims.spiral(P, _y(pos, 0.1), Color(1, 0.9, 0.3, 0.9), 1.6, 2.4, 2.0, 0.9)
			FxPrims.column(P, _y(pos, 0.0), Color(1, 0.9, 0.4), 6.0, 0.9, 0.9)
			FxPrims.ring(P, _y(pos, 0.05), 0.5, 5.0, Color(1, 0.9, 0.4, 0.9), 0.8, 0.1)
		"cigarra_bad_thought":
			FxPrims.streak(P, _y(pos, 2.0), _y(tp, 1.3), Color(0.7, 0.35, 1.0, 0.9), 0.28, 0.22)
			FxPrims.streak(P, _y(pos, 2.0), _y(tp, 1.3), Color(1, 1, 1, 0.8), 0.2, 0.07)
			FxPrims.sparks(P, _y(pos, 2.0), Color(0.8, 1.0, 0.4), 10, 4.0, -2.0, 0.5, 0.12, 120.0)
		"cigarra_crown_barrage":
			for k in 5:
				var oy := Vector3(randf_range(-0.8, 0.8), randf_range(1.6, 2.6), randf_range(-0.8, 0.8))
				FxPrims.streak(P, pos + oy, _y(tp, 1.3) + oy * 0.2, Color(0.7, 0.35, 1.0, 0.85), 0.35 + float(k) * 0.05, 0.14)
			FxPrims.ring(P, _y(tp, 0.05), 0.4, 2.2, Color(0.7, 0.35, 1.0, 0.8), 0.4, 0.1)
		# ---------------- Bramvex: camouflage, terrain, restraint
		"bramvex_ghost":
			FxPrims.sparks(P, hi, Color(0.5, 0.9, 0.4), 30, 2.0, 0.5, 1.0, 0.12, 180.0)
			FxPrims.ring(P, _y(pos, 0.05), 1.8, 0.4, Color(0.4, 0.8, 0.4, 0.7), 0.7, 0.08)
		"bramvex_ground_prep":
			FxPrims.spikes(P, _y(pos, 0) + dir * 3.2, Color(0.85, 0.78, 0.55), 8, 1.8, 1.1, 0.6)
			FxPrims.ring(P, _y(pos, 0.05) + dir * 3.2, 0.4, 2.2, Color(0.9, 0.3, 0.2, 0.8), 0.5, 0.08)
		"bramvex_detain":
			FxPrims.ring(P, _y(tp, 1.4), 2.0, 0.55, Color(0.85, 0.6, 0.3, 0.95), 0.5, 0.16, false)
			FxPrims.ring(P, _y(tp, 0.8), 2.2, 0.6, Color(0.85, 0.6, 0.3, 0.95), 0.55, 0.14, false)
			FxPrims.sparks(P, _y(tp, 1.2), Color(0.9, 0.7, 0.4), 12, 3.0, -2.0, 0.4, 0.1)
		"bramvex_day_20":
			FxPrims.burst(P, hi, Color(1, 0.4, 0.3), 16, 3.2, 0.4, 0.14)
			FxPrims.spikes(P, _y(pos, 0), Color(0.9, 0.82, 0.55), 12, 3.0, 1.4, 0.7)
			FxPrims.ring(P, _y(pos, 0.05), 0.6, 5.0, Color(1, 0.4, 0.3, 0.9), 0.5, 0.12)
		"bramvex_cigarra_hole":
			FxPrims.sparks(P, hi, Color(0.9, 0.9, 0.6), 10, 3.0, 0.0, 0.3, 0.1)
		# ---------------- Scarlith: ferment, decay, growth
		"scarlith_ferment":
			FxPrims.sparks(P, _y(tp, 0.4), Color(0.7, 1.0, 0.3), 26, 2.2, 3.0, 1.0, 0.16, 40.0)
			FxPrims.ring(P, _y(tp, 0.05), 0.5, 2.0, Color(0.7, 1.0, 0.3, 0.8), 0.6, 0.1)
		"scarlith_decompose":
			FxPrims.sparks(P, _y(tp, 2.0), Color(0.55, 0.85, 0.3), 24, 1.5, -3.0, 0.9, 0.14, 60.0, Vector3.DOWN)
			FxPrims.disc(P, _y(tp, 0.04), 1.4, Color(0.4, 0.7, 0.2, 0.6), 0.9, 1.5)
		"scarlith_cultivate":
			FxPrims.spikes(P, _y(pos, 0) + dir * 2.0, Color(0.85, 0.35, 0.5), 7, 1.6, 0.8, 0.8)
			FxPrims.ring(P, _y(pos, 0.05) + dir * 2.0, 0.4, 2.0, Color(0.5, 0.9, 0.3, 0.7), 0.6, 0.1)
		"scarlith_aged_to_perfection":
			FxPrims.burst(P, _y(tp, 1.2), Color(1, 0.85, 0.3), 14, 3.0, 0.4, 0.16)
			FxPrims.column(P, _y(tp, 0.0), Color(1, 0.85, 0.3), 5.0, 1.0, 0.6)
			FxPrims.ring(P, _y(tp, 0.05), 0.5, 4.0, Color(1, 0.85, 0.3, 0.9), 0.5, 0.12)
			FxPrims.sparks(P, _y(tp, 1.2), Color(1, 0.9, 0.5), 30, 6.0, -5.0, 0.8, 0.15)
		"scarlith_barter":
			FxPrims.streak(P, _y(tp, 1.2), _y(pos, 1.2), Color(1, 0.85, 0.3, 0.9), 0.35, 0.1)
			FxPrims.sparks(P, _y(tp, 1.2), Color(1, 0.9, 0.4), 10, 3.0, -2.0, 0.4, 0.14)
		# ---------------- Mollusk: time inertia
		"mollusk_inertia_field":
			FxPrims.dome(P, _y(pos, 0.2), 1.6, Color(1, 0.7, 0.2), 1.1)
			FxPrims.ring(P, _y(pos, 0.05), 0.8, 5.0, Color(1, 0.7, 0.2, 0.8), 1.0, 0.07)
			FxPrims.ring(P, _y(pos, 0.05), 0.4, 3.5, Color(1, 0.85, 0.4, 0.8), 0.8, 0.07)
		"mollusk_borrowed_seconds":
			for k in 3:
				FxPrims.ring(P, _y(pos, 0.1 + k * 0.05), 3.0 - k * 0.7, 0.4, Color(1, 0.8, 0.3, 0.8), 0.5 + k * 0.15, 0.06)
			FxPrims.spiral(P, _y(pos, 0.1), Color(1, 0.85, 0.4, 0.9), 1.4, 2.0, 2.0, 0.7, true)
		"mollusk_lift":
			FxPrims.column(P, _y(tp, 0.0) + Vector3(-0.5, 0, 0), Color(1, 0.7, 0.2), 3.5, 0.2, 0.5)
			FxPrims.column(P, _y(tp, 0.0) + Vector3(0.5, 0, 0), Color(1, 0.7, 0.2), 3.5, 0.2, 0.5)
			FxPrims.sparks(P, _y(tp, 0.3), Color(1, 0.8, 0.3), 14, 3.0, 4.0, 0.7, 0.12, 30.0)
		"mollusk_everything_arrives":
			for k in 4:
				FxPrims.ring(P, _y(tp, 0.05), 4.5 - k, 0.5, Color(1, 0.65, 0.2, 0.9), 0.35 + k * 0.1, 0.1)
			FxPrims.burst(P, _y(tp, 1.0), Color(1, 0.8, 0.3), 16, 3.5, 0.45, 0.16)
		# ---------------- Zephyr: wind, pollen, promises
		"zephyr_gust":
			for k in 3:
				FxPrims.spiral(P, _y(pos, 0.3) + dir * (1.5 + k * 1.6), Color(0.8, 1.0, 0.7, 0.8), 1.0 + k * 0.4, 1.2, 1.5, 0.6)
			FxPrims.sparks(P, _y(pos, 1.0) + dir * 2.0, Color(0.7, 0.95, 0.5), 20, 7.0, 0.0, 0.7, 0.14, 25.0, dir)
		"zephyr_pollen":
			FxPrims.sparks(P, _y(tp, 1.0), Color(1, 0.4, 0.85), 36, 3.5, 0.5, 1.1, 0.14, 180.0)
			FxPrims.sparks(P, _y(tp, 1.0), Color(1, 0.9, 0.4), 24, 2.5, 0.5, 1.2, 0.1, 180.0)
			FxPrims.ring(P, _y(tp, 0.05), 0.5, 3.0, Color(1, 0.5, 0.85, 0.7), 0.7, 0.08)
		"zephyr_promise_attack", "zephyr_promise":
			FxPrims.ring(P, _y(pos, 1.0), 0.5, 1.6, Color(1, 0.5, 0.9, 0.9), 0.6, 0.1, true)
			FxPrims.sparks(P, hi, Color(1, 0.8, 0.5), 16, 3.0, 0.0, 0.7, 0.1)
		"zephyr_a_promise_kept":
			for k in 7:
				var off := Vector3(randf_range(-1.5, 1.5), randf_range(0.6, 2.0), randf_range(-1.5, 1.5))
				FxPrims.streak(P, _y(pos, 1.0) + off - dir * 1.0, _y(tp, 1.2) + off * 0.3, Color(1, 0.55, 0.9, 0.9), 0.35 + k * 0.04, 0.1)
			FxPrims.burst(P, _y(tp, 1.2), Color(1, 0.8, 0.5), 14, 2.6, 0.4, 0.12)
		# ---------------- Nyxaris: frost silk, venom
		"nyxaris_boundary":
			FxPrims.spikes(P, _y(pos, 0) + dir * 3.2, Color(0.8, 0.95, 1.0), 9, 2.0, 1.2, 0.8)
			FxPrims.ring(P, _y(pos, 0.05) + dir * 3.2, 0.4, 2.4, Color(0.6, 0.85, 1.0, 0.9), 0.6, 0.08)
		"nyxaris_venom_fang":
			FxPrims.slash(P, _y(tp, 1.2), -dir, Color(0.5, 1.0, 0.4, 0.9), 1.5, 0.2)
			FxPrims.sparks(P, _y(tp, 1.0), Color(0.5, 1.0, 0.35), 16, 3.0, -4.0, 0.6, 0.13)
		"nyxaris_cocoon":
			FxPrims.spiral(P, _y(tp, 0.1), Color(0.85, 0.95, 1.0, 0.9), 1.4, 2.2, 3.0, 0.7, true)
			FxPrims.spikes(P, _y(tp, 0), Color(0.8, 0.95, 1.0), 6, 1.0, 1.0, 0.7)
			FxPrims.ring(P, _y(tp, 1.2), 1.8, 0.5, Color(0.85, 0.95, 1.0, 0.9), 0.5, 0.12)
		"nyxaris_cold_archive":
			FxPrims.ring(P, _y(pos, 0.05), 1.0, 22.0, Color(0.7, 0.9, 1.0, 0.9), 1.2, 0.04)
			FxPrims.dome(P, _y(pos, 0.2), 3.0, Color(0.7, 0.9, 1.0), 1.4)
			FxPrims.sparks(P, _y(pos, 6.0), Color(0.9, 0.97, 1.0), 60, 1.0, -2.0, 2.0, 0.12, 180.0, Vector3.DOWN)
		_:
			return false
	return true

## per-critter hit style on top of the generic spark burst
static func hit(critter: String, c: Dictionary, dmg: float, heavy: bool) -> void:
	var P: Node3D = c["parent"]
	var hp: Vector3 = c["tpos"] + Vector3(0, 1.1, 0)
	var dir: Vector3 = c["dir"]
	var glow: Color = c["glow"]
	var s := clampf(0.7 + dmg * 0.04, 0.7, 2.2) * (1.4 if heavy else 1.0)
	FxPrims.burst(P, hp, Color(glow, 0.95), 7 + int(s * 3.0), 0.9 * s, 0.22, 0.08 + 0.03 * s)
	match critter:
		"aruun":
			FxPrims.slash(P, hp, dir, Color(1, 0.55, 0.25, 0.9), 1.4 * s, 0.2)
			if heavy:
				FxPrims.ring(P, Vector3(hp.x, 0.05, hp.z), 0.4, 3.0, Color(0.9, 0.5, 0.3, 0.8), 0.35, 0.1)
				FxPrims.sparks(P, Vector3(hp.x, 0.2, hp.z), Color(0.75, 0.62, 0.45), 14, 4.0, -9.0, 0.6, 0.18, 70.0)
		"cigarra":
			FxPrims.sparks(P, hp, Color(0.75, 0.45, 1.0), 14, 4.5, -2.0, 0.5, 0.12)
			FxPrims.ring(P, hp, 0.2, 1.2 * s, Color(0.8, 1.0, 0.4, 0.8), 0.25, 0.1, true)
		"bramvex":
			FxPrims.slash(P, hp, dir, Color(0.85, 0.75, 0.45, 0.9), 1.5 * s, 0.2, 0.5)
			FxPrims.sparks(P, hp, Color(0.9, 0.25, 0.2), 8, 3.0, -5.0, 0.5, 0.1)
		"scarlith":
			FxPrims.sparks(P, hp, Color(0.65, 0.95, 0.3), 14, 3.5, -6.0, 0.6, 0.15)
			FxPrims.sparks(P, hp, Color(1, 0.85, 0.4), 6, 2.5, -4.0, 0.5, 0.12)
		"mollusk":
			FxPrims.ring(P, hp, 0.3, 2.0 * s, Color(1, 0.7, 0.25, 0.8), 0.6, 0.08, true)
			FxPrims.sparks(P, hp, Color(1, 0.8, 0.4), 8, 2.0, -1.0, 0.7, 0.14)
		"zephyr":
			FxPrims.slash(P, hp, dir, Color(1, 0.6, 0.9, 0.9), 1.3 * s, 0.16, -0.4)
			FxPrims.sparks(P, hp, Color(1, 0.7, 0.9), 10, 4.0, 1.0, 0.6, 0.1)
		"nyxaris":
			FxPrims.spikes(P, Vector3(hp.x, 0, hp.z), Color(0.8, 0.95, 1.0), 4, 0.8, 0.9, 0.4)
			FxPrims.sparks(P, hp, Color(0.8, 0.95, 1.0), 12, 3.5, -3.0, 0.6, 0.12)
