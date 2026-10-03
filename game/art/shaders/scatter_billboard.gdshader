shader_type spatial;
// CRITTER scatter billboards (MultiMesh): painted plants / trees / rocks cut from the Reaches kit.
// INSTANCE_CUSTOM = atlas uv rect (u0, v0, u1, v1). Instance COLOR: r = sway, g = tint variation, b = flip.
// Instance basis scale = (width m, height m, 1). Quad: 1x1 centred at (0, 0.5).
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 light_tint : source_color = vec3(1.0, 0.96, 0.9);
uniform vec3 shade_tint : source_color = vec3(0.78, 0.66, 0.72);
uniform float wind = 1.0;

varying vec4 v_rect;
varying vec2 v_uv;
varying float v_var;
varying float v_h;
varying vec3 w_pos;
uniform vec3 critter_focus_pos;
uniform vec3 critter_cam_pos;
#include "res://game/art/shaders/occlusion_fade.gdshaderinc"

void vertex() {
	v_rect = INSTANCE_CUSTOM;
	vec2 uv = UV;
	if (COLOR.b > 0.5) {
		uv.x = 1.0 - uv.x;
	}
	v_uv = uv;
	v_var = COLOR.g;
	v_h = UV.y;
	vec3 v = VERTEX;
	float hy = clamp(v.y, 0.0, 1.0);
	vec3 org = MODEL_MATRIX[3].xyz;
	float sway = sin(TIME * 1.7 + org.x * 0.37 + org.z * 0.21) * 0.5 + sin(TIME * 2.9 + org.x) * 0.2;
	v.x += sway * COLOR.r * wind * hy * hy * 0.12;
	// Y-axis billboard toward the camera, keeping instance scale
	vec3 cam_x = normalize(INV_VIEW_MATRIX[0].xyz);
	cam_x.y = 0.0;
	cam_x = normalize(cam_x);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 z = cross(cam_x, up);
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	mat4 m = mat4(vec4(cam_x * sx, 0.0), vec4(up * sy, 0.0), vec4(z, 0.0), MODEL_MATRIX[3]);
	VERTEX = v;
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
	w_pos = (m * vec4(v, 1.0)).xyz;
}

void fragment() {
	vec2 uv = mix(v_rect.xy, v_rect.zw, vec2(v_uv.x, v_uv.y));
	vec4 c = texture(atlas, uv, -0.4);
	if (c.a < 0.5) {
		discard;
	}
	occ_discard(w_pos, FRAGCOORD.xy);
	// painted art already carries its shading; tint by scene light, darken the base a touch (contact)
	vec3 col = c.rgb * light_tint * (0.92 + v_var * 0.16);
	col = mix(col * shade_tint, col, smoothstep(0.0, 0.35, 1.0 - v_h));
	ALBEDO = col;
}
