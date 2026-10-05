shader_type spatial;
// Character inverted-hull outline (Agent 4). Chained as next_pass of character_pop materials.
// Width is in screen-ish terms: grows with camera distance so the line stays ~constant at phone size.
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;
uniform vec4 outline_color : source_color = vec4(0.05, 0.02, 0.08, 1.0);
uniform float width = 0.018;            // metres at 10 m
uniform float flash = 0.0;
void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float d = length(INV_VIEW_MATRIX[3].xyz - wp.xyz);
	float w = width * clamp(d / 10.0, 0.55, 2.2) * COLOR.r;
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	VERTEX += normalize(NORMAL) * w / max(scale, vec3(0.001));
}
void fragment() {
	ALBEDO = outline_color.rgb;
}
