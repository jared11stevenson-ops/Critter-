shader_type canvas_item;
// CRITTER title backdrop grade (LOOK_PASS): split-tone (teal shadows, gold highlights), slightly calmer midtone saturation,
// warm light bloom from the upper right, soft vignette. Replaces nothing: it is the TextureRect's own material (no extra draw).
uniform float sat = 0.9;
uniform float vignette = 0.5;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 c = t.rgb;
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(vec3(l), c, sat);
	// shadows toward teal, highlights toward gold
	c = mix(c, c * vec3(0.78, 0.98, 1.10) + vec3(0.0, 0.015, 0.03), (1.0 - smoothstep(0.0, 0.5, l)) * 0.7);
	c = mix(c, c * vec3(1.10, 1.0, 0.86), smoothstep(0.45, 0.9, l) * 0.6);
	// golden-hour glow from the planet side
	float g = 1.0 - clamp(length((UV - vec2(0.78, 0.22)) * vec2(1.0, 1.4)) * 1.4, 0.0, 1.0);
	c += vec3(1.0, 0.72, 0.36) * g * g * 0.10;
	vec2 q = UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.25, 0.85, dot(q, q) * 2.2);
	COLOR = vec4(c, t.a);
}
