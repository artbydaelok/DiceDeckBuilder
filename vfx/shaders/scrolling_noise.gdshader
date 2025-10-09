shader_type spatial;

uniform sampler2D noise_tex_1 : filter_nearest;
uniform sampler2D noise_tex_2 : filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 t1 = vec2(555. + (TIME * 0.1), -122. + (TIME * 0.225));
	vec2 t2 = vec2(242. - (TIME * 0.16), 9993. + (TIME * 0.145));	
	vec4 noise_color_1 = texture(noise_tex_1, UV + t1);
	vec4 noise_color_2 = texture(noise_tex_2, UV + t2);
	ALBEDO.rgb = (noise_color_1.rgb + noise_color_2.rgb) / 2.;
}
