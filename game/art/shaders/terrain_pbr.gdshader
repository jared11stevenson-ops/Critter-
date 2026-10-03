shader_type spatial;
// CRITTER Red Reaches terrain, painterly-realism PBR (Agent 1, v0.7).
// Ground: tiling dirt / flagstone / scrub sets (albedo.a = height, normal maps) height-blended by the builder's
// weights; cliffs: bi-planar strata rock (projected on XY and ZY) slope-blended with the ground; macro colour
// variation + dust patches kill tiling. Vertex COLOR: r = stone paving weight, g = walkable floor weight,
// b = crest (sun-bleached edges), a = cavity/AO. Standard (Burley + GGX) lighting, dry roughness.
// Quality variants (Agent 2 perf pass, defines injected by the Quality autoload):
//   HIGH (no define)  13 texture samples: full set above.
//   QUALITY_MEDIUM     7 samples: one macro, single-scale dirt (+normal), flag + scrub albedo, bi-planar cliff albedo;
//                      no cliff / flag / scrub normal maps. Lambert diffuse.
//   QUALITY_LOW        3 samples: macro, dirt albedo, cliff albedo on the dominant plane; paving / scrub as tints;
//                      no normal maps, Lambert, no specular.
#if defined(QUALITY_LOW)
render_mode diffuse_lambert, specular_disabled;
#elif defined(QUALITY_MEDIUM)
render_mode diffuse_lambert, specular_schlick_ggx;
#else
render_mode diffuse_burley, specular_schlick_ggx;
#endif

uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D flag_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D flag_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D scrub_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D scrub_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro_tex : filter_linear_mipmap, repeat_enable;

uniform float dirt_scale = 0.16;      // 1 / tile size in m
uniform float flag_scale = 0.22;
uniform float scrub_scale = 0.12;
uniform float cliff_scale = 0.09;     // horizontal
uniform float cliff_v_scale = 0.075;  // vertical (strata thickness)
uniform float macro_scale = 0.011;
uniform float normal_strength = 1.5;

uniform vec3 strata_0 : source_color = vec3(0.62, 0.24, 0.17);
uniform vec3 strata_1 : source_color = vec3(0.80, 0.42, 0.26);
uniform vec3 strata_2 : source_color = vec3(0.93, 0.70, 0.52);
uniform vec3 strata_3 : source_color = vec3(0.46, 0.17, 0.14);
uniform vec3 strata_4 : source_color = vec3(0.72, 0.33, 0.21);
uniform float strata_band = 0.21;     // world bands per meter
uniform float strata_mix = 0.55;
uniform vec3 dust_color : source_color = vec3(0.86, 0.64, 0.48);
uniform vec3 ground_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float deep_fade_y = -14.0;
uniform vec3 deep_color : source_color = vec3(0.36, 0.22, 0.26);

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 strata_tint(float y, float warp) {
	float s = y * strata_band + warp;
	float band = floor(s);
	float f = fract(s);
	float k = mod(band, 5.0);
	vec3 c0 = strata_0;
	if (k > 0.5) c0 = strata_1;
	if (k > 1.5) c0 = strata_2;
	if (k > 2.5) c0 = strata_4;
	if (k > 3.5) c0 = strata_3;
	vec3 c1 = strata_0;
	if (k < 3.5) c1 = strata_3;
	if (k < 2.5) c1 = strata_4;
	if (k < 1.5) c1 = strata_2;
	if (k < 0.5) c1 = strata_1;
	return mix(c0, c1, smoothstep(0.82, 1.0, f));
}

