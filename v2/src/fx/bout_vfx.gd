class_name BoutVfx
extends Node3D
## Presentation VFX for a bout: reacts to sim events (casts, hits, blocks, parries...) and renders the REAL sim entities
## (projectiles, traps, zones, ghosts, decoys at their real radius/life) and active statuses on both fighters.
## Nothing here changes gameplay; everything is driven by sim.state() / sim events. Attach with `BoutVfx.new()` + `bind(bout)`.

var max_live := 90
var _low := false
var bout: Node
var _ents: Array[Dictionary] = []            # slot -> {sig, node, last}
var _aura: Array[Dictionary] = [{}, {}]      # per fighter: status -> Node3D
var _t := 0.0
var _icons: Dictionary = {}

const STATUS_COLORS := {
	"rooted": Color(0.75, 0.55, 0.3), "root": Color(0.75, 0.55, 0.3), "slow": Color(0.4, 0.7, 1.0), "slowed": Color(0.4, 0.7, 1.0),
	"compelled": Color(1.0, 0.45, 0.95), "premonition": Color(1.0, 0.95, 0.4), "touched": Color(1.0, 0.9, 0.4),
	"camo": Color(0.5, 0.9, 0.4), "haste": Color(1.0, 0.95, 0.3), "raging": Color(1.0, 0.25, 0.1), "stunned": Color(1, 1, 0.5),
	"winded": Color(0.6, 0.6, 0.7), "bleed": Color(1.0, 0.2, 0.2), "last_stand": Color(1.0, 0.3, 0.25)}

func bind(b: Node) -> void:
	bout = b
	var q := int(Settings.get_value("quality"))
	max_live = [32, 60, 90][clampi(q, 0, 2)]
	_low = q == 0
	FxPrims.density = [0.45, 0.75, 1.0][clampi(q, 0, 2)]
	name = "BoutVfx"
	b.add_child(self)
	b.fight_event.connect(_on_event)

func _live() -> int:
	return get_child_count()

func _pal(idx: int) -> Dictionary:
	return bout.rigs[idx].palette

func _cid(idx: int) -> String:
	return str(bout.cfg.a_id if idx == 0 else bout.cfg.b_id)

func _pos3(idx: int) -> Vector3:
	var p: Vector3 = bout.holders[idx].position
	return Vector3(p.x, 0.0, p.z)

func _ctx(caster: int, target: int) -> Dictionary:
	var pal := _pal(caster)
	var a := _pos3(caster)
	var b := _pos3(target)
	var d := b - a
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	return {"parent": self, "pos": a, "tpos": b, "dir": d, "col": pal.get("main", Color.WHITE), "acc": pal.get("accent", Color.WHITE), "glow": pal.get("glow", Color.WHITE)}

func _icon(mid: String) -> Texture2D:
	if _icons.has(mid):
		return _icons[mid]
	var t: Texture2D = Hud._icon_for(mid)
	_icons[mid] = t
	return t

