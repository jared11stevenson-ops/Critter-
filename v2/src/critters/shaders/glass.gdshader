shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;
// Transparent wing glass (Zell). Vertex color RGB = tint, A = vein mask (opaque white-ish veins). No outline pass.
uniform float membrane : hint_range(0.0, 1.0) = 0.38;
uniform float glow : hint_range(0.0, 3.0) = 1.0;
uniform float silhouette : hint_range(0.0, 1.0) = 0.0;
uniform vec3 edge_col : source_color = vec3(0.2, 0.4, 1.0);
varying vec4 vc;
void vertex() { vc = COLOR; }
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	vec3 c = mix(vc.rgb, vec3(1.0), vc.a * 0.6);
	ALBEDO = c + edge_col * rim * 0.6 * glow;
	ALPHA = clamp(membrane + vc.a * 0.6 + rim * 0.3, 0.0, 0.95);
	if (silhouette > 0.5) {
		ALBEDO = vec3(0.0);
		ALPHA = 1.0;
	}
}
