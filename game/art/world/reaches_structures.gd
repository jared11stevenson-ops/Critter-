class_name ReachesStructures
extends RefCounted
## Red Reaches structures (Agent 1). `build(spec, terrain)` returns a Node3D for a layout.json structure.
## Each structure merges its visuals into 1-3 meshes (draw-call budget) and owns layer-1 collision.

const STONE := Color(0.66, 0.42, 0.31)
const STONE_DARK := Color(0.56, 0.34, 0.26)
const OCHRE := Color(0.74, 0.47, 0.26)
const WOOD := Color(0.48, 0.32, 0.22)
const ROPE := Color(0.80, 0.66, 0.42)
const GUNMETAL := Color(0.30, 0.31, 0.35)
const DOM_RED := Color(0.72, 0.10, 0.09)
const THOUGHT := Color(0.62, 0.86, 1.0)


static func build(spec: Dictionary, terrain: Node) -> Node3D:
	match str(spec.get("kind", "")):
		"gate_ring":
			return GateRing.new(spec, terrain)
		"rope_bridge":
			return RopeBridge.new(spec, terrain)
		"stone_bridge":
			return StoneBridge.new(spec, terrain)
		"ruins":
			return Ruins.new(spec, terrain)
		"marker_stone":
			return MarkerStone.new(spec, terrain)
		"cracked_boulder":
			return CrackedBoulder.new(spec, terrain)
		"dominion_camp":
			return DominionCamp.new(spec, terrain)
		"boss_rig":
			var n := Node3D.new()   # the boss is spawned by gameplay from game/art/creatures/augur_rig.tscn
			n.position = _v3(spec.get("pos", [0, 0, 0]))
			return n
	return null


static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _sfx(node: Node, name: String, pos: Vector3) -> void:
	var au := node.get_node_or_null("/root/Audio")
	if au and au.has_method("sfx_at"):
		au.sfx_at(name, pos)


static func _add_mesh(parent: Node3D, st: SurfaceTool, mat: Material, name: String, shadow: bool = true) -> MeshInstance3D:
	var mi := ToonKit.mesh_instance(ToonKit.finish(st), mat, name)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _glow_mesh(parent: Node3D, st: SurfaceTool, c: Color, energy: float, name: String) -> MeshInstance3D:
	var mi := ToonKit.mesh_instance(st.commit(), ToonKit.glow(c, energy), name)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# =====================================================================================================
class GateRing extends Node3D:
	## Terrarium arrival gate: an upright stone-and-brass ring on a stepped dais, Thoughtstone membrane.
	var membrane: MeshInstance3D

	func _init(spec: Dictionary, _t: Node) -> void:
		position = ReachesStructures._v3(spec.get("pos", [0, 0, 0]))
		rotation.y = deg_to_rad(float(spec.get("rot_y", 0.0)))
		var st := ToonKit.begin()
		# dais: two stepped discs
		ToonKit.cylinder(st, Vector3(0, -0.6, 0), Vector3(0, 0.12, 0), 4.6, 4.5, 14, STONE_DARK, true, 0.03, 4)
		ToonKit.cylinder(st, Vector3(0, 0.12, 0), Vector3(0, 0.34, 0), 3.7, 3.6, 14, STONE, true, 0.02, 5)
		# ring
		ToonKit.torus(st, Transform3D(Basis(), Vector3(0, 4.0, 0)), 3.5, 0.48, 22, 6, Color(0.66, 0.46, 0.34))
		ToonKit.torus(st, Transform3D(Basis(), Vector3(0, 4.0, 0)), 3.5, 0.2, 22, 4, Color(0.86, 0.66, 0.30))
		# keystones + feet
		for i in 6:
			var a := TAU * float(i) / 6.0 + PI / 2.0
			var p := Vector3(cos(a) * 3.5, 4.0 + sin(a) * 3.5, 0)
			ToonKit.box(st, Transform3D(Basis(Vector3.BACK, a), p), Vector3(0.6, 1.1, 1.3), STONE)
		for sx: float in [-1.0, 1.0]:
			ToonKit.box(st, Transform3D(Basis(Vector3.BACK, -sx * 0.35), Vector3(sx * 2.6, 0.9, 0)), Vector3(1.3, 1.9, 1.5), STONE_DARK)
		ReachesStructures._add_mesh(self, st, ToonKit.material({"outline": 0.04}), "Ring")
		# membrane (soft glow disc)
		var g := SurfaceTool.new()
		g.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 24
		for i in n:
			var a0 := TAU * float(i) / n
			var a1 := TAU * float(i + 1) / n
			g.add_vertex(Vector3(0, 4.0, 0))
			g.add_vertex(Vector3(cos(a1) * 3.1, 4.0 + sin(a1) * 3.1, 0))
			g.add_vertex(Vector3(cos(a0) * 3.1, 4.0 + sin(a0) * 3.1, 0))
		membrane = ReachesStructures._glow_mesh(self, g, Color(0.55, 0.8, 1.0, 0.28), 1.6, "Membrane")
		for sx: float in [-1.0, 1.0]:
			ToonKit.static_cylinder(self, Vector3(sx * 2.7, 0, 0), 0.8, 3.0)

	func _process(_d: float) -> void:
		if membrane:
			var m: StandardMaterial3D = membrane.material_override
			var k := 0.22 + 0.08 * sin(Time.get_ticks_msec() * 0.002)
			m.albedo_color.a = k