func _on_event(ev: Dictionary) -> void:
	if _live() > max_live:
		return
	var idx := int(ev.get("fighter", 0))
	var t := str(ev.get("type", ""))
	var mid := str(ev.get("move_id", ""))
	match t:
		"tell":
			var kind := str(ev.get("kind", ""))
			var c := _ctx(idx, 1 - idx)
			var is_ability := AbilityVfx.cast(mid, c)
			if is_ability:
				var tex := _icon(mid)
				FxPrims.glyph(self, _pos3(idx) + Vector3(0, 4.4, 0), tex, 1.0, 1.5)
			elif kind == "heavy":
				var hg: Color = c["glow"]
				FxPrims.ring(self, _pos3(idx) + Vector3(0, 0.05, 0), 0.3, 1.2, Color(hg, 0.6), 0.3, 0.08)
		"hit":
			var att := int(ev.get("attacker", 1 - idx))
			var c := _ctx(att, idx)
			var dmg := float(ev.get("damage", 0.0))
			var heavy := bool(ev.get("counter", false)) or dmg >= 14.0
			AbilityVfx.hit(_cid(att), c, dmg, heavy)
		"block":
			var att := int(ev.get("attacker", 1 - idx))
			var c := _ctx(att, idx)
			var bd: Vector3 = c["dir"]
			var hp: Vector3 = _pos3(idx) + Vector3(0, 1.2, 0) - bd * 0.5
			FxPrims.burst(self, hp, Color(0.7, 0.9, 1.0), 8, 1.0, 0.2, 0.07)
			FxPrims.ring(self, hp, 0.2, 0.9, Color(0.7, 0.9, 1.0, 0.9), 0.2, 0.1, true)
		"parry":
			var hp := _pos3(idx) + Vector3(0, 1.3, 0)
			FxPrims.ring(self, hp, 0.2, 2.6, Color(1, 1, 0.8, 1.0), 0.35, 0.1, true)
			FxPrims.burst(self, hp, Color(1, 0.95, 0.6), 14, 2.2, 0.3, 0.12)
			FxPrims.sparks(self, hp, Color(1, 1, 0.8), 14, 6.0, -4.0, 0.5, 0.1)
		"clash":
			var hp := (_pos3(0) + _pos3(1)) * 0.5 + Vector3(0, 1.3, 0)
			FxPrims.burst(self, hp, Color(1, 0.9, 0.5), 12, 1.8, 0.3, 0.1)
			FxPrims.ring(self, hp, 0.2, 2.0, Color(1, 0.9, 0.5, 0.9), 0.3, 0.1, true)
		"grab":
			var hp := _pos3(idx) + Vector3(0, 1.1, 0)
			FxPrims.ring(self, hp, 0.2, 1.6, Color(1, 0.5, 0.3, 0.9), 0.3, 0.1, true)
			FxPrims.sparks(self, hp, Color(1, 0.7, 0.4), 10, 3.5, -4.0, 0.4, 0.12)
		"dodge":
			var c := _ctx(idx, 1 - idx)
			var a := _pos3(idx)
			var dd: Vector3 = c["dir"]
			var dgl: Color = c["glow"]
			FxPrims.streak(self, a + Vector3(0, 0.9, 0) - dd.rotated(Vector3.UP, 1.4) * 1.2, a + Vector3(0, 0.9, 0), Color(dgl, 0.6), 0.28, 0.2)
			FxPrims.sparks(self, a + Vector3(0, 0.3, 0), Color(0.85, 0.8, 0.7), 8, 2.0, 0.5, 0.4, 0.14, 90.0)
		"stagger":
			FxPrims.sparks(self, _pos3(idx) + Vector3(0, 2.2, 0), Color(1, 1, 0.5), 8, 2.0, 0.0, 0.7, 0.12, 180.0)
		"ko":
			var hp := _pos3(idx) + Vector3(0, 1.0, 0)
			FxPrims.ring(self, Vector3(hp.x, 0.05, hp.z), 0.5, 6.0, Color(1, 0.9, 0.7, 0.9), 0.6, 0.1)
			FxPrims.burst(self, hp, Color(1, 0.85, 0.5), 18, 3.5, 0.5, 0.16)
			FxPrims.column(self, Vector3(hp.x, 0, hp.z), Color(1, 0.9, 0.7), 6.0, 0.8, 0.8)
		"ringout":
			FxPrims.sparks(self, _pos3(idx) + Vector3(0, 1.0, 0), Color(1, 0.8, 0.5), 16, 5.0, -2.0, 0.8, 0.14, 180.0)
		"laststand":
			var pal := _pal(idx)
			var g: Color = pal.get("glow", Color.WHITE)
			var a := _pos3(idx)
			FxPrims.ring(self, a + Vector3(0, 0.05, 0), 0.6, 9.0, Color(g, 0.95), 0.9, 0.14)
			FxPrims.ring(self, a + Vector3(0, 0.05, 0), 0.4, 6.0, Color(1, 1, 1, 0.8), 0.7, 0.1)
			FxPrims.column(self, a, g, 8.0, 1.1, 1.0)
			FxPrims.burst(self, a + Vector3(0, 1.2, 0), g, 20, 4.0, 0.6, 0.18)
			var tex := _icon(mid)
			FxPrims.glyph(self, a + Vector3(0, 3.4, 0), tex if tex != null else _icon("basic_last_stand"), 1.4, 2.6)
		"yield":
			FxPrims.sparks(self, _pos3(idx) + Vector3(0, 1.6, 0), Color(1, 1, 1), 10, 2.0, 0.5, 0.8, 0.12, 180.0)
		"gust":
			pass
		"morrow_first":
			var c := _ctx(idx, 1 - idx)
			var md: Vector3 = c["dir"]
			FxPrims.slash(self, _pos3(idx) + Vector3(0, 1.3, 0) + md * 1.6, md, Color(1, 0.4, 0.3, 0.9), 2.0, 0.25)
		"shatter":
			var hp := Vector3(float(ev["pos"].x), 0.2, float(ev["pos"].y)) if ev.get("pos") is Vector2 else _pos3(idx)
			FxPrims.sparks(self, hp, Color(0.8, 0.65, 0.5), 20, 5.0, -9.0, 0.7, 0.2, 80.0)
		"ripe":
			FxPrims.burst(self, _pos3(1 - idx) + Vector3(0, 1.2, 0), Color(1, 0.85, 0.3), 10, 1.8, 0.3, 0.12)
		"plate":
			FxPrims.sparks(self, _pos3(idx) + Vector3(0, 1.5, 0), Color(0.55, 0.2, 0.15), 10, 4.0, -8.0, 0.6, 0.2, 120.0)
		"teleport":
			FxPrims.burst(self, _pos3(idx) + Vector3(0, 1.0, 0), Color(0.9, 1, 0.8), 10, 1.4, 0.25, 0.1)

