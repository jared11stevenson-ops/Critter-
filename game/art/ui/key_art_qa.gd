extends Node3D
## Renders the title key art (Agent 1): Red Reaches vista, ringed planet, Aruun + Cigarra in the foreground.
## tools/shot.sh res://game/art/ui/key_art_qa.tscn <out> 2.5 3   then downscale to game/art/ui/key_art_title.png

var terrain: RedReachesTerrain


func _ready() -> void:
	terrain = RedReachesTerrain.new()
	add_child(terrain)
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 900.0
	add_child(cam)
	cam.current = true
	var f := Vector3(262, -2, -1.4)
	f.y = terrain.height_at(f.x, f.z)
	cam.position = f + Vector3(-2.4, 1.6, 4.9)
	cam.look_at(f + Vector3(5.0, 2.6, -14.0), Vector3.UP)
	RenderingServer.global_shader_parameter_set("critter_focus_pos", Vector3.ZERO)
	var spots := {"aruun": Vector3(-1.4, 0, -0.4), "cigarra": Vector3(1.2, 0, 0.9)}
	for id in spots:
		var bb: Node3D = VisualFactory.character(id)
		add_child(bb)
		var p: Vector3 = f + spots[id]
		p.y = terrain.height_at(p.x, p.z)
		bb.position = p
		bb.call_deferred("set_facing", Vector3(0.2, 0, 1))
	var sky: ShaderMaterial = terrain.lighting.get("sky_mat")
	if sky:
		sky.set_shader_parameter("planet_dir", Vector3(0.38, 0.30, -0.87))
		sky.set_shader_parameter("planet_size", 0.2)
