extends RefCounted
## Pose key library. A pose = {part: PackedFloat32Array[rx,ry,rz, px,py,pz, sx,sy,sz]} (degrees / meters) relative to the
## critter's rest pose. Conventions: +X forward, +Y up, rotation about Z with positive = swing forward/up, negative body lean = forward.
## Attack poses are generated from "weapon axis angle" styles so one table drives all seven critters; each design
## supplies its rest weapon angle (`wa`) and any per-action overrides in its config.

const PARTS := ["body", "torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]
const ACTIONS := ["idle", "walk", "strike_light", "strike_heavy", "guard", "parry", "grab", "dodge", "ability1",
		"ability2", "laststand", "hit", "stagger", "ko"]
const IDENT := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0]

static func K(rx: float = 0.0, ry: float = 0.0, rz: float = 0.0, px: float = 0.0, py: float = 0.0, pz: float = 0.0,
		sx: float = 1.0, sy: float = 1.0, sz: float = 1.0) -> PackedFloat32Array:
	return PackedFloat32Array([rx, ry, rz, px, py, pz, sx, sy, sz])

## Swing style table. Each phase: th = weapon axis angle (deg, 0 = forward, 90 = up, 180 = back), lean = torso rz, brz = body rz,
## lunge = body px, crouch = body py, sy = body squash/stretch (volume kept), twist = torso yaw, head = head rz, legs = leg spread.
## fl: smear = draw swing trail during the active phase; shake = tremble amount at the end of anticipation.
const STYLES := {
	"overhead": {"smear": true, "shake": 0.5,
		"ant": {"th": 78, "lean": 14, "brz": 9, "lunge": -0.18, "crouch": -0.04, "sy": 1.1, "head": 16, "legs": 16},
		"strike": {"th": -28, "lean": -22, "brz": -8, "lunge": 0.5, "crouch": -0.05, "sy": 1.05, "head": -10, "legs": 30},
		"rec": {"th": -34, "lean": -12, "brz": -4, "lunge": 0.38, "crouch": -0.12, "sy": 0.84, "head": -6, "legs": 22}},
	"chop": {"smear": true, "shake": 0.3,
		"ant": {"th": 100, "lean": 8, "brz": 4, "lunge": -0.1, "sy": 1.04, "head": 8, "legs": 10},
		"strike": {"th": -12, "lean": -18, "brz": -8, "lunge": 0.34, "sy": 1.05, "head": -8, "legs": 24},
		"rec": {"th": -25, "lean": -8, "brz": -3, "lunge": 0.22, "crouch": -0.06, "sy": 0.9, "legs": 16}},
	"slash_up": {"smear": true, "shake": 0.2,
		"ant": {"th": -80, "lean": -10, "brz": -6, "lunge": -0.05, "crouch": -0.08, "sy": 0.9, "head": -6, "legs": 16},
		"strike": {"th": 85, "lean": 6, "brz": 6, "lunge": 0.4, "sy": 1.12, "twist": 18, "head": 8, "legs": 26},
		"rec": {"th": 70, "lean": 4, "brz": 2, "lunge": 0.28, "sy": 0.94, "legs": 18}},
	"slash_back": {"smear": true, "shake": 0.2,
		"ant": {"th": 70, "lean": 6, "brz": 5, "lunge": -0.1, "sy": 0.94, "twist": -18, "head": 8, "legs": 12},
		"strike": {"th": -40, "lean": -14, "brz": -6, "lunge": 0.42, "sy": 1.08, "twist": 22, "head": -8, "legs": 28},
		"rec": {"th": -30, "lean": -6, "lunge": 0.3, "sy": 0.92, "legs": 20}},
	"thrust": {"smear": true, "shake": 0.35, "ax": true,
		"ant": {"th": 10, "lean": 8, "brz": 4, "lunge": -0.22, "sy": 0.94, "head": 6, "legs": 12, "ax": -0.34},
		"strike": {"th": 4, "lean": -16, "brz": -8, "lunge": 0.5, "sy": 1.06, "head": -8, "legs": 32, "ax": 0.5},
		"rec": {"th": 8, "lean": -6, "brz": -2, "lunge": 0.32, "sy": 0.92, "legs": 20, "ax": 0.12}},
	"punch": {"smear": true, "shake": 0.4, "ax": true,
		"ant": {"th": -45, "lean": 10, "brz": 6, "lunge": -0.18, "sy": 0.93, "twist": -20, "head": 8, "legs": 12, "ax": -0.12},
		"strike": {"th": 5, "lean": -20, "brz": -9, "lunge": 0.46, "sy": 1.07, "twist": 26, "head": -8, "legs": 30, "ax": 0.28},
		"rec": {"th": -10, "lean": -8, "brz": -3, "lunge": 0.3, "sy": 0.9, "twist": 8, "legs": 20}},
	"charge": {"smear": true, "shake": 0.5,
		"ant": {"th": 20, "lean": -20, "brz": -14, "lunge": -0.25, "crouch": -0.18, "sy": 0.82, "head": -10, "legs": 22},
		"strike": {"th": 10, "lean": -34, "brz": -22, "lunge": 0.9, "crouch": -0.1, "sy": 0.94, "head": -14, "legs": 38},
		"rec": {"th": 10, "lean": -16, "brz": -8, "lunge": 0.5, "crouch": -0.1, "sy": 0.86, "legs": 22}},
	"roar": {"smear": false, "shake": 1.0,
		"ant": {"th": 0, "lean": -14, "brz": -6, "crouch": -0.22, "sy": 0.76, "head": -14, "legs": 22},
		"strike": {"th": 40, "lean": 22, "brz": 10, "crouch": 0.1, "sy": 1.2, "head": 24, "legs": 14},
		"rec": {"th": 30, "lean": 10, "brz": 4, "crouch": -0.04, "sy": 0.96, "head": 10, "legs": 12}},
	"spin": {"smear": true, "shake": 0.2,
		"ant": {"th": 120, "lean": 6, "brz": 4, "lunge": -0.1, "sy": 0.92, "twist": -50, "head": 8, "legs": 14},
		"strike": {"th": -40, "lean": -12, "brz": -6, "lunge": 0.3, "sy": 1.08, "twist": 70, "head": -8, "legs": 28},
		"rec": {"th": -10, "lean": -4, "lunge": 0.2, "sy": 0.9, "twist": 20, "legs": 18}},
	"stance": {"smear": false, "shake": 0.6,
		"ant": {"th": 40, "lean": -10, "brz": -4, "crouch": -0.12, "sy": 0.9, "head": -6, "legs": 20},
		"strike": {"th": 50, "lean": -12, "brz": -6, "crouch": -0.14, "sy": 0.88, "head": -8, "legs": 24},
		"rec": {"th": 30, "lean": -6, "crouch": -0.06, "sy": 0.94, "legs": 14}},
	"grab": {"smear": false, "shake": 0.3, "arms2": true,
		"ant": {"th": 60, "lean": 8, "brz": 4, "lunge": -0.18, "crouch": -0.1, "sy": 0.9, "head": 6, "legs": 16},
		"strike": {"th": 5, "lean": -26, "brz": -14, "lunge": 0.55, "crouch": -0.08, "sy": 1.02, "head": -14, "legs": 34},
		"rec": {"th": 15, "lean": -10, "brz": -4, "lunge": 0.3, "crouch": -0.1, "sy": 0.9, "legs": 20}},
	"hook": {"smear": true, "shake": 0.3, "arms2": false,
		"ant": {"th": -30, "lean": 10, "brz": 5, "lunge": -0.2, "sy": 0.92, "twist": -26, "head": 8, "legs": 14},
		"strike": {"th": 10, "lean": -22, "brz": -10, "lunge": 0.36, "sy": 1.06, "twist": 30, "head": -10, "legs": 30},
		"rec": {"th": -5, "lean": -8, "lunge": 0.2, "sy": 0.92, "twist": 8, "legs": 18}},
	"leap": {"smear": true, "shake": 0.3,
		"ant": {"th": 120, "lean": 12, "brz": 8, "lunge": -0.2, "crouch": -0.2, "sy": 0.78, "head": 10, "legs": 22},
		"strike": {"th": -70, "lean": -30, "brz": -30, "lunge": 0.9, "crouch": 0.7, "sy": 1.18, "head": -16, "legs": 44},
		"rec": {"th": -60, "lean": -16, "brz": -8, "lunge": 0.55, "crouch": -0.08, "sy": 0.82, "legs": 24}},
}

