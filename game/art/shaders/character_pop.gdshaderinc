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

void pop_fragment(vec2 uv, vec3 nrm, vec3 view, out vec3 albedo, out float rough, out float metal, out vec3 emis, out vec3 nmap, out float alpha) {
	vec4 a = texture(albedo_tex, uv) * albedo_tint;
	alpha = a.a;
	albedo = pop_grade(a.rgb, sat_lift, val_lift);
	rough = rough_base;
	metal = metal_base;
	if (use_orm > 0.5) {
		vec3 o = texture(orm_tex, uv).rgb;
		rough = clamp(o.g * (rough_base / 0.7), 0.05, 1.0);
		metal = o.b;
	}
	nmap = vec3(0.5, 0.5, 1.0);
	if (use_normal > 0.5) {
		nmap = texture(normal_tex, uv).rgb;
	}
	float ndv = clamp(dot(nrm, view), 0.0, 1.0);
	float f = pow(1.0 - ndv, rim_power);
	emis = albedo * shadow_floor * (1.0 + vcol.b * 2.2) + rim_color.rgb * f * rim_strength * vcol.g;
	if (use_emis > 0.5) {
		vec3 e = texture(emis_tex, uv).rgb;
		float m = max(e.r, max(e.g, e.b));
		emis += mix(e, accent_color.rgb * m, accent_mix) * accent_strength;
	}
	float f3 = pow(1.0 - ndv, 3.0);
	emis += highlight_color.rgb * f3 * highlight * 1.6 + vec3(1.0, 0.85, 0.8) * flash;
}
