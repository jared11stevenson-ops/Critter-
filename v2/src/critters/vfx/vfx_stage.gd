extends Node3D
## VFX registry + manager (BoutScene adds ONE of these under the arena). Visuals are driven by the REAL simulation, never decorative:
##   stage.ability(rig, move_id, phase)         called by CritterRig itself when `rig.vfx = stage` (tell / go at the active frame / end), sized from the MoveDef
##   stage.event(ev, rigs)                      sim events: hit block parry dodge ko teleport summon laststand stance tell (+ projectile zone trap handled by sync)
##   stage.sync(state, rigs, dt)                every frame with sim.state(): zones / traps / projectiles / summons (entity lists) and fighters[i].status
##                                              -> persistent effects whose radius = the entity's real radius and whose lifetime = its remaining ticks / 60
##   stage.tick(dt)                             advance (pass 0 during hit-stop); auto-called from _process unless `manual_tick` is true
## Budget: <= MAX_DRAWS quad draws alive at once (15; 8 on Low), no particle systems, so it is cheap on Low. quality: 0 low, 1 med, 2 high.
## Entity dict keys read (any missing key has a fallback): id, kind|type (zone trap projectile summon), owner (fighter idx), pos (Vector2 plane x,y),
##   radius, remaining|ttl|ticks_left (ticks), tag, move_id, angle (rad, plane), reach.

const Fx := preload("res://src/critters/vfx/vfx_fx.gd")
const Rec := preload("res://src/critters/vfx/vfx_recipes.gd")
const Pal := preload("res://src/critters/palettes.gd")
const Timing := preload("res://src/critters/timing.gd")

const TICKS := 60.0
var quality := 2
var manual_tick := false
var to_world: Callable = func(p: Vector2) -> Vector3: return Vector3(p.x, 0.0, p.y)   # sim plane (x, y) -> world; override if the arena maps differently
var fx_list: Array = []
var _keyed: Dictionary = {}

func max_draws() -> int:
	return [8, 12, 15][clampi(quality, 0, 2)]

func draws_alive() -> int:
	var n := 0
	for f in fx_list:
		n += (f as Fx).draw_count()
	return n

func _process(dt: float) -> void:
	if not manual_tick:
		tick(dt)

func tick(dt: float) -> void:
	for f in fx_list.duplicate():
		var fx: Fx = f
		fx.tick(dt)
		if fx.expire_at > 0.0 and fx.age >= fx.expire_at:
			fx.finish()
		if fx.done:
			fx_list.erase(fx)
			if fx.key != "" and _keyed.get(fx.key) == fx:
				_keyed.erase(fx.key)
			fx.queue_free()

func clear() -> void:
	for f in fx_list:
		(f as Node).queue_free()
	fx_list.clear()
	_keyed.clear()

func _ctx(critter: String, facing: float, extra: Dictionary = {}) -> Dictionary:
	var c := {"pal": Pal.get_pal(critter), "facing": facing, "reach": 5.0, "radius": 3.0, "dur": 1.2}
	c.merge(extra, true)
	return c

func _make(layers: Array, pos: Vector3, facing: float, key: String = "") -> Fx:
	if layers.is_empty():
		return null
	if quality == 0 and layers.size() > 2:
		layers = layers.slice(0, 2)
	var need := layers.size()
	while draws_alive() + need > max_draws() and not fx_list.is_empty():
		var victim: Fx = null
		for f in fx_list:
			if not (f as Fx).persist:
				victim = f
				break
		if victim == null:
			victim = fx_list[0]
		victim.done = true
		fx_list.erase(victim)
		if victim.key != "" and _keyed.get(victim.key) == victim:
			_keyed.erase(victim.key)
		victim.queue_free()
	var fx := Fx.new()
	add_child(fx)
	fx.position = pos
	fx.key = key
	for L in layers:
		fx.add_layer(L, facing)
	fx_list.append(fx)
	if key != "":
		_keyed[key] = fx
	return fx

## real numbers from the move data (reach, radius, duration), falling back to recipe defaults
func _move_ctx(critter: String, move_id: String, facing: float) -> Dictionary:
	var mv: Dictionary = Timing._move(critter, move_id)
	var ex := {}
	var hb: Dictionary = mv.get("hitbox", {})
	if hb.has("reach"):
		ex["reach"] = float(hb["reach"])
	if hb.has("radius"):
		ex["radius"] = float(hb["radius"])
	for sp in mv.get("spawns", []):
		if sp is Dictionary and sp.has("radius"):
			ex["radius"] = float(sp["radius"])
		if sp is Dictionary and sp.has("reach"):
			ex["reach"] = float(sp["reach"])
	var st: Dictionary = mv.get("stance", {})
	if st.has("frames"):
		ex["dur"] = float(st["frames"]) / TICKS
	elif mv.has("active"):
		ex["dur"] = maxf(float(mv["active"]) / TICKS, 0.5)
	return _ctx(critter, facing, ex)

