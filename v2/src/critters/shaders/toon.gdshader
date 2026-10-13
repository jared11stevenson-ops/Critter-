shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled, shadows_disabled, ambient_light_disabled;
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

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;   // generated (Tripo) models are textured: UV0 samples this
uniform float use_tex : hint_range(0.0, 1.0) = 0.0;
varying vec2 v_uv;
varying vec3 v_col;
varying float v_glow;

void vertex() {
	v_col = COLOR.rgb;   // palette values are authored for the final (display) space; shading is multiplicative
	v_glow = use_tex > 0.5 ? 0.0 : COLOR.a;
	v_uv = UV;
}

// Crack geometry is authored with vertex alpha 0.01 / 0.02 / 0.03 = tier 1 / 2 / 3 (see Prim crack tubes); ordinary glow is >= 0.1.
float crack_tier(float a) {
	return a > 0.005 && a < 0.04 ? (a < 0.015 ? 1.0 : (a < 0.025 ? 2.0 : 3.0)) : 0.0;
}

void fragment() {
	float tier = crack_tier(v_glow);
	if (tier > crack_level + 0.5) { discard; }
	vec3 base = use_tex > 0.5 ? clamp(texture(albedo_tex, v_uv).rgb * 1.35, 0.0, 1.0) : v_col;
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
	// lit band adds the (golden) sun; the shadow band is only the cool floor added in fragment()
	DIFFUSE_LIGHT += LIGHT_COLOR * lit * lit_gain;
}
