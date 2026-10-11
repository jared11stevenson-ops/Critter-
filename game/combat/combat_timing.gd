class_name CombatTiming
extends RefCounted
## Pure combat-feel math (no scene access) so the timing rules are unit-testable.
## Phases of an attack: windup (telegraphed, cancellable) -> active (damage lands) -> recover (committed, but
## inputs are buffered and a dash may cancel it).

enum Phase { WINDUP, ACTIVE, RECOVER, DONE }

static func phase_at(t: float, windup: float, active: float, recover: float) -> int:
	if t < windup:
		return Phase.WINDUP
	if t < windup + active:
		return Phase.ACTIVE
	if t < windup + active + recover:
		return Phase.RECOVER
	return Phase.DONE

## True when a press made at `pressed_at` (same clock as `now`) is still fresh enough to fire.
static func buffer_valid(now: float, pressed_at: float, window: float) -> bool:
	return pressed_at >= 0.0 and now - pressed_at <= window and now >= pressed_at

## Score used to rank auto-aim candidates (lower wins). The current target gets a flat bonus so the lock does not
## flicker between two enemies at similar distance; the angle penalty keeps aim near the stick direction.
static func aim_score(dist: float, angle_rad: float, is_object: bool, is_current: bool, stick_bonus: float) -> float:
	var s := dist + angle_rad * 2.0 + (6.0 if is_object else 0.0)
	if is_current:
		s -= stick_bonus
	return s

## Distance a lunge may cover toward a target: never push through it (stop `gap` short of its edge).
static func lunge_clamp(lunge: float, dist_to_target_edge: float, gap: float = 0.9) -> float:
	if dist_to_target_edge < 0.0:
		return lunge
	return clampf(dist_to_target_edge - gap, 0.0, lunge)

## Telegraph urgency: 0 until `from` of the windup has elapsed, then ramps to 1 at the moment of impact.
static func urgency(progress: float, from: float = 0.65) -> float:
	return clampf((progress - from) / maxf(0.001, 1.0 - from), 0.0, 1.0)

## Whether a hit landing now should be a "perfect dodge": the actor is mid-dash, inside its i-frames.
static func is_perfect_dodge(state: String, invuln_left: float) -> bool:
	return state == "dash" and invuln_left > 0.0
