extends RefCounted
## Key poses and timing curves for skinned critters (see skinned_rig.gd for the axis conventions). Currently authored for Bramvex
## (hunched sergeant: economical, committed, weight shifts; the free left hand is the Command Hand; wings are the counterweight and the shield).
## A pose is {bone: Vector3(roll, pitch, yaw) degrees, "root": Vector3 metres (+x forward, +y up)}; partial poses are merged over IDLE.
## Hanging arm: roll +/-72..86 lowers it (right +, left -), pitch negative = forward. Elbow = arm_lo yaw (right +, left - bends it forward).
## Leg: thigh pitch negative = forward, shin pitch positive = knee bend. Spine/neck pitch positive = lean forward. Yaw positive turns left.

const WALK_RATE := 8.0

const IDLE := {
	"root": Vector3(0, -0.04, 0),
	"hips": Vector3(0, 4, 0), "spine": Vector3(0, 9, 0), "chest": Vector3(0, 7, 0), "neck": Vector3(0, -6, 0), "head": Vector3(0, -9, 0),
	"arm_up_L": Vector3(-74, -6, 0), "arm_lo_L": Vector3(0, 0, -16),
	"arm_up_R": Vector3(68, -24, 0), "arm_lo_R": Vector3(0, 0, 38),
	"th_L": Vector3(0, -8, 0), "sh_L": Vector3(0, 12, 0), "th_R": Vector3(0, 10, 0), "sh_R": Vector3(0, 16, 0),
}

