extends SceneTree
## Blender-ready export: godot --headless --path v2 --script res://src/critters/tools/export_glb.gd -- [--ids=a,b] [--out=res://art_export]
## Writes <out>/<id>.glb (A-pose, named part nodes with pivots at the joints, vertex-colored materials, sockets as empty nodes named socket_*)
## and <out>/<id>_parts.md (part list, dimensions, tri counts). Then RE-IMPORTS each .glb and prints node / mesh / tri counts as verification.
## Notes: the outline hull is a render pass (next_pass shader) and is not exported; tri counts in the md are fill tris (x2 with outline).
const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")

func _initialize() -> void:
	await process_frame
	var ids: PackedStringArray = Pal.IDS
	var out := "res://art_export"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for id in ids:
		_export(id, out)
	quit()

func _std(color_vertex: bool, alpha: bool, nm: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = nm
	m.vertex_color_use_as_albedo = color_vertex
	m.albedo_color = Color.WHITE
	m.roughness = 1.0
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.7, 1.0, 0.7, 0.45)
	return m

func _prep(n: Node, parts: Array) -> void:
	for c in n.get_children():
		if c.name in ["spark", "smear", "thread"]:
			c.free()
			continue
		if c is Marker3D:
			var e := Node3D.new()
			e.name = c.name
			e.transform = (c as Node3D).transform
			var par := c.get_parent()
			var idx := c.get_index()
			par.remove_child(c)
			c.free()
			par.add_child(e)
			par.move_child(e, idx)
			continue
		if c is MultiMeshInstance3D:   # swarm -> individual named meshes (one per body) so Blender gets separate spheres
			var mmi := c as MultiMeshInstance3D
			for i in range(mmi.multimesh.instance_count):
				var one := MeshInstance3D.new()
				one.name = "%s_%d" % [mmi.name, i]
				one.mesh = mmi.multimesh.mesh
				one.transform = mmi.multimesh.get_instance_transform(i)
				mmi.get_parent().add_child(one)
			c.free()
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var isface: bool = mi.name == "face"
			var glass: bool = mi.material_override is ShaderMaterial and (mi.material_override as ShaderMaterial).shader.resource_path.ends_with("glass.gdshader")
			mi.material_override = _std(not isface and not glass, glass, "%s_%s" % [mi.name, "face_plate" if isface else ("glass" if glass else "toon_vertex_color")])
			if mi.mesh != null and mi.mesh is ArrayMesh:
				var am := mi.mesh as ArrayMesh
				var tris := am.surface_get_array_index_len(0) / 3
				parts.append([mi.name, am.get_aabb().size, tris, mi.position])
		_prep(c, parts)

func _export(id: String, out: String) -> void:
	var rig = Rig.new()
	root.add_child(rig)
	rig.setup(id)
	rig.apose_deg = 35.0
	rig.three_quarter = 0.0
	rig.apply_fighter_state({"action": "idle", "action_frame": 0, "facing": 1.0}, 1.0 / 60.0)
	rig.name = id
	var parts: Array = []
	_prep(rig, parts)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(rig, state)
	var path := "%s/%s.glb" % [out, id]
	if err == OK:
		err = doc.write_to_filesystem(state, path)
	print("EXPORT ", id, " -> ", path, " err=", err)
	# parts md
	var tot := 0
	var md := "# %s - parts (exported A-pose, meters)\n\nPivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.\nSockets are empty nodes named `socket_*`.\n\n| part | size x/y/z (m) | tris (fill) | pivot in parent |\n|---|---|---|---|\n" % id
	for p in parts:
		var sz: Vector3 = p[1]
		md += "| %s | %.2f / %.2f / %.2f | %d | (%.2f, %.2f, %.2f) |\n" % [p[0], sz.x, sz.y, sz.z, p[2], (p[3] as Vector3).x, (p[3] as Vector3).y, (p[3] as Vector3).z]
		tot += p[2]
	md += "\n**Total fill tris: %d (x2 with the outline hull = %d; budget 6000).** Draw calls in engine: see test_art_build.\n" % [tot, tot * 2]
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/%s_parts.md" % [out, id]), FileAccess.WRITE)
	f.store_string(md)
	f.close()
	rig.free()
	# verify by re-importing
	var d2 := GLTFDocument.new()
	var s2 := GLTFState.new()
	var e2 := d2.append_from_file(ProjectSettings.globalize_path(path), s2)
	if e2 != OK:
		print("VERIFY ", id, " re-import FAILED ", e2)
		return
	var scene := d2.generate_scene(s2)
	var counts := {"nodes": 0, "meshes": 0, "tris": 0, "empties": 0}
	_count(scene, counts)
	print("VERIFY %s nodes=%d meshes=%d empties(sockets)=%d tris=%d (exported fill tris=%d)" % [id, counts["nodes"], counts["meshes"], counts["empties"], counts["tris"], tot])
	scene.free()

func _count(n: Node, c: Dictionary) -> void:
	c["nodes"] += 1
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		c["meshes"] += 1
		var m := (n as MeshInstance3D).mesh
		for s in range(m.get_surface_count()):
			c["tris"] += (m.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	elif n.get_class() == "Node3D" and str(n.name).begins_with("socket_"):
		c["empties"] += 1
	for ch in n.get_children():
		_count(ch, c)
