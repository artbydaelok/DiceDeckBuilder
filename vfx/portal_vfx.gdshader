shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_texture;
uniform float grid_scale = 1.0;

void vertex() {
	COLOR.rgb = VERTEX;
}

void fragment() {
	vec2 uv = (UV * grid_scale) + vec2(TIME * 0.25, TIME * 0.5);
	
	vec4 color = texture(noise_texture, uv);
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
