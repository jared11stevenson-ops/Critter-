class_name Telegraph
extends MeshInstance3D
## Ground telegraph: outline + fill that grows over the windup, then a flash and free.
## Modes: circle, rect (line strike), arc (beam sweep). Runs on scaled time so slow-mo stays honest.

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.25, 0.15, 1.0);
uniform float progress = 0.0;
uniform int mode = 0;
uniform float a0 = 0.0;
uniform float a1 = 1.0;
uniform float flash = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float a = 0.0;
	if (mode == 1) {
		float e = max(abs(p.x), abs(p.y));
		if (e > 1.0) discard;
		float outline = smoothstep(0.86, 0.94, abs(p.x)) + smoothstep(0.96, 0.99, abs(p.y));
		float filled = step(1.0 - UV.y, progress);
		a = clamp(outline * 0.9 + filled * 0.32 + 0.08, 0.0, 1.0);
	} else {
		float r = length(p);
		if (r > 1.0) discard;
		if (mode == 2) {
			float ang = atan(p.y, p.x);
			float span = a1 - a0;
			float rel = mod(ang - a0 + 12.566370, 6.2831853);
			if (rel > span) discard;
			float edge = min(rel, span - rel) * r;
			float outline = smoothstep(0.92, 0.98, r) + (1.0 - smoothstep(0.0, 0.06, edge));
			a = clamp(outline * 0.9 + step(r, progress) * 0.3 + 0.08, 0.0, 1.0);
		} else {
			float outline = smoothstep(0.86, 0.95, r);
			float inner = step(r, progress) * 0.34;
			float rim = smoothstep(progress - 0.06, progress, r) * step(r, progress) * 0.5;
			a = clamp(outline * 0.95 + inner + rim + 0.07, 0.0, 1.0);
		}
	}
	ALBEDO = mix(col.rgb, vec3(1.0, 0.95, 0.85), flash);
	ALPHA = a * col.a;
}
"""

static var _shader: Shader = null
var _mat: ShaderMaterial
var _dur := 1.0
var _t := 0.0
var _done := false
var hostile := true
var _mode := 0
var _c := Vector3.ZERO
var _r := 1.0
var _dir := Vector3.FORWARD
var _len := 1.0
var _w := 1.0
var _arc := Vector2.ZERO

func _init() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.render_priority = 2
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _ground(pos: Vector3) -> Vector3:
	var y := pos.y
	if Field.current:
		y = Field.current.height_at(pos.x, pos.z)
	return Vector3(pos.x, y + 0.08, pos.z)

func setup_circle(pos: Vector3, radius: float, dur: float, col: Color) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	mesh = pm
	global_position = _ground(pos)
	_c = pos
	_r = radius
	_start(dur, col, 0)

func setup_rect(origin: Vector3, dir: Vector3, length: float, width: float, dur: float, col: Color) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(width, length)
	mesh = pm
	var d := Vector3(dir.x, 0, dir.z).normalized()
	if d.length_squared() < 0.01:
		d = Vector3.FORWARD
	var center := origin + d * length * 0.5
	global_position = _ground(center)
	look_at(global_position + d, Vector3.UP)
	_c = origin
	_dir = d
	_len = length
	_w = width
	_start(dur, col, 1)

func setup_arc(origin: Vector3, from_angle: float, to_angle: float, radius: float, dur: float, col: Color) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	mesh = pm
	global_position = _ground(origin)
	_mat.set_shader_parameter("a0", from_angle)
	_mat.set_shader_parameter("a1", to_angle)
	_c = origin
	_r = radius
	_arc = Vector2(from_angle, to_angle)
	_start(dur, col, 2)

func _start(dur: float, col: Color, mode: int) -> void:
	_mode = mode
	if hostile and Field.current:
		Field.current.dangers.append(self)
	_dur = maxf(0.05, dur)
	_t = 0.0
	_mat.set_shader_parameter("col", col)
	_mat.set_shader_parameter("mode", mode)
	_mat.set_shader_parameter("progress", 0.0)

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var p := clampf(_t / _dur, 0.0, 1.0)
	_mat.set_shader_parameter("progress", p)
	if p >= 1.0:
		_done = true
		var fl := 0.0 if bool(GameState.settings.get("reduce_flashing", false)) else 0.8
		_mat.set_shader_parameter("flash", fl)
		var tw := create_tween()
		tw.tween_method(func(v): _mat.set_shader_parameter("flash", v), fl, 0.0, 0.12)
		tw.tween_callback(queue_free)

func cancel() -> void:
	queue_free()

func _exit_tree() -> void:
	if Field.current:
		Field.current.dangers.erase(self)

## Direction to step out of this zone (ZERO if outside). Used by the partner AI.
func escape_vector(p: Vector3) -> Vector3:
	var to := Vector3(p.x - _c.x, 0, p.z - _c.z)
	match _mode:
		0:
			if to.length() < _r + 0.8:
				return to.normalized() if to.length() > 0.1 else Vector3.RIGHT
		1:
			var along := to.dot(_dir)
			if along > -0.5 and along < _len + 0.5:
				var perp := to - _dir * along
				if perp.length() < _w * 0.5 + 0.8:
					var side := perp.normalized() if perp.length() > 0.05 else Vector3(-_dir.z, 0, _dir.x)
					return side
		2:
			if to.length() < _r:
				var ang := atan2(to.z, to.x)
				var rel := fposmod(ang - _arc.x, TAU)
				if rel <= _arc.y - _arc.x:
					return -to.normalized()
	return Vector3.ZERO
