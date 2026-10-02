extends Node
## Read-only access to the canon database (res://game/canon/canon.json).
## Everything the game says about the world comes from here or from narrative scripts that cite the bible.

var data: Dictionary = {}

func _ready() -> void:
	var f := FileAccess.open("res://game/canon/canon.json", FileAccess.READ)
	if f == null:
		push_error("Canon: canon.json missing")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed
	else:
		push_error("Canon: canon.json failed to parse")

func character(id: String) -> Dictionary:
	return data.get("characters", {}).get(id, {})

func ability(id: String) -> Dictionary:
	return data.get("abilities", {}).get(id, {})

func species(id: String) -> Dictionary:
	return data.get("species", {}).get(id, {})

func place(id: String) -> Dictionary:
	return data.get("places", {}).get(id, {})

func display_name(id: String) -> String:
	var c := character(id)
	return c.get("name", id.capitalize())
