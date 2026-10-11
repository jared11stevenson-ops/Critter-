shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;
// FX quads: mode 0 = smear arc (UV.x along swing length 0 old..1 new, UV.y across),
// mode 1 = hit spark (flat star-burst, UV centered).
uniform vec3 tint : source_color = vec3(1.0);
uniform int mode = 0;
uniform float t = 0.0;      // 0..1 life
uniform float alpha = 1.0;
uniform vec3 core : source_color = vec3(1.0, 0.98, 0.9);
uniform float spikes = 8.0;

void vertex() {
	if (mode == 1) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, length(MODEL_MATRIX[2].xyz), 0), vec4(0, 0, 0, 1));
	}
}

void fragment() {
	vec2 uv = UV;
	if (mode == 0) {
		float along = uv.x;            // 0 old .. 1 newest
		float y = uv.y;                // 1 = blade tip edge, 0 = inner edge
		float body = pow(y, 1.4) * pow(along, 1.3);
		float core_s = smoothstep(0.82, 0.97, y) * pow(along, 1.0);
		ALBEDO = mix(tint, core, core_s);
		ALPHA = clamp(body * 1.0 + core_s * 0.7, 0.0, 1.0) * alpha;
	} else {
		vec2 p = (uv - 0.5) * 2.0;
		float r = length(p);
		float ang = atan(p.y, p.x);
		float star = 0.35 + 0.65 * pow(abs(cos(ang * spikes * 0.5)), 3.0);
		float grow = mix(0.5, 1.0, clamp(t * 4.0, 0.0, 1.0));
		float edge = star * grow * (1.0 - t * 0.5);
		float body = smoothstep(edge, edge - 0.08, r);
		float inner = smoothstep(edge * 0.45, edge * 0.35, r);
		ALBEDO = mix(tint, core, inner);
		ALPHA = body * alpha;
	}
}
