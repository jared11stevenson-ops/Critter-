shader_type spatial;
// Light shaft: an open 3D cone/cylinder (not a sprite) that fades toward its rim (fresnel) and along its length, with slow
// drifting dust banding. Additive, unshaded, no depth write. One draw call each; used sparingly (god rays).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 shaft_color : source_color = vec4(1.0, 0.78, 0.5, 1.0);
uniform float intensity = 0.55;
uniform float drift = 0.25;
uniform float seed = 0.0;

void fragment() {
	float rim = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 2.4);
	float along = clamp(UV.y, 0.0, 1.0);             // 0 = sun end (top), 1 = ground end
	float fade = smoothstep(0.0, 0.25, along) * (1.0 - smoothstep(0.45, 1.0, along));
	float band = 0.62 + 0.38 * sin(UV.x * 31.4159 * 1.7 + TIME * drift + seed) * sin(UV.x * 9.4 - TIME * drift * 0.6 + along * 3.0);
	ALBEDO = shaft_color.rgb * intensity * rim * fade * band;
	ALPHA = 1.0;
}
