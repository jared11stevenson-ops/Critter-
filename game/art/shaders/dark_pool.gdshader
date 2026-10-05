shader_type spatial;
// Lumen dark pool: still black water that mirrors the living constellations, with a faint cyan rim shimmer.
render_mode unshaded, cull_disabled, shadows_disabled;
#include "res://game/art/shaders/lumen_stars.gdshaderinc"

uniform vec3 deep : source_color = vec3(0.01, 0.03, 0.06);
uniform vec3 rim_col : source_color = vec3(0.30, 0.8, 0.9);
uniform float star_density = 0.2;

varying vec3 w_pos;
void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 V = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);   // surface -> camera, world space
	vec3 R = reflect(-V, vec3(0.0, 1.0, 0.0));
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	vec3 rip = vec3(0.0, 0.0, 0.0);
	// slow ripple distortion of the reflection
	R.xz += vec2(sin(w_pos.x * 1.7 + TIME * 0.5), cos(w_pos.z * 1.3 + TIME * 0.4)) * 0.025;
	vec3 st = lumen_stars(normalize(R), TIME, star_density);
	float fres = pow(1.0 - clamp(dot(V, vec3(0.0, 1.0, 0.0)), 0.0, 1.0), 2.5);
	vec3 col = deep + st * (0.55 + 0.6 * fres) + rim_col * smoothstep(0.82, 1.0, r) * 0.35 * (0.6 + 0.4 * sin(TIME * 0.8 + r * 20.0));
	ALBEDO = col;
	ALPHA = 1.0 - smoothstep(0.96, 1.0, r) * 0.7;
}