func _process(delta: float) -> void:
	if bout == null or not is_instance_valid(bout) or bout.sim == null:
		return
	_t += delta
	var st: Dictionary = bout.sim.state()
	_update_entities(st["entities"])
	for i in 2:
		_update_status(i, st["fighters"][i])

# ------------------------------------------------------------------ entities (real positions / radii)
func _ent_sig(e: Dictionary) -> String:
	return "%s|%s|%s" % [str(e.get("kind")), str(e.get("tag")), str(e.get("move_id"))]

func _update_entities(ents: Array) -> void:
	while _ents.size() < ents.size():
		_ents.append({"sig": "", "node": null, "last": Vector3.ZERO})
	for i in _ents.size():
		var slot := _ents[i]
		if i >= ents.size():
			if slot["node"] != null:
				(slot["node"] as Node).queue_free()
				slot["node"] = null
				slot["sig"] = ""
			continue
		var e: Dictionary = ents[i]
		var sig := _ent_sig(e)
		if slot["sig"] != sig:
			if slot["node"] != null:
				(slot["node"] as Node).queue_free()
			slot["node"] = _build_entity(e)
			slot["sig"] = sig
			slot["last"] = Vector3(float(e["pos"].x), 0.0, float(e["pos"].y))
			if slot["node"] != null:
				add_child(slot["node"])
		var n: Node3D = slot["node"]
		if n == null:
			continue
		var p := Vector3(float(e["pos"].x), 0.0, float(e["pos"].y))
		n.position = p
		var moved: Vector3 = p - (slot["last"] as Vector3)
		slot["last"] = p
		_animate_entity(n, e, moved)

func _owner_color(e: Dictionary) -> Color:
	var o := int(e.get("owner", 0))
	return _pal(clampi(o, 0, 1)).get("glow", Color.WHITE)

