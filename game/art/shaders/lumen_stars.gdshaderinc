// Lumen Depths living constellations: pulsing bioluminescent colonies on a far vault ceiling, drifting very slowly
// (their movement marks season / migration / danger). Shared by the vault sky and the dark-pool reflection.
float lh(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 lumen_stars(vec3 d, float t, float density) {
	float u = atan(d.z, d.x) / 6.28318 + 0.5 + t * 0.0016;
	float v = asin(clamp(d.y, -1.0, 1.0)) / 1.5708;
	vec3 acc = vec3(0.0);
	for (int layer = 0; layer < 2; layer++) {
		float sc = layer == 0 ? 90.0 : 38.0;
		vec2 g = vec2(u * sc, v * sc * 0.5);
		vec2 id = floor(g);
		vec2 f = fract(g);
		float h = lh(id + float(layer) * 17.0);
		if (h > density) continue;
		vec2 c = vec2(0.25 + 0.5 * lh(id + 3.1), 0.25 + 0.5 * lh(id + 7.7));
		float r = length(f - c);
		float size = (layer == 0 ? 0.09 : 0.14) * (0.5 + lh(id + 1.3));
		float pulse = 0.55 + 0.45 * sin(t * (0.6 + 1.6 * lh(id + 9.0)) + lh(id) * 40.0);
		float s = smoothstep(size, 0.0, r) * pulse;
		float k = lh(id + 5.5);
		vec3 col = k < 0.45 ? vec3(0.55, 0.85, 1.0) : (k < 0.75 ? vec3(0.95, 0.9, 0.6) : vec3(0.95, 0.6, 0.85));
		acc += col * s * (layer == 0 ? 0.9 : 1.6);
	}
	return acc * smoothstep(-0.02, 0.18, d.y);
}
