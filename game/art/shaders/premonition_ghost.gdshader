shader_type spatial;
// Premonition "future ghost" tint for duplicated creatures / props (Agent 1). Additive violet with fresnel
// edges and drifting scanlines. Works on any mesh (toon creatures included).
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 ghost_color : source_color = vec4(0.62, 0.42, 1.0, 1.0);
uniform float ghost_alpha = 0.55;
uniform float scan_speed = 2.0;

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float scan = 0.7 + 0.3 * sin(FRAGCOORD.y * 0.6 - TIME * scan_speed * 6.0);
	ALBEDO = ghost_color.rgb * (0.25 + fres * 1.2) * scan * ghost_alpha;
}