# =====================================================================================================
class RopeBridge extends Node3D:
	## Spanwright rope span. Starts rolled up at the far anchor; `set_unrolled(true)` unrolls it toward a.
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var width := 2.6
	var sag := 0.35
	var deck: MeshInstance3D
	var bundle: MeshInstance3D
	var body: StaticBody3D
	var mat: ShaderMaterial
	var unrolled := false
	var _tw: Tween

	func _init(spec: Dictionary, t: Node) -> void:
		a = ReachesStructures._v3(spec["a"])
		b = ReachesStructures._v3(spec["b"])
		width = float(spec.get("width", 2.6))
		var dir := (b - a)
		var flat := Vector3(dir.x, 0, dir.z).normalized()
		var side := flat.cross(Vector3.UP).normalized()
		var L := dir.length()
		mat = ToonKit.material({"outline": 0.025, "unique": true})
		# posts at both ends (always visible, part of the anchors)
		var sp := ToonKit.begin()
		for e in [a, b]:
			var ep: Vector3 = e
			var off := flat * (-0.4 if ep == a else 0.4)
			for s: float in [-1.0, 1.0]:
				var base: Vector3 = ep + off + side * s * (width * 0.5 + 0.1)
				ToonKit.cylinder(sp, base + Vector3(0, -0.6, 0), base + Vector3(0, 1.5, 0), 0.14, 0.11, 6, WOOD, true, 0.1, int(s * 3 + 5))
				ToonKit.cylinder(sp, base + Vector3(0, 1.25, 0), base + Vector3(0, 1.45, 0), 0.17, 0.17, 6, ROPE)
		ReachesStructures._add_mesh(self, sp, ToonKit.material({"outline": 0.025}), "Posts")
		# deck: planks + rails; UV2.x = distance from b (0) to a (1) for the unroll reveal
		var st := ToonKit.begin()
		st.set_uv2(Vector2(0, 0))
		var n := int(L / 0.42)
		for i in n:
			var tt := (float(i) + 0.5) / n
			var p := _deck_point(tt) + Vector3(0, -0.07, 0)
			st.set_uv2(Vector2(1.0 - tt, 0))
			var tilt := (_deck_point(minf(tt + 0.02, 1.0)) - _deck_point(maxf(tt - 0.02, 0.0)))
			var pitch := atan2(tilt.y, Vector2(tilt.x, tilt.z).length())
			var xf := Transform3D(Basis(side, -pitch) * Basis.looking_at(flat, Vector3.UP), p)
			var c := WOOD.lightened(0.08 * float(i % 3)) if i % 5 != 0 else WOOD.darkened(0.15)
			ToonKit.box(st, xf, Vector3(width * (0.95 + 0.05 * float(i % 2)), 0.12, 0.34), c)
		# hand ropes (segmented)
		var segs := 12
		for s: float in [-1.0, 1.0]:
			for i in segs:
				var t0 := float(i) / segs
				var t1 := float(i + 1) / segs
				st.set_uv2(Vector2(1.0 - t1, 0))
				var o: Vector3 = side * s * (width * 0.5 + 0.08)
				ToonKit.cylinder(st, _deck_point(t0) + o + Vector3(0, 1.2 - sag * 0.5 * sin(t0 * PI), 0), _deck_point(t1) + o + Vector3(0, 1.2 - sag * 0.5 * sin(t1 * PI), 0), 0.045, 0.045, 4, ROPE, false)
				ToonKit.cylinder(st, _deck_point(t0) + o, _deck_point(t1) + o, 0.04, 0.04, 4, ROPE, false)
				# verticals
				ToonKit.cylinder(st, _deck_point(t0) + o, _deck_point(t0) + o + Vector3(0, 1.2 - sag * 0.5 * sin(t0 * PI), 0), 0.025, 0.025, 3, ROPE, false)
		deck = ReachesStructures._add_mesh(self, st, mat, "Deck")
		# rolled bundle at the b anchor
		var bt := ToonKit.begin()
		var bc := b + flat * -0.3 + Vector3(0, 0.45, 0)
		ToonKit.cylinder(bt, bc - side * width * 0.5, bc + side * width * 0.5, 0.42, 0.42, 9, WOOD.lightened(0.05))
		ToonKit.cylinder(bt, bc - side * width * 0.3, bc - side * width * 0.24, 0.45, 0.45, 9, ROPE)
		ToonKit.cylinder(bt, bc + side * width * 0.24, bc + side * width * 0.3, 0.45, 0.45, 9, ROPE)
		bundle = ReachesStructures._add_mesh(self, bt, ToonKit.material({"outline": 0.025}), "Bundle")
		# collision (layer 1): deck segments + side ropes so nobody walks off
		body = StaticBody3D.new()
		body.name = "DeckBody"
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		var cs := 7
		for i in cs:
			var t0 := float(i) / cs
			var t1 := float(i + 1) / cs
			var p0 := _deck_point(t0)
			var p1 := _deck_point(t1)
			var mid := (p0 + p1) * 0.5
			var seg := p1 - p0
			var xf := Transform3D(Basis.looking_at(seg.normalized(), Vector3.UP), mid)
			_box_shape(xf.translated_local(Vector3(0, -0.25, 0)), Vector3(width, 0.5, seg.length() + 0.3))
			for s: float in [-1.0, 1.0]:
				_box_shape(xf.translated_local(Vector3(s * (width * 0.5 + 0.15), 0.7, 0)), Vector3(0.2, 1.4, seg.length() + 0.3))
		if t and t.has_method("register_deck"):
			t.register_deck(a, b, width, deck, sag)
		set_unrolled(not bool(spec.get("starts_hidden", false)), true)

	func _deck_point(tt: float) -> Vector3:
		return a.lerp(b, tt) - Vector3(0, sag * sin(tt * PI), 0)

	func _box_shape(xf: Transform3D, size: Vector3) -> void:
		var c := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		c.shape = bs
		c.transform = xf
		body.add_child(c)

	func set_unrolled(on: bool, instant: bool = false) -> void:
		unrolled = on
		if _tw:
			_tw.kill()
		for c in body.get_children():
			(c as CollisionShape3D).set_deferred("disabled", not on)
		if instant:
			_set_reveal(1.0 if on else 0.0)
			deck.visible = on
			return
		deck.visible = true
		ReachesStructures._sfx(self, "rope_unroll", b)
		_tw = create_tween()
		_tw.tween_method(_set_reveal, 0.0 if on else 1.0, 1.0 if on else 0.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if not on:
			_tw.tween_callback(func() -> void: deck.visible = false)

	func _set_reveal(v: float) -> void:
		mat.set_shader_parameter("reveal", v)
		if mat.next_pass:
			(mat.next_pass as ShaderMaterial).set_shader_parameter("reveal", v)
		if bundle:
			var k := clampf(1.0 - v * 1.2, 0.0, 1.0)
			bundle.visible = k > 0.02


# =====================================================================================================
class StoneBridge extends Node3D:
	## The Ochre Span: ancient Spanwright stone bridge over the chasm. Walkable deck (layer 1),
	## parapets as soft walls. States: intact | braced | failing. `shake(i)` for the Burden moment.
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var width := 7.0
	var visual: Node3D
	var braces: MeshInstance3D
	var damage: MeshInstance3D
	var mid_seg: MeshInstance3D
	var state := "intact"
	var _shake := 0.0
	var _rng := RandomNumberGenerator.new()

	func _init(spec: Dictionary, t: Node) -> void:
		a = ReachesStructures._v3(spec["a"])
		b = ReachesStructures._v3(spec["b"])
		width = float(spec.get("width", 7.0))
		_rng.seed = 7
		var L := Vector2(b.x - a.x, b.z - a.z).length()
		var ang := atan2(-(b.z - a.z), b.x - a.x)
		position = a
		rotation.y = ang
		# local frame: +X along the span, Z across, deck top at y = 0 (a.y and b.y equal in the layout)
		var rise := b.y - a.y
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
		var st := ToonKit.begin()
		var mid_st := ToonKit.begin()
		var hw := width * 0.5
		var nseg := int(L / 2.6)
		for i in nseg:
			var x0 := L * float(i) / nseg
			var x1 := L * float(i + 1) / nseg
			var xm := (x0 + x1) * 0.5
			var y := rise * xm / L
			var c := OCHRE.lerp(STONE, 0.3 + 0.4 * _rng.randf())
			var target := mid_st if absf(xm - L * 0.5) < 6.0 else st
			# deck slab (slightly varied heights for a hand-laid look)
			ToonKit.box(target, Transform3D(Basis(), Vector3(xm, y - 0.45 + _rng.randf() * 0.04, 0)), Vector3(x1 - x0 - 0.06, 0.9, width), c)
			# parapets (with a few broken gaps)
			for s: float in [-1.0, 1.0]:
				if _rng.randf() < 0.12:
					continue
				var ph := 0.75 + _rng.randf() * 0.2
				ToonKit.box(target, Transform3D(Basis(), Vector3(xm, y + ph * 0.5, s * (hw - 0.3))), Vector3(x1 - x0 - 0.1, ph, 0.6), STONE.lerp(OCHRE, _rng.randf() * 0.4))
				ToonKit.box(target, Transform3D(Basis(), Vector3(xm, y + ph + 0.06, s * (hw - 0.3))), Vector3(x1 - x0 + 0.05, 0.14, 0.75), STONE_DARK.lightened(0.15))
		# cornice band under the deck
		for s: float in [-1.0, 1.0]:
			ToonKit.box(st, Transform3D(Basis(), Vector3(L * 0.5, rise * 0.5 - 1.05, s * (hw + 0.05))), Vector3(L, 0.35, 0.3), STONE_DARK)
		# piers + arches down into the chasm
		var piers := [0.0, L * 0.27, L * 0.5, L * 0.73, L]
		for px in piers:
			var pxf: float = px
			if pxf <= 0.0 or pxf >= L:
				continue
			ToonKit.box(st, Transform3D(Basis(), Vector3(pxf, -20.0, 0)), Vector3(2.6, 38.0, width * 0.8), STONE.darkened(0.08))
			ToonKit.box(st, Transform3D(Basis(), Vector3(pxf, -1.6, 0)), Vector3(3.2, 0.5, width * 0.9), STONE_DARK)
		for i in piers.size() - 1:
			var p0: float = piers[i]
			var p1: float = piers[i + 1]
			var span := p1 - p0
			var na := 9
			for k in na:
				var u0 := float(k) / na
				var u1 := float(k + 1) / na
				var x0 := p0 + span * u0
				var x1 := p0 + span * u1
				var y0 := -1.0 - (1.0 - pow(sin(u0 * PI), 0.6)) * span * 0.32
				var y1 := -1.0 - (1.0 - pow(sin(u1 * PI), 0.6)) * span * 0.32
				for s: float in [-1.0, 1.0]:
					var z := s * (width * 0.4)
					var zi := s * (width * 0.4 - 0.9)
					# arch face (spandrel) between deck underside and arch curve
					ToonKit.quad(st, Vector3(x0, -0.9, z), Vector3(x1, -0.9, z), Vector3(x1, y1, z), Vector3(x0, y0, z), STONE.darkened(0.05) if s > 0 else STONE.darkened(0.15))
					ToonKit.quad(st, Vector3(x1, -0.9, zi), Vector3(x0, -0.9, zi), Vector3(x0, y0, zi), Vector3(x1, y1, zi), STONE.darkened(0.25))
				# arch intrados
				ToonKit.quad(st, Vector3(x0, y0, width * 0.4), Vector3(x1, y1, width * 0.4), Vector3(x1, y1, -width * 0.4), Vector3(x0, y0, -width * 0.4), STONE_DARK.darkened(0.2))
				# voussoir ink accents
				if k % 2 == 0:
					ToonKit.box(st, Transform3D(Basis(), Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5 - 0.15, width * 0.4 + 0.08)), Vector3(x1 - x0 + 0.04, 0.32, 0.12), OCHRE)
		# Spanwright carvings: glyph discs on the pier heads
		for px: float in [L * 0.27, L * 0.5, L * 0.73]:
			for s: float in [-1.0, 1.0]:
				ToonKit.cylinder(st, Vector3(px, -2.6, s * width * 0.4), Vector3(px, -2.6, s * (width * 0.4 + 0.15)), 0.9, 0.9, 10, OCHRE.lightened(0.1))
		var smat := ToonKit.material({"outline": 0.04, "strata": 0.5})
		ReachesStructures._add_mesh(visual, st, smat, "Span")
		mid_seg = ReachesStructures._add_mesh(visual, mid_st, smat, "MidSpan")
		# braces (Burden Bridge braced state): timber struts + rope lashings + amber glow lines
		var bst := ToonKit.begin()
		for px: float in [L * 0.27, L * 0.5, L * 0.73]:
			for s: float in [-1.0, 1.0]:
				var z := s * (width * 0.5 + 0.25)
				ToonKit.cylinder(bst, Vector3(px - 4.5, 1.2, z), Vector3(px, -5.0, z), 0.16, 0.16, 6, WOOD)
				ToonKit.cylinder(bst, Vector3(px + 4.5, 1.2, z), Vector3(px, -5.0, z), 0.16, 0.16, 6, WOOD)
				ToonKit.cylinder(bst, Vector3(px - 0.3, -0.6, z), Vector3(px + 0.3, -0.6, z), 0.26, 0.26, 6, ROPE)
		for s: float in [-1.0, 1.0]:
			ToonKit.cylinder(bst, Vector3(0, 1.05, s * (width * 0.5 - 0.3)), Vector3(L, 1.05 + rise, s * (width * 0.5 - 0.3)), 0.06, 0.06, 4, ROPE, false)
		braces = ReachesStructures._add_mesh(visual, bst, ToonKit.material({"outline": 0.025}), "Braces")
		braces.visible = false
		# damage (failing state): ink cracks on the deck + fallen parapet chunks
		var dst := ToonKit.begin()
		for i in 14:
			var x := L * 0.5 + _rng.randf_range(-9.0, 9.0)
			var z := _rng.randf_range(-hw + 0.6, hw - 0.6)
			var r := _rng.randf() * PI
			ToonKit.box(dst, Transform3D(Basis(Vector3.UP, r), Vector3(x, 0.02, z)), Vector3(_rng.randf_range(1.0, 2.6), 0.03, 0.08), Color(0.12, 0.06, 0.06))
		for i in 5:
			ToonKit.rock(dst, Vector3(L * 0.5 + _rng.randf_range(-8, 8), 0.15, _rng.randf_range(-hw + 0.8, hw - 0.8)), Vector3(0.4, 0.3, 0.35), STONE, i + 30, 0)
		damage = ReachesStructures._add_mesh(visual, dst, ToonKit.material({"outline": 0.02}), "Damage", false)
		damage.visible = false
		# collision: deck + parapet walls (local frame)
		var body := StaticBody3D.new()
		body.name = "DeckBody"
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		var basis_tilt := Basis(Vector3.BACK, atan2(rise, L))
		var deck := CollisionShape3D.new()
		var ds := BoxShape3D.new()
		ds.size = Vector3(L + 2.0, 1.0, width)
		deck.shape = ds
		deck.transform = Transform3D(basis_tilt, Vector3(L * 0.5, rise * 0.5 - 0.5, 0))
		body.add_child(deck)
		for s: float in [-1.0, 1.0]:
			var wall := CollisionShape3D.new()
			var ws := BoxShape3D.new()
			ws.size = Vector3(L, 2.0, 0.6)
			wall.shape = ws
			wall.transform = Transform3D(basis_tilt, Vector3(L * 0.5, rise * 0.5 + 1.0, s * (hw - 0.3)))
			body.add_child(wall)
		if t and t.has_method("register_deck"):
			t.register_deck(a, b, width - 0.6, null, 0.0)

	func set_state(s: String) -> void:
		state = s
		braces.visible = s == "braced"
		damage.visible = s == "failing"
		if s == "failing":
			mid_seg.rotation = Vector3(deg_to_rad(1.2), 0, deg_to_rad(-0.8))
			mid_seg.position = Vector3(0, -0.12, 0)
		else:
			mid_seg.rotation = Vector3.ZERO
			mid_seg.position = Vector3.ZERO

	func shake(intensity: float) -> void:
		_shake = maxf(_shake, clampf(intensity, 0.0, 2.0))
		if intensity > 0.05:
			ReachesStructures._sfx(self, "span_creak", a.lerp(b, 0.5))

	func _process(delta: float) -> void:
		if _shake > 0.0:
			_shake = maxf(0.0, _shake - delta * 0.8)
			var k := _shake * 0.12
			visual.position = Vector3(_rng.randf_range(-k, k), _rng.randf_range(-k, k) * 0.6, _rng.randf_range(-k, k) * 0.5)
			visual.rotation.x = sin(Time.get_ticks_msec() * 0.03) * _shake * 0.006
		elif visual.position != Vector3.ZERO:
			visual.position = Vector3.ZERO
			visual.rotation = Vector3.ZERO


