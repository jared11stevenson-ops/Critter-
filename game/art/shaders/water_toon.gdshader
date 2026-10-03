shader_type spatial;
// CRITTER toon water (Agent 1): painted teal pool with banded depth, drifting ripple rings and a foam rim.
// Mesh: disc/plane with UV centred (0.5, 0.5) at the pool centre; rim at UV radius 0.5.
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 deep : source_color = vec3(0.10, 0.32, 0.42);
uniform vec3 shallow : source_color = vec3(0.30, 0.66, 0.70);
uniform vec3 foam : source_color = vec3(0.92, 0.96, 0.90);
uniform vec3 glint : source_color = vec3(0.75, 0.95, 1.0);
uniform float ripple_speed = 0.35;

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5); }

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	// banded depth (cel)
	float d = 1.0 - smoothstep(0.0, 1.0, r);
	float band = floor(d * 3.0) / 3.0;
	vec3 col = mix(shallow, deep, band);
	// ripple rings from a few drifting centres
	float rings = 0.0;
	for (int i = 0; i < 3; i++) {
		vec2 c = vec2(sin(float(i) * 2.1 + TIME * 0.11), cos(float(i) * 1.7 + TIME * 0.09)) * 0.45;
		float rr = length(p - c);
		float w = fract(rr * 3.0 - TIME * ripple_speed - float(i) * 0.33);
		rings += smoothstep(0.92, 1.0, w) * (1.0 - smoothstep(0.2, 0.9, rr));
	}
	col = mix(col, glint, clamp(rings, 0.0, 1.0) * 0.45);
	// foam rim with a wobbly inner edge
	float a = atan(p.y, p.x);
	float edge = 0.86 + 0.03 * sin(a * 9.0 + TIME * 1.3) + 0.02 * sin(a * 17.0 - TIME);
	col = mix(col, foam, smoothstep(edge, edge + 0.03, r));
	// little sparkle flecks
	vec2 g = floor(UV * 60.0);
	float s = step(0.985, hash(g + floor(TIME * 2.0)));
	col += glint * s * 0.4 * (1.0 - band);
	ALBEDO = col;
}
