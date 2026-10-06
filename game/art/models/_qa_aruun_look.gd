extends Node3D
## Lookdev QA board for Aruun: one model, a sequence of lighting rigs x phone camera presets.
## tools/shot.sh res://game/art/models/_qa_aruun_look.tscn /tmp/x 2,4.5,7 8 - qa_seq=reaches:close,reaches:hero,dusk:wide
## rig = hub | reaches | dusk | boss | ice | green | noon   cam = close | hero | wide | head | face
## Camera numbers are the real follow-camera presets (camera_rig.gd CAM_MODES; fov 42), target = leader chest.
const GROUNDS := {
	"hub": Color(0.20, 0.16, 0.15), "reaches": Color(0.55, 0.32, 0.24), "dusk": Color(0.34, 0.20, 0.20),
	"boss": Color(0.30, 0.17, 0.15), "ice": Color(0.72, 0.82, 0.90), "green": Color(0.20, 0.38, 0.18), "noon": Color(0.62, 0.40, 0.30),
}
const CAMS := {"wide": [14.0, -40.0], "close": [10.0, -33.0], "hero": [7.2, -26.0]}
var wl: Node3D
var ground_mat: StandardMaterial3D
var cam: Camera3D
var model: Node3D
var seq: Array = []
var _t := 0.0
var _i := -1
var fill: OmniLight3D
var amb := -1.0


func _ready() -> void:
	seq = ["reaches:close"]
	var yaw := 0.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("qa_seq="):
			seq = a.substr(7).split(",")
		elif a.begins_with("qa_amb="):
			amb = float(a.substr(7))
		elif a.begins_with("qa_pal="):
			for kv in a.substr(7).split(";"):
				var p := kv.split("=")
				var v: Variant = float(p[1])
				if p[1].begins_with("c:"):
					var c := p[1].substr(2).split(",")
					v = Color(float(c[0]), float(c[1]), float(c[2]))
				CharacterPop.qa_override[p[0]] = v
	wl = Node3D.new()
	wl.set_script(load("res://game/world/common/world_lighting.gd"))
	wl.set("preset", "reaches")
	add_child(wl)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground_mat = StandardMaterial3D.new()
	ground_mat.roughness = 0.95
	pm.material = ground_mat
	g.mesh = pm
	add_child(g)
	model = load("res://game/art/models/aruun/aruun_model.tscn").instantiate()
	add_child(model)
	model.rotation.y = deg_to_rad(-30.0)
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 42.0
	fill = OmniLight3D.new()
	fill.visible = false
	add_child(fill)


func _process(d: float) -> void:
	_t += d
	var want := int(floor((_t - 1.5) / 2.5))
	if want > _i and _i + 1 < seq.size():
		_i += 1
		_apply(seq[_i])


func _apply(s: String) -> void:
	var p := s.split(":")
	var rig := p[0]
	var ck := p[1] if p.size() > 1 else "close"
	var lp := rig
	if rig in ["ice", "green", "noon"]:
		lp = "gate"
	wl.call("apply_preset", lp)
	if amb >= 0.0:
		wl.get("env").ambient_light_energy = amb
	ground_mat.albedo_color = GROUNDS.get(rig, Color(0.5, 0.3, 0.2))
	fill.visible = false
	if rig == "ice":
		wl.sun.light_color = Color(0.85, 0.92, 1.0)
	if rig == "green":
		wl.sun.light_color = Color(1.0, 0.95, 0.80)
	if rig == "dusk":
		wl.sun.light_color = Color(1.0, 0.55, 0.30)
	var target := Vector3(0, 1.05, 0)
	var dist := 10.0
	var pitch := -33.0
	var fov := 42.0
	if CAMS.has(ck):
		dist = CAMS[ck][0]
		pitch = CAMS[ck][1]
	elif ck == "head":
		target = Vector3(0.0, 1.8, 0.0); dist = 2.6; pitch = -8.0; fov = 38.0
	elif ck == "face":
		target = Vector3(0.1, 2.35, 0.0); dist = 7.2; pitch = -26.0; fov = 42.0   # hero camera, cropped 2x later
	cam.fov = fov
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), 0, 0))
	cam.global_transform = Transform3D(b, target + b * Vector3(0, 0, dist))
	var lp2 := cam.global_transform.affine_inverse() * Vector3(0.0, 1.9, 0.0)
	var th := tan(deg_to_rad(fov * 0.5))
	var hp := Vector2(640.0 + (lp2.x / -lp2.z) / th * 360.0, 360.0 - (lp2.y / -lp2.z) / th * 360.0)
	print("[LOOK] ", s, " head_px=", int(hp.x), ",", int(hp.y))