static func _mk(p: Dictionary, wa: float, cfg: Dictionary) -> Dictionary:
	var sy: float = p.get("sy", 1.0)
	var sx: float = 1.0 / sqrt(sy)
	var th: float = p.get("th", wa) - wa
	var legs: float = p.get("legs", 0.0)
	var ax: float = p.get("ax", 0.0)
	var out := {
		"body": K(0, 0, p.get("brz", 0.0), p.get("lunge", 0.0), p.get("crouch", 0.0), 0, sx, sy, sx),
		"torso": K(0, p.get("twist", 0.0), p.get("lean", 0.0)),
		"head": K(0, 0, p.get("head", 0.0)),
		"arm_f": K(0, 0, th, ax, 0, 0),
		"leg_f": K(0, 0, legs), "leg_b": K(0, 0, -legs),
		"extra": K(0, 0, -p.get("lunge", 0.0) * 55.0 - p.get("lean", 0.0) * 0.7),
	}
	if cfg.get("arm_b_follow", false):
		out["arm_b"] = K(0, 0, th, ax, 0, 0)
	else:
		out["arm_b"] = K(0, 0, -th * 0.3 + p.get("armb", 0.0), 0, 0, 0)
	return out

## Returns {ant, strike, rec, hold, smear, shake, kind} for an action using the critter cfg.
static func keys_for(action: String, cfg: Dictionary) -> Dictionary:
	var wa: float = cfg.get("wa", -90.0)
	var styles: Dictionary = cfg.get("style", {})
	var ov: Dictionary = cfg.get("poses", {})
	var out := {"hold": false, "smear": false, "shake": 0.0}
	var sname: String = styles.get(action, "")
	if sname == "":
		match action:
			"strike_light": sname = "chop"
			"strike_heavy": sname = "overhead"
			"ability1": sname = "roar"
			"ability2": sname = "thrust"
			"laststand": sname = "roar"
			"grab": sname = "grab"
	var amp: float = cfg.get("amp", {}).get(action, 1.0)
	match action:
		"strike_light", "strike_heavy", "ability1", "ability2", "laststand", "grab":
			var st: Dictionary = STYLES[sname]
			for k in ["ant", "strike", "rec"]:
				var ph: Dictionary = (st[k] as Dictionary).duplicate()
				for n in ["lean", "brz", "lunge", "crouch", "twist", "head", "legs", "ax"]:
					if ph.has(n):
						ph[n] = float(ph[n]) * amp
				if ph.has("sy"):
					ph["sy"] = 1.0 + (float(ph["sy"]) - 1.0) * amp
				out[k] = _mk(ph, wa, cfg)
			out["smear"] = st.get("smear", false)
			out["shake"] = st.get("shake", 0.0)
			if st.get("arms2", false):
				for k in ["ant", "strike", "rec"]:
					out[k]["arm_b"] = (out[k]["arm_f"] as PackedFloat32Array).duplicate()
		"guard":
			out["hold"] = true
			var g := {"th": cfg.get("guard_th", 55.0), "lean": -8, "brz": -3, "crouch": -0.08, "sy": 0.93, "legs": 12, "head": -4}
			out["ant"] = _mk(g, wa, cfg)
			out["strike"] = out["ant"]
			out["rec"] = out["ant"]
			if cfg.get("arm_b_follow", false) == false:
				out["ant"]["arm_b"] = K(0, 0, 50.0, 0.1, 0, 0)
		"parry":
			var g := {"th": cfg.get("guard_th", 55.0), "lean": -8, "brz": -3, "crouch": -0.08, "sy": 0.93, "legs": 12}
			var s := {"th": cfg.get("parry_th", 20.0), "lean": -20, "brz": -9, "lunge": 0.3, "sy": 1.08, "legs": 26, "head": -10}
			var r := {"th": cfg.get("guard_th", 55.0), "lean": -10, "lunge": 0.12, "crouch": -0.06, "sy": 0.94, "legs": 16}
			out["ant"] = _mk(g, wa, cfg); out["strike"] = _mk(s, wa, cfg); out["rec"] = _mk(r, wa, cfg)
			out["smear"] = true
		"dodge":
			var a := {"th": wa, "lean": 14, "brz": 14, "lunge": -0.2, "crouch": -0.2, "sy": 0.74, "head": 10, "legs": 24}
			var s := {"th": wa + 25.0, "lean": -22, "brz": -26, "lunge": 0.95, "crouch": 0.04, "sy": 0.78, "head": -12, "legs": 40}
			var r := {"th": wa, "lean": -6, "brz": -4, "lunge": 0.6, "crouch": -0.1, "sy": 0.88, "legs": 20}
			out["ant"] = _mk(a, wa, cfg); out["strike"] = _mk(s, wa, cfg); out["rec"] = _mk(r, wa, cfg)
		"hit":
			var a := {"th": wa, "lean": 10, "brz": 12, "lunge": -0.18, "sy": 0.84, "head": 22, "legs": 10, "armb": 30}
			var s := {"th": wa, "lean": 14, "brz": 16, "lunge": -0.26, "sy": 0.88, "head": 26, "legs": 14, "armb": 40}
			var r := {"th": wa, "lean": 4, "brz": 4, "lunge": -0.08, "sy": 0.96, "head": 8}
			out["ant"] = _mk(a, wa, cfg); out["strike"] = _mk(s, wa, cfg); out["rec"] = _mk(r, wa, cfg)
		"stagger":
			out["hold"] = true
			var a := {"th": wa - 15.0, "lean": 18, "brz": 10, "lunge": -0.1, "crouch": -0.08, "sy": 0.9, "head": 30, "legs": 8, "armb": 35}
			out["ant"] = _mk(a, wa, cfg); out["strike"] = out["ant"]; out["rec"] = out["ant"]
		"ko":
			out["hold"] = true
			var a := {"th": wa + 30.0, "lean": 8, "brz": 18, "lunge": -0.3, "crouch": 0.1, "sy": 1.05, "head": 20, "legs": 20}
			var s := {"th": wa + 40.0, "lean": 6, "brz": 98, "lunge": -0.55, "crouch": 0.05, "sy": 1.0, "head": 14, "legs": 18, "armb": 50}
			out["ant"] = _mk(a, wa, cfg); out["strike"] = _mk(s, wa, cfg); out["rec"] = out["strike"]
		_:
			var z := {"th": wa}
			out["ant"] = _mk(z, wa, cfg); out["strike"] = out["ant"]; out["rec"] = out["ant"]
	# per-critter overrides: ov[action][key][part] = K(...)
	if ov.has(action):
		for k in (ov[action] as Dictionary):
			if k in ["ant", "strike", "rec"]:
				for part in (ov[action][k] as Dictionary):
					if out[k] == out["ant"] and k != "ant":
						out[k] = (out["ant"] as Dictionary).duplicate()
					out[k][part] = ov[action][k][part]
			else:
				out[k] = ov[action][k]
	return out

static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for part in PARTS:
		var pa = a.get(part, null)
		var pb = b.get(part, null)
		if pa == null and pb == null:
			continue
		var fa: PackedFloat32Array = pa if pa != null else PackedFloat32Array(IDENT)
		var fb: PackedFloat32Array = pb if pb != null else PackedFloat32Array(IDENT)
		var r := PackedFloat32Array()
		r.resize(9)
		for i in range(9):
			r[i] = lerpf(fa[i], fb[i], t)
		out[part] = r
	return out

static func copy(pose: Dictionary) -> Dictionary:
	var out := {}
	for part in pose:
		out[part] = (pose[part] as PackedFloat32Array).duplicate()
	return out