func _build_entity(e: Dictionary) -> Node3D:
	var root := Node3D.new()
	var col := _owner_color(e)
	var kind := str(e.get("kind"))
	var tag := str(e.get("tag"))
	var r := maxf(0.2, float(e.get("radius", 1.0)))
	root.set_meta("r", r)
	match kind:
		"proj":
			var sp := SphereMesh.new()
			sp.radius = 0.28
			sp.height = 0.56
			sp.radial_segments = 8
			sp.rings = 4
			var mi := MeshInstance3D.new()
			mi.mesh = sp
			mi.material_override = FxPrims.mat(Color(col, 0.95))
			mi.position.y = 1.2
			root.add_child(mi)
			var tr := MeshInstance3D.new()
			var bx := BoxMesh.new()
			bx.size = Vector3(0.14, 0.14, 1.6)
			tr.mesh = bx
			tr.material_override = FxPrims.mat(Color(col, 0.5))
			tr.position = Vector3(0, 1.2, 0)
			tr.name = "Trail"
			root.add_child(tr)
		"zone":
			var base := MeshInstance3D.new()
			var cy := CylinderMesh.new()
			cy.top_radius = 1.0
			cy.bottom_radius = 1.0
			cy.height = 0.02
			cy.radial_segments = 24
			cy.rings = 1
			base.mesh = cy
			var zc := _zone_color(tag, col)
			base.material_override = FxPrims.mat(Color(zc, 0.22))
			base.scale = Vector3(r, 1, r)
			base.position.y = 0.03
			base.name = "Base"
			root.add_child(base)
			var rg := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.94
			tm.outer_radius = 1.0
			tm.rings = 24
			tm.ring_segments = 4
			rg.mesh = tm
			rg.material_override = FxPrims.mat(Color(zc, 0.9))
			rg.scale = Vector3(r, r * 0.3, r)
			rg.position.y = 0.05
			rg.name = "Edge"
			root.add_child(rg)
			match tag:
				"thorn":
					_decor(root, zc.lerp(Color(0.9, 0.85, 0.6), 0.5), r, 5, 0.9, true)
				"fungus":
					_decor(root, Color(0.9, 0.4, 0.5), r, 6, 0.7, false)
				"boundary", "archive":
					_decor(root, Color(0.85, 0.96, 1.0), r, 6, 1.0, true)
				"pollen":
					if not _low:
						var em := FxPrims.emitter(root, Vector3(0, 0.8, 0), Color(1, 0.55, 0.85, 0.8), 20, 1.2, 0.12, 0.3, r * 0.8)
						em.name = "Emit"
				"inertia":
					var dm := MeshInstance3D.new()
					var sph := SphereMesh.new()
					sph.radius = 1.0
					sph.height = 2.0
					sph.radial_segments = 16
					sph.rings = 6
					dm.mesh = sph
					dm.material_override = FxPrims.mat(Color(1, 0.7, 0.2, 0.12))
					dm.scale = Vector3(r, r * 0.6, r)
					root.add_child(dm)
		"ghost", "phantom", "decoy":
			var cap := CapsuleMesh.new()
			cap.radius = 0.5
			cap.height = 2.0
			cap.radial_segments = 8
			cap.rings = 3
			var gm := MeshInstance3D.new()
			gm.mesh = cap
			var gc := Color(1, 0.4, 0.9) if kind == "decoy" else col
			gm.material_override = FxPrims.mat(Color(gc, 0.35))
			gm.position.y = 1.0
			gm.name = "Ghost"
			root.add_child(gm)
	return root

func _zone_color(tag: String, owner_col: Color) -> Color:
	match tag:
		"thorn": return Color(0.9, 0.5, 0.25)
		"fungus": return Color(0.85, 0.35, 0.5)
		"boundary": return Color(0.6, 0.85, 1.0)
		"archive": return Color(0.75, 0.92, 1.0)
		"pollen": return Color(1.0, 0.5, 0.85)
		"inertia": return Color(1.0, 0.7, 0.2)
	return owner_col

