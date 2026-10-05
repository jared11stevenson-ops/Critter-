shader_type spatial;
// Worn path ribbon (real 3D strip lying 4 cm over the terrain): packed, sun-bleached dirt with edge fade; vertex COLOR
// carries tint + alpha (rut lines are darker). Lit like terrain; pushed toward the camera with distance so it never z-fights.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_disabled;

void vertex() {
	float d = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	VERTEX.y += 0.035 + d * 0.0035;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
	ROUGHNESS = 0.95;
}
