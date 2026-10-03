class_name VisualFactory
extends RefCounted
## Creates visuals by path (Agent 1's art when merged) with in-house fallbacks. Never references
## Agent 1 class_names; everything is loaded by path and called duck-typed.

const BILLBOARD := "res://game/art/characters/character_billboard.tscn"
static var _scene_cache: Dictionary = {}

static func _scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path]
	var ps: PackedScene = null
	if ResourceLoader.exists(path):
		var r: Variant = load(path)
		if r is PackedScene:
			ps = r
	_scene_cache[path] = ps
	return ps

static func character(id: String) -> Node3D:
	var ps := _scene(BILLBOARD)
	if ps:
		var n: Node = ps.instantiate()
		if n is Node3D:
			if "character_id" in n:
				n.set("character_id", id)
			return n as Node3D
		n.free()
	var fb := FallbackVisual.new()
	fb.setup(id, "character")
	return fb

static func creature(species_id: String) -> Node3D:
	var ps := _scene("res://game/art/creatures/%s.tscn" % species_id)
	if ps:
		var n: Node = ps.instantiate()
		if n is Node3D:
			return n as Node3D
		n.free()
	var fb := FallbackVisual.new()
	fb.setup(species_id, "creature")
	return fb

static func has_creature_art(species_id: String) -> bool:
	return _scene("res://game/art/creatures/%s.tscn" % species_id) != null

## Generic visual API call with existence check.
static func call_v(v: Object, method: String, args: Array = []) -> Variant:
	if v and is_instance_valid(v) and v.has_method(method):
		return v.callv(method, args)
	return null

## Locate a marker on a visual: direct child, nested, or via get_marker().
static func marker(v: Node, marker_name: String) -> Node3D:
	if v == null:
		return null
	if v.has_method("get_marker"):
		var m: Variant = v.get_marker(marker_name)
		if m is Node3D:
			return m
	var found := v.find_child(marker_name, true, false)
	return found as Node3D