# =====================================================================================================
class Ruins extends Node3D:
	## Spanwright waystation ruins: broken colonnade + wall stubs ringing the plaza; tall pieces stay
	## on the north arc (camera looks -Z), the south arc gets low rubble only. East/west road kept open.
	func _init(spec: Dictionary, t: Node) -> void:
		var c := ReachesStructures._v3(spec.get("pos", [0, 0, 0]))
		var R := float(spec.get("radius", 15.0))
		var rng := RandomNumberGenerator.new()
		rng.seed = 118
		var st := ToonKit.begin()
		var n := 22
		for i in n:
			var ang := TAU * float(i) / n + rng.randf_range(-0.05, 0.05)
			var dx := cos(ang)
			var dz := sin(ang)
			if absf(dz) < 0.5:   # keep the road (east / west) open
				continue
			var r := R * rng.randf_range(0.72, 0.95)
			var p := Vector3(c.x + dx * r, 0, c.z + dz * r)
			if t and t.has_method("floor_sdf") and t.floor_sdf(p.x, p.z) > -0.5:
				r = R * 0.68
				p = Vector3(c.x + dx * r, 0, c.z + dz * r)
			p.y = t.height_at(p.x, p.z) if t else c.y
			var north := dz < 0.0
			var col := STONE.lerp(OCHRE, rng.randf() * 0.5)
			if north and i % 3 != 1:
				var hgt := rng.randf_range(2.2, 5.5)
				ToonKit.box(st, Transform3D(Basis(), p + Vector3(0, 0.15, 0)), Vector3(1.6, 0.5, 1.6), STONE_DARK)
				ToonKit.cylinder(st, p, p + Vector3(0, hgt, 0), 0.55, 0.5, 8, col, true, 0.06, i)
				if hgt > 4.5:
					ToonKit.box(st, Transform3D(Basis(Vector3.UP, ang), p + Vector3(0, hgt + 0.25, 0)), Vector3(1.5, 0.5, 1.5), col.lightened(0.05))
				ToonKit.static_cylinder(self, p, 0.6, hgt)
			elif north:
				var w := rng.randf_range(2.5, 4.0)
				var hh := rng.randf_range(1.0, 2.6)
				var xf := Transform3D(Basis(Vector3.UP, -ang + PI / 2.0), p + Vector3(0, hh * 0.5 - 0.2, 0))
				ToonKit.box(st, xf, Vector3(w, hh, 0.8), col)
				ToonKit.box(st, xf.translated_local(Vector3(-w * 0.25, hh * 0.5 + 0.2, 0)), Vector3(w * 0.5, 0.4, 0.8), col.lightened(0.04))
				ToonKit.static_box(self, xf, Vector3(w, hh, 0.8))
			else:
				# south: low rubble + toppled drums
				ToonKit.rock(st, p + Vector3(0, 0.1, 0), Vector3(0.7, 0.45, 0.6), col, i + 50, 0)
				if i % 2 == 0:
					var d := Vector3(cos(ang + 1.3), 0, sin(ang + 1.3))
					ToonKit.cylinder(st, p + Vector3(0, 0.45, 0) - d * 1.0, p + Vector3(0, 0.45, 0) + d * 1.0, 0.45, 0.45, 8, col)
		# fallen archway on the north edge
		var ap := Vector3(c.x - 2.0, 0, c.z - R * 0.9)
		ap.y = t.height_at(ap.x, ap.z) if t else c.y
		for sx: float in [-1.0, 1.0]:
			ToonKit.box(st, Transform3D(Basis(), ap + Vector3(sx * 2.4, 2.6, 0)), Vector3(1.1, 5.2, 1.1), STONE)
		ToonKit.torus(st, Transform3D(Basis(), ap + Vector3(0, 5.0, 0)), 2.4, 0.5, 10, 4, OCHRE)
		ReachesStructures._add_mesh(self, st, ToonKit.material({"outline": 0.035}), "Ruins")


