shader_type sky;
// CRITTER sky: painterly gradient, ringed planet with arcing ring band, soft stylised clouds.
// Palette from the World Assets sheet sky strips. Compatibility-safe (no radiance-heavy features).

uniform vec3 zenith_color : source_color = vec3(0.27, 0.42, 0.74);
uniform vec3 mid_color : source_color = vec3(0.55, 0.66, 0.88);
uniform vec3 horizon_color : source_color = vec3(0.98, 0.80, 0.66);
uniform vec3 ground_color : source_color = vec3(0.55, 0.33, 0.25);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.93, 0.90);
uniform vec3 cloud_shade : source_color = vec3(0.86, 0.62, 0.70);
uniform vec3 planet_color : source_color = vec3(0.80, 0.66, 0.86);
uniform vec3 planet_shade : source_color = vec3(0.45, 0.36, 0.62);
uniform vec3 ring_color : source_color = vec3(0.95, 0.86, 0.92);
uniform vec3 planet_dir = vec3(0.35, 0.42, -0.84);
uniform float planet_size = 0.16;
uniform float ring_tilt = 0.42;
uniform float cloud_cover = 0.48;
uniform float cloud_speed = 0.004;
uniform vec3 sun_tint : source_color = vec3(1.0, 0.9, 0.7);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col;
	if (h > 0.0) {
		col = mix(horizon_color, mid_color, smoothstep(0.0, 0.25, h));
		col = mix(col, zenith_color, smoothstep(0.25, 0.9, h));
	} else {
		col = mix(horizon_color * 0.9, ground_color, smoothstep(0.0, 0.25, -h));
	}
	// sun glow
	if (LIGHT0_ENABLED) {
		float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
		col += sun_tint * (pow(s, 8.0) * 0.25 + pow(s, 200.0) * 1.2);
	}
	// ringed planet
	vec3 pd = normalize(planet_dir);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), pd));
	vec3 up = cross(pd, right);
	float facing = dot(d, pd);
	if (facing > 0.0) {
		vec2 p = vec2(dot(d, right), dot(d, up)) / max(facing, 0.001);
		float r = length(p);
		// ring: an ellipse band, tilted
		float ct = cos(ring_tilt);
		float st = sin(ring_tilt);
		vec2 q = vec2(p.x * ct - p.y * st, p.x * st + p.y * ct);
		float er = length(vec2(q.x, q.y * 4.2));
		float band = smoothstep(planet_size * 1.45, planet_size * 1.55, er) * (1.0 - smoothstep(planet_size * 2.3, planet_size * 2.45, er));
		band *= 0.55 + 0.45 * sin(er * 120.0);
		bool behind = q.y > 0.0 && r < planet_size;
		float disc = 1.0 - smoothstep(planet_size - 0.004, planet_size, r);
		vec3 pc = mix(planet_color, planet_shade, smoothstep(-0.6, 0.9, dot(normalize(p + vec2(0.0001)), vec2(0.7, -0.6)) * (r / planet_size)));
		pc += vec3(0.08) * sin(p.y * 70.0 + p.x * 8.0);
		col = mix(col, pc, disc * 0.92);
		if (!behind) {
			col = mix(col, ring_color, band * 0.75);
		}
		// thin ink limb
		col = mix(col, planet_shade * 0.6, (smoothstep(planet_size - 0.006, planet_size - 0.002, r) - smoothstep(planet_size - 0.002, planet_size, r)) * 0.6);
	}
	// grand arcing ring band across the sky (World Assets panorama)
	float arc = abs(dot(d, normalize(vec3(0.25, 0.55, 0.8))) - 0.18);
	float arcb = (1.0 - smoothstep(0.0, 0.012, arc)) * smoothstep(0.02, 0.3, h);
	col = mix(col, ring_color, arcb * 0.45);
	// clouds: flattened fbm bands near the horizon
	if (h > -0.02) {
		vec2 cuv = d.xz / (h + 0.18);
		cuv = cuv * 1.3 + vec2(TIME * cloud_speed, 0.0);
		float n = fbm(cuv * 1.4);
		float n2 = fbm(cuv * 3.1 + 7.0);
		float c = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.12, n * 0.8 + n2 * 0.3);
		float shade = smoothstep(0.3, 0.8, n2);
		vec3 cc = mix(cloud_shade, cloud_color, shade);
		float fade = smoothstep(-0.02, 0.06, h) * (1.0 - smoothstep(0.35, 0.8, h));
		col = mix(col, cc, c * fade);
	}
	COLOR = col;
}
