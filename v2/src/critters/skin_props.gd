extends RefCounted
## Procedural props for skinned critters (built in code, no files): Bramvex's club "Diplomacy" (thorn-studded, handle thin, head heavy).
## Long axis = +X, the grip (hand) is at the origin, the pommel sits slightly behind it. Vertex colours (the toon shader reads them).

static func club(length := 2.3, handle_r := 0.055, head_r := 0.20) -> ArrayMesh:
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var seg := 16
	var rings := 56
	var wood := Color(0.20, 0.125, 0.08)
	var dark := Color(0.09, 0.06, 0.045)
	var wrap := Color(0.40, 0.12, 0.10)             # the sergeant's red insignia cloth wrapped on the grip
	var back := -0.10 * length
	for r in rings + 1:
		var t := float(r) / float(rings)
		var rad := _radius(t, handle_r, head_r)
		var c := wood.lerp(dark, smoothstep(0.55, 0.9, t) * 0.5)
		if t > 0.08 and t < 0.26 and (r % 3 != 2):
			c = wrap
		for s in seg:
			var a := TAU * float(s) / float(seg)
			var n := Vector3(0, cos(a), sin(a))
			var grain := 0.80 + 0.30 * (0.5 + 0.5 * sin(a * 3.0 + t * 38.0)) * (0.5 + 0.5 * sin(t * 90.0 + float(s) * 1.7))     # wood grain streaks crossed by growth rings
			var scorch := smoothstep(0.80, 0.97, t) * 0.55                                          # the striking face is charred
			verts.append(Vector3(back + t * length, 0, 0) + n * rad * (1.0 + 0.025 * sin(a * 5.0 + t * 24.0)))     # gnarled, not a lathe-turned cylinder
			norms.append(n)
			cols.append((c * grain).lerp(Color(0.05, 0.04, 0.035), scorch))
	for r in rings:
		for s in seg:
			var a0 := r * seg + s
			var a1 := r * seg + (s + 1) % seg
			idx.append_array([a0, a0 + seg, a1, a1, a0 + seg, a1 + seg])        # clockwise = front face in Godot
	# end cap (head)
	var cap := verts.size()
	verts.append(Vector3(back + length, 0, 0)); norms.append(Vector3.RIGHT); cols.append(dark)
	for s in seg:
		idx.append_array([(rings) * seg + s, (rings) * seg + (s + 1) % seg, cap])
	# thorns: cones in a spiral on the head
	var thorns := 30
	for i in thorns:
		var t2 := 0.52 + 0.45 * float(i) / float(thorns - 1)
		var a2 := float(i) * 2.399963                # golden angle
		var rad2 := _radius(t2, handle_r, head_r)
		var dir := Vector3(0.35, cos(a2), sin(a2)).normalized()    # leans toward the tip
		var base := Vector3(back + t2 * length, 0, 0) + Vector3(0, cos(a2), sin(a2)) * rad2 * 0.92
		var perp := dir.cross(Vector3.RIGHT).normalized() * 0.032
		var perp2 := dir.cross(perp).normalized() * 0.032
		var tip := base + dir * (0.13 + 0.05 * sin(float(i) * 1.7))
		var b0 := verts.size()
		for k in 4:
			var ang := TAU * float(k) / 4.0
			verts.append(base + perp * cos(ang) + perp2 * sin(ang))
			norms.append((perp * cos(ang) + perp2 * sin(ang)).normalized())
			cols.append(Color(0.14, 0.09, 0.07))
		verts.append(tip); norms.append(dir); cols.append(Color(0.1, 0.07, 0.06))
		for k in 4:
			idx.append_array([b0 + (k + 1) % 4, b0 + k, b0 + 4])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m

static func _radius(t: float, h: float, hd: float) -> float:
	if t < 0.04:
		return h * (1.5 + 3.0 * t)                    # pommel knob
	var k := smoothstep(0.42, 0.82, t)
	var r := lerpf(h, hd, k)
	if t > 0.94:
		r *= sqrt(maxf(0.0, (1.0 - t) / 0.06))        # rounded end
	return r
