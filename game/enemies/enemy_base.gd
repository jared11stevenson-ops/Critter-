class_name EnemyBase
extends CritterActor
## Shared enemy body + AI scaffold. Collision layer 3, mask 1|4.
## Every attack is preceded by visual.play_telegraph(t) (≥ 0.45 s) and a ground telegraph.

signal removed(enemy)

var cfg: Dictionary = {}
var state := "idle"
var state_t := 0.0
var target: Node = null
var aggro := false
var home := Vector3.ZERO
var fly_height := -1.0
var speed := 3.0
var accel := 20.0
var _telegraph: Node = null
var _attack_point := Vector3.ZERO
var _windup_total := 0.5
var _desired := Vector3.ZERO
var _think_t := 0.0
var _contained := false
var drops_enabled := true
var _rid := 0

static func create(species: String) -> EnemyBase:
	var e: EnemyBase
	match species:
		"skitter_mite": e = SkitterMite.new()
		"plate_beetle": e = PlateBeetle.new()
		"dust_grazer": e = DustGrazer.new()
		"dominion_drone": e = DominionDrone.new()
		"resonance_pylon": e = ResonancePylon.new()
		"augur_rig": e = AugurRig.new()
		_: e = SkitterMite.new()
	e.species_id = species
	return e

func _ready() -> void:
	_actor_ready()
	cfg = Balance.section("enemies." + species_id)
	max_hp = float(cfg.get("hp", 50))
	if species_id != "dust_grazer" and species_id != "resonance_pylon" and species_id != "augur_rig":
		max_hp *= Director.enemy_hp_mult()
	hp = max_hp
	poise = float(cfg.get("poise", 0))
	speed = float(cfg.get("speed", 3.0))
	body_radius = float(cfg.get("radius", 0.5))
	var sp := Canon.species(species_id)
	display_name = str(sp.get("name", species_id.capitalize()))
	wild = sp.get("class", "") == "WILDLIFE" and not bool(sp.get("sapient", false))
	team = "enemy"
	collision_layer = 4
	collision_mask = 1 | 8
	visual = _make_visual()
	add_child(visual)
	if visual.has_method("get_radius"):
		var r: float = float(visual.get_radius())
		if r > 0.05:
			body_radius = r
	height = float(visual.get_height()) if visual.has_method("get_height") else body_radius * 1.6
	if height <= 0.05:
		height = body_radius * 1.6
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = body_radius * 0.85
	cap.height = maxf(cap.radius * 2.0 + 0.05, minf(height, 2.4))
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	home = global_position
	_rid = randi() % 1000
	_think_t = randf() * 0.2
	if Field.current:
		Field.current.register_enemy(self)
	_enemy_ready()

func _enemy_ready() -> void:
	pass

## Subclasses with their own look (Ledger Rivals) override this.
func _make_visual() -> Node3D:
	return VisualFactory.creature(species_id)

func _exit_tree() -> void:
	if Field.current:
		Field.current.unregister_enemy(self)
	_cancel_telegraph()

func hostile_now() -> bool:
	return aggro and alive and state != "flee" and state != "calm"

func is_winding_up() -> bool:
	return state == "windup"

# ---------------- loop ----------------
func _physics_process(delta: float) -> void:
	if not alive:
		return
	tick_statuses(delta)
	state_t += delta
	if is_stunned():
		if state == "windup":
			_cancel_telegraph()
			_set_state("recover")
		_desired = Vector3.ZERO
	else:
		_think_t -= delta
		_think(delta)
	body_move(_desired, accel, accel, delta, fly_height)
	var hs := Vector2(velocity.x, velocity.z).length()
	vis("set_move_amount", clampf(hs / maxf(0.1, speed), 0.0, 1.0))
	if hs > 0.4 and state != "windup" and state != "attack" and knock.length_squared() < 1.0:
		face_toward(Vector3(velocity.x, 0, velocity.z))
	if global_position.y < -20.0:
		_fall_out()

func _think(_delta: float) -> void:
	pass

func _set_state(s: String) -> void:
	state = s
	state_t = 0.0

func _fall_out() -> void:
	alive = false
	drops_enabled = false
	died.emit(self)
	Events.actor_died.emit(self)
	_remove(0.0)

# ---------------- helpers ----------------
func pick_target() -> Node:
	if Field.current == null:
		return null
	return Field.current.enemy_pick_target(global_position, float(cfg.get("aggro", 14.0)) * (1.6 if aggro else 1.0))

func flat_to(p: Vector3) -> Vector3:
	var d := p - global_position
	d.y = 0
	return d

