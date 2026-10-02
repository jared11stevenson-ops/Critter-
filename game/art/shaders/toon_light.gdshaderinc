// CRITTER shared toon lighting (Agent 1). Include AFTER render_mode in lit spatial shaders.
// 3-band cel ramp with soft edges; warm light, ambient (from the environment) supplies the cool shadow.
uniform float toon_soft = 0.06;
uniform float toon_shadow_lift = 0.0;

float toon_ramp(float ndl) {
	float a = smoothstep(0.0 - toon_soft, 0.0 + toon_soft, ndl);
	float b = smoothstep(0.42 - toon_soft, 0.42 + toon_soft, ndl);
	return a * 0.62 + b * 0.38;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float sh = ATTENUATION;
	float r = toon_ramp(ndl) * smoothstep(0.25, 0.6, sh);
	r = max(r, toon_shadow_lift);
	DIFFUSE_LIGHT += LIGHT_COLOR * r / 3.14159;
}
