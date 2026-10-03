shader_type spatial;
// CRITTER toon prop / creature shader (Agent 1): flat albedo (x vertex color), cel ramp, rim, ink outline via next_pass.
render_mode diffuse_lambert, specular_disabled;

#include "res://game/art/shaders/toon_light.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float grain = 0.18;
uniform float grain_scale = 0.35;
uniform float strata = 0.0;               // horizontal red strata (rocks)
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.85, 0.65, 1.0);
uniform float rim_strength = 0.25;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash = 0.0;
uniform vec4 highlight_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float highlight = 0.0;
uniform float use_vertex_color = 1.0;
uniform float reveal = 2.0;
uniform float occlude = 1.0;              // camera occlusion fade on/off               // rope unroll: fragments with UV2.x > reveal are hidden

varying float v_rev;
uniform vec3 critter_focus_pos;
uniform vec3 critter_cam_pos;
#include "res://game/art/shaders/occlusion_fade.gdshaderinc"

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_rev = UV2.x;
}

void fragment() {
	if (reveal < 1.5 && v_rev > reveal) {
		discard;
	}
	if (occlude > 0.5 && occ_cut(w_pos, FRAGCOORD.xy)) {
		discard;
	}
	vec3 base = albedo.rgb * mix(vec3(1.0), COLOR.rgb, use_vertex_color);
	// tri-planar-ish grain so flat colours read as painted
	vec3 an = abs(w_nrm);
	float g = texture(noise_tex, w_pos.xz * grain_scale).b * an.y + texture(noise_tex, w_pos.xy * grain_scale).b * an.z
		+ texture(noise_tex, w_pos.zy * grain_scale).b * an.x;
	base *= 1.0 - grain * 0.5 + grain * g;
	if (strata > 0.0) {
		float s = fract(w_pos.y * 0.9 + texture(noise_tex, w_pos.xz * 0.05).r * 1.5);
		base *= 1.0 - strata * 0.22 * step(0.5, s);
		base = mix(base, vec3(0.16, 0.07, 0.07), strata * (1.0 - smoothstep(0.0, 0.06, s)) * 0.6);
	}
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(base, flash_color.rgb, flash);
	EMISSION = emission_color.rgb * emission_energy + rim_color.rgb * fres * rim_strength * 0.5
		+ highlight_color.rgb * highlight * (0.35 + fres * 1.5) + flash_color.rgb * flash * 0.6;
	ROUGHNESS = 1.0;
}
