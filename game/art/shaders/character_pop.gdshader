shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://game/art/shaders/character_pop.gdshaderinc"
void vertex() {
	vcol = COLOR;
}
void fragment() {
	vec3 al; float ro; float me; vec3 em; vec3 nm; float a;
	pop_fragment(UV, NORMAL, VIEW, al, ro, me, em, nm, a);
	ALBEDO = al;
	ROUGHNESS = ro;
	METALLIC = me;
	EMISSION = em;
	if (use_normal > 0.5) {
		NORMAL_MAP = nm;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
