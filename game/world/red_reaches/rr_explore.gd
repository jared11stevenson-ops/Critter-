class_name RrExplore
extends Node
## Red Reaches exploration layer. Opens the road up without touching the story beats:
##  - Places: discoverable points of interest (data: rr_explore.json "places" + the region's spokes). First visit toasts,
##    unlocks codex pages, records a Ledger discovery and unlocks a fast-travel waypoint.
##  - Guidance: a soft target ladder (never a forced order) + faint hints for hidden secrets, drawn by ExploreHud.
##  - Fast travel: Gate Map stub. Waypoints you have found; refuses mid-fight, mid-burden, behind a story barrier.
##  - Traversal: climb links (leader hops a cliff cut between side areas; partner follows). Reuses PlayableCritter.start_leap.
##  - Roaming encounters: small mite / drone / beetle groups appear in data-defined zones, never in view, capped, with a
##    growing respawn cooldown and a clear limit per descent. Common pickups regrow each descent.
## Cost: one 0.5 s discovery tick, one 1 s roaming tick, one enemy spawned per frame at most; no per-frame allocation.

const DATA := "res://game/world/red_reaches/rr_explore.json"
const LAYOUT := "res://game/world/red_reaches/layout.json"

signal discovered(poi_id: String)

var level                       # the Red Reaches level script (duck-typed host)
var data: Dictionary = {}
var floors: Array = []
var pois: Array = []             # {id,name,pos:Vector3,r,kind,codex,spoke,wp:Vector3,wp_req}
var hud: ExploreHud = null
var clock := 0.0

var _poi_t := 0.0
var _roam_t := 0.0
var _zones: Array = []
var _spawn_queue: Array = []
var _rng := RandomNumberGenerator.new()
var _travel_ready_at := 0.0
var _hinted: Dictionary = {}
var _traveling := false

# ---------------------------------------------------------------- static data helpers (used by tests, too)
static func load_data() -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA)) if FileAccess.file_exists(DATA) else null
	return d if d is Dictionary else {}

static func load_floors() -> Array:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT)) if FileAccess.file_exists(LAYOUT) else null
	return (d as Dictionary).get("floors", []) if d is Dictionary else []

## Collected common pickups grow back on every descent (uncommon+ ones stay taken). Returns how many flags were cleared.
static func regrow_common_loot(extra: Dictionary, layout: Dictionary, table: Array) -> int:
	var common: Dictionary = {}
	for row in table:
		if str(row.get("rarity", "common")) == "common":
			common[str(row["item"])] = true
	var n := 0
	var li := 0
	for lt in extra.get("loot", []):
		var k := "_loot_%d" % li
		li += 1
		if common.has(str(lt["item"])) and bool(GameState.flags.get(k, false)):
			GameState.flags.erase(k)
			n += 1
	var i := 0
	for pk in layout.get("pickups", []):
		var k2 := "_pk_%d" % i
		i += 1
		if common.has(str(pk["kind"])) and bool(GameState.flags.get(k2, false)):
			GameState.flags.erase(k2)
			n += 1
	return n

# ---------------------------------------------------------------- setup
func setup(lvl) -> void:
	level = lvl
	_rng.randomize()
	data = load_data()
	floors = load_floors()
	if data.is_empty():
		return
	_build_pois()
	_build_zones()
	hud = ExploreHud.new()
	hud.name = "ExploreHud"
	hud.setup(self)
	add_child(hud)

func _build_pois() -> void:
	for p in data.get("places", []):
		var pp: Array = p["pos"]
		var rec := {"id": str(p["id"]), "name": str(p["name"]), "pos": Vector3(float(pp[0]), 0.0, float(pp[1])), "r": float(p.get("r", data.get("discover_r", 16.0))),
			"kind": "place", "codex": str(p.get("codex", "")), "spoke": false, "wp_req": str(p.get("waypoint_requires", ""))}
		if p.has("waypoint"):
			rec["wp"] = Vector3(float(p["waypoint"][0]), 0.0, float(p["waypoint"][1]))
		pois.append(rec)
	var rg: Variant = level.get("region")
	if rg != null:
		var wps: Dictionary = data.get("spoke_waypoints", {})
		for sp in rg.recipe.get("spokes", []):
			var tp: Array = sp["trigger"]["pos"]
			var rec := {"id": str(sp["id"]), "name": str(sp.get("name", sp["id"])), "pos": Vector3(float(tp[0]), 0.0, float(tp[2])), "r": float(sp["trigger"].get("r", 8.0)),
				"kind": "spoke", "codex": "", "spoke": true, "wp_req": ""}
			if wps.has(str(sp["id"])):
				rec["wp"] = Vector3(float(wps[sp["id"]][0]), 0.0, float(wps[sp["id"]][1]))
			pois.append(rec)

