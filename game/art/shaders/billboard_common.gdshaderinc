// CRITTER — shared code for the HD-2D character billboard (Agent 1).
// Quad mesh: size 1x1, centered at (0, 0.5) so the feet sit at the node origin.
// The script sets quad_size (meters, including the outline margin) and margin_uv.

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 quad_size = vec2(1.0, 2.0);       // world meters (w, h) of the textured area
uniform vec2 margin_uv = vec2(0.02, 0.01);     // extra uv border so the outline can grow outside the art
uniform float flip_h = 0.0;                    // 1 = mirror (side view facing left)
uniform vec2 anim_scale = vec2(1.0, 1.0);      // squash / stretch around the feet
uniform vec2 anim_offset = vec2(0.0, 0.0);     // screen-plane offset in meters (x = right, y = up)
uniform float anim_shear = 0.0;                // lean: x += shear * y (feet stay planted)
uniform float lean_forward = 0.0;              // tilts the top toward the camera (meters at the top)
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float tint_strength = 1.0;
uniform vec4 outline_color : source_color = vec4(0.09, 0.06, 0.07, 1.0);
uniform float outline_px = 2.0;                // in texels
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float rim_strength = 0.35;
uniform vec2 rim_dir = vec2(-0.6, 0.8);        // direction (uv space, y up) the rim light comes from
uniform vec4 highlight_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float highlight = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash = 0.0;
uniform float desaturate = 0.0;
uniform float darken = 0.0;
uniform float mip_bias = -0.3;

varying vec2 v_uv;

vec3 billboard_vertex(vec3 vtx, vec2 uv, out vec2 uv_out) {
	vec3 v = vtx;                               // quad local: x in [-0.5,0.5], y in [0,1]
	vec2 size = quad_size;
	v.x *= size.x;
	v.y *= size.y;
	v.y -= size.y * margin_uv.y;                // keep the art's feet (not the margin) on the origin
	v.x *= anim_scale.x;
	v.y *= anim_scale.y;
	v.x += anim_shear * v.y + anim_offset.x;
	v.y += anim_offset.y;
	float hy = clamp(v.y / max(size.y, 0.001), 0.0, 1.5);
	v.z += lean_forward * hy;
	vec2 u = uv;
	if (flip_h > 0.5) {
		u.x = 1.0 - u.x;
	}
	// expand uv into the margin
	u = (u - 0.5) * (1.0 + 2.0 * margin_uv) + 0.5;
	uv_out = u;
	return v;
}

// Y-axis billboard: X follows the camera, Y stays world-up (scaled by the node's basis).
mat4 billboard_matrix(mat4 model, mat4 inv_view) {
	vec3 cam_x = normalize(inv_view[0].xyz);
	vec3 up = model[1].xyz;
	float sx = length(model[0].xyz);
	vec3 z = normalize(cross(cam_x, normalize(up)));
	return mat4(vec4(cam_x * sx, 0.0), vec4(up, 0.0), vec4(z * length(model[2].xyz), 0.0), model[3]);
}

float sample_a(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return textureLod(tex, uv, 0.0).a;
}

// returns rgb, writes alpha (0..1 coverage incl. outline)
vec4 billboard_color() {
	vec2 uv = v_uv;
	vec2 ts = vec2(textureSize(tex, 0));
	vec2 px = outline_px / ts;
	bool inside = uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0;
	vec4 c = inside ? texture(tex, uv, mip_bias) : vec4(0.0);
	// neighbourhood alpha for outline / rim / highlight
	float an = 0.0;
	an = max(an, sample_a(uv + vec2(px.x, 0.0)));
	an = max(an, sample_a(uv - vec2(px.x, 0.0)));
	an = max(an, sample_a(uv + vec2(0.0, px.y)));
	an = max(an, sample_a(uv - vec2(0.0, px.y)));
	an = max(an, sample_a(uv + px * 0.7071));
	an = max(an, sample_a(uv - px * 0.7071));
	an = max(an, sample_a(uv + vec2(px.x, -px.y) * 0.7071));
	an = max(an, sample_a(uv + vec2(-px.x, px.y) * 0.7071));
	// rim: lit where the art is opaque but the texel toward the light is empty
	vec2 rd = normalize(rim_dir) * vec2(1.0, -1.0) * (px * 2.2);
	float toward = sample_a(uv + rd);
	float rim = clamp(c.a - toward, 0.0, 1.0);
	vec3 col = c.rgb;
	// lighting tint (scene light computed by the script; painted shading is kept)
	col *= mix(vec3(1.0), light_tint, tint_strength);
	col += rim * rim_color.rgb * rim_strength;
	// downed: desaturate / darken
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(g) * vec3(0.92, 0.9, 1.0), desaturate);
	col *= (1.0 - darken);
	// highlight (scan / select): coloured inner edge glow
	float edge = clamp(an - c.a, 0.0, 1.0);
	float inner = clamp(c.a - sample_a(uv + vec2(px.x * 2.0, 0.0)) * sample_a(uv - vec2(px.x * 2.0, 0.0)) * sample_a(uv + vec2(0.0, px.y * 2.0)) * sample_a(uv - vec2(0.0, px.y * 2.0)), 0.0, 1.0);
	col = mix(col, highlight_color.rgb * 1.6, highlight * inner * 0.85);
	col = mix(col, flash_color.rgb * 1.4, flash);
	// composite outline behind the art
	vec3 ocol = mix(outline_color.rgb, highlight_color.rgb * 1.8, highlight);
	float a = max(c.a, an * outline_color.a);
	vec3 rgb = mix(ocol, col, c.a > 0.5 ? 1.0 : c.a * 1.6);
	return vec4(rgb, a);
}
