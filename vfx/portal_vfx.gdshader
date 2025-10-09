shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_texture;
uniform sampler2D gradient_texture;
uniform float grid_scale = 1.0;

void vertex() {
	COLOR.rgb = VERTEX;
	float offset_x = texture(noise_texture, UV + TIME * 0.1).r;
	float offset_y = texture(noise_texture, UV + TIME * 0.182).r;
	VERTEX.z -= offset_x * 0.2;
	VERTEX.y -= offset_y * 0.1;
}

void fragment() {
	vec2 uv = (UV * grid_scale) + vec2(TIME * 0.25, TIME * 0.5);
	float noise = texture(noise_texture, uv).r;
	vec3 color = texture(gradient_texture, vec2(noise)).rgb;
	
	ALBEDO = color.rgb;
	//ALPHA = noise.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