func _build_zones() -> void:
	for z in data.get("roaming", {}).get("zones", []):
		_zones.append({"def": z, "live": [], "clears": 0, "next_ok": float(z.get("initial_delay_s", 120)), "retired": false, "ref_h": 0.0})

# ---------------------------------------------------------------- discovery
func poi_flag(p: Dictionary) -> String:
	return ("_spoke_" if bool(p["spoke"]) else "_poi_") + str(p["id"])

func is_discovered(p: Dictionary) -> bool:
	return bool(GameState.flags.get(poi_flag(p), false))

func found_count() -> int:
	var n := 0
	for p in pois:
		if is_discovered(p):
			n += 1
	return n

func discover(p: Dictionary) -> void:
	if is_discovered(p):
		return
	GameState.flags[poi_flag(p)] = true
	if str(p["codex"]) != "":
		GameState.unlock_codex(str(p["codex"]))
	Ledger.record("discovered", "player", str(p["id"]), ["discovery", "curiosity"], {}, 1, "red_reaches")
	Events.toast.emit("Discovered: %s (%d/%d places)" % [p["name"], found_count(), pois.size()], "codex")
	Audio.sfx("ui_confirm")
	discovered.emit(str(p["id"]))
	if found_count() == pois.size() and not bool(GameState.get_flag("rr_charted", false)):
		GameState.set_flag("rr_charted", true)
		Events.toast.emit("The Reaches are charted. Every road you walked is on the map.", "info")

func _discover_tick(lp: Vector3) -> void:
	for p in pois:
		if bool(p["spoke"]):
			continue        # spokes announce themselves through RegionRunner.enter_spoke
		if is_discovered(p):
			continue
		var pp: Vector3 = p["pos"]
		if Vector2(lp.x - pp.x, lp.z - pp.z).length() <= float(p["r"]):
			discover(p)
	# chart the ground as it is walked (minimap fog)
	for f in floors:
		var fk := "_seen_" + str(f["id"])
		if not bool(GameState.flags.get(fk, false)) and ExploreRules.shape_dist(f, lp.x, lp.z) < float(data.get("discover_r", 16.0)) * 0.6:
			GameState.flags[fk] = true
	_secret_hints(lp)

func floor_seen(f: Dictionary) -> bool:
	return bool(GameState.flags.get("_seen_" + str(f["id"]), false))

## Hidden secrets: when you are close and have not found one, say its hint once ("hot"), and let the minimap pulse.
func hot_secrets(lp: Vector3) -> Array:
	var out: Array = []
	var rg: Variant = level.get("region")
	if rg == null:
		return out
	var hr := float(data.get("secret_hint_r", 24.0))
	for sc in rg.recipe.get("secrets", []):
		var t: Dictionary = sc.get("trigger", {})
		if not (t.get("pos") is Array) or not rg.secret_ready(sc):
			continue
		var tp: Array = t["pos"]
		if Vector2(lp.x - float(tp[0]), lp.z - float(tp[2])).length() <= hr:
			out.append({"id": str(sc["id"]), "pos": Vector3(float(tp[0]), 0.0, float(tp[2])), "hint": str(sc.get("hint", ""))})
	return out

func _secret_hints(lp: Vector3) -> void:
	for h in hot_secrets(lp):
		if _hinted.has(h["id"]) or str(h["hint"]) == "":
			continue
		_hinted[h["id"]] = true
		Events.toast.emit("You sense something: " + str(h["hint"]), "info")

# ---------------------------------------------------------------- guidance
## The soft "where next" target (the story ladder), as a world position; Vector3.INF if none.
func guide_target() -> Vector3:
	for g in data.get("guide", []):
		if not bool(GameState.get_flag(str(g["flag"]), false)):
			var m: Vector3 = level.marker(str(g["marker"]))
			return m if m != Vector3.ZERO else Vector3.INF
	if str(GameState.get_flag("ochre_span", "")) == "":
		return level.marker("choice_point")
	return level.marker("exfil_beacon")

