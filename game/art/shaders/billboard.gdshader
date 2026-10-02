shader_type spatial;
// CRITTER character billboard — alpha scissor, ink outline, rim, flash, highlight. (Agent 1)
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

#include "res://game/art/shaders/billboard_common.gdshaderinc"

void vertex() {
	vec2 buv;
	VERTEX = billboard_vertex(VERTEX, UV, buv);
	v_uv = buv;
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_matrix(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec4 c = billboard_color();
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
