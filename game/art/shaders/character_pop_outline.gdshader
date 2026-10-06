shader_type spatial;
// Character inverted-hull outline. Screen-constant width (px at 720p) so the line stays thin on the face at close cameras and
// does not swamp the model at the wide one; per-vertex COLOR.r scales it (authored thin on faces / hands). The line colour is
// the local albedo darkened (painted ink, not flat black) when `tex_mix` > 0.
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;
uniform vec4 outline_color : source_color = vec4(0.05, 0.02, 0.08, 1.0);
uniform float width = 0.018;            // legacy: metres at 10 m (used when width_px = 0)
uniform float width_px = 0.0;           // >0: screen-constant width in pixels at 720p
uniform float tex_mix = 0.0;
uniform float ink_value = 0.22;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float flash = 0.0;
void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float d = length(INV_VIEW_MATRIX[3].xyz - wp.xyz);
	float w;
	if (width_px > 0.0) {
		w = width_px * d * 0.00107 * clamp(COLOR.r, 0.15, 1.0);
	} else {
		w = width * clamp(d / 10.0, 0.55, 2.2) * COLOR.r;
	}
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	VERTEX += normalize(NORMAL) * w / max(scale, vec3(0.001));
}
void fragment() {
	vec3 c = outline_color.rgb;
	if (tex_mix > 0.0) {
		vec3 t = texture(albedo_tex, UV).rgb;
		c = mix(c, t * ink_value + outline_color.rgb * 0.5, tex_mix);
	}
	ALBEDO = c;
}
