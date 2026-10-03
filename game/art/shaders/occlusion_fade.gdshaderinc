// CRITTER camera-occlusion fade (Agent 1). Screen-door dither of fragments between the camera and the focus
// (player). Requires, BEFORE this include, the two uniforms below. They are plain uniforms in the file so the
// shader compiles standalone; ToonKit.occluding_shader() rewrites them to `global uniform` at runtime once the
// globals `critter_focus_pos` / `critter_cam_pos` exist (gameplay updates them every frame).
//   uniform vec3 critter_focus_pos;
//   uniform vec3 critter_cam_pos;

const float OCC_RADIUS = 2.6;

float occ_bayer4(vec2 p) {
	ivec2 q = ivec2(mod(p, 4.0));
	int i = q.x + q.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}

// 0 = fully visible, 1 = fully cut away
float occ_amount(vec3 wp) {
	vec3 f = critter_focus_pos + vec3(0.0, 1.0, 0.0);
	vec3 d = f - critter_cam_pos;
	float L2 = dot(d, d);
	if (L2 < 0.25 || dot(critter_focus_pos, critter_focus_pos) < 0.0001) {
		return 0.0;
	}
	float t = dot(wp - critter_cam_pos, d) / L2;
	if (t <= 0.0 || t >= 0.86) {
		return 0.0;
	}
	float dist = length(wp - (critter_cam_pos + d * t));
	float k = 1.0 - smoothstep(OCC_RADIUS * 0.55, OCC_RADIUS, dist);
	return k * smoothstep(0.86, 0.72, t) * 0.85;
}

// usage in fragment(): if (occ_cut(w_pos, FRAGCOORD.xy)) { discard; }  (4.3 forbids discard in helpers)
bool occ_cut(vec3 wp, vec2 fragcoord) {
	return occ_amount(wp) > occ_bayer4(fragcoord);
}
