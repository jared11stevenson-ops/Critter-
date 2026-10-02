shader_type spatial;
// CRITTER character billboard — translucent ghost variant (False Memory decoys, Premonition future ghosts).
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

#include "res://game/art/shaders/billboard_common.gdshaderinc"

uniform vec4 ghost_color : source_color = vec4(0.62, 0.42, 1.0, 1.0);
uniform float ghost_alpha = 0.5;
uniform float ghost_time_scale = 1.0;

void vertex() {
	VERTEX = billboard_vertex(VERTEX, UV);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_matrix(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec4 c = billboard_color();
	float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	// scanline shimmer + brighter edges so the silhouette reads
	float scan = 0.75 + 0.25 * sin(FRAGCOORD.y * 0.9 + TIME * 6.0 * ghost_time_scale);
	float a = step(0.5, c.a);
	float edge = 1.0 - smoothstep(0.0, 0.25, lum);
	vec3 col = ghost_color.rgb * (0.35 + lum * 1.1 + edge * 0.6) * scan;
	ALBEDO = col * ghost_alpha * a;
	ALPHA = 1.0;
}