## Attack styles: [anticipation, impact, recovery] partial poses merged over IDLE.
const STYLES := {
	"strike_light": [   # a short committed thrust of the club; the left hand points down the line of the thrust
		{"root": Vector3(-0.16, -0.08, 0), "spine": Vector3(0, -2, -14), "chest": Vector3(0, -4, -10), "hips": Vector3(0, 2, -12),
			"arm_up_R": Vector3(74, 26, 0), "arm_lo_R": Vector3(0, 0, 74), "arm_up_L": Vector3(-62, -30, 0), "arm_lo_L": Vector3(0, 0, -34),
			"th_L": Vector3(0, -16, 0), "sh_L": Vector3(0, 12, 0), "th_R": Vector3(0, 22, 0), "sh_R": Vector3(0, 30, 0), "head": Vector3(0, -10, 6)},
		{"root": Vector3(0.58, -0.10, 0), "spine": Vector3(0, 18, 16), "chest": Vector3(0, 14, 10), "hips": Vector3(0, 6, 14),
			"arm_up_R": Vector3(80, -60, 0), "arm_lo_R": Vector3(0, 0, 6), "arm_up_L": Vector3(-82, -56, 0), "arm_lo_L": Vector3(0, 0, -4),
			"th_L": Vector3(0, -42, 0), "sh_L": Vector3(0, 10, 0), "th_R": Vector3(0, 30, 0), "sh_R": Vector3(0, 6, 0), "head": Vector3(0, -16, -4)},
		{"root": Vector3(0.30, -0.06, 0), "spine": Vector3(0, 14, 4), "chest": Vector3(0, 10, 2),
			"arm_up_R": Vector3(76, -40, 0), "arm_lo_R": Vector3(0, 0, 26), "arm_up_L": Vector3(-76, -26, 0), "arm_lo_L": Vector3(0, 0, -16),
			"th_L": Vector3(0, -28, 0), "sh_L": Vector3(0, 14, 0), "th_R": Vector3(0, 20, 0), "sh_R": Vector3(0, 14, 0)}],
	"strike_heavy": [   # one-handed overhead slam; wings flare as the counterweight, the free arm swings back
		{"root": Vector3(-0.10, -0.18, 0), "spine": Vector3(0, -16, -24), "chest": Vector3(0, -14, -16), "hips": Vector3(0, 0, -20),
			"arm_up_R": Vector3(-52, -18, 0), "arm_lo_R": Vector3(0, 0, 58), "arm_up_L": Vector3(-34, 44, 0), "arm_lo_L": Vector3(0, 0, -20),
			"wing_L": Vector3(46, 0, 0), "wing_R": Vector3(-46, 0, 0), "wing2_L": Vector3(24, 0, 0), "wing2_R": Vector3(-24, 0, 0),
			"th_L": Vector3(0, -28, 0), "sh_L": Vector3(0, 34, 0), "th_R": Vector3(0, 26, 0), "sh_R": Vector3(0, 40, 0), "head": Vector3(0, -6, 8)},
		{"root": Vector3(0.64, -0.30, 0), "spine": Vector3(0, 40, 18), "chest": Vector3(0, 30, 12), "hips": Vector3(0, 8, 16),
			"arm_up_R": Vector3(46, -52, 0), "arm_lo_R": Vector3(0, 0, 8), "arm_up_L": Vector3(-22, 62, 0), "arm_lo_L": Vector3(0, 0, -6),
			"wing_L": Vector3(10, 0, 0), "wing_R": Vector3(-10, 0, 0),
			"th_L": Vector3(0, -46, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, 36, 0), "sh_R": Vector3(0, 16, 0), "head": Vector3(0, -22, -6)},
		{"root": Vector3(0.40, -0.26, 0), "spine": Vector3(0, 30, 6), "chest": Vector3(0, 22, 4),
			"arm_up_R": Vector3(60, -34, 0), "arm_lo_R": Vector3(0, 0, 30), "arm_up_L": Vector3(-56, 20, 0), "arm_lo_L": Vector3(0, 0, -14),
			"th_L": Vector3(0, -34, 0), "sh_L": Vector3(0, 30, 0), "th_R": Vector3(0, 26, 0), "sh_R": Vector3(0, 24, 0)}],
	"grab": [   # the thorned left forearm hooks and drags (raptorial grab); the club stays ready in the right hand
		{"root": Vector3(-0.14, -0.12, 0), "spine": Vector3(0, 6, 18), "chest": Vector3(0, 4, 12),
			"arm_up_L": Vector3(-30, 36, 0), "arm_lo_L": Vector3(0, 0, -64), "th_L": Vector3(0, -14, 0), "sh_L": Vector3(0, 24, 0)},
		{"root": Vector3(0.5, -0.12, 0), "spine": Vector3(0, 22, -16), "chest": Vector3(0, 16, -12),
			"arm_up_L": Vector3(-74, -76, 0), "arm_lo_L": Vector3(0, 0, -6), "th_L": Vector3(0, -40, 0), "sh_L": Vector3(0, 12, 0), "head": Vector3(0, -18, 0)},
		{"root": Vector3(0.3, -0.08, 0), "spine": Vector3(0, 14, -4), "arm_up_L": Vector3(-76, -40, 0), "arm_lo_L": Vector3(0, 0, -30)}],
	"ability": [   # club braced on the shoulder, the left hand flicks / commands
		{"root": Vector3(-0.08, -0.1, 0), "spine": Vector3(0, 2, 10), "chest": Vector3(0, 0, 8),
			"arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-24, -20, 0), "arm_lo_L": Vector3(0, 0, -36),
			"wing_L": Vector3(24, 0, 0), "wing_R": Vector3(-24, 0, 0)},
		{"root": Vector3(0.22, -0.1, 0), "spine": Vector3(0, 12, -12), "chest": Vector3(0, 8, -8),
			"arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-60, -70, 0), "arm_lo_L": Vector3(0, 0, -4),
			"wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0)},
		{"root": Vector3(0.1, -0.06, 0), "spine": Vector3(0, 10, -4), "arm_up_L": Vector3(-72, -30, 0), "arm_lo_L": Vector3(0, 0, -20)}],
}

const GUARD := {
	"root": Vector3(0.06, -0.12, 0), "spine": Vector3(0, 12, 0), "chest": Vector3(0, 10, 0), "head": Vector3(0, -12, 0),
	"arm_up_R": Vector3(80, -58, 0), "arm_lo_R": Vector3(0, 0, 96), "arm_up_L": Vector3(-82, -36, 0), "arm_lo_L": Vector3(0, 0, -52),
	"wing_L": Vector3(52, 0, 0), "wing_R": Vector3(-52, 0, 0), "wing2_L": Vector3(26, 0, 0), "wing2_R": Vector3(-26, 0, 0),
	"th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 32, 0), "th_R": Vector3(0, 14, 0), "sh_R": Vector3(0, 28, 0),
}
const DODGE := {   # a fold: collapse into a thin rod and slide, wings snapped shut
	"root": Vector3(-0.6, -0.16, 0), "spine": Vector3(0, 24, 0), "chest": Vector3(0, 16, 0), "head": Vector3(0, -14, 0),
	"arm_up_L": Vector3(-86, -4, 0), "arm_lo_L": Vector3(0, 0, -8), "arm_up_R": Vector3(84, -10, 0), "arm_lo_R": Vector3(0, 0, 14),
	"wing_L": Vector3(-16, 0, 0), "wing_R": Vector3(16, 0, 0),
	"th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 46, 0), "th_R": Vector3(0, -12, 0), "sh_R": Vector3(0, 44, 0),
}
const HIT := {
	"root": Vector3(-0.12, -0.04, 0), "spine": Vector3(0, -18, 8), "chest": Vector3(0, -14, 6), "neck": Vector3(0, 8, 0), "head": Vector3(0, 10, -8),
	"arm_up_L": Vector3(-58, 22, 0), "arm_up_R": Vector3(56, 12, 0), "wing_L": Vector3(20, 0, 0), "wing_R": Vector3(-20, 0, 0),
	"th_L": Vector3(0, -4, 0), "sh_L": Vector3(0, 22, 0), "th_R": Vector3(0, 12, 0), "sh_R": Vector3(0, 24, 0),
}
const STAGGER := {
	"root": Vector3(0.04, -0.26, 0), "spine": Vector3(0, 34, 6), "chest": Vector3(0, 26, 4), "head": Vector3(0, -6, 0),
	"arm_up_R": Vector3(86, -14, 0), "arm_lo_R": Vector3(0, 0, 6), "arm_up_L": Vector3(-70, -18, 0), "arm_lo_L": Vector3(0, 0, -30),
	"th_L": Vector3(0, -30, 0), "sh_L": Vector3(0, 52, 0), "th_R": Vector3(0, -14, 0), "sh_R": Vector3(0, 46, 0),
}
const KO := {
	"root": Vector3(-0.9, -1.35, 0), "hips": Vector3(0, -84, 0), "spine": Vector3(0, -10, 0), "head": Vector3(0, 12, 0),
	"arm_up_L": Vector3(-30, 10, 0), "arm_up_R": Vector3(30, 10, 0), "wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0),
	"th_L": Vector3(0, -6, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, -2, 0), "sh_R": Vector3(0, 30, 0),
}

static func merged(base: Dictionary, over: Dictionary) -> Dictionary:
	var d := base.duplicate()
	for k in over:
		d[k] = over[k]
	return d

static func compile(p: Dictionary) -> Dictionary:
	var d := p.duplicate()
	d.erase("root")
	return d

static func root_of(p: Dictionary) -> Vector3:
	return p.get("root", Vector3.ZERO)

static func mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := {}
	for k in a:
		out[k] = (a[k] as Vector3).lerp(b.get(k, Vector3.ZERO), w)
	for k in b:
		if not out.has(k):
			out[k] = Vector3.ZERO.lerp(b[k], w)
	return out

static func add(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = (out.get(k, Vector3.ZERO) as Vector3) + (b[k] as Vector3)
	return out

static func _full(over: Dictionary) -> Dictionary:
	return merged(IDLE, over)

static func _lerp_pose(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var r := mix(compile(a), compile(b), w)
	r["root"] = root_of(a).lerp(root_of(b), w)
	return r

static func _out_back(t: float) -> float:
	var c := 1.4
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)

static func _out(t: float, p: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), p)

static func _result(p: Dictionary) -> Dictionary:
	return {"bones": compile(p), "root": root_of(p)}

## action: sim action name, frame: frames into the action, tm: Vector3i(startup, active, recovery), walk_t: walk phase, t: seconds.
static func evaluate(action: String, frame: int, tm: Vector3i, walk_t: float, t: float, vit: float) -> Dictionary:
	var idle := _idle(t, vit)
	match action:
		"walk":
			return _result(_walk(idle, walk_t))
		"strike_light", "strike_heavy", "grab", "ability1", "ability2", "laststand":
			var key := action if STYLES.has(action) else "ability"
			if action == "laststand":
				key = "ability"
			return _result(_attack(idle, STYLES[key], frame, tm))
		"guard", "parry":
			return _result(_lerp_pose(idle, _full(GUARD), _out(float(frame + 1) / 4.0, 2.0)))
		"dodge":
			var d := maxi(1, tm.x + tm.y)
			var u := clampf(float(frame) / float(d), 0.0, 1.0)
			var back := _lerp_pose(_full(DODGE), idle, _out((float(frame) - float(d)) / maxf(1.0, float(tm.z)), 1.8) if frame > d else 0.0)
			return _result(_lerp_pose(idle, back, _out(u * 3.0, 2.0)))
		"hit", "clash":
			return _result(_lerp_pose(_full(HIT), idle, _out(float(frame) / maxf(10.0, float(tm.y + tm.z)), 2.0)))
		"stagger":
			return _result(_lerp_pose(idle, _full(STAGGER), _out(float(frame + 1) / 6.0, 2.0)))
		"ko", "knockdown":
			var u2 := clampf(float(frame) / maxf(1.0, float(tm.x + tm.y) * 0.6), 0.0, 1.0)
			var p := _lerp_pose(_full(STAGGER), _full(KO), _out(u2, 3.0))
			if action == "knockdown" and frame > tm.x + tm.y:
				p = _lerp_pose(_full(KO), idle, _out(float(frame - tm.x - tm.y) / maxf(1.0, float(tm.z)), 2.0))
			return _result(p)
	return _result(idle)

static func _idle(t: float, vit: float) -> Dictionary:
	var p := IDLE.duplicate()
	var br := sin(t * 2.1)
	p["spine"] = (p["spine"] as Vector3) + Vector3(0, 1.4 * br + (1.0 - vit) * 10.0, 0)
	p["chest"] = (p["chest"] as Vector3) + Vector3(0, 1.0 * br, 0)
	p["head"] = (p["head"] as Vector3) + Vector3(0, -0.8 * br, 1.5 * sin(t * 0.7))
	p["arm_up_L"] = (p["arm_up_L"] as Vector3) + Vector3(0.8 * br, 0, 0)
	p["wing_L"] = Vector3(4.0 + 2.0 * sin(t * 1.3), 0, 0)
	p["wing_R"] = Vector3(-4.0 - 2.0 * sin(t * 1.3 + 1.0), 0, 0)
	return p

static func _walk(idle: Dictionary, ph: float) -> Dictionary:
	var s := sin(ph)
	var c := cos(ph)
	var p := idle.duplicate()
	p["root"] = Vector3(0.0, -0.06 - 0.035 * absf(c), 0)
	p["hips"] = (p["hips"] as Vector3) + Vector3(0, 0, 7.0 * s)
	p["spine"] = (p["spine"] as Vector3) + Vector3(0, 0, -6.0 * s)
	p["chest"] = (p["chest"] as Vector3) + Vector3(0, 0, -4.0 * s)
	p["th_L"] = Vector3(0, -10.0 - 34.0 * s, 0)
	p["sh_L"] = Vector3(0, 14.0 + 26.0 * maxf(0.0, c * -1.0 * signf(s) * 0.0 + (-c)), 0)
	p["th_R"] = Vector3(0, 12.0 + 34.0 * s, 0)
	p["sh_R"] = Vector3(0, 16.0 + 26.0 * maxf(0.0, c), 0)
	p["arm_up_L"] = (p["arm_up_L"] as Vector3) + Vector3(0, 12.0 * s, 0)
	return p

static func _attack(idle: Dictionary, st: Array, frame: int, tm: Vector3i) -> Dictionary:
	var ant := _full(st[0])
	var hit := _full(st[1])
	var rec := _full(st[2])
	var s := maxi(1, tm.x)
	var a := maxi(1, tm.y)
	var r := maxi(1, tm.z)
	if frame < s:                                   # anticipation: slow in, hold, a tremble of held strength just before the strike
		var u := float(frame) / float(s)
		var w := u * u * (3.0 - 2.0 * u)
		w = pow(w, 1.35)
		var p := _lerp_pose(idle, ant, w)
		if u > 0.7:
			var tr := (u - 0.7) / 0.3
			p["spine"] = (p["spine"] as Vector3) + Vector3(0, 0, sin(float(frame) * 2.3) * 1.6 * tr)
		return p
	if frame < s + a:                               # impact: snap through the pose with overshoot
		var u2 := float(frame - s) / float(a)
		return _lerp_pose(ant, hit, _out_back(clampf(u2 * 2.0, 0.0, 1.0)))
	var u3 := float(frame - s - a) / float(r)       # recovery: settle out of the lunge, then return to stance
	if u3 < 0.6:
		return _lerp_pose(hit, rec, _out(u3 / 0.6, 2.2))
	return _lerp_pose(rec, idle, _out((u3 - 0.6) / 0.4, 1.6))
