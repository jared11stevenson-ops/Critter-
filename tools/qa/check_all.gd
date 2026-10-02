extends Node
## Loads every script and instantiates every scene under res://game. Errors print to stderr.
## Run: tools/validate.sh
var loaded := 0
var failed: Array = []

func _ready() -> void:
	await get_tree().process_frame
	_walk("res://game")
	print("[CHECK] loaded=%d failed=%d" % [loaded, failed.size()])
	for f in failed:
		print("[CHECK] FAIL ", f)
	get_tree().quit(1 if failed.size() > 0 else 0)

func _walk(dir_path: String) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir_path + "/" + n
		if d.current_is_dir():
			if not n.begins_with("."):
				_walk(p)
		elif n.ends_with(".gd") or n.ends_with(".tscn") or n.ends_with(".gdshader") or n.ends_with(".tres"):
			var r := ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_REUSE)
			if r == null:
				failed.append(p)
			else:
				loaded += 1
				if r is PackedScene and not p.contains("/boot/"):
					var inst: Node = (r as PackedScene).instantiate()
					if inst == null:
						failed.append(p + " (instantiate)")
					else:
						inst.free()
				elif r is GDScript and not (r as GDScript).can_instantiate():
					failed.append(p + " (script compile)")
		n = d.get_next()