func _decor(root: Node3D, col: Color, r: float, n: int, h: float, sharp: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var a := TAU * float(i) / float(n) + rng.randf() * 0.6
		var rr := r * rng.randf_range(0.2, 0.85)
		var c := CylinderMesh.new()
		c.top_radius = 0.0 if sharp else 0.18
		c.bottom_radius = 0.14 if sharp else 0.06
		c.height = h * rng.randf_range(0.5, 1.0)
		c.radial_segments = 5
		c.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = FxPrims.mat(Color(col, 0.95), false)
		mi.position = Vector3(cos(a) * rr, c.height * 0.5, sin(a) * rr)
		mi.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		root.add_child(mi)

func _animate_entity(n: Node3D, e: Dictionary, moved: Vector3) -> void:
	var kind := str(e.get("kind"))
	var life := float(e.get("life", 1.0))
	var pulse := 0.85 + 0.15 * sin(_t * 6.0)
	if kind == "zone":
		var edge := n.get_node_or_null("Edge") as MeshInstance3D
		if edge != null:
			var r := float(e.get("radius", 1.0))
			edge.scale = Vector3(r, r * 0.3, r) * pulse
		var fade := clampf(life / 40.0, 0.2, 1.0)
		n.scale = Vector3.ONE * (0.6 + 0.4 * fade)
	elif kind == "proj":
		var tr := n.get_node_or_null("Trail") as MeshInstance3D
		if tr != null and moved.length() > 0.001:
			tr.look_at_from_position(n.global_position + Vector3(0, 1.2, 0) - moved.normalized() * 0.8, n.global_position + Vector3(0, 1.2, 0), Vector3.UP)
	elif kind == "ghost" or kind == "phantom" or kind == "decoy":
		var g := n.get_node_or_null("Ghost") as MeshInstance3D
		if g != null:
			g.position.y = 1.0 + sin(_t * 4.0) * 0.1
			g.scale = Vector3.ONE * (0.95 + 0.08 * sin(_t * 9.0))

# ------------------------------------------------------------------ statuses (real remaining ticks)
func _update_status(i: int, f: Dictionary) -> void:
	var active: Dictionary = {}
	var ticks: Dictionary = f.get("status_ticks", {})
	for k in ticks.keys():
		if int(ticks[k]) > 0 and STATUS_COLORS.has(str(k)):
			active[str(k)] = true
	for k in f.get("status", []):
		if STATUS_COLORS.has(str(k)):
			active[str(k)] = true
	if bool(f.get("raging", false)):
		active["raging"] = true
	if bool(f.get("compelled", false)):
		active["compelled"] = true
	if int(f.get("dots", 0)) > 0:
		active["bleed"] = true
	var auras: Dictionary = _aura[i]
	for k in auras.keys():
		if not active.has(k):
			(auras[k] as Node).queue_free()
			auras.erase(k)
	var base := _pos3(i)
	var idx_n := 0
	for k in active.keys():
		var node: Node3D = auras.get(k, null)
		if node == null:
			node = _make_aura(str(k))
			add_child(node)
			auras[k] = node
		node.position = base
		var s := 1.0 + 0.1 * sin(_t * 5.0 + float(idx_n))
		node.scale = Vector3(s, 1, s)
		node.rotation.y = _t * (1.5 + float(idx_n) * 0.3)
		idx_n += 1

func _make_aura(k: String) -> Node3D:
	var col: Color = STATUS_COLORS[k]
	var root := Node3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 20
	tm.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = FxPrims.mat(Color(col, 0.85))
	var rad := 1.1 + float(abs(k.hash()) % 5) * 0.12
	mi.scale = Vector3(rad, rad * 0.3, rad)
	mi.position.y = 0.06
	root.add_child(mi)
	# a few orbiting motes make the status readable from any angle
	for j in 3:
		var sp := SphereMesh.new()
		sp.radius = 0.08
		sp.height = 0.16
		sp.radial_segments = 6
		sp.rings = 3
		var m := MeshInstance3D.new()
		m.mesh = sp
		m.material_override = FxPrims.mat(Color(col, 0.95))
		var a := TAU * float(j) / 3.0
		m.position = Vector3(cos(a) * rad, 0.35 + float(j) * 0.55, sin(a) * rad)
		root.add_child(m)
	if k == "raging" or k == "bleed" or k == "camo" or k == "haste":
		FxPrims.emitter(root, Vector3(0, 1.0, 0), Color(col, 0.8), 14, 0.8, 0.12, 1.2 if k == "raging" else 0.6, 0.5)
	return root
