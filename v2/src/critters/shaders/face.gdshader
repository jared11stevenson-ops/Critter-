shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, depth_draw_never, blend_mix;
// Procedural cartoon face on a thin patch hugging the head (1 draw call, no textures).
// p.x spans -1..1 across the patch (viewer's left..right when looking at the face), p.y spans +-aspect.
// Per-critter design uniforms are set once; the six expressions only drive the dynamic block.

uniform vec3 ink : source_color = vec3(0.05, 0.03, 0.06);
uniform vec3 sclera : source_color = vec3(1.0, 0.98, 0.9);
uniform vec3 mouth_in : source_color = vec3(0.40, 0.06, 0.12);
uniform vec3 accent : source_color = vec3(1.0, 0.5, 0.2);
uniform vec3 eye_col : source_color = vec3(0.05, 0.03, 0.06);
uniform float aspect = 0.64;
// design
uniform float eye_sep = 0.36;
uniform float eye_y = 0.10;
uniform vec2 eye_size = vec2(0.17, 0.17);   // L, R radius
uniform float eye_white = 0.0;              // 0 = ink dot, 1 = white eye + pupil
uniform float eye_sy = 1.0;                 // vertical stretch
uniform float lid_bias = 0.0;               // 0..0.6 sleepy
uniform vec2 brow_bias = vec2(0.0, 0.0);    // per-eye lift (raised eyebrow)
uniform float brow_len = 0.2;
uniform float brow_thick = 0.034;
uniform float brow_off = 0.1;
uniform float no_brow = 0.0;
uniform float mouth_y = -0.30;
uniform float mouth_w = 0.2;
uniform float mouth_base = 0.15;
uniform float ring = 0.0;
uniform float glint = 1.0;
uniform float brow_color_accent = 0.0;
uniform float glasses = 0.0;       // 1 = round spectacle frames with spiral lenses (Weft)
uniform float goggle = 0.0;        // 1 = thick goggle rims (Zell)
uniform float mouth_skew = 0.0;    // smirk: one corner higher
// expression state
uniform float open = 1.0;
uniform float brow_tilt = 0.0;
uniform float brow_lift = 0.0;
uniform float mouth_curve = 0.0;
uniform float mouth_open = 0.0;
uniform float mouth_wide = 1.0;
uniform vec2 look = vec2(0.0);
uniform float xeyes = 0.0;
uniform float sweat = 0.0;
uniform float wobble = 0.0;
uniform float time = 0.0;