func separation() -> Vector3:
	var f := Field.current
	if f == null:
		return Vector3.ZERO
	var push := Vector3.ZERO
	for e in f.enemies:
		if e == self or not is_instance_valid(e) or not e.alive:
			continue
		var d: Vector3 = global_position - e.global_position
		d.y = 0
		var r: float = body_radius + e.body_radius + 0.3
		var l := d.length()
		if l < r and l > 0.001:
			push += d / l * (r - l) / r
	return push

func start_windup(t: float, point: Vector3) -> void:
	_windup_total = maxf(0.45, t)
	_attack_point = point
	_set_state("windup")
	vis("play_telegraph", _windup_total)

func _cancel_telegraph() -> void:
	if _telegraph and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

## Brain Skip: current action is skipped.
func skip_action() -> void:
	_cancel_telegraph()
	if state == "windup" or state == "attack":
		_set_state("recover")

## Premonition: where this enemy will be / where its next attack lands.
func future_point(lead: float) -> Vector3:
	if state == "windup" or state == "attack":
		return _attack_point
	var p := global_position + Vector3(velocity.x, 0, velocity.z) * lead
	return p

func future_facing() -> Vector3:
	if state == "windup":
		return flat_to(_attack_point)
	return facing

func make_ghost_visual() -> Node3D:
	var g := VisualFactory.creature(species_id)
	VisualFactory.call_v(g, "set_ghost", [0.42])
	return g

func hit_party_in_radius(center: Vector3, radius: float, hit: Dictionary) -> int:
	var f := Field.current
	if f == null:
		return 0
	var n := 0
	for d in f.decoys:
		if is_instance_valid(d) and d.alive and d.global_position.distance_to(center) < radius + 0.5:
			d.receive_hit(hit)
	for p in f.party_members:
		if not is_instance_valid(p) or not p.is_targetable():
			continue
		var dd := Vector2(p.global_position.x - center.x, p.global_position.z - center.z).length()
		if dd < radius + p.body_radius:
			var h := hit.duplicate()
			h["dir"] = flat_to(p.global_position).normalized()
			p.receive_hit(h)
			n += 1
	return n

func make_hit(amount: float, kind: String = "light", extra: Dictionary = {}) -> Dictionary:
	var h := {"amount": amount * Director.enemy_damage_mult(), "source": self, "kind": kind, "can_crit": false, "feel": true}
	for k in extra:
		h[k] = extra[k]
	return h

# ---------------- damage reactions ----------------
func _on_hit(hit: Dictionary, _amount: float) -> void:
	if not aggro and not passive:
		aggro = true
		var src: Node = hit.get("source", null)
		if src and src.get("team") == "party":
			target = src
	if Field.current and Field.current.level and Field.current.level.has_method("on_enemy_hit"):
		Field.current.level.on_enemy_hit(self, hit)

func _on_staggered() -> void:
	if state == "windup":
		_cancel_telegraph()
		_set_state("recover")

func _on_zero_hp(hit: Dictionary) -> void:
	_cancel_telegraph()
	super._on_zero_hp(hit)
	if drops_enabled:
		_drop_loot()
	var t := 0.6
	var r: Variant = vis("play_die")
	if r != null:
		t = float(r)
	Audio.sfx_at("explosion" if species_id == "dominion_drone" else "hit_shell", global_position)
	collision_layer = 0
	_remove(t)

func _drop_loot() -> void:
	var drops: Dictionary = Balance.section("drops." + species_id)
	for item in drops:
		if randf() < float(drops[item]):
			if Field.current and Field.current.level and Field.current.level.has_method("spawn_pickup"):
				Field.current.level.spawn_pickup(item, global_position + Vector3(randf_range(-0.6, 0.6), 0.3, randf_range(-0.6, 0.6)), 1)

## Wild Containment: removed from the field and sent to the Terrarium.
func contained() -> void:
	_contained = true
	alive = false
	_cancel_telegraph()
	collision_layer = 0
	Events.actor_died.emit(self)
	died.emit(self)
	vis("set_ghost", 0.5)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(_remove.bind(0.0))

func was_contained() -> bool:
	return _contained

func _remove(after: float) -> void:
	if Field.current:
		Field.current.unregister_enemy(self)
	removed.emit(self)
	if after > 0.0:
		await get_tree().create_timer(after, false).timeout
	if is_instance_valid(self):
		queue_free()

## Leave peacefully (flee / calm): walk off, fade, free. Not a kill.
func leave_peacefully(dir: Vector3, t: float = 3.0) -> void:
	_set_state("calm")
	aggro = false
	_desired = dir.normalized() * speed
	await get_tree().create_timer(t, false).timeout
	if not is_instance_valid(self) or not alive:
		return
	alive = false
	collision_layer = 0
	removed.emit(self)
	if Field.current:
		Field.current.unregister_enemy(self)
	vis("set_ghost", 0.6)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.6, 0.6, 0.6), 0.5)
	tw.tween_callback(queue_free)
