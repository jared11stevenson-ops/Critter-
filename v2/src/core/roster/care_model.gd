class_name CareModel
extends RefCounted
## Habitat care + stress model (GDD 6.5, 4). Pure rules on CritterInstance; no timers. Time passes in SESSIONS
## (RosterState.end_session), and each session you only have CARE_POINTS actions to spend, so care is a choice.

const CARE_POINTS := 3
const NEGLECT_THRESHOLD := 70.0
const HURT_BELOW := 0.5
const STRESS_FREE_BELOW := 30.0
const TRAIN_MIN_VITALITY := 0.4

## Per-session drift if nobody tends the jar.
const HUNGER_PER_SESSION := 25.0
const MESS_PER_SESSION := 20.0


static func _clamp(c: CritterInstance) -> void:
	c.vitality = clampf(c.vitality, 0.0, 1.0)
	c.stress = clampf(c.stress, 0.0, 100.0)
	c.hunger = clampf(c.hunger, 0.0, 100.0)
	c.mess = clampf(c.mess, 0.0, 100.0)


## Care actions return {ok, bond, reason}. They do not consume care points; RosterState does that.
static func feed(c: CritterInstance) -> Dictionary:
	c.hunger -= 60.0
	c.vitality += 0.05
	c.stress -= 5.0
	_clamp(c)
	return {"ok": true, "bond": 1}


static func clean(c: CritterInstance) -> Dictionary:
	c.mess = 0.0
	c.stress -= 3.0
	_clamp(c)
	return {"ok": true, "bond": 1}


static func play(c: CritterInstance) -> Dictionary:
	c.stress -= 10.0
	c.mess += 10.0
	c.hunger += 5.0
	_clamp(c)
	return {"ok": true, "bond": 2}


static func train(c: CritterInstance) -> Dictionary:
	if c.vitality < TRAIN_MIN_VITALITY:
		return {"ok": false, "bond": 0, "reason": "too hurt to train"}
	c.stress += 6.0
	c.hunger += 10.0
	_clamp(c)
	return {"ok": true, "bond": 2}


static func rest(c: CritterInstance) -> Dictionary:
	c.vitality += 0.30
	c.hunger += 10.0
	_clamp(c)
	return {"ok": true, "bond": 0}


## A session passes with the jar untended: hunger and mess grow; neglect raises Stress, well-kept critters relax.
static func end_session(c: CritterInstance) -> void:
	c.hunger += HUNGER_PER_SESSION
	c.mess += MESS_PER_SESSION
	if c.hunger >= NEGLECT_THRESHOLD:
		c.stress += 10.0
	if c.mess >= NEGLECT_THRESHOLD:
		c.stress += 6.0
	if c.hunger < 40.0 and c.mess < 40.0:
		c.stress -= 3.0
	_clamp(c)


static func is_stressed(c: CritterInstance) -> bool:
	return c.stress > STRESS_FREE_BELOW + 20.0


static func is_hurt(c: CritterInstance) -> bool:
	return c.vitality < HURT_BELOW


static func is_neglected(c: CritterInstance) -> bool:
	return c.hunger >= NEGLECT_THRESHOLD or c.mess >= NEGLECT_THRESHOLD


## Multipliers the bout set-up applies to the critter's stats. 1.0 = unaffected. Stress above 30 and being Hurt weaken it.
static func stat_modifiers(c: CritterInstance) -> Dictionary:
	var sf := clampf((c.stress - STRESS_FREE_BELOW) / (100.0 - STRESS_FREE_BELOW), 0.0, 1.0)
	var hf := 1.0 if is_hurt(c) else 0.0
	return {
		"damage": 1.0 - 0.10 * sf - 0.05 * hf,
		"speed": 1.0 - 0.15 * sf - 0.05 * hf,
		"poise": 1.0 - 0.20 * sf - 0.10 * hf,
		"stamina": 1.0 - 0.20 * sf - 0.05 * hf,
	}


## Small, real Bond benefits (GDD 7): not raw stats. level from CritterInstance.bond_level().
static func bond_perks(level: int) -> Dictionary:
	return {
		"parry_window_frames": 0 if level < 2 else (1 if level < 4 else 2),
		"voice_line": level >= 3,
		"passive_trait": level >= 5,
	}
