shader_type spatial;
render_mode cull_back, diffuse_lambert, shadows_disabled, ambient_light_disabled;
// CRITTER v2 toon character shader (Compatibility-safe: no screen reads, no extra passes).
// Vertex color RGB = part color, vertex color A = emissive mask (glow gems, blade edges, gauges).
// 2-band cel lighting + soft rim in the critter's glow color. One material per rig.

uniform float band_edge : hint_range(0.0, 1.0) = 0.38;
uniform float band_soft : hint_range(0.001, 0.5) = 0.035;
uniform vec3 shade_amb = vec3(0.46, 0.50, 0.62);    // cool teal-violet floor of the shadow band
uniform float lit_gain : hint_range(0.0, 3.0) = 0.62;
uniform vec3 rim_color : source_color = vec3(1.0, 0.6, 0.2);
uniform float rim_power : hint_range(0.5, 8.0) = 2.6;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.9;
uniform float glow_strength : hint_range(0.0, 4.0) = 1.0;   // pulsed by the rig (breath, abilities)
uniform float flash : hint_range(0.0, 1.0) = 0.0;           // white hit flash
uniform float invert_mode : hint_range(0.0, 1.0) = 0.0;     // impact frame: flat white critter
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float crack_level = 0.0;                              // 0..3 shell-plate crack tiers revealed
uniform vec3 crack_col = vec3(1.0, 0.35, 0.15);
uniform float silhouette : hint_range(0.0, 1.0) = 0.0;     // flat black (silhouette gate / lookdev)
// --- "finish" layer (v0.14): baked AO lives in the vertex colour; UV.x = specular/metal mask, UV.y = convex-edge highlight (both baked in Blender)
uniform float detail_amount : hint_range(0.0, 0.5) = 0.16;  // procedural grain / mottling strength (object space, 3 octaves)
uniform float detail_scale = 7.0;
uniform float spec_strength : hint_range(0.0, 3.0) = 0.45;
uniform float spec_power = 70.0;
uniform float edge_strength : hint_range(0.0, 2.0) = 0.3;  // convex edges catch light (wear / bevel highlight)
uniform float bump_amount : hint_range(0.0, 1.5) = 0.35;   // object-space noise bump on the normal: skin / fur / chitin irregularity
uniform float mid_edge : hint_range(0.0, 1.0) = 0.12;       // third (soft shadow-core) band
uniform vec3 tint_shadow = vec3(0.50, 0.46, 0.66);          // hue-shifted shadow colour (cool violet), multiplies the albedo
uniform float saturation : hint_range(0.5, 2.0) = 1.18;   // richer cartoon colour
uniform vec3 hi_tint = vec3(1.0, 0.86, 0.62);              // warm key-light colour added in the lit band
uniform float hi_strength : hint_range(0.0, 1.0) = 0.14;
varying vec3 v_obj;
varying vec2 v_det;

varying vec3 v_col;
varying float v_glow;

void vertex() {
	v_col = COLOR.rgb;   // palette values are authored for the final (display) space; shading is multiplicative
	v_glow = COLOR.a;
	v_obj = VERTEX;
	v_det = UV;
}

float h31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

// Crack geometry is authored with vertex alpha 0.01 / 0.02 / 0.03 = tier 1 / 2 / 3 (see Prim crack tubes); ordinary glow is >= 0.1.
float crack_tier(float a) {
	return a > 0.005 && a < 0.04 ? (a < 0.015 ? 1.0 : (a < 0.025 ? 2.0 : 3.0)) : 0.0;
}

void fragment() {
	float tier = crack_tier(v_glow);
	if (tier > crack_level + 0.5) { discard; }
	{
		// bump: finite-difference gradient of low-frequency noise nudges the normal (lit detail without textures)
		vec3 q = v_obj * detail_scale * 1.6;
		float e = 0.35;
		float n0 = vnoise(q);
		vec3 g = vec3(vnoise(q + vec3(e, 0, 0)) - n0, vnoise(q + vec3(0, e, 0)) - n0, vnoise(q + vec3(0, 0, e)) - n0) / e;
		NORMAL = normalize(NORMAL + (mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * g) * bump_amount * (1.0 - v_det.x * 0.7));
	}
	vec3 base = v_col;
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	base = clamp(mix(vec3(lum), base, saturation), 0.0, 1.0);
	// grain: three octaves of object-space noise break up flat colour (skin, cloth, chitin) without textures
	float gn = vnoise(v_obj * detail_scale) * 0.55 + vnoise(v_obj * detail_scale * 2.7 + 5.0) * 0.3 + vnoise(v_obj * detail_scale * 7.0 + 11.0) * 0.15;
	base *= 1.0 + (gn - 0.5) * 2.0 * detail_amount * (1.0 - v_det.x * 0.6);
	// convex edges catch light: a soft lift on bevels and ridges
	base += base * v_det.y * edge_strength;
	// Cel shading is computed in light(); here we only set albedo, rim and emission.
	ALBEDO = base;
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	rim = smoothstep(0.35, 0.95, rim);
	vec3 em = rim_color * rim * rim_strength;
	em += base * (tier > 0.5 ? 0.0 : v_glow) * glow_strength * 1.4;
	if (tier > 0.5) { base = vec3(0.02); em += crack_col * 1.7 * (0.7 + 0.3 * glow_strength); }
	em += base * shade_amb * 1.0;
	em = mix(em, flash_color, flash * 0.85);
	EMISSION = em;
	ALBEDO = mix(base, vec3(0.0), clamp(flash + invert_mode, 0.0, 1.0));
	ROUGHNESS = 1.0;
	if (invert_mode > 0.5) {
		EMISSION = vec3(1.0);
	}
	if (silhouette > 0.5) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(0.0);
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float lit = smoothstep(band_edge - band_soft, band_edge + band_soft, ndl);
	float core = smoothstep(mid_edge - band_soft, mid_edge + band_soft, ndl);   // a second step: the terminator gets a soft mid tone
	// lit band adds the (golden) sun; the shadow band is only the cool floor added in fragment()
	DIFFUSE_LIGHT += LIGHT_COLOR * (lit * lit_gain + core * lit_gain * 0.22) + hi_tint * lit * hi_strength * ATTENUATION;
	// stylised specular: a hard-edged highlight on glossy parts (baked mask), none on fur / cloth
	vec3 hv = normalize(LIGHT + VIEW);
	float sp = pow(max(dot(NORMAL, hv), 0.0), spec_power);
	SPECULAR_LIGHT += LIGHT_COLOR * smoothstep(0.35, 0.55, sp) * v_det.x * spec_strength * ATTENUATION;
}