# =====================================================================================================
class MarkerStone extends Node3D:
	## Old Road marker stone: carved Spanwright monolith with softly glowing glyphs (scan target).
	func _init(spec: Dictionary, _t: Node) -> void:
		position = ReachesStructures._v3(spec.get("pos", [0, 0, 0]))
		var st := ToonKit.begin()
		ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.15, 0)), Vector3(2.0, 0.5, 1.4), STONE_DARK)
		ToonKit.box(st, Transform3D(Basis(Vector3.BACK, 0.04), Vector3(0, 1.6, 0)), Vector3(1.2, 2.8, 0.6), STONE.lerp(OCHRE, 0.3))
		ToonKit.box(st, Transform3D(Basis(Vector3.BACK, 0.04), Vector3(0.05, 3.1, 0)), Vector3(1.35, 0.3, 0.7), STONE)
		ReachesStructures._add_mesh(self, st, ToonKit.material({"outline": 0.035}), "Stone")
		var gs := ToonKit.begin()
		for i in 4:
			var y := 0.9 + i * 0.5
			ToonKit.box(gs, Transform3D(Basis(Vector3.BACK, 0.04), Vector3(0.0, y, 0.31)), Vector3(0.7 - (i % 2) * 0.3, 0.07, 0.02), THOUGHT)
			ToonKit.box(gs, Transform3D(Basis(Vector3.BACK, 0.04), Vector3(-0.2 + (i % 2) * 0.4, y + 0.15, 0.31)), Vector3(0.07, 0.3, 0.02), THOUGHT)
		var gm := ToonKit.mesh_instance(gs.commit(), ToonKit.glow(Color(0.65, 0.9, 1.0), 1.6), "Glyphs")
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(gm)
		ToonKit.static_cylinder(self, Vector3.ZERO, 0.9, 3.2)


