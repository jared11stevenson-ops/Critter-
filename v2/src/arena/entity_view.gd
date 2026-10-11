class_name EntityView extends Node3D
## Draws the sim's world entities (projectiles, zones/traps, phantoms) from state()["entities"] with a small pool of
## unshaded meshes. No gameplay here: positions and radii come straight from the sim snapshot.

const POOL := 14
var _meshes: Array[MeshInstance3D] = []
var _mats := {}
var _t := 0.0
var colors: Array = [Color(1.0, 0.8, 0.3), Color(0.5, 0.9, 1.0)]    # per owner (fighter glow colors)

func _ready() -> void:
	var sph := SphereMesh.new()
	sph.radius = 0.5; sph.height = 1.0; sph.radial_segments = 10; sph.rings = 5
	for i in POOL:
		var mi := MeshInstance3D.new()
		mi.mesh = sph
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_meshes.append(mi)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0; disc.bottom_radius = 1.0; disc.height = 0.04; disc.radial_segments = 28; disc.rings = 1
	_mats["disc"] = disc

func _mat(c: Color, alpha: float) -> StandardMaterial3D:
	var key := "%s%.2f" % [c.to_html(), alpha]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(c.r, c.g, c.b, alpha)
		if alpha < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[key] = m
	return _mats[key]

func show_entities(ents: Array, dt: float) -> void:
	_t += dt
	var sph: Mesh = _meshes[0].mesh if not _meshes.is_empty() else null
	var n := 0
	for e in ents:
		if n >= POOL:
			break
		var mi := _meshes[n]
		var col: Color = colors[clampi(int(e["owner"]), 0, 1)]
		var p: Vector2 = e["pos"]
		var r := float(e["radius"])
		mi.visible = true
		match str(e["kind"]):
			"zone":
				mi.mesh = _mats["disc"]
				mi.position = Vector3(p.x, 0.05, p.y)
				mi.scale = Vector3(r, 1.0, r)
				mi.material_override = _mat(col.lerp(Color(0.5, 0.95, 0.3) if str(e["tag"]) == "fungus" else col, 0.4), 0.28 + 0.1 * sin(_t * 5.0))
			"phantom":
				mi.mesh = sph
				mi.position = Vector3(p.x, 0.9, p.y)
				mi.scale = Vector3(0.8, 1.7, 0.8)
				mi.material_override = _mat(col, 0.45)
			_:
				mi.mesh = sph
				mi.position = Vector3(p.x, 1.0, p.y)
				mi.scale = Vector3.ONE * maxf(0.3, r * 1.6)
				mi.material_override = _mat(col.lightened(0.35), 1.0)
		n += 1
	for i in range(n, POOL):
		_meshes[i].visible = false
