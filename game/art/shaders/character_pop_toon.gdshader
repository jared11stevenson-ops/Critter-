shader_type spatial;
// Aruun lookdev shader: painted shading ramp + zone-aware stylised specular on top of the shared pop layer.
// Mobile-safe (Compatibility): one pass, no screen reads, light() runs per light that touches him (sun + rim only in the world).
render_mode cull_disabled, diffuse_lambert, specular_disabled, ambient_light_disabled;
#include "res://game/art/shaders/character_pop.gdshaderinc"
uniform float ramp_soft = 0.10;         // band edge softness (painterly: soft, not cel-hard)
uniform float ramp_split = 0.42;        // where the lit band starts (n.l)
uniform float spec_size = 0.10;         // highlight size on lacquer (1 - n.h threshold)
uniform float spec_power = 0.9;
uniform vec4 char_ambient : source_color = vec4(0.24, 0.185, 0.185, 1.0);   // warm authored fill instead of the world's cool sky ambient
uniform float wrap = 0.18;              // wrapped diffuse so the terminator is not a black cut

void vertex() {
	vcol = COLOR;
}
void fragment() {
	vec3 al; float ro; float me; vec3 em; vec3 nm; float a;
	pop_fragment(UV, NORMAL, VIEW, al, ro, me, em, nm, a);
	ALBEDO = al;
	ROUGHNESS = ro;
	EMISSION = em + al * char_ambient.rgb;
	if (use_normal > 0.5) {
		NORMAL_MAP = nm;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	// two soft bands: core shadow -> half tone -> lit
	float b1 = smoothstep(0.0, ramp_soft + 0.1, w);
	float b2 = smoothstep(ramp_split - ramp_soft, ramp_split + ramp_soft, w);
	float lit = 0.34 * b1 + 0.66 * b2;
	vec4 z = pop_zones(ALBEDO);
	vec3 tint = z.x * shade_red.rgb + z.y * shade_black.rgb + z.z * shade_bone.rgb + z.w * shade_cloth.rgb;
	vec3 ramp = mix(tint, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * ramp * (1.0 / 3.14159265) * (0.25 + 0.75 * step(0.001, lit));
	// lacquer spec: tight, hard-edged highlight (painted gloss) masked by the zone roughness
	float gloss = 1.0 - smoothstep(0.30, 0.50, ROUGHNESS);
	vec3 h = normalize(LIGHT + VIEW);
	float nh = dot(NORMAL, h);
	float sp = smoothstep(1.0 - spec_size, 1.0 - spec_size + 0.035, nh) * step(0.0, ndl);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * sp * gloss * spec_power * (1.0 / 3.14159265) * 3.0;
	// soft sheen on chitin / cloth (broad, faint)
	float sheen = pow(max(nh, 0.0), 14.0) * (1.0 - gloss) * 0.07 * step(0.0, ndl);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * sheen;
}
