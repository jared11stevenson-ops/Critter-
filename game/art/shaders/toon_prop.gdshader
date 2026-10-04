shader_type spatial;
// CRITTER prop / creature shader (Agent 1, v0.7 painterly realism): vertex-colour albedo with tri-planar painted
// detail (prop_detail) + tri-planar rock normal, Burley/GGX lighting, soft rim so forms read against the sky.
// Quality variants (Agent 2 perf pass; defines injected by the Quality autoload):
//   HIGH: tri-planar detail + grain + detail normal (9-10 samples). MEDIUM: tri-planar detail albedo only (3).
//   LOW: detail albedo on the dominant plane (1 sample), no normal map, Lambert, no specular.
#if defined(QUALITY_LOW)
render_mode diffuse_lambert, specular_disabled;
#elif defined(QUALITY_MEDIUM)
render_mode diffuse_lambert, specular_schlick_ggx;
#else
render_mode diffuse_burley, specular_schlick_ggx;
#endif

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float grain = 0.18;
uniform float grain_scale = 0.35;
uniform sampler2D detail_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float detail_scale = 0.55;
uniform float detail_strength = 0.55;
uniform float normal_depth = 0.8;
uniform float roughness = 0.82;
uniform float metallic = 0.0;
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
uniform float occlude = 1.0;              // camera occlusion fade on/off
// reveal: rope unroll, fragments with UV2.x > reveal are hidden
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

varying float v_rev;
uniform vec3 critter_focus_pos;
uniform vec3 critter_cam_pos;
#include "res://game/art/shaders/occlusion_fade.gdshaderinc"

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	VERTEX = gait_offset(VERTEX, UV2);
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
#if defined(QUALITY_LOW) || defined(QUALITY_MEDIUM)
	vec3 an = abs(w_nrm);
#ifdef QUALITY_LOW
	vec2 duv = an.y > max(an.x, an.z) ? w_pos.xz : (an.z > an.x ? w_pos.xy : w_pos.zy);
	vec4 dt = texture(detail_tex, duv * detail_scale);
#else
	vec3 bw = pow(an, vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec4 dt = texture(detail_tex, w_pos.xz * detail_scale) * bw.y + texture(detail_tex, w_pos.xy * detail_scale) * bw.z
		+ texture(detail_tex, w_pos.zy * detail_scale) * bw.x;
#endif
	base *= mix(1.0, 0.55 + dt.r * 0.9, detail_strength);
	base *= mix(1.0, 0.7 + dt.a * 0.5, detail_strength * 0.6);
	base = mix(base, vec3(0.80, 0.60, 0.46), smoothstep(0.6, 0.95, w_nrm.y) * 0.18 * detail_strength);
	ROUGHNESS = clamp(roughness + (dt.g - 0.5) * 0.2, 0.05, 1.0);
#else
	vec3 an = abs(w_nrm);
	vec3 bw = pow(an, vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec2 uy = w_pos.xz * detail_scale;
	vec2 uz = w_pos.xy * detail_scale;
	vec2 ux = w_pos.zy * detail_scale;
	vec4 dt = texture(detail_tex, uy) * bw.y + texture(detail_tex, uz) * bw.z + texture(detail_tex, ux) * bw.x;
	float g = texture(noise_tex, w_pos.xz * grain_scale * 0.3).b * bw.y + texture(noise_tex, w_pos.xy * grain_scale * 0.3).b * bw.z
		+ texture(noise_tex, w_pos.zy * grain_scale * 0.3).b * bw.x;
	base *= (1.0 - grain * 0.4 + grain * 0.8 * g) * mix(1.0, 0.55 + dt.r * 0.9, detail_strength);
	// grime in crevices (detail alpha = cavity) + dust on up-facing surfaces
	base *= mix(1.0, 0.7 + dt.a * 0.5, detail_strength * 0.6);
	base = mix(base, vec3(0.80, 0.60, 0.46), smoothstep(0.6, 0.95, w_nrm.y) * 0.18 * detail_strength);
	vec3 ny_ = texture(detail_normal, uy).xyz * 2.0 - 1.0;
	vec3 nz_ = texture(detail_normal, uz).xyz * 2.0 - 1.0;
	vec3 nx_ = texture(detail_normal, ux).xyz * 2.0 - 1.0;
	vec3 wn = normalize(w_nrm + (vec3(ny_.x, 0.0, -ny_.y) * bw.y + vec3(nz_.x, nz_.y, 0.0) * bw.z
		+ vec3(0.0, nx_.y, nx_.x) * bw.x) * normal_depth);
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(wn, 0.0)).xyz, 1.0));
	ROUGHNESS = clamp(roughness + (dt.g - 0.5) * 0.2, 0.05, 1.0);
#endif
	METALLIC = metallic;
	if (strata > 0.0) {
#ifdef QUALITY_LOW
		float s = fract(w_pos.y * 0.9 + sin(w_pos.x * 0.31 + w_pos.z * 0.23) * 0.4);
#else
		float s = fract(w_pos.y * 0.9 + texture(noise_tex, w_pos.xz * 0.05).r * 1.5);
#endif
		base *= 1.0 - strata * 0.22 * step(0.5, s);
		base = mix(base, vec3(0.16, 0.07, 0.07), strata * (1.0 - smoothstep(0.0, 0.06, s)) * 0.6);
	}
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(base, flash_color.rgb, flash);
	EMISSION = emission_color.rgb * emission_energy + rim_color.rgb * fres * rim_strength * 0.25
		+ highlight_color.rgb * highlight * (0.35 + fres * 1.5) + flash_color.rgb * flash * 0.6;
}