# =====================================================================================================
class CrackedBoulder extends Node3D:
	## Thoughtstone-veined boulder blocking the pass. `shatter()` breaks it apart and removes collision.
	var radius := 3.6
	var rock_mi: MeshInstance3D
	var veins: MeshInstance3D
	var body: StaticBody3D
	var broken := false

	func _init(spec: Dictionary, _t: Node) -> void:
		position = ReachesStructures._v3(spec.get("pos", [0, 0, 0]))
		radius = float(spec.get("radius", 3.6))
		var st := ToonKit.begin()
		ToonKit.rock(st, Vector3(0, radius * 0.55, 0), Vector3(radius, radius * 0.85, radius * 0.9), Color(0.52, 0.27, 0.22), 151, 2)
		ToonKit.rock(st, Vector3(radius * 0.8, 0.5, radius * 0.5), Vector3(1.1, 0.8, 1.0), Color(0.5, 0.27, 0.21), 152, 1)
		rock_mi = ReachesStructures._add_mesh(self, st, ToonKit.material({"outline": 0.05, "strata": 0.6}), "Boulder")
		# glowing Thoughtstone cracks: thin bright wedges on the camera-facing (+Z) side and top
		var gs := ToonKit.begin()
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 9:
			var p := Vector3(rng.randf_range(-0.75, 0.75), rng.randf_range(0.15, 0.95), 0.0)
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), 0).normalized()
			var pts: Array = []
			var q := p
			for k in 4:
				pts.append(q)
				q += d * 0.12
				d = (d + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6), 0)).normalized()
			for k in pts.size() - 1:
				var u: Vector3 = _surf(pts[k])
				var v: Vector3 = _surf(pts[k + 1])
				ToonKit.cylinder(gs, u, v, 0.09 - k * 0.015, 0.075 - k * 0.015, 4, THOUGHT, false)
		veins = ToonKit.mesh_instance(gs.commit(), ToonKit.glow(Color(0.45, 0.8, 1.0), 1.5), "Veins")
		veins.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(veins)
		body = ToonKit.static_cylinder(self, Vector3(0, -0.5, 0), radius * 0.95, radius * 1.6)

	## project a (x in -1..1, y 0..1) point onto the boulder's +Z face
	func _surf(p: Vector3) -> Vector3:
		var x := p.x * radius * 0.85
		var y := radius * 0.55 + (p.y - 0.5) * radius * 1.3
		var e := Vector2(x / radius, (y - radius * 0.55) / (radius * 0.85))
		var zz := sqrt(maxf(0.0, 1.0 - e.length_squared())) * radius * 0.9 * 1.04
		return Vector3(x, y, zz)

	func _process(_d: float) -> void:
		if veins and not broken:
			var m: StandardMaterial3D = veins.material_override
			var k := 1.3 + 0.4 * sin(Time.get_ticks_msec() * 0.004)
			m.albedo_color = Color(0.45, 0.8, 1.0) * k

	func shatter() -> void:
		if broken:
			return
		broken = true
		if body:
			body.queue_free()
			body = null
		ReachesStructures._sfx(self, "boulder_break", global_position)
		var vfx_path := "res://game/art/vfx/thoughtstone_shards.tscn"
		if ResourceLoader.exists(vfx_path):
			var v: Node3D = load(vfx_path).instantiate()
			add_child(v)
			v.position = Vector3(0, radius * 0.6, 0)
		rock_mi.visible = false
		veins.visible = false
		var mat := ToonKit.material({"outline": 0.03, "strata": 0.6})
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		var chunks := Node3D.new()
		chunks.name = "Chunks"
		add_child(chunks)
		var st := ToonKit.begin()
		for i in 9:
			var dir := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
			ToonKit.rock(st, Vector3.ZERO, Vector3.ONE * rng.randf_range(0.6, 1.2), Color(0.62, 0.36, 0.30), 200 + i, 0)
			var mi := ToonKit.mesh_instance(ToonKit.finish(st), mat)
			st = ToonKit.begin()
			mi.position = Vector3(0, radius * 0.6, 0) + dir * 0.6
			chunks.add_child(mi)
			var end := dir * rng.randf_range(radius * 0.9, radius * 2.0)
			end.y = rng.randf_range(0.2, 0.6)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(mi, "position:x", end.x, 0.7).set_ease(Tween.EASE_OUT)
			tw.tween_property(mi, "position:z", end.z, 0.7).set_ease(Tween.EASE_OUT)
			tw.tween_property(mi, "position:y", radius * 0.6 + 1.5, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(mi, "position:y", end.y, 0.4).set_delay(0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(mi, "rotation", Vector3(rng.randf() * 4.0, rng.randf() * 4.0, rng.randf() * 2.0), 0.7)
			var s := rng.randf_range(0.5, 0.9)
			tw.tween_property(mi, "scale", Vector3(s, s, s), 0.7)
		# chunks settle and sink into the ground after a while
		var tw2 := create_tween()
		tw2.tween_interval(6.0)
		tw2.tween_property(chunks, "position:y", -1.5, 2.0)
		tw2.tween_callback(chunks.queue_free)


# =====================================================================================================
class DominionCamp extends Node3D:
	## Dominion survey camp: gunmetal prefab huts with Dominion red bands, survey derrick, antenna mast,
	## crates and barricades. Red beacon glows (no real lights -> no extra passes).
	func _init(spec: Dictionary, t: Node) -> void:
		position = ReachesStructures._v3(spec.get("pos", [0, 0, 0]))
		var st := ToonKit.begin()
		var huts := [[Vector3(-1, 0, -7), 0.2], [Vector3(9.5, 0, -5.5), -0.3]]
		for h in huts:
			var p: Vector3 = h[0]
			var r: float = h[1]
			var xf := Transform3D(Basis(Vector3.UP, r), p)
			ToonKit.box(st, xf.translated_local(Vector3(0, 1.3, 0)), Vector3(4.4, 2.6, 3.2), GUNMETAL)
			ToonKit.box(st, xf.translated_local(Vector3(0, 2.7, 0)), Vector3(4.7, 0.25, 3.5), GUNMETAL.darkened(0.25))
			ToonKit.box(st, xf.translated_local(Vector3(0, 1.85, 1.62)), Vector3(4.42, 0.35, 0.05), DOM_RED)
			ToonKit.box(st, xf.translated_local(Vector3(0.9, 0.95, 1.62)), Vector3(1.1, 1.9, 0.06), GUNMETAL.darkened(0.4))
			ToonKit.static_box(self, xf.translated_local(Vector3(0, 1.3, 0)), Vector3(4.4, 2.6, 3.2))
		# survey derrick (lattice tower) behind the huts
		var dp := Vector3(4.5, 0, -11.0)
		var Ht := 9.0
		for cx: float in [-1.0, 1.0]:
			for cz: float in [-1.0, 1.0]:
				ToonKit.cylinder(st, dp + Vector3(cx * 1.6, 0, cz * 1.6), dp + Vector3(cx * 0.5, Ht, cz * 0.5), 0.12, 0.1, 4, GUNMETAL)
		for k in 5:
			var y := 1.0 + k * 1.7
			var w := lerpf(1.6, 0.5, y / Ht)
			for s: float in [-1.0, 1.0]:
				ToonKit.cylinder(st, dp + Vector3(-w, y, s * w), dp + Vector3(w, y, s * w), 0.06, 0.06, 4, DOM_RED if k % 2 == 0 else GUNMETAL, false)
				ToonKit.cylinder(st, dp + Vector3(s * w, y, -w), dp + Vector3(s * w, y, w), 0.06, 0.06, 4, GUNMETAL, false)
		ToonKit.box(st, Transform3D(Basis(), dp + Vector3(0, Ht + 0.3, 0)), Vector3(1.6, 0.6, 1.6), GUNMETAL.darkened(0.2))
		ToonKit.cylinder(st, dp + Vector3(0, -0.5, 0), dp + Vector3(0, Ht, 0), 0.22, 0.22, 6, Color(0.55, 0.55, 0.58))
		ToonKit.static_box(self, Transform3D(Basis(), dp + Vector3(0, 2.0, 0)), Vector3(3.4, 4.0, 3.4))
		# antenna mast + dish
		var mp := Vector3(-6.5, 0, -10.0)
		ToonKit.cylinder(st, mp, mp + Vector3(0, 7.0, 0), 0.12, 0.07, 5, GUNMETAL)
		ToonKit.cylinder(st, mp + Vector3(0, 5.2, 0), mp + Vector3(0.6, 5.6, 0.6), 0.9, 0.2, 8, Color(0.62, 0.62, 0.66))
		# crates + barricades
		var rng := RandomNumberGenerator.new()
		rng.seed = 208
		for i in 7:
			var p := Vector3(rng.randf_range(2, 12), 0, rng.randf_range(-3, 1.5))
			var s := rng.randf_range(0.8, 1.2)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p + Vector3(0, 0.45 * s, 0))
			ToonKit.box(st, xf, Vector3(1.1, 0.9, 0.9) * s, GUNMETAL.lightened(0.1))
			ToonKit.box(st, xf.translated_local(Vector3(0, 0.46 * s, 0)), Vector3(1.14, 0.05, 0.94) * s, DOM_RED)
			if i % 2 == 0:
				ToonKit.static_box(self, xf, Vector3(1.1, 0.9, 0.9) * s)
		for sx: float in [-1.0, 1.0]:
			var xf := Transform3D(Basis(Vector3.UP, sx * 0.4), Vector3(4.0 + sx * 9.0, 0.5, -2.0))
			ToonKit.box(st, xf, Vector3(3.0, 1.0, 0.5), Color(0.5, 0.48, 0.45))
			ToonKit.box(st, xf.translated_local(Vector3(0, 0.3, 0.26)), Vector3(3.0, 0.2, 0.02), DOM_RED)
		ReachesStructures._add_mesh(self, st, ToonKit.material({"outline": 0.035, "grain": 0.1, "metal": 0.45, "roughness": 0.5, "detail": 0.4}), "Camp")
		# Dominion red work lights (short range, shadowless: only the camp props pick up the extra light pass)
		for lp: Vector3 in [Vector3(1.5, 3.2, -4.0), dp + Vector3(0, Ht + 0.6, 1.2)]:
			var ol := OmniLight3D.new()
			ol.position = lp
			ol.light_color = Color(1.0, 0.22, 0.14)
			ol.light_energy = 1.5
			ol.omni_range = 9.0
			ol.omni_attenuation = 1.4
			ol.shadow_enabled = false
			add_child(ol)
			var q := ToonKit.quality()
			if q:
				q.call("track_light", ol, 1)
		# beacons
		var gs := ToonKit.begin()
		ToonKit.rock(gs, dp + Vector3(0, Ht + 0.8, 0), Vector3(0.3, 0.3, 0.3), DOM_RED, 1, 1)
		ToonKit.rock(gs, mp + Vector3(0, 7.15, 0), Vector3(0.2, 0.2, 0.2), DOM_RED, 2, 1)
		var gm := ToonKit.mesh_instance(gs.commit(), ToonKit.glow(Color(1.0, 0.18, 0.12), 2.5), "Beacons")
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(gm)
		# settle on the terrain
		if t:
			position.y = t.height_at(position.x, position.z)
