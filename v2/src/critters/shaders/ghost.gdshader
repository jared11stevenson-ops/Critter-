shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, depth_draw_never, blend_add;
// Translucent "future ghost" copy of a rig (Cigarra's Premonition). Fresnel-bright silhouette, no outline pass.
uniform vec3 tint : source_color = vec3(0.45, 0.6, 1.0);
uniform float alpha = 0.5;
void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 1.6);
	ALBEDO = tint * (0.12 + rim * 0.6);
	ALPHA = alpha * (0.25 + rim * 0.8);
}
