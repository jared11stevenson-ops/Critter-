shader_type spatial;
// Vertex-colour emissive with a slow per-object pulse (phase from world position): colonies breathe out of sync,
// cressets and beacons flicker lightly. Unshaded: no lights.
render_mode unshaded, cull_back;
uniform float energy = 1.8;
uniform float pulse = 0.22;
uniform float rate = 1.1;
varying float v_ph;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 cell = floor(wp.xz / 4.0);
	v_ph = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
}
void fragment() {
	float k = 1.0 - pulse + pulse * (0.5 + 0.5 * sin(TIME * rate + v_ph));
	ALBEDO = COLOR.rgb * energy * k;
}
