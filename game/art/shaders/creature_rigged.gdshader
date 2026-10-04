shader_type spatial;
render_mode cull_disabled;
// Rigged creature surface (Agent 1): palette-atlas albedo + emission atlas, soft rim, and the same flash / highlight /
// telegraph-emission uniforms CritterCreature drives on its procedural toon material.
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable;
uniform sampler2D emis_tex : source_color, filter_nearest, repeat_disable;
uniform float use_emis = 0.0;
uniform vec4 highlight_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float highlight = 0.0;
uniform float flash = 0.0;
uniform vec4 emission_color : source_color = vec4(1.0, 0.25, 0.12, 1.0);
uniform float emission_energy = 0.0;
void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	ALBEDO = c * 1.05;
	ROUGHNESS = 0.85;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 e = texture(emis_tex, UV).rgb * use_emis * 1.6;
	EMISSION = e + emission_color.rgb * emission_energy * (0.4 + c) + highlight_color.rgb * f * highlight * 1.6 + vec3(1.0, 0.85, 0.8) * flash + vec3(1.0, 0.9, 0.7) * f * 0.22;
}
