// Character pop layer (Agent 4). Shared by character_pop.gdshader (one-sided) and character_pop_2s.gdshader (wings).
// Cheap on mobile: one pass, no screen reads. Pushes silhouette separation from ANY biome via
//   (1) a per-character value/saturation lift of the baked albedo (hue-preserving),
//   (2) a fresnel rim tinted per character (cool against warm worlds), widened on the side facing away from the sun,
//   (3) emissive accents (the baked emissive map tinted by accent_color) that stay bright in shade.
// An inverted-hull outline (character_pop_outline.gdshader) is chained as next_pass by CharacterPop.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_tex : hint_roughness_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D emis_tex : source_color, hint_default_black, filter_linear_mipmap, repeat_disable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float use_normal = 0.0;
uniform float use_orm = 0.0;
uniform float use_emis = 0.0;
uniform float normal_strength = 1.0;
uniform float rough_base = 0.7;
uniform float metal_base = 0.0;
uniform float sat_lift = 1.15;          // 1 = sheet saturation
uniform float val_lift = 1.08;
uniform float contrast = 1.0;           // S-curve around mid grey: deeper darks, whiter bone          // multiply value
uniform float shadow_floor = 0.10;      // emission floor so shade never goes muddy: albedo * floor
uniform vec4 rim_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float rim_power = 2.6;
uniform float rim_strength = 0.55;
uniform vec4 accent_color : source_color = vec4(0.3, 1.0, 0.9, 1.0);
uniform float accent_strength = 1.4;
uniform float accent_mix = 0.4;       // how much of the baked emissive hue is replaced by accent_color
uniform float alpha_cut = 0.0;          // >0: leaf-cut membrane
// per-vertex control (glb COLOR_0, authored by tools/modeling): r = outline width scale, g = rim scale, b = shade-floor boost (faces).
varying vec4 vcol;
// painted-lookdev extras (character_pop_toon.gdshader; zone_grade 0 keeps the legacy look for other characters)
uniform float zone_grade = 0.0;
uniform float ao_strength = 0.55;       // orm.r baked occlusion
uniform float edge_dark = 0.32;         // painted edge darkening (down-facing silhouettes)
uniform vec4 shade_red : source_color = vec4(0.40, 0.11, 0.20, 1.0);    // shadow tint per material zone
uniform vec4 shade_black : source_color = vec4(0.62, 0.44, 0.40, 1.0);
uniform vec4 shade_bone : source_color = vec4(0.66, 0.50, 0.52, 1.0);
uniform vec4 shade_cloth : source_color = vec4(0.50, 0.46, 0.40, 1.0);
uniform float gloss_red = 0.26;         // roughness of the lacquered carapace discs
uniform float rough_black = 0.58;
uniform float rough_bone = 0.78;
uniform float rough_cloth = 0.9;

// gameplay feedback (driven by CharacterModel)
uniform vec4 highlight_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float highlight = 0.0;
uniform float flash = 0.0;
uniform float time_pulse = 0.0;

vec3 pop_grade(vec3 c, float s, float v) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, s);
	c = (c - 0.45) * contrast + 0.45;
	return clamp(c * v, 0.0, 1.0);
}

// zone masks from the sheet albedo: red lacquer / near-black chitin / bone / cloth+leather
vec4 pop_zones(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float rd = smoothstep(0.30, 0.62, (c.r - c.g) / (c.r + 0.03)) * smoothstep(0.10, 0.26, c.r);
	float bk = (1.0 - smoothstep(0.11, 0.26, l)) * (1.0 - rd);
	float bn = smoothstep(0.42, 0.66, l) * (1.0 - rd);
	float cl = clamp(1.0 - rd - bk - bn, 0.0, 1.0);
	return vec4(rd, bk, bn, cl);
}

void pop_fragment(vec2 uv, vec3 nrm, vec3 view, out vec3 albedo, out float rough, out float metal, out vec3 emis, out vec3 nmap, out float alpha) {
	vec4 a = texture(albedo_tex, uv) * albedo_tint;
	alpha = a.a;
	albedo = pop_grade(a.rgb, sat_lift, val_lift);
	rough = rough_base;
	metal = metal_base;
	float occl = 1.0;
	if (use_orm > 0.5) {
		vec3 o = texture(orm_tex, uv).rgb;
		rough = clamp(o.g * (rough_base / 0.7), 0.05, 1.0);
		metal = o.b;
		occl = o.r;
	}
	vec4 zn = vec4(0.0);
	if (zone_grade > 0.5) {
		zn = pop_zones(a.rgb);
		// chitin: the sheet's near-black is warm brown-black, not navy; keep it dark but legible
		float l0 = dot(albedo, vec3(0.299, 0.587, 0.114));
		vec3 warm_black = vec3(l0 * 1.30 + 0.040, l0 * 0.74 + 0.016, l0 * 0.44 + 0.010);   // pre-compensates the cool sky ambient
		albedo = mix(albedo, warm_black, zn.y);
		// lacquer: deeper oxblood, a touch more chroma
		albedo = mix(albedo, albedo * vec3(0.98, 0.62, 0.70), zn.x);
		// bone: warm cream
		albedo = mix(albedo, albedo * vec3(1.04, 0.97, 0.88), zn.z);
		rough = zn.x * gloss_red + zn.y * rough_black + zn.z * rough_bone + zn.w * rough_cloth;
		metal = 0.0;
		albedo *= mix(1.0, clamp(occl * 1.15, 0.0, 1.0), ao_strength);
	}
	nmap = vec3(0.5, 0.5, 1.0);
	if (use_normal > 0.5) {
		nmap = texture(normal_tex, uv).rgb;
	}
	float ndv = clamp(dot(nrm, view), 0.0, 1.0);
	float f = pow(1.0 - ndv, rim_power);
	float rim_up = 1.0;
	if (zone_grade > 0.5) {
		// teal rim only on the upper / outer edges (what a back light would catch); the underside gets painted edge darkening
		rim_up = smoothstep(-0.35, 0.35, nrm.y);
		float dk = pow(1.0 - ndv, 2.0) * edge_dark * (1.0 - rim_up);
		albedo *= 1.0 - dk;
	}
	emis = albedo * shadow_floor * (1.0 + vcol.b * 2.2) + rim_color.rgb * f * rim_strength * vcol.g * rim_up;
	if (use_emis > 0.5) {
		vec3 e = texture(emis_tex, uv).rgb;
		float m = max(e.r, max(e.g, e.b));
		emis += mix(e, accent_color.rgb * m, accent_mix) * accent_strength;
	}
	float f3 = pow(1.0 - ndv, 3.0);
	emis += highlight_color.rgb * f3 * highlight * 1.6 + vec3(1.0, 0.85, 0.8) * flash;
}
