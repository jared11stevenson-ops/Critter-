shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
#include "res://game/art/shaders/character_pop.gdshaderinc"
void vertex() {
	vcol = COLOR;
}
void fragment() {
	vec3 al; float ro; float me; vec3 em; vec3 nm; float a;
	pop_fragment(UV, NORMAL, VIEW, al, ro, me, em, nm, a);
	if (alpha_cut > 0.0 && a < alpha_cut) {
		discard;
	}
	ALBEDO = al;
	ROUGHNESS = ro;
	METALLIC = me;
	EMISSION = em;
}