vec3 unpack_n(vec4 t) {
	vec2 xy = t.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

#if defined(QUALITY_LOW) || defined(QUALITY_MEDIUM)
void fragment() {
	vec3 N = normalize(w_nrm);
	vec2 xz = w_pos.xz;
	vec4 mac = texture(macro_tex, xz * macro_scale);
	float floor_w = COLOR.g;
	float stone_w = COLOR.r;
	float ny = clamp(N.y, 0.0, 1.0);
	// ground
	vec4 da = texture(dirt_albedo, xz * dirt_scale);
#ifdef QUALITY_MEDIUM
	vec4 fa = texture(flag_albedo, xz * flag_scale);
	vec4 sa = texture(scrub_albedo, xz * scrub_scale);
	vec3 dirt_n = unpack_n(texture(dirt_normal, xz * dirt_scale));
	float sw = clamp((stone_w + (mac.g - 0.5) * 0.5 - 0.5) * 3.0 + 0.5 + (fa.a - da.a) * 2.2, 0.0, 1.0);
	sw = smoothstep(0.25, 0.75, sw) * step(0.02, stone_w);
	vec3 g_col = mix(da.rgb, fa.rgb, sw);
	float g_h = mix(da.a, fa.a, sw);
	float tw = smoothstep(0.2, 0.8, floor_w + (sa.a - 0.5) * 0.4);
	g_col = mix(sa.rgb, g_col, tw);
	g_h = mix(sa.a, g_h, tw);
	vec3 g_n = mix(vec3(0.0, 0.0, 1.0), dirt_n, (1.0 - sw) * tw);
#else
	// paving and scrub approximated by tints of the dirt sample (keeps the read of the path)
	float sw = smoothstep(0.35, 0.75, stone_w + (mac.g - 0.5) * 0.4) * step(0.02, stone_w);
	vec3 g_col = mix(da.rgb, da.rgb * vec3(1.18, 1.08, 1.0) * (0.9 + 0.2 * da.a), sw);
	float g_h = da.a;
	float tw = smoothstep(0.2, 0.8, floor_w);
	g_col = mix(g_col * vec3(0.94, 0.86, 0.74), g_col, tw);
#endif
	g_col *= mix(0.84, 1.12, mac.r) * ground_tint;
	g_col = mix(g_col, g_col * vec3(1.06, 0.92, 0.86), smoothstep(0.4, 0.8, mac.g) * 0.6);
	float dust = mac.a * smoothstep(0.62, 0.35, g_h) * (1.0 - sw * 0.7);
	g_col = mix(g_col, dust_color, dust * 0.5);
	// cliff
	float warp = (mac.r - 0.5) * 2.6 + (mac.b - 0.5) * 0.7;
	float vy = -w_pos.y * cliff_v_scale + (mac.r - 0.5) * 0.35;
#ifdef QUALITY_MEDIUM
	vec4 cz = texture(cliff_albedo, vec2(w_pos.x * cliff_scale, vy));
	vec4 cx = texture(cliff_albedo, vec2(w_pos.z * cliff_scale + 0.5, vy));
	vec2 bw = pow(abs(N.zx) + 0.001, vec2(4.0));
	bw /= (bw.x + bw.y);
	vec3 c_col = cz.rgb * bw.x + cx.rgb * bw.y;
	float c_h = cz.a * bw.x + cx.a * bw.y;
#else
	// dominant plane only (one sample)
	vec2 cuv = abs(N.z) > abs(N.x) ? vec2(w_pos.x * cliff_scale, vy) : vec2(w_pos.z * cliff_scale + 0.5, vy);
	vec4 cs = texture(cliff_albedo, cuv);
	vec3 c_col = cs.rgb;
	float c_h = cs.a;
#endif
	c_col = mix(c_col, c_col * strata_tint(w_pos.y, warp) * 1.6, strata_mix);
	c_col *= mix(0.86, 1.08, mac.b);
	float deep = smoothstep(deep_fade_y, deep_fade_y - 22.0, w_pos.y);
	c_col = mix(c_col, deep_color, deep * 0.8);
	float flat_w = smoothstep(0.66, 0.86, ny + (g_h - c_h) * 0.25);
	vec3 col = mix(c_col, g_col, flat_w);
	float rim = smoothstep(0.55, 0.66, ny) * (1.0 - smoothstep(0.66, 0.8, ny));
	col = mix(col, dust_color, rim * 0.25 + COLOR.b * 0.3);
	ALBEDO = col;
	AO = (1.0 - COLOR.a * 0.55) * mix(0.72, 1.0, smoothstep(0.2, 0.6, mix(c_h, g_h, flat_w)));
	AO_LIGHT_AFFECT = 0.35;
#ifdef QUALITY_MEDIUM
	ROUGHNESS = 0.92;
	SPECULAR = 0.32;
	vec3 Tg = normalize(vec3(1.0, 0.0, 0.0) - N * N.x);
	vec3 Bg = normalize(vec3(0.0, 0.0, -1.0) + N * N.z);
	vec3 gN = normalize(Tg * g_n.x * normal_strength + Bg * g_n.y * normal_strength + N * g_n.z);
	vec3 wn = normalize(mix(N, gN, flat_w));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
#endif
}
#else
void fragment() {
	vec3 N = normalize(w_nrm);
	vec2 xz = w_pos.xz;
	vec4 mac = texture(macro_tex, xz * macro_scale);
	vec4 mac2 = texture(macro_tex, xz * macro_scale * 4.1 + vec2(0.37, 0.71));
	float floor_w = COLOR.g;
	float stone_w = COLOR.r;

	// ---------------------------------------------------------------- ground sets
	// dirt: two scales (rotated second) blended by macro noise to break tiling
	vec2 uvd = xz * dirt_scale;
	vec4 da = texture(dirt_albedo, uvd);
	vec2 uvd2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * xz * dirt_scale * 0.43 + vec2(0.13, 0.57);
	vec4 da2 = texture(dirt_albedo, uvd2);
	float dmix = smoothstep(0.35, 0.65, mac2.r);
	vec3 dirt_c = mix(da.rgb, da2.rgb, dmix * 0.35);
	float dirt_h = mix(da.a, da2.a, dmix * 0.6);
	vec3 dirt_n = unpack_n(texture(dirt_normal, uvd));

	vec2 uvf = xz * flag_scale;
	vec4 fa = texture(flag_albedo, uvf);
	vec3 flag_n = unpack_n(texture(flag_normal, uvf));

	vec2 uvs = xz * scrub_scale;
	vec4 sa = texture(scrub_albedo, uvs);
	vec3 scrub_n = unpack_n(texture(scrub_normal, uvs));

	// height-blend: flagstones sink into the dirt at the paving borders
	float sw = clamp((stone_w + (mac2.g - 0.5) * 0.5 - 0.5) * 3.0 + 0.5 + (fa.a - dirt_h) * 2.2, 0.0, 1.0);
	sw = smoothstep(0.25, 0.75, sw) * step(0.02, stone_w);
	vec3 g_col = mix(dirt_c, fa.rgb, sw);
	vec3 g_n = mix(dirt_n, flag_n, sw);
	float g_h = mix(dirt_h, fa.a, sw);
	// mesa tops / off-path: dusty scrub
	float tw = smoothstep(0.2, 0.8, floor_w + (sa.a - 0.5) * 0.4);
	g_col = mix(sa.rgb, g_col, tw);
	g_n = mix(scrub_n, g_n, tw);
	g_h = mix(sa.a, g_h, tw);
	// macro variation: brightness + hue drift (redder / more ochre) + soft dust drifts in the low spots
	g_col *= mix(0.84, 1.12, mac.r) * ground_tint;
	g_col = mix(g_col, g_col * vec3(1.06, 0.92, 0.86), smoothstep(0.4, 0.8, mac.g) * 0.6);
	g_col = mix(g_col, g_col * vec3(0.95, 1.02, 1.04), smoothstep(0.55, 0.9, mac.b) * 0.5);
	float dust = mac.a * smoothstep(0.62, 0.35, g_h) * (1.0 - sw * 0.7);
	g_col = mix(g_col, dust_color * mix(0.9, 1.05, mac2.b), dust * 0.55);
	g_n = mix(g_n, vec3(0.0, 0.0, 1.0), dust * 0.6);
	// ground TBN in world space: u -> +X, texture up -> -Z
	vec3 Tg = normalize(vec3(1.0, 0.0, 0.0) - N * N.x);
	vec3 Bg = normalize(vec3(0.0, 0.0, -1.0) + N * N.z);
	vec3 gN = normalize(Tg * g_n.x * normal_strength + Bg * g_n.y * normal_strength + N * g_n.z);

	// ---------------------------------------------------------------- cliff (bi-planar strata rock)
	float warp = (mac.r - 0.5) * 2.6 + (mac2.g - 0.5) * 0.7;
	float vy = -w_pos.y * cliff_v_scale + (mac.r - 0.5) * 0.35;
	vec2 uvz = vec2(w_pos.x * cliff_scale, vy);
	vec2 uvx = vec2(w_pos.z * cliff_scale + 0.5, vy);
	vec4 cz = texture(cliff_albedo, uvz);
	vec4 cx = texture(cliff_albedo, uvx);
	vec3 nz = unpack_n(texture(cliff_normal, uvz));
	vec3 nx = unpack_n(texture(cliff_normal, uvx));
	vec2 bw = pow(abs(N.zx) + 0.001, vec2(4.0));
	bw /= (bw.x + bw.y);
	vec3 c_col = cz.rgb * bw.x + cx.rgb * bw.y;
	float c_h = cz.a * bw.x + cx.a * bw.y;
	c_col = mix(c_col, c_col * strata_tint(w_pos.y, warp) * 1.6, strata_mix);
	// weathering: darker streaks below protruding layers, bleached tops of ledges
	c_col *= mix(0.86, 1.08, mac2.r);
	// UDN blend of the two projections into world space
	float sz = sign(N.z);
	float sx = sign(N.x);
	vec3 cN = normalize(N + (vec3(nz.x * sz, nz.y, 0.0) * bw.x + vec3(0.0, nx.y, nx.x * sx) * bw.y) * 1.25 * normal_strength);
	// deep chasm walls fade into cool haze
	float deep = smoothstep(deep_fade_y, deep_fade_y - 22.0, w_pos.y);
	c_col = mix(c_col, deep_color, deep * 0.8);

	// ---------------------------------------------------------------- slope blend (height-aware)
	float ny = clamp(N.y, 0.0, 1.0);
	float flat_w = smoothstep(0.66, 0.86, ny + (g_h - c_h) * 0.25 + (mac2.b - 0.5) * 0.08);
	vec3 col = mix(c_col, g_col, flat_w);
	vec3 wn = normalize(mix(cN, gN, flat_w));
	// ledge rims: sun-bleached grit along crests
	float rim = smoothstep(0.55, 0.66, ny) * (1.0 - smoothstep(0.66, 0.8, ny));
	col = mix(col, dust_color, rim * 0.25 + COLOR.b * 0.3);
	// cavity / AO from the builder + texture height
	float ao = (1.0 - COLOR.a * 0.55) * mix(0.72, 1.0, smoothstep(0.2, 0.6, mix(c_h, g_h, flat_w)));
	ALBEDO = col;
	AO = ao;
	AO_LIGHT_AFFECT = 0.35;
	ROUGHNESS = mix(0.86, 0.97, mac2.a) - sw * flat_w * 0.06;
	SPECULAR = 0.32;
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
}
#endif
