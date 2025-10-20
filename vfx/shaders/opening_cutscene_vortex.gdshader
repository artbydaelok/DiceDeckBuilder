shader_type spatial;

uniform sampler2D noise1 : repeat_enable, filter_nearest;
uniform sampler2D noise2 : repeat_enable, filter_nearest;

uniform sampler2D noise_color : repeat_enable, filter_nearest;
uniform float vertex_noise_strength = 1.0;
uniform float color_distorsion_noise_strength = 1.0;

void vertex() {
	float noise_value_x = (texture(noise1, UV - TIME * 0.02).r - 0.5 ) * 2.0 * vertex_noise_strength;
	float noise_value_y = (texture(noise2, UV - TIME * 0.141).r - 0.5 ) * 2.0 * vertex_noise_strength;
	VERTEX += vec3(noise_value_x, noise_value_y, 0.0);
}

void fragment() {
	float noise_value_x = (texture(noise1, UV - TIME * 0.1).r - 0.5 ) * 2.0 * color_distorsion_noise_strength;
	float noise_value_y = (texture(noise2, UV - TIME * 0.225).r - 0.5 ) * 2.0 * color_distorsion_noise_strength;
	vec2 uv_offset = vec2(noise_value_x, noise_value_y);
	ALBEDO = texture(noise_color, UV + uv_offset).rgb;
	ROUGHNESS = 0.5;
	vec3 emission_color_tint = vec3(noise_value_x, 0.0, noise_value_y);
	EMISSION = ALBEDO.rgb + emission_color_tint;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
