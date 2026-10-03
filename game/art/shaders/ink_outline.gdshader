shader_type spatial;
// Inverted-hull ink outline pass (Agent 1). Use as next_pass of toon materials.
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;

uniform vec4 ink_color : source_color = vec4(0.12, 0.06, 0.06, 1.0);
uniform float reveal = 2.0;
varying float v_rev;
varying vec3 w_pos;
uniform float occlude = 1.0;
uniform float gait_phase = 0.0;          // creatures: walk cycle phase (cycles)
uniform float gait_amp = 0.0;            // creatures: leg swing (m); legs carry UV2 = (leg phase 0..1, weight 0..1)
vec3 gait_offset(vec3 v, vec2 uv2) {
	if (gait_amp <= 0.0001 || uv2.y <= 0.0) {
		return v;
	}
	float a = (gait_phase + uv2.x) * 6.28318;
	v.z += sin(a) * gait_amp * uv2.y;
	v.y += max(0.0, cos(a)) * gait_amp * 0.55 * uv2.y;
	return v;
}
uniform vec3 critter_focus_pos;
uniform vec3 critter_cam_pos;
#include "res://game/art/shaders/occlusion_fade.gdshaderinc"
uniform float width = 0.035;          // meters at 10 m from camera (scales with distance a little)

void vertex() {
	v_rev = UV2.x;
	VERTEX = gait_offset(VERTEX, UV2);
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
	if (occlude > 0.5 && occ_cut(w_pos, FRAGCOORD.xy)) {
		discard;
	}
	ALBEDO = ink_color.rgb;
}
