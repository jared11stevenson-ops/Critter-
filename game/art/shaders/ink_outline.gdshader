shader_type spatial;
// Inverted-hull ink outline pass (Agent 1). Use as next_pass of toon materials.
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;

uniform vec4 ink_color : source_color = vec4(0.12, 0.06, 0.06, 1.0);
uniform float reveal = 2.0;
varying float v_rev;
varying vec3 w_pos;
uniform float occlude = 1.0;
uniform vec3 critter_focus_pos;
uniform vec3 critter_cam_pos;
#include "res://game/art/shaders/occlusion_fade.gdshaderinc"
uniform float width = 0.035;          // meters at 10 m from camera (scales with distance a little)

void vertex() {
	v_rev = UV2.x;
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	w_pos = wp.xyz;
	float d = length((INV_VIEW_MATRIX[3].xyz) - wp.xyz);
	float w = width * clamp(d / 10.0, 0.6, 2.5);
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	VERTEX += NORMAL * w / max(scale, vec3(0.001));
}

void fragment() {
	if (reveal < 1.5 && v_rev > reveal) {
		discard;
	}
	if (occlude > 0.5) {
		occ_discard(w_pos, FRAGCOORD.xy);
	}
	ALBEDO = ink_color.rgb;
}
