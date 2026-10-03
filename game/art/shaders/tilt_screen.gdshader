shader_type canvas_item;
// "The Tilt" — scale sickness on arrival through the Gate (Agent 1). Put on a full-screen ColorRect.
// strength 0..1: barrel warp, swaying horizon, chromatic split, depth wobble, warm vignette.
// The rect's COLOR.a (modulate / color alpha) fades the result to dark (1 = black).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.14, 0.05, 0.08, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float s = strength;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	// slow sway / roll of the whole view
	float roll = sin(TIME * 0.9) * 0.035 * s;
	c = mat2(vec2(cos(roll), sin(roll)), vec2(-sin(roll), cos(roll))) * c;
	// breathing barrel warp (scale sickness: everything too big, then too small)
	float breathe = 0.5 + 0.5 * sin(TIME * 1.3);
	c *= 1.0 + (r2 * (0.35 + 0.25 * breathe) - 0.06 * breathe) * s;
	// depth wobble: horizontal waves stronger toward the bottom (near ground)
	c.x += sin(c.y * 18.0 + TIME * 3.1) * 0.006 * s * (0.5 + uv.y);
	c.y += sin(c.x * 11.0 - TIME * 2.3) * 0.004 * s;
	vec2 wuv = c + 0.5;
	// chromatic split grows toward the edges
	vec2 dir = normalize(c + vec2(0.0001)) * (0.004 + r2 * 0.03) * s;
	float rr = textureLod(screen_tex, wuv + dir, 0.0).r;
	float gg = textureLod(screen_tex, wuv, 0.0).g;
	float bb = textureLod(screen_tex, wuv - dir, 0.0).b;
	vec3 col = vec3(rr, gg, bb);
	// soft double vision
	vec3 ghost = textureLod(screen_tex, wuv + vec2(0.012 * s * sin(TIME * 1.7), 0.0), 1.5).rgb;
	col = mix(col, ghost, 0.25 * s);
	// vignette
	float v = smoothstep(0.2, 0.75, sqrt(r2) * (1.0 + 0.6 * s));
	col = mix(col, vignette_color.rgb, v * 0.65 * s);
	// fade to dark via the rect colour alpha
	col = mix(col, vec3(0.02, 0.01, 0.02), clamp(COLOR.a, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