func ability(rig: Node3D, move_id: String, phase: String, style: String = "") -> Fx:
	var critter: String = rig.critter_id
	var facing: float = rig._facing
	var ctx := _move_ctx(critter, move_id, facing)
	var rec: Dictionary = Rec.build(move_id, ctx)
	if rec.is_empty():
		rec = Rec.by_style(style if style != "" else Timing.tell_anim(critter, move_id, {}), ctx)
	var layers: Array = rec.get(phase, [])
	var fx := _make(layers, rig.global_position, facing)
	if fx != null and fx.persist:
		fx.expire_at = float(ctx["dur"]) + 0.2    # a held stance/zone ends with the move's real duration unless the sim state keeps it alive
	return fx

func event(ev: Dictionary, rigs: Array) -> void:
	var t := str(ev.get("type", ""))
	var fi := int(ev.get("fighter", 0))
	var rig: Node3D = rigs[fi] if fi < rigs.size() else null
	if rig == null:
		return
	var critter: String = rig.critter_id
	var facing: float = rig._facing
	var ctx := _ctx(critter, facing, {"heavy": bool(ev.get("heavy", false))})
	var wp: Vector3 = rig.global_position
	if ev.get("pos") is Vector2 and t in ["hit", "block", "parry", "teleport", "summon"]:
		wp = to_world.call(ev["pos"])
		if t in ["hit", "block", "parry"]:
			wp = rig.global_position     # sparks sit on the fighter who was struck/guarded
	match t:
		"hit", "block", "parry", "dodge", "ko", "teleport", "summon":
			_make(Rec.event_fx(t, critter, ctx), wp, facing)
		"laststand":
			var rec := Rec.build(str(ev.get("move_id", "")), _move_ctx(critter, str(ev.get("move_id", "")), facing))
			_make(rec.get("tell", []), rig.global_position, facing)
		"tell":
			var mid := str(ev.get("move_id", ""))
			if mid != "":
				var rc := Rec.build(mid, _move_ctx(critter, mid, facing))
				if not rc.is_empty() and rig.vfx != self:
					_make(rc.get("tell", []), rig.global_position, facing)

## Persistent, state-driven visuals. state = sim.state() (fighters[], plus any of zones / traps / projectiles / summons / entities arrays).
func sync(state: Dictionary, rigs: Array, _dt: float = 0.0) -> void:
	var seen: Dictionary = {}
	var lists: Array = []
	for k in ["zones", "traps", "projectiles", "summons", "entities"]:
		if state.get(k) is Array:
			lists.append([k, state[k]])
	for pair in lists:
		var idx := 0
		for e in pair[1]:
			if not (e is Dictionary):
				continue
			idx += 1
			var kind := str(e.get("kind", e.get("type", str(pair[0]).trim_suffix("s"))))
			var key := "ent:%s:%s" % [kind, str(e.get("id", "%s%d" % [e.get("tag", ""), idx]))]
			seen[key] = true
			var rem: float = float(e.get("remaining", e.get("ttl", e.get("ticks_left", 0.0)))) / TICKS
			var owner := int(e.get("owner", 0))
			var orig: Node3D = rigs[owner] if owner < rigs.size() else null
			var critter: String = orig.critter_id if orig != null else "aruun"
			var pos2 = e.get("pos", Vector2.ZERO)
			var wp: Vector3 = to_world.call(pos2) if pos2 is Vector2 else Vector3.ZERO
			var fx: Fx = _keyed.get(key)
			if fx == null:
				var mid := str(e.get("move_id", e.get("tag", "")))
				var ctx := _ctx(critter, 1.0, {"reach": 0.0, "radius": float(e.get("radius", 2.0)), "dur": maxf(rem, 0.3)})
				var layers: Array = []
				if kind == "projectile":
					layers = Rec.projectile_fx(critter, ctx)
				else:
					var rec := Rec.build(mid, ctx)
					for L in rec.get("go", []):
						if L.get("persist", false):
							layers.append(L)
					if layers.is_empty():
						layers = Rec.zone_fallback(critter, kind, ctx)
				fx = _make(layers, wp, 1.0, key)
				if fx == null:
					continue
			fx.position = wp
			if e.has("angle"):
				fx.rotation.y = -float(e["angle"])
			if rem > 0.0:
				fx.expire_at = fx.age + rem
	# fighter statuses on their owners for their real remaining time
	var fighters: Array = state.get("fighters", [])
	for i in range(mini(fighters.size(), rigs.size())):
		var sts = fighters[i].get("status", [])
		for s in sts:
			var nm := ""
			var rem2 := 0.0
			if s is Dictionary:
				nm = str(s.get("name", s.get("status", "")))
				rem2 = float(s.get("remaining", s.get("ticks", 0.0))) / TICKS
			else:
				nm = str(s)
			if nm == "":
				continue
			var key2 := "st:%d:%s" % [i, nm]
			seen[key2] = true
			var fx2: Fx = _keyed.get(key2)
			if fx2 == null:
				var layers2 := Rec.status_fx(nm, (rigs[i] as Node3D).get("critter_id"), _ctx((rigs[i] as Node3D).get("critter_id"), 1.0))
				fx2 = _make(layers2, (rigs[i] as Node3D).global_position, 1.0, key2)
				if fx2 == null:
					continue
				fx2.follow = rigs[i]
			if rem2 > 0.0:
				fx2.expire_at = fx2.age + rem2
	for key3 in _keyed.keys():
		if not seen.has(key3):
			(_keyed[key3] as Fx).finish()
			_keyed.erase(key3)