# ---------------------------------------------------------------- fast travel (Gate Map stub)
func waypoints() -> Array:
	var out: Array = []
	var g: Dictionary = data.get("gate_landing", {})
	if not g.is_empty():
		out.append({"id": "gate_landing", "name": str(g["name"]), "pos": Vector3(float(g["pos"][0]), 0.0, float(g["pos"][1])), "unlocked": true})
	for p in pois:
		if not p.has("wp"):
			continue
		var unlocked := is_discovered(p)
		if unlocked and str(p["wp_req"]) != "" and not bool(GameState.get_flag(str(p["wp_req"]), false)):
			unlocked = false
		out.append({"id": str(p["id"]), "name": str(p["name"]), "pos": p["wp"], "unlocked": unlocked})
	return out

func hostile_near(lp: Vector3, r: float) -> bool:
	var f: Variant = level.get("field")
	if f == null:
		return false
	for e in f.enemies:
		if is_instance_valid(e) and e.get("team") == "enemy" and e.get("alive") != false and e.get("aggro") == true:
			if Vector2(lp.x - e.global_position.x, lp.z - e.global_position.z).length() < r:
				return true
	return false

## "" when the party can travel to `wp_id` right now, else a short reason.
func travel_reason(wp_id: String) -> String:
	var wp: Dictionary = {}
	for w in waypoints():
		if w["id"] == wp_id:
			wp = w
	if wp.is_empty() or not bool(wp["unlocked"]):
		return "Not found yet"
	if _traveling:
		return "Travelling"
	var party: Variant = level.get("party")
	if party == null or party.get_leader() == null:
		return "No party"
	var lp: Vector3 = party.get_leader().global_position
	var dest: Vector3 = wp["pos"]
	if clock < _travel_ready_at:
		return "Catch your breath (%ds)" % int(ceil(_travel_ready_at - clock))
	if bool(level.get("burden_active")) or bool(level.get("_run_ended")):
		return "Not now"
	var f: Variant = level.get("field")
	if f != null and (bool(f.get("boss_active")) or bool(f.get("in_combat"))):
		return "In combat"
	if hostile_near(lp, float(data.get("travel", {}).get("enemy_block_r", 30.0))):
		return "Enemies nearby"
	var rv: Variant = level.get("rivals")
	if rv != null and not rv.live.is_empty() and rv.any_engaged():
		return "A rival is on you"
	if not level.can_partner_reach(lp, dest):
		return "The way is blocked"
	if Vector2(lp.x - dest.x, lp.z - dest.z).length() < 6.0:
		return "You are here"
	return ""

func travel(wp_id: String) -> String:
	var why := travel_reason(wp_id)
	if why != "":
		return why
	var dest := Vector3.ZERO
	for w in waypoints():
		if w["id"] == wp_id:
			dest = w["pos"]
	_traveling = true
	var party: Variant = level.get("party")
	party.input_enabled = false
	var fade: ColorRect = level.get("_fade")
	var tw := create_tween()
	if fade:
		tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_arrive.bind(dest))
	if fade:
		tw.tween_property(fade, "color:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		party.input_enabled = true
		_traveling = false)
	return ""

func _arrive(dest: Vector3) -> void:
	var party: Variant = level.get("party")
	var l: PlayableCritter = party.get_leader()
	var p: PlayableCritter = party.get_partner()
	l.teleport(level.ground(dest, 0.3))
	if p:
		p.teleport(level.ground(dest + Vector3(-2.0, 0, 1.2), 0.3))
	party.clear_trail()
	level.get("cam").set_target(l, true)
	_travel_ready_at = clock + float(data.get("travel", {}).get("cooldown_s", 10.0))
	_clear_roamers_near(dest, 28.0)
	Audio.sfx("ui_confirm")

# ---------------------------------------------------------------- traversal
func interactables() -> Array:
	var out: Array = []
	for l in data.get("links", []):
		for dir in 2:
			var a: Array = l["a"] if dir == 0 else l["b"]
			out.append({"id": "tl_%s_%d" % [l["id"], dir], "pos": Vector3(float(a[0]), 0.0, float(a[1])), "r": 2.8,
				"label": str(l["label_ab"] if dir == 0 else l["label_ba"]), "cond": _link_ok.bind(l, dir), "act": _do_link.bind(l, dir)})
	return out

