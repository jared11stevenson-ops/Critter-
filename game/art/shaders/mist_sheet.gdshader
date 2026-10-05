shader_type spatial;
// Chasm mist: a horizontal 3D sheet with drifting noise alpha and a soft radial edge (cheap volumetric-feel fog layer).
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 mist_color : source_color = vec4(0.86, 0.58, 0.46, 1.0);
uniform float density = 0.5;
uniform float scale = 0.045;
uniform float speed = 0.02;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
varying vec3 w_pos;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = texture(noise_tex, w_pos.xz * scale + vec2(TIME * speed, TIME * speed * 0.4)).r;
	float n2 = texture(noise_tex, w_pos.xz * scale * 2.3 - vec2(TIME * speed * 0.7, 0.0)).g;
	float edge = 1.0 - smoothstep(0.55, 1.0, length(UV * 2.0 - 1.0));
	float a = smoothstep(0.32, 0.8, n * 0.7 + n2 * 0.4) * edge * density;
	ALBEDO = mist_color.rgb;
	ALPHA = a;
}
