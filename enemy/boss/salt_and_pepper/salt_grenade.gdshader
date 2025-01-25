shader_type spatial;
render_mode unshaded;

uniform vec3 color : source_color;

void fragment() {
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