func link_ends(l: Dictionary, dir: int) -> Array:
	var a: Array = l["a"] if dir == 0 else l["b"]
	var b: Array = l["b"] if dir == 0 else l["a"]
	return [Vector3(float(a[0]), 0.0, float(a[1])), Vector3(float(b[0]), 0.0, float(b[1]))]

func _link_ok(l: Dictionary, dir: int) -> bool:
	var party: Variant = level.get("party")
	if party == null or party.get_leader() == null or bool(level.get("burden_active")):
		return false
	var e := link_ends(l, dir)
	return not level._barrier_blocks(e[0], e[1])

func _do_link(l: Dictionary, dir: int) -> void:
	var party: Variant = level.get("party")
	var lead: PlayableCritter = party.get_leader()
	if lead.downed or lead.state != "normal":
		return
	var e := link_ends(l, dir)
	var dest: Vector3 = level.ground(e[1], 0.3)
	lead.start_leap(dest, float(l.get("dur", 1.3)), float(l.get("h", 5.0)), _link_landed.bind(l, dest))

func _link_landed(l: Dictionary, dest: Vector3) -> void:
	var party: Variant = level.get("party")
	var p: PlayableCritter = party.get_partner()
	if p:
		p.teleport(level.ground(dest + Vector3(-1.6, 0, 1.0), 0.3))
	party.clear_trail()
	var k := "_trav_" + str(l["id"])
	if not bool(GameState.flags.get(k, false)):
		GameState.flags[k] = true
		Events.toast.emit("Shortcut: %s. Both ways now." % str(l.get("name", "")), "info")

# ---------------------------------------------------------------- roaming encounters
func _roam_ok() -> bool:
	var party: Variant = level.get("party")
	if party == null or party.get_leader() == null or not bool(party.input_enabled):
		return false
	if bool(level.get("burden_active")) or bool(level.get("_run_ended")):
		return false
	var rn: Variant = level.get("runner")
	if rn != null and bool(rn.active):
		return false
	var f: Variant = level.get("field")
	if f != null and (bool(f.get("boss_active")) or bool(f.get("in_combat"))):
		return false
	var rv: Variant = level.get("rivals")
	if rv != null and not rv.live.is_empty():
		return false
	return true

func live_roamers() -> int:
	var n := 0
	for z in _zones:
		n += (z["live"] as Array).size()
	return n

func _walkable(x: float, z: float, ref_h: float) -> bool:
	for o in [Vector2.ZERO, Vector2(2.5, 0), Vector2(-2.5, 0), Vector2(0, 2.5), Vector2(0, -2.5)]:
		var h: float = level.height_at(x + o.x, z + o.y)
		if absf(h - ref_h) > 1.6:
			return false
	for s in data.get("roaming", {}).get("safe", []):
		if Vector2(x - float(s[0]), z - float(s[1])).length() < float(s[2]):
			return false
	return true

func _roam_tick() -> void:
	var cfg: Dictionary = data.get("roaming", {})
	var lp: Vector3 = level.get("party").get_leader().global_position
	var despawn_d := float(cfg.get("despawn_dist", 120.0))
	for z in _zones:
		var live: Array = z["live"]
		for i in range(live.size() - 1, -1, -1):
			var e: Variant = live[i]
			if not is_instance_valid(e):
				live.remove_at(i)
			elif not bool(e.aggro) and Vector2(lp.x - e.global_position.x, lp.z - e.global_position.z).length() > despawn_d:
				if e.removed.is_connected(_on_roamer_gone):
					e.removed.disconnect(_on_roamer_gone)
				e.queue_free()
				var fld: Variant = level.get("field")
				if fld:
					fld.unregister_enemy(e)
				live.remove_at(i)
				if live.is_empty():
					z["next_ok"] = clock + 30.0       # walked away from it: not a clear, not a reward
	if not _roam_ok() or not _spawn_queue.is_empty():
		return
	var spawn_min := float(cfg.get("spawn_min_dist", 36.0))
	var spawn_max := float(cfg.get("spawn_max_dist", 85.0))
	for z in _zones:
		if _zone_can_spawn(z, lp, spawn_min, spawn_max, int(cfg.get("global_cap", 6))):
			if _queue_group(z, cfg):
				return          # one group per tick

