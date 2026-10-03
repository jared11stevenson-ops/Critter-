shader_type spatial;
// CRITTER Red Reaches terrain: painterly toon ground + red strata cliffs (Agent 1).
// Vertex COLOR: r = stone paving weight, g = walkable floor weight, b = ink crest, a = cavity/AO.
render_mode diffuse_lambert, specular_disabled;

#include "res://game/art/shaders/toon_light.gdshaderinc"

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D flag_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 dirt_a : source_color = vec3(0.60, 0.26, 0.16);
uniform vec3 dirt_b : source_color = vec3(0.71, 0.39, 0.23);
uniform vec3 dirt_dark : source_color = vec3(0.46, 0.19, 0.14);
uniform vec3 stone_a : source_color = vec3(0.64, 0.41, 0.31);
uniform vec3 stone_b : source_color = vec3(0.50, 0.29, 0.23);
uniform vec3 top_a : source_color = vec3(0.62, 0.34, 0.22);
uniform vec3 top_b : source_color = vec3(0.52, 0.42, 0.26);
uniform vec3 strata_0 : source_color = vec3(0.50, 0.16, 0.12);
uniform vec3 strata_1 : source_color = vec3(0.70, 0.30, 0.18);
uniform vec3 strata_2 : source_color = vec3(0.84, 0.56, 0.38);
uniform vec3 strata_3 : source_color = vec3(0.34, 0.11, 0.11);
uniform vec3 strata_4 : source_color = vec3(0.60, 0.23, 0.16);
uniform vec3 ink : source_color = vec3(0.16, 0.07, 0.07);
uniform float strata_scale = 0.42;
uniform float flag_scale = 0.3;
uniform float deep_fade_y = -14.0;
uniform vec3 deep_color : source_color = vec3(0.30, 0.16, 0.20);

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 strata_color(float y, float warp) {
	float s = y * strata_scale + warp;
	float band = floor(s);
	float f = fract(s);
	float k = mod(band, 5.0);
	vec3 c = strata_0;
	if (k > 0.5) c = strata_1;
	if (k > 1.5) c = strata_2;
	if (k > 2.5) c = strata_4;
	if (k > 3.5) c = strata_3;
	// thin ink line at some band boundaries + soft shading inside the band (painted look)
	float line = (1.0 - smoothstep(0.0, 0.06, f)) * step(0.5, mod(band, 2.0));
	c *= 0.86 + 0.14 * smoothstep(0.0, 0.7, f);
	return mix(c, ink, line * 0.75);
}

void fragment() {
	vec2 xz = w_pos.xz;
	vec4 n1 = texture(noise_tex, xz * 0.018);
	vec4 n2 = texture(noise_tex, xz * 0.07 + vec2(0.31, 0.77));
	vec4 n3 = texture(noise_tex, xz * 0.21);
	float ny = clamp(w_nrm.y, 0.0, 1.0);
	float flat_w = smoothstep(0.62, 0.86, ny + (n2.g - 0.5) * 0.12);
	float floor_w = COLOR.g;
	float stone_w = COLOR.r;

	// --- ground: dirt with painted patches, pebbles, cracks
	vec3 dirt = mix(dirt_a, dirt_b, smoothstep(0.35, 0.7, n1.r + (n2.g - 0.5) * 0.4));
	dirt = mix(dirt, dirt_dark, smoothstep(0.58, 0.8, n2.r) * 0.65);
	dirt *= 0.93 + 0.12 * n3.b;
	float crack = texture(noise_tex, xz * 0.06).a;
	dirt = mix(dirt, ink, crack * 0.55);
	// --- stone paving (flagstones with ink mortar)
	vec4 fl = texture(flag_tex, xz * flag_scale);
	vec3 stone = mix(stone_b, stone_a, fl.r) * (0.82 + 0.18 * fl.g);
	stone = mix(stone, dirt_dark, smoothstep(0.55, 0.8, n2.b) * 0.35);
	stone = mix(stone, ink, fl.a * 0.85);
	float sw = smoothstep(0.35, 0.65, stone_w + (n2.r - 0.5) * 0.5);
	vec3 ground = mix(dirt, stone, sw);
	// --- mesa tops: dusty scrub
	vec3 top = mix(top_a, top_b, smoothstep(0.45, 0.75, n1.g + n3.r * 0.2));
	top = mix(top, dirt_b, smoothstep(0.6, 0.9, n2.b) * 0.5);
	top = mix(top, ink, crack * 0.4);
	vec3 flat_col = mix(top, ground, smoothstep(0.2, 0.8, floor_w));
	// --- cliffs: red strata with warp + vertical weathering streaks
	float warp = (n1.r - 0.5) * 2.2 + (n2.g - 0.5) * 0.6;
	vec3 cliff = strata_color(w_pos.y, warp);
	float hcoord = (w_pos.x + w_pos.z) * 0.35;
	float streak = texture(noise_tex, vec2(hcoord * 0.15, w_pos.y * 0.012)).b;
	cliff *= 0.8 + 0.3 * streak;
	cliff = mix(cliff, ink, smoothstep(0.78, 0.92, texture(noise_tex, vec2(hcoord * 0.4, w_pos.y * 0.05)).g) * 0.5);
	// deep chasm walls fade to cool violet haze
	cliff = mix(cliff, deep_color, smoothstep(deep_fade_y, deep_fade_y - 22.0, w_pos.y) * 0.85);

	vec3 col = mix(cliff, flat_col, flat_w);
	// rim between flat and cliff gets an ink stroke; crest from the builder
	float rim = smoothstep(0.5, 0.62, ny) * (1.0 - smoothstep(0.62, 0.74, ny));
	col = mix(col, ink, clamp(rim * 0.55 + COLOR.b, 0.0, 0.9));
	col *= 1.0 - COLOR.a * 0.45;
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
