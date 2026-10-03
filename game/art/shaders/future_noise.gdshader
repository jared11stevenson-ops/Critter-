shader_type canvas_item;
// Cigarra's "future noise" overload overlay (Agent 1). Full-screen ColorRect; noise 0..1.
// Static grain, violet probability-line flicker, horizontal tearing and edge darkening. Transparent at 0.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float noise : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.62, 0.42, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float n = noise;
	float t = floor(TIME * 24.0);
	// tearing: random bands shift sideways
	float band = floor(uv.y * 40.0);
	float tear = step(1.0 - 0.25 * n, hash(vec2(band, t))) * (hash(vec2(t, band)) - 0.5) * 0.06 * n;
	vec2 suv = uv + vec2(tear, 0.0);
	vec3 col = textureLod(screen_tex, suv, 0.0).rgb;
	// chromatic jitter
	float off = 0.004 * n * (hash(vec2(t, 3.0)) - 0.5) * 2.0;
	col.r = textureLod(screen_tex, suv + vec2(off, 0.0), 0.0).r;
	col.b = textureLod(screen_tex, suv - vec2(off, 0.0), 0.0).b;
	// grain
	float g = hash(uv * vec2(1280.0, 720.0) + t);
	col = mix(col, vec3(g), 0.18 * n);
	// probability lines: thin violet scanlines branching
	float lines = smoothstep(0.97, 1.0, sin(uv.y * 90.0 + sin(uv.x * 7.0 + TIME * 4.0) * 5.0)) * step(0.4, hash(vec2(floor(uv.y * 90.0 / 6.2832), t)));
	col += tint.rgb * lines * 0.35 * n;
	// edge darkening / violet vignette
	float r = length(uv - 0.5);
	col = mix(col, tint.rgb * 0.18, smoothstep(0.35, 0.8, r) * 0.7 * n);
	COLOR = vec4(col, 1.0);
}
