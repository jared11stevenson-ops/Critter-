shader_type spatial;
// Soft painted blob shadow under billboards / creatures. (Agent 1)
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 shadow_color : source_color = vec4(0.16, 0.07, 0.06, 1.0);
uniform float strength = 0.5;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float a = (1.0 - smoothstep(0.35, 1.0, d)) * strength;
	ALBEDO = shadow_color.rgb;
	ALPHA = a;
}
