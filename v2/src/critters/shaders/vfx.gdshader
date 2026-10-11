shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;
// CRITTER v2 ability / event VFX: one procedural ink-style shader, 26 pattern kinds (hard-edged shapes with a dark ink border, no textures).
// Quads carry UV (0,0) bottom-left .. (1,1) top-right. p = centered coords (-1..1, aspect-corrected); y01 = 0..1 height for vertical kinds.
// Kind list: 0 burst star, 1 smear arc, 2 ground cracks, 3 ring wave, 4 gust swirl, 5 bubbling cultures, 6 frost web, 7 time ripple,
// 8 thorn row, 9 pollen / spores, 10 psychic threads, 11 sigil, 12 impact lines, 13 camo leaf blotches, 14 silk cocoon, 15 gravity vortex,
// 16 lift chevrons, 17 fangs, 18 rage flame tongues, 19 mold growth, 20 hypnosis spiral, 21 jagged beam, 22 bridge arch, 23 frozen shards,
// 24 petal rosette, 25 ghost eye.
uniform int kind = 0;
uniform float t = 0.0;                  // life 0..1
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.2);
uniform vec3 tint2 : source_color = vec3(1.0, 0.95, 0.8);
uniform vec3 ink : source_color = vec3(0.06, 0.04, 0.08);
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float aspect = 1.0;
uniform float billboard = 0.0;
uniform float size_x = 1.0;
uniform float size_y = 1.0;


float hash(float n) { return fract(sin(n * 127.1 + seed * 17.3) * 43758.5453); }
vec2 hash2(float n) { return vec2(hash(n), hash(n + 41.7)); }

vec4 over(vec4 a, vec4 b) { return vec4(mix(a.rgb, b.rgb, b.a), max(a.a, b.a)); }
vec4 inkfill(float d, vec3 c) {            // d < 0 inside; thin ink border outside
	float e = 0.034;
	float a = d < e ? 1.0 : 0.0;
	return vec4(d < 0.0 ? c : ink, a);
}
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
float polyd(vec2 p, float n, float rot) {  // regular-polygon radial distance (1 at the polygon edge for r=1)
	float a = atan(p.y, p.x) + rot;
	float s = TAU / n;
	return length(p) * cos(mod(a, s) - s * 0.5);
}

void vertex() {
	if (billboard > 0.5) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(size_x, 0, 0, 0), vec4(0, size_y, 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
	}
}