float fill(float d, float aa) { return smoothstep(aa, -aa, d); }

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, (1.0 - UV.y) * 2.0 - 1.0) ;
	p.y *= aspect;
	float aa = max(fwidth(p.x) * 1.1, 0.004);
	vec3 col = vec3(0.0);
	float a = 0.0;
	float o_eff = clamp(open - lid_bias, 0.04, 1.4);

	for (int i = 0; i < 2; i++) {
		float s = i == 0 ? -1.0 : 1.0;
		float er = eye_size[i] * (1.0 + max(open - 1.0, 0.0) * 0.35);
		vec2 c = vec2(s * eye_sep, eye_y);
		vec2 q = p - c;
		q.y /= eye_sy;
		float lid_y = er * (2.0 * min(o_eff, 1.0) - 1.0);   // cut line (relative to eye centre)
		float disc = length(q) - er;
		float cut = q.y - lid_y;                             // >0 = covered by the lid
		float body = fill(max(disc, cut), aa);
		vec3 ec = vec3(0.0);
		float ea = 0.0;
		if (eye_white > 0.5) {
			float ring_d = abs(disc) - 0.012;
			vec2 pu = q - look * er * 0.4;
			float pupil = fill(max(length(pu) - er * 0.56, cut), aa);
			float shine = fill(length(pu - vec2(er * 0.2, er * 0.26)) - er * 0.17, aa) * glint;
			float rr = fill(max(ring_d, cut), aa);
			ec = mix(sclera, ink, rr * 0.9);
			ec = mix(ec, eye_col, pupil);
			ec = mix(ec, vec3(1.0), shine * pupil);
			ea = max(body, rr);
		} else {
			vec2 pu = q - look * er * 0.25;
			float shine = fill(length(pu - vec2(er * 0.28, er * 0.34)) - er * 0.27, aa) * glint;
			ec = mix(eye_col, vec3(1.0), shine * 0.95);
			ea = body;
		}
		// lid stroke when mostly closed (blink / dying) so a closed eye reads as a line
		float closed = smoothstep(0.55, 0.15, o_eff);
		float lid_line = fill(seg(q, vec2(-er * 1.05, lid_y), vec2(er * 1.05, lid_y)) - 0.016, aa) * closed;
		ec = mix(ec, ink, lid_line);
		ea = max(ea, lid_line);
		// X eyes replace the eye entirely
		float xe = max(fill(seg(q, vec2(-er * 0.8, -er * 0.8), vec2(er * 0.8, er * 0.8)) - 0.022, aa),
				fill(seg(q, vec2(-er * 0.8, er * 0.8), vec2(er * 0.8, -er * 0.8)) - 0.022, aa));
		ec = mix(ec, ink, xeyes);
		ea = mix(ea, xe, xeyes);
		if (glasses > 0.5) {
			float lr = length(q);
			float ang = atan(q.y, q.x);
			float spiral = smoothstep(0.30, 0.1, abs(fract(lr / (er * 0.34) - ang / 6.2832) - 0.5));
			ec = mix(ec, accent, spiral * 0.55 * step(lr, er));
		}
		col = mix(col, ec, ea);
		a = max(a, ea);
		if (glasses > 0.5 || goggle > 0.5) {
			float fr = fill(abs(length(q) - er * 1.32) - (goggle > 0.5 ? 0.03 : 0.02), aa);
			vec3 fcol = goggle > 0.5 ? mix(ink, accent, 0.6) : vec3(0.78, 0.82, 0.9);
			col = mix(col, fcol, fr);
			a = max(a, fr);
		}
		// brows: inner end is toward x = 0
		if (no_brow < 0.5) {
			float lift = brow_lift + brow_bias[i];
			float inner = -s;
			vec2 bc = c + vec2(0.0, er * eye_sy + brow_off + lift * 0.1);
			vec2 b0 = bc + vec2(inner * brow_len, brow_tilt * 0.11);
			vec2 b1 = bc + vec2(-inner * brow_len, -brow_tilt * 0.05);
			float bd = seg(p, b0, b1) - brow_thick;
			float br = fill(bd, aa);
			vec3 bcol = mix(ink, accent, brow_color_accent);
			col = mix(col, bcol, br);
			a = max(a, br);
			if (ring > 0.5 && i == 1) {
				vec2 rc = bc + vec2(-inner * brow_len * 0.55, 0.0);
				float rg = fill(abs(length(p - rc) - 0.065) - 0.017, aa);
				col = mix(col, accent, rg);
				a = max(a, rg);
			}
		}
		// sweat drop
		float sd = fill(length((p - (c + vec2(s * 0.3, er * 1.6))) * vec2(1.0, 0.7)) - 0.06, aa) * sweat * (i == 1 ? 1.0 : 0.0);
		col = mix(col, vec3(0.6, 0.88, 1.0), sd);
		a = max(a, sd);
	}

	if (glasses > 0.5) {   // bridge between the lenses
		float br2 = fill(seg(p, vec2(-eye_sep + eye_size[0] * 1.32, eye_y + 0.02), vec2(eye_sep - eye_size[1] * 1.32, eye_y + 0.02)) - 0.016, aa);
		col = mix(col, vec3(0.78, 0.82, 0.9), br2);
		a = max(a, br2);
	}
	// mouth
	float mw = mouth_w * mouth_wide;
	float t = p.x / max(mw, 0.001);
	float inside = step(abs(t), 1.0);
	float curve = mouth_base + mouth_curve;
	float wob = sin(p.x * 26.0 + time * 10.0) * 0.014 * wobble;
	float ym = mouth_y + curve * 0.13 * t * t + wob + mouth_skew * t * 0.09;
	float op = clamp(mouth_open, 0.0, 1.0);
	float top = ym + op * max(curve, 0.0) * 0.13 * (1.0 - t * t);
	float bot = ym - op * 0.14 * (1.0 - t * t);
	float thick = 0.017;
	float line_t = fill(abs(p.y - top) - thick, aa) * inside;
	float line_b = fill(abs(p.y - bot) - thick, aa) * inside * step(0.03, op);
	float interior = fill(max(p.y - top, bot - p.y), aa) * inside * step(0.03, op);
	col = mix(col, mouth_in, interior);
	a = max(a, interior);
	col = mix(col, ink, max(line_t, line_b));
	a = max(a, max(line_t, line_b));
	ALBEDO = col;
	ALPHA = a;
}
