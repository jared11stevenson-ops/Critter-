shader_type sky;
// Lumen Depths vault sky: no sun, a far ceiling dome with living constellations, drifting plankton nebulae, and a jagged
// horizon of distant cavern wall. Uniforms mirror sky_reaches so CritterLighting can drive either.
#include "res://game/art/shaders/lumen_stars.gdshaderinc"

uniform vec3 zenith_color : source_color = vec3(0.02, 0.04, 0.10);
uniform vec3 mid_color : source_color = vec3(0.04, 0.09, 0.18);
uniform vec3 horizon_color : source_color = vec3(0.08, 0.20, 0.28);
uniform vec3 sun_tint : source_color = vec3(0.5, 0.8, 1.0);
uniform float cloud_time = 0.0;
uniform float star_density = 0.2;

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lh(i), lh(i + vec2(1.0, 0.0)), f.x), mix(lh(i + vec2(0.0, 1.0)), lh(i + vec2(1.0, 1.0)), f.x), f.y);
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon_color, mid_color, smoothstep(0.0, 0.3, h));
	col = mix(col, zenith_color, smoothstep(0.25, 0.95, h));
	if (h < 0.0) {
		col = mix(horizon_color * 0.6, zenith_color, smoothstep(0.0, 0.5, -h));
	}
	// plankton nebula: two slow bands of teal / violet light
	vec2 uv = vec2(atan(d.z, d.x) * 1.4, h * 3.2);
	float nb = n2(uv * 1.6 + vec2(cloud_time * 0.004, 0.0)) * 0.6 + n2(uv * 3.7 - 4.0) * 0.4;
	col += vec3(0.05, 0.22, 0.26) * smoothstep(0.45, 0.85, nb) * smoothstep(0.0, 0.3, h) * (1.0 - smoothstep(0.5, 0.95, h)) * 0.9;
	col += vec3(0.16, 0.08, 0.22) * smoothstep(0.55, 0.9, n2(uv * 2.2 + 9.0)) * smoothstep(0.1, 0.5, h) * 0.6;
	// constellations
	col += lumen_stars(d, cloud_time + TIME * 0.0, star_density);
	// jagged cavern rim at the horizon
	float a = atan(d.z, d.x);
	float rim = 0.05 + 0.07 * n2(vec2(a * 6.0, 1.0)) + 0.05 * n2(vec2(a * 17.0, 3.0)) + 0.03 * sin(a * 41.0);
	float wall = 1.0 - smoothstep(rim - 0.01, rim + 0.012, h);
	col = mix(col, vec3(0.012, 0.02, 0.04), wall * smoothstep(-0.2, 0.0, h + 0.3));
	COLOR = col;
}
