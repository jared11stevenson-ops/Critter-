class_name RigPalette extends RefCounted
## Thin accessor for a critter's display palette (main / accent / glow Colors) without instancing a rig.
const Pal := preload("res://src/critters/palettes.gd")
static func of(id: String) -> Dictionary:
	return Pal.get_pal(id)