void fragment() {
	vec2 uv = UV;
	vec2 p = (uv * 2.0 - 1.0) * vec2(aspect, 1.0);
	float r = length(p);
	float ang = atan(p.y, p.x);
	float y01 = uv.y;
	float g = min(t * 4.0, 1.0);
	vec4 o = vec4(0.0);

	if (kind == 0) {            // burst star
		float rad = 0.32 + 0.68 * pow(abs(cos(ang * 4.0 + seed)), 2.2);
		float R = rad * g * (1.0 - t * 0.3);
		o = inkfill(r - R, tint);
		o = over(o, inkfill(r - R * 0.45, tint2));
	} else if (kind == 1) {     // smear arc
		float ring = max(r - 0.98, 0.5 - r + 0.18 * cos(ang * 1.0));
		float win = abs(ang - (t * 3.0 - 1.5)) - 0.85;
		o = inkfill(max(ring, win), tint);
		o = over(o, inkfill(max(max(r - 0.95, 0.78 - r), win + 0.1), tint2));
	} else if (kind == 2) {     // ground cracks
		float dmin = 9.0;
		for (int i = 0; i < 12; i++) {
			float fi = float(i);
			float a0 = (fi + 0.5) / 12.0 * TAU - PI + (hash(fi) - 0.5) * 0.35;
			float L = (0.4 + 0.6 * hash(fi * 3.1)) * min(t * 3.0, 1.0);
			vec2 dir = vec2(cos(a0), sin(a0));
			vec2 nrm = vec2(-dir.y, dir.x);
			vec2 q = p + nrm * sin(dot(p, dir) * 22.0 + fi) * 0.025;
			float d1 = seg(q, dir * 0.05, dir * L) - 0.022 * (1.0 - dot(p, dir) / max(L, 0.01) * 0.7);
			vec2 b0 = dir * (L * 0.55);
			float a1 = a0 + (hash(fi + 9.0) > 0.5 ? 0.6 : -0.6);
			float d2 = seg(q, b0, b0 + vec2(cos(a1), sin(a1)) * L * 0.4) - 0.014;
			dmin = min(dmin, min(d1, d2));
		}
		o = inkfill(dmin, ink * 0.5 + tint * 0.0);
		o.rgb = dmin < 0.0 ? mix(tint, tint2, 0.6) : ink;
		o.rgb = dmin < -0.008 ? tint2 : o.rgb;
		float dust = step(0.5, hash(floor(p.x * 9.0) + floor(p.y * 9.0) * 13.0)) * step(r, 0.3 + t * 0.5) * step(t, 0.5);
		o = over(o, vec4(tint * 0.8, dust * 0.5));
	} else if (kind == 3) {     // ring wave with dashed inner ring
		float R = 0.15 + 0.85 * (1.0 - pow(1.0 - min(t * 1.2, 1.0), 2.0));
		float th = 0.075 * (1.0 - t * 0.8);
		o = inkfill(abs(r - R) - th, tint);
		float dash = step(0.5, fract(ang * 6.0 / PI + t * 2.0));
		float d2 = max(abs(r - R * 0.72) - th * 0.45, dash > 0.5 ? 1.0 : -1.0);
		o = over(o, inkfill(d2, tint2));
	} else if (kind == 4) {     // gust swirl
		float a = ang - r * 4.2 - t * 7.0;
		float band = abs(fract(a * 3.0 / TAU) - 0.5) * TAU / 3.0 * r;
		float d = max(band - 0.1 * (1.0 - r * 0.65), r - 0.98);
		o = inkfill(d, tint);
		float a2 = ang - r * 4.2 - t * 7.0 + 0.5;
		float band2 = abs(fract(a2 * 3.0 / TAU) - 0.5) * TAU / 3.0 * r;
		o = over(o, inkfill(max(band2 - 0.035, r - 0.95), tint2));
	} else if (kind == 5) {     // bubbling cultures
		float dmin = 9.0;
		vec3 col = tint;
		float hl = 9.0;
		for (int i = 0; i < 12; i++) {
			float fi = float(i);
			vec2 c = (hash2(fi) - 0.5) * 1.5;
			c.y += fract(t * (0.3 + 0.4 * hash(fi + 3.0)) + hash(fi + 5.0)) * 0.5 - 0.25;
			float rr = (0.1 + 0.16 * hash(fi + 7.0)) * (0.5 + 0.5 * sin(PI * clamp(t * 1.4 + hash(fi) * 0.3, 0.0, 1.0)));
			float d = length(p - c) - rr;
			if (d < dmin) {
				dmin = d;
				col = hash(fi + 2.0) > 0.5 ? tint : tint * 0.75 + tint2 * 0.25;
				hl = length(p - c - vec2(-rr * 0.3, rr * 0.35)) - rr * 0.22;
			}
		}
		o = inkfill(dmin, col);
		o = over(o, vec4(tint2, hl < 0.0 && dmin < 0.0 ? 1.0 : 0.0));
	} else if (kind == 6) {     // frost web
		float reveal = r - t * 1.6;
		float spokes = abs(sin(ang * 4.0)) * r - 0.014;
		float d = spokes;
		float pd = polyd(p, 8.0, 0.0);
		for (int i = 0; i < 4; i++) {
			d = min(d, abs(pd - (0.2 + float(i) * 0.24)) - 0.012);
		}
		d = max(d, max(reveal, r - 0.98));
		o = inkfill(d, tint2);
		float sh = abs(sin(ang * 4.0 + 0.4)) * r - 0.07 * (1.0 - r);
		o = over(o, inkfill(max(max(sh, r - 0.98), reveal + 0.2), tint));
	} else if (kind == 7) {     // time ripple
		float d = 9.0;
		for (int i = 0; i < 4; i++) {
			float R = 0.25 + float(i) * 0.22 + 0.05 * sin(t * 6.0 + float(i) * 1.7);
			float dash = step(0.35, fract(ang * 3.0 / TAU * float(i + 3) + t * (i % 2 == 0 ? 1.0 : -1.0)));
			d = min(d, max(abs(r - R) - 0.022, dash > 0.5 ? -1.0 : 1.0));
		}
		o = inkfill(d, tint);
		float tick = step(0.9, abs(sin(ang * 6.0))) * step(abs(r - 0.97), 0.05);
		o = over(o, vec4(tint2, tick));
		for (int i = 0; i < 6; i++) {          // frozen diamond shards orbiting
			float a = float(i) / 6.0 * TAU + t * 2.0;
			vec2 c = vec2(cos(a), sin(a)) * 0.62;
			vec2 q = p - c;
			float dd = abs(q.x) + abs(q.y) * 0.6 - 0.08;
			o = over(o, inkfill(dd, tint2));
		}
	} else if (kind == 8) {     // thorn row (vertical)
		float y = y01 * 2.0;
		float dmin = 9.0;
		float tipc = 0.0;
		for (int i = 0; i < 7; i++) {
			float fi = float(i);
			float xi = (fi - 3.0) * 0.3 + (hash(fi) - 0.5) * 0.1;
			float h = (0.55 + 0.45 * hash(fi + 2.0)) * min(max(t * 5.0 - fi * 0.18, 0.0), 1.0) * 1.8;
			float w = 0.15 * (1.0 - y / max(h, 0.01));
			float d = max(abs(p.x - xi) - w, y - h);
			if (d < dmin) { dmin = d; tipc = y / max(h, 0.01); }
		}
		o = inkfill(dmin, tipc > 0.7 ? tint2 : tint);
		float dirt = step(0.6, hash(floor(p.x * 12.0) + floor(y * 12.0) * 7.0)) * step(y, 0.35) * step(t, 0.7);
		o = over(o, vec4(tint * 0.6, dirt * 0.6));
	} else if (kind == 9) {     // pollen / spores
		for (int i = 0; i < 28; i++) {
			float fi = float(i);
			vec2 c = (hash2(fi) - 0.5) * 1.8 * vec2(1.0, 0.9);
			c += vec2(sin(t * 5.0 + fi) * 0.08, t * (0.15 + 0.35 * hash(fi + 3.0)));
			c.y = mod(c.y + 1.0, 2.0) - 1.0;
			float rr = 0.03 + 0.045 * hash(fi + 8.0);
			float d = length(p - c) - rr;
			vec3 col = hash(fi + 1.0) > 0.5 ? tint : tint2;
			o = over(o, vec4(col, d < 0.0 ? 1.0 : 0.0));
			o = over(o, vec4(ink, (d >= 0.0 && d < 0.016) ? 0.9 : 0.0));
		}
	} else if (kind == 10) {    // psychic threads
		float d = 9.0;
		for (int k = 0; k < 5; k++) {
			float fk = float(k);
			float yk = (fk - 2.0) * 0.26 * (1.0 - t * 0.3) + sin(p.x * 6.0 + t * 12.0 + fk * 1.3) * 0.07 * (1.0 - abs(p.x) * 0.5);
			d = min(d, abs(p.y - yk) - 0.016);
		}
		d = max(d, p.x - (t * 2.6 - 1.0));
		o = inkfill(d, tint);
		o = over(o, vec4(tint2, (d < -0.004 && fract(p.x * 5.0 - t * 6.0) < 0.2) ? 1.0 : 0.0));
	} else if (kind == 11) {    // sigil
		float rot = t * 1.5 + seed;
		float d = abs(r - 0.92) - 0.022;
		d = min(d, abs(r - 0.78) - 0.012);
		d = min(d, abs(polyd(p, 3.0, rot) - 0.5) - 0.018);
		d = min(d, abs(polyd(p, 3.0, rot + PI) - 0.5) - 0.018);
		float tick = step(0.8, abs(sin(ang * 6.0 + rot))) * step(abs(r - 0.85), 0.06);
		d = min(d, tick > 0.5 ? -0.01 : 9.0);
		d = max(d, r - min(g * 1.1, 1.0));
		o = inkfill(d, tint);
		o = over(o, vec4(tint2, r < 0.09 * g ? 1.0 : 0.0));
	} else if (kind == 12) {    // impact lines
		float s = mod(ang + PI, TAU / 14.0) - TAU / 28.0;
		float k = floor((ang + PI) / (TAU / 14.0));
		float perp = r * sin(s);
		float r0 = 0.25 + t * 0.35 + 0.1 * hash(k);
		float r1 = 0.55 + t * 0.4 + 0.3 * hash(k + 4.0);
		float d = max(abs(perp) - 0.028 * (1.0 - (r - r0) / max(r1 - r0, 0.01)), max(r0 - r, r - r1));
		o = inkfill(d, tint2);
		o = over(o, vec4(tint, 0.0));
	} else if (kind == 13) {    // camo blotches
		float n = sin(p.x * 8.0 + seed) * sin(p.y * 8.0 + t * 2.0) + 0.6 * sin(p.x * 17.0 - p.y * 11.0);
		float inside = step(r, 0.95);
		vec3 col = n > 0.5 ? tint : (n > -0.2 ? tint2 : tint * 0.55);
		float rim = step(0.88, r) * step(r, 0.95);
		o = vec4(col, inside * 0.85);
		o = over(o, vec4(ink, rim));
	} else if (kind == 14) {    // cocoon
		float e = length(p / vec2(0.58, 0.97)) - 1.0;
		float grow = -0.97 + 2.0 * min(t * 3.0, 1.0);
		float stripe = step(0.55, fract((p.x * 2.0 + p.y * 3.4) * 4.0)) * step(e, -0.04);
		float stripe2 = step(0.6, fract((-p.x * 2.0 + p.y * 3.4) * 3.0)) * step(e, -0.04);
		o = inkfill(max(e, p.y - grow), tint2);
		o = over(o, vec4(tint, (stripe > 0.5 || stripe2 > 0.5) && p.y < grow ? 0.9 : 0.0));
	} else if (kind == 15) {    // gravity vortex (inward arrows)
		float a = ang + r * 5.0 + t * 8.0;
		float band = abs(fract(a * 4.0 / TAU) - 0.5) * TAU / 4.0 * r;
		float dash = step(0.4, fract(r * 7.0 + t * 5.0));
		float d = max(band - 0.07 * (0.4 + r * 0.6), r - 0.98);
		d = max(d, dash > 0.5 ? -1.0 : 1.0);
		o = inkfill(d, tint);
		o = over(o, inkfill(r - 0.12 * (1.0 + sin(t * 20.0) * 0.1), tint2));
	} else if (kind == 16) {    // lift chevrons
		float d = 9.0;
		for (int k = 0; k < 4; k++) {
			float yk = fract(float(k) / 4.0 + t * 0.9) * 2.0 - 1.0;
			float c = abs(p.y - (yk - abs(p.x) * 0.55)) - 0.06;
			d = min(d, max(c, abs(p.x) - 0.8));
		}
		o = inkfill(d, tint);
		o = over(o, vec4(tint2, d < -0.03 ? 1.0 : 0.0));
	} else if (kind == 17) {    // fangs (top and bottom bite toward the middle)
		float k = min(t * 4.0, 1.0);
		float len = 0.9 * k + 0.001;
		float dtop = max(abs(p.x) - 0.3 * clamp((p.y - (1.0 - len)) / len, 0.0, 1.0), max(p.y - 1.0, (1.0 - len) - p.y));
		float dbot = max(abs(p.x) - 0.3 * clamp((-p.y - (1.0 - len)) / len, 0.0, 1.0), max(-p.y - 1.0, (1.0 - len) + p.y));
		float dd = min(dtop, dbot);
		o = inkfill(dd, tint2);
		o = over(o, vec4(tint, (dd < -0.08 && abs(p.y) > 0.45) ? 0.7 : 0.0));
	} else if (kind == 18) {    // rage flame tongues
		float y = y01 * 1.3;
		float dmin = 9.0;
		float hh = 0.0;
		for (int i = 0; i < 6; i++) {
			float fi = float(i);
			float xi = (fi - 2.5) * 0.32;
			float h = (0.55 + 0.4 * hash(fi)) * (0.75 + 0.25 * sin(t * 18.0 + fi * 2.0)) * min(t * 6.0, 1.0);
			float wob = sin(y * 9.0 + t * 14.0 + fi) * 0.05;
			float d = max(abs(p.x - xi - wob) - 0.15 * (1.0 - y / max(h, 0.01)), y - h);
			if (d < dmin) { dmin = d; hh = y / max(h, 0.01); }
		}
		o = inkfill(dmin, mix(tint, tint2, clamp(hh, 0.0, 1.0)));
	} else if (kind == 19) {    // mold growth
		float R = min(t * 2.0, 1.0) * 0.92;
		float dmin = 9.0;
		float tn = 0.0;
		for (int i = 0; i < 14; i++) {
			float fi = float(i);
			vec2 c = (hash2(fi) - 0.5) * 1.6;
			float rr = (0.08 + 0.16 * hash(fi + 6.0)) * min(max(t * 3.0 - hash(fi + 1.0), 0.0), 1.0);
			float d = length(p - c) - rr;
			if (d < dmin) { dmin = d; tn = hash(fi + 3.0); }
		}
		o = inkfill(max(dmin, r - R - 0.1), tn > 0.5 ? tint : tint * 0.7 + tint2 * 0.3);
		o = over(o, vec4(tint2, (dmin < -0.03 && hash(floor(p.x * 20.0) + floor(p.y * 20.0) * 3.0) > 0.85) ? 1.0 : 0.0));
	} else if (kind == 20) {    // hypnosis spiral
		float a = ang + r * 9.0 - t * 9.0;
		float band = fract(a / TAU);
		float d = max(abs(band - 0.5) - 0.25, r - 0.98);
		o = inkfill(d, band > 0.5 ? tint : tint2);
		o = over(o, inkfill(r - 0.08, ink));
	} else if (kind == 21) {    // jagged beam (along +x)
		float x = p.x / aspect;
		float edge = 0.3 + 0.07 * sin(x * 28.0 + t * 30.0);
		float taper = 1.0 - smoothstep(0.6, 1.0, x);
		float d = abs(p.y) - edge * taper;
		d = max(d, x - (min(t * 3.0, 1.0) * 2.2 - 1.0));
		d = max(d, -1.0 - x);
		o = inkfill(d, tint);
		o = over(o, inkfill(max(abs(p.y) - 0.12 * taper, max(-1.0 - x, x - (min(t * 3.0, 1.0) * 2.2 - 1.0))), tint2));
	} else if (kind == 22) {    // bridge arch (vertical)
		float x = p.x;
		float y = y01 * 1.4;
		float outer = length(vec2(x, y)) - 1.0;
		float inner = length(vec2(x, y)) - 0.8;
		float arch = max(outer, -inner);
		float trussd = 9.0;
		for (int i = 0; i < 7; i++) {
			float a0 = float(i) / 7.0 * PI;
			float a1 = float(i + 1) / 7.0 * PI;
			vec2 A = vec2(cos(a0), sin(a0)) * 0.82;
			vec2 B = vec2(cos(a1), sin(a1)) * 1.0;
			trussd = min(trussd, seg(vec2(x, y), A, B) - 0.018);
		}
		float deck = max(abs(y - 0.02) - 0.035, abs(x) - 1.0);
		float d = min(min(arch, trussd), deck);
		d = max(d, y < -0.02 ? 1.0 : -1.0);
		d = max(d, abs(x) - min(t * 4.0, 1.0) * 1.05);
		o = inkfill(d, tint);
		o = over(o, vec4(tint2, (d < -0.02 && arch < 0.0 && y > 0.5) ? 0.8 : 0.0));
	} else if (kind == 23) {    // frozen shards
		float s = mod(ang + PI, TAU / 10.0) - TAU / 20.0;
		float k = floor((ang + PI) / (TAU / 10.0));
		float Lk = (0.5 + 0.5 * hash(k)) * min(t * 4.0, 1.0);
		float d = max(abs(r * sin(s)) - 0.1 * (1.0 - r / max(Lk, 0.01)), r - Lk);
		d = max(d, 0.12 - r);
		o = inkfill(d, hash(k + 1.0) > 0.5 ? tint : tint2);
	} else if (kind == 24) {    // petal rosette
		float rad = 0.28 + 0.72 * pow(abs(cos(ang * 4.0 + t * 1.5)), 0.8);
		float R = rad * min(t * 4.0, 1.0);
		o = inkfill(r - R, cos(ang * 4.0 + t * 1.5) > 0.0 ? tint : tint2);
		o = over(o, inkfill(r - 0.14 * min(t * 4.0, 1.0), vec3(1.0, 0.85, 0.3)));
	} else {                    // 25 ghost eye
		float e = length(p / vec2(1.0, 0.5)) - 0.9;
		o = inkfill(e, tint2);
		o = over(o, inkfill(length(p) - 0.32, tint));
		o = over(o, inkfill(length(p) - 0.12, ink));
	}

	float fade = (1.0 - smoothstep(0.7, 1.0, t)) * smoothstep(0.0, 0.05, t);
	ALBEDO = o.rgb;
	ALPHA = o.a * fade * alpha;
}