func _zone_can_spawn(z: Dictionary, lp: Vector3, dmin: float, dmax: float, cap: int) -> bool:
	var def: Dictionary = z["def"]
	if bool(z["retired"]) or not (z["live"] as Array).is_empty() or clock < float(z["next_ok"]):
		return false
	if live_roamers() >= cap:
		return false
	var need := str(def.get("needs", ""))
	if need != "" and not bool(GameState.get_flag(need, false)):
		return false
	var c: Array = def["c"]
	var d := Vector2(lp.x - float(c[0]), lp.z - float(c[1])).length()
	return d >= dmin and d <= dmax

func _queue_group(z: Dictionary, cfg: Dictionary) -> bool:
	var def: Dictionary = z["def"]
	var amb: Variant = level.get("ambient")
	var phase := str(amb.phase) if amb != null else "day"
	var mods: Dictionary = cfg.get("phase_mods", {}).get(phase, {})
	var groups: Array = def["groups"]
	var gi := ExploreRules.pick_weighted(groups, _rng.randf(), mods)
	if gi < 0:
		z["next_ok"] = clock + 20.0
		return false
	var g: Dictionary = groups[gi]
	var n := int(g.get("n", 1))
	if live_roamers() + n > int(cfg.get("global_cap", 6)):
		return false
	var c: Array = def["c"]
	var ref_h: float = level.height_at(float(c[0]), float(c[1]))
	var at := Vector3.ZERO
	var ok := false
	for _t in 10:
		var a := _rng.randf() * TAU
		var rr := sqrt(_rng.randf()) * float(def.get("r", 6.0))
		var x := float(c[0]) + cos(a) * rr
		var zz := float(c[1]) + sin(a) * rr
		if _walkable(x, zz, ref_h):
			at = Vector3(x, 0.0, zz)
			ok = true
			break
	if not ok:
		z["next_ok"] = clock + 20.0
		return false
	var swarm: Array = []
	for k in n:
		var ang := TAU * float(k) / float(maxi(n, 1))
		_spawn_queue.append({"zone": z, "species": str(g["species"]), "pos": at + Vector3(cos(ang), 0, sin(ang)) * (1.8 if n > 1 else 0.0), "swarm": swarm})
	return true

func _spawn_one() -> void:
	var q: Dictionary = _spawn_queue.pop_front()
	var z: Dictionary = q["zone"]
	var e: Variant = level.spawn_enemy(str(q["species"]), q["pos"])
	if e == null:
		return
	if e is SkitterMite:
		(e as SkitterMite).swarm = q["swarm"]
		(q["swarm"] as Array).append(e)
	(z["live"] as Array).append(e)
	e.removed.connect(_on_roamer_gone.bind(z))

func _on_roamer_gone(e: Variant, z: Dictionary) -> void:
	var live: Array = z["live"]
	live.erase(e)
	if not live.is_empty() or not _spawn_queue.is_empty():
		return
	z["clears"] = int(z["clears"]) + 1
	var def: Dictionary = z["def"]
	if int(z["clears"]) >= int(def.get("max_clears", 3)):
		z["retired"] = true
	z["next_ok"] = clock + ExploreRules.cooldown(float(def.get("respawn_s", 180)), int(z["clears"]) - 1)

func _clear_roamers_near(p: Vector3, r: float) -> void:
	for z in _zones:
		var live: Array = z["live"]
		for i in range(live.size() - 1, -1, -1):
			var e: Variant = live[i]
			if is_instance_valid(e) and not bool(e.aggro) and Vector2(p.x - e.global_position.x, p.z - e.global_position.z).length() < r:
				if e.removed.is_connected(_on_roamer_gone):
					e.removed.disconnect(_on_roamer_gone)
				var fld: Variant = level.get("field")
				if fld:
					fld.unregister_enemy(e)
				e.queue_free()
				live.remove_at(i)
		if live.is_empty():
			z["next_ok"] = maxf(float(z["next_ok"]), clock + 20.0)

# ---------------------------------------------------------------- frame
func _process(delta: float) -> void:
	if data.is_empty() or level == null:
		return
	clock += delta
	if not _spawn_queue.is_empty():
		_spawn_one()
	var party: Variant = level.get("party")
	if party == null or party.get_leader() == null:
		return
	_poi_t -= delta
	if _poi_t <= 0.0:
		_poi_t = 0.5
		_discover_tick(party.get_leader().global_position)
	_roam_t -= delta
	if _roam_t <= 0.0:
		_roam_t = float(data.get("roaming", {}).get("tick_s", 1.0))
		_roam_tick()
