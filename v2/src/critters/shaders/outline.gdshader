shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;
// Inverted-hull outline. Used as next_pass of the toon material (same mesh, 2nd draw).
// Width is in screen pixels (scaled by viewport height), so it stays inked at any camera distance.
// Color = the part's own vertex color pushed to its darkest tone (never pure black).

uniform float px_width = 3.0;
uniform float min_world = 0.004;
uniform float max_world = 0.06;
uniform float darken : hint_range(0.0, 1.0) = 0.16;
uniform vec3 ink : source_color = vec3(0.05, 0.03, 0.05);
uniform float ink_mix : hint_range(0.0, 1.0) = 0.45;
uniform float invert_mode : hint_range(0.0, 1.0) = 0.0;
uniform float silhouette : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_ink;

void vertex() {
	vec4 vv = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float depth = max(-vv.z, 0.05);
	float w = px_width * 2.0 * depth / (abs(PROJECTION_MATRIX[1][1]) * max(VIEWPORT_SIZE.y, 1.0));
	w = clamp(w, min_world, max_world);
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vv.xyz += nv * w;
	POSITION = PROJECTION_MATRIX * vv;
	v_ink = mix(COLOR.rgb * darken, ink, ink_mix);
}

void fragment() {
	ALBEDO = mix(v_ink, vec3(0.0), max(invert_mode, silhouette));
}
